package;

import refraction.core.Application;
import game.GameState;

class Main {
	public static function main() {
		Application.init("HXB Port", 800, 600, 2, function() {
			Application.setState(new GameState());
		});
	}
}
