package game;

import entbuilders.ItemBuilder.Items;
import kha.math.Vector2;
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

	public function new(_type:Items = null, _name:String = "default"):Void {
		type = _type;
		name = _name;
	}

	public function castWeapon(_position:PositionCmp):Void {}

	public function persistCast(_positionc:PositionCmp):Void {}

	public function setAnimation(_anim:AnimatedRenderCmp):Void {}

	public function getAmmo(_i:Inventory):Void {}

	public function update():Void {}
}
