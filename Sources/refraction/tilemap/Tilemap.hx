package refraction.tilemap;

import hxblit.Camera;
import hxblit.KhaBlit;
import kha.math.Vector2;
import refraction.core.Utils;

/**
 * ...
 * @author qwerber
 */
class TileMap extends GenericTileMap<Tile>{

	public var threashold:Bool;
	public var mode:Int;
	public var colIndex:Int;
	public var tilesheet:Tilesheet;

	public function new(tilesheet:Tilesheet, _width:Int, _height:Int, _tilesize:Int, _colIndex:Int) {
		super(_width, _height, _tilesize);

		this.tilesheet = tilesheet;
		this.colIndex = _colIndex;
	}

	public function getTilesize():Int {
		return tilesize;
	}

	public function render(camera:Camera) {
		var left:Int = getIndexAtFloat(camera.roundedX());
		var right:Int = getIndexAtFloat(camera.roundedR()) + 1;
		var up:Int = getIndexAtFloat(camera.roundedY());
		var down:Int = getIndexAtFloat(camera.roundedB()) + 1;

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
		if (data[i][j] == null) {
			return;
		}
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
			tilesheet.surfaceset.surfaces[index],
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

	public function getTileArray():Array<Array<Int>> {
		var mData:Array<Array<Tile>> = cast data;
		return mData.map(function(row:Array<Tile>) {
			return row.map(function(tile:Tile):Int {
				return tile.imageIndex;
			});
		});
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
