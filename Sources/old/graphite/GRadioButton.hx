package graphite;
import flash.display.Shape;
import flash.display.Sprite;
import flash.events.MouseEvent;
import flash.text.TextField;
import graphite.GObject;
import graphite.GraphiteEngine;

/**
 * ...
 * @author worldedit
 */

class GRadioButton extends GObject
{
	private var button:Sprite;
	private var label:TextField;
	private var selected:Bool;
	private var marker:Shape;
	
	public function new(_label:String = "default") 
	{
		button = new Sprite();
		button.graphics.lineStyle(1,GraphiteEngine.configOptions.chrome_color_3);
		button.graphics.beginFill(GraphiteEngine.configOptions.chrome_color_1);
		button.graphics.drawCircle(0, 0, 10);
		addChild(button);
		button.x = button.y = 10;
		
		label = new TextField();
		label.defaultTextFormat = GraphiteEngine.textFormatLeft;
		label.text = _label;
		label.selectable = false;
		label.mouseEnabled = false;
		label.x = 20;
		addChild(label);
		
		marker = new Shape();
		marker.graphics.lineStyle(1,GraphiteEngine.configOptions.chrome_color_3);
		marker.graphics.beginFill(GraphiteEngine.configOptions.chrome_color_2);
		marker.graphics.drawCircle(0, 0, 5);
		button.addChild(marker);
		marker.visible = false;
		
		button.addEventListener(MouseEvent.MOUSE_DOWN, mouseDown);
		
		super();
	}
	
	private function mouseDown(e:MouseEvent):Void 
	{
		selected = !selected;
		marker.visible = !marker.visible;
	}
	
}