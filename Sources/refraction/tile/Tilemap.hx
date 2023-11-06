package refraction.tile;

import hxblit.Camera;
import hxblit.KhaBlit;
import refraction.core.Component;
import refraction.core.Utils;
import refraction.display.SurfaceSetCmp;

/**
 * ...
 * @author qwerber
 */
class Tilemap extends Component {

	public var threashold:Bool;
	public var mode:Int;
	public var targetCamera:Camera;

	var surface2set:SurfaceSetCmp;
	var tilemapData:TilemapData;

	public function new() {
		super();
	}

	override public function load() {
		surface2set = entity.getComponent(SurfaceSetCmp);
		tilemapData = entity.getComponent(TilemapData);
	}

	public function render() {
		var left:Int = tilemapData.toTileCoord(targetCamera.roundedX());
		var right:Int = tilemapData.toTileCoord(targetCamera.roundedR()) + 1;
		var up:Int = tilemapData.toTileCoord(targetCamera.roundedY());
		var down:Int = tilemapData.toTileCoord(targetCamera.roundedB()) + 1;

		left = Utils.clampInt(left, 0, tilemapData.width);
		right = Utils.clampInt(right, 0, tilemapData.width);
		up = Utils.clampInt(up, 0, tilemapData.height);
		down = Utils.clampInt(down, 0, tilemapData.height);

		var i:Int = down;
		while (i-- > up) {
			var j:Int = right;
			while (j-- > left) {
				renderTile(i, j);
			}
		}
	}

	function renderTile(i:Int, j:Int) {
		var index:Int = tilemapData.data[i][j].imageIndex;
		if (threashold) {
			if (mode == 0 && index > tilemapData.colIndex) {
				return;
			}
			if (mode == 1 && index <= tilemapData.colIndex) {
				return;
			}
		}

		KhaBlit.blit(
			surface2set.surfaces[index],
			cast j * tilemapData.tilesize - targetCamera.roundedX(),
			cast i * tilemapData.tilesize - targetCamera.roundedY()
		);
	}
}
