package entbuilders;

import refraction.core.Entity;
import refraction.generic.Position;
import refraction.generic.Dimensions;
import refraction.display.AnimatedRender;
import refraction.generic.Tooltip;
import components.Interactable;
import refraction.display.ResourceFormat;
import game.GameContext;
import game.Inventory;

/**
 * ...
 * @author
 */
class ItemBuilder {
	public static inline var CROSSBOW_DEFAULT_ANIMATION = "crossbow_animation";
	public static inline var FLAMETHROWER_DEFAULT_ANIMATION = "flamethrower_animation";

	private var gameContext:GameContext;

	public function create(_x = 0, _y = 0, _itemId:Int):Entity {
		var e:Entity = makebaseItem(new Entity(), _x = 0, _y = 0);

		var animatedRender = e.getComponent(AnimatedRender);
		animatedRender.animations.set(CROSSBOW_DEFAULT_ANIMATION, [0]);
		animatedRender.setCurrentAnimation(CROSSBOW_DEFAULT_ANIMATION);
		animatedRender.frame = 0;
		gameContext.renderSystem.addComponent(animatedRender);

		var tt:Tooltip = new Tooltip("Demon Hunter's Crossbow", kha.Color.Green);
		e.addComponent(tt);
		gameContext.tooltipSystem.addComponent(tt);

		var ic = new Interactable(gameContext.camera, function(e:Entity) {
			trace(_itemId);
			gameContext.playerEntity
				.getComponent(Inventory)
				.pickup(_itemId);
			e.remove();
		});
		gameContext.interactSystem.addComponent(ic);
		e.addComponent(ic);

		return e;
	}

	public function create2(_x = 0, _y = 0, _itemId:Int):Entity {
		var e = makebaseItem(new Entity());
		var animatedRender = e.getComponent(AnimatedRender);
		animatedRender.animations.set(FLAMETHROWER_DEFAULT_ANIMATION, [1]);
		animatedRender.setCurrentAnimation(FLAMETHROWER_DEFAULT_ANIMATION);
		animatedRender.frame = 0;
		gameContext.renderSystem.addComponent(animatedRender);

		var tt:Tooltip = new Tooltip("Flamethrower", kha.Color.Red);
		e.addComponent(tt);
		gameContext.tooltipSystem.addComponent(tt);

		var ic = new Interactable(gameContext.camera, function(e:Entity) {
			trace(_itemId);
			gameContext.playerEntity
				.getComponent(Inventory)
				.pickup(_itemId);
			e.remove();
		});
		gameContext.interactSystem.addComponent(ic);
		e.addComponent(ic);

		return e;
	}

	public function makebaseItem(e:Entity, _x = 0, _y = 0):Entity {
		e.addComponent(new Position(_x, _y));
		e.addComponent(new Dimensions(32, 32));
		e.addComponent(ResourceFormat.getSurfaceSet("items"));

		var animatedRender:AnimatedRender = new AnimatedRender();
		e.addComponent(animatedRender);
		return e;
	}

	public function new(_gameContext:GameContext) {
		gameContext = _gameContext;
	}
}
