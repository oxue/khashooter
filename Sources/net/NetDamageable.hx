package net;

import components.Health;
import game.EntFactory;
import refraction.generic.PositionCmp;

class NetDamageable extends NetComponent {

    var position:PositionCmp;
    var health:Health;

    override public function load() {
        super.load(); // caches netIdentity
        position = entity.getComponent(PositionCmp);
        health = entity.getComponent(Health);

        // Subscribe to network events
        on("net:hit", onHit);
        on("net:kill", onKill);
        on("net:spawn", onSpawn);
    }

    function onHit(data:Dynamic) {
        if (health != null) health.value = Std.int(data.health);
        // Gib splash feedback
        if (position != null) {
            var ef = EntFactory.instance();
            if (ef != null) ef.createGibSplash(1, position);
        }
        log("HIT_FEEDBACK", "damage applied");
    }

    function onKill(data:Dynamic) {
        // Gib splash
        if (position != null) {
            var ef = EntFactory.instance();
            if (ef != null) ef.createGibSplash(5, position);
        }
        log("KILL_FEEDBACK", "death effect");
    }

    function onSpawn(data:Dynamic) {
        if (position != null) {
            position.x = data.x;
            position.y = data.y;
        }
        if (health != null) health.value = health.maxValue;
        log("SPAWN_FEEDBACK", "respawned");
    }

    static function log(tag:String, msg:String) {
        #if js
        untyped __js__("console.log('[GAME:' + {0} + '] ' + {1})", tag, msg);
        #end
    }
}
