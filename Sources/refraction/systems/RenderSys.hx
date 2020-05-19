package refraction.systems;

import refraction.core.Sys;
import refraction.display.AnimatedRender;
import hxblit.Camera;
import refraction.utils.ObjectPool;

class RenderSys extends Sys<AnimatedRender> {
	private var camera:Camera;
	private var pool:Array<AnimatedRender>;

	public function new(_camera:Camera) {
		camera = _camera;
		pool = new Array<AnimatedRender>();
		super();
	}

	override public function produce():AnimatedRender {
		if (pool.length != 0) {
			// return pool.pop();
		}
		return null;
	}

	override public function update() {
		var i = 0;
		while (i < components.length) {
			var c = components[i];
			if (c.remove) {
				removeIndex(i); // , pool);
				continue;
			}
			c.draw(camera);
			++i;
		}
	}
}
