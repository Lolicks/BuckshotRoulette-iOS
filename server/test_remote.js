const WebSocket = require('ws');
const URL = 'ws://buckshot-129-146-71-78.nip.io/ws';
const a = new WebSocket(URL);
const b = new WebSocket(URL);
let aid = 0, bid = 0, roomId = 0;
const seen = [];
function log(...x) { console.log(...x); }
for (const [label, ws] of [['A', a], ['B', b]]) {
  ws.on('error', e => log(label, 'ERROR', e.message));
  ws.on('message', raw => {
    const m = JSON.parse(raw);
    if (m.t === 'welcome') {
      if (label === 'A') aid = m.id; else bid = m.id;
      log(label, 'connected as', m.id);
      ws.send(JSON.stringify({ t: 'hello', name: label }));
      if (label === 'A' && b.readyState === 1) a.send(JSON.stringify({ t: 'room.create', name: 'Remote test', limit: 4 }));
    }
    if (m.t === 'lobby.created') { roomId = m.id; log('A created room', roomId); }
    if (m.t === 'room.list' && label === 'B' && m.rooms.length && !roomId) {
      // join will be triggered once A publishes the room; roomId is local to A, so use list
      if (!b.__joined) { b.__joined = true; b.send(JSON.stringify({ t: 'room.join', id: m.rooms[0].id })); log('B joining', m.rooms[0].id); }
    }
    if (m.t === 'lobby.joined' && m.id === roomId && m.response === 0) {
      log(label, 'in room');
      if (label === 'B') b.send(JSON.stringify({ t: 'packet', data: 'REMOTE_OK' }));
    }
    if (m.t === 'packet') { log(label, 'got packet', m.data); seen.push(m.data); }
  });
}
a.on('open', () => {
  setTimeout(() => { if (!roomId) a.send(JSON.stringify({ t: 'room.create', name: 'Remote test', limit: 4 })); }, 1500);
});
setTimeout(() => {
  log('seen', seen, 'aid', aid, 'bid', bid, 'room', roomId);
  a.close(); b.close();
  process.exit(seen.includes('REMOTE_OK') ? 0 : 1);
}, 8000);
