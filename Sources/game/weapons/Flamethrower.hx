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
		if (gc.playerEntity != null) {
			var dirDeg:Float = Math.atan2(muzzleDir.y, muzzleDir.x) * (180 / 3.1415926);
			var dmgField:Dynamic = Reflect.field(gc.config, "flamethrower_damage");
			var damage:Float = (dmgField != null) ? cast(dmgField, Float) : 3.0;
			gc.playerEntity.notify("weapon_fired", {weapon: "flamethrower", x: muzzlePos.x, y: muzzlePos.y, dir: dirDeg, damage: damage});
		}
	}
}
