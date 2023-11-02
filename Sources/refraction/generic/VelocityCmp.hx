package refraction.generic;

import kha.math.Vector2;
import refraction.core.Component;
import refraction.core.Utils;

/**
 * ...
 * @author worldedit
 */
class VelocityCmp extends Component {

	public static final TWIP_LOCK_EPSILON:Float = 0.05;

	var position:PositionCmp;
	var velX:Float;
	var velY:Float;

	var publiclyTwipLocked:Bool;

	public function new() {
		velX = velY = 0;
		publiclyTwipLocked = true;
		super();
	}

	public function getVelX():Float {
		if (Math.abs(
			velX
		) < TWIP_LOCK_EPSILON && publiclyTwipLocked) {
			return 0;
		}
		return velX;
	}

	public function getVelY():Float {
		if (Math.abs(
			velY
		) < TWIP_LOCK_EPSILON && publiclyTwipLocked) {
			return 0;
		}
		return velY;
	}

	public function setVelX(_value:Float) {
		velX = _value;
	}

	public function setVelY(_value:Float) {
		velY = _value;
	}

	public function addVelX(_value:Float) {
		velX += _value;
	}

	public function addVelY(_value:Float) {
		velY += _value;
	}

	public function timesVelX(_value:Float) {
		velX *= _value;
	}

	public function timesVelY(_value:Float) {
		velY *= _value;
	}

	override public function load() {
		position = entity.getComponent(PositionCmp);
	}

	public function vec():Vector2 {
		return new Vector2(getVelX(), getVelY());
	}

	override public function update() {
		position.x += getVelX();
		position.y += getVelY();
	}

	public function interpolate(speed:Float) {
		var len:Float = Math.sqrt(Utils.sq(velX) + Utils.sq(velY));
		if (len < speed) {
			return;
		}
		velX = velX / len * speed;
		velY = velY / len * speed;
	}
}
