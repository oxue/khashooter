package game;

import entbuilders.ItemBuilder.Items;
import kha.math.Vector2;
import refraction.core.Utils;
import refraction.display.AnimatedRenderCmp;
import refraction.generic.PositionCmp;

/**
 * ...
 * @author worldedit
 */
class Weapon {

	public var type:Items;
	public var name:String;
	public var ammo:AmmunitionObject;
	public var muzzleOffset:Vector2;
	public var enabled:Bool;

	public function new(_type:Items = null, _name:String = "default") {
		type = _type;
		name = _name;
		enabled = false;
	}

	public function calcMuzzlePosition(position:PositionCmp):Vector2 {
		return position
			.vec()
			.add(
				Utils.rotateVec2(muzzleOffset, Utils.a2rad(position.rotationDegrees))
			);
	}

	public function muzzleDirection(position:PositionCmp):Vector2 {
		var worldMouse:Vector2 = EntFactory
			.instance()
			.worldMouse();
		// TODO: paramterize this later
		return Utils.rotateVec2(
			worldMouse.sub(position
				.vec()
				.add(new Vector2(0, 0))
			),
			// 0
			Math.random() * 0.1 - 0.05
		);
	}

	public function castWeapon(_position:PositionCmp) {}

	public function persistCast(_positionc:PositionCmp) {}

	public function setAnimation(_anim:AnimatedRenderCmp) {}

	public function getAmmo(_i:InventoryCmp) {}

	public function update() {}
}
