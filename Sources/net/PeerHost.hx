package net;

class PeerHost {

    var peerConnection:Dynamic; // RTCPeerConnection
    var dataChannel:Dynamic; // RTCDataChannel
    var roomCode:String;
    public var onOpen:Void -> Void;
    public var onMessage:String -> Void;
    public var onClose:Void -> Void;
    var iceCandidates:Array<Dynamic>;
    var pollTimer:Dynamic;

    public function new() {
        iceCandidates = [];
    }

    public function createRoom(hostName:String, map:String, onRoomCreated:String -> Void) {
        #if js
        // Create room via API
        RoomClient.createRoom(hostName, map, function(code:String) {
            roomCode = code;
            log("HOST", 'Room created: $code');

            // Create peer connection
            peerConnection = untyped __js__("new RTCPeerConnection({iceServers: [{urls: 'stun:stun.l.google.com:19302'}]})");

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
        // Post offer to room API
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
            // Add guest ICE candidates
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
            log("HOST", "Data channel open!");
            if (onOpen != null) onOpen();
        };
        dataChannel.onmessage = function(event:Dynamic) {
            if (onMessage != null) onMessage(untyped event.data);
        };
        dataChannel.onclose = function() {
            log("HOST", "Data channel closed");
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
