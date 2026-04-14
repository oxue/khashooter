# Network Principles — Lessons from Khashooter

## The Core Rule

**Every gameplay effect has exactly one authority, and that authority applies the effect to itself.**

An effect should never be applied by the observer. The entity experiencing the effect applies it, triggered by a message from the authority.

## The Knockback Example

### Wrong (what we had):
```
Shooter's client detects bolt hit → calls knockback(remotePlayer)
```
Problem: The remote player's position comes from the network. Any local velocity change is immediately overwritten by the next position sync. The knockback is invisible.

### Right (what it should be):
```
1. Shooter's client: bolt hits remote player hitcircle
   → Visual only: remove bolt, create gib splash
   → NO gameplay effect on the remote entity

2. Server: ray-cast detects hit
   → Sends to victim: {type: "hit", damage: 10, health: 90, dir: 45.0}

3. Victim's client receives hit event
   → Applies knockback to OWN velocity (they own their physics)
   → Reduces own health display
   → Creates gib splash on self
```

## The Three-Way Split

Every interaction in a multiplayer game has three locations where code runs. Each location has a specific responsibility:

### 1. The INITIATOR (shooter, attacker, interactor)
**Responsibility: Visual feedback only**
- Remove projectile on contact
- Play muzzle flash, sound effect
- Send the action event to server
- Do NOT modify any other entity's state

### 2. The AUTHORITY (server)
**Responsibility: Validate and decide**
- Verify the action is valid (is the shooter alive? is the target in range?)
- Calculate the outcome (damage amount, direction, new health)
- Send the result to affected clients
- Do NOT render anything

### 3. The RECIPIENT (victim, target)
**Responsibility: Apply the effect to self**
- Receive the result from server
- Apply to own entity (health, velocity, position, status)
- Create feedback effects (gib splash, hit flash, knockback)
- The recipient OWNS their entity — only they modify it

## Decision Table

For any new interaction, fill in this table:

| Interaction | Initiator does | Server does | Recipient does |
|-------------|---------------|-------------|----------------|
| **Shoot** | Create projectile, send shoot event | Ray-cast hit detection, send hit to victim | — |
| **Get hit** | — | — | Apply damage, knockback, gib splash |
| **Die** | — | Send kill + spawn events | Play death effect, wait for spawn |
| **Respawn** | — | Assign position, send spawn | Create fresh entity at position |
| **Pick up item** | Send pickup request | Validate, remove item, send confirm | Add to inventory |
| **Chat** | Send message | Broadcast to all | Display message |
| **Move** | Update own position, send to server | Relay to others | Interpolate remote position |

## The "Who Owns This Entity?" Test

Before writing any gameplay code, ask: **who owns the entity being modified?**

- If you own it → modify it directly
- If someone else owns it → send a message, let them modify it
- If the server owns it → send a request, server decides

```
Local player entity     → owned by YOU → modify directly
Remote player entity    → owned by THEM → visual only, wait for their updates
NPC entity (host)       → owned by HOST → only host modifies, syncs to others
Projectile              → owned by CREATOR → creator handles physics
Pickup item             → owned by SERVER → request to pick up
```

## The "What If Two Clients Disagree?" Test

If two clients could reach different conclusions about an interaction, the server must decide:

- **Hit detection**: Shooter thinks they hit, victim thinks they dodged → server ray-casts authoritatively
- **Item pickup**: Two players grab the same item → server decides who gets it
- **Kill credit**: Two players shoot the same target → server assigns kill to first hit

If only one client cares (visual-only effects), no server involvement needed:
- Particle effects, screen shake, UI feedback → client-only, no sync needed

## Anti-Patterns to Avoid

### 1. "Apply and sync"
```
// WRONG: modify remote entity, hope the sync catches up
remotePlayer.getComponent(Health).value -= 10;
```
The remote player's health comes from the network. Your local change gets overwritten next frame.

### 2. "Observe and act"
```
// WRONG: observe a collision on someone else's entity and apply effects
onHit(HG_BOLT, HG_PLAYER, function(bolt, player) {
    player.knockback(direction); // player isn't yours to modify
});
```
The collision handler should only affect entities you own (the bolt). The player effect comes from the server.

### 3. "Mixed responsibility"
```
// WRONG: one function does both visual and gameplay
function onBoltHitPlayer(bolt, player) {
    bolt.remove();           // Visual — OK, bolt is ours
    player.damage(10);       // Gameplay — WRONG, player isn't ours
    createGibSplash(player); // Visual — OK (cosmetic, no state change)
}
```
Split into: initiator removes bolt + creates splash. Server sends damage. Recipient applies damage.

## Applying to New Features

When adding any new multiplayer interaction:

1. **Identify the entities involved** and who owns each
2. **Fill in the three-way table** (initiator/server/recipient)
3. **Visual effects go on the observer** (anyone can create particles)
4. **State changes go on the owner** (only the owner modifies their entity)
5. **Validation goes on the server** (server decides if the action is valid)
6. **Use entity.notify("net:eventName", data)** for received events
7. **Add [NET:] logs** for every network event for Playwright testing
