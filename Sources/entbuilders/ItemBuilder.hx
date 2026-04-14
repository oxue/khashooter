package entbuilders;

import components.InteractableCmp;
import game.GameContext;
import game.InventoryCmp;
import refraction.core.Entity;
import refraction.display.AnimatedRenderCmp;
import refraction.display.ResourceFormat;
import refraction.generic.DimensionsCmp;
import refraction.generic.PositionCmp;
import refraction.generic.Tooltip;

/**
 * ...
 * @author
 */
class ItemBuilder {
	public static inline var CROSSBOW_DEFAULT_ANIMATION = "crossbow_animation";
	public static inline var FLAMETHROWER_DEFAULT_ANIMATION = "flamethrower_animation";

	private var gameContext:GameContext;

	public function createHuntersCrossbow(_x = 0, _y = 0):Entity {
		return createWeaponItem(_x, _y, Items.HuntersCrossbow, CROSSBOW_DEFAULT_ANIMATION, [0], "Demon Hunter's Crossbow", kha.Color.Green);
	}

	public function createFlameThrower(_x = 0, _y = 0):Entity {
		return createWeaponItem(_x, _y, Items.Flamethrower, FLAMETHROWER_DEFAULT_ANIMATION, [5], "Flamethrower", kha.Color.Red);
	}

	public function createMachineGun(_x = 0, _y = 0):Entity {
		return createWeaponItem(_x, _y, Items.MachineGun, "default", [3], "Machine Gun", kha.Color.Red);
	}

	function createWeaponItem(_x:Int, _y:Int, itemType:Items, animName:String, animFrames:Array<Int>, tooltip:String, color:kha.Color):Entity {
		var e:Entity = makebaseItem(_x, _y);

		var animatedRender = e.getComponent(AnimatedRenderCmp);
		animatedRender.animations.set(animName, animFrames);
		animatedRender.setCurrentAnimation(animName);
		animatedRender.frame = 0;
		gameContext.renderSystem.addComponent(animatedRender);

		var tt:Tooltip = new Tooltip(tooltip, color);
		e.addComponent(tt);
		gameContext.tooltipSystem.addComponent(tt);

		var ic = new InteractableCmp(gameContext.camera, function(e:Entity) {
			gameContext.playerEntity
				.getComponent(InventoryCmp)
				.pickup(itemType);
			e.remove();
		});
		gameContext.interactSystem.addComponent(ic);
		e.addComponent(ic);

		return e;
	}

	public function makebaseItem(_x = 0, _y = 0):Entity {
		var e:Entity = new Entity();
		e.addComponent(new PositionCmp(_x, _y));
		e.addComponent(new DimensionsCmp(32, 32));
		e.addComponent(ResourceFormat.getSurfaceSet("items"));

		var animatedRender:AnimatedRenderCmp = new AnimatedRenderCmp();
		e.addComponent(animatedRender);
		return e;
	}

	public function new(_gameContext:GameContext) {
		gameContext = _gameContext;
	}
}

enum Items {
	Empty;
	HuntersCrossbow;
	Flamethrower;
	MachineGun;
}
