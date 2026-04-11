# Khashooter - Development Guide

## Quick Start

```bash
# Build the game (HTML5 target, requires system Haxe 4.3.2)
node Kha/make html5 --haxe /usr/local/lib/haxe

# IMPORTANT: Fix index.html after every build (Kha overwrites it)
# Canvas must be 1300x800, tabindex=0, with contextmenu prevention

# Serve the game
python3 -m http.server 8081 --directory build/html5

# Start the multiplayer server
node server/index.js  # runs on port 3000

# Play multiplayer
# Open: http://localhost:8081?server=ws://localhost:3000

# Run multiplayer tests (starts its own server)
node test_multiplayer.mjs
```

## Architecture

- **Language**: Haxe, compiled to JS for HTML5 via the Kha framework
- **Bundled Haxe**: 4.0.5 (at Kha/Tools/haxe/) — DO NOT USE, has compatibility issues
- **System Haxe**: 4.3.2 — always use `--haxe /usr/local/lib/haxe`
- **ECS Framework**: Custom "Refraction" in Sources/refraction/
- **Rendering**: Custom vertex indexer (Sources/rendering/KhaVertexIndexer.hx)
- **Multiplayer**: WebSocket client-server with SyncVar interpolation (Sources/net/)

## Key Files

| File | Purpose |
|------|---------|
| `Sources/game/GameState.hx` | Main game loop, render pipeline, networking integration |
| `Sources/game/GameContext.hx` | Singleton hub for all systems, config, state |
| `Sources/game/EntFactory.hx` | Entity creation from YAML templates |
| `Sources/game/ShooterComponentFactory.hx` | Maps component type strings to system.procure() calls |
| `Sources/net/NetState.hx` | Network state manager, SyncVars, remote player tracking |
| `Sources/net/NetClient.hx` | WebSocket client wrapper with [NET:] logging |
| `Sources/net/SyncVar.hx` | Synchronized value with lerp interpolation |
| `server/index.js` | Node.js WebSocket relay server with ray-cast hit detection |
| `khafile.js` | Kha build config (sources, shaders, assets, window size) |

## Haxe 4.3.2 Gotchas

When adding code, watch out for these Haxe 4.3.2 issues that don't exist in 4.0.5:
- **Case-sensitive module names**: filename must match class name exactly (TileMap.hx not Tilemap.hx)
- **Color enum members**: use `kha.Color.Green` not bare `Green`
- **Stencil API**: use `stencilMode`/`stencilBothPass`, not `stencilFrontMode`/`stencilBackMode`
- **No pushScale**: use `pushTransformation(FastMatrix3.scale(x, y))` instead
- **catch syntax**: use `catch(e:Dynamic)` not `catch(_)`

## Build Output Fix

After every `node Kha/make html5`, the generated `build/html5/index.html` resets to default. Must be overwritten with:
```html
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8"/>
    <title>Khashooter</title>
    <style>body{margin:0;overflow:hidden;background:#000}canvas{display:block}</style>
</head>
<body>
    <canvas id="khanvas" width="1300" height="800" tabindex="0"></canvas>
    <script src="kha.js"></script>
    <script>
        var c=document.getElementById('khanvas');c.focus();
        c.addEventListener('contextmenu',function(e){e.preventDefault();return false});
    </script>
</body>
</html>
```

## Multiplayer Architecture

- **Model**: Client-authoritative input, server-relay with host authority for NPCs
- **Host**: First connected client runs AI/pathfinding systems, sends NPC positions
- **Non-host**: Receives NPC positions from network, only runs visual systems
- **SyncVar**: Port of ck's C0 pattern — value + delta + lerpValue for smooth interpolation
- **Send rate**: 20Hz (every 3 frames at 60fps) for player state, 10Hz for NPCs
- **Hit detection**: Server-side ray-cast along shoot direction

## Testing

```bash
# Single-player smoke test (no server needed)
node test_game.mjs http://localhost:8081 10

# Multiplayer 2-tab test (starts its own server on port 3000)
node test_multiplayer.mjs
```

Tests verify: connection, player discovery, position sync, shooting sync, no page errors.

## Adding a New Component

1. Create `Sources/components/MyComponent.hx` extending `refraction.core.Component`
2. Register in `Sources/game/ShooterComponentFactory.hx`:
   ```haxe
   typeToMethodMap.set("MyComponent", (e, name) -> gameContext.mySystem.procure(e, MyComponent, name));
   ```
3. Add to entity YAML: `- type: MyComponent`
4. If it needs a system, create one extending `Sys<MyComponent>` and add to GameContext

## Debug Controls

- **P**: Toggle map editor
- **Right-click**: Debug menu (spawn entities, lights, reload configs)
- **F9**: Reload game config
- **F10**: Reload entity templates
- **Q/E**: Switch weapons
