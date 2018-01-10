package refraction.core;

import refraction.core.Component;

class ComponentFactory
{
	private var gameContext:GameContext;

	public function new(_gameContext:GameContext)
	{
		gameContext = _gameContext;
	}

	public function get(_type:String, _e:Entity, _name:String = null):Component
	{
		return null;
	}
}