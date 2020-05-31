package refraction.ds2d;

/*import flash.display.BitmapData;
	import flash.display.GradientType;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Vector3D; */
import kha.math.Vector2;
import kha.math.FastVector4;

/**
 * ...
 * @author werber
 */
class LightSource {
	public var position:Vector2;

	public var radius:Float;
	public var color:Int;

	public var remove:Bool;

	public var v3Color:FastVector4;

	public function new(_x:Int = 0, _y:Int = 0, _color:Int = 0xff0000, _radius:Int = 100) {
		position = new Vector2(_x, _y);

		radius = _radius;
		color = _color;

		var r:Int = color >> 16;
		var g:Int = (color >> 8) - (r << 8);
		var b:Int = color - (r << 16) - (g << 8);
		v3Color = new FastVector4(r / 255, g / 255, b / 255, 1);
	}

	public inline function clear():Void {}
}
