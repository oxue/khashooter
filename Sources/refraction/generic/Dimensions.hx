package refraction.generic;

import refraction.core.Component;
import kha.math.Vector2;

/**
 * ...
 * @author worldedit
 */
class Dimensions extends Component {
	public var width:Int;
	public var height:Int;

	public function new(_width:Int = 20, _height:Int = 20) {
		super();
		width = _width;
		height = _height;
	}

	override public function autoParams(_args:Dynamic):Void {
		width = _args.w;
		height = _args.h;
	}

	public function containsPoint(coords:Vector2):Bool {
		return coords.x <= width && coords.x >= 0 && coords.y <= height && coords.y >= 0;
	}
}
