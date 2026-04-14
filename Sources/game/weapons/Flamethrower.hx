package game.weapons;

import entbuilders.ItemBuilder.Items;
import game.GameContext;
import refraction.generic.PositionCmp;

class Flamethrower extends Weapon {

	public function new() {
		super(Items.Flamethrower);
	}

	override function persistCast(_position:PositionCmp) {
		var muzzlePos = calcMuzzlePosition(_position);
		var muzzleDir = muzzleDirection(_position);
		EntFactory
			.instance()
			.createFireball(
				muzzlePos,
				muzzleDir
			);

		var gc = GameContext.instance();
		var dmgField:Dynamic = (gc != null) ? Reflect.field(gc.config, "flamethrower_damage") : null;
		var damage:Float = (dmgField != null) ? cast(dmgField, Float) : 3.0;
		notifyWeaponFired("flamethrower", muzzlePos, muzzleDir, damage);
	}
}
