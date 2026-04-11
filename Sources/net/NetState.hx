package net;

import haxe.Json;

class NetState {

    public var client:NetClient;
    public var localId:Int;
    public var hostId:Int;

    // Local player's synced vars
    public var localPosX:SyncVar;
    public var localPosY:SyncVar;
    public var localRotation:SyncVar;
    public var localAnimState:Int;
    public var localWeapon:Int;

    // Remote players' state: clientId -> RemotePlayerState
    public var remotePlayers:Map<Int, RemotePlayerState>;

    // NPC state from host
    public var npcStates:Map<String, NpcState>;

    // Callbacks
    public var onPlayerJoined:Int -> Float -> Float -> Void;
    public var onPlayerLeft:Int -> Void;
    public var onHit:Int -> Int -> Float -> Float -> Void;
    public var onKill:Int -> Int -> Void;
    public var onSpawn:Int -> Float -> Float -> Void;
    public var onRemoteShoot:Int -> String -> Float -> Float -> Float -> Float -> Void;
    public var onNpcState:Map<String, NpcState> -> Void;
    public var onHostChange:Int -> Void;
    public var onChat:Int -> String -> String -> Void;

    var sendTimer:Int;
    var npcSendTimer:Int;
    static inline var SEND_INTERVAL:Int = 3; // 20Hz at 60fps
    static inline var NPC_SEND_INTERVAL:Int = 6; // 10Hz for NPCs

    public function new() {
        client = new NetClient();
        localId = -1;
        hostId = -1;
        remotePlayers = new Map<Int, RemotePlayerState>();
        npcStates = new Map<String, NpcState>();
        localPosX = new SyncVar(0);
        localPosY = new SyncVar(0);
        localRotation = new SyncVar(0);
        localAnimState = 0;
        localWeapon = 0;
        sendTimer = 0;
        npcSendTimer = 0;

        client.onConnect = onConnected;
        client.onMessage = onServerMessage;
        client.onDisconnect = onDisconnected;
    }

    public function connect(serverUrl:String) {
        client.connect(serverUrl);
    }

    public function isHost():Bool {
        return localId >= 0 && localId == hostId;
    }

    function onConnected(id:Int) {
        localId = id;
        log("STATE", 'connected as player $id host=$hostId');
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

            case "host_change":
                hostId = msg.hostId;
                log("HOST_CHANGE", 'new host=$hostId isHost=${isHost()}');
                if (onHostChange != null) onHostChange(hostId);

            case "hit":
                log("HIT", 'target=${msg.target} source=${msg.source} damage=${msg.damage} health=${msg.health}');
                if (onHit != null) onHit(msg.target, msg.source, msg.damage, msg.health);
                var nm = NetManager.instance();
                if (nm != null) nm.routeMessage("player_" + msg.target, "hit", {damage: msg.damage, health: msg.health, source: msg.source});

            case "hit_confirm":
                log("HIT_CONFIRM", 'target=${msg.target} damage=${msg.damage}');

            case "kill":
                log("KILL", 'killed=${msg.killed} killer=${msg.killer}');
                if (onKill != null) onKill(msg.killed, msg.killer);
                var nm = NetManager.instance();
                if (nm != null) nm.routeMessage("player_" + msg.killed, "kill", {killer: msg.killer});

            case "spawn":
                log("SPAWN", 'id=${msg.id} x=${msg.x} y=${msg.y}');
                if (onSpawn != null) onSpawn(msg.id, msg.x, msg.y);
                var nm = NetManager.instance();
                if (nm != null) nm.routeMessage("player_" + msg.id, "spawn", {x: msg.x, y: msg.y});

            case "shoot":
                var fromId:Int = msg.from;
                // Don't process our own shoot events
                if (fromId != localId) {
                    log("REMOTE_SHOOT", 'from=$fromId weapon=${msg.weapon}');
                    if (onRemoteShoot != null) onRemoteShoot(fromId, msg.weapon, msg.x, msg.y, msg.dir, msg.damage);
                    var nm = NetManager.instance();
                    if (nm != null) nm.routeMessage("player_" + fromId, "shoot", {weapon: msg.weapon, x: msg.x, y: msg.y, dir: msg.dir, damage: msg.damage});
                }

            case "chat":
                var fromId:Int = msg.from;
                var name:String = Std.string(msg.name);
                var text:String = Std.string(msg.text);
                log("CHAT", 'from=$fromId name=$name text=$text');
                if (onChat != null) onChat(fromId, name, text);

            case "npc_state":
                applyNpcState(msg.npcs);
        }
    }

    function applyRemoteState(fromId:Int, vars:Dynamic) {
        if (vars == null) return;

        var rp = remotePlayers.get(fromId);
        if (rp == null) {
            rp = new RemotePlayerState();
            remotePlayers.set(fromId, rp);
        }

        var posXVal:Dynamic = Reflect.field(vars, '${fromId}|pos_x');
        var posYVal:Dynamic = Reflect.field(vars, '${fromId}|pos_y');
        var rotVal:Dynamic = Reflect.field(vars, '${fromId}|rot');

        if (posXVal != null) rp.posX.applyRemote(posXVal[0], posXVal[1]);
        if (posYVal != null) rp.posY.applyRemote(posYVal[0], posYVal[1]);
        if (rotVal != null) rp.rotation.applyRemote(rotVal[0], rotVal[1]);

        var animVal:Dynamic = Reflect.field(vars, '${fromId}|anim');
        var weapVal:Dynamic = Reflect.field(vars, '${fromId}|weapon');
        if (animVal != null) rp.animState = Std.int(animVal[0]);
        if (weapVal != null) rp.weapon = Std.int(weapVal[0]);

        if (posXVal != null || posYVal != null) {
            log("RECV_POS", 'from=$fromId x=${rp.posX.value} y=${rp.posY.value}');
            // Route position to NetTransformReceiver via entity message system
            var nm = NetManager.instance();
            if (nm != null) {
                nm.routeMessage("player_" + fromId, "pos", {x: rp.posX.value, y: rp.posY.value, rot: rp.rotation.value});
            }
        }
    }

    function applyNpcState(npcs:Dynamic) {
        if (npcs == null) return;
        var npcArray:Array<Dynamic> = npcs;
        for (npc in npcArray) {
            var id:String = Std.string(npc.id);
            var state = npcStates.get(id);
            if (state == null) {
                state = new NpcState();
                npcStates.set(id, state);
            }
            state.posX.applyRemote(npc.x, 0);
            state.posY.applyRemote(npc.y, 0);
            state.rotation.applyRemote(npc.rot, 0);
        }
        if (onNpcState != null) onNpcState(npcStates);
    }

    public function update(dt:Float) {
        // Interpolate remote players
        for (rp in remotePlayers) {
            rp.posX.update(dt);
            rp.posY.update(dt);
            rp.rotation.update(dt);
        }

        // Interpolate NPC states (for non-host clients)
        if (!isHost()) {
            for (npc in npcStates) {
                npc.posX.update(dt);
                npc.posY.update(dt);
                npc.rotation.update(dt);
            }
        }

        // Send local state
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

    // Host sends NPC positions to server for relay
    public function sendNpcStates(npcs:Array<Dynamic>) {
        if (!isHost() || !client.isConnected()) return;
        npcSendTimer++;
        if (npcSendTimer >= NPC_SEND_INTERVAL) {
            npcSendTimer = 0;
            client.send({type: "npc_update", npcs: npcs});
        }
    }

    public function sendChat(text:String) {
        client.send({type: "chat", text: text});
    }

    public function sendShoot(weapon:String, x:Float, y:Float, dir:Float, damage:Float) {
        client.sendShoot(weapon, x, y, dir, damage);
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

class NpcState {
    public var posX:SyncVar;
    public var posY:SyncVar;
    public var rotation:SyncVar;

    public function new() {
        posX = new SyncVar(0);
        posY = new SyncVar(0);
        rotation = new SyncVar(0);
    }
}
