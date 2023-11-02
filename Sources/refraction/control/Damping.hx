package refraction.control;

import refraction.core.Component;
import refraction.generic.PositionCmp;
import refraction.generic.VelocityCmp;

/**
 * ...
 * @author worldedit
 */
class Damping extends Component {
	private var velocity:VelocityCmp;
	private var factor:Float;

	public function new(_factor:Float = 0.9) {
		factor = _factor;
		super();
	}

	override public function autoParams(_args:Dynamic):Void {
		factor = _args.factor;
	}

	override public function load():Void {
		velocity = entity.getComponent(VelocityCmp);
	}

	override public function update():Void {
		velocity.timesVelX(factor);
		velocity.timesVelY(factor);
	}
}
