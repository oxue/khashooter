package game.weapons;

import entbuilders.ItemBuilder.Items;
import refraction.generic.PositionCmp;

class Flamethrower extends Weapon {

	public function new() {
		super(Items.Flamethrower);
	}

	override function persistCast(_position:PositionCmp) {
		EntFactory
			.instance()
			.createFireball(
				calcMuzzlePosition(_position),
				muzzleDirection(_position)
			);
	}
}
