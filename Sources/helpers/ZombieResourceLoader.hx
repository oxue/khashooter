package helpers;

import haxe.Timer;
import kha.Assets;
import refraction.display.ResourceFormat;
import refraction.display.SurfaceSetCmp;
import yaml.Yaml;

class ZombieResourceLoader {

	static inline final ROTATED_SPRITE:String = "rotated_sprite";
	static inline final TILESHEET:String = "tilesheet";

	public static function load() {
		var t:Float = Timer.stamp();
		ResourceFormat.images.set("mimi_normal", Assets.images.mimi_normal);
		ResourceFormat.images.set("mimi_pout", Assets.images.mimi_pout);

		ResourceFormat.beginAtlas("all");

		var configs:Dynamic = getSpriteConfigs();
		var sprites:Array<Dynamic> = cast configs.get("sprites");
		for (spriteConfig in sprites) {
			formatSprite(spriteConfig);
		}

		ResourceFormat.endAtlas();
		DebugLogger.info("PERF", {time: Timer.stamp() - t});
	}

	static function formatSprite(spriteConfig:Dynamic) {
		var spriteName:String = spriteConfig.get("name");
		var surfaceName:String = spriteConfig.get("surface_name");

		if (spriteConfig.get("type") == TILESHEET) {
			ResourceFormat.formatTileSheet(
				surfaceName,
				Assets.images.get(spriteName),
				spriteConfig.get("size_px")
			);
		} else if (spriteConfig.get("type") == ROTATED_SPRITE) {
			final dimensions = spriteConfig.get("dimensions");
			var surfaceSetComp:SurfaceSetCmp = ResourceFormat.formatRotatedSprite(
				surfaceName,
				Assets.images.get(spriteName),
				dimensions[0],
				dimensions[1]
			);
			final translation = spriteConfig.get("translation");
			final registration = spriteConfig.get("registration");
			if (translation != null) {
				surfaceSetComp.addTranslation(translation[0], translation[1]);
			}
			if (registration != null) {
				surfaceSetComp.registration(registration[0], registration[1]);
			}
		}
	}

	public static function getSpriteConfigs():Dynamic {
		var yamlObj:Dynamic = Yaml.parse(Assets.blobs.sprite_configs_yaml.toString());
		return yamlObj;
	}
}
