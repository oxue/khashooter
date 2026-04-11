import { WebSocketServer } from 'ws';
import http from 'http';

const PORT = process.env.PORT || 3000;

const server = http.createServer((req, res) => {
  if (req.url === '/health') {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ status: 'ok', players: Object.keys(players).length, host: hostId }));
    return;
  }
  res.writeHead(404);
  res.end();
});

const wss = new WebSocketServer({ server });

let nextId = 0;
let hostId = -1; // First connected client is the host
const players = {};
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

function broadcastAll(msg) {
  const payload = JSON.stringify(msg);
  for (const player of Object.values(players)) {
    if (player.ws.readyState === 1) {
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

function electHost() {
  const ids = Object.keys(players).map(Number);
  if (ids.length === 0) {
    hostId = -1;
    return;
  }
  hostId = Math.min(...ids);
  log('HOST', `New host elected: ${hostId}`);
  // Notify all clients who the host is
  broadcastAll({ type: 'host_change', hostId });
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

  // Elect host if needed
  if (hostId === -1) {
    hostId = clientId;
    log('HOST', `${clientId} is the host (first connected)`);
  }

  // Send welcome
  sendTo(clientId, {
    type: 'welcome',
    id: clientId,
    map: MAP,
    spawn,
    hostId,
    players: Object.entries(players)
      .filter(([id]) => parseInt(id) !== clientId)
      .map(([id, p]) => ({ id: parseInt(id), name: p.name, x: p.x, y: p.y, health: p.health })),
  });

  // Tell others
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
      return;
    }

    switch (msg.type) {
      case 'update': {
        const p = players[clientId];
        if (!p) break;

        if (msg.vars) {
          for (const [key, val] of Object.entries(msg.vars)) {
            p.vars[key] = val;
          }
          const pxKey = `${clientId}|pos_x`;
          const pyKey = `${clientId}|pos_y`;
          if (msg.vars[pxKey]) p.x = msg.vars[pxKey][0];
          if (msg.vars[pyKey]) p.y = msg.vars[pyKey][0];
        }

        broadcast(clientId, {
          type: 'state',
          from: clientId,
          vars: msg.vars,
        });
        break;
      }

      // Host sends NPC/world state updates
      case 'npc_update': {
        if (clientId !== hostId) break; // Only host can send NPC updates
        broadcast(clientId, {
          type: 'npc_state',
          npcs: msg.npcs, // array of {id, x, y, rot, anim}
        });
        break;
      }

      case 'shoot': {
        // Relay shoot event to all clients (including shooter for confirmation)
        broadcastAll({
          type: 'shoot',
          from: clientId,
          weapon: msg.weapon,
          x: msg.x,
          y: msg.y,
          dir: msg.dir,
          damage: msg.damage || 10,
        });

        log('SHOOT', `Client ${clientId}`, { weapon: msg.weapon });

        // Server-side hit detection against other players
        const HIT_RADIUS = 25;
        for (const [id, target] of Object.entries(players)) {
          const targetId = parseInt(id);
          if (targetId === clientId) continue;

          const dx = target.x - msg.x;
          const dy = target.y - msg.y;
          const dist = Math.sqrt(dx * dx + dy * dy);

          if (dist < HIT_RADIUS) {
            const damage = msg.damage || 10;
            target.health -= damage;

            log('HIT', `${clientId} -> ${targetId}`, { damage, health: target.health });

            sendTo(targetId, { type: 'hit', target: targetId, source: clientId, damage, health: target.health });
            sendTo(clientId, { type: 'hit_confirm', target: targetId, damage });

            if (target.health <= 0) {
              log('KILL', `${clientId} killed ${targetId}`);
              broadcastAll({ type: 'kill', killed: targetId, killer: clientId });

              const newSpawn = getSpawnPoint(targetId);
              target.health = 100;
              target.x = newSpawn.x;
              target.y = newSpawn.y;

              sendTo(targetId, { type: 'spawn', id: targetId, x: newSpawn.x, y: newSpawn.y, health: 100 });
            }
          }
        }
        break;
      }

      case 'ping': {
        sendTo(clientId, { type: 'pong', time: msg.time, serverTime: Date.now() });
        break;
      }
    }
  });

  ws.on('close', () => {
    log('DISCONNECT', `Client ${clientId} disconnected`);
    delete players[clientId];
    broadcast(-1, { type: 'player_left', id: clientId });

    // Re-elect host if the host disconnected
    if (clientId === hostId) {
      electHost();
    }
  });

  ws.on('error', (err) => {
    log('ERROR', `Client ${clientId}: ${err.message}`);
  });
});

server.listen(PORT, () => {
  log('SERVER', `Khashooter server listening on port ${PORT}`);
});
