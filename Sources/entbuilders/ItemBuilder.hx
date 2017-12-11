package entbuilders;
import refraction.core.Entity;
import refraction.generic.PositionComponent;
import refraction.generic.TransformComponent;
import refraction.display.Surface2RenderComponentC;

/**
 * ...
 * @author 
 */
 
class ItemBuilder
{

	private var gameContext:GameContext;

	public function create(_x = 0, _y = 0):Entity
	{
		var e:Entity = new Entity();
		e.addComponent(new PositionComponent(_x, _y));
		e.addComponent(new TransformComponent());
		e.addComponent(ResourceFormat.getSurfaceSet("items"));
		
		var surfaceRender:Surface2RenderComponentC = new Surface2RenderComponentC();
		e.addComponent(surfaceRender);
		surfaceRender.targetCamera = gameContext.cameraRect;

		surfaceRender.animations[0] = [0];
		surfaceRender.animations.push([1]);
		surfaceRender.animations.push([2]);
		surfaceRender.animations.push([3]);
		surfaceRender.curAnimaition = 0;
		surfaceRender.frame = 0;
		
		gameContext.surface2RenderSystem.addComponent(surfaceRender);

		return e;
	}

	public function new(_gameContext:GameContext)
	{
		gameContext = _gameContext;
	}
	
}