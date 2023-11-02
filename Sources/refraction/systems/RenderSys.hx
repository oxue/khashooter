package refraction.systems;

import hxblit.Camera;
import refraction.core.Sys;
import refraction.display.AnimatedRenderCmp;

class RenderSys extends Sys<AnimatedRenderCmp> {

	var camera:Camera;
	var pool:Array<AnimatedRenderCmp>;

	public function new(_camera:Camera) {
		camera = _camera;
		pool = [];
		super();
	}

	// TODO: fix this
	override public function produce():AnimatedRenderCmp {
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
			i++;
		}
	}
}
