# Refraction ECS Engine Guide

This document describes how the custom "Refraction" Entity-Component-System framework works in the khashooter project. The engine source lives in `Sources/refraction/`.

## Core Architecture

### Component (`Sources/refraction/core/Component.hx`)

The base class for all components. Key features:

- **`remove: Bool`** -- Flag checked by systems during iteration; when true the component is removed from the system's list.
- **`entity: Entity`** -- Back-reference to the owning entity, set automatically by `Entity.addComponent()`.
- **`load()`** / **`unload()`** -- Lifecycle hooks called when a component is added to or removed from an entity.
- **`update()`** -- Default per-frame update (called by `Sys.updateComponent()` unless overridden).
- **`autoParams(args: Dynamic)`** -- Override this to accept YAML-driven configuration. The args object comes directly from the entity template's `args:` block.
- **`notify(msgType, msgData)`** -- Event system: components can register handlers with `on()` and receive messages propagated from the entity.

```haxe
class Component {
    public var remove:Bool;
    public var entity:Entity;
    public function autoParams(_args:Dynamic) {}
    public function load() {}
    public function unload() {}
    public function update() {}
    public function notify(_msgType:String, _msgData:Dynamic) { ... }
    public function on(_msgType:String, _msgHandler:Dynamic->Void) { ... }
}
```

### Entity (`Sources/refraction/core/Entity.hx`)

An entity is a bag of named components with an event bus.

- **`components: Map<String, Component>`** -- Components keyed by their fully-qualified class name (or a custom name if provided).
- **`addComponent(comp, ?name)`** -- Adds a component, sets `comp.entity = this`, and calls `comp.load()`. Throws if a component with that name already exists.
- **`getComponent<T>(type, ?name)`** -- Fast O(1) lookup by class name or custom name. Returns `null` if not found.
- **`linSearchType<T>(type)`** -- Slower linear search by runtime type check (for when the name doesn't match).
- **`notify(msgType, ?msgData)`** -- Broadcasts a message to all components on the entity. Used for damage, collision, death events, etc.
- **`on(msgType, handler)`** -- Register an entity-level event handler (checked before component handlers).
- **`remove()`** -- Marks all components for removal by calling `unload()` and setting `remove = true`.

```haxe
// Example: getting a component
var pos:PositionCmp = entity.getComponent(PositionCmp);

// Example: sending a message to all components
entity.notify("damage", {amount: -10});
```

### Sys<T> -- System (`Sources/refraction/core/Sys.hx`)

A generic system that owns and iterates over an array of components of type `T`.

- **`components: Array<T>`** -- The live list of components this system manages.
- **`procure<G>(entity, type, ?name, ?default)`** -- Creates a new component instance (via `Type.createInstance`), adds it to the entity, and registers it with this system. This is the standard way to create components that belong to a system.
- **`update()`** -- Iterates all components. Removes any with `remove == true` (swap-with-last for O(1) removal), and calls `updateComponent()` on the rest.
- **`updateComponent(comp)`** -- Virtual method; default implementation calls `comp.update()`. Override this in subclasses for custom system logic.
- **`sweepRemoved()`** -- Alternative bulk removal using `Array.filter()`.

```haxe
// The update loop removes dead components in-place:
public function update() {
    l = components.length;
    var i:Int = 0;
    while (i < l) {
        if (components[i].remove) {
            components[i] = components[--l];  // swap with last
            continue;
        }
        updateComponent(components[i]);
        ++i;
    }
    while (components.length > l) components.pop();
}
```

Many systems in the game are plain `Sys<Component>` instances (e.g., `controlSystem`, `aiSystem`, `environmentSystem`). Specialized systems subclass `Sys` and override `update()` or `updateComponent()` -- for example:

- **`RenderSys`** (`Sources/refraction/systems/RenderSys.hx`) -- Overrides `update()` to call `c.draw(camera)` instead of `c.update()`.
- **`TileCollisionSys`** -- Handles tile-based collision detection.
- **`HitTestSys`** -- Circle-vs-circle hit detection with callback registration via `onHit(tagA, tagB, callback)`.
- **`ParticleSys`** -- Manages particle lifespans.

### State (`Sources/refraction/core/State.hx`)

A game state with four virtual methods:

```haxe
class State {
    public function load() {}
    public function unload() {}
    public function update() {}
    public function render(frame:Framebuffer) {}
}
```

The active state is set via `Application.setState(state)`, which calls `unload()` on the old state and `load()` on the new one.

### Application (`Sources/refraction/core/Application.hx`)

The static singleton that drives the game loop.

- **`init(title, width, height, zoom, callback)`** -- Initializes input state and screen dimensions.
- **`update()`** -- Called by `kha.Scheduler` at 60 FPS. Delegates to `currentState.update()`. Computes edge-triggered mouse flags (`mouseJustDown`, `mouse2JustDown`, etc.).
- **`render(frame)`** -- Called by `kha.System.notifyOnFrames`. Delegates to `currentState.render()`. Clears edge-triggered flags after render.
- **`setState(state)`** -- Transitions between states.
- **Input** -- Tracks `keys: Map<Int, Bool>`, `mouseIsDown`, `mouse2IsDown`, mouse coordinates, and provides listener registration (`addKeyDownListener`, `addKeyUpListener`, `addMouseDownListener`, `addMouseUpListener`).

The main entry point (`Sources/Main.hx`) wires it all together:

```haxe
System.start({title: "Pew Pew", width: 1300, height: 800}, (window) -> {
    Mouse.get().notify(Application.mouseDown, Application.mouseUp, Application.mouseMove, null);
    Keyboard.get().notify(Application.keyDown, Application.keyUp);
    Scheduler.addTimeTask(Application.update, 0, 1 / 60);
    System.notifyOnFrames(Application.render);

    Application.init("Pew Pew", 1300, 800, 2, () -> {
        KhaVertexIndexer.init(...);
        ResourceFormat.init();
        Application.setState(new GameState());
    });
});
```

## Entity Templates (YAML) and autoBuild

### TemplateParser (`Sources/refraction/core/TemplateParser.hx`)

At startup, `TemplateParser.parse()` scans `kha.Assets.blobs` for all blob names matching `entity_*.yaml`, parses them with the `yaml` library, and returns a `StringMap<Dynamic>` keyed by `entity_name`.

YAML entity files live in `Assets/entity/`. Examples:

- `Assets/entity/Actor.yaml` -- Base entity with Position, Dimensions, Velocity, Spacing, Damping
- `Assets/entity/Player.yaml` -- Extends Actor with rendering, controls, inventory, health, etc.
- `Assets/entity/Zombie.yaml` -- Extends Actor with AI, hitcircles, breadcrumbs
- `Assets/entity/Blood.yaml` -- Particle entity with velocity and damping

### Template Format

```yaml
---
entity_name: Player
base_entity: Actor          # optional: inherits all components from Actor first
components:
- type: SurfaceSet           # component type name (matched in ShooterComponentFactory)
  resource: shiro            # type-specific fields
- type: AnimatedRender
  name: null                 # optional custom component name
  args:                      # passed to component.autoParams()
    animations:
    - name: idle
      frames: [0]
    - name: running
      frames: [0, 1, 0, 2]
    initialAnimation: idle
    surface: null
    frameTime: 8
- type: KeyControl
  args:
    speed: 1
- type: Health
  args:
    maxValue: 100
```

### autoBuild (`Sources/game/EntFactory.hx`)

`EntFactory.autoBuild(entityName)` is the main entity creation method:

1. If the template has `base_entity`, recursively call `autoBuild(base_entity)` first to create the base entity.
2. Create a new `Entity` (or reuse the one from the base).
3. Iterate the `components` array and call `autoComponent(type, settings, entity)` for each one.
4. Return the fully assembled entity.

```haxe
public function autoBuild(_entityName:String, ?_e:Entity):Entity {
    if (entityTemplates.get(_entityName).base_entity != null) {
        _e = autoBuild(entityTemplates.get(_entityName).base_entity);
    }
    if (_e == null) { _e = new Entity(); }

    var components:Array<Dynamic> = entityTemplates.get(_entityName).components;
    for (component in components) {
        autoComponent(component.type, component, _e);
    }
    return _e;
}
```

### autoComponent

`autoComponent()` handles two cases:
1. **SurfaceSet** -- Loads a sprite resource from `ResourceFormat.surfacesets` and adds it directly.
2. **Everything else** -- Delegates to `ComponentFactory.get(type, entity, name)`, then calls `ret.autoParams(args)` if args are provided.

### ComponentFactory (`Sources/refraction/core/ComponentFactory.hx`)

Abstract base class with a single method `get(type, entity, name)`. The game-specific implementation is:

### ShooterComponentFactory (`Sources/game/ShooterComponentFactory.hx`)

Maps string type names to lambda functions that create and register components with the correct system:

```haxe
typeToMethodMap.set("AnimatedRender",
    (e, name) -> gameContext.renderSystem.procure(e, AnimatedRenderCmp, name));
typeToMethodMap.set("KeyControl",
    (e, name) -> gameContext.controlSystem.procure(e, KeyControl, name));
typeToMethodMap.set("TileCollision",
    (e, name) -> gameContext.collisionSystem.procure(e, TileCollisionCmp, name));
typeToMethodMap.set("Health",
    (e, name) -> e.addComponent(new Health()));
// ... etc for all ~18 component types
```

The `get()` override looks up the type in the map and calls the corresponding factory function. Components that need system registration use `system.procure(entity, Type, name)`. Components that are standalone (like Health, Inventory, Position, Dimensions) just use `e.addComponent(new Foo())`.

**Registered component types:**
| YAML Type | Component Class | System |
|-----------|----------------|--------|
| AnimatedRender | AnimatedRenderCmp | renderSystem |
| AnimatedRender/SelfLit | AnimatedRenderCmp | selfLitRenderSystem |
| RotationControl | RotationControl | controlSystem |
| KeyControl | KeyControl | controlSystem |
| PlayerAnimation | PlayerAnimation | controlSystem |
| TileCollision | TileCollisionCmp | collisionSystem |
| Velocity | VelocityCmp | velocitySystem |
| Spacing | SpacingCmp | spacingSystem |
| Damping | Damping | dampingSystem |
| HitCircle | HitCircleCmp | hitTestSystem |
| BreadCrumbs | BreadCrumbs | breadCrumbsSystem |
| Beacon | Beacon | beaconSystem |
| ZombieAI | ZombieAI | aiSystem |
| MimiAI | MimiAI | aiSystem |
| LesserDemonBehaviour | LesserDemonBehaviour | aiSystem |
| Particle | ParticleCmp | particleSystem |
| LightSource | LightSourceCmp | lightSourceSystem |
| Position | PositionCmp | (none -- standalone) |
| Dimensions | DimensionsCmp | (none -- standalone) |
| Health | Health | (none -- standalone) |
| Inventory | InventoryCmp | (none -- standalone) |

## How to Add a New Component and System

### Step 1: Create the Component

Create a new file in `Sources/components/` or `Sources/game/`:

```haxe
package components;

import refraction.core.Component;

class MyNewCmp extends Component {
    public var someValue:Float;

    override public function autoParams(_args:Dynamic) {
        someValue = _args.someValue;
    }

    override public function update() {
        // Per-frame logic (if using default Sys.updateComponent)
    }
}
```

### Step 2: (Optional) Create a Custom System

If you need custom update logic beyond `component.update()`:

```haxe
package systems;

import refraction.core.Sys;
import components.MyNewCmp;

class MyNewSys extends Sys<MyNewCmp> {
    override public function updateComponent(comp:MyNewCmp) {
        // Custom per-component logic
        comp.someValue += 1;
    }
}
```

### Step 3: Register in GameContext

Add the system to `Sources/game/GameContext.hx`:

```haxe
public var myNewSystem:Sys<MyNewCmp>;  // or MyNewSys

// In the constructor:
myNewSystem = new Sys<MyNewCmp>();     // or new MyNewSys()
```

### Step 4: Register in ShooterComponentFactory

Add a mapping in `Sources/game/ShooterComponentFactory.hx`:

```haxe
typeToMethodMap.set("MyNew",
    (e:Entity, name:String) -> gameContext.myNewSystem.procure(e, MyNewCmp, name)
);
```

### Step 5: Add to Update Loop

In `Sources/game/GameState.hx`, add the system update call in the appropriate position:

```haxe
override public function update() {
    // ... existing systems ...
    gameContext.myNewSystem.update();
}
```

### Step 6: Use in YAML Templates

```yaml
- type: MyNew
  args:
    someValue: 42
```

## Event / Message System

Entities and components share a simple pub/sub message bus:

```haxe
// Register a handler on an entity
entity.on("death", function(data) { /* respawn logic */ });

// Register a handler on a component
component.on("damage", function(data) { health -= data.amount; });

// Broadcast to entity + all its components
entity.notify("damage", {amount: -10});
```

This is used for damage, collision responses, death, and other game events. The collision system (`CollisionBehaviours.hx`) uses `entity.notify("damage", ...)` and `entity.notify("collided")` to communicate hit results.

## Hot Reloading

The engine supports runtime reloading of data:

- **F9** -- Reloads `config.yaml` from disk (`TemplateParser.reloadConfigurations`)
- **F10** -- Reloads all entity YAML templates from disk (`TemplateParser.reloadEntityBlobs`)
- **Debug Menu > Reload Graphics** -- Reloads all asset images with cache-busting query strings
