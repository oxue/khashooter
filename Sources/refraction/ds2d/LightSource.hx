package refraction.ds2d;

/*import flash.display.BitmapData;
	import flash.display.GradientType;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Vector3D; */
import game.GameContext;
import refraction.core.Application;
import kha.Color;
import kha.graphics4.Graphics2.ColoredShaderPainter;
import hxblit.Camera;
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

	public function debugDraw(camera:Camera, g2:kha.graphics2.Graphics) {
		var center:Vector2 = position.sub(camera.position());
		var numRot:Int = 12;
		var globalRad:Float = GameContext.instance().lightingSystem.globalRadius;
		for (i in 0...numRot) {
			var offset1:Vector2 = {
				x: Math.cos(2 * Math.PI * i / numRot) * globalRad,
				y: Math.sin(2 * Math.PI * i / numRot) * globalRad
			};

			var offset2:Vector2 = {
				x: Math.cos(2 * Math.PI * (i + 1) / numRot) * globalRad,
				y: Math.sin(2 * Math.PI * (i + 1) / numRot) * globalRad
			};

			offset1 = offset1.add(center).mult(Application.getScreenZoom());
			offset2 = offset2.add(center).mult(Application.getScreenZoom());

			g2.color = Color.Green;
			g2.drawLine(offset1.x, offset1.y, offset2.x, offset2.y, 2);
		}
	}

	public inline function clear():Void {}
}
