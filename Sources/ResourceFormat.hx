package;
import hxblit.Surface2;
import hxblit.TextureAtlas;
import kha.Image;
import refraction.core.Entity;
import refraction.display.SurfaceSet;
import refraction.tile.TileRender;
import refraction.tile.TilemapData;

/**
 * ...
 * @author 
 */
class ResourceFormat
{
	
	private static var curAtlas:TextureAtlas = null;
	
	public static var atlases:Map<String, TextureAtlas>;
	public static var surfacesets:Map<String, SurfaceSet>;

	public static function init(){
		atlases = new Map<String, TextureAtlas>();
	}

	public static function getSurfaceSet(_name:String):SurfaceSet
	{
		return surfacesets.get(_name);
	}
	
	public static function beginAtlas(_name:String){
		if (curAtlas != null)
		{
			return;
		}
		var newAtlas = new TextureAtlas();
		atlases.set(_name, newAtlas);
		curAtlas = newAtlas;
		surfacesets = new Map<String, SurfaceSet>();
	}

	public static function formatTileSheet(_name:String, _img:Image, _tilesize:Int):SurfaceSet
	{
		var ret:SurfaceSet = curAtlas.splitAndIndex(_img, new FloatRect(0, 0, _tilesize, _tilesize));
		surfacesets.set(_name, ret);
		return ret;
	}
	
	public static function formatRotatedSprite(_name:String, _img:Image, _w:Int, _h:Int):SurfaceSet
	{
		var baked:Image = TextureAtlas.bakeForAnimation(_img, new IntRect(0, 0, _w, _h), 32);
		var diagnol:Int = Math.ceil(Math.sqrt(_w * _w + _h * _h));
		var ret:SurfaceSet = formatTileSheet(_name, baked, diagnol);
		ret.translateX = (diagnol - _w) / 2;
		ret.translateY = (diagnol - _h) / 2;
		return ret;	
	}
	
	public static function endAtlas(){
		curAtlas.binpack();
		for(surfaceset in surfacesets){
			var j:Int = surfaceset.indexes.length;
			while (j-->0){
				surfaceset.surfaces[j] = curAtlas.assets.get(surfaceset.indexes[j]);
			}
		}
	}
	
	public function new() 
	{
		
	}
	
}