package components;

import nape.phys.BodyType;
import nape.shape.Shape;
import nape.shape.Circle;
import nape.phys.Body;
import refraction.core.Component;

class PhysicsCmp extends Component {

	var body:Body;
	var shape:Shape;

	public function new() {
		super();
	}

	override public function load() {
		body = new Body(BodyType.DYNAMIC);
		shape = new Circle(10);
        body.shapes.add(shape);
	}
}
