package refraction.display;

import hxblit.TextureAtlas.FloatRect;

/**
 * ...
 * @author worldedit
 */

class Canvas 
{
	public var camera:FloatRect;
	
	public function new(_width:Int = 400, _height:Int = 300, _zoom:Int = 2) 
	{
		//displayBitmap.blendMode = BlendMode.MULTIPLY;
		clear();
		camera = new FloatRect(0,0,_width, _height);
	}
	
	public inline function clear(_color = 0x00000000):Void
	{
	}
	
	public inline function lock():Void
	{
	}
	
	public inline function unlock():Void
	{
	}
	
}