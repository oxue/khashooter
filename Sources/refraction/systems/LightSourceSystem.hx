package refraction.systems;

import refraction.core.Sys;
import refraction.display.LightSourceCmp;

/**
 * ...
 * @author
 */
class LightSourceSystem extends Sys<LightSourceCmp> {
	public function new() {
		super();
	}

	override public function updateComponent(comp:LightSourceCmp) {
		comp.light.position.x = comp.position.x;
		comp.light.position.y = comp.position.y;
	}
}
