package refraction.core;
import haxe.ds.StringMap;
import haxe.Json;
import kha.Assets;

class TemplateParser
{
	public static function parse():StringMap<Dynamic>
	{
		var jsonObj:Dynamic = Json.parse(Assets.blobs.entity_entities_json.toString());
		var ret = new StringMap<Dynamic>();
		var i:Int = jsonObj.entities.length;

		while(i-->0){
			var entityName:String = jsonObj.entities[i];
			ret.set(entityName, getEntityTemplate(entityName));
		}

		return ret;
	}

	private static function getEntityTemplate(_entityName:String):Dynamic
	{
		var entityBlob:String = Reflect.field(Assets.blobs, 'entity_${_entityName}_json').toString();
		return Json.parse(entityBlob);
	}
}