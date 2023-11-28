package refraction.tilemap;

/**
 * ...
 * @author worldedit
 */
class Tile {
	public var imageIndex:Int;
	public var solid:Bool;

	public function new(_imageIndex:Int = 0, _solid:Bool = false) {
		imageIndex = _imageIndex;
		solid = _solid;
	}
}
