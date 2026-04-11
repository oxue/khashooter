# Multiplayer UX Spec

## Main Menu (before gameplay)

When the game loads, instead of immediately dropping into gameplay, show a **title screen** with three options:

```
┌─────────────────────────────────────┐
│                                     │
│          K H A S H O O T E R        │
│                                     │
│       [ Single Player ]             │
│       [ Create Room   ]             │
│       [ Join Room     ]             │
│                                     │
│                                     │
└─────────────────────────────────────┘
```

### Single Player
- Loads the game immediately with the level selector (existing flow)
- No WebSocket connection
- Map editor (P) and debug tools available
- Level switching allowed

### Create Room
- Prompts for a **room name** (auto-generated 4-letter code, editable)
- Prompts for **map selection** (level2, bloodstrike_zm, modern_home, rooms)
- Prompts for **player name** (defaults to "Player")
- Creates a room on the signaling server
- Displays: "Waiting for players... Room code: **ABCD**"
- Copy button for the room code
- Game loads with the selected map
- This player becomes the **host**
- When another player joins, game starts

### Join Room
- Prompts for **room code** (4-letter input)
- Prompts for **player name**
- Connects to the signaling server, looks up the room
- If room exists: joins, loads the same map as the host
- If room doesn't exist: shows error "Room not found"
- This player is a **non-host** client

## In-Game Restrictions by Mode

| Feature | Single Player | Multiplayer (Host) | Multiplayer (Non-Host) |
|---------|--------------|-------------------|----------------------|
| Level selector (P menu) | Yes | No | No |
| Map editor tools | Yes | No | No |
| Debug menu (right-click) | Yes | Yes (limited) | Yes (limited) |
| NPC spawning | Yes | Host runs AI | AI synced from host |
| Weapon pickup items | Yes | Yes | Yes |
| Chat (T) | No | Yes | Yes |
| Scoreboard (Tab) | No | Yes | Yes |
| Level switching | Yes | No | No |

## Room System Architecture

### Option A: Vercel API Routes + Database (Recommended)

Since you already have Vercel + a DB, use Vercel API routes as the signaling layer:

```
Vercel API Routes (serverless):
  POST /api/rooms          → create room, returns room code
  GET  /api/rooms/[code]   → get room info (host peer ID, map, players)
  POST /api/rooms/[code]/join → join room, exchange connection info
  DELETE /api/rooms/[code] → delete room (host leaves)

Database (Supabase/Vercel KV):
  rooms table:
    code: string (PK, 4 chars)
    host_offer: text (WebRTC SDP offer)
    guest_answer: text (WebRTC SDP answer)  
    host_candidates: text[] (ICE candidates)
    guest_candidates: text[] (ICE candidates)
    map: string
    host_name: string
    created_at: timestamp
    status: 'waiting' | 'connecting' | 'active' | 'closed'
```

**WebRTC Flow:**
1. Host creates room → POST /api/rooms → gets code "ABCD"
2. Host creates RTCPeerConnection, generates offer
3. Host sends offer → POST /api/rooms/ABCD {host_offer: sdp}
4. Guest enters code → GET /api/rooms/ABCD → gets host's offer
5. Guest creates RTCPeerConnection, sets remote description to offer
6. Guest generates answer → POST /api/rooms/ABCD/join {guest_answer: sdp}
7. Host polls for answer → GET /api/rooms/ABCD → gets guest's answer
8. ICE candidates exchanged via the same polling mechanism
9. WebRTC data channel established → direct peer-to-peer
10. No more server needed — all game data flows P2P

**Pros:** No persistent server. Free. Uses existing infrastructure.
**Cons:** Only supports 2 players per room (WebRTC mesh gets complex beyond 2). Polling-based signaling adds ~1-2s to connection time.

### Option B: Keep WebSocket Server (Deploy to Render/Railway)

Keep the existing `server/index.js` and deploy it:
- Render.com free tier: 750 hours/month, spins down after 15min idle
- Room codes managed by the server in-memory
- Supports 2+ players per room easily

**Pros:** Already works. Supports N players. No WebRTC complexity.
**Cons:** Needs a separate hosting service. Free tier spins down (cold start ~30s).

### Recommendation

**Option A** for 2-player (1v1 CS2D duels) — zero infrastructure cost, uses your existing Vercel.
**Option B** for 2+ players — needs a deployed server but already built.

Start with Option A since it matches the "two guys in different tabs" use case and uses your existing stack.

## Implementation Plan

### Phase 1: Title Screen (Haxe)
- New `MenuState.hx` extending State — shown on game boot instead of GameState
- Renders the three buttons using kha.graphics2 or zui
- Single Player: `Application.setState(new GameState(selectedMap))`
- Create/Join: transitions to lobby UI

### Phase 2: Room API (Vercel)
- `dev-website/src/app/api/rooms/route.ts` — POST to create, GET to list
- `dev-website/src/app/api/rooms/[code]/route.ts` — GET room, POST to join/update
- Use Vercel KV or Supabase for storage (whichever you already have)
- Rooms auto-expire after 30 minutes

### Phase 3: WebRTC Integration (Haxe + JS interop)
- Replace NetClient's WebSocket with a WebRTC data channel
- Use `js.html.RTCPeerConnection` from Haxe's JS externs
- The signaling (offer/answer exchange) goes through the Vercel API
- Once connected, all game messages flow directly P2P
- NetState/NetManager don't need to change — they just get a different transport

### Phase 4: Connection UX
- "Waiting for players..." screen with room code display
- Copy-to-clipboard button
- Connection status indicators
- "Player joined!" notification
- Countdown before game starts (3, 2, 1, GO)

## UI Mockups

### Create Room Screen
```
┌─────────────────────────────────────┐
│  CREATE ROOM                        │
│                                     │
│  Your name: [Player1    ]           │
│  Map:       [level2        ▼]       │
│                                     │
│       [ Create ]  [ Back ]          │
└─────────────────────────────────────┘
```

### Waiting Screen (after creating)
```
┌─────────────────────────────────────┐
│  WAITING FOR PLAYERS                │
│                                     │
│  Room Code:  A B C D                │
│              [ Copy ]               │
│                                     │
│  Share this code with your friend   │
│                                     │
│  Players: 1/2                       │
│  Map: level2                        │
│                                     │
│       [ Cancel ]                    │
└─────────────────────────────────────┘
```

### Join Room Screen
```
┌─────────────────────────────────────┐
│  JOIN ROOM                          │
│                                     │
│  Your name: [Player2    ]           │
│  Room code: [_ _ _ _]              │
│                                     │
│       [ Join ]  [ Back ]            │
└─────────────────────────────────────┘
```

### Error States
- "Room not found" — wrong code
- "Room is full" — already 2 players
- "Connection failed" — WebRTC/network issue
- "Host disconnected" — room closed

## Development Workflow

**Game client (Haxe):** Iterate locally only. Build with `./build.sh`, serve with `python3 -m http.server 8081 --directory build/html5`. Do NOT deploy to Vercel website until a milestone is reached and manually tested.

**Signaling API (Vercel routes):** Deploy only the API routes to Vercel when they change. The game on localhost can call the production Vercel API for signaling since it's just REST endpoints.

**Testing order:**
1. Build + test locally with Playwright (`node test_suite.mjs --filter=...`)
2. Manual test in two browser tabs on localhost
3. Only deploy to website when a full flow works end-to-end

**What gets deployed where:**
| Component | Where | When |
|-----------|-------|------|
| Game client (kha.js) | localhost during dev, Vercel website at milestones | After manual testing |
| Room API routes | Vercel (dev-website) | When API changes |
| WebRTC signaling | In-browser (no server) | N/A |
| WebSocket server | localhost only (for local testing fallback) | Never in prod if using WebRTC |

## Player Name Flow

- Stored in localStorage so you don't re-enter each time
- Displayed in name labels, kill feed, scoreboard, chat
- Sent to other player during connection handshake
- Max 16 characters, alphanumeric + spaces
