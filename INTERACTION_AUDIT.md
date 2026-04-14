# Interaction Audit — Network Correctness

## Scorecard

| Status | Count | Interactions |
|--------|-------|-------------|
| **CORRECT** | 3 | Bolt→Player, Weapon Switch, Player Movement |
| **MIXED** | 4 | Fire→NPC, Fire→Player, Weapon Pickup, Player Shoots |
| **BROKEN** | 8 | Bolt→NPC, MG→NPC, MG→Player, Fireball→Player, Melee→Player, Player Dies, Player Respawns, NPC Dies |
| **NOT IMPL** | 1 | NPC Interaction (Mimi) |
| **PARTIAL** | 2 | Player Disconnect, Crate Destroyed |

## Priority Fixes

### P0 — Game-Breaking

| # | Issue | Root Cause | Fix |
|---|-------|-----------|-----|
| 14 | Player death not handled in MP | Health._callback disabled, no kill event from host | Host must detect health ≤ 0 in hit detection, send kill event |
| 15 | Player can't respawn | Server never sends spawn event after kill | Host sends spawn event after kill (SupabaseTransport.doHitDetection already does this) |
| 8 | NPC melee modifies remote player directly | CollisionBehaviours applies damage to any entity | Guard: only apply if entity is locally owned |

### P1 — Major Bugs  

| # | Issue | Root Cause | Fix |
|---|-------|-----------|-----|
| 1 | Bolt→NPC: initiator modifies NPC health | Collision handler applies damage directly | Only host should process NPC damage |
| 3,4 | MG bullets don't hit anything | No collision handler for MG bullets vs players/NPCs | MG bullets share `crossbow_bolt` tag — handler exists for bolt→player but not bolt→NPC in MP context |
| 7 | Demon fireball modifies player directly | Collision handler applies damage + knockback | Visual only on initiator; host sends hit event |

### P2 — Desync Issues

| # | Issue | Root Cause | Fix |
|---|-------|-----------|-----|
| 5,17 | Fire damage only on host | Collision runs on all clients but should only on host | Gate damage behind `isHost` check |
| 9 | Item pickup not server-validated | Client removes item locally | Host validates, broadcasts removal |
| 18 | NPC death not broadcast | Host removes NPC, stops sending position | Add explicit npc_died broadcast |

## The Pattern

Most bugs follow one of two anti-patterns:

### Anti-Pattern 1: "Observer applies effect"
```
// WRONG — in CollisionBehaviours
onHit(BOLT, ENEMY, (bolt, enemy) -> {
    enemy.notify(MSG_DAMAGE, {amount: -10});  // We don't own enemy!
});
```
**Fix:** Gate behind ownership check:
```
onHit(BOLT, ENEMY, (bolt, enemy) -> {
    bolt.notify(MSG_COLLIDED);  // We own the bolt — OK
    createGibSplash(enemy.pos);  // Visual — OK
    // Damage applied by host only, via server hit detection
});
```

### Anti-Pattern 2: "Missing host authority"
```
// WRONG — collision runs on ALL clients
onHit(FIRE, NPC, (fire, npc) -> {
    npc.notify(MSG_DAMAGE, ...);  // Every client does this independently
});
```
**Fix:** Only host processes gameplay collisions:
```
onHit(FIRE, NPC, (fire, npc) -> {
    if (!GameState.isHost()) return;  // Only host decides
    npc.notify(MSG_DAMAGE, ...);
    broadcastNpcDamage(npc.id, damage);  // Tell others
});
```

## Systematic Fix Strategy

Instead of fixing each interaction individually, add a **global guard** to CollisionBehaviours:

1. **Split handlers into VISUAL and GAMEPLAY:**
   - Visual (all clients): remove projectile, create gib splash, play sound
   - Gameplay (host only): apply damage, modify health, trigger death

2. **Add `isHost` gate to all gameplay handlers:**
   ```haxe
   function defineCollisionBehaviours(gameContext:GameContext) {
       var isHost = () -> !GameState.isMultiplayer() || gameContext.netState.isHost();
       
       onHit(BOLT, ENEMY, (bolt, enemy) -> {
           // Visual — all clients
           bolt.notify(MSG_COLLIDED);
           createGibSplash(enemy.pos);
           // Gameplay — host only  
           if (isHost()) {
               enemy.notify(MSG_DAMAGE, {amount: -10});
               knockback(enemy, direction);
           }
       });
   }
   ```

3. **Host broadcasts damage to non-host clients** for entities they don't own (NPCs, remote players).

This pattern covers interactions #1, #3, #5, #7, #8, #17 with minimal code changes.
