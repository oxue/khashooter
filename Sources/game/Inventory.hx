package game;

import entbuilders.ItemBuilder.Items;
import game.WeaponFactory;
import helpers.DebugLogger;
import kha.math.Vector2;
import refraction.core.Component;
import refraction.core.Utils;
import refraction.generic.Position;

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

	override public function load() {
		position = entity.getComponent(Position);
	}

	override public function update() {}

	public function pickup(_itemId:Items) {
		currentWeapon = WeaponFactory.create(_itemId);
		DebugLogger.info(
			"DEBUG",
			"weapon picked up " + Std.string(currentWeapon.type)
		);
		currentWeapon.muzzleOffset = new Vector2(
			14,
			7
		);
	}

	public function wieldingWeapon():Bool {
		return currentWeapon != null;
	}

	public function muzzlePositon():Vector2 {
		return position
			.vec()
			.add(Utils.rotateVec2(
				currentWeapon.muzzleOffset,
				Utils.a2rad(position.rotation)
			));
	}

	public function muzzleDirection():Vector2 {
		var worldMouse:Vector2 = EntFactory
			.instance()
			.worldMouse();
		// TODO: paramterize this later
		return Utils.rotateVec2(
			worldMouse.sub(position
				.vec()
				.add(new Vector2(
					0,
					0
				))
			),
			Math.random() * 0.1
		);
	}

	public function persistentAction() {
		if (currentWeapon == null) {
			return;
		}

		EntFactory
			.instance()
			.createFireball(
				muzzlePositon(),
				muzzleDirection()
			);
	}

	public function primaryAction() {
		if (currentWeapon == null) {
			return;
		}

		// Application.defaultCamera.shake(3, 2);
		// EntFactory
		// 	.instance()
		// 	.createFireball(muzzlePositon(), muzzleDirection());
	}
}
