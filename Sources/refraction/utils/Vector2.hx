package utils;

import flash.Vector;

/**
 * ...
 * @author worldedit
 */
class Vector2<T> {
	public var data:Vector<T>;
	public var width:Int;
	public var height:Int;

	public function new(_width:Int, _height:Int, _defaultValue:Class<Dynamic> = null) {
		width = _width;
		height = _height;
		data = new Vector<T>(_width * _height);
		if (_defaultValue != null) {
			var i:Int = width * height;
			while (i-- > 0) {
				data[i] = Type.createInstance(_defaultValue, []);
			}
		}
	}

	public inline function get(i:Int, j:Int):T {
		return data[i * width + j];
	}

	public inline function set(i:Int, j:Int, _o:T):Void {
		data[i * width + j] = _o;
	}
}
