package entbuilders;
import refraction.core.Entity;
import refraction.generic.Position;
import refraction.generic.Dimensions;
import refraction.display.AnimatedRender;
import refraction.generic.Tooltip;
import components.Interactable;
import refraction.display.ResourceFormat;

/**
 * ...
 * @author 
 */
 
class ItemBuilder
{

	private var gameContext:GameContext;

	public function create(_x = 0, _y = 0, _itemId:Int):Entity
	{
		var e:Entity = new Entity();
		e.addComponent(new Position(_x, _y));
		e.addComponent(new Dimensions(32,32));
		e.addComponent(ResourceFormat.getSurfaceSet("items"));
		
		var surfaceRender:AnimatedRender = new AnimatedRender();
		e.addComponent(surfaceRender);

		surfaceRender.animations.set("crossbow",[0]);
		//surfaceRender.animations.push([1]);
		//surfaceRender.animations.push([2]);
		//surfaceRender.animations.push([3]);
		surfaceRender.curAnimaition = "crossbow";
		surfaceRender.frame = 0;
		
		gameContext.renderSystem.addComponent(surfaceRender);

		var tt:Tooltip = new Tooltip("Demon Hunter's Crossbow", kha.Color.Green);
		e.addComponent(tt);
		gameContext.tooltipSystem.addComponent(tt);

		var ic = new Interactable(gameContext.camera, function(e:Entity){
			trace(_itemId);
			gameContext.playerEntity.getComponent(Inventory).pickup(_itemId);
			e.remove();
		});
		gameContext.interactSystem.addComponent(ic);
		e.addComponent(ic);

		return e;
	}

	public function new(_gameContext:GameContext)
	{
		gameContext = _gameContext;
	}
	
}