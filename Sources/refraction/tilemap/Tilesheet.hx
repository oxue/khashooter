package refraction.tilemap;

import kha.Assets;
import kha.math.Vector2;
import refraction.core.Utils;
import refraction.display.SurfaceSetCmp;

class Tilesheet {

	public var surfaceset:SurfaceSetCmp;
	public var originalSpriteName:String;
	public var tilesize:Int;

	var sheetWidth:Int;
	var sheetHeight:Int;

	public function new(tilesize:Int, surfaceset:SurfaceSetCmp, originalSpriteName:String) {
		this.surfaceset = surfaceset;
		this.originalSpriteName = originalSpriteName;
		this.tilesize = tilesize;
		sheetWidth = Std.int(
			Assets.images
				.get(originalSpriteName)
				.width / tilesize
		);
		sheetHeight = Std.int(
			Assets.images
				.get(originalSpriteName)
				.height / tilesize
		);
	}

	public function getTileIndex(x:Float, y:Float, zoom:Int = 1):Int {
		var zoomedTileSize:Int = tilesize * zoom;
		var ret:Int = Utils.clampInt(
			Math.floor(x / zoomedTileSize) + Math.floor(y / zoomedTileSize) * sheetWidth,
			0,
			sheetWidth * sheetHeight - 1
		);
		return ret;
	}

	public function tileIndexToTexCoords(ind:Int, zoom:Int = 1):Vector2 {
		var zoomedTileSize:Int = tilesize * zoom;
		var x:Int = ind % sheetWidth;
		var y:Int = Math.floor(ind / sheetWidth);
		return new Vector2(
			x * zoomedTileSize,
			y * zoomedTileSize
		);
	}
}
