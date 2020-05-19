package refraction.control;

import refraction.core.Component;
import refraction.generic.Position;
import refraction.generic.Velocity;

/**
 * ...
 * @author worldedit
 */
class Damping extends Component {
	private var velocity:Velocity;
	private var factor:Float;

	public function new(_factor:Float = 0.9) {
		factor = _factor;
		super();
	}

	override public function autoParams(_args:Dynamic):Void {
		factor = _args.factor;
	}

	override public function load():Void {
		velocity = entity.getComponent(Velocity);
	}

	override public function update():Void {
		velocity.timesVelX(factor);
		velocity.timesVelY(factor);
	}
}
