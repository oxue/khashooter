package components;

import hxblit.Camera;
import kha.math.Vector2;
import refraction.core.Application;
import refraction.core.Component;
import refraction.core.Entity;
import refraction.generic.DimensionsCmp;
import refraction.generic.PositionCmp;

/**
 * ...
 * @author
 */
class InteractableCmp extends Component {

	public var interactFunc:Entity -> Void;

	var position:PositionCmp;
	var dimensions:DimensionsCmp;
	var camera:Camera;

	public function new(_cam:Camera, _interactFunc:Entity -> Void) {
		camera = _cam;
		interactFunc = _interactFunc;
		super();
	}

	override public function load() {
		position = entity.getComponent(PositionCmp);
		dimensions = entity.getComponent(DimensionsCmp);
	}

	public function containsCursor():Bool {
		var worldMouseCoords:Vector2 = Application
			.mouseCoords()
			.div(Application.getScreenZoom())
			.add(camera.position());
		return dimensions.containsPoint(worldMouseCoords.sub(position.vec()));
	}
}
