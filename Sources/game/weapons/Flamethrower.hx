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

		var netState = GameContext.instance().netState;
		if (netState != null && netState.isConnected()) {
			var dirDeg:Float = Math.atan2(muzzleDir.y, muzzleDir.x) * (180 / 3.1415926);
			var dmgField:Dynamic = Reflect.field(GameContext.instance().config, "flamethrower_damage");
			var damage:Float = (dmgField != null) ? cast(dmgField, Float) : 3.0;
			netState.sendShoot("flamethrower", muzzlePos.x, muzzlePos.y, dirDeg, damage);
		}
	}
}
