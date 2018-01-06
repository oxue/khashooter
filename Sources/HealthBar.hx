package ;
import flash.geom.Rectangle;
import refraction.display.Canvas;

/**
 * ...
 * @author worldedit
 */

class HealthBar 
{

	public var hc:HealthComponent;
	public var targetCanvas:Canvas;
	
	public function new() 
	{
		
	}
	
	public function render():Void
	{
		targetCanvas.displayData.fillRect(new Rectangle(5, 5, 50, 10), 0xffff0000);
		targetCanvas.displayData.fillRect(new Rectangle(6, 6, 48, 8), 0xff000000);
		var scaling:Float = (hc.value / hc.maxValue);
		
		targetCanvas.displayData.fillRect(new Rectangle(7, 7, 46 * scaling, 6), 0xffff0000);
		targetCanvas.displayData.fillRect(new Rectangle(7, 7, 46 * scaling, 6), 0xffff0000);
	}
	
}