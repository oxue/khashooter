package refraction.display;
/*import flash.geom.Point;
import flash.geom.Rectangle;*/
import refraction.core.Component;
import refraction.generic.Position;
import refraction.generic.TransformComponent;

/**
 * ...
 * @author worldedit
 */

class BlitComponentB extends Component
{

	private var bitmap:BitmapComponent;
	private var position:Position;
	private var transform:TransformComponent;
	public var targetCanvas:Canvas;
	
	private var tempPoint:Point;
	private var tempRect:Rectangle;
	
	public function new() 
	{
		super("blit2_comp");
	}
	
	override public function load():Void
	{
		bitmap = cast entity.components.get("bitmap_comp");
		position = cast entity.components.get("pos_comp");
		transform = cast entity.components.get("trans_comp");
		
		tempPoint = new Point();
		tempRect = new Rectangle(0,0,bitmap.diagnol,bitmap.diagnol);
	}
	
	override public function update():Void 
	{
		if (transform.rotation < 0)
		{
			transform.rotation += 360;
		}else if (transform.rotation >= 360)
		{
			transform.rotation -= 360;
		}
		tempRect.x = Math.round(transform.rotation / 11.25) * bitmap.diagnol;
		tempPoint.x = position.x - bitmap.translateX + targetCanvas.camera.x;
		tempPoint.y = position.y - bitmap.translateY + targetCanvas.camera.y;
		
		targetCanvas.displayData.copyPixels(bitmap.cache, tempRect, tempPoint, null, null, true);
	}
	
}