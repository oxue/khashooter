package refraction.tilemap;

import haxe.ds.Vector;
import helpers.DebugLogger;
import refraction.utils.Pair;
import haxe.Timer;
import kha.math.Vector2;

class DijkstraField extends GenericTileMap<Vector2> {

	var solidFunc:(Int, Int) -> Bool;

	public function new(width:Int, height:Int, tilesize:Int, solidFunc:(Int, Int) -> Bool) {
		super(width, height, tilesize);

		this.solidFunc = solidFunc;
	}
	
	function neighbors(i, j):Array<Pair<Int, Int>> {
		var ret:Array<Pair<Int, Int>> = [];
		for (d in [[-1, 0], [1, 0], [0, -1], [0, 1], [1, 1], [-1, -1], [-1, 1], [1, -1]]) {
			var di:Int = d[0];
			var dj:Int = d[1];

			var ii:Int = i + di;
			var jj:Int = j + dj;

			if (di == 0 && dj == 0) {
				continue;
			}

			if (di * dj != 0) {
				if (solidFunc(i, jj) || solidFunc(ii, j)) {
					continue;
				}
			}

			if (ii < 0 || jj < 0 || ii >= height || jj >= width) {
				continue;
			}
			if (solidFunc(ii, jj)) {
				continue;
			}
			ret.push(new Pair(ii, jj));
		}
		return ret;
	}

	public function smoothen(size:Int) {
		var ts:Float = Timer.stamp();

		var newData:Vector<Vector<Vector2>> = new Vector<Vector<Vector2>>(height);
		for (i in 0...height) {
			newData[i] = new Vector<Vector2>(width);
			for (j in 0...width) {
				newData[i][j] = null;
			}
		}

		for (i in 0...height) {
			for (j in 0...width) {
				if (data[i][j] == null) {
					continue;
				}
				var sum:Vector2 = new Vector2(0, 0);
				var count:Int = 0;
				for (di in -size...size) {
					for (dj in -size...size) {
						var ii:Int = i + di;
						var jj:Int = j + dj;

						if (ii < 0 || jj < 0 || ii >= height || jj >= width) {
							continue;
						}

						if (data[ii][jj] != null) {
							sum = sum.add(data[ii][jj]);
							count++;
						}
					}
				}
				if (count > 0) {
					newData[i][j] = sum.normalized();
				}
			}
		}

		data = newData;

		DebugLogger.info(
			'PERF',
			'Dijkstra field smoothened in ' + (Timer.stamp() - ts) + ' seconds'
		);
	
	}

	public function setTarget(ti:Int, tj:Int) {
		var ts:Float = Timer.stamp();

		// clear
		for (i in 0...height) {
			for (j in 0...width) {
				data[i][j] = null;
			}
		}

		var q:Array<Pair<Int, Int>> = [new Pair(ti, tj)];
		setTileAt(ti, tj, new Vector2(1, 1));

		var count:Int = 0;

		while (q.length > 0) {
			var cur:Pair<Int, Int> = q.shift();
			var curI:Int = cur.first;
			var curJ:Int = cur.second;

			for (tile in neighbors(curI, curJ)) {
				var i:Int = tile.first;
				var j:Int = tile.second;
				if (data[i][j] == null) { // if not visited
					data[i][j] = new Vector2(curJ - j, curI - i)
						.normalized();
					q.push(tile);
					count++;
				}
			}
		}
		DebugLogger.info(
			'PERF',
			'Dijkstra field computed in ' + (Timer.stamp() - ts) + ' seconds, ' + count + ' tiles visited'
		);
	}
}
