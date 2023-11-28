package refraction.tilemap;

import kha.math.Vector2i;
import haxe.ds.Vector;
import kha.math.Vector2;

@:generic
class GenericTileMap<T> {

	public var tilesize:Int;
	public var data:Vector<Vector<T>>;
	public var width:Int;
	public var height:Int;

	public function new(_width:Int, _height:Int, _tilesize:Int) {
		this.width = _width;
		this.height = _height;
		this.tilesize = _tilesize;

		this.data = new Vector<Vector<T>>(height);
		for (y in 0...height) {
			this.data[y] = new Vector<T>(width);
		}
	}

	public function getIndexAtFloat(x:Float):Int {
		return Math.floor(x / tilesize);
	}

	public function getTileIndexesContaining(x:Float, y:Float):Vector2i {
		return new Vector2i(getIndexAtFloat(x), getIndexAtFloat(y));
	}

	public function getTileContaining(x:Float, y:Float):T {
		return getTileAt(getIndexAtFloat(y), getIndexAtFloat(x));
	}

	public function getTileContainingVec2(pos:Vector2):T {
		return getTileAt(getIndexAtFloat(pos.y), getIndexAtFloat(pos.x));
	}

	public function getTileAtVec2i(pos:Vector2i):T {
		return getTileAt(pos.y, pos.x);
	}

	public function getTileAt(row:Int, col:Int):T {
		if (row < 0 || col < 0 || row >= height || col >= width) {
			return null;
		}

		return data[row][col];
	}

	public function setTileAt(row:Int, col:Int, tile:T) {
		if (row < 0 || col < 0 || row >= height || col >= width) {
			return;
		}

		data[row][col] = tile;
	}

	public function genericResizeFunc(tx:Int, ty:Int, filler:Void->T) {
		trace("resize");
		// first determine the size of the new tilemapdata
		width = determineNewSize(tx, width);
		height = determineNewSize(ty, height);

		trace(width, height);

		// create blank new data
		var newData:Vector<Vector<T>> = new Vector<Vector<T>>(height);
		for (y in 0...height) {
			newData[y] = new Vector<T>(width);
		}

		// copy the data over
		var startX:Int = 0;
		if (tx < 0) {
			startX = cast Math.abs(tx);
		} else if (tx >= this.data[0].length) {
			startX = 0;
		}
		var startY:Int = 0;
		if (ty < 0) {
			startY = cast Math.abs(ty);
		} else if (ty >= this.data.length) {
			startY = 0;
		}
		for (i in 0...this.data.length) {
			for (j in 0...this.data[i].length) {
				newData[i + startY][j + startX] = this.data[i][j];
			}
		}
		this.data = newData;
		for (i in 0...this.data.length) {
			for (j in 0...this.data[i].length) {
				if (this.data[i][j] == null) {
					this.data[i][j] = filler();
				}
			}
		}
	}

	function determineNewSize(value:Int, originalSize:Int):Int {
		if (value < 0) {
			return originalSize + cast Math.abs(value);
		}
		if (value >= originalSize) {
			return value + 1;
		}
		return 0;
	}
}
