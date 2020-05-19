package refraction.control;

/*import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.Vector; */
import refraction.core.Component;
import refraction.core.Application;
// import refraction.display.EFLA;
import refraction.generic.Position;
import refraction.generic.TransformComponent;
import refraction.generic.VelocityComponent;
import refraction.tile.TilemapUtils;

/**
 * ...
 * @author qwerber
 */
class WayPointFollow extends Component {
	// public static var IDLE:Int;
	public static var WANDER:Int;
	public static var SMELLTR:Int;

	// public static var AGGRO:Int;
	private var IDLE:Int = 0;
	private var AGGRO:Int = 1;

	private var followTarget:Position;
	private var queue:Vector<Position>;
	private var velocity:VelocityComponent;
	private var position:Position;
	private var rotation:TransformComponent;
	private var maxAccel:Float;

	private var scentTimer:Int;
	private var timer:Int;

	private var state:Int;
	private var lastSeen:Bool;

	public function new() {
		super("waypoint_follow_comp");
		queue = new Vector<Position>();
	}

	override public function load():Void {
		rotation = cast entity.components.get("trans_comp");
		position = cast entity.components.get("pos_comp");
		velocity = cast entity.components.get("vel_comp");
		maxAccel = 0.2;
		scentTimer = 10;
		timer = 10;
		followTarget = queue[0];
		queue.length = 0;
		state = AGGRO;
	}

	public function addWaypoint(_p:Position):Void {
		queue.push(_p);
	}

	override public function update():Void {
		//			c.clear(0);
		var p:Point = new Point(followTarget.x - position.x, followTarget.y - position.y);
		var seen:Bool = !TilemapUtils.raycast(cast(Application.currentState, GameState)
			.tilemapdata
			,
			position.x
			+ 10, position.y
			+ 10, followTarget.x
			+ 10, followTarget.y
			+ 10)
			&& p.length < 200;
		if (seen) {
			while (queue.length > 3)
				queue.shift();
			state = AGGRO;
			var p:Point = new Point(followTarget.x - position.x, followTarget.y - position.y);
			p.normalize(maxAccel);
			velocity.velX += p.x;
			velocity.velY += p.y;
			var s:Float = Math.atan2(p.y, p.x);
			rotation.rotation = cast(s * 57.3);
		}
		timer++;
		if (timer >= scentTimer) {
			timer = 0;
			queue.push(new Position(followTarget.x, followTarget.y));
		}
		var k:Int = queue.length;
		while (k-- > 0) {
			// c.displayData.fillRect(new Rectangle(queue[k].x + 9 - c.camera.x, queue[k].y + 9 - c.camera.y, 2, 2), seen?0xffff00ff:0xff00ff00);
		}
		/*EFLA.efla(c.displayData, cast position.x + 10 - c.camera.x, 
			cast position.y + 10 - c.camera.y,
			cast followTarget.x + 10 - c.camera.x,
			cast followTarget.y + 10 - c.camera.y,
			seen?0xffff00ff:0xff00ff00); */
		if (state == AGGRO && !seen) {
			if (lastSeen) {
				timer = scentTimer;
			}

			if (queue.length != 0) {
				if (queue[0] != null) {
					p = new Point(queue[0].x - position.x, queue[0].y - position.y);
					p.normalize(maxAccel);
					velocity.velX += p.x;
					velocity.velY += p.y;
					var s:Float = Math.atan2(p.y, p.x);
					rotation.rotation = cast(s * 57.3);
					p = new Point(queue[0].x - position.x, queue[0].y - position.y);
					if (p.length < 16) {
						queue.shift();
					}
				}
			}
		}
		lastSeen = seen;
	}
}
