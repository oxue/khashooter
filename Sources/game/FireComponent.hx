package game;

import refraction.display.LightSourceComponent;
import refraction.core.Component;
import refraction.generic.Position;

/**
 * ...
 * @author qwerber
 */
class FireComponent extends Component {
	public var lightSource:LightSourceComponent;
	public var position:Position;

	private var t:Int;
	private var timer:Int;

	public function new() {
		super();
	}

	override public function load():Void {
		position = entity.getComponent(Position);
		lightSource = entity.getComponent(LightSourceComponent);
		timer = GameContext
			.instance()
			.configurations.flamethrower_total_particle_life;
	}

	override public function update():Void {
		t++;
		if (t >= timer || lightSource.light.radius <= 0) {
			entity.remove();
			lightSource.remove = true;
		}
		if (t < GameContext
			.instance()
			.configurations.flamethrower_grow_util
		)
			lightSource.light.radius += GameContext
				.instance()
				.configurations.flamethrower_grow_rate;

		lightSource.light.v3Color.x += (1 - lightSource.light.v3Color.x) / 60;
		lightSource.light.v3Color.y += (0.6 - lightSource.light.v3Color.y) / 60;
		lightSource.light.v3Color.z -= 0.040;

		if (t > GameContext
			.instance()
			.configurations.flamethrower_shrink_after
		) {
			lightSource.light.radius -= GameContext
				.instance()
				.configurations.flamethrower_shrink_rate;
		}
	}
}
