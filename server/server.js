/*
 * Self-hosted relay/matchmaking server for Buckshot Roulette.
 * No Steam. Host-authoritative: clients send requests to host, host broadcasts
 * authoritative state to everyone in the room. The server never touches game logic.
 */
'use strict';

const http = require('http');
const crypto = require('crypto');
const { WebSocketServer } = require('ws');

const PORT = Number(process.env.PORT || 8080);
const MAX_PAYLOAD = 1024 * 1024;
const ROOM_LIMIT = 4;
const RATE_LIMIT = 120; // packets per second per client

const server = http.createServer((req, res) => {
  if (req.url === '/health') {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ ok: true, rooms: rooms.size, clients: clients.size }));
  } else {
    res.writeHead(404);
    res.end();
  }
});

const wss = new WebSocketServer({ server, maxPayload: MAX_PAYLOAD });

/** @type {Map<number, {id:number,name:string,ws:any,roomId:number,tokens:number,lastRefill:number}>} */
const clients = new Map();
/** @type {Map<number, {id:number,name:string,hostId:number,limit:number,members:Set<number>,data:Object,started:boolean}>} */
const rooms = new Map();

let nextClientId = Math.floor(Math.random() * 1000000) + 1000;
let nextRoomId = 1000;

function uid() {
  let id;
  do { id = nextClientId++; } while (clients.has(id));
  return id;
}
function rid() {
  let id;
  do { id = nextRoomId++; } while (rooms.has(id));
  return id;
}
function send(ws, obj) {
  if (ws && ws.readyState === 1) ws.send(JSON.stringify(obj));
}
function safeName(name) {
  return String(name || 'Player').replace(/[<>]/g, '').trim().slice(0, 24) || 'Player';
}
function roomSummary(r) {
  return {
    id: r.id,
    name: r.name,
    host_id: r.hostId,
    member_count: r.members.size,
    player_limit: r.limit,
    started: r.started,
  };
}
function broadcastRoomList() {
  const list = [...rooms.values()].filter(r => !r.started).map(roomSummary);
  for (const c of clients.values()) send(c.ws, { t: 'room.list', rooms: list });
}
function notifySnapshot(room) {
  const ids = [...room.members];
  for (const id of ids) {
    const c = clients.get(id);
    if (c) send(c.ws, {
      t: 'room.snapshot',
      id: room.id,
      host_id: room.hostId,
      members: ids.map(mid => {
        const mc = clients.get(mid);
        return { id: mid, name: mc ? mc.name : 'Player' };
      }),
      data: room.data,
      limit: room.limit,
    });
  }
}
function emitMemberChange(room, changeId, state) {
  for (const id of room.members) {
    const c = clients.get(id);
    if (c) send(c.ws, { t: 'lobby.chat', room_id: room.id, change_id: changeId, changer_id: changeId, state });
  }
}
function leaveRoom(client) {
  const room = rooms.get(client.roomId);
  client.roomId = 0;
  if (!room) return;
  room.members.delete(client.id);
  emitMemberChange(room, client.id, 2); // LEFT
  if (room.members.size === 0) {
    rooms.delete(room.id);
  } else if (room.hostId === client.id) {
    // MVP: host migration = dissolve room and send everyone back to lobby.
    for (const id of room.members) {
      const c = clients.get(id);
      if (c) {
        c.roomId = 0;
        send(c.ws, { t: 'lobby.joined', id: 0, response: 0, host_id: 0, reason: 'host_left' });
      }
    }
    rooms.delete(room.id);
  } else {
    notifySnapshot(room);
  }
  broadcastRoomList();
}

wss.on('connection', (ws) => {
  const id = uid();
  const client = { id, name: 'Player', ws, roomId: 0, tokens: RATE_LIMIT, lastRefill: Date.now() };
  clients.set(id, client);
  send(ws, { t: 'welcome', id, version: 1 });

  ws.on('message', (raw) => {
    let msg;
    try { msg = JSON.parse(raw.toString()); } catch (_) { return; }
    if (!msg || typeof msg.t !== 'string') return;

    const now = Date.now();
    if (now - client.lastRefill > 1000) {
      client.tokens = RATE_LIMIT;
      client.lastRefill = now;
    }
    if (client.tokens-- <= 0) return;

    switch (msg.t) {
      case 'hello':
        client.name = safeName(msg.name);
        broadcastRoomList();
        break;

      case 'room.list':
        broadcastRoomList();
        break;

      case 'room.create': {
        leaveRoom(client);
        const room = {
          id: rid(), name: safeName(msg.room_name || client.name + "'s game"),
          hostId: client.id, limit: Math.min(4, Math.max(2, Number(msg.limit) || 4)),
          members: new Set([client.id]), data: {}, started: false,
        };
        rooms.set(room.id, room);
        client.roomId = room.id;
        send(ws, { t: 'lobby.created', connect: 1, id: room.id });
        send(ws, { t: 'lobby.joined', id: room.id, response: 0, host_id: room.hostId });
        notifySnapshot(room);
        emitMemberChange(room, client.id, 1); // ENTERED
        broadcastRoomList();
        break;
      }

      case 'room.join': {
        const room = rooms.get(Number(msg.id));
        if (!room || room.started || room.members.size >= room.limit) {
          send(ws, { t: 'lobby.joined', id: Number(msg.id), response: room ? 3 : 1, host_id: 0 });
          return;
        }
        leaveRoom(client);
        room.members.add(client.id);
        client.roomId = room.id;
        send(ws, { t: 'lobby.joined', id: room.id, response: 0, host_id: room.hostId });
        notifySnapshot(room);
        emitMemberChange(room, client.id, 1);
        broadcastRoomList();
        break;
      }

      case 'room.leave':
        leaveRoom(client);
        broadcastRoomList();
        break;

      case 'lobby.setdata': {
        const room = rooms.get(client.roomId);
        if (!room || room.hostId !== client.id) return;
        room.data[String(msg.key)] = String(msg.value ?? '');
        broadcastRoomList();
        notifySnapshot(room);
        break;
      }

      case 'room.start': {
        const room = rooms.get(client.roomId);
        if (!room || room.hostId !== client.id) return;
        room.started = true;
        for (const id of room.members) {
          const c = clients.get(id);
          if (c) send(c.ws, { t: 'room.start', id: room.id });
        }
        broadcastRoomList();
        break;
      }

      case 'packet': {
        const room = rooms.get(client.roomId);
        if (!room || typeof msg.data !== 'string') return;
        if (client.id === room.hostId) {
          const targets = (msg.to !== undefined && msg.to !== null)
            ? [Number(msg.to)]
            : [...room.members].filter(id => id !== client.id);
          for (const id of targets) {
            if (id === client.id) continue;
            const c = clients.get(id);
            if (c) send(c.ws, { t: 'packet', from: client.id, data: msg.data });
          }
        } else {
          // Clients can only talk to the host (server keeps the host authoritative).
          const host = clients.get(room.hostId);
          if (host) send(host.ws, { t: 'packet', from: client.id, data: msg.data });
        }
        break;
      }

      case 'ping':
        send(ws, { t: 'pong' });
        break;
    }
  });

  ws.on('close', () => {
    leaveRoom(client);
    clients.delete(id);
    broadcastRoomList();
  });
});

server.listen(PORT, '0.0.0.0', () => {
  console.log(`Buckshot Roulette relay listening on 0.0.0.0:${PORT}`);
});
