import { WebSocketServer } from 'ws';
import http from 'http';

const PORT = process.env.PORT || 3000;

const server = http.createServer((req, res) => {
  // Health check endpoint
  if (req.url === '/health') {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ status: 'ok', players: Object.keys(players).length }));
    return;
  }
  res.writeHead(404);
  res.end();
});

const wss = new WebSocketServer({ server });

let nextId = 0;
const players = {}; // id -> { ws, vars, name }
const MAP = 'level2';
const SPAWN_POINTS = [
  { x: 30, y: 100 },
  { x: 200, y: 100 },
  { x: 100, y: 200 },
  { x: 300, y: 200 },
];

function log(tag, msg, data) {
  const ts = new Date().toISOString();
  console.log(`[${ts}] [${tag}] ${msg}`, data ? JSON.stringify(data) : '');
}

function broadcast(excludeId, msg) {
  const payload = JSON.stringify(msg);
  for (const [id, player] of Object.entries(players)) {
    if (parseInt(id) !== excludeId && player.ws.readyState === 1) {
      player.ws.send(payload);
    }
  }
}

function sendTo(id, msg) {
  const player = players[id];
  if (player && player.ws.readyState === 1) {
    player.ws.send(JSON.stringify(msg));
  }
}

function getSpawnPoint(id) {
  return SPAWN_POINTS[id % SPAWN_POINTS.length];
}

wss.on('connection', (ws) => {
  const clientId = nextId++;
  const spawn = getSpawnPoint(clientId);

  players[clientId] = {
    ws,
    vars: {},
    name: `Player${clientId}`,
    x: spawn.x,
    y: spawn.y,
    health: 100,
  };

  log('CONNECT', `Client ${clientId} connected`, { totalPlayers: Object.keys(players).length });

  // Send welcome with ID, map, and spawn point
  sendTo(clientId, {
    type: 'welcome',
    id: clientId,
    map: MAP,
    spawn,
    players: Object.entries(players)
      .filter(([id]) => parseInt(id) !== clientId)
      .map(([id, p]) => ({ id: parseInt(id), name: p.name, x: p.x, y: p.y, health: p.health })),
  });

  // Tell others about new player
  broadcast(clientId, {
    type: 'player_joined',
    id: clientId,
    name: players[clientId].name,
    spawn,
  });

  ws.on('message', (raw) => {
    let msg;
    try {
      msg = JSON.parse(raw);
    } catch {
      log('ERROR', `Invalid JSON from client ${clientId}`);
      return;
    }

    switch (msg.type) {
      case 'update': {
        // Client sending their synced variable updates
        const p = players[clientId];
        if (!p) break;

        // Store latest position from vars
        if (msg.vars) {
          for (const [key, val] of Object.entries(msg.vars)) {
            p.vars[key] = val;
          }
          // Extract position for server-side hit detection
          const pxKey = `${clientId}|pos_x`;
          const pyKey = `${clientId}|pos_y`;
          if (msg.vars[pxKey]) p.x = msg.vars[pxKey][0];
          if (msg.vars[pyKey]) p.y = msg.vars[pyKey][0];
        }

        // Relay to all other clients
        broadcast(clientId, {
          type: 'state',
          from: clientId,
          vars: msg.vars,
        });
        break;
      }

      case 'shoot': {
        // Client reports shooting — relay to others for visual effect
        broadcast(clientId, {
          type: 'shoot',
          from: clientId,
          weapon: msg.weapon,
          x: msg.x,
          y: msg.y,
          dir: msg.dir,
        });

        log('SHOOT', `Client ${clientId} shot`, { weapon: msg.weapon, x: msg.x, y: msg.y });

        // Simple hit detection: check if any other player is within hit radius
        const HIT_RADIUS = 20;
        for (const [id, target] of Object.entries(players)) {
          const targetId = parseInt(id);
          if (targetId === clientId) continue;

          const dx = target.x - msg.x;
          const dy = target.y - msg.y;
          const dist = Math.sqrt(dx * dx + dy * dy);

          if (dist < HIT_RADIUS) {
            const damage = msg.damage || 10;
            target.health -= damage;

            log('HIT', `Client ${clientId} hit client ${targetId}`, { damage, health: target.health });

            // Notify the target they got hit
            sendTo(targetId, {
              type: 'hit',
              target: targetId,
              source: clientId,
              damage,
              health: target.health,
            });

            // Notify the shooter
            sendTo(clientId, {
              type: 'hit_confirm',
              target: targetId,
              damage,
            });

            // Check for kill
            if (target.health <= 0) {
              log('KILL', `Client ${clientId} killed client ${targetId}`);

              broadcast(-1, {
                type: 'kill',
                killed: targetId,
                killer: clientId,
              });

              // Respawn
              const newSpawn = getSpawnPoint(targetId);
              target.health = 100;
              target.x = newSpawn.x;
              target.y = newSpawn.y;

              sendTo(targetId, {
                type: 'spawn',
                id: targetId,
                x: newSpawn.x,
                y: newSpawn.y,
                health: 100,
              });
            }
          }
        }
        break;
      }

      case 'ping': {
        sendTo(clientId, { type: 'pong', time: msg.time, serverTime: Date.now() });
        break;
      }

      default:
        log('WARN', `Unknown message type from ${clientId}: ${msg.type}`);
    }
  });

  ws.on('close', () => {
    log('DISCONNECT', `Client ${clientId} disconnected`);
    delete players[clientId];
    broadcast(-1, { type: 'player_left', id: clientId });
  });

  ws.on('error', (err) => {
    log('ERROR', `WebSocket error for client ${clientId}: ${err.message}`);
  });
});

server.listen(PORT, () => {
  log('SERVER', `Khashooter server listening on port ${PORT}`);
});
