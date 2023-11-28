package;

import game.PhysState;
import game.GameState;
import hxblit.KhaBlit;
import kha.Assets;
import refraction.core.Application;
import refraction.display.ResourceFormat;
import yaml.Yaml;

class Main {

	public static function main() {
		// Application.init("Physics Test", 600, 400, 1, function() {
		// 	Application.setState(new PhysState());
		// });

		Assets.blobs.config_yamlLoad(() -> {
			var config:Dynamic = Yaml.parse(Std.string(Assets.blobs.config_yaml));

			Application.init(
				"Pew Pew",
				config.get("system").get("width"),
				config.get("system").get("height"),
				config.get("system").get("zoom"),
				function() {
					KhaBlit.init(
						Application.getScreenWidth(),
						Application.getScreenHeight(),
						Application.getScreenZoom()
					);
					ResourceFormat.init();
					Application.setState(new GameState());
				}
			);
		});
	}
}
