package refraction.tilemap;

import kha.math.Vector2;
import refraction.ds2d.Face;
import refraction.ds2d.Polygon;

/**
 * ...
 * @author worldedit
 */
class TilemapUtils {
	public static function raycast(targetTilemap:Tilemap, x1:Float, y1:Float, x2:Float, y2:Float):Bool {
		var i:Int = Math.floor(x1 / targetTilemap.tilesize);
		var j:Int = Math.floor(y1 / targetTilemap.tilesize);

		var iEnd:Int = Math.floor(x2 / targetTilemap.tilesize);
		var jEnd:Int = Math.floor(y2 / targetTilemap.tilesize);

		var di:Int = ((x1 < x2) ? 1 : ((x1 > x2) ? -1 : 0));
		var dj:Int = ((y1 < y2) ? 1 : ((y1 > y2) ? -1 : 0));

		var minX:Float = targetTilemap.tilesize * Math.floor(
			x1 / targetTilemap.tilesize
		);
		var maxX:Float = minX + targetTilemap.tilesize;

		var minY:Float = targetTilemap.tilesize * Math.floor(
			y1 / targetTilemap.tilesize
		);
		var maxY:Float = minY + targetTilemap.tilesize;

		var tx:Float = ((x1 > x2) ? (x1 - minX) : (maxX - x1)) / Math.abs(
			x2 - x1
		);
		var ty:Float = ((y1 > y2) ? (y1 - minY) : (maxY - y1)) / Math.abs(
			y2 - y1
		);

		var deltaX:Float = targetTilemap.tilesize / Math.abs(
			x2 - x1
		);
		var deltaY:Float = targetTilemap.tilesize / Math.abs(
			y2 - y1
		);

		while (true) {
			var t:Tile;
			if (i < 0 || j < 0 || i >= targetTilemap.data[0].length || j >= targetTilemap.data.length) {
				t = new Tile();
				t.solid = false;
			} else {
				t = targetTilemap.data[j][i];
			}

			if (t.solid) {
				return true;
			}

			if (tx <= ty) {
				if (i == iEnd) {
					return t.solid;
				}
				tx += deltaX;
				i += di;
			} else {
				if (j == jEnd) {
					return t.solid;
				}
				ty += deltaY;
				j += dj;
			}
		}
		return false;
	}

	static function generatePolygonForTileInd(_tilemapData:Tilemap, i:Int, j:Int):Polygon {
		var p:Polygon = new Polygon();

		final left:Int = j * _tilemapData.tilesize;
		final top:Int = i * _tilemapData.tilesize;
		final bottom:Int = (i + 1) * _tilemapData.tilesize;
		final right:Int = (j + 1) * _tilemapData.tilesize;

		if (!_tilemapData.data[i][j - 1].solid) {
			p.faces.push(
				new Face(
					new Vector2(left, top),
					new Vector2(left, bottom),
				)
			);
		}
		if (!_tilemapData.data[i][j + 1].solid) {
			p.faces.push(
				new Face(
					new Vector2(right, top),
					new Vector2(right, bottom),
				)
			);
		}
		if (!_tilemapData.data[i - 1][j].solid) {
			p.faces.push(
				new Face(
					new Vector2(left, top),
					new Vector2(right, top),
				)
			);
		}
		if (!_tilemapData.data[i + 1][j].solid) {
			p.faces.push(
				new Face(
					new Vector2(left, bottom),
					new Vector2(right, bottom),
				)
			);
		}
		return p;
	}

	public static function computeGeometry(_tilemapData:Tilemap):Array<Polygon> {
		var ret:Array<Polygon> = [];
		for (i in 1..._tilemapData.height - 1) {
			for (j in 1..._tilemapData.width - 1) {
				if (!_tilemapData.data[i][j].solid) {
					continue;
				}
				var p:Polygon = generatePolygonForTileInd(
					_tilemapData,
					i,
					j
				);
				ret.push(p);
			}
		}
		return ret;
	}
}
