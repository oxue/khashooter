package components;

import refraction.core.Component;
import refraction.generic.Velocity;

class Particle extends Component {
	public var lifespan:Int;

	public function new(_lifespan:Int) {
		lifespan = _lifespan;
		super();
	}

	override public function autoParams(_args:Dynamic):Void {
		lifespan = _args.lifespan;
	}

	public function randomDirection(_magnitude:Float):Void {
		var velocity = getEntity()
			.getComponent(Velocity);
		var a = Math.random() * 3.14159 * 2;
		velocity.setVelX(Math.cos(a) * _magnitude);
		velocity.setVelY(Math.sin(a) * _magnitude);
	}
}
