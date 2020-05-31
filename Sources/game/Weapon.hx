package game;

import refraction.display.AnimatedRender;
import refraction.generic.Position;
import kha.math.Vector2;

/**
 * ...
 * @author worldedit
 */
class Weapon {
	public var type:Int;
	public var name:String;
	public var ammo:AmmunitionObject;
	public var muzzleOffset:Vector2;

	public function new(_type:Int = 0, _name:String = "default"):Void {
		type = _type;
		name = _name;
	}

	public function castWeapon(_position:Position):Void {}

	public function persistCast(_positionc:Position):Void {}

	public function setAnimation(_anim:AnimatedRender):Void {}

	public function getAmmo(_i:Inventory):Void {}

	public function update():Void {}
}
