package refraction.tile;

import hxblit.Camera;
// import hxblit.HxBlit;
import hxblit.KhaBlit;
import refraction.core.Component;
import refraction.display.SurfaceSetCmp;

/**
 * ...
 * @author qwerber
 */
class TileRender extends Component {

	private var surface2set:SurfaceSetCmp;
	private var tilemapData:TilemapData;

	public var threashold:Bool;
	public var mode:Int;
	public var targetCamera:Camera;

	public function new() {
		super();
	}

	override public function load() {
		surface2set = entity.getComponent(SurfaceSetCmp);
		tilemapData = entity.getComponent(TilemapData);
	}

	override public function update() {
		var left:Int = Math.floor(
			targetCamera.roundedX() / tilemapData.tilesize
		);
		left = (left < 0) ? 0 : left;
		var right:Int = Math.ceil(
			(targetCamera.roundedX() + targetCamera.w) / tilemapData.tilesize
		);
		right = (right > tilemapData.width) ? tilemapData.width : right;

		var up:Int = Math.floor(
			targetCamera.roundedY() / tilemapData.tilesize
		);
		up = (up < 0) ? 0 : up;
		var down:Int = Math.ceil(
			(targetCamera.roundedY() + targetCamera.h) / tilemapData.tilesize
		);
		down = (down > tilemapData.height) ? tilemapData.height : down;

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
