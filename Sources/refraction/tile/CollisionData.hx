package refraction.tile;

/**
 * ...
 * @author worldedit
 */

 
class CollisionData 
{
	public static inline var HORIZONTAL:Int = 0;
	public inline static var VERTICAL:Int = 1;

	public var nature:Int;
	public var collided:Bool;
	public var time:Float;
	
	public function new(_collided:Bool, _time:Float = 0, _nature:Int = 0) 
	{
		collided = _collided;
		nature = _nature;
		time = _time;
	}
	
}