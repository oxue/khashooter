package net;

class PeerGuest {

    var peerConnection:Dynamic;
    var dataChannel:Dynamic;
    var roomCode:String;
    var guestName:String;
    public var onOpen:Void -> Void;
    public var onClose:Void -> Void;
    var iceCandidates:Array<Dynamic>;

    // Message callback with buffering for early messages
    var _onMessage:Dynamic -> Void;
    var messageBuffer:Array<Dynamic>;

    public var onMessage(get, set):Dynamic -> Void;

    function get_onMessage():Dynamic -> Void {
        return _onMessage;
    }

    function set_onMessage(cb:Dynamic -> Void):Dynamic -> Void {
        _onMessage = cb;
        // Flush any buffered messages
        if (cb != null && messageBuffer.length > 0) {
            log("GUEST", "Flushing " + messageBuffer.length + " buffered messages");
            var buf = messageBuffer.copy();
            messageBuffer = [];
            for (msg in buf) {
                cb(msg);
            }
        }
        return cb;
    }

    public function new() {
        iceCandidates = [];
        messageBuffer = [];
        _onMessage = null;
    }

    public function joinRoom(code:String, name:String, onError:String -> Void) {
        roomCode = code;
        guestName = name;

        RoomClient.getRoom(code, function(room:Dynamic) {
            if (room == null) {
                if (onError != null) onError("Room not found");
                return;
            }
            if (untyped room.hostOffer == null) {
                if (onError != null) onError("Host not ready yet");
                return;
            }

            log("GUEST", "Room found, connecting to host...");
            connectToHost(room);
        });
    }

    function connectToHost(room:Dynamic) {
        #if js
        peerConnection = untyped __js__("new RTCPeerConnection({iceServers: [{urls: 'stun:stun.l.google.com:19302'}, {urls: 'stun:stun1.l.google.com:19302'}]})");

        // Listen for data channel from host
        peerConnection.ondatachannel = function(event:Dynamic) {
            dataChannel = untyped event.channel;
            setupDataChannel();
        };

        // Gather ICE candidates
        peerConnection.onicecandidate = function(event:Dynamic) {
            if (untyped event.candidate != null) {
                iceCandidates.push(untyped event.candidate.toJSON());
            }
        };

        peerConnection.onicegatheringstatechange = function() {
            if (untyped peerConnection.iceGatheringState == "complete") {
                postAnswer();
            }
        };

        // Set remote description (host's offer)
        var offer:Dynamic = untyped __js__("new RTCSessionDescription({0})", room.hostOffer);
        untyped peerConnection.setRemoteDescription(offer).then(function(_:Dynamic) {
            // Add host ICE candidates
            var candidates:Array<Dynamic> = untyped room.hostCandidates;
            if (candidates != null) {
                for (c in candidates) {
                    untyped peerConnection.addIceCandidate(untyped __js__("new RTCIceCandidate({0})", c));
                }
            }
            // Create answer
            return peerConnection.createAnswer();
        }).then(function(answer:Dynamic) {
            return peerConnection.setLocalDescription(answer);
        }).then(function(_:Dynamic) {
            // Wait for ICE gathering (handled by onicegatheringstatechange)
        });
        #end
    }

    function postAnswer() {
        #if js
        var answerData:Dynamic = untyped {
            guestName: guestName,
            guestAnswer: peerConnection.localDescription.toJSON(),
            guestCandidates: iceCandidates
        };
        RoomClient.updateRoom(roomCode, answerData, function(room:Dynamic) {
            log("GUEST", "Answer posted, waiting for data channel...");
        });
        #end
    }

    function dispatchMessage(msg:Dynamic) {
        if (_onMessage != null) {
            _onMessage(msg);
        } else {
            // Buffer the message until onMessage callback is set
            messageBuffer.push(msg);
            log("GUEST", "Buffered message of type: " + Std.string(untyped msg.type));
        }
    }

    function setupDataChannel() {
        #if js
        dataChannel.onopen = function() {
            log("GUEST", "Data channel open!");
            // Send join request to host
            sendToChannel(untyped __js__("{ type: 'join_request', name: {0} }", guestName));

            if (onOpen != null) onOpen();
        };
        dataChannel.onmessage = function(event:Dynamic) {
            try {
                var msg = haxe.Json.parse(event.data);
                dispatchMessage(msg);
            } catch (e:Dynamic) {
                log("GUEST", "Parse error: " + Std.string(e));
            }
        };
        dataChannel.onclose = function() {
            log("GUEST", "Data channel closed");
            if (onClose != null) onClose();
        };
        #end
    }

    // Send a game message to the host (as JSON)
    public function sendToChannel(msg:Dynamic) {
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
