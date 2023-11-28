package refraction.control;

import kha.input.KeyCode;
import game.GameContext;
import kha.math.FastVector2;
import refraction.core.Application;
import refraction.core.Component;
import refraction.generic.PositionCmp;
import refraction.generic.VelocityCmp;
import refraction.tilemap.TileCollisionCmp;

/**
 * ...
 * @author worldedit
 */
class KeyControl extends Component {
	private var position:PositionCmp;
	private var velocity:VelocityCmp;

	public var speed:Float;

	public function new(_speed:Float = 5) {
		super();
		speed = _speed;
	}

	override public function autoParams(_args:Dynamic) {
		speed = _args.speed;
	}

	override public function load() {
		position = entity.getComponent(PositionCmp);
		velocity = entity.getComponent(VelocityCmp);
	}

	override public function update() {
		// no clip
		this.entity.getComponent(TileCollisionCmp).enabled = !GameContext.instance().config.system.noclip;

		var acc:FastVector2 = new FastVector2();

		if (Application.keys.get(KeyCode.A))
			acc.x = -1;
		if (Application.keys.get(KeyCode.D))
			acc.x = 1;
		if (Application.keys.get(KeyCode.W))
			acc.y = -1;
		if (Application.keys.get(KeyCode.S))
			acc.y = 1;

		acc.normalize();
		acc = acc.mult(speed);

		velocity.addVelX(acc.x);
		velocity.addVelY(acc.y);
	}
}
