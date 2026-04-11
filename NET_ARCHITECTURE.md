# NetBehaviour Architecture Assessment

## Verdict: Proceed with modifications

The proposed NetBehaviour component architecture is well-suited for AI-driven development. It scores highest on **discoverability** (the strongest property for AI agents) and **isolation**, with manageable risks around failure modes and migration.

---

## Proposed Architecture

### Components

**NetManager** (singleton) — thin message router:
- Owns NetClient + WebSocket connection
- Maps `netId → entity` via NetIdentity registry
- Routes incoming messages: `entity.notify("net:" + msgType, data)`
- Collects dirty state from all NetTransformSenders, batch-sends per frame
- Does NOT understand individual message types — just routes by netId

**NetIdentity** (component) — on every networked entity:
- `netId:String` — unique, stable (e.g. "player_0", "npc_mimi")
- `ownerId:Int` — which client owns it (-1 = host-owned)
- `isLocal:Bool` — does this client control this entity?
- `load()` registers with NetManager, `unload()` deregisters
- Replaces: remotePlayers map, array-index NPC matching

**NetTransformSender** (component) — on locally-controlled entities:
- Reads PositionCmp each frame, marks dirty if changed
- NetManager collects all dirty senders and batch-sends
- Replaces: `updateNetworking()` position writing code

**NetTransformReceiver** (component) — on remote entities:
- Holds SyncVars, receives position updates from NetManager
- Interpolates lerpValue each frame, writes to PositionCmp
- Replaces: the `for(id => rp)` loop in `updateNetworking()`

**NetDamageable** (component) — event-driven, no per-frame tick:
- Subscribes to "net:hit", "net:kill", "net:spawn" via `entity.on()`
- Applies health change, creates gib splash, applies knockback
- Replaces: onHit/onKill/onSpawn callbacks in initMultiplayer

**NetShootSender** (component) — on locally-controlled player:
- Subscribes to "weapon_fired" entity message
- Sends shoot event to NetManager
- Replaces: `GameContext.instance().netState.sendShoot()` calls in weapon classes

**NetShootReceiver** (component) — on remote players:
- Subscribes to "net:shoot" via entity.on()
- Spawns visual-only projectiles
- Replaces: onRemoteShoot callback

### Entity Templates

```yaml
# Player.yaml (local player) — add to existing
- type: NetIdentity
- type: NetTransformSender
- type: NetDamageable
- type: NetShootSender

# RemotePlayer.yaml (NEW — replaces autoBuild + disable pattern)
entity_name: RemotePlayer
base_entity: Actor
components:
- type: SurfaceSet
  resource: shiro
- type: AnimatedRender
  args:
    animations:
    - name: idle
      frames: [0]
    - name: running
      frames: [0, 1, 0, 2]
    initialAnimation: idle
    frameTime: 8
- type: NetIdentity
- type: NetTransformReceiver
- type: NetDamageable
- type: NetShootReceiver
```

---

## Assessment Criteria

### 1. Isolation — Strong (with modification)

Each component has a single responsibility. An AI agent modifying hit feedback only touches `NetDamageable.hx`. 

**Critical modification**: NetManager must NOT have message-type-specific routing logic. Instead, it routes via `entity.notify("net:" + msgType, data)` and components subscribe in their `load()` method. This keeps NetManager thin and prevents it from growing with every new feature.

### 2. Testability — Moderate

The existing Playwright test infrastructure relies on `[NET:*]` console logs. Each NetBehaviour component should emit its own `[NET:*]` log (e.g., NetDamageable logs `[NET:HIT]`, NetTransformReceiver logs `[NET:RECV_POS]`). This is actually better than centralized logging because each log is co-located with its logic.

**Key risk**: Migration must preserve existing log format strings or tests break silently. Each migration phase should run the full test suite before proceeding.

### 3. Discoverability — Excellent (strongest property)

The naming convention `Net + Domain + Sender/Receiver` makes the right file obvious:

| Task | File |
|------|------|
| "Add knockback when hit" | `NetDamageable.hx` |
| "Fix position jitter" | `NetTransformReceiver.hx` |
| "Players can't see each other's shots" | `NetShootReceiver.hx` |
| "Sync weapon switching" | Create `NetWeaponSender.hx` + `NetWeaponReceiver.hx` |

Compare to current: "add knockback when hit" requires finding the `onHit` callback buried in `GameState.initMultiplayer()` line 136 of a 786-line file.

### 4. Extensibility — Good (O(3) files for new features)

Adding a new synced feature (e.g., weapon switching):
1. Create `NetWeaponSender.hx` — reads weapon state, sends when changed
2. Create `NetWeaponReceiver.hx` — receives weapon state, updates entity
3. Register in `ShooterComponentFactory.hx`
4. Add to entity YAML templates

NetManager stays untouched. O(3) files, each following the same template.

### 5. Failure Modes — Biggest risk area

| Failure | Impact | Mitigation |
|---------|--------|------------|
| Message arrives for removed entity | Null crash | NetIdentity.unload() deregisters from NetManager. NetManager checks entity exists before routing. |
| Components added in wrong order | NetTransformReceiver can't find NetIdentity | Defer registration to first update() if NetIdentity not found in load() |
| Late hit message on dead entity | Double-death | NetDamageable checks health > 0 before applying damage |
| Disconnected peer, stale SyncVars | Ghost player stops moving | NetManager receives disconnect, calls entity.remove() |

### 6. Migration Risk — High, but incrementally mitigatable

**5-phase incremental migration**:

| Phase | Add | Remove | Risk |
|-------|-----|--------|------|
| 0 | NetManager + NetIdentity (parallel to NetState) | Nothing | None — both systems run |
| 1 | NetTransformSender + Receiver | updateNetworking() position code | Medium — most complex phase |
| 2 | NetDamageable | onHit/onKill/onSpawn callbacks | Low |
| 3 | NetShootSender + Receiver | Weapon sendShoot calls, onRemoteShoot callback | Low |
| 4 | Cleanup | NetState, remotePlayers map | Low |

Each phase runs the full Playwright test suite. Roll back if tests fail.

### 7. Compatibility with Refraction ECS — Good fit

- **Component lifecycle**: `load()` for registration, `unload()` for deregistration — matches existing pattern
- **Entity message system**: `entity.on("net:hit", handler)` — already used by Health component
- **System management**: Use a single `NetSys extends Sys<NetComponent>` for per-frame components (transform sync). Event-driven components (damage, shooting) need no Sys — they just register message handlers in `load()`
- **ShooterComponentFactory**: Adding net component registrations follows the existing pattern exactly

**Friction point**: Refraction's `Sys<T>` is generic over a single type. Solution: create a `NetComponent extends Component` base class. Components needing per-frame ticks extend NetComponent and go in one NetSys. Event-driven components extend Component directly.

### 8. Compared to Alternatives

| Approach | Discoverability | Isolation | Migration Risk | AI-Friendliness |
|----------|----------------|-----------|---------------|-----------------|
| **NetBehaviour components** (proposed) | Excellent | Strong | High but incremental | Best |
| Organized callbacks (refactor current) | Poor | Weak | Low | Scales poorly |
| Global message bus | Poor (implicit) | Maximum | Medium | Hard to trace |
| State machines | Moderate | Strong | High | Overengineered |

---

## Key Design Decisions

1. **NetManager is a thin router**, not a god object. It maps netId → entity and calls `entity.notify()`. It never learns about specific message types.

2. **Use entity.notify() for incoming messages**, not direct method calls. This leverages Refraction's existing message bus and keeps components decoupled.

3. **Create a RemotePlayer.yaml template** instead of building a full Player and disabling components. This eliminates the fragile "build then strip" pattern.

4. **One NetSys for per-frame components**, entity.on() for event-driven ones. Don't create a Sys per net component type.

5. **Preserve [NET:*] log format strings** throughout migration to keep Playwright tests working.

6. **NetIdentity.unload() must deregister** from NetManager to prevent null-entity crashes.
