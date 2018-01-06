package refraction.ds2d;

/**
 * ...
 * @author ...
 */
class Float2 
{
	public var _0:Float;
	public var _1:Float;
	
	public function new(__0:Float, __1:Float) 
	{
		_0 = __0;
		_1 = __1;
	}
	
	public function toString():String
	{
		return cast(_0,String) + ' ' + cast(_1,String) + ' ';
	}
	
}

