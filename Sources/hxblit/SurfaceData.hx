package hxblit;

import kha.Image;

class SurfaceData {

	public var data:Image;
	public var id:Int;

	public function new(_data:Image, _id:Int) {
		data = _data;
		id = _id;
	}
}
