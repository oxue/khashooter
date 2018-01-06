package refraction.generic;
import refraction.core.Component;
import refraction.core.Utils;
import kha.math.Vector2;

/**
 * ...
 * @author worldedit
 */

class Velocity extends Component
{
	
	private var position:Position;
	public var velX:Float;
	public var velY:Float;

	public function new() 
	{
		velX = velY = 0;
		super();
	}
	
	override public function load():Void 
	{
		position = entity.getComponent(Position);
	}
	
	public function vec():Vector2
	{
		return new Vector2(velX, velY);
	}

	override public function update():Void 
	{
		position.x += velX;
		position.y += velY;
	}
	
	public function interpolate(speed:Float) 
	{
		var len = Math.sqrt(Utils.sq(velX) + Utils.sq(velY));
		if (len < speed){
			return;
		}
		velX = velX / len * speed; 
		velY = velY / len * speed;
		trace(velX);
	}
	
}