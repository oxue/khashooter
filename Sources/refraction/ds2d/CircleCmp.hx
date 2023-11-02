package refraction.ds2d;

import refraction.core.Component;
import refraction.generic.PositionCmp;

/**
 * ...
 * @author qwerber
 */
class CircleCmp extends Component {

	public var x:Float;
	public var y:Float;
	public var radius:Float;
	public var position:PositionCmp;

	public function new(_x:Float, _y:Float, _radius:Float) {
		x = _x;
		y = _y;
		radius = _radius;
		super();
	}

	override public function load() {
		position = cast entity.components.get("pos_comp");
	}
}
