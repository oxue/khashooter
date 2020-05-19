package refraction.core;

import haxe.ds.StringMap;
import helpers.DebugLogger;

/**
 * ...
 * @author worldedit
 */
class Entity {
	public var components:Map<String, Component>;

	private var events:StringMap<Dynamic->Void>;

	public function new() {
		components = new Map<String, Component>();
		events = new StringMap<Dynamic->Void>();
	}

	public inline function addComponent(_comp:Component, ?_name:String):Component {
		var compName = (_name == null) ? Type.getClassName(Type.getClass(_comp)) : _name;
		components.set(compName, _comp);
		_comp.entity = this;
		_comp.load();
		return _comp;
	}

	public function on(_msgType:String, _msgHandler:Dynamic->Void):Void {
		events.set(_msgType, _msgHandler);
	}

	private function notifySelf(_msgType:String, _msgData:Dynamic = null) {
		if (events.exists(_msgType)) {
			DebugLogger.info("NOTIFY", {
				recipientClass: Type.getClassName(Type.getClass(this)),
				messageType: _msgType,
				messageData: _msgData
			});

			var handler = events.get(_msgType);
			handler(_msgData);
		}
	}

	public function notify(_msgType:String, _msgData:Dynamic = null):Void {
		notifySelf(_msgType, _msgData);

		for (comp in components) {
			comp.notify(_msgType, _msgData);
		}
	}

	public inline function removeComponent(_name:String):Void {
		components
			.get(_name)
			.remove = true;
		components.remove(_name);
	}

	@:generic
	public function getComponent<T>(_type:Class<T>, ?_name:String):T {
		if (_name != null) {
			return cast components.get(_name);
		} else {
			return cast components.get(Type.getClassName(_type));
		}
	}

	public function remove():Void {
		for (comp in components) {
			comp.remove = true;
		}
	}
}
