package refraction.core;

import haxe.ds.StringMap;
import haxe.Json;
import kha.Assets;
import yaml.Yaml;
import yaml.Parser;

class TemplateParser {
	public static var FALL_BACK_TO_JSON:Array<String> = [];

	public static function parse():StringMap<Dynamic> {
		var jsonObj:Dynamic = Yaml.parse(Assets.blobs.entity_entities_yaml.toString());
		var ret = new StringMap<Dynamic>();
		var i:Int = jsonObj
			.get("entities")
			.length;

		while (i-- > 0) {
			var entityName:String = jsonObj.get("entities")[i];
			ret.set(entityName, getEntityTemplate(entityName));
		}

		return ret;
	}

	private static function getEntityTemplate(_entityName:String):Dynamic {
		if (FALL_BACK_TO_JSON.indexOf(_entityName) == -1) {
			var entityBlobYaml = Reflect
				.field(Assets.blobs, 'entity_${_entityName}_yaml')
				.toString();
			return Yaml.parse(entityBlobYaml, Parser
				.options()
				.useObjects()
			);
		}
		var entityBlob:String = Reflect
			.field(Assets.blobs, 'entity_json_${_entityName}_json')
			.toString();
		return Json.parse(entityBlob);
	}
}
