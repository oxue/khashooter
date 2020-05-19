package components;

import hxblit.Camera;
import refraction.core.Component;
import refraction.core.Application;
import refraction.core.Utils;
import refraction.generic.Dimensions;
import refraction.generic.Position;
import refraction.core.Entity;

/**
 * ...
 * @author
 */
class Interactable extends Component {
	private var position:Position;
	private var dimensions:Dimensions;
	private var camera:Camera;

	public var interactFunc:Entity->Void;

	public function new(_cam:Camera, _interactFunc:Entity->Void) {
		camera = _cam;
		interactFunc = _interactFunc;
		super();
	}

	override public function load():Void {
		position = entity.getComponent(Position);
		dimensions = entity.getComponent(Dimensions);
	}

	public function containsCursor():Bool {
		var worldMouseCoords = Application
			.mouseCoords()
			.mult(0.5)
			.add(camera.position());
		return dimensions.containsPoint(worldMouseCoords.sub(position.vec()));
	}
}
