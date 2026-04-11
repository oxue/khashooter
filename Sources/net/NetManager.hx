package net;

import refraction.core.Entity;

class NetManager {

    static var _instance:NetManager;

    public static function instance():NetManager {
        if (_instance == null) {
            _instance = new NetManager();
        }
        return _instance;
    }

    public static function destroy() {
        _instance = null;
    }

    public var entities:Map<String, Entity>;

    public function new() {
        entities = new Map<String, Entity>();
    }

    public function register(netId:String, entity:Entity) {
        entities.set(netId, entity);
    }

    public function deregister(netId:String) {
        entities.remove(netId);
    }

    public function getEntity(netId:String):Entity {
        return entities.get(netId);
    }

    public function routeMessage(netId:String, msgType:String, data:Dynamic) {
        var entity = entities.get(netId);
        if (entity != null) {
            entity.notify("net:" + msgType, data);
        }
    }
}
