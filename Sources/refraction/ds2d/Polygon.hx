package refraction.ds2d;

import hxblit.Camera;
import kha.math.Vector2;

/**
 * ...
 * @author ...
 */
class Polygon {

	public var vertices:Array<Vector2>;
	public var faces:Array<Face>;
	public var x:Int;
	public var y:Int;

	public function new(_x:Int = 0, _y:Int = 0) {
		vertices = [];
		faces = [];
		x = _x;
		y = _y;
	}

	public function addDefaultFaces(_numVertices:Int, _radius:Int) {
		var i:Int = _numVertices;
		while (i-- > 0) {
			var pi:Float = 3.1415;
			var rads:Float = (pi * 2 / _numVertices) * i + pi / 4;
			vertices.push(
				new Vector2(
					Math.cos(rads) * _radius + x,
					Math.sin(rads) * _radius + y
				)
			);
		}
		var i:Int = _numVertices - 1;
		while (i-- > 0) {
			faces.push(new Face(vertices[i], vertices[i + 1]));
		}
		faces.push(new Face(vertices[_numVertices - 1], vertices[0]));
	}

	public function debugDraw(camera:Camera, g:kha.graphics2.Graphics) {
		for (f in faces) {
			g.color = Green;
			final p1:Vector2 = camera.toScreenPos(f.v1);
			final p2:Vector2 = camera.toScreenPos(f.v2);
			g.drawLine(p1.x, p1.y, p2.x, p2.y);
		}
	}
}
