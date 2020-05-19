package systems;

import components.Interactable;
import refraction.core.Sys;
import refraction.core.Application;

class InteractSys extends Sys<Interactable> {
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
