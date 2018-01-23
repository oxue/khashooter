package refraction.ds2d;

/**
 * ...
 * @author ...
 */
class Float2 
{
	public var x:Float;
	public var y:Float;
	
	public function new(_x:Float, _y:Float) 
	{
		x = _x;
		y = _y;
	}
	
	public function toString():String
	{
		return cast(x,String) + ' ' + cast(y,String) + ' ';
	}
	
}

