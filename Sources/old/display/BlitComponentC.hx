package refraction.display;
/*import flash.geom.Point;
import flash.geom.Rectangle;
import flash.Vector;*/
import refraction.core.Component;
import refraction.generic.Position;
import refraction.generic.TransformComponent;
import refraction.generic.VelocityComponent;

/**
 * ...
 * @author worldedit
 */

class BlitComponentC extends Component
{

	public var frameTime:Int;
	private var time:Int;
	public var frame:Int;
	public var animations:Vector<Array<Int>>;
	private var bound:Rectangle;
	private var data:BitmapComponent;
	private var transform:TransformComponent;
	private var position:Position;
	public var curAnimaition:Int;
	public var targetCanvas:Canvas;
	
	public function new() 
	{
		super("blit_comp_c");
	}
	
	override public function load():Void 
	{
		data = cast entity.components.get("bitmap_comp");
		transform = cast entity.components.get("trans_comp");
		position = cast entity.components.get("pos_comp");
		bound = new Rectangle(0, 0, data.diagnol, data.diagnol);
		animations = new Vector<Array<Int>>();
		animations.push([0,0, 0,1, 2,1]);
		frameTime = 4;
		//time = cast Math.random() * frameTime;
		frame = cast Math.random() * 5;
	}
	
	override public function update():Void 
	{
		time++;
		if (time == frameTime)
		{
			time = 0;
			frame ++;
			if (frame == animations[curAnimaition].length)
			{
				frame = 0;
			}
			bound.y = animations[curAnimaition][frame] * data.diagnol;
		}
		if (transform.rotation < 0)
		{
			transform.rotation += 360;
		}else if (transform.rotation >= 360)
		{
			transform.rotation -= 360;
		}
		bound.x = Math.round(transform.rotation / 11.25) * data.diagnol;
		targetCanvas.displayData.copyPixels(data.cache,
											bound,
											new Point(Math.round(position.x - data.translateX) - targetCanvas.camera.x,
													  Math.round(position.y - data.translateY) - targetCanvas.camera.y),
											null, 
											null, 
											true);
	}
	
}