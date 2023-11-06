package refraction.tilemap;

import hxblit.TextureAtlas.FloatRect;
import hxblit.TextureAtlas.IntBounds;
import refraction.core.Sys;
import refraction.generic.DimensionsCmp;

class TileCollisionSys extends Sys<TileCollisionCmp> {
	var tilemapData:Tilemap;
	var pool:Array<TileCollisionCmp>;

	public function new() {
		pool = [];
		super();
	}

	override public function produce():TileCollisionCmp {
		if (pool.length != 0) {
			return pool.pop();
		}
		return null;
	}

	public function setTilemap(_tilemapData:Tilemap) {
		tilemapData = _tilemapData;
	}

	override public function update() {
		var i = 0;
		while (i < components.length) {
			var tc = components[i];
			if (tc.remove) {
				removeIndex(i, pool);
				continue;
			}
			collide(tc);
			++i;
		}
	}

	function maxi(a:Int, b:Int):Int {
		return (a < b) ? b : a;
	}

	function mini(a:Int, b:Int):Int {
		return (a > b) ? b : a;
	}

	function clamp(a:Int, low:Int, high:Int):Int {
		return maxi(mini(a, high), low);
	}

	function getCollisionBounds(_bound:FloatRect):IntBounds {
		var bottom = Math.floor(
			_bound.bottom() / tilemapData.tilesize
		) + 1;
		var top = Math.floor(
			_bound.top() / tilemapData.tilesize
		) - 1;
		var right = Math.floor(
			_bound.right() / tilemapData.tilesize
		) + 1;
		var left = Math.floor(
			_bound.left() / tilemapData.tilesize
		) - 1;

		top = clamp(top, 0, tilemapData.height - 1);
		left = clamp(left, 0, tilemapData.width - 1);
		bottom = clamp(bottom, 0, tilemapData.height - 1);
		right = clamp(right, 0, tilemapData.width - 1);

		return new IntBounds(left, right, top, bottom);
	}

	function sweptRect(tc:TileCollisionCmp):FloatRect {
		var previousX = tc.position.x - tc.velocity.getVelX();
		var previousY = tc.position.y - tc.velocity.getVelY();

		var hx = tc.hitboxPosition.x;
		var hy = tc.hitboxPosition.y;

		var lastRect = new FloatRect(
			previousX + hx,
			previousY + hy,
			tc.dimensions.width,
			tc.dimensions.height
		);
		var nowRect = new FloatRect(
			tc.position.x + hx,
			tc.position.y + hy,
			tc.dimensions.width,
			tc.dimensions.height
		);
		return lastRect.union(nowRect);
	}

	function pushBack(tc:TileCollisionCmp, data:CollisionData) {
		var xFlag:Int = 1 - data.nature;
		var yFlag:Int = data.nature;

		var pushbackX:Float = -tc.velocity.getVelX() * (1 - data.time);
		var pushbackY:Float = -tc.velocity.getVelY() * (1 - data.time);

		// pushback
		tc.position.x += pushbackX * xFlag;
		tc.position.y += pushbackY * yFlag;

		tc.velocity.setVelX(-pushbackX * yFlag);
		tc.velocity.setVelY(-pushbackY * xFlag);
	}

	function getCollisionsInBound(tc:TileCollisionCmp, bounds:IntBounds):Array<CollisionData> {
		var datas = new Array<CollisionData>();
		var i = bounds.t;
		while (i <= bounds.b) {
			var j = bounds.l;
			while (j <= bounds.r) {
				if (tilemapData.data[i][j].solid) {
					var cdata = solveRect(
						tc,
						j * tilemapData.tilesize,
						i * tilemapData.tilesize,
						tilemapData.tilesize,
						tilemapData.tilesize
					);
					if (cdata.collided) {
						datas.push(cdata);
					}
				}
				j++;
			}
			i++;
		}
		return datas;
	}

	public function collideOneAxis(tc:TileCollisionCmp) {
		var datas:Array<CollisionData> = getCollisionsInBound(
			tc,
			getCollisionBounds(sweptRect(tc))
		);

		if (datas.length <= 0) {
			return;
		}

		// get data by min time:
		var minTimeData:CollisionData = datas[0];
		for (data in datas) {
			if (data.time < minTimeData.time) {
				minTimeData = data;
			}
		}

		pushBack(tc, minTimeData);
	}

	function collide(tc:TileCollisionCmp) {
		collideOneAxis(tc);
		collideOneAxis(tc);
	}

	// WARNING DELICATE FLOATING POINT MATH
	public function solveRect(_tc:TileCollisionCmp, _tx:Int, _ty:Int, _tw:Int, _th:Int):CollisionData {
		var position = _tc.position
			.vec()
			.add(_tc.hitboxPosition);
		var previous = _tc.position
			.vec()
			.sub(_tc.velocity.vec())
			.add(_tc.hitboxPosition);
		var dimensions:DimensionsCmp = _tc.dimensions;
		var velX = position.x - previous.x;
		var velY = position.y - previous.y;
		var dtxc = 0.0;
		var dtyc = 0.0;
		var dtxd = 0.0;
		var dtyd = 0.0;

		if (_tc.velocity.getVelX() < 0) {
			dtxc = _tx + _tw - previous.x;
			dtxd = _tx - previous.x - dimensions.width;
		} else {
			dtxc = _tx - previous.x - dimensions.width;
			dtxd = _tx + _tw - previous.x;
		}
		if (velY < 0) {
			dtyc = _ty + _th - previous.y;
			dtyd = _ty - previous.y - dimensions.height;
		} else {
			dtyc = _ty - previous.y - dimensions.height;
			dtyd = _ty + _th - previous.y;
		}
		var timeX:Float = dtxc / velX;
		var timeY:Float = dtyc / velY;
		var t0:Float = Math.max(timeX, timeY);

		var disjointTimeX:Float = (dtxd / velX);
		var disjointTimeY:Float = (dtyd / velY);

		var t1:Float = Math.min(disjointTimeX, disjointTimeY);

		if ((timeX < 0 && timeY < 0) || (timeX > 1 || timeY > 1)) {
			return new CollisionData(false);
		}

		if (t0 < t1) {
			var collisionNature:Int = CollisionData.VERTICAL;
			if (timeX >= timeY) {
				collisionNature = CollisionData.HORIZONTAL;
			}

			return new CollisionData(true, t0, collisionNature);
		}

		return new CollisionData(false);
	}
}
