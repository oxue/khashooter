package net;

class SupabaseTransport {

    var channel:Dynamic;
    var client:Dynamic;
    var roomCode:String;
    var localId:Int;
    var isHost:Bool;
    var players:Map<Int, PlayerInfo>;
    var nextGuestId:Int;

    public var onMessage:Dynamic -> Void;
    public var onConnect:Void -> Void;
    public var onDisconnect:Void -> Void;

    public function new() {
        localId = -1;
        isHost = false;
        players = new Map();
        nextGuestId = 1;
    }

    public function createRoom(code:String, playerName:String) {
        this.roomCode = code;
        this.isHost = true;
        this.localId = 0;

        initSupabase();
        joinChannel(playerName);
    }

    public function joinRoom(code:String, playerName:String) {
        this.roomCode = code;
        this.isHost = false;

        initSupabase();
        joinChannel(playerName);
    }

    function initSupabase() {
        #if js
        var url:String = "https://etfkdcsoazbxiqzsjkrh.supabase.co";
        var key:String = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImV0ZmtkY3NvYXpieGlxenNqa3JoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzE1NzA1ODUsImV4cCI6MjA4NzE0NjU4NX0.CJCUm5r9eFc8yRzxRM1gco439hRK40bqmO67eBSyI9M";
        client = untyped __js__("window.supabase.createClient({0}, {1})", url, key);
        #end
    }

    function joinChannel(playerName:String) {
        #if js
        var channelName:String = "game:" + roomCode;
        var broadcastConfig:Dynamic = untyped __js__("{ broadcast: { self: false } }");
        channel = untyped client.channel(channelName, untyped __js__("{ config: {0} }", broadcastConfig));

        var self = this;
        var filterObj:Dynamic = untyped __js__("{ event: 'game' }");
        var onBroadcast = function(payload:Dynamic) {
            self.handleIncoming(payload.payload);
        };
        channel.on("broadcast", filterObj, onBroadcast);

        var onSubscribe = function(status:Dynamic) {
            var s:String = Std.string(status);
            if (s == "SUBSCRIBED") {
                log("CONNECT", "joined channel " + channelName);
                if (self.isHost) {
                    self.sendWelcomeToSelf(playerName);
                } else {
                    self.broadcast(untyped __js__("{ type: 'join_request', name: {0} }", playerName));
                }
            }
        };
        channel.subscribe(onSubscribe);
        #end
    }

    function sendWelcomeToSelf(name:String) {
        players.set(0, new PlayerInfo(name, 30, 100, 100));
        if (onMessage != null) {
            onMessage(untyped __js__("{ type: 'welcome', id: 0, map: 'level2', hostId: 0, players: [] }"));
        }
        if (onConnect != null) onConnect();
    }

    function handleIncoming(msg:Dynamic) {
        if (isHost) {
            handleAsHost(msg);
        } else {
            handleAsGuest(msg);
        }
    }

    function handleAsHost(msg:Dynamic) {
        var msgType:String = Std.string(untyped msg.type);

        if (msgType == "join_request") {
            var guestId:Int = nextGuestId++;
            var guestName:String = Std.string(untyped msg.name);
            players.set(guestId, new PlayerInfo(guestName, 200, 100, 100));

            var playerList:Dynamic = getPlayerListJS();
            broadcast(untyped __js__("{ type: 'welcome_guest', id: {0}, map: 'level2', hostId: 0, players: {1} }", guestId, playerList));
            broadcast(untyped __js__("{ type: 'player_joined', id: {0}, name: {1}, spawn: { x: 200, y: 100 } }", guestId, guestName));

            log("HOST", "assigned id " + guestId + " to " + guestName);

            if (onMessage != null) {
                onMessage(untyped __js__("{ type: 'player_joined', id: {0}, name: {1}, spawn: { x: 200, y: 100 } }", guestId, guestName));
            }
        } else if (msgType == "update") {
            broadcast(msg);
            if (onMessage != null) {
                onMessage(untyped __js__("{ type: 'state', from: {0}.from, vars: {0}.vars }", msg));
            }
            var fromId:Int = untyped msg.from;
            var p:PlayerInfo = players.get(fromId);
            if (p != null && untyped msg.vars != null) {
                var pxKey:String = fromId + "|pos_x";
                var pyKey:String = fromId + "|pos_y";
                var px:Dynamic = untyped msg.vars[pxKey];
                var py:Dynamic = untyped msg.vars[pyKey];
                if (px != null) p.x = untyped px[0];
                if (py != null) p.y = untyped py[0];
            }
        } else if (msgType == "shoot") {
            broadcast(msg);
            doHitDetection(msg);
            var shootFrom:Int = untyped msg.from;
            if (shootFrom != localId && onMessage != null) {
                onMessage(msg);
            }
        } else if (msgType == "npc_update") {
            // Host relays NPC state from itself - this shouldn't happen via broadcast
            // but if it does, relay it
            broadcast(untyped __js__("{ type: 'npc_state', npcs: {0}.npcs }", msg));
        } else if (msgType == "chat") {
            broadcast(msg);
            if (onMessage != null) onMessage(msg);
        } else if (msgType == "set_name") {
            var nameFrom:Int = untyped msg.from;
            var p:PlayerInfo = players.get(nameFrom);
            if (p != null) p.name = Std.string(untyped msg.name);
            broadcast(untyped __js__("{ type: 'name_change', id: {0}, name: {1} }", nameFrom, untyped msg.name));
        }
    }

    function handleAsGuest(msg:Dynamic) {
        var msgType:String = Std.string(untyped msg.type);

        if (msgType == "welcome_guest") {
            var assignedId:Dynamic = untyped msg.id;
            if (assignedId != null) {
                localId = untyped __js__("parseInt({0})", assignedId);
                log("JOIN", "assigned id=" + localId);
                if (onMessage != null) {
                    onMessage(untyped __js__("{ type: 'welcome', id: {0}, map: {1}.map, hostId: {1}.hostId, players: {1}.players }", localId, msg));
                }
                if (onConnect != null) onConnect();
            }
        } else if (msgType == "state" || msgType == "update") {
            var stateFrom:Int = untyped msg.from;
            if (stateFrom != localId && onMessage != null) {
                if (msgType == "update") {
                    onMessage(untyped __js__("{ type: 'state', from: {0}.from, vars: {0}.vars }", msg));
                } else {
                    onMessage(msg);
                }
            }
        } else if (msgType == "player_joined") {
            var joinId:Int = untyped msg.id;
            if (joinId != localId && onMessage != null) onMessage(msg);
        } else if (msgType == "shoot") {
            var shootFrom:Int = untyped msg.from;
            if (shootFrom != localId && onMessage != null) onMessage(msg);
        } else if (msgType == "npc_state") {
            if (onMessage != null) onMessage(msg);
        } else if (msgType == "player_left" || msgType == "hit" || msgType == "hit_confirm"
            || msgType == "kill" || msgType == "spawn" || msgType == "chat"
            || msgType == "host_change" || msgType == "name_change") {
            if (onMessage != null) onMessage(msg);
        }
    }

    function doHitDetection(msg:Dynamic) {
        var weapon:String = Std.string(untyped msg.weapon);
        var isFlamethrower:Bool = weapon == "flamethrower";
        var HIT_RADIUS:Float = isFlamethrower ? 30 : 15;
        var MAX_RANGE:Float = isFlamethrower ? 100 : 300;

        var dirVal:Float = untyped msg.dir;
        var dirRad:Float = dirVal * (Math.PI / 180.0);
        var rayDx:Float = Math.cos(dirRad);
        var rayDy:Float = Math.sin(dirRad);
        var shooterId:Int = untyped msg.from;
        var shootX:Float = untyped msg.x;
        var shootY:Float = untyped msg.y;

        for (id => target in players) {
            if (id == shooterId) continue;

            var toX:Float = target.x - shootX;
            var toY:Float = target.y - shootY;
            var alongRay:Float = toX * rayDx + toY * rayDy;

            if (alongRay < 0 || alongRay > MAX_RANGE) continue;

            var perpDist:Float = Math.abs(toX * rayDy - toY * rayDx);

            if (perpDist < HIT_RADIUS) {
                var damage:Float = untyped msg.damage;
                if (damage == null || untyped __js__("isNaN({0})", damage)) damage = 10;
                target.health -= damage;

                log("HIT", shooterId + " -> " + id + " perpDist=" + Std.string(perpDist));

                broadcast(untyped __js__("{ type: 'hit', target: {0}, source: {1}, damage: {2}, health: {3}, dir: {4} }", id, shooterId, damage, target.health, dirVal));
                if (id == localId && onMessage != null) {
                    onMessage(untyped __js__("{ type: 'hit', target: {0}, source: {1}, damage: {2}, health: {3}, dir: {4} }", id, shooterId, damage, target.health, dirVal));
                }

                broadcast(untyped __js__("{ type: 'hit_confirm', target: {0}, damage: {1} }", id, damage));

                if (target.health <= 0) {
                    log("KILL", shooterId + " killed " + id);
                    broadcast(untyped __js__("{ type: 'kill', killed: {0}, killer: {1} }", id, shooterId));
                    if (onMessage != null) {
                        onMessage(untyped __js__("{ type: 'kill', killed: {0}, killer: {1} }", id, shooterId));
                    }

                    target.health = 100;
                    var spawnX:Float = 30 + (id % 4) * 50;
                    var spawnY:Float = 100.0;
                    target.x = spawnX;
                    target.y = spawnY;
                    broadcast(untyped __js__("{ type: 'spawn', id: {0}, x: {1}, y: {2}, health: 100 }", id, spawnX, spawnY));
                    if (id == localId && onMessage != null) {
                        onMessage(untyped __js__("{ type: 'spawn', id: {0}, x: {1}, y: {2}, health: 100 }", id, spawnX, spawnY));
                    }
                }
            }
        }
    }

    function getPlayerListJS():Dynamic {
        #if js
        var list:Dynamic = untyped __js__("[]");
        for (id => p in players) {
            untyped __js__("{0}.push({ id: {1}, name: {2}, x: {3}, y: {4}, health: {5} })", list, id, p.name, p.x, p.y, p.health);
        }
        return list;
        #else
        return null;
        #end
    }

    public function broadcast(msg:Dynamic) {
        #if js
        if (channel != null) {
            untyped channel.send(untyped __js__("{ type: 'broadcast', event: 'game', payload: {0} }", msg));
        }
        #end
    }

    public function send(msg:Dynamic) {
        #if js
        var msgType:String = Std.string(untyped msg.type);

        if (msgType == "update") {
            untyped msg.from = localId;
            broadcast(msg);
            // Host also processes own updates locally for relay
            if (isHost) {
                // Update local player position in host tracking
                var p:PlayerInfo = players.get(localId);
                if (p != null && untyped msg.vars != null) {
                    var pxKey:String = localId + "|pos_x";
                    var pyKey:String = localId + "|pos_y";
                    var px:Dynamic = untyped msg.vars[pxKey];
                    var py:Dynamic = untyped msg.vars[pyKey];
                    if (px != null) p.x = untyped px[0];
                    if (py != null) p.y = untyped py[0];
                }
            }
        } else if (msgType == "shoot") {
            untyped msg.from = localId;
            broadcast(msg);
            if (isHost) {
                doHitDetection(msg);
            }
        } else if (msgType == "npc_update") {
            // Host sends NPC state - relay to all others
            if (isHost) {
                broadcast(untyped __js__("{ type: 'npc_state', npcs: {0}.npcs }", msg));
            }
        } else if (msgType == "chat") {
            untyped msg.from = localId;
            var p:PlayerInfo = players.get(localId);
            if (p != null) {
                untyped msg.name = p.name;
            }
            broadcast(msg);
            if (onMessage != null) onMessage(msg);
        } else if (msgType == "set_name") {
            untyped msg.from = localId;
            if (isHost) {
                var p:PlayerInfo = players.get(localId);
                if (p != null) p.name = Std.string(untyped msg.name);
                broadcast(untyped __js__("{ type: 'name_change', id: {0}, name: {1} }", localId, untyped msg.name));
            } else {
                broadcast(msg);
            }
        } else if (msgType == "ping") {
            // No-op for Supabase
        }
        #end
    }

    public function isConnected():Bool {
        return localId >= 0;
    }

    public function getLocalId():Int {
        return localId;
    }

    public function getIsHost():Bool {
        return isHost;
    }

    public function disconnect() {
        #if js
        if (channel != null) {
            broadcast(untyped __js__("{ type: 'player_left', id: {0} }", localId));
            untyped channel.unsubscribe();
        }
        #end
    }

    static function log(tag:String, msg:String) {
        #if js
        untyped __js__("console.log('[NET:' + {0} + '] ' + {1})", tag, msg);
        #end
    }
}

class PlayerInfo {
    public var name:String;
    public var x:Float;
    public var y:Float;
    public var health:Float;

    public function new(name:String, x:Float, y:Float, health:Float) {
        this.name = name;
        this.x = x;
        this.y = y;
        this.health = health;
    }
}
