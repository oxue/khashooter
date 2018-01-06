package refraction.control;
import refraction.core.Component;
import refraction.generic.Position;
import refraction.generic.TransformComponent;
import refraction.generic.VelocityComponent;

/**
 * ...
 * @author worldedit
 */

class RotationFollow extends Component
{

	private var rotation:TransformComponent;
	private var position:Position;
	private var speed:Float;
	private var velocity:VelocityComponent;
	public var followPosition:Position;
	
	public function new() 
	{
		super("rot_follow_comp");
	}
	
	override public function load():Void 
	{
		rotation = cast entity.components.get("trans_comp");
		position = cast entity.components.get("pos_comp");
		velocity = cast entity.components.get("vel_comp");
		speed = 1;
	}
	
	override public function update():Void 
	{		
		var s:Float = Math.atan2(followPosition.y - position.y, followPosition.x - position.x);
		rotation.rotation = cast (Math.atan2(followPosition.y - position.y, followPosition.x - position.x) * 180 / 3.14);
		velocity.velX = Math.cos(s) * speed;
		velocity.velY = Math.sin(s) * speed;
	}
	
}