package refraction.control;
import flash.events.MouseEvent;
import refraction.core.Component;
import refraction.core.Application;
import refraction.generic.Position;

/**
 * ...
 * @author worldedit
 */

class ClickControlComponent extends Component
{
	private var position:Position;
	
	public function new() 
	{
		super("click_con_comp");
	}
	
	override public function load():Void 
	{
		position = entity.getComponent(Position);
	}
	
	public function move():Void 
	{
		position.oldX = position.x;
		position.oldY = position.y;
		position.x = Application.mouseX;
		position.y = Application.mouseY;
	}
	
}