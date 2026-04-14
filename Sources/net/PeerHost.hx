package net;

import net.SupabaseTransport.PlayerInfo;

class PeerHost {

    var peerConnection:Dynamic;
    var dataChannel:Dynamic;
    var roomCode:String;
    var mapName:String;
    var hostName:String;
    public var onOpen:Void -> Void;
    public var onMessage:Dynamic -> Void;
    public var onClose:Void -> Void;
    var iceCandidates:Array<Dynamic>;
    var pollTimer:Dynamic;

    // Host authority state
    var players:Map<Int, PlayerInfo>;
    var nextGuestId:Int;
    var localId:Int;

    public function new() {
        iceCandidates = [];
        players = new Map();
        nextGuestId = 1;
        localId = 0;
    }

    public function getRoomCode():String {
        return roomCode;
    }

    public function getMapName():String {
        return mapName;
    }

    public function createRoom(hostPlayerName:String, map:String, onRoomCreated:String -> Void) {
        hostName = hostPlayerName;
        mapName = map;
        #if js
        RoomClient.createRoom(hostPlayerName, map, function(code:String) {
            roomCode = code;
            log("HOST", 'Room created: $code');

            // Register host player
            players.set(0, new PlayerInfo(hostPlayerName, 30, 100, 100));

            // Create peer connection
            peerConnection = untyped __js__("new RTCPeerConnection({iceServers: [{urls: 'stun:stun.l.google.com:19302'}, {urls: 'stun:stun1.l.google.com:19302'}]})");

            // Create data channel
            dataChannel = peerConnection.createDataChannel("game");
            setupDataChannel();

            // Gather ICE candidates
            peerConnection.onicecandidate = function(event:Dynamic) {
                if (untyped event.candidate != null) {
                    iceCandidates.push(untyped event.candidate.toJSON());
                }
            };

            // When ICE gathering is complete, post offer + candidates
            peerConnection.onicegatheringstatechange = function() {
                if (untyped peerConnection.iceGatheringState == "complete") {
                    postOfferAndPoll();
                }
            };

            // Create offer
            untyped peerConnection.createOffer().then(function(offer:Dynamic) {
                return peerConnection.setLocalDescription(offer);
            }).then(function(_:Dynamic) {
                // Wait for ICE gathering to complete (handled by onicegatheringstatechange)
            });

            onRoomCreated(code);
        });
        #end
    }

    function postOfferAndPoll() {
        #if js
        var offerData:Dynamic = untyped {
            hostOffer: peerConnection.localDescription.toJSON(),
            hostCandidates: iceCandidates
        };
        RoomClient.updateRoom(roomCode, offerData, function(room:Dynamic) {
            log("HOST", "Offer posted, polling for guest answer...");
            startPolling();
        });
        #end
    }

    function startPolling() {
        #if js
        pollTimer = untyped __js__("setInterval(() => {0}(), 1000)", pollForAnswer);
        #end
    }

    function pollForAnswer() {
        RoomClient.getRoom(roomCode, function(room:Dynamic) {
            if (room != null) {
                var guests:Array<Dynamic> = untyped room.guests;
                if (guests != null && guests.length > 0) {
                    var guest:Dynamic = guests[0];
                    if (untyped guest.answer != null) {
                        #if js
                        untyped __js__("clearInterval({0})", pollTimer);
                        #end
                        handleGuestAnswer(guest);
                    }
                }
            }
        });
    }

    function handleGuestAnswer(guest:Dynamic) {
        #if js
        log("HOST", "Guest answer received, connecting...");
        var answer:Dynamic = untyped __js__("new RTCSessionDescription({0})", guest.answer);
        untyped peerConnection.setRemoteDescription(answer).then(function(_:Dynamic) {
            var candidates:Array<Dynamic> = untyped guest.candidates;
            if (candidates != null) {
                for (c in candidates) {
                    untyped peerConnection.addIceCandidate(untyped __js__("new RTCIceCandidate({0})", c));
                }
            }
            log("HOST", "Remote description set, waiting for data channel...");
        });
        #end
    }

    function setupDataChannel() {
        #if js
        dataChannel.onopen = function() {
            log("HOST", "Data channel open! Guest connected.");
            if (onOpen != null) onOpen();
        };
        dataChannel.onmessage = function(event:Dynamic) {
            try {
                var msg = haxe.Json.parse(event.data);
                handleAsHost(msg);
            } catch (e:Dynamic) {
                log("HOST", "Parse error: " + Std.string(e));
            }
        };
        dataChannel.onclose = function() {
            log("HOST", "Data channel closed");
            if (onClose != null) onClose();
        };
        #end
    }

    // ========================
    // HOST AUTHORITY LOGIC
    // (Ported from SupabaseTransport)
    // ========================

    function handleAsHost(msg:Dynamic) {
        var msgType:String = Std.string(untyped msg.type);

        if (msgType == "join_request") {
            var guestId:Int = nextGuestId++;
            var guestName:String = Std.string(untyped msg.name);

            // Build player list BEFORE adding guest (so guest doesn't see itself as existing)
            var playerList:Dynamic = getPlayerListJS();

            // Now add guest to tracking
            players.set(guestId, new PlayerInfo(guestName, 200, 100, 100));

            // Send welcome to the guest (existing players only, not including self)
            sendToChannel(untyped __js__("{ type: 'welcome', id: {0}, map: {1}, hostId: 0, players: {2} }", guestId, mapName, playerList));

            log("HOST", "assigned id " + guestId + " to " + guestName);

            // Notify local (host) game about the new player
            if (onMessage != null) {
                onMessage(untyped __js__("{ type: 'player_joined', id: {0}, name: {1}, spawn: { x: 200, y: 100 } }", guestId, guestName));
            }
        } else if (msgType == "update") {
            // Relay state to guest (echo back) so guest sees host state
            sendToChannel(msg);
            // Notify local game
            if (onMessage != null) {
                onMessage(untyped __js__("{ type: 'state', from: {0}.from, vars: {0}.vars }", msg));
            }
            // Track guest position
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
            sendToChannel(msg);
            doHitDetection(msg);
            var shootFrom:Int = untyped msg.from;
            if (shootFrom != localId && onMessage != null) {
                onMessage(msg);
            }
        } else if (msgType == "npc_update") {
            sendToChannel(untyped __js__("{ type: 'npc_state', npcs: {0}.npcs }", msg));
        } else if (msgType == "chat") {
            sendToChannel(msg);
            if (onMessage != null) onMessage(msg);
        } else if (msgType == "set_name") {
            var nameFrom:Int = untyped msg.from;
            var p:PlayerInfo = players.get(nameFrom);
            if (p != null) p.name = Std.string(untyped msg.name);
            sendToChannel(untyped __js__("{ type: 'name_change', id: {0}, name: {1} }", nameFrom, untyped msg.name));
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

                sendToChannel(untyped __js__("{ type: 'hit', target: {0}, source: {1}, damage: {2}, health: {3}, dir: {4} }", id, shooterId, damage, target.health, dirVal));
                if (id == localId && onMessage != null) {
                    onMessage(untyped __js__("{ type: 'hit', target: {0}, source: {1}, damage: {2}, health: {3}, dir: {4} }", id, shooterId, damage, target.health, dirVal));
                }

                sendToChannel(untyped __js__("{ type: 'hit_confirm', target: {0}, damage: {1} }", id, damage));

                if (target.health <= 0) {
                    log("KILL", shooterId + " killed " + id);
                    sendToChannel(untyped __js__("{ type: 'kill', killed: {0}, killer: {1} }", id, shooterId));
                    if (onMessage != null) {
                        onMessage(untyped __js__("{ type: 'kill', killed: {0}, killer: {1} }", id, shooterId));
                    }

                    target.health = 100;
                    var spawnX:Float = 30 + (id % 4) * 50;
                    var spawnY:Float = 100.0;
                    target.x = spawnX;
                    target.y = spawnY;
                    sendToChannel(untyped __js__("{ type: 'spawn', id: {0}, x: {1}, y: {2}, health: 100 }", id, spawnX, spawnY));
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

    // ========================
    // SEND (host outgoing)
    // ========================

    // Send a message from the host's local game to the guest via data channel,
    // and also process it locally via the host authority logic.
    public function sendFromLocal(msg:Dynamic) {
        #if js
        var msgType:String = Std.string(untyped msg.type);

        if (msgType == "update") {
            untyped msg.from = localId;
            sendToChannel(msg);
            // Update local player position tracking
            var p:PlayerInfo = players.get(localId);
            if (p != null && untyped msg.vars != null) {
                var pxKey:String = localId + "|pos_x";
                var pyKey:String = localId + "|pos_y";
                var px:Dynamic = untyped msg.vars[pxKey];
                var py:Dynamic = untyped msg.vars[pyKey];
                if (px != null) p.x = untyped px[0];
                if (py != null) p.y = untyped py[0];
            }
        } else if (msgType == "shoot") {
            untyped msg.from = localId;
            sendToChannel(msg);
            doHitDetection(msg);
        } else if (msgType == "npc_update") {
            sendToChannel(untyped __js__("{ type: 'npc_state', npcs: {0}.npcs }", msg));
        } else if (msgType == "chat") {
            untyped msg.from = localId;
            var p:PlayerInfo = players.get(localId);
            if (p != null) {
                untyped msg.name = p.name;
            }
            sendToChannel(msg);
            if (onMessage != null) onMessage(msg);
        } else if (msgType == "set_name") {
            untyped msg.from = localId;
            var p:PlayerInfo = players.get(localId);
            if (p != null) p.name = Std.string(untyped msg.name);
            sendToChannel(untyped __js__("{ type: 'name_change', id: {0}, name: {1} }", localId, untyped msg.name));
        } else if (msgType == "ping") {
            // No-op for WebRTC
        }
        #end
    }

    // Low-level send to the data channel
    function sendToChannel(msg:Dynamic) {
        #if js
        if (dataChannel != null && untyped dataChannel.readyState == "open") {
            untyped dataChannel.send(haxe.Json.stringify(msg));
        }
        #end
    }

    public function send(msg:String) {
        #if js
        if (dataChannel != null && untyped dataChannel.readyState == "open") {
            untyped dataChannel.send(msg);
        }
        #end
    }

    public function close() {
        #if js
        if (pollTimer != null) untyped __js__("clearInterval({0})", pollTimer);
        if (dataChannel != null) untyped dataChannel.close();
        if (peerConnection != null) untyped peerConnection.close();
        #end
    }

    static function log(tag:String, msg:String) {
        #if js
        untyped __js__("console.log('[NET:' + {0} + '] ' + {1})", tag, msg);
        #end
    }
}
