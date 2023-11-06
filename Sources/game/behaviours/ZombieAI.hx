package game.behaviours;

import helpers.DebugLogger;
import kha.math.FastVector2;
import refraction.control.BreadCrumbs;
import refraction.core.Component;
import refraction.display.AnimatedRenderCmp;
import refraction.generic.PositionCmp;
import refraction.generic.VelocityCmp;
import refraction.tile.Tilemap;
import refraction.tile.Tilemap;
import refraction.tile.TilemapUtils;
import refraction.utils.Interval;

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
	public var position:PositionCmp;
	public var velocity:VelocityCmp;

	public var followTarget:PositionCmp;
	public var targetMap:Tilemap;

	var blc:AnimatedRenderCmp;
	var state:ZombieAIState;
	var scentInterval:Interval;
	var lastScene:Bool;

	public function new(?_followTarget:PositionCmp, ?_tilemap:Tilemap) {
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

	override public function load() {
		breadcrumbs = entity.getComponent(BreadCrumbs);
		position = entity.getComponent(PositionCmp);
		velocity = entity.getComponent(VelocityCmp);
		blc = entity.getComponent(AnimatedRenderCmp);
		// targetMap = entity.getComponent(TileCollision).targetTilemap;
	}

	override public function update() {
		//	randTargetInterval.tick();

		// AI
		if (followTarget == null || followTarget.remove) {
			breadcrumbs.clear();
			followTarget = GameContext
				.instance()
				.beaconSystem.getOne("player")
				.getComponent(PositionCmp);
			DebugLogger.info("AI", {
				what: "retargeting zombie target",
				target: followTarget
			});
		}
		if (targetMap == null) {
			targetMap = GameContext
				.instance()
				.tilemap;
		}

		var p:FastVector2 = new FastVector2(
			position.x - followTarget.x,
			position.y - followTarget.y
		);
		var seen:Bool = !TilemapUtils.raycast(
			targetMap,
			position.x + 20,
			position.y + 20,
			followTarget.x + 20,
			followTarget.y + 20
		)
			&& !TilemapUtils.raycast(
				targetMap,
				position.x + 0,
				position.y + 0,
				followTarget.x + 0,
				followTarget.y + 0
			)
			&& !TilemapUtils.raycast(
				targetMap,
				position.x + 20,
				position.y + 0,
				followTarget.x + 20,
				followTarget.y + 0
			)
			&& !TilemapUtils.raycast(
				targetMap,
				position.x + 0,
				position.y + 20,
				followTarget.x + 0,
				followTarget.y + 20
			);

		if (seen) {
			while (breadcrumbs.breadcrumbs.length > 1) {
				breadcrumbs.breadcrumbs.shift();
			}
			state = AGGRESSIVE;
		}

		scentInterval.tick();

		// ANIMATION
		if (Math.round(velocity.getVelX()) == 0 && Math.round(velocity.getVelY()) == 0) {
			blc.curAnimation = "idle";
			blc.frame = 0;
		} else {
			blc.curAnimation = "running";
		}
	}
}
