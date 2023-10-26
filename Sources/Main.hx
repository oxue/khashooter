package;

import game.GameState;
import hxblit.KhaBlit;
import refraction.core.Application;
import refraction.display.ResourceFormat;

class Main {
	public static function main() {
		Application.init("HXB Port", 1200, 800, 2, function() {
			KhaBlit.init(Application.getScreenWidth(), Application.getScreenHeight(), Application.getScreenZoom());
			ResourceFormat.init();
			Application.setState(new GameState("rooms"));
		});
	}
}
