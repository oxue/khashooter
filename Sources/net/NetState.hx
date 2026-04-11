package net;

import haxe.Json;

class NetState {

    public var client:NetClient;
    public var localId:Int;

    // Local player's synced vars
    public var localPosX:SyncVar;
    public var localPosY:SyncVar;
    public var localRotation:SyncVar;
    public var localAnimState:Int;
    public var localWeapon:Int;

    // Remote players' state: clientId -> RemotePlayerState
    public var remotePlayers:Map<Int, RemotePlayerState>;

    // Callbacks for game integration
    public var onPlayerJoined:Int -> Float -> Float -> Void;
    public var onPlayerLeft:Int -> Void;
    public var onHit:Int -> Int -> Float -> Float -> Void; // target, source, damage, health
    public var onKill:Int -> Int -> Void; // killed, killer
    public var onSpawn:Int -> Float -> Float -> Void; // id, x, y
    public var onRemoteShoot:Int -> String -> Float -> Float -> Float -> Void; // from, weapon, x, y, dir

    var sendTimer:Int;
    static inline var SEND_INTERVAL:Int = 3; // send every 3 frames (20Hz at 60fps)

    public function new() {
        client = new NetClient();
        localId = -1;
        remotePlayers = new Map<Int, RemotePlayerState>();
        localPosX = new SyncVar(0);
        localPosY = new SyncVar(0);
        localRotation = new SyncVar(0);
        localAnimState = 0;
        localWeapon = 0;
        sendTimer = 0;

        client.onConnect = onConnected;
        client.onMessage = onServerMessage;
        client.onDisconnect = onDisconnected;
    }

    public function connect(serverUrl:String) {
        client.connect(serverUrl);
    }

    function onConnected(id:Int) {
        localId = id;
        log("STATE", 'connected as player $id');
    }

    function onDisconnected() {
        log("STATE", 'disconnected');
        localId = -1;
    }

    function onServerMessage(msg:Dynamic) {
        var msgType:String = Std.string(msg.type);
        switch (msgType) {
            case "state":
                applyRemoteState(msg.from, msg.vars);

            case "player_joined":
                var joinId:Int = msg.id;
                log("PLAYER_JOINED", 'id=$joinId name=${msg.name}');
                var rp = new RemotePlayerState();
                rp.posX.set(msg.spawn.x);
                rp.posY.set(msg.spawn.y);
                remotePlayers.set(joinId, rp);
                if (onPlayerJoined != null) onPlayerJoined(joinId, msg.spawn.x, msg.spawn.y);

            case "player_left":
                var leftId:Int = msg.id;
                log("PLAYER_LEFT", 'id=$leftId');
                remotePlayers.remove(leftId);
                if (onPlayerLeft != null) onPlayerLeft(leftId);

            case "hit":
                log("HIT", 'target=${msg.target} source=${msg.source} damage=${msg.damage} health=${msg.health}');
                if (onHit != null) onHit(msg.target, msg.source, msg.damage, msg.health);

            case "hit_confirm":
                log("HIT_CONFIRM", 'target=${msg.target} damage=${msg.damage}');

            case "kill":
                log("KILL", 'killed=${msg.killed} killer=${msg.killer}');
                if (onKill != null) onKill(msg.killed, msg.killer);

            case "spawn":
                log("SPAWN", 'id=${msg.id} x=${msg.x} y=${msg.y}');
                if (onSpawn != null) onSpawn(msg.id, msg.x, msg.y);

            case "shoot":
                log("REMOTE_SHOOT", 'from=${msg.from} weapon=${msg.weapon}');
                if (onRemoteShoot != null) onRemoteShoot(msg.from, msg.weapon, msg.x, msg.y, msg.dir);
        }
    }

    function applyRemoteState(fromId:Int, vars:Dynamic) {
        if (vars == null) return;

        var rp = remotePlayers.get(fromId);
        if (rp == null) {
            rp = new RemotePlayerState();
            remotePlayers.set(fromId, rp);
        }

        // Parse synced vars
        var posXKey = '${fromId}|pos_x';
        var posYKey = '${fromId}|pos_y';
        var rotKey = '${fromId}|rot';

        var posXVal:Dynamic = Reflect.field(vars, posXKey);
        var posYVal:Dynamic = Reflect.field(vars, posYKey);
        var rotVal:Dynamic = Reflect.field(vars, rotKey);

        if (posXVal != null) rp.posX.applyRemote(posXVal[0], posXVal[1]);
        if (posYVal != null) rp.posY.applyRemote(posYVal[0], posYVal[1]);
        if (rotVal != null) rp.rotation.applyRemote(rotVal[0], rotVal[1]);

        var animKey = '${fromId}|anim';
        var weapKey = '${fromId}|weapon';
        var animVal:Dynamic = Reflect.field(vars, animKey);
        var weapVal:Dynamic = Reflect.field(vars, weapKey);
        if (animVal != null) rp.animState = Std.int(animVal[0]);
        if (weapVal != null) rp.weapon = Std.int(weapVal[0]);
    }

    // Call every frame
    public function update(dt:Float) {
        // Interpolate remote players
        for (rp in remotePlayers) {
            rp.posX.update(dt);
            rp.posY.update(dt);
            rp.rotation.update(dt);
        }

        // Send local state periodically
        sendTimer++;
        if (sendTimer >= SEND_INTERVAL && client.isConnected() && localId >= 0) {
            sendTimer = 0;
            sendLocalState();
        }
    }

    function sendLocalState() {
        var vars:Dynamic = {};
        Reflect.setField(vars, '${localId}|pos_x', localPosX.serialize());
        Reflect.setField(vars, '${localId}|pos_y', localPosY.serialize());
        Reflect.setField(vars, '${localId}|rot', localRotation.serialize());
        Reflect.setField(vars, '${localId}|anim', [localAnimState, 0]);
        Reflect.setField(vars, '${localId}|weapon', [localWeapon, 0]);
        client.sendUpdate(vars);
    }

    public function isConnected():Bool {
        return client.isConnected() && localId >= 0;
    }

    static function log(tag:String, msg:String) {
        #if js
        untyped __js__("console.log('[NET:' + {0} + '] ' + {1})", tag, msg);
        #end
    }
}

class RemotePlayerState {
    public var posX:SyncVar;
    public var posY:SyncVar;
    public var rotation:SyncVar;
    public var animState:Int;
    public var weapon:Int;

    public function new() {
        posX = new SyncVar(0);
        posY = new SyncVar(0);
        rotation = new SyncVar(0);
        animState = 0;
        weapon = 0;
    }
}
