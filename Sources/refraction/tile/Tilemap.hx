package refraction.tile;

import haxe.ds.Vector;
import hxblit.Camera;
import hxblit.KhaBlit;
import kha.math.Vector2;
import refraction.core.Utils;
import refraction.display.SurfaceSetCmp;

/**
 * ...
 * @author qwerber
 */
class Tilemap {

	public var threashold:Bool;
	public var mode:Int;
	public var data:Vector<Vector<Tile>>;
	public var width:Int;
	public var height:Int;
	public var tilesize:Int;
	public var colIndex:Int;

	var surface2set:SurfaceSetCmp;

	public function new(tilesheet:SurfaceSetCmp, _width, _height, _tilesize, _colIndex) {
		this.surface2set = tilesheet;
		this.tilesize = _tilesize;
		this.width = _width;
		this.height = _height;
		this.colIndex = _colIndex;

		this.data = new Vector<Vector<Tile>>(_height);
		var i:Int = _height;
		while (i-- > 0) {
			data[i] = new Vector<Tile>(_width);
		}
	}

	public function getTilesize():Int {
		return tilesize;
	}

	public function toTileCoord(x:Float):Int {
		return Math.floor(x / tilesize);
	}

	public function render(camera:Camera) {
		var left:Int = toTileCoord(camera.roundedX());
		var right:Int = toTileCoord(camera.roundedR()) + 1;
		var up:Int = toTileCoord(camera.roundedY());
		var down:Int = toTileCoord(camera.roundedB()) + 1;

		left = Utils.clampInt(left, 0, width);
		right = Utils.clampInt(right, 0, width);
		up = Utils.clampInt(up, 0, height);
		down = Utils.clampInt(down, 0, height);

		var i:Int = down;
		while (i-- > up) {
			var j:Int = right;
			while (j-- > left) {
				renderTile(i, j, camera);
			}
		}
	}

	function renderTile(i:Int, j:Int, camera:Camera) {
		var index:Int = data[i][j].imageIndex;
		if (threashold) {
			if (mode == 0 && index > colIndex) {
				return;
			}
			if (mode == 1 && index <= colIndex) {
				return;
			}
		}

		KhaBlit.blit(
			surface2set.surfaces[index],
			cast j * tilesize - camera.roundedX(),
			cast i * tilesize - camera.roundedY()
		);
	}

	public function hitTestPoint(p:Vector2):Bool {
		var tCol:Int = Math.floor(p.x / tilesize);
		var tRow:Int = Math.floor(p.y / tilesize);
		var tile:Tile = getTileAt(tRow, tCol);
		return tile != null && tile.solid;
	}

	/**
	 * right, bottom, left, top
	 * @param i 
	 * @param j 
	 * @return (Int, Int, Int, Int)
	 */
	public function getTileBoundsAt(i:Int, j:Int):Array<Int> {
		return [j * tilesize + tilesize, i * tilesize + tilesize, j * tilesize, i * tilesize];
	}

	public function getTileAt(row:Int, col:Int):Tile {
		if (row < 0 || col < 0 || row >= height || col >= width) {
			return null;
		}

		return data[row][col];
	}

	public function setDataIntArray(_data:Array<Array<Int>>) {
		var i:Int = _data.length;
		while (i-- > 0) {
			var j:Int = _data[0].length;
			while (j-- > 0) {
				var t:Tile = new Tile();
				t.imageIndex = _data[i][j];
				t.solid = (_data[i][j] > colIndex);
				data[i][j] = t;
			}
		}
	}
}
