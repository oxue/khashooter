package refraction.core;

import haxe.Json;
import haxe.ds.StringMap;
import helpers.DebugLogger;
import kha.Assets;
import yaml.Parser;
import yaml.Yaml;

class TemplateParser {

	public static var FALL_BACK_TO_JSON:Array<String> = [];

	public static function parse():StringMap<Dynamic> {
		var entityYamlNames:Array<String> = Reflect
			.fields(Assets.blobs)
			.filter(
				(field) -> (field.indexOf("entity_") == 0 && field.substr(field.length - 4) == "yaml")
			);
		var ret:StringMap<Dynamic> = new StringMap<Dynamic>();

		for (entityYaml in entityYamlNames) {
			var template:Dynamic = getEntityTemplate(entityYaml);
			ret.set(template.entity_name, template);
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

	public static function reloadConfigurations(_dirPath, _done:Dynamic -> Void) {
		Assets.loadBlobFromPath('${_dirPath}/config.yaml', (blob) -> {
			var yamlObj:Dynamic = Yaml.parse(blob.toString(), Parser
				.options()
				.useObjects()
			);
			DebugLogger.info("yamlObj", yamlObj);
			_done(yamlObj);
		});
	}

	public static function reloadEntityBlobs(_dirPath:String, _done:StringMap<Dynamic> -> Void) {
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

	public static function loadEntityTemplate(_dirPath:String, _name:String, _done:Dynamic -> Void) {
		Assets.loadBlobFromPath('${_dirPath}/${_name}.yaml', (blob) -> {
			_done(
				Yaml.parse(blob.toString(), Parser
					.options()
					.useObjects()
				)
			);
		});
	}

	static function getEntityTemplate(_entityName:String):Dynamic {
		var entityBlobYaml:String = Reflect
			.field(Assets.blobs, _entityName)
			.toString();
		return Yaml.parse(entityBlobYaml, Parser
			.options()
			.useObjects()
		);
	}
}
