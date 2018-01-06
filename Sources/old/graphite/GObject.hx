package graphite;
import flash.display.Sprite;

/**
 * ...
 * @author worldedit
 */

class GObject extends Sprite
{
	
	public function new()
	{
		super();
	}
	
	public function load():Void
	{
		
	}
	
	public function unload():Void
	{
		var gparent:GObjectContainer = cast(parent, GObjectContainer);
		var index:Int = gparent.children.lastIndexOf(this);
		gparent.children[index] = gparent.children[gparent.children.length - 1];
		gparent.children.length--;
		parent.removeChild(this);
	}
	
}