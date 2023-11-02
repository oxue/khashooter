package components;

import refraction.core.Component;
import refraction.generic.VelocityCmp;
import refraction.stats.Norm.randNorm;

class Particle extends Component {

	public var lifespan:Int;

	public function new(_lifespan:Int) {
		lifespan = _lifespan;
		super();
	}

	override public function autoParams(_args:Dynamic) {
		lifespan = _args.lifespan;
	}

	public function randomDirection(magnitude:Float, ?biasAngleRad:Float, ?stdRad:Float) {
		var velocity:VelocityCmp = getEntity()
			.getComponent(VelocityCmp);
		var a:Float;
		if (biasAngleRad != null) {
			var std:Float = stdRad == null ? 0.5 : stdRad;
			a = randNorm(biasAngleRad, std);
		} else {
			a = Math.random() * Math.PI * 2;
		}
		velocity.setVelX(Math.cos(a) * magnitude);
		velocity.setVelY(Math.sin(a) * magnitude);
	}
}
