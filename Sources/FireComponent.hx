package;

import refraction.core.Component;
import refraction.core.Utils;
import refraction.ds2d.LightSource;
import refraction.core.Sys;
import refraction.generic.Position;

/**
 * ...
 * @author qwerber
 */
class FireComponent extends Component {
	public var targetLight:LightSource;
	public var position:Position;

	public var targetSystem:Sys<EnemyCollideComponent>;

	private var t:Int;
	private var timer:Int;

	public function new() {
		super("fire_comp");
	}

	override public function load():Void {
		position = cast entity.components.get("pos_comp");
		timer = 60;
	}

	override public function update():Void {
		t++;
		if (t >= timer) {
			entity.remove();
			targetLight.remove = true;
		}
		if (t < 20)
			targetLight.radius += 1;
		targetLight.v3Color.x += (1 - targetLight.v3Color.x) / 15;
		targetLight.v3Color.y += (0.6 - targetLight.v3Color.y) / 15;
		targetLight.v3Color.z -= 0.080;
		if (t > 50) {
			targetLight.radius -= 2;
		}
		var i:Int = targetSystem.components.length;
		while (i-- > 0) {
			var e:EnemyCollideComponent = targetSystem.components[i];
			if (Utils.posDis2(e.position, position) < e.radius2 + Utils.f2(targetLight.radius) && t > 20) {
				e.health.applyHealth(-5);
			}
		}
	}
}
