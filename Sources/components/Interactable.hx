package components;

import hxblit.Camera;
import refraction.core.Application;
import refraction.core.Component;
import refraction.core.Entity;
import refraction.core.Utils;
import refraction.generic.DimensionsCmp;
import refraction.generic.PositionCmp;

/**
 * ...
 * @author
 */
class Interactable extends Component {
	private var position:PositionCmp;
	private var dimensions:DimensionsCmp;
	private var camera:Camera;

	public var interactFunc:Entity->Void;

	public function new(_cam:Camera, _interactFunc:Entity->Void) {
		camera = _cam;
		interactFunc = _interactFunc;
		super();
	}

	override public function load():Void {
		position = entity.getComponent(PositionCmp);
		dimensions = entity.getComponent(DimensionsCmp);
	}

	public function containsCursor():Bool {
		var worldMouseCoords = Application
			.mouseCoords()
			.mult(0.5)
			.add(camera.position());
		return dimensions.containsPoint(worldMouseCoords.sub(position.vec()));
	}
}
