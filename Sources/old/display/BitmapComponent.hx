package refraction.display;
/*import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.geom.Matrix;
import flash.geom.Point;
import flash.geom.Rectangle;
import flash.Lib;
import flash.Vector;*/
//import hxblit.HxBlit;
import hxblit.Surface2;
//import hxblit.TextureAtlas;
import refraction.core.Application;
import refraction.core.Component;

/**
 * ...
 * @author worldedit
 */

class BitmapComponent extends Component
{
	public var data:BitmapData;
	public var cache:BitmapData;
	public var diagnol:Int;
	public var translateX:Float;
	public var translateY:Float;
	public var surfaces:Vector<Surface2>;
	
	public function new(_data:BitmapData, _bake:Bool = false) 
	{
		data = _data;
		super("bitmap_comp");
	}
	
	public function bake(_bitmap:BitmapData = null, _rot:Int = 32):Void
	{
		if (_bitmap == null)
		{
			_bitmap = data;
		}
		
		diagnol = Math.ceil(Math.sqrt(_bitmap.width * _bitmap.width + _bitmap.height * _bitmap.height));
		cache = new BitmapData(diagnol * (_rot+1), diagnol, true, 0);
		var brush:BitmapData = new BitmapData(diagnol, diagnol,true,0);
		var i:Int = -1;
		var m:Matrix = new Matrix();
		translateX = (diagnol - _bitmap.width) * 0.5;
		translateY = (diagnol - _bitmap.height) * 0.5;
		var p:Point = new Point(translateX, translateY);
		brush.copyPixels(_bitmap, _bitmap.rect, p);
		m.translate( -_bitmap.width / 2, -_bitmap.height / 2);
		p.y = 0;
		while (i++< _rot+1)
		{
			p.x = diagnol * i;
			cache.copyPixels(brush, brush.rect, p, null, null, true);
			brush.fillRect(brush.rect, 0);
			m.rotate((Math.PI * 2 / _rot));
			m.translate(diagnol / 2, diagnol / 2);
			brush.draw(_bitmap, m,null,null,null,true);
			m.translate( -diagnol / 2, -diagnol / 2);
		}
	}
	
	public function bakeForAnimation(_frame:Rectangle,_rot:Int = 32):Void
	{
		var brush:BitmapData = new BitmapData(cast _frame.width,cast  _frame.height, true, 0);
		var gWidth:Int = cast data.width / _frame.width;
		var gHeight:Int = cast data.height / _frame.height;
		diagnol = cast Math.ceil(Math.sqrt(_frame.width * _frame.width + _frame.height * _frame.height));
		var ret:BitmapData = new BitmapData(diagnol * (_rot + 1), gWidth * gHeight * diagnol, true, 0);
		var i:Int = -1;
		while (i++ < gHeight - 1)
		{
			var j:Int = -1;
			while (j++ < gWidth - 1)
			{
				brush.copyPixels(data, _frame, new Point(), null, null, true);
				bake(brush,_rot);
				ret.copyPixels(cache, cache.rect, new Point(0, diagnol * (i * gWidth + j)));
				_frame.x += _frame.width;
				brush.fillRect(brush.rect, 0);
			}
			_frame.y += _frame.width;
			_frame.x = 0;
			cache = ret;
		}
	}
}