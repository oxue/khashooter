package ;
import refraction.core.Component;
import refraction.ds2d.LightSource;
import refraction.generic.Position;
import refraction.generic.VelocityComponent;

/**
 * ...
 * @author qwerber
 */

class LightControlComponent extends Component
{
	public var position:Position;
	public var targetLight:LightSource;
	
	public var displaceX:Int;
	public var displaceY:Int;
		
	public function new() 
	{
		super("light_control_comp");
	}
	
	override public function load():Void 
	{
		position = entity.getComponent(Position);
		displaceX = displaceY = 5;
	}
	
	public inline function setColor(_r:Float,_g:Float, _b:Float):Void
	{
		targetLight.v3Color.x = _r;
		targetLight.v3Color.y = _g;
		targetLight.v3Color.z = _b;
	}
	
	override public function update():Void 
	{
		targetLight.x = cast position.x + displaceX;
		targetLight.y = cast position.y + displaceY;
	}
	
}