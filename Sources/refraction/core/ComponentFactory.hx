package refraction.core;

import refraction.core.Component;

class ComponentFactory {
	private var gameContext:Dynamic;

	public function new(_gameContext:Dynamic) {
		gameContext = _gameContext;
	}

	public function get(_type:String, _e:Entity, _name:String = null):Component {
		return null;
	}
}
