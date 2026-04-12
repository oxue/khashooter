# Player Lifecycle — Clean Architecture

## Current Problems

The current code has 3 separate spawn paths, 2 death paths, and asymmetric respawn logic:

| Event | Local Player | Remote Player |
|-------|-------------|---------------|
| Initial spawn | LevelLoader.spawnPlayer() | N/A |
| Network connect | GameState.onReady adds net components | N/A |
| Remote join | N/A | GameState.spawnRemotePlayer() |
| Death | Health triggers "death" → LevelLoader respawns | NetDamageable.onKill → entity.remove() |
| Respawn | LevelLoader creates NEW entity | GameState.onSpawn creates NEW entity |

This causes:
- Entity references go stale after respawn (old entity removed, new one created, but systems hold old refs)
- Net components lost after respawn (added once in onReady, not re-added on new entity)
- Double death triggers (Health callback + NetDamageable both fire)

## Design: Single PlayerSpawner

One function that handles ALL player creation for both local and remote:

```
PlayerSpawner.spawnLocal(x, y, name) → Entity
PlayerSpawner.spawnRemote(id, x, y) → Entity
PlayerSpawner.despawn(entity) → void
PlayerSpawner.respawnLocal(x, y) → Entity  // calls despawn + spawnLocal
PlayerSpawner.respawnRemote(id, x, y) → Entity  // calls despawn + spawnRemote
```

### spawnLocal(x, y, name):
1. autoBuild("Player") → entity
2. Set position (x, y)
3. Create HealthBar
4. Equip crossbow
5. Set gameContext.playerEntity = entity
6. Return entity
(Net components added separately by onReady — this is fine since they only need to be added once per connection)

### spawnRemote(id, x, y):
1. autoBuild("RemotePlayer") → entity  
2. Set position (x, y)
3. Add NetIdentity, NetTransformReceiver, NetDamageable, NetShootReceiver
4. Set gameContext.remotePlayers[id] = entity
5. Return entity

### despawn(entity):
1. entity.remove() — marks all components for cleanup
2. NetIdentity.unload() auto-deregisters from NetManager

### respawnLocal(x, y):
1. despawn(old entity)
2. spawnLocal(x, y, name) → new entity
3. Re-add net components if connected (NetIdentity, TransformSender, Damageable, ShootSender)
4. Update gameContext.playerEntity

### respawnRemote(id, x, y):
1. despawn(old entity if exists)
2. remotePlayers.remove(id)
3. spawnRemote(id, x, y) → new entity

## Death/Respawn Flow

```
Server detects kill → sends 'kill' to victim + all clients
                    → sends 'spawn' to victim with new position

Client receives 'kill':
  → Kill feed + scoreboard (game-wide UI)
  → Gib splash at entity position
  → Do NOT destroy entity yet (wait for spawn)

Client receives 'spawn':
  → If local: PlayerSpawner.respawnLocal(x, y)
  → If remote: PlayerSpawner.respawnRemote(id, x, y)

This means:
  - Death is visual-only (gib splash) — entity stays until respawn
  - Respawn is the authoritative lifecycle event
  - No race condition between kill and spawn
  - Server controls both timing and position
```

## What Changes

1. Remove the `entity.on("death", ...)` listener in LevelLoader — server handles respawn
2. Remove `entity.remove()` from NetDamageable.onKill — wait for spawn
3. Health component's `_callback` (entity.remove) should be disabled in multiplayer
4. Create PlayerSpawner class with the functions above
5. All spawn/respawn flows go through PlayerSpawner
6. GameState callbacks become one-liners that call PlayerSpawner
