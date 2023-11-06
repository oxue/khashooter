package refraction.core;

import haxe.ds.StringMap;
import helpers.DebugLogger;

/**
 * ...
 * @author worldedit
 */
class Component {
	/**
		The component should be removed
	**/
	public var remove:Bool;

	public var entity:Entity;

	var events:StringMap<Dynamic->Void>;

	public function new() {
		events = new StringMap<Dynamic->Void>();
	}

	public function getEntity():Entity {
		return entity;
	}

	public function reset() {
		remove = false;
	}

	public function defaulted(_value:Dynamic, ?_default:Dynamic):Dynamic {
		if (_value != null) {
			return _value;
		}
		return _default;
	}

	public function notify(_msgType:String, _msgData:Dynamic) {
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

	public function on(_msgType:String, _msgHandler:Dynamic->Void) {
		events.set(_msgType, _msgHandler);
	}

	public function autoParams(_args:Dynamic) {}

	public function load() {}

	public function unload() {}

	public function update() {}
}
