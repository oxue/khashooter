package game;

import helpers.DebugLogger;
import entbuilders.ItemBuilder.Items;
import refraction.core.Component;
import refraction.generic.Position;
import kha.math.Vector2;
import refraction.core.Utils;
import game.WeaponFactory;

/**
 * ...
 * @author worldedit
 */
class Inventory extends Component {
	private var currentWeapon:Weapon;
	private var position:Position;

	public function new() {
		super();
	}

	override public function load():Void {
		position = entity.getComponent(Position);
	}

	override public function update():Void {}

	public function pickup(_itemId:Items):Void {
		currentWeapon = WeaponFactory.create(_itemId);
		DebugLogger.info("DEBUB", "weapon picked up " + Std.string(currentWeapon.type));
		currentWeapon.muzzleOffset = new Vector2(14, 7);
	}

	public function wieldingWeapon():Bool {
		return currentWeapon != null;
	}

	public function muzzlePositon():Vector2 {
		return position
			.vec()
			.add(Utils.rotateVec2(currentWeapon.muzzleOffset, Utils.a2rad(position.rotation)));
	}

	public function muzzleDirection():Vector2 {
		var worldMouse = EntFactory
			.instance()
			.worldMouse();
		// TODO: paramterize this later
		return Utils.rotateVec2(worldMouse.sub(position
			.vec()
			.add(new Vector2(0, 0))
		), Math.random() * 0.1);
	}

	public function persist():Void {
		if (currentWeapon == null) {
			return;
		}

		EntFactory
			.instance()
			.createFireball(muzzlePositon(), muzzleDirection());
	}

	public function primary():Void {
		if (currentWeapon == null) {
			return;
		}

		// Application.defaultCamera.shake(3, 2);
		// EntFactory
		// 	.instance()
		// 	.createFireball(muzzlePositon(), muzzleDirection());
	}
}
