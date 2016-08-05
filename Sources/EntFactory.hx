package;
import kha.Assets;
import refraction.control.DampingComponent;
import refraction.control.KeyControlComponent;
import refraction.control.RotationControlComponent;
import refraction.core.Entity;
import refraction.display.Surface2RenderComponentC;
import refraction.display.Surface2SetComponent;
import refraction.generic.DimensionsComponent;
import refraction.generic.PositionComponent;
import refraction.generic.TransformComponent;
import refraction.generic.VelocityComponent;
import refraction.tile.Surface2TileRenderComponent;
import refraction.tile.TileCollisionComponent;
import refraction.tile.TilemapDataComponent;

/**
 * ...
 * @author 
 */
class EntFactory
{

	private var gameContext:GameContext;
	
	public function new(_gc:GameContext){
		gameContext = _gc;
		
		ResourceFormat.init();
		ResourceFormat.beginAtlas("all");
		ResourceFormat.formatTileSheet("all_tiles", Assets.images.tilesheet, 16);
		ResourceFormat.formatRotatedSprite("man", Assets.images.man, 20, 20);
		ResourceFormat.formatRotatedSprite("weapons", Assets.images.weapons, 36, 20).translateX += 8;
		ResourceFormat.endAtlas();
	}
	
	public function createBaseTransformEntity(_x:Int = 0, _y:Int = 0, _w:Int = 20, _h:Int = 20):Entity
	{
		var e:Entity = new Entity();
		e.addDataComponent(new PositionComponent(_x, _y));
		e.addDataComponent(new DimensionsComponent(_w, _h));
		e.addDataComponent(new TransformComponent());
		return e;
	}
	
	public function createPlayer(_x:Int = 0, _y:Int = 0):Void
	{
		var e:Entity = createBaseTransformEntity(_x, _y, 20, 20);
		e.addDataComponent(ResourceFormat.surfacesets.get("man"));
		
		var surfaceRender:Surface2RenderComponentC = new Surface2RenderComponentC();
		e.addActiveComponent(surfaceRender);
		surfaceRender.targetCamera = gameContext.cameraRect;
		
		surfaceRender.animations[0] = [0];
		surfaceRender.animations.push([0, 1, 0, 2]);
		surfaceRender.frameTime = 10;
		surfaceRender.frame = 0;
		
		gameContext.surface2RenderSystem.addComponent(surfaceRender);
		
		var velocity:VelocityComponent = new VelocityComponent();
		e.addActiveComponent(velocity);
		
		gameContext.velocitySystem.addComponent(velocity);
		
		var damping:DampingComponent = new DampingComponent(0.7);
		e.addActiveComponent(damping);
		
		gameContext.dampingSystem.addComponent(damping);
		
		var rotationControl:RotationControlComponent = new RotationControlComponent(gameContext.cameraRect);
		e.addActiveComponent(rotationControl);
		
		gameContext.controlSystem.addComponent(rotationControl);
		
		var keyControl:KeyControlComponent = new KeyControlComponent(0.5);
		e.addActiveComponent(keyControl);
		gameContext.controlSystem.addComponent(keyControl);
		
		var tileCollision:TileCollisionComponent = new TileCollisionComponent();
		tileCollision.targetTilemap = gameContext.currentTilemapData;
		e.addActiveComponent(tileCollision);
		gameContext.collisionSystem.addComponent(tileCollision);
		
		var we:Entity = new Entity();
		we.addDataComponent(ResourceFormat.surfacesets.get("weapons"));
		we.addDataComponent(e.components.get("pos_comp"));
		we.addDataComponent(e.components.get("trans_comp"));
		
		var surfaceRenderWeapons:Surface2RenderComponentC = new Surface2RenderComponentC();
		we.addActiveComponent(surfaceRenderWeapons);
		surfaceRenderWeapons.targetCamera = gameContext.cameraRect;
		surfaceRenderWeapons.animations[0] = [0];
		
		surfaceRenderWeapons.animations.push([0, 1, 0, 2]);
		surfaceRenderWeapons.animations.push([3]);
		surfaceRenderWeapons.animations.push([4]);
		surfaceRenderWeapons.animations.push([5]);
		surfaceRenderWeapons.frameTime = 10;
		surfaceRenderWeapons.frame = 0;
		
		gameContext.surface2RenderSystem.addComponent(surfaceRenderWeapons);
		
		var animationControl:AnimationControlComponent = new AnimationControlComponent();
		animationControl.blc2 = surfaceRenderWeapons;
		e.addActiveComponent(animationControl);
		
		gameContext.controlSystem.addComponent(animationControl);
		
		e.addEntity(we);
	}
	
	public function createTilemap(_width:Int, _height:Int, _tilesize:Int, _colIndex:Int, _data:Array<Array<Int>>):Entity
	{
		var e:Entity = new Entity();
		
		var tilemapData:TilemapDataComponent = new TilemapDataComponent(_width, _height, _tilesize, _colIndex);
		e.addDataComponent(tilemapData);
		tilemapData.setDataIntArray(_data);
		e.addDataComponent(ResourceFormat.surfacesets.get("all_tiles"));
		
		var tileRender:Surface2TileRenderComponent = new Surface2TileRenderComponent();
		tileRender.targetCamera = gameContext.cameraRect;
		e.addActiveComponent(tileRender);
		
		gameContext.currentMap = tileRender;
		gameContext.currentTilemapData = tilemapData;
		
		return e;
	}
	
}