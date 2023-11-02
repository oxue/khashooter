package refraction.generic;

import kha.math.Vector2;
import refraction.core.Component;

/**
 * ...
 * @author worldedit
 */
class DimensionsCmp extends Component {
	public var width:Int;
	public var height:Int;

	public function new(_width:Int = 20, _height:Int = 20) {
		super();
		width = _width;
		height = _height;
	}

	/**
		Auto_params
		@param w     width
		@param h     height
	 */
	override public function autoParams(_args:Dynamic) {
		width = _args.w;
		height = _args.h;
	}

	public function containsPoint(coords:Vector2):Bool {
		return coords.x <= width && coords.x >= 0 && coords.y <= height && coords.y >= 0;
	}
}
