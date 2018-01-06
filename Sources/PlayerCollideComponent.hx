package ;
import refraction.core.Component;
import refraction.generic.Position;
import refraction.core.Sys;

/**
 * ...
 * @author worldedit
 */

class PlayerCollideComponent extends Component
{

	public var radius2:Int;
	public var targetSystem:Sys<EnemyCollideComponent>;
	private var position:Position;
	private var health:HealthComponent;
	
	public function new() 
	{
		super("player_col_comp");
		radius2 = 900;		
	}
	
	override public function load():Void 
	{
		position = cast(entity.components.get("pos_comp"), Position);
		health = cast(entity.components.get("health_comp"), HealthComponent);
	}
	
	override public function update():Void 
	{
		var i:Int = targetSystem.components.length;
		while (i-->0)
		{
			var z:EnemyCollideComponent = targetSystem.components[i];
			var dx:Float = position.x - z.position.x;
			var dy:Float = position.y - z.position.y;
			var dis:Float = dx * dx + dy * dy;
			if (z.radius2 + this.radius2 > dis)
			{
				health.applyHealth(-1);
			}
		}
	}
	
}