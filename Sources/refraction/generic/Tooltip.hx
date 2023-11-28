package refraction.generic;

import hxblit.Camera;
import kha.Color;
import kha.math.Vector2;
import refraction.core.Application;
import refraction.core.Component;

/**
 * ...
 * @author worldedit
 */
class Tooltip extends Component {
	public var message:String;
	public var camera:Camera;
	public var position:PositionCmp;
	public var mouseBox:DimensionsCmp;
	public var color:Color;

	public function new(_message = "Default", _color = Color.White, ?_camera:Camera) {
		message = _message;
		camera = _camera;
		color = _color;
		if (camera == null) {
			camera = Application.defaultCamera;
		}
		super();
	}

	override public function autoParams(_args:Dynamic) {
		message = _args.message;
		color = _args.color;
	}

	override public function load() {
		position = entity.getComponent(PositionCmp);
		mouseBox = entity.getComponent(DimensionsCmp);
	}

	public function containsPoint(mouseCoords:Vector2):Bool {
		var deltaCoords:Vector2 = new Vector2(mouseCoords.x + camera.x - position.x,
			mouseCoords.y + camera.y - position.y);
		return mouseBox.containsPoint(deltaCoords);
	}
}
