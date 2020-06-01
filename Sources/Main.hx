package;

import refraction.display.ResourceFormat;
import hxblit.KhaBlit;
import pgr.dconsole.DC;
import refraction.core.Application;
import game.GameState;


class Main {
	public static function main() {
		

		Application.init("HXB Port", 1920, 1080, 2, function() {
			KhaBlit.init(Application.width, Application.height, Application.zoom);
			ResourceFormat.init();
			Application.setState(new GameState("rooms"));
		});
	}
}
