package game;

class Values {

	var config:Dynamic;

	public function new(_config:Dynamic) {
		config = _config;
	}

	public function getRandomGibSplashMaginutude():Float {
		var range:Float = config.gib_splash_magnitude_max - config.gib_splash_magnitude_min;
		return Math.random() * range + config.gib_splash_magnitude_min;
	}
}
