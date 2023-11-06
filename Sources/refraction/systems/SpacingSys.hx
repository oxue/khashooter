package refraction.systems;

// import flash.Vector;
import kha.math.FastVector2;
import refraction.core.Component;
import refraction.core.Sys;
import refraction.core.Utils;
import refraction.generic.PositionCmp;
import refraction.generic.VelocityCmp;

/**
 * ...
 * @author worldedit
 */
class SpacingCmp extends Component {

	public var position:PositionCmp;
	public var velocity:VelocityCmp;
	public var radius:Float;

	public function new() {
		super();
	}

	override public function autoParams(_args:Dynamic) {
		radius = _args.radius;
	}

	override public function load() {
		position = entity.getComponent(PositionCmp);
		velocity = entity.getComponent(VelocityCmp);
	}
}

class SpacingSys extends Sys<SpacingCmp> {

	var spacingFactor:Float;

	public function new() {
		super();

		spacingFactor = 0.125;
	}

	override public function update() {
		var i:Int = components.length;
		while (i-- > 0) {
			var spacer:SpacingCmp = components[i];
			if (spacer.position.remove) {
				Utils.quickRemoveIndex(components, i);
				continue;
			}
			pushSpacer(spacer);
		}
	}

	function pushSpacer(spacer:SpacingCmp) {
		var position:PositionCmp = spacer.position;
		var aggDisplaceTargetX:Float = 0;
		var aggDisplaceTargetY:Float = 0;
		for (spacer2 in components) {
			var position2:PositionCmp = spacer2.position;
			if (spacer == spacer2) {
				continue;
			}

			var r2:Float = Math.pow(spacer.radius + spacer2.radius, 2);

			if (position.distanceToSquared(position2) < r2) {
				if (position.equals(position2)) {
					aggDisplaceTargetX += Utils.randomOneOrNegOne();
					aggDisplaceTargetY += Utils.randomOneOrNegOne();
				} else {
					var diffVec:FastVector2 = new FastVector2(
						position2.x - position.x,
						position2.y - position.y
					);
					var penetrationDepth:Float = spacer.radius + spacer2.radius - diffVec.length;
					diffVec = diffVec.normalized();
					var displace:FastVector2 = diffVec.mult(-penetrationDepth);
					aggDisplaceTargetX = aggDisplaceTargetX + displace.x;
					aggDisplaceTargetY = aggDisplaceTargetY + displace.y;
				}
			}
		}
		spacer.velocity.addVelX(aggDisplaceTargetX * spacingFactor);
		spacer.velocity.addVelY(aggDisplaceTargetY * spacingFactor);
	}
}
