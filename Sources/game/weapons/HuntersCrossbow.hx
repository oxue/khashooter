package game.weapons;

import entbuilders.ItemBuilder.Items;
import refraction.core.Application;
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
		notifyWeaponFired("crossbow", muzzlePos, muzzleDir, 10);
	}
}
