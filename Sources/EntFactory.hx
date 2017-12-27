package;
import kha.Assets;
import kha.math.FastVector2;
import kha.math.Vector2;
import refraction.control.BreadCrumbsComponent;
import refraction.control.DampingComponent;
import refraction.control.KeyControlComponent;
import refraction.control.RotationControlComponent;
import refraction.core.Entity;
import refraction.display.LightSourceComponent;
import refraction.display.Surface2RenderComponentC;
import refraction.generic.DimensionsComponent;
import refraction.generic.PositionComponent;
import refraction.generic.TransformComponent;
import refraction.generic.VelocityComponent;
import refraction.tile.Surface2TileRenderComponent;
import refraction.tile.TileCollisionComponent;
import refraction.tile.TilemapDataComponent;
import entbuilders.ItemBuilder;
import refraction.generic.TooltipComponent;
import components.InteractComponent;
import components.ProjectileComponent;
import refraction.core.Application;

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
		
		ResourceFormat.init();
		ResourceFormat.beginAtlas("all");

		ResourceFormat.formatTileSheet("all_tiles", Assets.images.tilesheet, 16);
		ResourceFormat.formatTileSheet("modern", Assets.images.modern, 16);

		ResourceFormat.formatRotatedSprite("man", Assets.images.man, 26, 26).addTranslation(3,3);
		ResourceFormat.formatRotatedSprite("weapons", Assets.images.weapons, 36, 20).addTranslation(8, 0);
		ResourceFormat.formatRotatedSprite("mimi", Assets.images.mimi, 26, 26).addTranslation(3, 3);
		ResourceFormat.formatRotatedSprite("zombie", Assets.images.zombie, 32, 32).addTranslation(6, 6);
		ResourceFormat.formatRotatedSprite("shiro", Assets.images.shiro, 26, 26).addTranslation(3, 3);
		ResourceFormat.formatRotatedSprite("items", Assets.images.items, 32, 32);
		ResourceFormat.formatRotatedSprite("gyo", Assets.images.gyo, 29, 24).addTranslation(3, 4);
		ResourceFormat.formatRotatedSprite("weapons", Assets.images.crossbow ,26,26).addTranslation(3, 3).registration(-13,-6);
		ResourceFormat.formatRotatedSprite("projectiles", Assets.images.projectiles ,20,20).registration(10,10);
		
		ResourceFormat.endAtlas();

		itemBuilder = new ItemBuilder(gameContext);
	}

	private function addTileCollisionComponent(e:Entity):Void
	{
		var tileCollision = new TileCollisionComponent();
		tileCollision.targetTilemap = gameContext.currentTilemapData;
		e.addComponent(tileCollision);
		gameContext.collisionSystem.addComponent(tileCollision);
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
		e.addComponent(new PositionComponent(_x, _y));
		e.addComponent(new DimensionsComponent(_w, _h));
		e.addComponent(new TransformComponent());
		
		var velocity:VelocityComponent = new VelocityComponent();
		e.addComponent(velocity);
		gameContext.velocitySystem.addComponent(velocity);
		
		gameContext.spacingSystem.add(cast e.components.get("pos_comp"), velocity, _w/2);
		
		var damping:DampingComponent = new DampingComponent(0.7);
		e.addComponent(damping);
		gameContext.dampingSystem.addComponent(damping);
		
		var lightsource:LightSourceComponent = new LightSourceComponent(gameContext.lightingSystem, 0xaaaaaa, cast _w/2 + 5, cast _w / 2, cast _h/2);
		e.addComponent(lightsource);
		gameContext.lightSourceSystem.addComponent(lightsource);
		
		return e;
	}

	public function createGyo(_x,_y):Entity
	{
		var e:Entity = createActorEntity(_x,_y,20,16);
		e.addComponent(ResourceFormat.surfacesets.get("gyo"));

		var surfaceRender = new Surface2RenderComponentC();
		e.addComponent(surfaceRender);
		surfaceRender.camera = gameContext.camera;

		surfaceRender.animations[0] = [4];
		surfaceRender.animations.push([for (i in 0...12) i]);
		surfaceRender.frameTime = 2;
		surfaceRender.frame = 0;
		surfaceRender.curAnimaition = 1;

		gameContext.surface2RenderSystem.addComponent(surfaceRender);

		addTileCollisionComponent(e);

		var breadcrumbs:BreadCrumbsComponent = new BreadCrumbsComponent(20, 1);
		e.addComponent(breadcrumbs);
		gameContext.breadCrumbsSystem.addComponent(breadcrumbs);
		//breadcrumbs.breadcrumbs.push(new FastVector2(40, 40));

		var ai:MimiAI = new MimiAI("MimiAI");
		e.addComponent(ai);
		gameContext.aiSystem.addComponent(ai);

		return e;
	}
	
	public function createZombie(_x:Int = 0, _y:Int = 0):Void
	{
		var e:Entity = createActorEntity(_x, _y, 20, 20);
		e.addComponent(ResourceFormat.surfacesets.get("zombie"));
		
		// SURFACE2 RENDER
		var surfaceRender:Surface2RenderComponentC = new Surface2RenderComponentC();
		e.addComponent(surfaceRender);
		surfaceRender.camera = gameContext.camera;
		
		surfaceRender.animations[0] = [0];
		surfaceRender.animations.push([0, 1, 0, 2]);
		surfaceRender.frameTime = 8;
		surfaceRender.frame = 0;
		surfaceRender.curAnimaition = 1;
		
		gameContext.surface2RenderSystem.addComponent(surfaceRender);
		
		addTileCollisionComponent(e);
		
		var breadcrumbs:BreadCrumbsComponent = new BreadCrumbsComponent(3, 0.8);
		e.addComponent(breadcrumbs);
		gameContext.breadCrumbsSystem.addComponent(breadcrumbs);
		breadcrumbs.breadcrumbs.push(new FastVector2(40, 40));
		
		var ai:ZombieAI = new ZombieAI("ZombieAI", cast gameContext.playerEntity.components.get("pos_comp"), gameContext.currentTilemapData);
		e.addComponent(ai);
		gameContext.aiSystem.addComponent(ai);
	}
	
	public function createPlayer(_x:Int = 0, _y:Int = 0):Void
	{
		// BASE ENTITY
		var e:Entity = createActorEntity(_x, _y, 20, 20);
		e.addComponent(ResourceFormat.surfacesets.get("shiro"));
		e.addComponentAs(ResourceFormat.surfacesets.get("weapons"), "weapons_surface");
		gameContext.playerEntity = e;
		
		// SURFACE2 RENDER
		var surfaceRender:Surface2RenderComponentC = new Surface2RenderComponentC(gameContext.camera);
		e.addComponent(surfaceRender);
		
		surfaceRender.animations[0] = [0]; 				 // standing
		surfaceRender.animations.push([0, 1, 0, 2]);	 // walking
		surfaceRender.animations.push([3]);				 // standing with weapon
		surfaceRender.animations.push([3, 4, 3, 5]);	 // walking with weapon
		surfaceRender.frameTime = 8;
		surfaceRender.frame = 0;

		var weaponRender = new Surface2RenderComponentC(gameContext.camera, "weapons_surface", "weapon_render");
		e.addComponent(weaponRender);
		weaponRender.animations[0] = [0];
		weaponRender.frame = 0;

		gameContext.surface2RenderSystem.addComponent(weaponRender);
		gameContext.surface2RenderSystem.addComponent(surfaceRender);
		gameContext.selfLitRenderSystem.addComponent(surfaceRender);
		
		// CONTROL
		var rotationControl:RotationControlComponent = new RotationControlComponent(gameContext.camera);
		e.addComponent(rotationControl);
		gameContext.controlSystem.addComponent(rotationControl);

		var inventory = new InventoryComponent();
		e.addComponent(inventory);
		
		var keyControl:KeyControlComponent = new KeyControlComponent(1);
		e.addComponent(keyControl);
		gameContext.controlSystem.addComponent(keyControl);
		
		addTileCollisionComponent(e);
		
		var we:Entity = new Entity();
		we.addComponent(ResourceFormat.surfacesets.get("weapons"));
		we.addComponent(e.components.get("pos_comp"));
		we.addComponent(e.components.get("trans_comp"));
		
		//var surfaceRenderWeapons:Surface2RenderComponentC = new Surface2RenderComponentC();
		//we.addComponent(surfaceRenderWeapons);
		//surfaceRenderWeapons.camera = gameContext.camera;
		//surfaceRenderWeapons.animations[0] = [0];
		//
		//surfaceRenderWeapons.animations.push([0, 1, 0, 2]);
		//surfaceRenderWeapons.animations.push([3]);
		//surfaceRenderWeapons.animations.push([4]);
		//surfaceRenderWeapons.animations.push([5]);
		//surfaceRenderWeapons.frameTime = 8;
		//surfaceRenderWeapons.frame = 0;
		
		//gameContext.surface2RenderSystem.addComponent(surfaceRenderWeapons);
		
		var animationControl:AnimationControlComponent = new AnimationControlComponent();
		//animationControl.blc2 = surfaceRenderWeapons;
		e.addComponent(animationControl);
		
		gameContext.controlSystem.addComponent(animationControl);
		
		//e.addEntity(we);
	}
	
	public function createNPC(_x:Int = 0, _y:Int = 0, name:String){
		var e:Entity = createActorEntity(_x, _y, 20, 20);
		e.addComponent(ResourceFormat.surfacesets.get(name));
		
		cast(e.components.get("trans_comp"), TransformComponent).rotation = Math.random() * 360;
		
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
		
		var breadcrumbs:BreadCrumbsComponent = new BreadCrumbsComponent(20, 0.3);
		e.addComponent(breadcrumbs);
		gameContext.breadCrumbsSystem.addComponent(breadcrumbs);
		breadcrumbs.breadcrumbs.push(new FastVector2(40, 40));
		
		addTileCollisionComponent(e);
		
		var ai:MimiAI = new MimiAI("MimiAI");
		e.addComponent(ai);
		gameContext.aiSystem.addComponent(ai);

		var tt:TooltipComponent = new TooltipComponent(gameContext.camera, name, kha.Color.Pink);
		e.addComponent(tt);
		gameContext.tooltipSystem.addComponent(tt);
	}
	
	public function createProjectile(_position:Vector2, direction:Vector2):Entity
	{
		var e:Entity = new Entity();
		e.addComponent(new PositionComponent(_position.x, _position.y));
		var t = new TransformComponent();
		t.rotation = Math.atan2(direction.y, direction.x) * 180 / 3.1415;
		e.addComponent(t);
		e.addComponent(ResourceFormat.surfacesets.get("projectiles"));

		var surfaceRender = new Surface2RenderComponentC(gameContext.camera);
		gameContext.surface2RenderSystem.addComponent(surfaceRender);
		surfaceRender.animations[0] = [0];
		e.addComponent(surfaceRender);

		var velocity = new VelocityComponent();
		direction.normalize();
		direction = direction.mult(8);
		velocity.velX = direction.x;
		velocity.velY = direction.y;
		e.addComponent(velocity);
		gameContext.velocitySystem.addComponent(velocity);

		var projectile = new ProjectileComponent(gameContext.currentTilemapData);
		gameContext.hitCheckSystem.addComponent(projectile);
		e.addComponent(projectile);

		return e;
	}

	public function createTilemap(_width:Int, _height:Int, _tilesize:Int, _colIndex:Int, _data:Array<Array<Int>>, _tileset:String = "all_tiles"):Entity
	{
		var e:Entity = new Entity();
		
		var tilemapData:TilemapDataComponent = new TilemapDataComponent(_width, _height, _tilesize, _colIndex);
		e.addComponent(tilemapData);
		tilemapData.setDataIntArray(_data);
		e.addComponent(ResourceFormat.surfacesets.get(_tileset));
		
		var tileRender:Surface2TileRenderComponent = new Surface2TileRenderComponent();
		tileRender.targetCamera = gameContext.camera;
		e.addComponent(tileRender);
		
		gameContext.currentMap = tileRender;
		gameContext.currentTilemapData = tilemapData;
		
		return e;
	}
	
}