package refraction.tile;

import refraction.core.Sys;
import refraction.generic.Position;
import refraction.generic.Dimensions;
import refraction.generic.Velocity;
import refraction.tile.TilemapData;
import refraction.tile.TileCollision;
import hxblit.TextureAtlas.FloatRect;
import hxblit.TextureAtlas.IntBounds;
import refraction.core.Utils;

class TileCollisionSys extends Sys<TileCollision>
{
	private var tilemapData:TilemapData;
	private var pool:Array<TileCollision>;

	public function new()
	{
		pool = new Array<TileCollision>();
		super();
	}

	override public function produce():TileCollision
	{
		if(pool.length != 0){
			return pool.pop();
		}
		return null;
	}

	public function setTilemap(_tilemapData:TilemapData):Void
	{
		tilemapData = _tilemapData;
	}

	override public function update():Void{
		var i = 0;
		while (i < components.length)
		{
			var tc = components[i];
			if (tc.remove)
			{
				removeIndex(i, pool);
				continue;
			}
			collide(tc);
			++i;
		}
	}

	private function maxi(a:Int, b:Int):Int
	{
		return (a < b) ? b : a;
	}

	private function mini(a:Int, b:Int):Int
	{
		return (a > b) ? b : a;
	}

	private function clamp(a:Int, low:Int, high:Int):Int
	{
		return maxi(mini(a, high), low);
	}

	private function getCollisionBounds(_bound:FloatRect):IntBounds
	{
		var bottom = Math.floor(_bound.bottom() / tilemapData.tilesize);
		var top = Math.floor(_bound.top() / tilemapData.tilesize);
		var right = Math.floor(_bound.right() / tilemapData.tilesize);
		var left = Math.floor(_bound.left() / tilemapData.tilesize);
		
		top = clamp(top, 0, tilemapData.height - 1);
		left = clamp(left, 0, tilemapData.width - 1);
		bottom = clamp(bottom, 0, tilemapData.height - 1);
		right = clamp(right, 0, tilemapData.width - 1);
		
		return new IntBounds(left, right, top, bottom);
	}

	private function sweptRect(tc:TileCollision):FloatRect
	{
		var previousX = tc.position.x - tc.velocity.velX;
		var previousY = tc.position.y - tc.velocity.velY;

		var hx = tc.hitboxPosition.x;
		var hy = tc.hitboxPosition.y;

		var lastRect = new FloatRect(previousX + hx, previousY + hy, tc.dimensions.width, tc.dimensions.height);
		var nowRect = new FloatRect(tc.position.x + hx, tc.position.y + hy, tc.dimensions.width, tc.dimensions.height);
		return lastRect.union(nowRect);
	}

	private function minTimeData(_datas:Array<CollisionData>):CollisionData
	{
		return Lambda.fold(_datas, function(d:CollisionData, f:CollisionData){
			return (d.time < f.time ? d : f);
		}, _datas[0]);
	}

	private function pushBack(tc:TileCollision, data:CollisionData):Void
	{
		var xFlag = 1 - data.nature;
		var yFlag = data.nature;
		
		var pushbackX = -tc.velocity.velX * (1 - data.time);
		var pushbackY = -tc.velocity.velY * (1 - data.time);

		// pushback
		tc.position.x += pushbackX * xFlag;
		tc.position.y += pushbackY * yFlag;

		tc.velocity.velX = -pushbackX * yFlag;
		tc.velocity.velY = -pushbackY * xFlag;
	}

	private function getCollisionsInBound(tc:TileCollision, bounds:IntBounds):Array<CollisionData>
	{
		var datas = new Array<CollisionData>();
		var i = bounds.t;
		while(i<=bounds.b)
		{
			var j = bounds.l;
			while(j<=bounds.r)
			{
				if(tilemapData.data[i][j].solid)
				{
					var cdata = solveRect(
						tc, 
						j * tilemapData.tilesize, 
						i * tilemapData.tilesize, 
						tilemapData.tilesize, 
						tilemapData.tilesize
					);
					if(cdata.collided)
					{
						datas.push(cdata);
					}
				}
				j++;
			}
			i++;
		}
		return datas;
	}

	public function collideOneAxis(tc:TileCollision):Void
	{
		var datas = getCollisionsInBound(tc, getCollisionBounds(sweptRect(tc)));
		
		if (datas.length > 0)
			pushBack(tc, minTimeData(datas));
	}

	private function collide(tc:TileCollision):Void 
	{
		collideOneAxis(tc);
		collideOneAxis(tc);
	}
	

	// WARNING DELICATE FLOATING POINT MATH
	public function solveRect(_tc:TileCollision, _tx:Int, _ty:Int, _tw:Int, _th:Int):CollisionData
	{
		var position = _tc.position.vec().add(_tc.hitboxPosition);
		var previous = _tc.position.vec().sub(_tc.velocity.vec()).add(_tc.hitboxPosition);
		var dimensions:Dimensions = _tc.dimensions;
		var velX = position.x - previous.x;
		var velY = position.y - previous.y;
		var dtxc = 0.0;
		var dtyc = 0.0;
		var dtxd = 0.0;
		var dtyd = 0.0;
		
		if (_tc.velocity.velX < 0)
		{
			dtxc = _tx + _tw - previous.x;
			dtxd = _tx - previous.x - dimensions.width;
		}
		else
		{
			dtxc = _tx - previous.x - dimensions.width;
			dtxd = _tx + _tw - previous.x;
		}
		if (velY < 0)
		{
			dtyc = _ty + _th - previous.y;
			dtyd = _ty - previous.y - dimensions.height;
		}
		else
		{
			dtyc = _ty - previous.y - dimensions.height;
			dtyd = _ty + _th - previous.y;
		}
		var timeX:Float = dtxc / velX;
		var timeY:Float = dtyc / velY;
		var t0:Float = Math.max(timeX, timeY);
		
		var disjointTimeX:Float = (dtxd / velX);
		var disjointTimeY:Float = (dtyd / velY);
		
		var t1:Float = Math.min(disjointTimeX, disjointTimeY);
		
		if ((timeX < 0 && timeY < 0) || (timeX > 1 || timeY > 1))
		{
			return new CollisionData(false);
		}
		
		if (t0 < t1)
		{
			return new CollisionData(true, t0, timeX >= timeY ? 0 : 1);
		}
		
		return new CollisionData(false);
	}
}