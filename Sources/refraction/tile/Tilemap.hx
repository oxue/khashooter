package refraction.tile;

/*import flash.display.Bitmap;
	import flash.Lib;
	import flash.display.BitmapData;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.Vector; */
import haxe.Timer;
import haxe.ds.Vector;
// import hxblit.HxBlit;
import hxblit.Surface2;
// import hxblit.TextureAtlas;
import refraction.display.Canvas;

/**
 * ...
 * @author worldedit
 */
class Tilemap {
	public var data:Vector<Vector<Tile>>;
	public var graphics:BitmapData;

	public var width:Int;
	public var height:Int;
	public var tilesize:Int;

	public var tempRect:Rectangle;
	public var tempPoint:Point;

	public var targetCanvas:Canvas;

	public var tilesW:Int;
	public var tilesH:Int;

	public var colIndex:Int;

	private var surfaces:Vector<Surface2>;
	private var surface:Surface2;

	public function new(_graphics:BitmapData, _width:Int, _height:Int, _tilesize:Int) {
		width = _width;
		height = _height;
		tilesize = _tilesize;
		graphics = _graphics;

		data = new Vector<Vector<Tile>>(_height);
		var i:Int = _height;
		while (i-- > 0) {
			data[i] = new Vector<Tile>(_width);
			var j:Int = _width;
			while (j-- > 0) {
				data[i][j] = new Tile();
			}
		}

		colIndex = 2;

		tempPoint = new Point();
		tempRect = new Rectangle(0, 0, _tilesize, _tilesize);

		tilesW = cast graphics.width / _tilesize;
		tilesH = cast graphics.height / _tilesize;

		surfaces = new Vector(tilesW * tilesH, true);

		var atlas:TextureAtlas = HxBlit.atlas;
		i = tilesH;
		var startInd:Int = atlas.numTextures;
		while (i-- > 0) {
			var j:Int = tilesW;
			while (j-- > 0) {
				var b:BitmapData = new BitmapData(_tilesize, _tilesize, true);
				tempRect.x = j * _tilesize;
				tempRect.y = i * _tilesize;
				b.copyPixels(graphics, tempRect, tempPoint);
				atlas.add(b, startInd + i * tilesW + j);
			}
		}
		atlas.pack();
		var i:Int = tilesW * tilesH;
		while (i-- > 0) {
			surfaces[i] = atlas.assets.get(startInd + i);
		}
		surface = surfaces[0];
	}

	public function update():Void {
		// HxBlit.clear();
		HxBlit.initShader();
		var _b:BitmapData = targetCanvas.displayData;
		var i:Int = height;
		while (i-- > 0) {
			var j:Int = width;
			while (j-- > 0) {
				var index:Int = data[i][j].imageIndex;
				tempRect.x = tilesize * (index % tilesW);
				tempRect.y = tilesize * Std.int(index / tilesW);
				tempPoint.x = j * tilesize - targetCanvas.camera.x;
				tempPoint.y = i * tilesize - targetCanvas.camera.y;
				HxBlit.blit(surfaces[index], cast tempPoint.x, cast tempPoint.y);
			}
		}

		// HxBlit.draw(targetCanvas.displayData);
	}
}
