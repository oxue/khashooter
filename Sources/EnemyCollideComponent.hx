package ;
import flash.geom.Point;
import flash.Vector;
import refraction.core.Component;
import refraction.generic.Position;
import refraction.core.Sys;
import refraction.generic.VelocityComponent;

/**
 * ...
 * @author worldedit
 */

class EnemyCollideComponent extends Component
{
	public var position:Position;
	public var radius:Int;
	public var health:HealthComponent;
	public var radius2:Int;
	public var velocity:VelocityComponent;
	public var distance:Float;
	
	public function new() 
	{
		super("ec_comp");
	}
	
	override public function load():Void 
	{
		position = cast entity.components.get("pos_comp");
		health = cast entity.components.get("health_comp");
		radius = 10;
		velocity = cast entity.components.get("vel_comp");
		radius2 = radius * radius;
	}
	
	override public function update():Void 
	{
		
	}
	
}