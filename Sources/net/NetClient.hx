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

    public var useWebRTC:Bool;
    var rtcSend:String -> Void;

    public var supabaseTransport:SupabaseTransport;
    public var peerHost:PeerHost;
    public var peerGuest:PeerGuest;

    public var clientId:Int;
    public var onConnect:Int -> Void;
    public var onDisconnect:Void -> Void;
    public var onMessage:NetMessage -> Void;

    public function new() {
        connected = false;
        useWebRTC = false;
        rtcSend = null;
        supabaseTransport = null;
        peerHost = null;
        peerGuest = null;
        clientId = -1;
    }

    public function attachDataChannel(sendFn:String -> Void) {
        useWebRTC = true;
        rtcSend = sendFn;
        connected = true;
    }

    public function onDataChannelMessage(data:String) {
        try {
            var msg = Json.parse(data);
            handleMessage(msg);
        } catch (e:Dynamic) {
            log("ERROR", 'parse error: $e');
        }
    }

    public function connectViaPeerHost(host:PeerHost) {
        peerHost = host;

        host.onMessage = function(msg:Dynamic) {
            handleMessage(msg);
        };

        // The host is immediately "connected" as player 0.
        // Send a synthetic welcome message so handleMessage processes it
        // (sets clientId, calls onConnect, etc.) -- same as SupabaseTransport.sendWelcomeToSelf.
        var mapName:String = host.getMapName();
        handleMessage({type: "welcome", id: 0, map: mapName, hostId: 0, players: []});

        log("CONNECT", "connected via PeerHost as host, id=0");
    }

    public function connectViaPeerGuest(guest:PeerGuest) {
        peerGuest = guest;

        guest.onMessage = function(msg:Dynamic) {
            handleMessage(msg);
        };

        // Guest is not fully connected until it receives a "welcome" message from host
        log("CONNECT", "waiting for welcome from host via PeerGuest...");
    }

    public function connectViaSupabase(transport:SupabaseTransport) {
        supabaseTransport = transport;

        transport.onMessage = function(msg:Dynamic) {
            handleMessage(msg);
        };

        transport.onConnect = function() {
            connected = true;
            clientId = transport.getLocalId();
            log("CONNECT", "connected via Supabase, id=" + clientId);
        };
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
                connected = true;
                log("JOIN", 'assigned id=$clientId map=${msg.map} host=${msg.hostId}');
                // Forward host_change before onConnect so hostId is set
                if (onMessage != null) {
                    onMessage({type: "host_change", hostId: msg.hostId});
                }
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
        if (!connected && supabaseTransport == null && peerHost == null && peerGuest == null) return;
        #if js
        if (peerHost != null) {
            // Host: process message through host authority logic
            peerHost.sendFromLocal(msg);
        } else if (peerGuest != null) {
            // Guest: tag with our ID and send to host via data channel
            var msgType:String = Std.string(untyped msg.type);
            if (msgType == "update" || msgType == "shoot" || msgType == "chat" || msgType == "set_name") {
                untyped msg.from = clientId;
            }
            peerGuest.sendToChannel(msg);
        } else if (supabaseTransport != null) {
            supabaseTransport.send(msg);
        } else {
            var str = Json.stringify(msg);
            if (useWebRTC && rtcSend != null) {
                rtcSend(str);
            } else {
                try {
                    ws.send(str);
                } catch (e:Dynamic) {
                    log("ERROR", 'send failed: $e');
                }
            }
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
        if (supabaseTransport != null) return supabaseTransport.isConnected();
        if (peerHost != null) return connected;
        if (peerGuest != null) return connected;
        return connected;
    }

    public function disconnect() {
        #if js
        if (peerHost != null) peerHost.close();
        if (peerGuest != null) peerGuest.close();
        if (ws != null) ws.close();
        #end
    }

    static function log(tag:String, msg:String) {
        #if js
        untyped __js__("console.log('[NET:' + {0} + '] ' + {1})", tag, msg);
        #end
    }
}
