package game;

import refraction.core.Component;
import refraction.display.LightSourceCmp;
import refraction.generic.PositionCmp;

/**
 * ...
 * @author qwerber
 */
class FireCmp extends Component {

	public var lightSource:LightSourceCmp;
	public var position:PositionCmp;

	var t:Int;
	var timer:Int;

	public function new() {
		super();
	}

	override public function load() {
		position = entity.getComponent(PositionCmp);
		lightSource = entity.getComponent(LightSourceCmp);
		timer = GameContext
			.instance()
			.config.flamethrower_total_particle_life;
	}

	override public function update() {
		t++;
		if (t >= timer || lightSource.light.radius <= 0) {
			entity.remove();
			lightSource.remove = true;
		}
		if (t < GameContext
			.instance()
			.config.flamethrower_grow_util
		) {
			lightSource.light.radius += GameContext
				.instance()
				.config.flamethrower_grow_rate;
		}

		lightSource.light.v3Color.x += (1 * 0.3 - lightSource.light.v3Color.x) / 60;
		lightSource.light.v3Color.y += (0.6 * 0.3 - lightSource.light.v3Color.y) / 60;
		lightSource.light.v3Color.z -= 0.12;

		if (t > GameContext
			.instance()
			.config.flamethrower_shrink_after
		) {
			lightSource.light.radius -= GameContext
				.instance()
				.config.flamethrower_shrink_rate;
		}
	}
}
