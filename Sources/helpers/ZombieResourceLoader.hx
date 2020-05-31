package helpers;

import haxe.Timer;
import kha.Assets;
import refraction.display.ResourceFormat;

class ZombieResourceLoader {
	public static function load():Void {
		var t = Timer.stamp();
		ResourceFormat.init();
		ResourceFormat.beginAtlas("all");

		ResourceFormat.formatTileSheet("all_tiles", Assets.images.tilesheet, 16);
		ResourceFormat.formatTileSheet("modern", Assets.images.modern, 16);

		ResourceFormat
			.formatRotatedSprite("man", Assets.images.man, 26, 26)
			.addTranslation(3, 3);
		ResourceFormat
			.formatRotatedSprite("mimi", Assets.images.mimi, 26, 26)
			.addTranslation(3, 3)
			.registration(10, 10);
		ResourceFormat
			.formatRotatedSprite("zombie", Assets.images.zombie, 32, 32)
			.addTranslation(6, 6)
			.registration(10, 10);
		ResourceFormat
			.formatRotatedSprite("shiro", Assets.images.shiro, 26, 26)
			.addTranslation(3, 3)
			.registration(10, 10);
		ResourceFormat.formatRotatedSprite("items", Assets.images.items, 32, 32);
		ResourceFormat
			.formatRotatedSprite("gyo", Assets.images.gyo, 29, 24)
			.addTranslation(3, 4);
		ResourceFormat
			.formatRotatedSprite("weapons", Assets.images.crossbow, 26, 26)
			.addTranslation(3, 3)
			.registration(-3, 5);
		ResourceFormat
			.formatRotatedSprite("projectiles", Assets.images.projectiles, 20, 20)
			.registration(10, 10);
		ResourceFormat
			.formatRotatedSprite("gibs", Assets.images.gibs, 16, 16)
			.registration(8, 8);

		ResourceFormat.endAtlas();
		DebugLogger.info("PERF", {time: Timer.stamp() - t});
	}
}
