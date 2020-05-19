package refraction.tile;

// import flash.Vector;
import refraction.ds2d.Face;
import refraction.ds2d.Float2;
import refraction.ds2d.Polygon;
import kha.math.Vector2;

/**
 * ...
 * @author worldedit
 */
class TilemapUtils {
	public static function raycast(targetTilemap:TilemapData, x1:Float, y1:Float, x2:Float, y2:Float):Bool {
		var i:Int = Math.floor(x1 / targetTilemap.tilesize);
		var j:Int = Math.floor(y1 / targetTilemap.tilesize);

		var iEnd:Int = Math.floor(x2 / targetTilemap.tilesize);
		var jEnd:Int = Math.floor(y2 / targetTilemap.tilesize);

		var di:Int = ((x1 < x2) ? 1 : ((x1 > x2) ? -1 : 0));
		var dj:Int = ((y1 < y2) ? 1 : ((y1 > y2) ? -1 : 0));

		var minX:Float = targetTilemap.tilesize * Math.floor(x1 / targetTilemap.tilesize);
		var maxX:Float = minX + targetTilemap.tilesize;

		var minY:Float = targetTilemap.tilesize * Math.floor(y1 / targetTilemap.tilesize);
		var maxY:Float = minY + targetTilemap.tilesize;

		var tx:Float = ((x1 > x2) ? (x1 - minX) : (maxX - x1)) / Math.abs(x2 - x1);
		var ty:Float = ((y1 > y2) ? (y1 - minY) : (maxY - y1)) / Math.abs(y2 - y1);

		var deltaX:Float = targetTilemap.tilesize / Math.abs(x2 - x1);
		var deltaY:Float = targetTilemap.tilesize / Math.abs(y2 - y1);
		// targetTilemap.tilesize = 16;
		// collidePoint.x = x2;
		// collidePoint.y = y2;

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
				break;
			}

			if (tx <= ty) {
				if (i == iEnd) {
					if (t.solid) {
						return true;
						break;
					}
					break;
				}
				tx += deltaX;
				i += di;
			} else {
				if (j == jEnd) {
					if (t.solid) {
						return true;
						break;
					}
					break;
				}
				ty += deltaY;
				j += dj;
			}
		}
		return false;
	}

	public static function computeGeometry(_t:TilemapData):Array<Polygon> {
		var ret:Array<Polygon> = new Array<Polygon>();

		var a = [];
		var i:Int = _t.height - 1;
		while (i-- > 1) {
			var j:Int = _t.width - 1;
			while (j-- > 1) {
				var p:Polygon = new Polygon(3, 1, cast j * _t.tilesize + _t.tilesize / 2,
					cast i * _t.tilesize + _t.tilesize / 2);
				p.faces = new Array<Face>();
				if (_t.data[i][j].solid) {
					if (!_t.data[i][j - 1].solid) {
						p.faces.push(new Face(new Vector2(j * _t.tilesize, i * _t.tilesize),
							new Vector2(j * _t.tilesize, (i + 1) * _t.tilesize), 1));
					}
					if (!_t.data[i][j + 1].solid) {
						p.faces.push(new Face(new Vector2((j + 1) * _t.tilesize, i * _t.tilesize),
							new Vector2((j + 1) * _t.tilesize, (i + 1) * _t.tilesize), 2));
					}
					if (!_t.data[i - 1][j].solid) {
						p.faces.push(new Face(new Vector2(j * _t.tilesize, i * _t.tilesize),
							new Vector2((j + 1) * _t.tilesize, i * _t.tilesize), 3));
					}
					if (!_t.data[i + 1][j].solid) {
						p.faces.push(new Face(new Vector2(j * _t.tilesize, (i + 1) * _t.tilesize),
							new Vector2((j + 1) * _t.tilesize, (i + 1) * _t.tilesize), 4));
					}
					ret.push(p);
				}
			}
		}
		return ret;
	}
}
