package game.weapons;

import entbuilders.ItemBuilder.Items;
import refraction.core.Application;
import refraction.generic.PositionCmp;

class HuntersCrossbow extends Weapon {

	public function new() {
		super(Items.HuntersCrossbow);
	}

	override public function castWeapon(_position:PositionCmp) {
		EntFactory
			.instance()
			.createProjectile(calcMuzzlePosition(_position), muzzleDirection(_position));
		Application.defaultCamera.shake(6, 4);
	}
}
