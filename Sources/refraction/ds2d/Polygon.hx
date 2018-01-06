package refraction.ds2d;
//port flash.Vector;

/**
 * ...
 * @author ...
 */
class Polygon 
{
	public var vertices:Array<Float2>;
	public var faces:Array<Face>;
	public var x:Int;
	public var y:Int;
	public var radius:Int;
	
	public function new(_numVertices:Int, _radius:Int, _x:Int, _y:Int) 
	{
		vertices = new Array<Float2>();
		faces = new Array<Face>();
		x = _x;
		y = _y;
		radius = _radius;
		var i:Int = _numVertices;
		while (i-->0)
		{
			vertices.push(
			new Float2(
			Math.cos((3.14159265 * 2 / _numVertices) * i+3.14/4) * _radius + x, 
			Math.sin((3.14159265 * 2 / _numVertices) * i+3.14/4) * _radius + y));
		}
		var i:Int = _numVertices - 1;
		while (i-->0)
		{
			faces.push(new Face(vertices[i], vertices[i + 1]));
		}
		faces.push(new Face(vertices[_numVertices - 1], vertices[0]));
	}
	
}

