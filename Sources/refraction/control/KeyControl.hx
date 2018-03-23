package refraction.control;
import kha.math.FastVector2;
import refraction.core.Component;
import refraction.core.Application;
import refraction.generic.Position;
import refraction.generic.Velocity;

/**
 * ...
 * @author worldedit
 */

class KeyControl extends Component
{
	private var position:Position;
	private var velocity:Velocity;

	public var speed:Float;
	
	public function new(_speed:Float = 5) 
	{
		super();
		speed = _speed;
	}

	override public function autoParams(_args:Dynamic):Void
	{
		speed = _args.speed;	
	}

	override public function load():Void 
	{
		position = entity.getComponent(Position);
		velocity = entity.getComponent(Velocity);
	}
	
	override public function update():Void 
	{
		var acc:FastVector2 = new FastVector2();
		
		if (Application.keys.get("A".charCodeAt(0)))
		acc.x = -1;
		if (Application.keys.get("D".charCodeAt(0)))
		acc.x = 1;
		if (Application.keys.get("W".charCodeAt(0)))
		acc.y = -1;
		if (Application.keys.get("S".charCodeAt(0)))
		acc.y = 1;
		
		acc.normalize();
		acc = acc.mult(speed);
		
		velocity.addVelX(acc.x);
		velocity.addVelY(acc.y);
	}
	
}