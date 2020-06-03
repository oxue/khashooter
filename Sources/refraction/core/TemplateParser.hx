package refraction.core;

import helpers.DebugLogger;
import haxe.ds.StringMap;
import haxe.Json;
import kha.Assets;
import yaml.Yaml;
import yaml.Parser;

class TemplateParser {
	public static var FALL_BACK_TO_JSON:Array<String> = [];

	public static function parse():StringMap<Dynamic> {
		var yamlObj:Dynamic = Yaml.parse(Assets.blobs.entity_entities_yaml.toString());
		var ret = new StringMap<Dynamic>();
		var i:Int = yamlObj
			.get("entities")
			.length;

		while (i-- > 0) {
			var entityName:String = yamlObj.get("entities")[i];
			ret.set(entityName, getEntityTemplate(entityName));
		}

		return ret;
	}

	public static function parseConfig():StringMap<Dynamic> {

		var str = Assets.blobs.config_yaml.toString();
		return Yaml.parse(str, Parser
			.options()
			.useObjects()
		);
	}

	public static function reloadConfigurations(_dirPath, _done:Dynamic->Void):Void {
		Assets.loadBlobFromPath('${_dirPath}/config.yaml', (blob) -> {
			var yamlObj:Dynamic = Yaml.parse(blob.toString(), Parser
				.options()
				.useObjects()
			);
			DebugLogger.info("yamlObj", yamlObj);
			_done(yamlObj);
		});
	}

	public static function reloadEntityBlobs(_dirPath:String, _done:StringMap<Dynamic>->Void):Void {
		Assets.loadBlobFromPath('${_dirPath}/entities.yaml', (blob) -> {
			var yamlObj:Dynamic = Yaml.parse(blob.toString());
			var ret = new StringMap<Dynamic>();
			var numReturned = 0;
			for (entityName in cast(yamlObj.get("entities"), Array<Dynamic>)) {
				loadEntityTemplate(_dirPath, entityName, (template) -> {
					ret.set(entityName, template);
				});
				numReturned++;
				if (numReturned >= yamlObj
					.get("entities")
					.length
				) {
					_done(ret);
				}
			}
		});
	}

	public static function loadEntityTemplate(_dirPath:String, _name:String, _done:Dynamic->Void):Void {
		Assets.loadBlobFromPath('${_dirPath}/${_name}.yaml', (blob) -> {
			_done(Yaml.parse(blob.toString(), Parser
				.options()
				.useObjects()
			));
		});
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
