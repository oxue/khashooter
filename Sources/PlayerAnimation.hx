package ;
import refraction.core.Component;
import refraction.display.AnimatedRender;
import refraction.generic.Velocity;

/**
 * ...
 * @author worldedit
 */

class PlayerAnimation extends Component
{
	private var velocity:Velocity;
	private var blc:AnimatedRender;
	public var weapons:AnimatedRender;

	private var inventory:Inventory;
	
	public function new() 
	{
		super();
	}
	
	override public function load():Void 
	{
		velocity = entity.getComponent(Velocity);
		blc = entity.getComponent(AnimatedRender);
		weapons = entity.getComponent(AnimatedRender, "weapon_render_comp");
		inventory = entity.getComponent(Inventory);
	}
	
	private function notMoving():Bool
	{
		return Math.round(velocity.velX) == 0 && Math.round(velocity.velY) == 0;
	}
	
	override public function update():Void 
	{
		var idle_animation = inventory.wieldingWeapon() ? "idle with weapon" : "idle";
		var walking_animation = inventory.wieldingWeapon() ? "running with weapon" : "running";

		if (notMoving())
		{
			if (blc.curAnimaition != idle_animation)
			{
				blc.curAnimaition = idle_animation;
				blc.frame = 0;
			}
		}
		else if (blc.curAnimaition != walking_animation)
		{
			blc.curAnimaition = walking_animation;
			blc.frame = Std.int(Math.random() * 4);
		}
	}
	
}