package refraction.control;
import flash.geom.Point;
import refraction.core.Component;
import refraction.generic.Position;

/**
 * ...
 * @author worldedit
 */

class RandomMoveComponent extends Component
{
	private var position:Position;
	
	public var velX:Float;
	public var velY:Float;
	public var speed:Float;
	
	private var target:Point;
	private var timer:Int;
	private var time:Int;
	
	public function new(_speed:Int = 1) 
	{
		super("rand_move_comp");
		velX = velY = 0;
		speed = _speed;
		target = new Point();
		time = 0;
		timer = 200;
	}
	
	override public function load():Void 
	{
		position = cast entity.components.get("pos_comp");
	}
	
	override public function update():Void 
	{
		time ++;
		if (time >= timer)
		{
			time = 0;
			target = new Point(Std.int(Math.random() * 300), Std.int(Math.random() * 300));
		}
		if (position.x < target.x)
		{
			velX = speed;
		}
		if (position.x > target.x)
		{
			velX = -speed;
		}
		if (position.y < target.y)
		{
			velY = speed;
		}
		if (position.y > target.y)
		{
			velY = -speed;
		}
		position.oldX = position.x;
		position.oldY = position.y;
		position.x += velX;
		position.y += velY;
	}
}