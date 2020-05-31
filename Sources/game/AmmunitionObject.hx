package game;

/**
 * assuming this class is correct
 * @author qwerber
 */
class AmmunitionObject {
	public var clipCount:Int;
	public var bulletCount:Int;
	public var perClip:Int;

	public function new(_perClip:Int) {
		perClip = _perClip;
	}

	public function applyAmmo(_n:Int):Void {
		clipCount += _n;
	}

	public function requestRound(_n):Int {
		if (bulletCount >= _n) {
			bulletCount -= _n;
			return _n;
		}
		return bulletCount;
	}

	public function reload():Void {
		if (bulletCount < perClip) {
			var transfer:Int;
			if (clipCount >= perClip - bulletCount) {
				transfer = perClip - bulletCount;
			} else {
				transfer = clipCount;
			}
			bulletCount += transfer;
			clipCount -= transfer;
		}
	}
}
