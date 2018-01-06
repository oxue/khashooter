package refraction.display;
import flash.display.Shape;
import refraction.core.Component;
import refraction.core.Application;
import refraction.generic.Position;

/**
 * ...
 * @author worldedit
 */

class VShapeComponent extends Component
{
	public var position:Position;
	public var graphic:Shape;
	
	public function new(_graphic:Shape) 
	{
		graphic = _graphic;
		super("vshape_comp");
		Application.stage.addChild(graphic);
	}
	
	override public function load():Void 
	{
		position = cast entity.components.get("pos_comp");
	}
	
	override public function update():Void 
	{
		graphic.x = position.x;
		graphic.y = position.y;
	}
	
}