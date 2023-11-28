package game;

import components.HitCircleCmp;
import components.InteractableCmp;
import components.Particle;
import components.Projectile;
import entbuilders.ItemBuilder;
import game.CollisionBehaviours.HG_CROSSBOW_BOLT;
import game.CollisionBehaviours.HG_FIRE;
import game.behaviours.MimiAI;
import haxe.ds.StringMap;
import helpers.DebugLogger;
import kha.math.Vector2;
import refraction.control.*;
import refraction.core.Application;
import refraction.core.Component;
import refraction.core.ComponentFactory;
import refraction.core.Entity;
import refraction.core.TemplateParser;
import refraction.core.Utils;
import refraction.display.AnimatedRenderCmp;
import refraction.display.LightSourceCmp;
import refraction.display.ResourceFormat;
import refraction.generic.*;
import refraction.tilemap.TileCollisionCmp;
import refraction.tilemap.TileMap;
import refraction.tilemap.Tilesheet;

/**
 * ...
 * @author
 */
class EntFactory {

	static var M_INSTANCE:EntFactory = null;

	public static function instance(?_gc:GameContext, ?_factory:ComponentFactory):EntFactory {
		if (M_INSTANCE == null) {
			M_INSTANCE = new EntFactory(_gc, _factory);
		}
		return M_INSTANCE;
	}

	public static function destroyInstance() {
		M_INSTANCE = null;
	}

	public var gameContext:GameContext;
	public var factory:ComponentFactory;

	var entityPrototypes:Dynamic;
	var itemBuilder:ItemBuilder;
	var entityTemplates:StringMap<Dynamic>;

	public function new(_gc:GameContext, _factory:ComponentFactory) {
		gameContext = _gc;
		factory = _factory;
		itemBuilder = new ItemBuilder(gameContext);
		entityTemplates = TemplateParser.parse();
	}

	public function getEntityTemplates():StringMap<Dynamic> {
		return entityTemplates;
	}

	public function reloadEntityBlobs() {
		TemplateParser.reloadEntityBlobs("../../Assets/entity", (templateMap) -> {
			this.entityTemplates = templateMap;
			DebugLogger.info("IO", "Entity Blobs Reloaded");
		});
	}

	public function worldMouse():Vector2 {
		var invZoom:Float = 1 / Application.getScreenZoom();
		return {
			x: cast Application.mouseX * invZoom + gameContext.camera.x,
			y: cast Application.mouseY * invZoom + gameContext.camera.y
		};
	}

	public function createItem(_x, _y, itemType:Items):Entity {
		if (itemType == Items.Flamethrower) {
			return itemBuilder.createFlameThrower(_x, _y);
		}

		if (itemType == Items.HuntersCrossbow) {
			return itemBuilder.createHuntersCrossbow(_x, _y);
		}

		if (itemType == Items.MachineGun) {
			return itemBuilder.createMachineGun(_x, _y);
		}

		return null;
	}

	public function autoComponent(_type:String, _settings:Dynamic, _e:Entity):Component {
		if (_type == "SurfaceSet") {
			return _e.addComponent(
				ResourceFormat.surfacesets.get(_settings.resource),
				_settings.name
			);
		}

		var ret:Component = factory.get(_type, _e, _settings.name);
		if (_settings.args != null) {
			ret.autoParams(_settings.args);
		}
		return ret;
	}

	public function autoBuild(_entityName:String, ?_e:Entity):Entity {
		if (entityTemplates
			.get(_entityName)
			.base_entity != null
		) {
			_e = autoBuild(entityTemplates
				.get(_entityName)
				.base_entity
			);
		}
		if (_e == null) {
			_e = new Entity();
		}

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
			.getComponent(PositionCmp)
			.setPosition(_x, _y)
			.getEntity();
		e.addComponent(ResourceFormat.surfacesets.get(name));

		var surfaceRender:AnimatedRenderCmp = new AnimatedRenderCmp();
		e.addComponent(surfaceRender);

		surfaceRender.animations.set("idle", [0]);
		surfaceRender.animations.set("running", [0, 1, 0, 2]);
		surfaceRender.frameTime = 8;
		surfaceRender.frame = 0;

		gameContext.renderSystem.addComponent(surfaceRender);

		var npc = new InteractableCmp(gameContext.camera, function(e) {
			trace("Asd");
		});
		e.addComponent(npc);

		gameContext.interactSystem.addComponent(npc);

		gameContext.breadCrumbsSystem
			.procure(e, BreadCrumbs, null, new BreadCrumbs())
			.autoParams({
				acceptanceRadius: Consts.BREADCRUMB_ACCEPTANCE_DISTANCE,
				maxAcceleration: Consts.BREADCRUMB_ZOMBIE_MAX_ACCEL
			});

		gameContext.collisionSystem
			.procure(e, TileCollisionCmp)
			.autoParams({tilemap: gameContext.tilemap});
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
		var offsetLight:Int = Std.int(gameContext.config.flamethrower_fireball_size / 2);

		e.addComponent(
			new PositionCmp(
				_position.x,
				_position.y,
				Utils.direction2Degrees(direction)
			)
		);
		var lightSource:LightSourceCmp = new LightSourceCmp(
			gameContext.lightingSystem,
			0x5500ff,
			gameContext.config.flamethrower_starting_size,
			offsetLight,
			offsetLight
		);
		e.addComponent(lightSource);
		gameContext.lightSourceSystem.addComponent(lightSource);

		var velocity:VelocityCmp = gameContext.velocitySystem.procure(e, VelocityCmp);
		direction = direction
			.normalized()
			.mult(gameContext.config.flamethrower_start_speed);
		velocity.setVelX(direction.x);
		velocity.setVelY(direction.y);

		var dimensions:DimensionsCmp = new DimensionsCmp(
			gameContext.config.flamethrower_fireball_size,
			gameContext.config.flamethrower_fireball_size
		);

		e.addComponent(dimensions);

		var damping = gameContext.dampingSystem.procure(e, Damping);
		damping.autoParams({factor: gameContext.config.flamethrower_damping});
		gameContext.environmentSystem.procure(e, FireCmp);
		gameContext.collisionSystem
			.procure(e, TileCollisionCmp)
			.autoParams({tilemap: gameContext.tilemap});

		gameContext.hitTestSystem
			.procure(e, HitCircleCmp)
			.autoParams({
				tag: HG_FIRE,
				radius: gameContext.config.flamethrower_hitcircle_size
			});

		return e;
	}

	public function spawnProjectile(projectileName:String, _position:Vector2, direction:Vector2):Entity {
		var e:Entity = autoBuild(projectileName);
		e
			.getComponent(PositionCmp)
			.setPosition(
				_position.x,
				_position.y,
				Utils.direction2Degrees(direction)
			);

		var projectileConfig:Dynamic = Reflect.field(gameContext.config.projectiles_info, projectileName);

		// refactor this
		direction = direction
			.normalized()
			.mult(projectileConfig.speed);

		e
			.getComponent(VelocityCmp)
			.setBoth(direction.x, direction.y);

		gameContext.hitCheckSystem
			.procure(e, Projectile)
			.tilemapData = gameContext.tilemap;

		return e;
	}

	public function createBullet(_position:Vector2, direction:Vector2):Entity {
		var e:Entity = autoBuild("MGBullet");
		e
			.getComponent(PositionCmp)
			.setPosition(
				_position.x,
				_position.y,
				Utils.direction2Degrees(direction)
			);
		var lightSource = new LightSourceCmp(
			gameContext.lightingSystem,
			0xFFFF00,
			gameContext.config.crossbow_bolt_light_radius,
			0,
			0
		);
		e.addComponent(lightSource);
		gameContext.lightSourceSystem.addComponent(lightSource);

		direction = direction
			.normalized()
			.mult(gameContext.config.crossbow_projectile_speed);
		e
			.getComponent(VelocityCmp)
			.setBoth(direction.x, direction.y);
		gameContext.hitCheckSystem
			.procure(e, Projectile)
			.tilemapData = gameContext.tilemap;
		return e;
	}

	public function createProjectile(_position:Vector2, direction:Vector2):Entity {
		var e:Entity = new Entity();
		e.addComponent(
			new PositionCmp(
				_position.x,
				_position.y,
				Utils.direction2Degrees(direction)
			)
		);
		e.addComponent(ResourceFormat.surfacesets.get("projectiles"));
		var lightSource = new LightSourceCmp(
			gameContext.lightingSystem,
			gameContext.config.crossbow_bolt_light_color,
			gameContext.config.crossbow_bolt_light_radius,
			0,
			0
		);
		e.addComponent(lightSource);
		gameContext.lightSourceSystem.addComponent(lightSource);

		var surfaceRender = gameContext.selfLitRenderSystem.procure(e, AnimatedRenderCmp);
		surfaceRender.autoParams({
			"animations": [{name: "bolt", frames: [0]}],
			"initialAnimation": "bolt",
			"surface": null,
			"frameTime": 8
		});

		var velocity:VelocityCmp = gameContext.velocitySystem.procure(e, VelocityCmp);
		direction = direction
			.normalized()
			.mult(gameContext.config.crossbow_projectile_speed);
		velocity.setVelX(direction.x);
		velocity.setVelY(direction.y);

		gameContext.hitCheckSystem
			.procure(e, Projectile)
			.tilemapData = gameContext.tilemap;
		gameContext.hitTestSystem
			.procure(e, HitCircleCmp)
			.autoParams({
				tag: HG_CROSSBOW_BOLT,
				radius: gameContext.config.crossbow_bolt_size
			});

		return e;
	}

	public function createTilemap(_width:Int, _height:Int, tilesize:Int, _colIndex:Int,
			_data:Array<Array<Int>>, _tileset:String = "all_tiles",
			_original_tilesheet_name = "tilesheet"):Entity {

		var tilemap:TileMap = new TileMap(
			new Tilesheet(
				tilesize,
				ResourceFormat.surfacesets.get(_tileset),
				_original_tilesheet_name
			),
			_width,
			_height,
			tilesize,
			_colIndex
		);
		tilemap.setDataIntArray(_data);

		gameContext.tilemap = tilemap;
		gameContext.collisionSystem.setTilemap(tilemap);

		return null;
	}

	// Smaller Stuff
	public function createGibSplash(amount:Int, _p:PositionCmp, ?_directionBiasRad:Float,
			?_directionStdRad:Float) {
		for (i in 0...amount) {
			autoBuild("Blood")
				.getComponent(PositionCmp)
				.setFromPosition(_p)
				.getEntity()
				.getComponent(Particle)
				.randomDirection(
					gameContext.values.getRandomGibSplashMaginutude(),
					_directionBiasRad,
					_directionStdRad
				);
		}
	}
}
