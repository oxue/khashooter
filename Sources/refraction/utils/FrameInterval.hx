package refraction.utils;

class FrameInterval
{
	private var interval:Int;
	private var timer:Int;
	private var handler:Void->Void;

	public function new(_handler:Void->Void, _interval:Int)
	{
		handler = _handler;
		interval = _interval;
		timer = 0;
	}

	public function tick():Void
	{
		timer ++;
		if(timer >= interval){
			handler();
			timer = 0;
		}
	}
}