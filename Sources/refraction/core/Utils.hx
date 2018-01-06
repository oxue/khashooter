package refraction.core;
import refraction.generic.Position;
import kha.math.Vector2;

/**
 * ...
 * @author worldedit
 */

class Utils 
{

	public static inline function posDis2(_pos1:Position, _pos2:Position):Float
	{
		var dx:Float = _pos1.x - _pos2.x;
		var dy:Float = _pos1.y - _pos2.y;
		
		var dis:Float = dx * dx + dy * dy;
		return dis;
	}

	public static inline function floatEq(f1:Float, f2:Float, precision:Float = 1e-12){
		return Math.abs(f1 - f2) <= precision;
	}
	
	public static inline function rotateVec2(_vec:Vector2, rad:Float):Vector2
	{
		var cs = Math.cos(rad);
		var sn = Math.sin(rad);
		return new Vector2(
			_vec.x * cs - _vec.y * sn,
			_vec.x * sn + _vec.y * cs
		);
	}

	public static inline function quickRemoveIndex(_array:Array<Dynamic>, _i:Int):Void
	{
		_array[_i] = _array[_array.length-1];
		_array.pop();
	}

	public static inline function a2rad(a:Float){
		return a * 3.14159 / 180;
	}

	public static inline function sq(_x:Float):Float
	{
		return _x * _x;
	}
	
}