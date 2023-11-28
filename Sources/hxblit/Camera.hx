package hxblit;

import kha.math.Vector2;
import refraction.core.Application;

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

	public function follow(followX: Float, followY: Float, followDamping: Float) {
		x += (followX - w / 2 - x) * followDamping;
		y += (followY - h / 2 - y) * followDamping;
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
		return new Vector2(roundedX(), roundedY());
	}

	public function roundedX():Int {
		return Math.round(x + shakeX);
	}

	public function roundedR():Int {
		return Math.round(r() + shakeX);
	}

	public function roundedB():Int {
		return Math.round(b() + shakeY);
	}

	public function roundedY():Int {
		return Math.round(y + shakeY);
	}

	public function roundedVec2():Vector2 {
		return new Vector2(roundedX(), roundedY());
	}

	public function toScreenPos(vec:Vector2):Vector2 {
		final zoom:Int = Application.getScreenZoom();
		return new Vector2(
			(vec.x - x) * zoom,
			(vec.y - y) * zoom
		);
	}

	public function worldMousePos():Vector2 {
		return {
			x: Application.mouseX / Application.getScreenZoom() + x,
			y: Application.mouseY / Application.getScreenZoom() + y
		}
	}
}
