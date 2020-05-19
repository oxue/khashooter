package refraction.control;

import hxblit.Camera;
import refraction.core.Component;
import refraction.core.Application;
import refraction.generic.Position;

/**
 * ...
 * @author worldedit
 */
class RotationControl extends Component {
	private var position:Position;
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

	override public function load():Void {
		position = entity.getComponent(Position);
	}

	override public function update():Void {
		targetRotation = cast(Math.atan2((Application.mouseY / 2) - position.y - 10 + targetCamera.y,
			(Application.mouseX / 2) - position.x - 10 + targetCamera.x) * 180 / 3.14);

		var diff = targetRotation - position.rotation;
		if (diff < 0)
			diff += 360;
		if (diff >= 360)
			diff -= 360;
		if (diff > 180)
			diff -= 360;
		position.rotation += diff / 5;
	}
}
