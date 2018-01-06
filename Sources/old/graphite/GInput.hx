package graphite;
import flash.display.Sprite;
import flash.text.TextField;
import flash.text.TextFieldType;

/**
 * ...
 * @author worldedit
 */

class GInput extends GObject
{
	
	private var label:TextField;
	private var input:TextField;
	
	public function new(_label:String = "default", _width:Int = 200, _textWidth:Int = 100) 
	{
		label = new TextField();
		label.defaultTextFormat = GraphiteEngine.textFormatLeft;
		label.text = _label;
		label.width = _textWidth;
		label.mouseEnabled = false;
		label.selectable = false;
		addChild(label);
		
		input = new TextField();
		input.defaultTextFormat = GraphiteEngine.textFormatLeft;
		input.type = TextFieldType.INPUT;
		input.width = _width - _textWidth;
		input.x = _textWidth;
		input.border = true;
		input.borderColor = GraphiteEngine.configOptions.chrome_color_3;
		input.background = true;
		input.backgroundColor = GraphiteEngine.configOptions.chrome_color_1;
		input.height = 20;
		addChild(input);
		
		super();
	}
	
	public function get_value():String 
	{
		return input.text;
	}
	
	public function set_value(value:String):String 
	{
		return input.text = value;
	}

}