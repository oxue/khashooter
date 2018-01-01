package;
import kha.math.Vector2;
import refraction.control.BreadCrumbsComponent;
import refraction.control.Damping;
import refraction.control.KeyControlComponent;
import refraction.control.RotationControlComponent;
import refraction.core.Entity;
import refraction.display.Surface2RenderComponentC;
import refraction.generic.Dimensions;
import refraction.generic.Position;
import refraction.generic.Velocity;
import refraction.tile.Surface2TileRenderComponent;
import refraction.tile.TileCollision;
import refraction.tile.TilemapData;
import entbuilders.ItemBuilder;
import refraction.generic.TooltipComponent;
import components.InteractComponent;
import components.ProjectileComponent;
import refraction.core.Application;
import refraction.systems.SpacingSystem.Spacing;

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
	
	public function new(_gc:GameContext){
		gameContext = _gc;
		itemBuilder = new ItemBuilder(gameContext);
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
		e.addComponent(new Position(_x, _y));
		e.addComponent(new Dimensions(_w, _h));
		gameContext.velocitySystem.procure(e, Velocity);
		gameContext.spacingSystem.procure(e, Spacing).autoSetup({ radius: _w/2 });
		gameContext.dampingSystem.procure(e, Damping).autoSetup({ factor: Consts.ACTOR_DAMPING });

		//var lightsource:LightSourceComponent = new LightSourceComponent(gameContext.lightingSystem, 0xaaaaaa, cast _w/2 + 5, cast _w / 2, cast _h/2);
		//e.addComponent(lightsource);
		//gameContext.lightSourceSystem.addComponent(lightsource);
		
		return e;
	}

	public function createGyo(_x,_y):Entity
	{
		var e:Entity = createActorEntity(_x,_y,20,20);

		e.addComponent(ResourceFormat.surfacesets.get("gyo"));

		var surfaceRender = new Surface2RenderComponentC();
		e.addComponent(surfaceRender);
		surfaceRender.camera = gameContext.camera;

		surfaceRender.animations[0] = [4];
		surfaceRender.animations.push([for (i in 0...12) i]);
		surfaceRender.frameTime = Consts.SMOOTH_FRAME_TIME;
		surfaceRender.frame = 0;
		surfaceRender.curAnimaition = 1;

		gameContext.surface2RenderSystem.addComponent(surfaceRender);

		gameContext.collisionSystem.procure(e, TileCollision).autoSetup({tilemap: gameContext.tilemapData});
		gameContext.breadCrumbsSystem.procure(e, BreadCrumbsComponent).autoSetup({
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
		var surfaceRender = new Surface2RenderComponentC();
		e.addComponent(surfaceRender);
		surfaceRender.camera = gameContext.camera;
		
		surfaceRender.animations[0] = [0];
		surfaceRender.animations.push([0, 1, 0, 2]);
		surfaceRender.frameTime = Consts.CHARACTER_FRAME_TIME;
		surfaceRender.frame = 0;
		surfaceRender.curAnimaition = 1;
		
		gameContext.surface2RenderSystem.addComponent(surfaceRender);
		
		gameContext.collisionSystem.procure(e, TileCollision).autoSetup({tilemap: gameContext.tilemapData});
		gameContext.breadCrumbsSystem.procure(e, BreadCrumbsComponent).autoSetup({
				acceptanceRadius: Consts.BREADCRUMB_ACCEPTANCE_DISTANCE,
				maxAcceleration: Consts.BREADCRUMB_ZOMBIE_MAX_ACCEL
			}
		);
		
		var ai = new ZombieAI(cast gameContext.playerEntity.getComponent(Position));
		e.addComponent(ai);
		gameContext.aiSystem.addComponent(ai);
	}
	
	public function createPlayer(_x:Int = 0, _y:Int = 0):Void
	{
		// BASE ENTITY
		var e:Entity = createActorEntity(_x, _y, 20, 20);
		e.addComponent(ResourceFormat.surfacesets.get("shiro"));
		e.addComponent(ResourceFormat.surfacesets.get("weapons"), "weapons_surface");
		gameContext.playerEntity = e;
		
		// SURFACE2 RENDER
		var surfaceRender = new Surface2RenderComponentC(gameContext.camera);
		e.addComponent(surfaceRender);
		
		surfaceRender.animations[0] = [0]; 				 // standing
		surfaceRender.animations.push([0, 1, 0, 2]);	 // walking
		surfaceRender.animations.push([3]);				 // standing with weapon
		surfaceRender.animations.push([3, 4, 3, 5]);	 // walking with weapon
		surfaceRender.frameTime = Consts.CHARACTER_FRAME_TIME;
		surfaceRender.frame = 0;

		var weaponRender = new Surface2RenderComponentC(gameContext.camera, "weapons_surface");
		e.addComponent(weaponRender, "weapon_render");
		weaponRender.animations[0] = [0];
		weaponRender.frame = 0;

		gameContext.surface2RenderSystem.addComponent(weaponRender);
		gameContext.selfLitRenderSystem.addComponent(surfaceRender);
		
		// CONTROL
		var rotationControl:RotationControlComponent = new RotationControlComponent(gameContext.camera);
		e.addComponent(rotationControl);
		gameContext.controlSystem.addComponent(rotationControl);

		var inventory = new InventoryComponent();
		e.addComponent(inventory);
		
		var keyControl = gameContext.controlSystem.procure(e, KeyControlComponent);
		keyControl.autoSetup({speed: 1});
		
		gameContext.collisionSystem
			.procure(e, TileCollision)
			.autoSetup({tilemap: gameContext.tilemapData});
				
		var animationControl:AnimationControlComponent = new AnimationControlComponent();
		e.addComponent(animationControl);
		gameContext.controlSystem.addComponent(animationControl);
	}
	
	public function createNPC(_x:Int = 0, _y:Int = 0, name:String){
		var e:Entity = createActorEntity(_x, _y, 20, 20);
		e.addComponent(ResourceFormat.surfacesets.get(name));
				
		var surfaceRender:Surface2RenderComponentC = new Surface2RenderComponentC();
		e.addComponent(surfaceRender);
		surfaceRender.camera = gameContext.camera;
		
		surfaceRender.animations[0] = [0];
		surfaceRender.animations.push([0, 1, 0, 2]);
		surfaceRender.frameTime = 8;
		surfaceRender.frame = 0;
		
		gameContext.surface2RenderSystem.addComponent(surfaceRender);
		
		var npc = new InteractComponent(gameContext.camera, function(e){
			trace("Asd");
		});
		e.addComponent(npc);
		
		gameContext.interactSystem.addComponent(npc);
		
		gameContext.breadCrumbsSystem.procure(e, BreadCrumbsComponent).autoSetup({
				acceptanceRadius: Consts.BREADCRUMB_ACCEPTANCE_DISTANCE,
				maxAcceleration: Consts.BREADCRUMB_ZOMBIE_MAX_ACCEL
			}
		);
		
		gameContext.collisionSystem.procure(e, TileCollision).autoSetup({ tilemap: gameContext.tilemapData });
		gameContext.aiSystem.procure(e, MimiAI);
		gameContext.tooltipSystem.procure(e, TooltipComponent).autoSetup({
			name: name,
			color: kha.Color.Pink
		});
	}
	
	public function createProjectile(_position:Vector2, direction:Vector2):Entity
	{
		var e:Entity = new Entity();
		e.addComponent(new Position(_position.x, _position.y, Math.atan2(direction.y, direction.x) * Consts.RAD2A));
		e.addComponent(ResourceFormat.surfacesets.get("projectiles"));

		var surfaceRender = new Surface2RenderComponentC(gameContext.camera);
		//gameContext.surface2RenderSystem.addComponent(surfaceRender);
		gameContext.selfLitRenderSystem.addComponent(surfaceRender);
		surfaceRender.animations[0] = [0];
		e.addComponent(surfaceRender);

		var velocity = gameContext.velocitySystem.procure(e, Velocity);
		direction.normalize();
		direction = direction.mult(Consts.CROSSBOW_PROJECTILE_SPEED);
		velocity.velX = direction.x;
		velocity.velY = direction.y;

		gameContext.hitCheckSystem.procure(e, ProjectileComponent).tilemapData = gameContext.tilemapData;

		return e;
	}

	public function createTilemap(_width:Int, _height:Int, _tilesize:Int, _colIndex:Int, _data:Array<Array<Int>>, _tileset:String = "all_tiles"):Entity
	{
		var e:Entity = new Entity();
		
		var tilemapData:TilemapData = new TilemapData(_width, _height, _tilesize, _colIndex);
		e.addComponent(tilemapData);
		tilemapData.setDataIntArray(_data);
		e.addComponent(ResourceFormat.surfacesets.get(_tileset));
		
		var tileRender:Surface2TileRenderComponent = new Surface2TileRenderComponent();
		tileRender.targetCamera = gameContext.camera;
		e.addComponent(tileRender);
		
		gameContext.currentMap = tileRender;
		gameContext.tilemapData = tilemapData;
		gameContext.collisionSystem.setTilemap(tilemapData);
		
		return e;
	}
	
}