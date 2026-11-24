# Buckshot Roulette relay server

Self-hosted matchmaking + relay server without Steam.

## Stack

- Node.js 22/24, `ws`
- systemd service `buckshot-net`, port `9090` (localhost only via nginx proxy)
- Public endpoint: `ws://buckshot-129-146-71-78.nip.io/ws` → nginx vhost `/etc/nginx/conf.d/buckshot-ws.conf` → `127.0.0.1:9090`

## Deploy (already done on 129.146.71.78)

```bash
cd /home/loki/buckshot-net
npm install --production
sudo systemctl restart buckshot-net
curl http://127.0.0.1:9090/health
```

nginx vhost (only adds a new server_name, does not touch existing sites):

```nginx
server {
    listen 80;
    server_name buckshot-129-146-71-78.nip.io;
    location /ws {
        proxy_pass http://127.0.0.1:9090/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
```

## Protocol (JSON)

| `t` | Direction | Meaning |
|---|---|---|
| `welcome` | S→C | assigned player id |
| `hello` | C→S | nickname |
| `room.list` | S→C | list of public rooms |
| `room.create` | C→S | create room |
| `room.join` | C→S | join room id |
| `room.leave` | C→S | leave room |
| `room.snapshot` | S→C | members, host, data |
| `lobby.created` / `lobby.joined` / `lobby.chat` | S→C | Steam-compatible signals |
| `packet` | C→S→C | GZIP `var_to_bytes` payload, base64 |
| `ping` / `pong` | ↔ | keepalive |

Clients send requests to the host; the host broadcasts authoritative packets to the room (`to` field for targeted packets). The server never evaluates game logic.

## Limits

- Max 4 players per room.
- Rate limit 120 messages/s/client, 1 MB max payload.
- Host leaving dissolves the room and returns everyone to the lobby.
