# Build and Run Guide

## Prerequisites

- **Haxe 4.3.2** -- The compiler. Must be compatible with the Kha framework version used.
- **Node.js** -- Required by the Kha build system.
- **Kha framework** -- Located in the `Kha/` subdirectory (a git submodule or copy).
- **Python 3** -- For the local development server.

## Project Configuration

### khafile.js

The build configuration lives in `khafile.js` at the project root:

```javascript
var project = new Project('Empty');

project.addSources('./Sources');
project.addShaders('./Shaders');

project.addLibrary("nape-haxe4");   // Physics (not heavily used)
project.addLibrary('zui');          // Debug UI framework
project.addLibrary("yaml");         // YAML parsing for entity templates
project.addLibrary("dconsole");     // Debug console
project.addLibrary("hscript");      // Runtime scripting

project.addAssets('Assets/**', {
    nameBaseDir: 'Assets',
    destination: '{dir}/{name}',
    name: '{dir}/{name}'
});

project.windowOptions.width = 1300;
project.windowOptions.height = 800;
project.targetOptions.html5.disableContextMenu = true;

resolve(project);
```

**Libraries used:**
- `zui` -- UI library for debug tools (map editor, debug menu). Located in `Libraries/zui` as a submodule.
- `yaml` -- Parses entity template YAML files at runtime.
- `nape-haxe4` -- Physics library (available but not the primary collision system).
- `dconsole` -- In-game debug console.
- `hscript` -- Haxe script interpreter for runtime evaluation.

## Building

### HTML5 Target

```bash
node Kha/make html5 --haxe /usr/local/lib/haxe
```

This compiles the Haxe source to JavaScript and outputs to `build/html5/`.

The `--haxe` flag points to the Haxe installation directory. Adjust the path if your Haxe is installed elsewhere.

### Post-Build Fixes for index.html

After building, `build/html5/index.html` may need manual adjustments:

1. **Canvas size** -- The canvas element dimensions should match the window size defined in `khafile.js` (1300x800). If the generated HTML has different dimensions, update them:

   ```html
   <canvas id="khanvas" width="1300" height="800" style="width:1300px;height:800px"></canvas>
   ```

2. **Context menu** -- Right-click is used for the debug menu. If the browser context menu appears, ensure this is disabled. The `khafile.js` sets `disableContextMenu = true`, but verify the generated HTML includes the corresponding JavaScript.

## Running Locally

### Development Server

```bash
python3 -m http.server 8081 --directory build/html5
```

Then open `http://localhost:8081` in a browser.

Any static file server will work. The game runs entirely client-side.

## Testing

### Automated Testing with Playwright

```bash
node test_game.mjs http://localhost:8081 10
```

Arguments:
- First argument: URL where the game is served
- Second argument: Duration in seconds to run the test

This launches a headless browser, loads the game, and verifies it runs without errors for the specified duration.

## Known Build Issues

### Haxe 4.3.2 Compatibility

Several issues may arise when building with Haxe 4.3.2:

1. **Case-sensitive imports** -- Haxe 4.3.2 is stricter about import casing. File names must exactly match their package/class declarations. For example, if a file declares `package rendering;` and `class Camera`, it must be at `Sources/rendering/Camera.hx` (capital C).

2. **Color qualifiers** -- `kha.Color` constants (like `Color.Pink`, `Color.White`) may need full qualification or the correct access pattern depending on the Kha version.

3. **Stencil API changes** -- The stencil buffer API in `kha.graphics4` may have changed between Kha versions. The lighting system (`DS2D`) uses stencil operations for shadow rendering -- if you get stencil-related errors, check `DepthStencilFormat` usage.

4. **pushScale removal** -- Some versions of Kha removed `g2.pushScale()`. The code uses `pushTransformation(FastMatrix3.scale(...))` as a workaround.

### Audio: gun.ogg Issue

The file `Assets/sound/gun.ogg` is broken -- it is actually an MP3 file disguised with an `.ogg` extension. The proper fix would be to re-encode it as a real OGG Vorbis file using `oggenc`, but `oggenc` is x86-only and does not run natively on Apple Silicon (ARM) Macs.

Workarounds:
- Use a Docker x86 container to run `oggenc`
- Use `ffmpeg` instead: `ffmpeg -i gun.ogg gun_real.ogg`
- Remove or replace the sound file

The file is currently deleted from the working tree (shown as deleted in git status).

## Directory Structure

```
khashooter/
  Assets/
    entity/        -- YAML entity templates (Player.yaml, Zombie.yaml, etc.)
    map/           -- JSON level files (level2.json, rooms.json, etc.)
    sound/         -- Audio files
    sprite_configs.yaml
    config.yaml    -- Runtime configuration (camera settings, weapon stats, etc.)
  Sources/
    Main.hx        -- Entry point
    refraction/    -- ECS engine framework
      core/        -- Entity, Component, Sys, State, Application, TemplateParser
      display/     -- AnimatedRenderCmp, ResourceFormat, SurfaceSetCmp, LightSourceCmp
      generic/     -- PositionCmp, VelocityCmp, DimensionsCmp
      control/     -- KeyControl, RotationControl, Damping, BreadCrumbs
      systems/     -- RenderSys, SpacingSys, BreadCrumbsSys, LightSourceSystem, TooltipSys
      tilemap/     -- TileMap, TileCollisionSys, TileCollisionCmp, Tilesheet, DijkstraField
      ds2d/        -- DS2D lighting/shadow system, Polygon, LightSource
      utils/       -- Interval, other utilities
    rendering/     -- Low-level rendering (KhaVertexIndexer, Camera, TextureAtlas, Surface2D)
      pipelines/   -- GPU pipeline states (Tex2, Light, Shadow, Decrement)
    game/          -- Game-specific code
      GameState.hx          -- Main game loop (extends State)
      GameContext.hx         -- Singleton hub for all systems
      EntFactory.hx          -- Entity creation
      ShooterComponentFactory.hx  -- Component type registry
      CollisionBehaviours.hx -- Hit response definitions
      debug/                 -- MapEditor, DebugMenu, TilePalette, Toolbox
      behaviours/            -- AI (ZombieAI, MimiAI, LesserDemonBehaviour)
      weapons/               -- Weapon implementations
      dialogue/              -- Dialogue system
    components/    -- Game-specific components (Health, HitCircleCmp, Projectile, etc.)
    systems/       -- Game-specific systems (BeaconSys, HitTestSys, InteractSys, ParticleSys)
    helpers/       -- LevelLoader, ZombieResourceLoader, DebugLogger
    ui/            -- HealthBar
    entbuilders/   -- ItemBuilder
  Shaders/         -- GLSL shader files
  Libraries/       -- Local library overrides (zui)
  Kha/             -- Kha framework
  khafile.js       -- Build configuration
  build/           -- Build output (generated)
```
