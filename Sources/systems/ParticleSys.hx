package systems;

import refraction.core.Sys;
import components.Particle;

class ParticleSys extends Sys<Particle> {
	public function new() {
		super();
	}

	override public function update():Void {
		var i = components.length;
		while (i-- > 0) {
			var particle = components[i];
			if (particle.remove) {
				components[i] = components[components.length - 1];
				components.pop();
				continue;
			}
			particle.lifespan -= 1;
			if (particle.lifespan <= 0) {
				particle
					.getEntity()
					.remove();
			}
		}
	}
}
