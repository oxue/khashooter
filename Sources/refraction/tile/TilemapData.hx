package refraction.tile;
//import flash.Vector;
import haxe.ds.Vector;
import kha.math.Vector2;
import refraction.core.Component;

/**
 * ...
 * @author qwerber
 */

class TilemapData extends Component
{
	public var data:Vector<Vector<Tile>>;
	
	public var width:Int;
	public var height:Int;
	
	public var tilesize:Int;
	
	public var colIndex:Int;
	
	public function new(_width:Int, _height:Int, _tilesize:Int, _colIndex:Int) 
	{
		width = _width;
		height = _height;
		tilesize = _tilesize;
		
		data = new Vector<Vector<Tile>>(_height);
		var i:Int = _height;
		while (i-->0)
		{
			data[i] = new Vector<Tile>(_width);
		}
		
		colIndex = _colIndex;
		
		super();
	}

	public function hitTestPoint(p:Vector2):Bool
	{
		var tCol = Math.floor(p.x / tilesize);
		var tRow = Math.floor(p.y / tilesize);
		var tile = getTileAt(tRow, tCol);
		return tile!=null && tile.solid;
	}

	public function getTileAt(row:Int, col:Int):Tile
	{
		if(row < 0 || col < 0 || row >= height || col >= width)
		{
			return null;
		}

		return data[row][col];
	}
	
	public function setDataIntArray(_data:Array<Array<Int>>):Void
	{
		var i:Int = _data.length;
		while (i-->0)
		{
			var j:Int = _data[0].length;
			while (j-->0)
			{
				var t:Tile = new Tile();
				t.imageIndex = _data[i][j];
				t.solid = (_data[i][j] > colIndex);
				data[i][j] = t;
			}
		}
		
	}
	
}