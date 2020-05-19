package refraction.utils;

/**
 * ...
 * @author
 */
class Interval {
	private var cb:Void->Void;
	private var interval:Int;
	private var timer:Int;

	public function new(_cb:Void->Void, _interval:Int) {
		cb = _cb;
		interval = _interval;
		timer = 0;
	}

	public function tick() {
		timer++;
		if (timer >= interval) {
			timer = 0;
			cb();
		}
	}
}
