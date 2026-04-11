# Game Architecture

This document describes how the khashooter game is structured on top of the Refraction ECS engine.

## Startup Sequence

The game boots through this chain (`Sources/Main.hx`):

1. `kha.System.start()` -- Initializes the Kha runtime with a 1300x800 window.
2. Wire input handlers: Mouse and Keyboard events -> `Application.mouseDown/mouseUp/mouseMove/keyDown/keyUp`.
3. Register the update task at 60 FPS: `Scheduler.addTimeTask(Application.update, 0, 1/60)`.
4. Register the render callback: `System.notifyOnFrames(Application.render)`.
5. `Application.init()` with zoom=2 (so internal resolution is 650x400).
6. `KhaVertexIndexer.init()` -- Sets up GPU vertex/index buffers and pipeline states.
7. `ResourceFormat.init()` -- Initializes sprite resource format system.
8. `Application.setState(new GameState())` -- Enters the main game state.

On macOS, the window size is doubled (2600x1600) to account for Retina displays.

## GameState -- The Main Game Loop (`Sources/game/GameState.hx`)

`GameState` extends `refraction.core.State` and is the central orchestrator.

### load()

Called once when the state is activated:

1. `Assets.loadEverything()` -- Loads all assets, then calls `onLoadAssets()`.
2. `onLoadAssets()`:
   - Creates a `Zui` instance for debug UI.
   - Creates the game `Camera` at half the screen resolution (650x400).
   - Initializes `GameContext` singleton (the hub for all systems).
   - Calls `formatResources()` -> `ZombieResourceLoader.load()` to set up sprite sheets.
   - Initializes `EntFactory` singleton with `ShooterComponentFactory`.
   - Creates `LevelLoader` and calls `loadMap()`.
   - Calls `defineCollisionBehaviours()` to register hit response callbacks.
   - Creates the `MapEditor`.
   - Creates the `DijkstraField` pathfinding grid.
   - Sets up periodic intervals (e.g., pathfinding target update every 60 frames).
   - Configures debug key bindings.

### update() -- Per-Frame Logic

The system update order is critical for correct behavior. Here is the exact order:

```
1.  controlSystem.update()       -- Player input, rotation, animation
2.  spacingSystem.update()       -- Entity spacing/separation forces
3.  dampingSystem.update()       -- Velocity damping (friction)
4.  velocitySystem.update()      -- Apply velocity to position
5.  collisionSystem.update()     -- Tile-based collision resolution
6.  environmentSystem.update()   -- Environment effects (fire, etc.)
7.  lightSourceSystem.update()   -- Update light source positions
8.  particleSystem.update()      -- Particle lifespan management
9.  breadCrumbsSystem.update()   -- Pathfinding breadcrumb following
10. hitCheckSystem.update()      -- Projectile hit checking
11. aiSystem.update()            -- AI behaviors (zombie, mimi, demon)
12. hitTestSystem.update()       -- Circle-vs-circle collision detection + callbacks
13. beaconSystem.update()        -- Named entity beacon tracking
14. intervals                    -- Periodic tasks (Dijkstra field recalculation)
15. persistentAction             -- Continuous fire while mouse is held
```

Additionally, `interactSystem.update()` is called on mouse-down (in `mouseDown()`) rather than every frame, and the player's `primaryAction()` fires on click.

### render() -- Per-Frame Rendering

The render pipeline has several distinct passes:

```
1. UPDATE CAMERA
   - Apply camera shake
   - Follow player position with damping
   - Compute world mouse coordinates

2. TILEMAP + ENTITY PASS (g4 / KhaVertexIndexer)
   - Begin g4 context
   - Set Tex2 pipeline (textured quad shader)
   - Set projection matrix and texture atlas
   - Render tilemap (gameContext.tilemap.render)
   - Render all entities in renderSystem (AnimatedRenderCmp.draw via KhaVertexIndexer)
   - Flush vertex buffer (KhaVertexIndexer.draw)
   - End g4

3. PLAYER PASS (g2)
   - Draw player's AnimatedRenderCmp separately with g2
   - (Player is rendered between entity pass and lighting so it appears correctly)

4. LIGHTING PASS (DS2D)
   - lightingSystem.renderSceneWithLighting()
   - Renders shadow volumes from tilemap polygons
   - Applies light sources with stencil-based shadow casting
   - Composites lighting onto the scene

5. SELF-LIT ENTITY PASS (g4 / KhaVertexIndexer)
   - Begin g4 context again
   - Set same Tex2 pipeline
   - Render selfLitRenderSystem (weapon sprites, projectiles, etc.)
   - These render ON TOP of the lighting, so they appear to glow
   - Flush and end g4

6. UI PASS
   - Right-click handling (toggle debug menu)
   - Game UI (g2): health bar, dialogue, status text, tooltips
   - Debug UI: hitboxes, Dijkstra map visualization, Zui windows
   - Map editor UI (if active)
```

## GameContext -- The System Hub (`Sources/game/GameContext.hx`)

`GameContext` is a singleton (`GameContext.instance()`) that holds references to every system and shared game state. It is the central dependency injection point.

### Systems

| Field | Type | Purpose |
|-------|------|---------|
| `renderSystem` | RenderSys | Main entity rendering |
| `selfLitRenderSystem` | RenderSys | Entities rendered after lighting (glow) |
| `controlSystem` | Sys<Component> | Player controls, rotation, animation |
| `velocitySystem` | Sys<VelocityCmp> | Applies velocity to position |
| `dampingSystem` | Sys<Damping> | Velocity friction |
| `collisionSystem` | TileCollisionSys | Tile-based AABB collision |
| `interactSystem` | InteractSys | Clickable entity interactions |
| `breadCrumbsSystem` | BreadCrumbsSys | Pathfinding breadcrumb following |
| `aiSystem` | Sys<Component> | AI behaviors |
| `lightSourceSystem` | LightSourceSystem | Dynamic light source management |
| `beaconSystem` | BeaconSys | Named entity lookup (e.g., "player") |
| `particleSystem` | ParticleSys | Particle lifecycle |
| `environmentSystem` | Sys<Component> | Environmental effects |
| `spacingSystem` | SpacingSys | Entity separation forces |
| `tooltipSystem` | TooltipSys | Hover tooltips |
| `lightingSystem` | DS2D | 2D shadow/lighting renderer |
| `hitCheckSystem` | Sys<Component> | Projectile hit checks |
| `hitTestSystem` | HitTestSys | Circle collision + callbacks |

### Shared State

| Field | Type | Purpose |
|-------|------|---------|
| `camera` | Camera | Game camera (position, shake, follow) |
| `tilemap` | TileMap | Current level tilemap |
| `dijkstraMap` | DijkstraField | Pathfinding field for AI |
| `tilemapShadowPolys` | Array<Polygon> | Precomputed shadow geometry |
| `playerEntity` | Entity | Reference to the player entity |
| `config` | Dynamic | Parsed config.yaml (weapon stats, etc.) |
| `values` | Values | Computed game values from config |
| `worldMouseX/Y` | Int | Mouse position in world coordinates |
| `shouldDrawHitBoxes` | Bool | Debug hitbox rendering toggle |
| `reloadGraphics` | Bool | Flag to trigger asset reload |

### UI/Debug

| Field | Type | Purpose |
|-------|------|---------|
| `statusText` | StatusText | On-screen status messages |
| `healthBar` | HealthBar | Player health UI |
| `dialogueManager` | DialogueManager | NPC dialogue system |
| `debugMenu` | DebugMenu | Right-click debug menu |
| `ui` | Zui | UI framework instance |

## EntFactory -- Entity Creation (`Sources/game/EntFactory.hx`)

Singleton (`EntFactory.instance()`) responsible for creating all game entities.

### Key Methods

- **`autoBuild(entityName)`** -- Creates an entity from a YAML template. Supports inheritance via `base_entity`. This is the primary creation method.
- **`createFireball(pos, dir)`** -- Manually creates a flamethrower fireball entity with light source, velocity, damping, collision, and hit circle.
- **`createProjectile(pos, dir)`** -- Creates a crossbow bolt with light, rendering, velocity, and hit detection.
- **`createBullet(pos, dir)`** -- Creates a machine gun bullet (uses autoBuild("MGBullet") + manual light source).
- **`spawnProjectile(name, pos, dir)`** -- Generic projectile spawning from YAML template + config-driven speed.
- **`createItem(x, y, type)`** -- Creates pickup items (delegates to ItemBuilder).
- **`createNPC(x, y, name)`** -- Creates an NPC with rendering, interaction, breadcrumbs, collision, AI, and tooltip.
- **`createTilemap(width, height, ...)`** -- Creates the TileMap and registers it with GameContext.
- **`createGibSplash(amount, pos)`** -- Spawns blood particles.
- **`reloadEntityBlobs()`** -- Hot-reloads entity YAML templates from disk.

## Level System

### Level Files (`Assets/map/`)

Levels are JSON files. Available maps: `level2.json`, `bloodstrike_zm.json`, `modern_home.json`, `rooms.json`.

JSON structure:

```json
{
  "data": [[261, 322, ...], [291, 2, ...], ...],  // 2D array of tile indices
  "width": 28,
  "height": 17,
  "tilesize": 16,
  "tileset_name": "mine_tiles",          // sprite resource name for tiles
  "original_tilesheet_name": "mine_tiles", // tilesheet image name
  "col_index": 255,                      // tile index threshold for collision
  "start": {"x": 30, "y": 100},         // player spawn position
  "warps": [{"x": 15, "y": 260, "level": "level.json"}],  // level transitions
  "zombies": [{"x": 15, "y": 215}, ...],  // enemy spawn positions
  "lights": [{"x": 100, "y": 100, "color": 16777215, "radius": 200}]  // static lights
}
```

Key fields:
- **`data`** -- 2D grid of tile indices. Each integer maps to a tile in the tilesheet.
- **`tileset_name`** -- Which sprite resource to use for tile rendering (e.g., "mine_tiles", "all_tiles").
- **`col_index`** -- Tiles with index >= this value are treated as solid (collidable). This is how walls are defined.
- **`tilesize`** -- Pixel size of each tile (typically 16).
- **`start`** -- Player spawn coordinates in pixels.

### LevelLoader (`Sources/helpers/LevelLoader.hx`)

`LevelLoader` handles loading and saving level data:

1. **`loadMap()`**:
   - Reads the JSON from `Assets.blobs.map_{name}_json`
   - Calls `spawnTilemap()` to create the TileMap entity
   - Calls `spawnPlayer()` to create the player from the "Player" YAML template at `start` position
   - Computes shadow polygons from tilemap geometry (`TilemapUtils.computeGeometry`)
   - Spawns static lights from the `lights` array
   - Spawns hardcoded items at the start position (HuntersCrossbow, Flamethrower, MachineGun)
   - Creates an NPC ("mimi")

2. **`export()`** -- Saves the current tilemap state as a JSON file (downloads in browser).

3. **`spawnPlayer()`** -- Creates the player entity and sets up a death handler that respawns.

4. **Level transitions** -- `GameState.loadLevel(mapName)` destroys the current `EntFactory` and `GameContext` singletons, resets key listeners, and creates a fresh `GameState` with the new map.

## Collision System

### Tile Collision

`TileCollisionSys` checks entity hitboxes against the tilemap grid. Components of type `TileCollisionCmp` specify hitbox offsets. Tiles with indices >= `col_index` are solid.

### Hit Detection (Circle-vs-Circle)

`HitTestSys` manages `HitCircleCmp` components, each tagged with a string (e.g., "player", "enemy", "fire", "crossbow_bolt").

### Collision Behaviours (`Sources/game/CollisionBehaviours.hx`)

Hit response callbacks are registered with `hitTestSystem.onHit(tagA, tagB, callback)`:

```haxe
// Enemy touches player -> damage + gibs
hitTestSystem.onHit("enemy", "player", (enemy, player) -> {
    player.notify("damage", {amount: -1});
    entFactory.createGibSplash(1, player.getComponent(PositionCmp));
});

// Fire hits neutral_hp -> fire damage
hitTestSystem.onHit("neutral_hp", "fire", (entity, fire) -> {
    entity.notify("damage", {amount: -config.fireball_damage, type: "fire"});
});

// Crossbow bolt hits enemy -> damage + knockback + gibs
hitTestSystem.onHit("enemy", "crossbow_bolt", (enemy, bolt) -> {
    enemy.notify("damage", {amount: -10});
    bolt.notify("collided");
    entFactory.createGibSplash(...);
    knockback(enemy, bolt rotation);
});

// Demon fireball hits player -> damage + knockback
hitTestSystem.onHit("demon_fireball", "player", (fireball, player) -> { ... });
```

**Hit group tags:**
- Entities: `player`, `enemy`, `neutral_hp`, `pickupable`
- Projectiles: `fire`, `crossbow_bolt`, `demon_fireball`

## Rendering Refactor: hxblit -> rendering

The codebase has been refactored from an older rendering module called `hxblit` to a new `rendering` package. The old `Sources/hxblit/` directory has been deleted (visible in git status).

Key renames:
| Old (hxblit) | New (rendering) |
|-------------|-----------------|
| `hxblit.KhaBlit` | `rendering.KhaVertexIndexer` |
| `hxblit.Camera` | `rendering.Camera` |
| `hxblit.Surface2D` | `rendering.Surface2D` |
| `hxblit.SurfaceData` | `rendering.SurfaceData` |
| `hxblit.TextureAtlas` | `rendering.TextureAtlas` |
| `hxblit.Utils` | `rendering.Utils` |
| `hxblit.pipelines.*` | `rendering.pipelines.*` |

`KhaVertexIndexer` is the core GPU rendering interface. It manages vertex/index buffers and pipeline states for batched quad rendering using Kha's g4 (graphics4) API. All sprite rendering goes through it.

The rendering pipeline uses these GPU pipeline states (in `Sources/rendering/pipelines/`):
- **Tex2PipelineState** -- Standard textured quad rendering (used for sprites and tiles).
- **LightPipelineState** -- Renders light volumes.
- **ShadowPipelineState** -- Renders shadow geometry into the stencil buffer.
- **DecrementPipelineState** -- Decrements stencil values (part of the shadow algorithm).

Custom fragment shaders live in `Shaders/` (e.g., `tex2.frag.glsl`).

## AI and Pathfinding

### Dijkstra Field

`DijkstraField` (`Sources/refraction/tilemap/DijkstraField.hx`) computes a vector field pointing toward the player. Updated every 60 frames:

1. Get the player's tile position.
2. Set it as the Dijkstra target.
3. Propagate distance values.
4. Smooth the field.

AI entities (zombies) use `BreadCrumbs` to follow the field toward the player.

### AI Behaviors

- **`ZombieAI`** (`Sources/game/behaviours/ZombieAI.hx`) -- Basic zombie that chases the player.
- **`MimiAI`** (`Sources/game/behaviours/MimiAI.hx`) -- NPC companion behavior.
- **`LesserDemonBehaviour`** (`Sources/game/behaviours/LesserDemonBehaviour.hx`) -- Demon enemy that shoots fireballs.

## Debug Tools

### Map Editor (P key)

Toggle with the **P** key. Provides:
- **Tile Palette** -- Select tiles to paint.
- **Toolbox** -- Paint, erase, and other editing tools. Includes export functionality to save modified maps.
- **Entity Library** -- Spawn entities from the template library.
- **Level Selector** -- Quick-load different levels (level2, bloodstrike_zm, modern_home, rooms).
- **Grid Overlay** -- Shows tile grid around the cursor.
- **Layout persistence** -- Editor window positions are saved/loaded from `layout.json`.

### Debug Menu (Right-Click)

Right-click anywhere to open a context menu with:
- **Reload Graphics** -- Hot-reload all image assets.
- **Spawn Crate** -- Place a crate entity at cursor position with a light source.
- **Play Dialogue / Advance Dialogue** -- Test the dialogue system.
- **Teleport Here** -- (Currently commented out) Move player to cursor.
- **Spawn Hell Minion** -- Spawn a zombie at cursor.
- **Reload Entity Blobs** -- Hot-reload YAML entity templates (same as F10).
- **Reload Config Blobs** -- Hot-reload config.yaml (same as F9).
- **Spawn Several Gyo** -- Spawn 5 Gyo enemies at cursor.
- **Spawn Light Source** -- Place a dynamic light at cursor.
- **Blood Particles** -- Spawn blood particle effects at cursor.
- **Ambient Level slider** -- Adjust global ambient light level.
- **Clear Lights** -- Remove all dynamic lights.
- **Draw Hitboxes checkbox** -- Toggle hitbox/debug visualization.

### Keyboard Shortcuts

| Key | Action |
|-----|--------|
| P | Toggle map editor |
| F9 | Reload config.yaml |
| F10 | Reload entity YAML templates |
| Right-click | Toggle debug menu |
| +/- | Adjust global light radius |

## Weapons System

Weapons are managed through `InventoryCmp` on the player entity. The weapon implementations live in `Sources/game/weapons/`:

- **HuntersCrossbow** -- Fires crossbow bolts (projectiles with light).
- **Flamethrower** -- Fires fireballs with area-of-effect fire damage.
- **MachineGun** -- Rapid-fire bullets.
- **Empty** -- No weapon equipped.

Weapons support `primaryAction()` (on click) and `persistentAction()` (while mouse held).

## Configuration

### config.yaml

Runtime-editable configuration parsed by `TemplateParser.parseConfig()`. Accessed as `gameContext.config.*`. Contains weapon stats, camera settings, projectile parameters, and other tunable values. Can be hot-reloaded with F9.

### Entity Templates

YAML files in `Assets/entity/` define entity archetypes. See ENGINE_GUIDE.md for full details on the template format and autoBuild system.

Available entity templates:
- **Actor** -- Base entity (position, dimensions, velocity, spacing, damping)
- **Player** -- Full player entity (extends Actor)
- **Zombie** -- Basic enemy (extends Actor)
- **Gyo** -- Another enemy type
- **LesserDemon** -- Ranged demon enemy
- **Wallman** -- Wall-based enemy
- **Crate** -- Destructible crate
- **Blood** -- Blood particle
- **MGBullet** -- Machine gun bullet
- **DemonFireball** -- Demon projectile
