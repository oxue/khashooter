package helpers;

import haxe.ds.StringMap;

class DebugLogger {
	private static var tagLogs:StringMap<Array<Dynamic>> = new StringMap();
	private static var linearLogs:Array<Dynamic> = new Array();
	public static var traceLogs = true;

	public static var silencedLogs:Map<String, Bool> = ["ROUTINE" => true, "PERF" => true];

	public static function info(_tag:String, _message:Dynamic) {
		if (silencedLogs.exists(_tag) && !silencedLogs.get(_tag)) {
			return;
		}
		var logObject = {
			time: Date.now(),
			tag: _tag,
			message: _message
		}
		if (!tagLogs.exists(_tag)) {
			tagLogs.set(_tag, new Array<Dynamic>());
		}
		tagLogs
			.get(_tag)
			.push(logObject);
		linearLogs.push(logObject);

		if (traceLogs) {
			trace('[${logObject.tag}] ${logObject.message}');
		}
	}
}
