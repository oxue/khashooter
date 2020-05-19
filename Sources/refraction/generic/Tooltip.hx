package refraction.generic;

import refraction.core.Component;
import refraction.core.Application;
import refraction.generic.Position;
import refraction.generic.Dimensions;
import kha.math.Vector2;
import hxblit.Camera;
import kha.Color;

/**
 * ...
 * @author worldedit
 */
class Tooltip extends Component {
	public var message:String;
	public var camera:Camera;
	public var position:Position;
	public var mouseBox:Dimensions;
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

	override public function autoParams(_args:Dynamic):Void {
		message = _args.message;
		color = _args.color;
	}

	override public function load():Void {
		position = entity.getComponent(Position);
		mouseBox = entity.getComponent(Dimensions);
	}

	public function containsPoint(mouseCoords:Vector2):Bool {
		var deltaCoords = new Vector2(mouseCoords.x + camera.x - position.x,
			mouseCoords.y + camera.y - position.y);
		return mouseBox.containsPoint(deltaCoords);
	}
}
