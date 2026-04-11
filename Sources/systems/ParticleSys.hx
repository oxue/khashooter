package systems;

import refraction.core.Sys;
import components.ParticleCmp;

class ParticleSys extends Sys<ParticleCmp> {

    public function new() {
        super();
    }

    override public function update() {
        var i = components.length;
        while (i-- > 0) {
            var particle:ParticleCmp = components[i];
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
