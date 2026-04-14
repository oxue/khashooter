# Exploration: Network Interaction Architecture for Multiplayer Games
Started: 2026-04-14
Budget: rounds:2 knowledge:5000 time:60

## Context
Khashooter is a 2D top-down shooter built in Haxe/Kha with a custom ECS (Refraction). We added multiplayer (WebRTC P2P, host-authoritative) but 8/18 gameplay interactions were broken because the original single-player collision handlers apply effects directly to entities regardless of network ownership.

## Research Graph
```
                        Network Interaction Architecture
                                    │
            ┌───────────┬───────────┼───────────┬────────────┐
            │           │           │           │            │
     Game Engines   ECS+Net    Indie 2D MP   WebRTC P2P   Code Patterns
     (Unreal/Unity  (Overwatch  (Vermintide   (star topo   (authority
      /Godot)       /Bevy)      pattern)      host relay)   checks)
            │           │           │           │            │
     ┌──────┘    ┌──────┘    ┌──────┘    ┌──────┘     ┌──────┘
     │           │           │           │            │
  GameplayCue  Component   Client-hit   Host runs   HasAuthority
  pattern:     markers:    Server-     full sim,    gate before
  cosmetic vs  Replicated  respond:    clients      state mutation
  authoritative vs Local   visual+send render only
               vs Predicted to server
                    │
          ┌─────────┴─────────┐
          │                   │
    Vermintide           Gabriel Gambetta
    "feel good"          "state authority"
    client hit detect    server reconciliation
    server damage        client prediction
          │
          └─────► Applied to khashooter as isHost() gate
                  in CollisionBehaviours.hx
```

## Round 1: Research Findings

### Sources (24 URLs across 5 sub-agents)
- Unreal GameplayCues: https://github.com/tranek/GASDocumentation
- Unreal stateful events: https://vorixo.github.io/devtricks/stateful-events-multiplayer/
- Unity Netcode physics: https://docs.unity3d.com/Packages/com.unity.netcode.gameobjects@2.5/manual/advanced-topics/physics.html
- Unity Netcode for Entities ghosts: https://docs.unity3d.com/Packages/com.unity.netcode@1.0/manual/ghost-snapshots.html
- Godot multiplayer: https://godotengine.org/article/multiplayer-in-godot-4-0-scene-replication/
- Overwatch GDC: https://www.gdcvault.com/play/1024001/-Overwatch-Gameplay-Architecture-and
- Bevy replicon: https://docs.rs/bevy_replicon/latest/bevy_replicon/
- Lightyear: https://github.com/cBournhonesque/lightyear
- Gabriel Gambetta: https://www.gabrielgambetta.com/client-server-game-architecture.html
- Daniel Jimenez Morales hit registration: https://danieljimenezmorales.github.io/2023-10-29-the-art-of-hit-registration/
- Vermintide networking: https://forums.fatsharkgames.com/t/client-server-authoritative-networking/67657
- Simple WebRTC P2P game: https://github.com/kevglass/simple-webrtc-p2p-game
- WebRTC vs WebSocket benchmarks: https://blog.brkho.com/2017/03/15/dive-into-client-server-web-games-webrtc/
- Unity HasAuthority: https://docs.unity3d.com/Packages/com.unity.netcode.gameobjects@2.5/manual/basics/ownership.html
- Mirror remote actions: https://mirror-networking.gitbook.io/docs/manual/guides/communications/remote-actions
- FishNet server/client: https://fish-networking.gitbook.io/docs/guides/features/server-and-client-identification/executing-on-server-or-client

### Key Findings

**F1: Three-Layer Split (Universal)**
Every engine separates: Visual (all clients) / Predicted (client+server) / Authoritative (host only).

**F2: Vermintide Pattern (Simplest Effective)**
Client detects hit + shows visual → Server validates + applies damage. Best for small teams.

**F3: Authority Gate in TakeDamage, Not in Collision Handler**
Unity's canonical pattern: collision fires everywhere, but `TakeDamage()` has `if (!isServer) return;`. The gate is in the state mutation, not the detection.

**F4: Component Markers Over System Scheduling**
Mature ECS frameworks tag component types (Replicated/Local/Predicted) rather than gating entire systems.

**F5: Browser Host Works for <10 Players**
Star topology with WebRTC. Host runs full simulation + relay. No production-scale examples found.

## Round 2: Implementation

### Applied Fix: isHost() Gate Pattern

Added to CollisionBehaviours.hx:
```haxe
var isHost = function():Bool {
    return !GameState.isMultiplayer() || (gameContext.netState != null && gameContext.netState.isHost());
};
```

Every collision handler split into visual (all clients) + gameplay (host only):

| Handler | Visual (all) | Gameplay (host only) |
|---------|-------------|---------------------|
| Enemy×Player | gib splash | MSG_DAMAGE |
| NeutralHP×Fire | — | MSG_DAMAGE |
| Enemy×Bolt | bolt collided + gib splash | MSG_DAMAGE + knockback |
| Bolt×Player | bolt collided + gib splash | (via NetDamageable) |
| Fireball×Player | fireball collided + gib splash | MSG_DAMAGE + knockback |

### Remaining Work
- Item pickup server validation
- NPC death broadcast
- MG bullet collision handler (shares crossbow_bolt tag, may already work)

## Final Synthesis

The **isHost() gate pattern** is the right solution for khashooter's scale:
- Simple: one closure, applied to each handler
- Correct: matches the industry Vermintide pattern
- Backward-compatible: returns true in single-player
- Future-proof: if we add a dedicated server, change the gate to check server role

The more sophisticated patterns (component markers, system groups, rollback) are for larger games with 10+ developers. For a 2-person indie game, the per-handler gate with visual/gameplay split is the industry-recommended approach.
