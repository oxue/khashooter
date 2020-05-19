package refraction.generic;

import refraction.core.Component;
import refraction.core.Utils;
import kha.math.Vector2;

/**
 * ...
 * @author worldedit
 */
class Velocity extends Component {
	private var position:Position;
	private var velX:Float;
	private var velY:Float;

	private var publiclyTwipLocked:Bool = true;

	public function new() {
		velX = velY = 0;
		super();
	}

	public function getVelX():Float {
		return (publiclyTwipLocked && Math.abs(velX) < 0.05) ? 0 : velX;
	}

	public function getVelY():Float {
		return (publiclyTwipLocked && Math.abs(velY) < 0.05) ? 0 : velY;
	}

	public function setVelX(_value:Float):Void {
		velX = _value;
	}

	public function setVelY(_value:Float):Void {
		velY = _value;
	}

	public function addVelX(_value:Float):Void {
		velX += _value;
	}

	public function addVelY(_value:Float):Void {
		velY += _value;
	}

	public function timesVelX(_value:Float):Void {
		velX *= _value;
	}

	public function timesVelY(_value:Float):Void {
		velY *= _value;
	}

	override public function load():Void {
		position = entity.getComponent(Position);
	}

	public function vec():Vector2 {
		return new Vector2(getVelX(), getVelY());
	}

	override public function update():Void {
		position.x += getVelX();
		position.y += getVelY();
	}

	public function interpolate(speed:Float) {
		var len = Math.sqrt(Utils.sq(velX) + Utils.sq(velY));
		if (len < speed) {
			return;
		}
		velX = velX / len * speed;
		velY = velY / len * speed;
	}
}
