package game;

import refraction.core.Component;
import refraction.display.AnimatedRenderCmp;
import refraction.generic.VelocityCmp;

/**
 * ...
 * @author worldedit
 */
class PlayerAnimation extends Component {

	public var weapons:AnimatedRenderCmp;

	var velocity:VelocityCmp;
	var blc:AnimatedRenderCmp;
	var inventory:Inventory;

	public function new() {
		super();
	}

	override public function load() {
		velocity = entity.getComponent(VelocityCmp);
		blc = entity.getComponent(AnimatedRenderCmp);
		weapons = entity.getComponent(AnimatedRenderCmp, "weapon_render_comp");
		inventory = entity.getComponent(Inventory);
	}

	function notMoving():Bool {
		return Math.round(
			velocity.getVelX()
		) == 0 && Math.round(velocity.getVelY()) == 0;
	}

	override public function update() {
		var idleAnimation:String = inventory.wieldingWeapon() ? "idle with weapon" : "idle";
		var walkingAnimation:String = inventory.wieldingWeapon() ? "running with weapon" : "running";

		if (notMoving()) {
			if (blc.curAnimaition != idleAnimation) {
				blc.curAnimaition = idleAnimation;
				blc.frame = 0;
			}
		} else if (blc.curAnimaition != walkingAnimation) {
			blc.curAnimaition = walkingAnimation;
			blc.frame = Std.int(Math.random() * 4);
		}
	}
}
