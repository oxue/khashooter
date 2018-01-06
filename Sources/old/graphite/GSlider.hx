package graphite;
import flash.display.Shape;
import flash.display.Sprite;
import flash.events.MouseEvent;
import graphite.GObject;
import graphite.GraphiteEngine;

/**
 * ...
 * @author worldedit
 */

class GSlider extends GObject
{
	private var background:Shape;
	private var block:GButton;
	private var maxValue:Int;
	private var dif:Int;
	
	public var value:Int;
		
	public function new(_maxValue:Int = 100, _width:Int = 100) 
	{
		maxValue = _maxValue;
		
		background = new Shape();
		background.graphics.beginFill(GraphiteEngine.configOptions.chrome_color_1);
		background.graphics.lineStyle(1, GraphiteEngine.configOptions.chrome_color_3);
		background.graphics.drawRect(0, 0, _width, 20);
		addChild(background);
		
		block = new GButton('',20,20);
		block.graphics.lineStyle(1,GraphiteEngine.configOptions.chrome_color_3);
		block.graphics.beginFill(GraphiteEngine.configOptions.chrome_color_2);
		block.graphics.drawRect(0, 0, 20, 20);
		addChild(block);
		
		block.addEventListener(MouseEvent.MOUSE_DOWN, mouseDown);
		
		super();
	}
	
	private function mouseDown(e:MouseEvent):Void 
	{
		stage.addEventListener(MouseEvent.MOUSE_UP, mouseUp);
		stage.addEventListener(MouseEvent.MOUSE_MOVE, mouseMove);
		dif = cast block.mouseX;
	}
	
	private function mouseMove(e:MouseEvent):Void 
	{
		block.x = mouseX - dif;
		if (block.x < 0)
		{
			block.x = 0;
		}else if (block.x > background.width - 20)
		{
			block.x = background.width - 20;
		}
		value = cast ((block.x / (background.width - 20)) * maxValue);
	}
	
	public function setValue(_value:Int):Void
	{
		block.x = (background.width - 20) * (_value / maxValue);
		value = _value;
	}
	
	private function mouseUp(e:MouseEvent):Void 
	{
		stage.removeEventListener(MouseEvent.MOUSE_UP, mouseUp);
		stage.removeEventListener(MouseEvent.MOUSE_MOVE, mouseMove);
		
	}
	
}