package graphite;
import flash.display.DisplayObject;
import flash.display.Sprite;
import flash.Vector;

/**
 * ...
 * @author worldedit
 */

class GObjectContainer extends GObject
{
	public var children:Vector<GObject>;
	
	public function new() 
	{
		children = new Vector<GObject>();
		super();
	}
	
	public override function load():Void
	{
		
	}
	
	public function addGObject(_o:GObject, _x:Int = 0, _y = 0):GObject
	{
		addChild(cast(_o, DisplayObject));
		children.push(_o);
		_o.load();
		_o.x = _x;
		_o.y = _y;
		return _o;
	}
	
	public override function unload():Void
	{
		for (c in children)
		{
			c.unload();
		}
		super.unload();
	}
	
}