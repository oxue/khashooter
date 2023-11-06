package game;

import entbuilders.ItemBuilder.Items;
import game.weapons.Empty.EmptyWeapon;
import game.weapons.Flamethrower;
import game.weapons.HuntersCrossbow;
import game.weapons.MachineGun;
import haxe.ds.EnumValueMap;
import helpers.DebugLogger;
import kha.input.KeyCode;
import kha.math.Vector2;
import refraction.core.Application;
import refraction.core.Component;
import refraction.generic.PositionCmp;

/**
 * ...
 * @author worldedit
 */
class InventoryCmp extends Component {

	var currentWeapon:Weapon;
	var position:PositionCmp;

	var weapons:Array<Weapon>;
	var currentWeaponIndex:Int;

	var weaponTypeToIndexMap:EnumValueMap<Items, Int>;

	public function new() {
		weapons = initializeWeaponsArr();
		weaponTypeToIndexMap = new EnumValueMap<Items, Int>();
		for (i in 0...weapons.length) {
			weaponTypeToIndexMap.set(weapons[i].type, i);
		}
		currentWeaponIndex = 0;
		setWeapon(currentWeaponIndex);
		Application.addKeyDownListener((code:KeyCode) -> {
			if (code == KeyCode.Q) {
				inventoryScroll(-1);
			} else if (code == KeyCode.E) {
				inventoryScroll(1);
			}
		});
		super();
	}

	function inventoryScroll(direction:Int) {
		currentWeaponIndex += direction;
		currentWeaponIndex = (currentWeaponIndex + weapons.length) % weapons.length;
		while (!weapons[currentWeaponIndex].enabled) {
			currentWeaponIndex += direction;
			currentWeaponIndex = (currentWeaponIndex + weapons.length) % weapons.length;
		}
		setWeapon(currentWeaponIndex);
	}

	function setWeapon(index:Int) {
		currentWeaponIndex = index;
		currentWeapon = weapons[currentWeaponIndex];
		GameContext.instance().statusText.text = Std.string(currentWeapon.type);
		GameContext.instance().statusText.x = 0;
		GameContext.instance().statusText.y = 20;
	}

	function setWeaponType(type:Items) {
		setWeapon(weaponTypeToIndexMap.get(type));
	}

	function initializeWeaponsArr():Array<Weapon> {
		var ret:Array<Weapon> = [];

		var empty:EmptyWeapon = new EmptyWeapon();
		empty.enabled = true;

		ret.push(empty);
		ret.push(new HuntersCrossbow());
		ret.push(new Flamethrower());
		ret.push(new MachineGun());

		return ret;
	}

	override public function load() {
		position = entity.getComponent(PositionCmp);
	}

	override public function update() {}

	public function pickup(itemType:Items) {
		setWeaponType(itemType);
		currentWeapon.enabled = true;
		DebugLogger.info(
			"DEBUG",
			"weapon picked up " + Std.string(currentWeapon.type)
		);
		// disable empty weapon
		weapons[0].enabled = false;
		// TODO: move this somewhere better
		currentWeapon.muzzleOffset = new Vector2(14, 7);
	}

	public function wieldingWeapon():Bool {
		return currentWeapon != null;
	}

	public function persistentAction() {
		currentWeapon.persistCast(position);
	}

	public function primaryAction() {
		currentWeapon.castWeapon(position);

		// EntFactory
		// 	.instance()
		// 	.createFireball(muzzlePositon(), muzzleDirection());
	}
}
