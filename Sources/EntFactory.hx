package;
import kha.Assets;
import kha.math.FastVector2;
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

/**
 * ...
 * @author 
 */
class EntFactory
{

	private var gameContext:GameContext;
	private var entityPrototypes:Dynamic;
	private var itemBuilder:ItemBuilder;
	
	public function new(_gc:GameContext){
		gameContext = _gc;
		
		ResourceFormat.init();
		ResourceFormat.beginAtlas("all");
		ResourceFormat.formatTileSheet("all_tiles", Assets.images.tilesheet, 16);
		ResourceFormat.formatTileSheet("modern", Assets.images.modern, 16);
		ResourceFormat.formatRotatedSprite("man", Assets.images.man, 26, 26).addTranslation(3,3);
		ResourceFormat.formatRotatedSprite("weapons", Assets.images.weapons, 36, 20).translateX += 8;
		ResourceFormat.formatRotatedSprite("mimi", Assets.images.mimi, 26, 26).addTranslation(3, 3);
		ResourceFormat.formatRotatedSprite("zombie", Assets.images.zombie, 32, 32).addTranslation(6, 6);
		ResourceFormat.formatRotatedSprite("shiro", Assets.images.shiro, 26, 26).addTranslation(3, 3);
		ResourceFormat.formatRotatedSprite("items", Assets.images.items, 32, 32);
		ResourceFormat.endAtlas();

		itemBuilder = new ItemBuilder(gameContext);
	}

	public function createItem(_x, _y):Entity
	{
		return itemBuilder.create(_x, _y);
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
		
		//var shadowSurface = 
		
		return e;
	}
	
	public function createZombie(_x:Int = 0, _y:Int = 0):Void
	{
		var e:Entity = createActorEntity(_x, _y, 20, 20);
		e.addComponent(ResourceFormat.surfacesets.get("zombie"));
		
		// SURFACE2 RENDER
		var surfaceRender:Surface2RenderComponentC = new Surface2RenderComponentC();
		e.addComponent(surfaceRender);
		surfaceRender.targetCamera = gameContext.cameraRect;
		
		surfaceRender.animations[0] = [0];
		surfaceRender.animations.push([0, 1, 0, 2]);
		surfaceRender.frameTime = 8;
		surfaceRender.frame = 0;
		surfaceRender.curAnimaition = 1;
		
		gameContext.surface2RenderSystem.addComponent(surfaceRender);
		
		var tileCollision:TileCollisionComponent = new TileCollisionComponent();
		tileCollision.targetTilemap = gameContext.currentTilemapData;
		e.addComponent(tileCollision);
		gameContext.collisionSystem.addComponent(tileCollision);
		
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
		gameContext.playerEntity = e;
		
		// SURFACE2 RENDER
		var surfaceRender:Surface2RenderComponentC = new Surface2RenderComponentC();
		e.addComponent(surfaceRender);
		surfaceRender.targetCamera = gameContext.cameraRect;
		
		surfaceRender.animations[0] = [0]; 				 // standing
		surfaceRender.animations.push([0, 1, 0, 2]);	 // walking
		surfaceRender.animations.push([3]);				 // standing with weapon
		surfaceRender.animations.push([3, 4, 3, 5]);	 // walking with weapon
		surfaceRender.frameTime = 8;
		surfaceRender.frame = 0;
		
		gameContext.surface2RenderSystem.addComponent(surfaceRender);
		
		// CONTROL
		var rotationControl:RotationControlComponent = new RotationControlComponent(gameContext.cameraRect);
		e.addComponent(rotationControl);
		gameContext.controlSystem.addComponent(rotationControl);

		var inventory = new InventoryComponent();
		e.addComponent(inventory);
		
		var keyControl:KeyControlComponent = new KeyControlComponent(1);
		e.addComponent(keyControl);
		gameContext.controlSystem.addComponent(keyControl);
		
		var tileCollision:TileCollisionComponent = new TileCollisionComponent();
		tileCollision.targetTilemap = gameContext.currentTilemapData;
		e.addComponent(tileCollision);
		gameContext.collisionSystem.addComponent(tileCollision);
		
		var we:Entity = new Entity();
		we.addComponent(ResourceFormat.surfacesets.get("weapons"));
		we.addComponent(e.components.get("pos_comp"));
		we.addComponent(e.components.get("trans_comp"));
		
		//var surfaceRenderWeapons:Surface2RenderComponentC = new Surface2RenderComponentC();
		//we.addComponent(surfaceRenderWeapons);
		//surfaceRenderWeapons.targetCamera = gameContext.cameraRect;
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
		surfaceRender.targetCamera = gameContext.cameraRect;
		
		surfaceRender.animations[0] = [0];
		surfaceRender.animations.push([0, 1, 0, 2]);
		surfaceRender.frameTime = 8;
		surfaceRender.frame = 0;
		
		gameContext.surface2RenderSystem.addComponent(surfaceRender);
		
		var npc:NPCComponent = new NPCComponent(gameContext.cameraRect, gameContext.statusText);
		e.addComponent(npc);
		
		gameContext.npcSystem.addComponent(npc);
		
		var breadcrumbs:BreadCrumbsComponent = new BreadCrumbsComponent(20, 0.3);
		e.addComponent(breadcrumbs);
		gameContext.breadCrumbsSystem.addComponent(breadcrumbs);
		breadcrumbs.breadcrumbs.push(new FastVector2(40, 40));
		
		var tileCollision:TileCollisionComponent = new TileCollisionComponent();
		tileCollision.targetTilemap = gameContext.currentTilemapData;
		e.addComponent(tileCollision);
		gameContext.collisionSystem.addComponent(tileCollision);
		
		var ai:MimiAI = new MimiAI("MimiAI");
		e.addComponent(ai);
		gameContext.aiSystem.addComponent(ai);
	}
	
	public function createTilemap(_width:Int, _height:Int, _tilesize:Int, _colIndex:Int, _data:Array<Array<Int>>, _tileset:String = "all_tiles"):Entity
	{
		var e:Entity = new Entity();
		
		var tilemapData:TilemapDataComponent = new TilemapDataComponent(_width, _height, _tilesize, _colIndex);
		e.addComponent(tilemapData);
		tilemapData.setDataIntArray(_data);
		e.addComponent(ResourceFormat.surfacesets.get(_tileset));
		
		var tileRender:Surface2TileRenderComponent = new Surface2TileRenderComponent();
		tileRender.targetCamera = gameContext.cameraRect;
		e.addComponent(tileRender);
		
		gameContext.currentMap = tileRender;
		gameContext.currentTilemapData = tilemapData;
		
		return e;
	}
	
}