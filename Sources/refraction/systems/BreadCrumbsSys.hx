package refraction.systems;

import haxe.macro.Compiler;
import kha.math.FastVector2;
import refraction.control.BreadCrumbs;
import refraction.core.Sys;

/**
 * ...
 * @author
 */
class BreadCrumbsSys extends Sys<BreadCrumbs> {
	public function new() {
		super();
	}

	override public function updateComponent(comp:BreadCrumbs) {
		if (comp.breadcrumbs.length != 0 && comp.breadcrumbs[0] != null) {
			var crumb:FastVector2 = comp.breadcrumbs[0];
			var direction:FastVector2 = new FastVector2(crumb.x - comp.position.x, crumb.y - comp.position.y);
			direction.normalize();
			direction = direction.mult(comp.maxAcceleration);

			comp.velocity.addVelX(direction.x);
			comp.velocity.addVelY(direction.y);

			var s = Math.atan2(direction.y, direction.x);
			var targetRotation = s * 57.3;
			var diff = targetRotation - comp.position.rotationDegrees;
			if (diff < 0)
				diff += 360;
			if (diff >= 360)
				diff -= 360;
			if (diff > 180)
				diff -= 360;
			comp.position.rotationDegrees += diff / 5;

			var diff = new FastVector2(crumb.x - comp.position.x, crumb.y - comp.position.y);
			if (diff.length < comp.acceptanceRadius) {
				comp.breadcrumbs.shift();
			}
		}
	}
}
