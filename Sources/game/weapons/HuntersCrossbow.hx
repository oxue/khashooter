package game.weapons;

import entbuilders.ItemBuilder.Items;
import refraction.core.Application;
import game.GameContext;
import refraction.generic.PositionCmp;

class HuntersCrossbow extends Weapon {

	public function new() {
		super(Items.HuntersCrossbow);
	}

	override public function castWeapon(_position:PositionCmp) {
		var muzzlePos = calcMuzzlePosition(_position);
		var muzzleDir = muzzleDirection(_position);
		EntFactory
			.instance()
			.createProjectile(muzzlePos, muzzleDir);
		Application.defaultCamera.shake(6, 4);

		var gc = GameContext.instance();
		if (gc.playerEntity != null) {
			var dirDeg:Float = Math.atan2(muzzleDir.y, muzzleDir.x) * (180 / 3.1415926);
			gc.playerEntity.notify("weapon_fired", {weapon: "crossbow", x: muzzlePos.x, y: muzzlePos.y, dir: dirDeg, damage: 10});
		}
	}
}
