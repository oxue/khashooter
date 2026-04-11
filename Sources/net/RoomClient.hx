package net;

class RoomClient {

    static var API_BASE:String = "https://www.oppyolly.com/api/rooms";

    // Create room, returns room code via callback
    public static function createRoom(hostName:String, map:String, callback:String -> Void) {
        #if js
        var body = haxe.Json.stringify({hostName: hostName, map: map});
        untyped __js__("fetch({0}, {method: 'POST', headers: {'Content-Type': 'application/json'}, body: {1}}).then(r => r.json()).then(data => {2}(data.code))", API_BASE, body, callback);
        #end
    }

    // Get room info
    public static function getRoom(code:String, callback:Dynamic -> Void) {
        #if js
        untyped __js__("fetch({0} + '/' + {1}).then(r => r.json()).then(data => {2}(data.room || null))", API_BASE, code, callback);
        #end
    }

    // Update room (post offer/answer/candidates or serverUrl)
    public static function updateRoom(code:String, data:Dynamic, callback:Dynamic -> Void) {
        #if js
        var body = haxe.Json.stringify(data);
        untyped __js__("fetch({0} + '/' + {1}, {method: 'POST', headers: {'Content-Type': 'application/json'}, body: {2}}).then(r => r.json()).then(d => {3}(d.room))", API_BASE, code, body, callback);
        #end
    }
}
