package ;
import flash.geom.Point;
import flash.Vector;
import refraction.core.Component;
import refraction.core.Application;
import refraction.ds2d.LightSource;
import refraction.generic.Position;
import refraction.tile.CollisionData;
import refraction.tile.Tile;
import refraction.tile.Tilemap;
import refraction.core.Sys;
import refraction.tile.TilemapData;

/**
 * ...
 * @author worldedit
 */

class LineProjectile extends Component
{

	public var targetTilemap:TilemapData;
	public var position:Position;
	public var damage:Int;
	public var collidePoint:Point;
	public var targetSystem:Sys<EnemyCollideComponent>;
	
	public function new() 
	{
		super("proj_comp");
		collidePoint = new Point();
	}
	
	override public function load():Void 
	{
		position = cast entity.components.get("pos_comp");
		damage = 50;
	}
	
	override public function update():Void 
	{
		//targetTilemap.tilesize = 16;
		
		var i:Int = Math.floor(position.oldX / targetTilemap.tilesize);
		var j:Int = Math.floor(position.oldY / targetTilemap.tilesize);
		
		var iEnd:Int = Math.floor(position.x / targetTilemap.tilesize);
		var jEnd:Int = Math.floor(position.y / targetTilemap.tilesize);
		
		var di:Int = ((position.oldX < position.x)?1:((position.oldX > position.x)?-1:0));
		var dj:Int = ((position.oldY < position.y)?1:((position.oldY > position.y)?-1:0));
		
		var minX:Float = targetTilemap.tilesize * Math.floor(position.oldX / targetTilemap.tilesize);
		var maxX:Float = minX + targetTilemap.tilesize;
		
		var minY:Float = targetTilemap.tilesize * Math.floor(position.oldY / targetTilemap.tilesize);
		var maxY:Float = minY + targetTilemap.tilesize;
		
		var tx:Float = ((position.oldX > position.x)?(position.oldX - minX):(maxX - position.oldX)) / Math.abs(position.x - position.oldX);
		var ty:Float = ((position.oldY > position.y)?(position.oldY - minY):(maxY - position.oldY)) / Math.abs(position.y - position.oldY);
		
		var deltaX:Float = targetTilemap.tilesize / Math.abs(position.x - position.oldX);
		var deltaY:Float = targetTilemap.tilesize / Math.abs(position.y - position.oldY);
		
		var velX:Float = position.x - position.oldX;
		var velY:Float = position.y - position.oldY;
		
		//targetTilemap.tilesize = 16;
		collidePoint.x = position.x;
		collidePoint.y = position.y;
		
		var c:CollisionData = new CollisionData(false,0,0);
		
		while (true)
		{
			var t:Tile = targetTilemap.data[j][i];
			
			if (t.solid)
			{
				c = intersectTile(i * targetTilemap.tilesize, j * targetTilemap.tilesize, targetTilemap.tilesize);
				collidePoint.x = position.oldX + velX * c.time;
				collidePoint.y = position.oldY + velY * c.time;
				entity.remove();
				break;
			}

			if (tx <= ty)
			{
				if (i == iEnd) 
				{
					if (t.solid)
			{
				c = intersectTile(i * targetTilemap.tilesize, j * targetTilemap.tilesize, targetTilemap.tilesize);
					collidePoint.x = i * 16;
					collidePoint.y = j * 16;
				entity.remove();
				break;
			}
					break;
				}
				tx += deltaX;
				i += di;
			}else
			{
				if (j == jEnd)
				{
					if (t.solid)
			{
				c = intersectTile(i * targetTilemap.tilesize, j * targetTilemap.tilesize, targetTilemap.tilesize);
				//if (c.collided)
				//{
					collidePoint.x = i * 16;
					collidePoint.y = j*16;
				//}
				//trace("yes");
				entity.remove();
				break;
			}
					break;
				}
				ty += deltaY;
				j += dj;
			}
		}
		var i:Int = targetSystem.components.length;
		var listCol:Vector<EnemyCollideComponent> = new Vector<EnemyCollideComponent>();
		var ec:EnemyCollideComponent, p:Position, cp:Point;
		ec = null;
		p = null;
		cp = null;
		while (i-->0)
		{
			ec = targetSystem.components[i];
			p = position;
			cp = this.collidePoint;
			
			var px:Int = cast cp.x - p.oldX;
			var py:Int = cast cp.y - p.oldY;
			
			var ex:Int = cast ec.position.x + 16 - p.oldX;
			var ey:Int = cast ec.position.y + 16 - p.oldY;
			
			var t:Int = px * ex + py * ey;
			var t1:Int = cast Math.abs(py * ex - px * ey);
			var d2:Int = cast t1 * t1 / (px * px + py * py);
			
			var dx:Float = ec.position.x + 16 - p.oldX;
			var dy:Float = ec.position.y + 16 - p.oldY;
			var dis:Float = Math.sqrt(dx * dx + dy * dy);

			if (d2 < ec.radius2 && t > 0 && ex * ex + ey* ey <= px * px + py * py)
			{
				ec.distance = dis;
				listCol.push(ec);
			}
		}
		ec = null;
		i = listCol.length;
		var hi = 999999.;
		while (i-->0)
		{
			if (hi > listCol[i].distance)
			{
				ec = listCol[i];
				hi = listCol[i].distance;
			}
		}
		if (ec == null)
		{
			entity.remove();
			if(c.nature == 0)
			Factory.createSpark(cast collidePoint.x - 5.5, cast collidePoint.y, c.nature);
			if(c.nature == 1)
			Factory.createSpark(cast collidePoint.x - 11, cast collidePoint.y - 5.5, c.nature);
			if(c.nature == 2)
			Factory.createSpark(cast collidePoint.x - 5.5, cast collidePoint.y - 11, c.nature);
			if(c.nature == 3)
			Factory.createSpark(cast collidePoint.x, cast collidePoint.y - 5.5, c.nature);
			
			var l:LightSource = new LightSource(cast collidePoint.x,cast  collidePoint.y, 0xffffaa,10);
			l.remove = true;
			cast(Application.currentState, GameState).shadowSystem.addLightSource(l);
			
			return;
		}
		ec.health.applyHealth( -damage);
		var dx:Float = ec.position.x + 16 - p.oldX;
		var dy:Float = ec.position.y + 16 - p.oldY;
		var dis:Float = Math.sqrt(dx * dx + dy * dy);
		cp.x -= p.oldX;
		cp.y -= p.oldY;
		cp.normalize(dis);
		cp.x += p.oldX;
		cp.y += p.oldY;
		entity.remove();
	}
	
	private function intersectTile(_tx:Int, _ty:Int, _tilesize:Int):CollisionData
	{	
		var itx:Float = 0;
		var dtx:Float = 0;
		var ity:Float = 0;
		var dty:Float = 0;
		var velX:Float = position.x - position.oldX;
		var velY:Float = position.y - position.oldY;
		if (velX > 0)
		{
			itx = (_tx - position.oldX) / velX;
			dtx = (_tx + _tilesize - position.oldX) / velX;
		}else
		{
			itx = (_tx + _tilesize - position.oldX) / velX;
			dtx = (_tx - position.oldX) / velX;
		}
		
		if (velY > 0)
		{
			ity = (_ty - position.oldY) / velY;
			dty = (_ty + _tilesize - position.oldY) / velY;
		}else
		{
			ity = (_ty + _tilesize - position.oldY) / velY;
			dty = (_ty - position.oldY) / velY;
		}
		if (Math.max(itx, ity) < Math.min(dtx, dty))
		{
			return new CollisionData(true, Math.max(itx, ity), (itx > ity?1:0) + (itx > ity?(velX > 0?0:2):(velY > 0?2:0)));
		}
		return new CollisionData(false);
	}
	
}