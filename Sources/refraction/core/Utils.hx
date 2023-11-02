package refraction.core;

import kha.math.Vector2;
import refraction.generic.PositionCmp;

/**
 * ...
 * @author worldedit
 */
class Utils {
	public static var TWIP:Float = 0.05;
	public static var RAD2A:Float = 180 / 3.1415926;
	public static var A2RAD:Float = 1 / RAD2A;

	public static inline function posDis2(_pos1:PositionCmp, _pos2:PositionCmp):Float {
		var dx:Float = _pos1.x - _pos2.x;
		var dy:Float = _pos1.y - _pos2.y;

		var dis:Float = dx * dx + dy * dy;
		return dis;
	}

	public static inline function floatEq(f1:Float, f2:Float, precision:Float = 1e-12) {
		return Math.abs(f1 - f2) <= precision;
	}

	public static inline function direction2Degrees(_dir:Vector2):Float {
		return Math.atan2(_dir.y, _dir.x) * RAD2A;
	}

	public static inline function rotateVec2(_vec:Vector2, rad:Float):Vector2 {
		var cs = Math.cos(rad);
		var sn = Math.sin(rad);
		return new Vector2(_vec.x * cs - _vec.y * sn, _vec.x * sn + _vec.y * cs);
	}

	public static inline function quickRemoveIndex(_array:Array<Dynamic>, _i:Int) {
		_array[_i] = _array[_array.length - 1];
		_array.pop();
	}

	public static inline function a2rad(a:Float):Float {
		return a * 3.14159 / 180;
	}

	public static inline function randomOneOrNegOne():Float {
		return Math.random() > 0.5 ? 1 : -1;
	}

	public static inline function sq(_x:Float):Float {
		return _x * _x;
	}
}
