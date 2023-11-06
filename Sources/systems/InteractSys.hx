package systems;

import components.InteractableCmp;
import refraction.core.Application;
import refraction.core.Sys;

class InteractSys extends Sys<InteractableCmp> {
	override public function update() {
		sweepRemoved();
		var hoveredItems = components.filter(function(ic) return ic.containsCursor());
		if (hoveredItems.length != 0) {
			if (Application.mouseIsDown) {
				hoveredItems[0].interactFunc(hoveredItems[0].entity);
			}
		}
	}
}
