package components;
import refraction.core.Component;

/**
 * ...
 * @author worldedit
 */

class Health extends Component
{

	public var value:Int;
	public var maxValue:Int;
	public var _callback:Void->Void;
	
	public function new(_maxValue = 100, _value = 100) 
	{
		value = _value;
		maxValue = _maxValue;
		_callback = defaultCallback;
		super();
	}

	override public function autoParams(_args:Dynamic):Void
	{
		value = _args.maxValue;
		maxValue = _args.maxValue;
	}

	override public function load():Void
	{
		on("damage", function(args:Dynamic) {
			applyHealth(args.amount);
		});
	}
	
	private function defaultCallback():Void
	{
		entity.remove();
	}

	public function applyHealth(_value:Int):Void
	{
		value += _value;
		if (value <= 0)
		{
			this.entity.notify("death", { reason: "health is 0."});
			_callback();
		}
	}
}