package refraction.systems;

import refraction.core.Sys;
import refraction.display.LightSourceComponent;

/**
 * ...
 * @author
 */
class LightSourceSystem extends Sys<LightSourceComponent> {
	public function new() {
		super();
	}

	override public function updateComponent(comp:LightSourceComponent) {
		comp.light.position.x = comp.position.x + comp.offset.x;
		comp.light.position.y = comp.position.y + comp.offset.y;
	}
}
