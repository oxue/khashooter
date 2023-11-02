package refraction.control;

import kha.math.FastVector2;
import refraction.core.Component;
import refraction.generic.PositionCmp;
import refraction.generic.VelocityCmp;

/**
 * ...
 * @author
 */
class BreadCrumbs extends Component {
	public var breadcrumbs:Array<FastVector2>;
	public var acceptanceRadius:Float;
	public var maxAcceleration:Float;

	public var position:PositionCmp;
	public var velocity:VelocityCmp;

	public function new() {
		breadcrumbs = new Array();

		super();
	}

	override public function autoParams(_args:Dynamic):Void {
		acceptanceRadius = _args.acceptanceRadius;
		maxAcceleration = _args.maxAcceleration;
	}

	public function addBreadCrumb(_v:FastVector2) {
		breadcrumbs.push(_v);
	}

	public function clear():Void {
		breadcrumbs = new Array();
	}

	override public function load():Void {
		position = entity.getComponent(PositionCmp);
		velocity = entity.getComponent(VelocityCmp);
	}
}
