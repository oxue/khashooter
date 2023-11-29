package refraction.core;

import haxe.ds.StringMap;
import helpers.DebugLogger;

/**
 * ...
 * @author worldedit
 */
class Entity {
    public var components:Map<String, Component>;

    var events:StringMap<Dynamic->Void>;

    public function new() {
        components = new Map<String, Component>();
        events = new StringMap<Dynamic->Void>();
    }

    public function addComponent(_comp:Component, ?_name:String):Component {
        var compName:String = (_name == null) ? Type.getClassName(Type.getClass(_comp)) : _name;
        if (components.exists(compName)) {
            throw "Component with name " + compName + " already exists on entity";
        }
        components.set(compName, _comp);
        _comp.entity = this;
        _comp.load();
        return _comp;
    }

    public function on(_msgType:String, _msgHandler:Dynamic->Void) {
        events.set(_msgType, _msgHandler);
    }

    function notifySelf(_msgType:String, ?_msgData:Dynamic) {
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

    public function notify(_msgType:String, ?_msgData:Dynamic) {
        notifySelf(_msgType, _msgData);

        for (comp in components) {
            comp.notify(_msgType, _msgData);
        }
    }

    public inline function removeComponent(_name:String) {
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

    public function linSearchType<T>(_type:Class<T>):T {
        for (comp in components) {
            if (Std.isOfType(comp, _type)) {
                return cast comp;
            }
        }
        return null;
    }

    public function remove() {
        for (comp in components) {
            comp.unload();
            comp.remove = true;
        }
    }
}
