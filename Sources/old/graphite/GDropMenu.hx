package graphite;
import flash.display.Shape;
import flash.events.MouseEvent;
import flash.events.TimerEvent;
import flash.utils.Timer;
import flash.Vector;

/**
 * ...
 * @author worldedit
 */

class GDropMenu extends GObjectContainer
{
	private var mainButton:GButton;
	private var menuButtonWidth:Int;
	private var seperators:Vector<Shape>;
	private var closed:Bool;
	private var orientation:String;
	
	public function new(_label:String = "default", _mainButtonWidth:Int = 100, _menuButtonsWidth:Int = 100, _orientation:String = "left") 
	{
		menuButtonWidth = _menuButtonsWidth;	
		seperators = new Vector<Shape>();
		super();
		mainButton = new GButton(_label, _mainButtonWidth, 20, openMenu);
		addEventListener(MouseEvent.ROLL_OUT, mouseOut);
		closed = true;
		orientation = _orientation;
		addEventListener(MouseEvent.MOUSE_UP, mouseOut);
		addGObject(mainButton);
	}
	
	private function mouseOut(e:MouseEvent):Void 
	{
		if (closed)
			return;
			
		closed = true;
			
		var i:Int = children.length;
		while (i-->1)
		{
			if (children[i].stage != null)
			cast(children[i], GButton).release(null);
			removeChild(children[i]);
		}
		i = seperators.length;
		while (i-->0)
		{
			seperators[i].visible = false;
		}
	}
	
	public function addMenuItem(_label:String = "default", _callback:GButton->Void = null):Void
	{
		var b:GButton = new GButton(_label, menuButtonWidth, 20, _callback);
		addGObject(b);
		b.y = (children.length - 1) * 20;
		if (orientation == "right")
		{
			b.x = mainButton.width - b.width;
		}
		removeChild(b);
	}
	
	override public function unload():Void 
	{
		removeEventListener(MouseEvent.ROLL_OUT, mouseOut);
		super.unload();
	}
	
	public function addSeperator():Void
	{
		var l:Shape = new Shape();
		l.graphics.lineStyle(3, GraphiteEngine.configOptions.chrome_color_1);
		l.graphics.moveTo(1.5,0);
		l.graphics.lineTo(menuButtonWidth-1.5, 0);
		l.y = children.length * 20;
		addChild(l);
		if (orientation == "right")
		{
			l.x = mainButton.width - l.width;
		}
		seperators.push(l);
		l.visible = false;
	}
	
	private function openMenu(b:GButton) 
	{
		parent.addChild(this);
		var i:Int = children.length;
		while (i-->1)
		{
			addChild(children[i]);
		}
		i = seperators.length;
		while (i-->0)
		{
			seperators[i].visible = true;
			addChild(seperators[i]);
		}
		closed = false;
	}
	
}