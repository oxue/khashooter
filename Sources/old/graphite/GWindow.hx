package graphite;
#if air
import flash.display.NativeWindow;
import flash.display.NativeWindowInitOptions;
import flash.display.NativeWindowSystemChrome;
#end
import flash.display.StageAlign;
import flash.display.StageScaleMode;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.geom.Rectangle;
import flash.Lib;
import flash.system.Capabilities;

/**
 * ...
 * @author worldedit
 */

class GWindow extends GPane
{
	#if air
	private var window:NativeWindow;
	
	public function new(_title:String = "default", _width:Int = 400, _height:Int = 300, _closeButton:Bool = true, _displayBounds:Rectangle = null) 
	{
		super(_title, _width, _height, _closeButton);
		var o:NativeWindowInitOptions = new NativeWindowInitOptions();
		o.systemChrome = NativeWindowSystemChrome.NONE;
		o.transparent = true;
		o.maximizable = false;
		window = new NativeWindow(o);
		window.stage.scaleMode = StageScaleMode.NO_SCALE;
		window.width = _width+21;
		window.height = _height + 21;
		this.x = 10;
		this.y = 10;
		if (_displayBounds != null)
		{
			window.width = _width - _displayBounds.x +_displayBounds.width+21;
			window.height = _height - _displayBounds.y +_displayBounds.height+21;
			this.x = -_displayBounds.x + 10;
			this.y = -_displayBounds.y + 10;
		}
		window.stage.align = StageAlign.TOP_LEFT;
		Lib.current.addChild(this);
		//window.stage.addChild(this);
	}
	
	override private function mouseDown(e:MouseEvent):Void 
	{
		window.startMove();
	}
	
	override public function unload():Void 
	{
		window.close();
	}
	
	override private function mouseUp(e:MouseEvent):Void 
	{
		null;
	}
	
	public function activate():Void
	{
		window.activate();
	}
	
	public function centerWindow():Void
	{
		x = Capabilities.screenResolutionX - width;
		x *= 0.5;
		y = Capabilities.screenResolutionY - height;
		y *= 0.5;
	}
	#end
}