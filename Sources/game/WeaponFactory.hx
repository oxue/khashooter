package game;

import entbuilders.ItemBuilder.Items;
import game.weapons.Flamethrower;
import game.weapons.HuntersCrossbow;
import haxe.Constraints.Constructible;

class WeaponFactory {
	private static var weaponCtorMap:Map<Items, Class<Weapon>> = [
		Items.HuntersCrossbow => game.weapons.HuntersCrossbow,
		Items.Flamethrower => game.weapons.Flamethrower
	];

	public static function create(itemId:Items):Weapon {
		if (!weaponCtorMap.exists(itemId)) {
			return null;
		}
		var clazz = weaponCtorMap.get(itemId);
		return Type.createInstance(clazz, []);
	}
}
