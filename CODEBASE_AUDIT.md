# Codebase Audit — Blow/Carmack Review

**Audited:** ~9,000 lines across 100+ files  
**Perspective:** Jonathan Blow's "write specific code, not general code" + Carmack's "minimize state, inline when possible"  
**Score:** 4/10 — it works but is unmaintainable

## Philosophy Applied

Blow: "Writing an ECS is something programmers do instead of writing the game." The Refraction ECS has become ceremony that makes every feature change cascade across 5+ files. The ECS itself isn't the problem — it's that the ECS is over-generalized while the game code is under-structured.

Carmack: "The real enemy is unexpected dependency and mutation of state." GameContext is a 30-field mutable singleton accessed from everywhere. Any system can modify any state at any time. No function is pure.

## Priority Issues (Fix Now)

### 1. ACTUAL BUGS

| Bug | File | Line | Impact |
|-----|------|------|--------|
| `position.x` should be `position.y` | MimiAI.hx | 37 | NPCs walk wrong direction |
| Same bug | ZombieAI.hx | 66 | NPCs walk wrong direction |
| Infinite loop if all weapons disabled | InventoryCmp.hx | 48-56 | Game freezes |
| `.add(new Vector2(0, 0))` does nothing | Weapon.hx | 44 | Dead code |
| WayPointFollow imports non-existent classes | WayPointFollow.hx | 10-11 | Broken component |

### 2. DEAD CODE (Remove)

| File | Lines | Reason |
|------|-------|--------|
| PhysState.hx | 78 | Nape physics, completely unused |
| RenderTargetState.hx | 26 | Never referenced |
| PhysicsCmp.hx | 23 | Nape integration, unused |
| Values.hx | 15 | One method, should inline |
| AmmunitionObject.hx | 41 | Created but never consumed |
| WayPointFollow.hx | 97 | Broken imports, Flash code |
| ObjectPool.hx | Has `trace("pool get")` | Debug statement in production |
| NullSystem in Sys.hx | 16 | Defined but never used |
| ComponentFactory.hx | 15 | Returns null, stub class |

### 3. COPY-PASTE CODE (Consolidate)

**Weapons** — HuntersCrossbow, MachineGun, Flamethrower each duplicate:
- `calcMuzzlePosition()` + `muzzleDirection()` call
- `atan2 * (180 / 3.1415926)` direction calculation
- `gc.playerEntity.notify("weapon_fired", {...})` call
- **Fix:** Move to base Weapon class

**Items** — ItemBuilder.createHuntersCrossbow/Flamethrower/MachineGun:
- 70+ lines, 90% identical
- Only differences: animation frame, tooltip text, enum value
- **Fix:** Single `createWeaponItem(type)` method

**Hit detection** — Duplicated 3x in server/index.js, PeerHost.hx, SupabaseTransport.hx:
- Same ray-cast algorithm, same radii, same damage logic
- **Fix:** Extract to shared utility

### 4. FRAMEWORK-GAME COUPLING (Decouple)

Framework files that import `game.GameContext` (violates layering):
- `refraction/control/KeyControl.hx` — accesses `config.system.noclip`
- `refraction/ds2d/DS2D.hx` — accesses `gameContext.camera`
- `refraction/ds2d/LightSource.hx` — accesses `lightingSystem.globalRadius`
- `refraction/core/ComponentFactory.hx` — takes GameContext in constructor

**Fix:** Inject configuration/dependencies instead of importing game singletons.

### 5. STRINGLY-TYPED APIs (Replace with types)

| Pattern | Examples | Fix |
|---------|----------|-----|
| Collision tags | `"player"`, `"enemy"`, `"crossbow_bolt"` | Enum |
| AI states | `"idle"`, `"attacking"`, `"roaming"` | Enum |
| Entity messages | `"damage"`, `"death"`, `"weapon_fired"` | Typed events |
| Beacon tags | `"player"`, `"remote_player"` | Enum |
| Component names | `"weapon_render"`, `"pos_comp"` | Type-safe lookup |

### 6. GOD OBJECTS (Split)

**GameState.hx (768 lines)** — does everything:
- Asset loading, input, game loop, rendering (g2+g4 interleaved 5x), UI, debug, camera, multiplayer, NPC sync, dialogue, chat, scoreboard
- **Fix:** Split rendering into RenderPipeline, networking into NetworkManager, input into InputHandler

**GameContext.hx (210 lines, 30+ fields)** — holds everything:
- Every system, every manager, every piece of state
- **Fix:** Domain-specific contexts or just pass dependencies directly

**EntFactory.hx (384 lines)** — builds everything:
- 10+ creation methods, each 20-40 lines of component assembly
- **Fix:** Data-driven entity templates should handle this without code

## Medium Priority (Fix Soon)

### 7. PERFORMANCE

- SpacingSys has O(n²) all-pairs loop (no spatial hashing)
- `Math.pow()` in tight loop (use multiplication instead)
- Pi hardcoded as `3.14159` / `3.1415` / `3.1415926` (use Math.PI)
- AnimatedRenderCmp.time increments forever (never resets)

### 8. MISSING ERROR HANDLING

- WebRTC data channel has no `onerror` handler
- NetState doesn't clean up on disconnect (stale remotePlayers)
- No message validation (Dynamic types trusted without field checks)
- Client can spoof `msg.from` player ID (no server validation)

### 9. TRANSPORT LAYER MESS

Three parallel transports (WebSocket, Supabase, WebRTC) with no shared interface:
- NetClient.send() cascades through if-else chain
- Hit detection duplicated 3x
- **Fix:** Extract Transport interface, consolidate host logic

### 10. RENDERING PIPELINE

5 switches between g2 and g4 in one render frame:
```
g4.begin → vertex draw → g4.end
g2.begin → player draw → g2.end  
lighting render (g4)
g4.begin → self-lit draw → g4.end
g2.begin → labels → g2.end
g2.begin → UI → g2.end
```
**Fix:** Batch into render passes

## Low Priority (Tech Debt)

- 10 documentation files, some outdated
- README.md is empty (just "# Empty")
- Shaders/ directory referenced in khafile.js but doesn't exist
- Unused sprite assets (man.png, pippy.png, etc.)
- Debug menu/map editor ships in production
- No unit tests (Playwright integration tests only)
- All singletons (GameContext, EntFactory, NetManager)

## Refactor Plan

### Phase 1: Bug fixes + dead code removal (~30 min)
- Fix MimiAI/ZombieAI position bug
- Fix InventoryCmp infinite loop
- Remove dead files (PhysState, RenderTargetState, PhysicsCmp, etc.)
- Remove dead code in WayPointFollow
- Clean up debug traces

### Phase 2: Copy-paste consolidation (~30 min)
- Consolidate weapon fire logic into base Weapon class
- Consolidate ItemBuilder into single parameterized method
- Consolidate hit detection into shared utility

### Phase 3: Framework decoupling (~30 min)
- Remove GameContext imports from refraction/
- Inject noclip config via component params
- Inject camera/lighting via method params

### Phase 4: Validate (~15 min)
- Build
- Run test_suite.mjs
- Run test_gameplay.mjs
- Verify single-player and multiplayer work
