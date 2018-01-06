package refraction.ds2d;

/**
 * ...
 * @author worldedit
 */

class Face 
{

	public var v1:Float2;
	public var v2:Float2;
	public var cull:Bool;
	public var cullNature:Int;
	
	public function new(_v1:Float2, _v2:Float2, _cull:Int = 0) 
	{
		v1 = _v1;
		v2 = _v2;
		
		if (_cull > 0)
		{
			cullNature = _cull;
			cull = true;
		}
	}
	
}