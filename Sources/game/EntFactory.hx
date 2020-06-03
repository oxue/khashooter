package game;

import helpers.DebugLogger;
import refraction.core.Utils;
import refraction.display.LightSourceComponent;
import kha.math.Vector2;
import refraction.control.*;
import refraction.core.Entity;
import refraction.display.AnimatedRender;
import refraction.generic.*;
import refraction.tile.TileRender;
import refraction.tile.TileCollision;
import refraction.tile.TilemapData;
import entbuilders.ItemBuilder;
import components.Interactable;
import components.Projectile;
import components.HitCircle;
import refraction.core.Application;
import refraction.systems.SpacingSys.Spacing;
import haxe.ds.StringMap;
import refraction.core.Component;
import refraction.core.ComponentFactory;
import refraction.core.TemplateParser;
import refraction.display.ResourceFormat;
import game.GameContext;
import game.EntFactory;
import game.Consts;

/**
 * ...
 * @author
 */
class EntFactory {
	private static var myInstance:EntFactory = null;

	public static function instance(?_gc:GameContext, ?_factory:ComponentFactory):EntFactory {
		if (myInstance == null) {
			myInstance = new EntFactory(_gc, _factory);
		}
		return myInstance;
	}

	public static function destroyInstance() {
		myInstance = null;
	}

	public var gameContext:GameContext;
	public var factory:ComponentFactory;

	private var entityPrototypes:Dynamic;
	private var itemBuilder:ItemBuilder;
	private var entityTemplates:StringMap<Dynamic>;

	public function new(_gc:GameContext, _factory:ComponentFactory) {
		gameContext = _gc;
		factory = _factory;
		itemBuilder = new ItemBuilder(gameContext);
		entityTemplates = TemplateParser.parse();
	}

	public function reloadEntityBlobs():Void {
		TemplateParser.reloadEntityBlobs("../../Assets/entity", (templateMap) -> {
			this.entityTemplates = templateMap;
			DebugLogger.info("IO", "Entity Blobs Reloaded");
		});
	}

	public function worldMouse():Vector2 {
		return new Vector2(cast Application.mouseX / 2 + gameContext.camera.x,
			cast Application.mouseY / 2 + gameContext.camera.y);
	}

	public function createItem(_x, _y):Entity {
		return itemBuilder.create2(_x, _y, 0);
	}

	public function autoComponent(_type:String, _settings:Dynamic, _e:Entity):Component {
		if (_type == "SurfaceSet") {
			return _e.addComponent(ResourceFormat.surfacesets.get(_settings.resource), _settings.name);
		}

		var ret:Component = factory.get(_type, _e, _settings.name);
		if (_settings.args != null) {
			ret.autoParams(_settings.args);
		}
		return ret;
	}

	public function autoBuild(_entityName:String, _e:Entity = null):Entity {
		if (entityTemplates
			.get(_entityName)
			.base_entity != null
		) {
			_e = autoBuild(entityTemplates
				.get(_entityName)
				.base_entity
			);
		}
		if (_e == null)
			_e = new Entity();

		var components:Array<Dynamic> = entityTemplates
			.get(_entityName)
			.components;

		for (component in components) {
			autoComponent(component.type, component, _e);
		}
		return _e;
	}

	public function createNPC(_x:Int = 0, _y:Int = 0, name:String) {
		var e:Entity = autoBuild("Actor")
			.getComponent(Position)
			.setPosition(_x, _y)
			.getEntity();
		e.addComponent(ResourceFormat.surfacesets.get(name));

		var surfaceRender:AnimatedRender = new AnimatedRender();
		e.addComponent(surfaceRender);

		surfaceRender.animations.set("idle", [0]);
		surfaceRender.animations.set("running", [0, 1, 0, 2]);
		surfaceRender.frameTime = 8;
		surfaceRender.frame = 0;

		gameContext.renderSystem.addComponent(surfaceRender);

		var npc = new Interactable(gameContext.camera, function(e) {
			trace("Asd");
		});
		e.addComponent(npc);

		gameContext.interactSystem.addComponent(npc);

		gameContext.breadCrumbsSystem
			.procure(e, BreadCrumbs)
			.autoParams({
				acceptanceRadius: Consts.BREADCRUMB_ACCEPTANCE_DISTANCE,
				maxAcceleration: Consts.BREADCRUMB_ZOMBIE_MAX_ACCEL
			});

		gameContext.collisionSystem
			.procure(e, TileCollision)
			.autoParams({tilemap: gameContext.tilemapData});
		gameContext.aiSystem.procure(e, MimiAI);
		gameContext.tooltipSystem
			.procure(e, Tooltip)
			.autoParams({
				message: name,
				color: kha.Color.Pink
			});
	}

	public function createFireball(_position:Vector2, direction:Vector2):Entity {
		var e = new Entity();
		var e:Entity = new Entity();
		var offsetLight = Std.int(gameContext.config.flamethrower_fireball_size / 2);

		e.addComponent(new Position(_position.x, _position.y, 10, 10, Utils.direction2Degrees(direction)));
		var lightSource = new LightSourceComponent(gameContext.lightingSystem, 0x5500ff,
			gameContext.config.flamethrower_starting_size, offsetLight, offsetLight);
		e.addComponent(lightSource);
		gameContext.lightSourceSystem.addComponent(lightSource);

		var velocity = gameContext.velocitySystem.procure(e, Velocity);
		direction.normalize();
		direction = direction.mult(Consts.CROSSBOW_PROJECTILE_SPEED);
		velocity.setVelX(direction.x);
		velocity.setVelY(direction.y);

		var dimensions = new Dimensions(gameContext.config.flamethrower_fireball_size,
			gameContext.config.flamethrower_fireball_size);

		e.addComponent(dimensions);

		var damping = gameContext.dampingSystem.procure(e, Damping);
		DebugLogger.info("DAMPING", gameContext.config);
		damping.autoParams({factor: gameContext.config.flamethrower_damping});
		gameContext.environmentSystem.procure(e, FireComponent);
		gameContext.collisionSystem
			.procure(e, TileCollision)
			.autoParams({tilemap: gameContext.tilemapData});

		return e;
	}

	public function createProjectile(_position:Vector2, direction:Vector2):Entity {
		var e:Entity = new Entity();
		e.addComponent(new Position(_position.x, _position.y, 10, 10, Utils.direction2Degrees(direction)));
		e.addComponent(ResourceFormat.surfacesets.get("projectiles"));
		var lightSource = new LightSourceComponent(gameContext.lightingSystem, 0x2222ff, 10, 0, 0);
		e.addComponent(lightSource);
		gameContext.lightSourceSystem.addComponent(lightSource);

		var surfaceRender = gameContext.selfLitRenderSystem.procure(e, AnimatedRender);
		surfaceRender.autoParams({
			"animations": [{name: "bolt", frames: [0]},],
			"initialAnimation": "bolt",
			"surface": null,
			"frameTime": 8
		});

		var velocity = gameContext.velocitySystem.procure(e, Velocity);
		direction.normalize();
		direction = direction.mult(Consts.CROSSBOW_PROJECTILE_SPEED);
		velocity.setVelX(direction.x);
		velocity.setVelY(direction.y);

		gameContext.hitCheckSystem
			.procure(e, Projectile)
			.tilemapData = gameContext.tilemapData;
		gameContext.hitTestSystem
			.procure(e, HitCircle)
			.autoParams({
				tag: Consts.PLAYER_BOLT,
				radius: 3
			});

		return e;
	}

	public function createTilemap(_width:Int, _height:Int, _tilesize:Int, _colIndex:Int,
			_data:Array<Array<Int>>, _tileset:String = "all_tiles"):Entity {
		var e:Entity = new Entity();

		var tilemapData:TilemapData = new TilemapData(_width, _height, _tilesize, _colIndex);
		e.addComponent(tilemapData);
		tilemapData.setDataIntArray(_data);
		e.addComponent(ResourceFormat.surfacesets.get(_tileset));

		var tileRender:TileRender = new TileRender();
		tileRender.targetCamera = gameContext.camera;
		e.addComponent(tileRender);

		gameContext.currentMap = tileRender;
		gameContext.tilemapData = tilemapData;
		gameContext.collisionSystem.setTilemap(tilemapData);

		return e;
	}
}
