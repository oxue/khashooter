package;

import kha.math.FastVector2;
import refraction.control.BreadCrumbs;
import refraction.core.Component;
import refraction.display.AnimatedRender;
import refraction.generic.Position;
import refraction.generic.Velocity;
import refraction.utils.Interval;

/**
 * ...
 * @author
 */
class MimiAI extends Component {
	public var breadcrumbs:BreadCrumbs;
	public var randTargetInterval:Interval;
	public var position:Position;
	public var velocity:Velocity;

	private var blc:AnimatedRender;

	public var lastX:Float;
	public var lastY:Float;

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

	override public function load():Void {
		breadcrumbs = entity.getComponent(BreadCrumbs);
		position = entity.getComponent(Position);
		velocity = entity.getComponent(Velocity);
		blc = entity.getComponent(AnimatedRender);

		lastX = position.x;
		lastY = position.y;
	}

	override public function update():Void {
		randTargetInterval.tick();
		if (Math.round(position.x - lastX) == 0 && Math.round(position.y - lastY) == 0) {
			blc.curAnimaition = "idle";
			blc.frame = 0;
		} else {
			blc.curAnimaition = "running";
		}
		lastX = position.x;
		lastY = position.y;
	}
}
