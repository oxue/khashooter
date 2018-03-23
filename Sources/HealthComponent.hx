package ;
import flash.events.Event;
import refraction.core.Application;
import refraction.core.Component;

/**
 * ...
 * @author worldedit
 */

class HealthComponent extends Component
{

	public var value:Int;
	public var maxValue:Int;
	public var _callback:Void->Void;
	
	public function new() 
	{
		value = 500;
		maxValue = 500;
		_callback = defaultCallback;
		super();
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
			_callback();
		}
	}
}