package net;

#if js
import js.html.WebSocket;
import js.Browser;
import js.Lib;
#end
import haxe.Json;

typedef NetMessage = Dynamic;

class NetClient {

    var ws:Dynamic;
    var serverUrl:String;
    var connected:Bool;

    public var clientId:Int;
    public var onConnect:Int -> Void;
    public var onDisconnect:Void -> Void;
    public var onMessage:NetMessage -> Void;

    public function new() {
        connected = false;
        clientId = -1;
    }

    public function connect(url:String) {
        serverUrl = url;
        log("CONNECT", 'connecting to $url');

        #if js
        ws = untyped __js__("new WebSocket({0})", url);
        ws.onopen = function() {
            connected = true;
            log("CONNECT", 'websocket opened');
        };
        ws.onmessage = function(event) {
            try {
                var msg:Dynamic = Json.parse(event.data);
                handleMessage(msg);
            } catch (e:Dynamic) {
                log("ERROR", 'parse error: $e');
            }
        };
        ws.onclose = function() {
            connected = false;
            log("DISCONNECT", 'connection closed');
            if (onDisconnect != null) onDisconnect();
        };
        ws.onerror = function(e) {
            log("ERROR", 'websocket error');
        };
        #end
    }

    function handleMessage(msg:Dynamic) {
        switch (Std.string(msg.type)) {
            case "welcome":
                clientId = msg.id;
                log("JOIN", 'assigned id=$clientId map=${msg.map}');
                if (onConnect != null) onConnect(clientId);
                // Process existing players
                if (msg.players != null) {
                    var players:Array<Dynamic> = msg.players;
                    for (p in players) {
                        log("PLAYER_JOINED", 'id=${p.id} name=${p.name} (existing)');
                        if (onMessage != null) {
                            onMessage({type: "player_joined", id: p.id, name: p.name, spawn: {x: p.x, y: p.y}});
                        }
                    }
                }

            case "pong":
                var now:Float = js.lib.Date.now();
                var latency = (now - msg.time) / 2;
                log("LATENCY", 'ping=${Math.round(latency)}ms');

            default:
                // Forward everything else to game handler
                if (onMessage != null) onMessage(msg);
        }
    }

    public function send(msg:Dynamic) {
        if (!connected) return;
        #if js
        try {
            ws.send(Json.stringify(msg));
        } catch (e:Dynamic) {
            log("ERROR", 'send failed: $e');
        }
        #end
    }

    public function sendUpdate(vars:Dynamic) {
        send({ type: "update", vars: vars });
    }

    public function sendShoot(weapon:String, x:Float, y:Float, dir:Float, damage:Float) {
        send({ type: "shoot", weapon: weapon, x: x, y: y, dir: dir, damage: damage });
        log("SHOOT", 'weapon=$weapon x=$x y=$y dir=$dir');
    }

    public function sendPing() {
        send({ type: "ping", time: js.lib.Date.now() });
    }

    public function isConnected():Bool {
        return connected;
    }

    public function disconnect() {
        #if js
        if (ws != null) ws.close();
        #end
    }

    static function log(tag:String, msg:String) {
        #if js
        untyped __js__("console.log('[NET:' + {0} + '] ' + {1})", tag, msg);
        #end
    }
}
