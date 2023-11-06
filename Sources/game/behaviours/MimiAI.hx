package game.behaviours;

import kha.math.FastVector2;
import refraction.control.BreadCrumbs;
import refraction.core.Component;
import refraction.display.AnimatedRenderCmp;
import refraction.generic.PositionCmp;
import refraction.generic.VelocityCmp;
import refraction.utils.Interval;

/**
 * ...
 * @author
 */
class MimiAI extends Component {
	public var breadcrumbs:BreadCrumbs;
	public var randTargetInterval:Interval;
	public var position:PositionCmp;
	public var velocity:VelocityCmp;

	public var lastX:Float;
	public var lastY:Float;

	var blc:AnimatedRenderCmp;

	public function new() {
		super();
		randTargetInterval = new Interval(walk, 120);
	}

	function walk() {
		if (breadcrumbs.breadcrumbs[0] == null) {
			breadcrumbs.breadcrumbs.push(new FastVector2());
		}

		breadcrumbs.breadcrumbs[0].x = position.x + Math.random() * 300 - 150;
		breadcrumbs.breadcrumbs[0].y = position.x + Math.random() * 300 - 150;
	}

	override public function load() {
		breadcrumbs = entity.getComponent(BreadCrumbs);
		position = entity.getComponent(PositionCmp);
		velocity = entity.getComponent(VelocityCmp);
		blc = entity.getComponent(AnimatedRenderCmp);

		lastX = position.x;
		lastY = position.y;
	}

	override public function update() {
		randTargetInterval.tick();
		if (Math.round(position.x - lastX) == 0 && Math.round(position.y - lastY) == 0) {
			blc.curAnimation = "idle";
			blc.frame = 0;
		} else {
			blc.curAnimation = "running";
		}
		lastX = position.x;
		lastY = position.y;
	}
}
