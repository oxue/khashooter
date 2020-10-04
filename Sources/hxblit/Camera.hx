package hxblit;

import kha.math.Vector2;

/**
 * ...
 * @author worldedit qwerber
 */
class Camera {
	public var x:Float;
	public var y:Float;
	public var w:Int;
	public var h:Int;

	private var shakeCounter:Int;
	private var shakeMagnitude:Float;

	private var shakeX:Int;
	private var shakeY:Int;

	public function new(_w:Int, _h:Int) {
		x = y = 0;
		w = _w;
		h = _h;
		shakeCounter = 0;
		shakeMagnitude = 0;
	}

	public function shake(duration:Int, magnitude:Float) {
		shakeCounter = duration;
		shakeMagnitude = magnitude;
	}

	public function updateShake() {
		shakeCounter--;
		if (shakeCounter <= 0) {
			shakeX = shakeY = 0;
		} else {
			shakeX = cast Math.random() * shakeMagnitude * 2 - shakeMagnitude;
			shakeY = cast Math.random() * shakeMagnitude * 2 - shakeMagnitude;
			shakeMagnitude *= 0.9;
		}
	}

	public inline function r():Float {
		return x + w;
	}

	public inline function b():Float {
		return y + h;
	}

	public function position():Vector2 {
		return new Vector2(x, y);
	}

	public function renderPosition():Vector2 {
		return new Vector2(X(), Y());
	}

	public function X():Int {
		return Math.round(x + shakeX);
	}

	public function Y():Int {
		return Math.round(y + shakeY);
	}
}
