package graphite;
import flash.display.Shape;
import flash.display.Sprite;
import flash.events.MouseEvent;
import flash.Lib;
import flash.text.TextField;

/**
 * ...
 * @author worldedit
 */

class GButton extends GObject
{
	private var label:TextField;
	private var background:Shape;
	private var _callback:GButton->Void;
	private var darken:Shape;
	private var over:Bool;
	
	public function new(_label:String = "default", _width:Int = 100, _height:Int = 20, __callback:GButton->Void = null) 
	{
		background = new Shape();
		background.graphics.lineStyle(1, GraphiteEngine.configOptions.chrome_color_1);
		background.graphics.beginFill(GraphiteEngine.configOptions.chrome_color_2);
		background.graphics.drawRect(0, 0, _width, _height);
		addChild(background);
		
		label = new TextField();
		label.defaultTextFormat = GraphiteEngine.textFormat;
		label.text = _label;
		label.mouseEnabled = false;
		label.selectable = false;
		addChild(label);		
		
		darken = new Shape();
		darken.graphics.beginFill(0);
		darken.alpha = 0.2;
		darken.graphics.drawRect(0, 0, _width, _height);
		addChild(darken);
		darken.visible = false;
		
		addEventListener(MouseEvent.ROLL_OVER, rollOver);
		addEventListener(MouseEvent.ROLL_OUT, rollOut);
		
		label.width = _width;
		label.height = label.textHeight>20?label.textHeight:20;
		
		label.y = (_height - label.textHeight) * 0.5;
		
		addEventListener(MouseEvent.MOUSE_DOWN, down);
		this.buttonMode = true;
		
		_callback = __callback;
		super();
	}
	
	public function get_label():String
	{
		return label.text;
	}
	
	private function rollOut(e:MouseEvent):Void 
	{
		darken.visible = false;
		darken.alpha = .2;
		over = false;
		if (stage != null)
		release(null);
	}
	
	private function rollOver(e:MouseEvent):Void 
	{
		darken.visible = true;
		darken.alpha = .05;
		over = true;
	}
	
	public override function load():Void
	{
		
	}
	
	public override function unload():Void
	{
		removeEventListener(MouseEvent.MOUSE_DOWN, down);
		removeEventListener(MouseEvent.ROLL_OVER, rollOver);
		removeEventListener(MouseEvent.ROLL_OUT, rollOut);
		
		super.unload();
	}
	
	private function down(e:MouseEvent):Void 
	{
		darken.visible = true;
		darken.alpha = 0.2;
		stage.addEventListener(MouseEvent.MOUSE_UP, release);
	}
	
	public function release(e:MouseEvent):Void 
	{
		stage.removeEventListener(MouseEvent.MOUSE_UP, release);
		if (over == false)
			darken.visible = false;
		else
			darken.alpha = 0.05;
		if(_callback != null && mouseX > 0 && mouseX < width && mouseY > 0 && mouseY < height)
			_callback(this);
	}
	
}