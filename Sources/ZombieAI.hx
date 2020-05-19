package;

import kha.math.FastVector2;
import refraction.control.BreadCrumbs;
import refraction.core.Component;
import refraction.display.AnimatedRender;
import refraction.generic.Position;
import refraction.generic.Velocity;
import refraction.tile.TilemapData;
import refraction.tile.TilemapUtils;
import refraction.utils.Interval;
import helpers.DebugLogger;

/**
 * ...
 * @author
 */
enum ZombieAIState {
	IDLE;
	AGGRESSIVE;
}

class ZombieAI extends Component {
	public var breadcrumbs:BreadCrumbs;
	public var randTargetInterval:Interval;
	public var position:Position;
	public var velocity:Velocity;

	private var blc:AnimatedRender;

	public var followTarget:Position;
	public var targetMap:TilemapData;

	private var state:ZombieAIState;
	private var scentInterval:Interval;
	private var lastScene:Bool;

	public function new(?_followTarget:Position, ?_tilemap:TilemapData) {
		super();

		followTarget = _followTarget;

		state = IDLE;
		// randTargetInterval = new Interval(walk, 120);
		lastScene = false;

		scentInterval = new Interval(dropCrumb, 5);

		targetMap = _tilemap;
	}

	function dropCrumb() {
		breadcrumbs.addBreadCrumb(new FastVector2(followTarget.x, followTarget.y));
		if (breadcrumbs.breadcrumbs.length > 50) // TODO: trail length
		{
			// breadcrumbs.breadcrumbs.shift();
		}
	}

	function walk() {
		if (breadcrumbs.breadcrumbs[0] == null) {
			breadcrumbs.addBreadCrumb(new FastVector2());
		}

		breadcrumbs.breadcrumbs[0].x = position.x + Math.random() * 300 - 150;
		breadcrumbs.breadcrumbs[0].y = position.x + Math.random() * 300 - 150;
	}

	override public function load():Void {
		breadcrumbs = entity.getComponent(BreadCrumbs);
		position = entity.getComponent(Position);
		velocity = entity.getComponent(Velocity);
		blc = entity.getComponent(AnimatedRender);
		// targetMap = entity.getComponent(TileCollision).targetTilemap;
	}

	override public function update():Void {
		//	randTargetInterval.tick();

		// AI
		if (followTarget == null || followTarget.remove) {
			breadcrumbs.clear();
			followTarget = GameContext
				.instance()
				.beaconSystem.getOne("player")
				.getComponent(Position);
			DebugLogger.info("AI", {
				what: "retargeting zombie target",
				target: followTarget
			});
		}
		if (targetMap == null) {
			targetMap = GameContext
				.instance()
				.tilemapData;
		}

		var p:FastVector2 = new FastVector2(position.x - followTarget.x, position.y - followTarget.y);
		var seen:Bool = !TilemapUtils.raycast(targetMap, position.x + 20, position.y + 20,
			followTarget.x + 20, followTarget.y + 20)
			&& !TilemapUtils.raycast(targetMap, position.x + 0, position.y + 0, followTarget.x + 0,
				followTarget.y + 0)
			&& !TilemapUtils.raycast(targetMap, position.x + 20, position.y + 0, followTarget.x + 20,
				followTarget.y + 0)
			&& !TilemapUtils.raycast(targetMap, position.x + 0, position.y + 20, followTarget.x + 0,
				followTarget.y + 20);

		if (seen) {
			while (breadcrumbs.breadcrumbs.length > 1) {
				breadcrumbs.breadcrumbs.shift();
			}
			state = AGGRESSIVE;
			/*var p2:FastVector2 = new FastVector2(position.x - followTarget.x, position.y - followTarget.y);
				p2.normalize();
				p2 = p2.mult(breadcrumbs.maxAcceleration);
				breadcrumbs.breadcrumbs.pop();
				breadcrumbs.breadcrumbs.push(new FastVector2(followTarget.x, followTarget.y)); */
		}

		scentInterval.tick();

		// ANIMATION
		if (Math.round(velocity.getVelX()) == 0 && Math.round(velocity.getVelY()) == 0) {
			blc.curAnimaition = "idle";
			blc.frame = 0;
		} else {
			blc.curAnimaition = "running";
		}
	}
}
