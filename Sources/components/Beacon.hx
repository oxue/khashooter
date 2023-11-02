package components;

import refraction.core.Component;
import refraction.generic.PositionCmp;

class Beacon extends Component {
	public var position:PositionCmp;
	public var tag:String;

	public function new() {
		super();
	}

	override public function autoParams(_args:Dynamic):Void {
		tag = defaulted(_args.tag, "default");
	}

	override public function load():Void {
		position = entity.getComponent(PositionCmp);
	}
}
