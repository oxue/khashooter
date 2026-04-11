package net;

class PeerGuest {

    var peerConnection:Dynamic;
    var dataChannel:Dynamic;
    var roomCode:String;
    var guestName:String;
    public var onOpen:Void -> Void;
    public var onMessage:String -> Void;
    public var onClose:Void -> Void;
    var iceCandidates:Array<Dynamic>;

    public function new() {
        iceCandidates = [];
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
        peerConnection = untyped __js__("new RTCPeerConnection({iceServers: [{urls: 'stun:stun.l.google.com:19302'}]})");

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

    function setupDataChannel() {
        #if js
        dataChannel.onopen = function() {
            log("GUEST", "Data channel open!");
            if (onOpen != null) onOpen();
        };
        dataChannel.onmessage = function(event:Dynamic) {
            if (onMessage != null) onMessage(untyped event.data);
        };
        dataChannel.onclose = function() {
            if (onClose != null) onClose();
        };
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
