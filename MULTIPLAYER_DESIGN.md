# Khashooter Multiplayer Design

## Goal
Two players open the game in separate browser tabs, see each other on the same map, and can shoot each other — CS2D-style.

## Architecture Overview

```
 Browser Tab A                   Node.js Server              Browser Tab B
 ┌──────────┐                   ┌─────────────┐             ┌──────────┐
 │ Kha Game  │◄──WebSocket──────│  Relay +     │─────WS────►│ Kha Game │
 │ (HTML5)   │──────────────────│  Authority   │◄───────────│ (HTML5)  │
 └──────────┘                   └─────────────┘             └──────────┘
```

**Client-authoritative input, server-relay model** (like ck):
- Each client owns their player's position/rotation/actions
- Server relays other players' state to all clients
- Server is the authority for shared state (hit registration, kill events, spawns)

## Core Networking Concepts (from ck)

### 1. SyncVar (equivalent to ck's C0)
A synchronized numeric value with velocity for interpolation.

```haxe
class SyncVar {
    public var value:Float;       // current authoritative value
    public var delta:Float;       // rate of change (velocity)
    public var lerpValue:Float;   // interpolated render value
    public var dirty:Bool;        // needs sending
    
    public function update(dt:Float) {
        value += delta * dt;
        lerpValue += (value - lerpValue) * 0.2; // smooth toward target
    }
}
```

### 2. Ownership Model (from ck's key prefixing)
Variables are keyed as `{clientId}|{name}`:
- `0|pos_x`, `0|pos_y`, `0|rotation` — owned by client 0
- `1|pos_x`, `1|pos_y`, `1|rotation` — owned by client 1
- `-1|game_state` — server-owned shared state

Clients can only write to variables they own. They read (and interpolate) all others.

### 3. Message Protocol (JSON over WebSocket)

**Client → Server:**
```json
{"type": "update", "vars": {"0|pos_x": [150.5, 2.0], "0|pos_y": [200.0, -1.5], "0|rot": [45.0, 0]}}
{"type": "shoot", "weapon": "crossbow", "x": 150, "y": 200, "dir": 45.0}
{"type": "join", "name": "Player1"}
```

**Server → Client:**
```json
{"type": "welcome", "id": 0, "map": "level2"}
{"type": "state", "vars": {"1|pos_x": [300, 0], "1|pos_y": [150, 1.5], "1|rot": [90, 0]}}
{"type": "player_joined", "id": 1, "name": "Player2"}
{"type": "player_left", "id": 1}
{"type": "hit", "target": 0, "damage": 10, "source": 1}
{"type": "kill", "killed": 0, "killer": 1}
{"type": "spawn", "id": 0, "x": 30, "y": 100}
```

## Implementation Plan

### Phase 1: Networking Foundation
**Files to create:**

1. **`server/index.js`** — Node.js WebSocket relay server
   - Express + `ws` library
   - Room/lobby management (one room per map)
   - Receives updates from clients, broadcasts to others
   - Hit detection authority (receives "shoot" events, calculates hits)
   - Runs on port 3000
   
2. **`Sources/net/NetClient.hx`** — Haxe WebSocket client
   - Wraps `js.html.WebSocket` 
   - Connect/disconnect/reconnect
   - Send/receive JSON messages
   - Exposes `onMessage`, `onConnect`, `onDisconnect` callbacks

3. **`Sources/net/SyncVar.hx`** — Synchronized variable
   - Port of ck's C0 concept
   - `value`, `delta`, `lerpValue`, `dirty` flag
   - `update(dt)` for interpolation
   - `serialize()` / `deserialize()` 

4. **`Sources/net/NetState.hx`** — Network state manager
   - Holds all SyncVars keyed by `{clientId}|{name}`
   - `sendDirtyVars()` — sends only changed vars
   - `applyRemoteUpdate(data)` — updates remote players' vars
   - `getLocalVar(name)` / `getRemoteVar(clientId, name)`

### Phase 2: Game Integration

5. **`Sources/net/RemotePlayer.hx`** — Remote player entity
   - Reads SyncVars for position/rotation
   - Renders using `lerpValue` for smooth movement
   - Shows weapon, animation state
   - No physics/collision (just visual representation)

6. **Modify `GameState.hx`** — Multiplayer mode
   - On load: connect to server, receive client ID
   - Each frame: write local player pos/rot to owned SyncVars
   - Each frame: read remote SyncVars, update RemotePlayer entities
   - On shoot: send shoot event to server
   - On hit received: apply damage to local player

7. **Modify `GameContext.hx`** — Add net state
   - `netState:NetState` — network state manager
   - `remotePlayers:Map<Int, Entity>` — remote player entities
   - `localClientId:Int`

### Phase 3: Shared Game Events

8. **Server-side hit detection**
   - Client sends: "I shot at position X,Y in direction D"
   - Server checks if any other player's position intersects
   - Server sends hit/kill events to affected clients

9. **Spawning and death**
   - Server assigns spawn points
   - On death: server picks new spawn, sends spawn event
   - Client respawns at server-assigned position

## Synced Variables Per Player

| Variable | Type | Update Rate | Notes |
|----------|------|-------------|-------|
| `pos_x` | SyncVar | Every frame | Position with velocity prediction |
| `pos_y` | SyncVar | Every frame | Position with velocity prediction |
| `rotation` | SyncVar | Every frame | Aim direction |
| `anim_state` | int | On change | idle/running/shooting |
| `weapon` | int | On change | Current weapon index |
| `health` | int | On change | Server-authoritative |

## Update Flow (per frame)

```
CLIENT A:                          SERVER:                         CLIENT B:
1. Read WASD input                                                
2. Update local position           
3. Write pos to SyncVars           
4. sendDirtyVars() ──────────────► 5. Receive A's update
                                   6. Broadcast to B ────────────► 7. Receive A's state
                                                                   8. Update RemotePlayer A
                                                                   9. Interpolate A's position
                                                                   10. Render A at lerpValue
```

## Server Tick Rate
- Server relays immediately on receive (no fixed tick)
- Clients send at 20Hz (every 3 frames at 60fps) to limit bandwidth
- Interpolation covers the gaps

## Observability & Playwright Testing

### Console Logging Protocol
All net events logged with `[NET]` prefix for Playwright filtering:

```
[NET:CONNECT] id=0 server=ws://localhost:3000
[NET:JOIN] id=0 map=level2
[NET:PLAYER_JOINED] id=1 name=Player2
[NET:SEND] vars=3 bytes=128
[NET:RECV] from=1 vars=3
[NET:SHOOT] weapon=crossbow x=150 y=200 dir=45
[NET:HIT] target=0 damage=10 source=1
[NET:KILL] killed=0 killer=1
[NET:SPAWN] id=0 x=30 y=100
[NET:DISCONNECT] id=1 reason=closed
[NET:LATENCY] ping=23ms
[NET:ERROR] message="connection refused"
```

### Playwright Test Script Design

```javascript
// test_multiplayer.mjs
import { chromium } from 'playwright';

// 1. Start server
// 2. Launch two browser tabs
// 3. Wait for both to boot (watch for [NET:CONNECT] in console)
// 4. Wait for [NET:PLAYER_JOINED] in both tabs
// 5. Simulate WASD input in tab A
// 6. Watch tab B console for [NET:RECV] with position updates
// 7. Verify remote player position changed in tab B
// 8. Simulate shooting in tab A toward tab B's player
// 9. Watch for [NET:HIT] or [NET:KILL] events
// 10. Report pass/fail with latency stats
```

### Key Test Scenarios

1. **Connection**: Both clients connect and see each other
   - Assert: Both tabs log `[NET:PLAYER_JOINED]`

2. **Position sync**: Move player A, verify B sees movement
   - Assert: Tab B receives `[NET:RECV]` with A's position within 200ms

3. **Shooting**: Player A shoots, server detects hit on B
   - Assert: Tab B logs `[NET:HIT]`

4. **Disconnect**: Close tab A, verify B sees disconnect
   - Assert: Tab B logs `[NET:DISCONNECT]` or `[NET:PLAYER_LEFT]`

### Boot Time Handling
The game takes ~2-3 seconds to load assets. Playwright tests must:
- Wait for `[PERF] {time:` log line (signals assets loaded and game running)
- Then wait for `[NET:CONNECT]` (signals WebSocket connected)
- Only then begin input simulation and assertions
- Use 15-second timeouts for initial boot

## Deployment

- **Game client**: Static HTML5 build on Vercel (already done)
- **WebSocket server**: Deploy to Railway/Fly.io (needs persistent process)
- **Server URL**: Configured via query param or env: `?server=wss://khashooter-server.fly.dev`
- **Fallback**: Single-player mode if server unreachable

## File Structure

```
khashooter/
├── server/
│   ├── index.js          # Node.js WebSocket relay server  
│   ├── package.json
│   └── Dockerfile        # For deployment
├── Sources/
│   └── net/
│       ├── NetClient.hx  # WebSocket client wrapper
│       ├── SyncVar.hx    # Synchronized variable (ck C0 port)
│       ├── NetState.hx   # Network state manager
│       └── RemotePlayer.hx # Remote player rendering
├── test_multiplayer.mjs  # Playwright multi-tab test
└── MULTIPLAYER_DESIGN.md # This document
```
