const WebSocket = require('ws');
const WS_URL = process.env.WS_URL || 'ws://127.0.0.1:9090';
const a = new WebSocket(WS_URL);
const b = new WebSocket(WS_URL);
const seen = [];
let aid = 0, bid = 0, roomId = 0;
function log(...x) { console.log(...x); }
function send(ws, obj) {
  const payload = JSON.stringify(obj);
  if (ws.readyState === WebSocket.OPEN) ws.send(payload);
  else ws.once('open', () => ws.send(payload));
}
a.on('message', raw => {
  const m = JSON.parse(raw);
  if (m.t === 'welcome') { aid = m.id; send(a, { t: 'hello', name: 'Alice' }); }
  if (m.t === 'lobby.created') { roomId = m.id; log('A created room', roomId); send(b, { t: 'room.join', id: roomId }); }
  if (m.t === 'packet') { log('A got packet', m.data); seen.push(m.data); finish(); }
});
b.on('message', raw => {
  const m = JSON.parse(raw);
  if (m.t === 'welcome') { bid = m.id; send(b, { t: 'hello', name: 'Bob' }); }
  if (m.t === 'lobby.joined' && m.id === roomId && m.response === 0) {
    log('B joined room', roomId);
    // Send only after this client is actually in the room; sending on A's
    // lobby.created races the join and the relay drops the packet.
    send(b, { t: 'packet', data: 'HELLO' });
  }
});
for (const ws of [a, b]) ws.on('error', e => log('WS error', e.message));
setTimeout(() => {
  if (!roomId) send(a, { t: 'room.create', name: 'Test', limit: 4 });
}, 300);
function finish() {
  log('seen', seen, 'aid', aid, 'bid', bid);
  a.close(); b.close();
  process.exit(seen.length >= 1 ? 0 : 1);
}
setTimeout(() => finish(), 6000);
