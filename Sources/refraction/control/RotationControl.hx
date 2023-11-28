package refraction.control;

import hxblit.Camera;
import kha.math.Vector2;
import refraction.core.Application;
import refraction.core.Component;
import refraction.generic.PositionCmp;

/**
 * ...
 * @author worldedit
 */
class RotationControl extends Component {

	private var position:PositionCmp;
	private var targetRotation:Float;
	private var targetCamera:Camera;

	public function new(_cam:Camera = null) {
		targetCamera = _cam;
		if (targetCamera == null) {
			targetCamera = Application.defaultCamera;
		}
		targetRotation = 0;
		super();
	}

	override public function load() {
		position = entity.getComponent(PositionCmp);
	}

	override public function update() {
		// Assuming targetCamera.worldMousePos() and position are already defined as Vector2
		var direction = targetCamera
			.worldMousePos()
			.sub(new Vector2(position.x, position.y));
		var d:Float = direction.length;
		var targetRotationRad:Float = Math.atan2(direction.y, direction.x);
		if (d > 10) {
			final thetaAdjustment:Float = Math.atan2(
				10,
				Math.sqrt(direction.length * direction.length - 100)
			);
			targetRotationRad -= thetaAdjustment;
		}
		var targetRotationDeg:Float = targetRotationRad * 180 / Math.PI;

		// Normalize the difference between target and current rotation to the range [0, 360)
		var diff = (targetRotationDeg - position.rotationDegrees + 360) % 360;
		if (diff > 180)
			diff -= 360;

		position.rotationDegrees += diff / 8; // Assuming you want to update the current rotation
	}
}
