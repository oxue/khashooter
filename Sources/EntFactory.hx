package;
import kha.math.Vector2;
import refraction.control.BreadCrumbs;
import refraction.control.Damping;
import refraction.control.KeyControl;
import refraction.control.RotationControl;
import refraction.core.Entity;
import refraction.display.AnimatedRender;
import refraction.generic.Dimensions;
import refraction.generic.Position;
import refraction.generic.Velocity;
import refraction.tile.Surface2TileRender;
import refraction.tile.TileCollision;
import refraction.tile.TilemapData;
import entbuilders.ItemBuilder;
import refraction.generic.Tooltip;
import components.Interactable;
import components.Projectile;
import refraction.core.Application;
import refraction.systems.SpacingSys.Spacing;
import kha.Assets;
import haxe.Json;
import haxe.ds.StringMap;
import refraction.core.Component;

/**
 * ...
 * @author 
 */
class EntFactory
{

	private static var myInstance:EntFactory = null;

	public static function instance(?_gc:GameContext):EntFactory{
		if(myInstance == null){
			myInstance = new EntFactory(_gc);
		}
		return myInstance;
	}

	public var gameContext:GameContext;
	private var entityPrototypes:Dynamic;
	private var itemBuilder:ItemBuilder;
	private var entityTemplates:StringMap<Dynamic>;
	
	public function new(_gc:GameContext){
		gameContext = _gc;
		itemBuilder = new ItemBuilder(gameContext);
		entityTemplates = parseEntityData(Assets.blobs.entity_entities_json.toString());
	}

	public function parseEntityData(_data:String):StringMap<Dynamic>
	{
		var jsonObj:Dynamic = Json.parse(_data);
		var ret = new StringMap<Dynamic>();
		var i:Int = jsonObj.entities.length;

		while(i-->0){
			var entityName:String = jsonObj.entities[i].entity_name;
			ret.set(entityName, jsonObj.entities[i]);
		}

		return ret;
	}

	public function worldMouse():Vector2{
		return new Vector2(
			cast Application.mouseX / 2 + gameContext.camera.x,
			cast Application.mouseY / 2 + gameContext.camera.y
		);
	}

	public function createItem(_x, _y):Entity
	{
		return itemBuilder.create(_x, _y, 0);
	}
	
	public function createActorEntity(_x:Int = 0, _y:Int = 0, _w:Int = 20, _h:Int = 20):Entity
	{
		var e:Entity = new Entity();
		var p = new Position(_x, _y, 10, 10);
		p.autoParams({x:_x,y:_y});
		e.addComponent(p);
		e.addComponent(new Dimensions(_w, _h));
		gameContext.velocitySystem.procure(e, Velocity);
		gameContext.spacingSystem.procure(e, Spacing).autoParams({ radius: _w/2 });
		gameContext.dampingSystem.procure(e, Damping).autoParams({ factor: Consts.ACTOR_DAMPING });

		//var lightsource:LightSourceComponent = new LightSourceComponent(gameContext.lightingSystem, 0xaaaaaa, cast _w/2 + 5, cast _w / 2, cast _h/2);
		//e.addComponent(lightsource);
		//gameContext.lightSourceSystem.addComponent(lightsource);
		
		return e;
	}

	public function createGyo(_x,_y):Entity
	{
		var e:Entity = createActorEntity(_x,_y,20,20);

		e.addComponent(ResourceFormat.surfacesets.get("gyo"));

		var surfaceRender = new AnimatedRender();
		e.addComponent(surfaceRender);

		surfaceRender.animations.set("idle", [4]);
		surfaceRender.animations.set("running", [for (i in 0...12) i]);
		surfaceRender.frameTime = Consts.SMOOTH_FRAME_TIME;
		surfaceRender.frame = 0;
		surfaceRender.curAnimaition = "idle";

		gameContext.renderSystem.addComponent(surfaceRender);

		gameContext.collisionSystem.procure(e, TileCollision).autoParams({tilemap: gameContext.tilemapData});
		gameContext.breadCrumbsSystem.procure(e, BreadCrumbs).autoParams({
				acceptanceRadius: 20,
				maxAcceleration: 1
			}
		);

		gameContext.aiSystem.procure(e, MimiAI);

		return e;
	}
	
	public function createZombie(_x:Int = 0, _y:Int = 0):Void
	{
		var e = createActorEntity(_x, _y, 20, 20);
		e.addComponent(ResourceFormat.surfacesets.get("zombie"));
		
		// SURFACE2 RENDER
		var surfaceRender = new AnimatedRender();
		e.addComponent(surfaceRender);
		
		surfaceRender.animations.set("idle", [0]);
		surfaceRender.animations.set("running", [0, 1, 0, 2]);
		surfaceRender.frameTime = Consts.CHARACTER_FRAME_TIME;
		surfaceRender.frame = 0;
		surfaceRender.curAnimaition = "idle";
		
		gameContext.renderSystem.addComponent(surfaceRender);
		
		gameContext.collisionSystem.procure(e, TileCollision).autoParams({tilemap: gameContext.tilemapData});
		gameContext.breadCrumbsSystem.procure(e, BreadCrumbs).autoParams({
				acceptanceRadius: Consts.BREADCRUMB_ACCEPTANCE_DISTANCE,
				maxAcceleration: Consts.BREADCRUMB_ZOMBIE_MAX_ACCEL
			}
		);
		
		var ai = new ZombieAI(cast gameContext.playerEntity.getComponent(Position));
		e.addComponent(ai);
		gameContext.aiSystem.addComponent(ai);
	}

	public function constructComponent(_type:String, _e:Entity, _name:String = null):Component
	{
		switch _type {
			case "AnimatedRender": return cast gameContext.renderSystem.procure(_e, AnimatedRender, _name);
			case "AnimatedRender/SelfLit": return cast gameContext.selfLitRenderSystem.procure(_e, AnimatedRender, _name);
			case "RotationControl": return cast gameContext.controlSystem.procure(_e, RotationControl, _name);
			case "KeyControl": return cast gameContext.controlSystem.procure(_e, KeyControl, _name);
			case "TileCollision": return cast gameContext.collisionSystem.procure(_e, TileCollision, _name);
			case "PlayerAnimation": return cast gameContext.controlSystem.procure(_e, PlayerAnimation, _name);
			case "Inventory": return _e.addComponent(new Inventory());
			case "Position": return _e.addComponent(new Position());
			case "Dimensions": return _e.addComponent(new Dimensions());
			case "Velocity": return cast gameContext.velocitySystem.procure(_e, Velocity, _name);
			case "Spacing": return cast gameContext.spacingSystem.procure(_e, Spacing, _name);
			case "Damping": return cast gameContext.dampingSystem.procure(_e, Damping, _name);
		}
		return null;
	}

	public function autoComponent(_type:String, _settings:Dynamic, _e:Entity):Component
	{
		if(_type == "SurfaceSet"){
			return _e.addComponent(ResourceFormat.surfacesets.get(_settings.resource), _settings.name);
		}

		var ret:Component = constructComponent(_type, _e, _settings.name);
		if(_settings.args != null){
			ret.autoParams(_settings.args);
		}
		return ret;
	}

	public function autoBuild(_entityName:String, _e:Entity = null):Entity
	{
		if(entityTemplates.get(_entityName).base_entity!=null){
			_e = autoBuild(entityTemplates.get(_entityName).base_entity);
		}
		if(_e == null) _e = new Entity();

		var components:Array<Dynamic> = entityTemplates.get(_entityName).components;

		for(component in components){
			autoComponent(component.type, component, _e);
		}
		return _e;
	}
	
	public function createPlayer(_x:Int = 0, _y:Int = 0):Void
	{
		var e = autoBuild("Player");
		e.getComponent(Position).x = _x;
		e.getComponent(Position).y = _y;
		gameContext.playerEntity = e;
	}
	
	public function createNPC(_x:Int = 0, _y:Int = 0, name:String){
		var e:Entity = autoBuild("Actor");
		e.addComponent(ResourceFormat.surfacesets.get(name));
				
		var surfaceRender:AnimatedRender = new AnimatedRender();
		e.addComponent(surfaceRender);
		
		surfaceRender.animations.set("idle", [0]);
		surfaceRender.animations.set("running", [0, 1, 0, 2]);
		surfaceRender.frameTime = 8;
		surfaceRender.frame = 0;
		
		gameContext.renderSystem.addComponent(surfaceRender);
		
		var npc = new Interactable(gameContext.camera, function(e){
			trace("Asd");
		});
		e.addComponent(npc);
		
		gameContext.interactSystem.addComponent(npc);
		
		gameContext.breadCrumbsSystem.procure(e, BreadCrumbs).autoParams({
				acceptanceRadius: Consts.BREADCRUMB_ACCEPTANCE_DISTANCE,
				maxAcceleration: Consts.BREADCRUMB_ZOMBIE_MAX_ACCEL
			}
		);
		
		gameContext.collisionSystem.procure(e, TileCollision).autoParams({ tilemap: gameContext.tilemapData });
		gameContext.aiSystem.procure(e, MimiAI);
		gameContext.tooltipSystem.procure(e, Tooltip).autoParams({
			message: name,
			color: kha.Color.Pink
		});
	}
	
	public function createProjectile(_position:Vector2, direction:Vector2):Entity
	{
		var e:Entity = new Entity();
		e.addComponent(new Position(_position.x, _position.y, 10, 10, Math.atan2(direction.y, direction.x) * Consts.RAD2A));
		e.addComponent(ResourceFormat.surfacesets.get("projectiles"));

		var surfaceRender = gameContext.renderSystem.procure(e,AnimatedRender);
		surfaceRender.autoParams({
			"animations": [
				{name: "bolt", frames: [0]},
			],
			"initialAnimation": "bolt",
			"surface": null,
			"frameTime": 8
		});

		var velocity = gameContext.velocitySystem.procure(e, Velocity);
		direction.normalize();
		direction = direction.mult(Consts.CROSSBOW_PROJECTILE_SPEED);
		velocity.velX = direction.x;
		velocity.velY = direction.y;

		gameContext.hitCheckSystem.procure(e, Projectile).tilemapData = gameContext.tilemapData;

		return e;
	}

	public function createTilemap(_width:Int, _height:Int, _tilesize:Int, _colIndex:Int, _data:Array<Array<Int>>, _tileset:String = "all_tiles"):Entity
	{
		var e:Entity = new Entity();
		
		var tilemapData:TilemapData = new TilemapData(_width, _height, _tilesize, _colIndex);
		e.addComponent(tilemapData);
		tilemapData.setDataIntArray(_data);
		e.addComponent(ResourceFormat.surfacesets.get(_tileset));
		
		var tileRender:Surface2TileRender = new Surface2TileRender();
		tileRender.targetCamera = gameContext.camera;
		e.addComponent(tileRender);
		
		gameContext.currentMap = tileRender;
		gameContext.tilemapData = tilemapData;
		gameContext.collisionSystem.setTilemap(tilemapData);
		
		return e;
	}
	
}