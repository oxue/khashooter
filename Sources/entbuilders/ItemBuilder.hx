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

	public function createHuntersCrossbow(_x = 0, _y = 0):Entity {
		var e:Entity = makebaseItem(_x, _y);

		var animatedRender = e.getComponent(AnimatedRender);
		animatedRender.animations.set(CROSSBOW_DEFAULT_ANIMATION, [0]);
		animatedRender.setCurrentAnimation(CROSSBOW_DEFAULT_ANIMATION);
		animatedRender.frame = 0;
		gameContext.renderSystem.addComponent(animatedRender);

		var tt:Tooltip = new Tooltip("Demon Hunter's Crossbow", kha.Color.Green);
		e.addComponent(tt);
		gameContext.tooltipSystem.addComponent(tt);

		var ic = new Interactable(gameContext.camera, function(e:Entity) {
			gameContext.playerEntity
				.getComponent(Inventory)
				.pickup(Items.HuntersCrossbow);
			e.remove();
		});
		gameContext.interactSystem.addComponent(ic);
		e.addComponent(ic);

		return e;
	}

	public function createFlameThrower(_x = 0, _y = 0):Entity {
		var e = makebaseItem(_x, _y);
		var animatedRender = e.getComponent(AnimatedRender);
		animatedRender.animations.set(FLAMETHROWER_DEFAULT_ANIMATION, [5]);
		animatedRender.setCurrentAnimation(FLAMETHROWER_DEFAULT_ANIMATION);
		animatedRender.frame = 0;
		gameContext.renderSystem.addComponent(animatedRender);

		var tt:Tooltip = new Tooltip("Flamethrower", kha.Color.Red);
		e.addComponent(tt);
		gameContext.tooltipSystem.addComponent(tt);

		var ic = new Interactable(gameContext.camera, function(e:Entity) {
			gameContext.playerEntity
				.getComponent(Inventory)
				.pickup(Items.Flamethrower);
			e.remove();
		});
		gameContext.interactSystem.addComponent(ic);
		e.addComponent(ic);

		return e;
	}

	public function makebaseItem(_x = 0, _y = 0):Entity {
		var e:Entity = new Entity();
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

enum Items {
	HuntersCrossbow;
	Flamethrower;
}
