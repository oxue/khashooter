package refraction.ds2d;
import refraction.core.Component;
import refraction.core.Component;
import refraction.generic.Position;

/**
 * ...
 * @author qwerber
 */

class Circle extends Component
{

	public var x:Float;
	public var y:Float;
	public var radius:Float;
	public var position:Position;
	
	public function new(_x:Float, _y:Float, _radius:Float) 
	{
		x = _x;
		y = _y;
		radius = _radius;
		super();
	}
	
	override public function load():Void 
	{
		position = cast entity.components.get("pos_comp");
	}
	
}