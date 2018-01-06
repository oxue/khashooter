package components;

import refraction.core.Component;
import refraction.core.Utils;
import refraction.generic.Position;

class HitCircle extends Component
{
	public var radius:Float;
	public var tag:String;
	
	public var position:Position;

	public function new()
	{
		radius = 0;
		tag = "default";
		super();
	}

	override public function autoParams(_args:Dynamic):Void
	{
		radius = defaulted(_args.radius, 0);
		tag = defaulted(_args.tag, "default");
	}

	public function hitTest(c:HitCircle):Bool
	{
		return (Utils.posDis2(c.position, position) < Utils.sq(c.radius + radius));
	}

	override public function load():Void
	{
		position = entity.getComponent(Position);
	}
}