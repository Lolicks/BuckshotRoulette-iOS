const WebSocket = require('ws');
const a = new WebSocket('ws://127.0.0.1:8080');
const b = new WebSocket('ws://127.0.0.1:8080');
const seen = [];
let aid = 0, bid = 0, roomId = 0;
function log(...x) { console.log(...x); }
a.on('message', raw => {
  const m = JSON.parse(raw);
  if (m.t === 'welcome') { aid = m.id; a.send(JSON.stringify({t:'hello',name:'Alice'})); }
  if (m.t === 'lobby.created') { roomId = m.id; log('A created room', roomId); b.send(JSON.stringify({t:'room.join',id:roomId})); }
  if (m.t === 'lobby.joined' && m.id === roomId && m.response === 0) { log('A sees join'); a.send(JSON.stringify({t:'packet',data:'HELLO'})); }
  if (m.t === 'packet') { log('A got packet', m.data); seen.push(m.data); finish(); }
});
b.on('message', raw => {
  const m = JSON.parse(raw);
  if (m.t === 'welcome') { bid = m.id; b.send(JSON.stringify({t:'hello',name:'Bob'})); }
  if (m.t === 'lobby.joined' && m.id === roomId && m.response === 0) log('B joined room', roomId);
  if (m.t === 'packet') { log('B got packet', m.data); seen.push(m.data); }
});
setTimeout(() => {
  if (!roomId) a.send(JSON.stringify({t:'room.create',name:'Test',limit:4}));
}, 300);
function finish() {
  log('seen', seen, 'aid', aid, 'bid', bid);
  a.close(); b.close();
  process.exit(seen.length >= 1 ? 0 : 1);
}
setTimeout(() => finish(), 4000);
