package hxblit;

import haxe.ds.Vector;
import kha.Color;
import kha.Image;
import kha.graphics2.Graphics;
import kha.math.Vector2;
import refraction.display.SurfaceSet;

/**
 * ...
 * @author worldedit qwerber
 */
class ARect {
	public var l:Int;
	public var t:Int;
	public var r:Int;
	public var b:Int;

	public function new(_l:Int, _t:Int, _r:Int, _b:Int) {
		l = _l;
		t = _t;
		r = _r;
		b = _b;
	}

	public inline function w():Int {
		return r - l;
	};

	public inline function h():Int {
		return b - t;
	};
}

class ANode {
	public var child:Vector<ANode>;
	public var rc:ARect;
	public var image:SurfaceData;

	public function new() {
		child = new Vector(2);
	}

	public function draw(g:Graphics, assets:Map<Int, Surface2>, size:Int = -1) {
		if (size == -1) {
			size = rc.w();
		}
		if (image != null) {
			g.drawImage(image.data, rc.l, rc.t);
			var v:Vector<Float> = new Vector<Float>(8);

			v[0] = rc.l / size;
			v[1] = rc.t / size;

			v[2] = ((rc.l + image.data.width) / size);
			v[3] = (rc.t / size);

			v[4] = (rc.l / size);
			v[5] = ((rc.t + image.data.height) / size);

			v[6] = ((rc.l + image.data.width) / size);
			v[7] = ((rc.t + image.data.height) / size);

			var s2:Surface2 = new Surface2();

			s2.vx1 = v[0];
			s2.vy1 = v[1];
			s2.vx2 = v[2];
			s2.vy2 = v[3];
			s2.vx3 = v[4];
			s2.vy3 = v[5];
			s2.vx4 = v[6];
			s2.vy4 = v[7];
			s2.width = image.data.width;
			s2.height = image.data.height;

			assets.set(image.id, s2);
		}
		if (child[0] != null)
			child[0].draw(g, assets, size);
		if (child[1] != null)
			child[1].draw(g, assets, size);
	}

	public function insert(img:SurfaceData):ANode {
		if (child.get(0) != null || child.get(1) != null) {
			var newNode:ANode = child[0].insert(img);
			if (newNode != null) {
				return newNode;
			}
			return child[1].insert(img);
		}
		if (image != null) {
			return null;
		}

		if (img.data.width > rc.w() || img.data.height > rc.h()) {
			return null;
		}
		if (img.data.width == rc.w() && img.data.height == rc.h()) {
			this.image = img;
			return this;
		}
		child[0] = new ANode();
		child[1] = new ANode();

		var dw:Int = rc.w() - img.data.width;
		var dh:Int = rc.h() - img.data.height;

		if (dw >= dh) {
			child[0].rc = new ARect(rc.l, rc.t, rc.l + img.data.width, rc.b);
			child[1].rc = new ARect(rc.l + img.data.width, rc.t, rc.r, rc.b);
		} else {
			child[0].rc = new ARect(rc.l, rc.t, rc.r, rc.t + img.data.height);
			child[1].rc = new ARect(rc.l, rc.t + img.data.height, rc.r, rc.b);
		}
		return child[0].insert(img);
	}
}

class IntBounds {
	public var t:Int;
	public var b:Int;
	public var l:Int;
	public var r:Int;

	public function new(_l:Int, _r:Int, _t:Int, _b:Int) {
		l = _l;
		r = _r;
		t = _t;
		b = _b;
	}
}

class IntRect {
	public var x:Int;
	public var y:Int;
	public var w:Int;
	public var h:Int;

	public function new(_x:Int, _y:Int, _w:Int, _h:Int) {
		x = _x;
		y = _y;
		w = _w;
		h = _h;
	}

	public function position():Vector2 {
		return new Vector2(x, y);
	}
}

class FloatRect {
	public var x:Float;
	public var y:Float;
	public var w:Float;
	public var h:Float;

	public function new(_x:Float, _y:Float, _w:Float, _h:Float) {
		x = _x;
		y = _y;
		w = _w;
		h = _h;
	}

	public function clone():FloatRect {
		return new FloatRect(x, y, w, h);
	}

	public function union(r:FloatRect):FloatRect {
		var nx:Float = Math.min(x, r.x);
		var ny:Float = Math.min(y, r.y);
		return new FloatRect(nx, ny, Math.max(x + w, r.x + r.w) - nx, Math.max(y + h, r.y + r.h) - ny);
	}

	public function bottom():Float {
		return y + h;
	}

	public function right():Float {
		return x + w;
	}

	public function top():Float {
		return y;
	}

	public function left():Float {
		return x;
	}
}

class TextureAtlas {
	public var images:Array<SurfaceData>;
	public var image:Image;
	public var assets:Map<Int, Surface2>;

	public function new() {
		images = new Array<SurfaceData>();
		assets = new Map<Int, Surface2>();
	}

	public function add(_image:Image, _id:Int):Void {
		images.push(new SurfaceData(_image, _id));
	}

	private inline function sortOnSize(x:SurfaceData, y:SurfaceData):Int {
		if (x.data.width * x.data.height < y.data.width * y.data.height)
			return -1;
		else
			return 1;
	}

	public static function bake(_data:Image, _rot:Int = 32):Image {
		var diagnol:Int = Math.ceil(Math.sqrt(_data.width * _data.width + _data.height * _data.height));
		var cache:Image = Image.createRenderTarget(diagnol * _rot, diagnol);
		cache.g2.begin(true, Color.fromFloats(0, 0, 0, 0));
		var i:Int = -1;
		var translateX:Float = (diagnol - _data.width) * 0.5;
		var translateY:Float = (diagnol - _data.height) * 0.5;
		var px:Float = 0;
		var py:Float = translateY;
		while (i++ < _rot - 1) {
			px = diagnol * i + translateX;
			cache.g2.pushRotation(Math.PI * 2 * i / _rot, _data.width / 2, _data.height / 2);
			cache.g2.pushTranslation(px, py);
			cache.g2.drawImage(_data, 0, 0);
			cache.g2.popTransformation();
			cache.g2.popTransformation();
		}
		cache.g2.end();
		return cache;
	}

	public static function bakeForAnimation(_data:Image, _frame:IntRect, _rot:Int = 32):Image {
		var gWidth:Int = cast _data.width / _frame.w;
		var gHeight:Int = cast _data.height / _frame.h;
		var diagnol:Int = Math.ceil(Math.sqrt(_frame.w * _frame.w + _frame.h * _frame.h));
		var ret:Image = Image.createRenderTarget(diagnol * _rot, gWidth * gHeight * diagnol);
		var brush:Image = Image.createRenderTarget(_frame.w, _frame.h);
		var i:Int = -1;
		while (i++ < gHeight - 1) {
			var j:Int = -1;
			while (j++ < gWidth - 1) {
				brush.g2.begin(true, Color.fromFloats(0, 0, 0, 0));
				brush.g2.drawSubImage(_data, 0, 0, _frame.x, _frame.y, _frame.w, _frame.h);
				brush.g2.end();
				var subret = bake(brush, _rot);
				ret.g2.begin(false);
				ret.g2.drawImage(subret, 0, diagnol * (i * gWidth + j));
				ret.g2.end();
				_frame.x += _frame.w;
			}
			_frame.y += _frame.h;
			_frame.x = 0;
		}
		return ret;
	}

	public function splitAndIndex(_img:Image, _frame:FloatRect):SurfaceSet {
		var startInd = images.length;
		var ret:SurfaceSet = new SurfaceSet();
		ret.frame = _frame;
		var gw:Int = cast _img.width / _frame.w;
		var gh:Int = cast _img.height / _frame.h;
		var i:Int = -1;
		ret.indexes = new Array<Int>();
		ret.surfaces = new Array<Surface2>();
		while (i++ < gh - 1) {
			var j:Int = -1;
			while (j++ < gw - 1) {
				var b:Image = Image.createRenderTarget(cast _frame.w, cast _frame.h);
				_frame.x = j * _frame.w;
				_frame.y = i * _frame.h;
				b.g2.begin(true, Color.fromFloats(0, 0, 0, 0));
				b.g2.drawSubImage(_img, 0, 0, _frame.x, _frame.y, _frame.w, _frame.h);
				b.g2.end();
				add(b, startInd + i * gw + j);
				ret.indexes.push(startInd + i * gw + j);
				ret.surfaces.push(null);
			}
		}
		return ret;
	}

	public function binpack() {
		images.sort(sortOnSize);

		var size:Int = 32;
		var root:ANode = null;
		var packed:Bool = false;
		while (!packed) {
			root = new ANode();
			root.rc = new ARect(0, 0, size, size);
			packed = true;
			var i:Int = images.length;
			while (i-- > 0) {
				var res = root.insert(images[i]);
				if (res == null) {
					size *= 2;
					packed = false;
					break;
				}
			}
		}
		image = Image.createRenderTarget(size, size);
		image.g2.begin(true, Color.fromFloats(0, 0, 0, 0));

		if (root != null) {
			root.draw(image.g2, assets);
		}

		image.g2.end();
	}
}
