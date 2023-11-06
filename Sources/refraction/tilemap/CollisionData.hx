package refraction.tilemap;

class CollisionData {

	public static inline final HORIZONTAL:Int = 0;
	public static inline final VERTICAL:Int = 1;

	public var nature:Int;
	public var collided:Bool;
	public var time:Float;

	public function new(_collided:Bool, _time:Float = 0, _nature:Int = HORIZONTAL) {
		collided = _collided;
		nature = _nature;
		time = _time;
	}
}
