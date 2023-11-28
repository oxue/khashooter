package refraction.generic;

import hxblit.Camera;
import kha.math.Vector2;
import refraction.core.Component;

/**
 * ...
 * @author worldedit
 */
class PositionCmp extends Component {

	public var x:Float;
	public var y:Float;

	public var rotationDegrees:Float;

	public function new(_x:Float = 0, _y:Float = 0, _rotation:Float = 0) {
		x = _x;
		y = _y;
		rotationDegrees = _rotation;
		super();
	}

	public function setPosition(_x:Float = 0, _y:Float = 0, ?_rotation):PositionCmp {
		x = _x;
		y = _y;
		if (_rotation != null) {
			rotationDegrees = _rotation;
		}
		return this;
	}

	public function setFromPosition(_p:PositionCmp):PositionCmp {
		return setPosition(_p.x, _p.y);
	}

	override public function autoParams(_args:Dynamic):Void {
		// x = _args.x;
		// y = _args.y;
	}

	public function vec():Vector2 {
		return new Vector2(x, y);
	}

	public function toString():String {
		return "<" + x + " " + y + ">\n";
	}

	public function distanceToSquared(position:PositionCmp): Float {
		return (x - position.x) * (x - position.x) + (y - position.y) * (y - position.y);
	}

	public function equals(position:PositionCmp):Bool {
		return position.x == x && position.y == y;
	}

	public function drawPoint(camera:Camera, g2:kha.graphics2.Graphics) {
		g2.color = kha.Color.Green;
		g2.drawRect(
			(x - camera.x + 1) * 2,
			(y - camera.y - 1) * 2,
			2,
			2,
			1.0
		);
	}
}
