package game.behaviours;

import refraction.tilemap.Tile;
import kha.graphics2.Graphics;
import hxblit.Camera;
import game.debug.IDebugDrawable;
import refraction.tilemap.DijkstraField;
import refraction.generic.VelocityCmp;
import refraction.tilemap.TileMap;
import haxe.ds.StringMap;
import refraction.core.Application;
import kha.math.Vector2;
import refraction.core.Utils;
import refraction.core.Entity;
import refraction.generic.PositionCmp;
import refraction.core.Component;

class LesserDemonBehaviour extends Component implements IDebugDrawable {

	static inline final IDLE:String = "idle";
	static inline final ATTACKING:String = "attacking";
	static inline final ROAMING:String = "roaming";

	var lastShotClock:Int;
	var cooldown:Int;
	var currentState:String;
	var stateFuncMap:StringMap<Void -> Void>;
	var shotCount:Int;
	var idleStateTimer:Int;
	var maxShotCount:Int;
	var idleStateTimerMaxSecs:Int;

	var wallForcePushVectors:Array<Vector2>;
	var predictionLocation:Vector2;

	public function new() {
		cooldown = Std.int(
			GameContext
				.instance()
				.config.lesser_demon_fireball_cooldown_secs * 60
		);
		lastShotClock = 0;
		maxShotCount = 15;
		shotCount = 10;
		idleStateTimer = 0;
		idleStateTimerMaxSecs = 2;
		wallForcePushVectors = initWallForcePushVectors();
		predictionLocation = null;

		stateFuncMap = new StringMap<Void -> Void>();
		stateFuncMap.set(IDLE, idle);
		stateFuncMap.set(ATTACKING, attacking);
		stateFuncMap.set(ROAMING, roaming);

		super();
	}

	override public function load() {
		super.load();

		currentState = IDLE;
	}

	public function drawDebug(camera:Camera, g2:Graphics) {
		var positionVec:Vector2 = getEntity()
			.getComponent(PositionCmp)
			.vec();
		g2.color = Pink;
		for (vec in wallForcePushVectors) {
			g2.drawLine(
				positionVec.x,
				positionVec.y,
				positionVec.x + vec.x,
				positionVec.y + vec.y
			);
		}

		if (predictionLocation != null) {
			g2.drawRect(predictionLocation.x, predictionLocation.y, 5, 5);
		}
	}

	function initWallForcePushVectors():Array<Vector2> {
		var vecLength:Int = 20;
		var vec:Array<Vector2> = [];
		for (i in 0...8) {
			var theta:Float = i * Math.PI / 4;
			vec.push(
				new Vector2(
					Math.cos(theta) * vecLength,
					Math.sin(theta) * vecLength
				)
			);
		}
		return vec;
	}

	function faceTarget(target:Entity) {
		var postion:PositionCmp = target.getComponent(PositionCmp);
		var monsterRotation:PositionCmp = getEntity()
			.getComponent(PositionCmp);
		var angle:Float = Utils.RAD2A * Math.atan2(
			postion.y - monsterRotation.y,
			postion.x - monsterRotation.x
		);
		monsterRotation.rotationDegrees = angle;
	}

	function faceVelocity() {
		var velocity:VelocityCmp = getEntity()
			.getComponent(VelocityCmp);
		var monsterRotation:PositionCmp = getEntity()
			.getComponent(PositionCmp);
		var angle:Float = Utils.RAD2A * Math.atan2(velocity.getVelY(), velocity.getVelX());
		monsterRotation.rotationDegrees = angle;
	}

	function shootTargetDumb(target:Entity) {
		final position:PositionCmp = getEntity()
			.getComponent(PositionCmp);

		final direction:Vector2 = target
			.getComponent(PositionCmp)
			.vec()
			.sub(position.vec())
			.normalized();

		EntFactory
			.instance()
			.spawnProjectile("DemonFireball", position.vec(), direction);
	}

	function shootTargetSmart(target:Entity) {
		final position:PositionCmp = getEntity()
			.getComponent(PositionCmp);

		var distanceToTarget = target
			.getComponent(PositionCmp)
			.vec()
			.sub(position.vec())
			.length;

		var projectileSpeed:Float = GameContext
			.instance()
			.config.projectiles_info.DemonFireball.speed;
		var timeToTargetFrames:Float = distanceToTarget / projectileSpeed;

		var targetVelocity:Vector2 = target
			.getComponent(VelocityCmp)
			.vec();
		var targetDistancePrediction:Vector2 = targetVelocity.mult(timeToTargetFrames);
		predictionLocation = target
			.getComponent(PositionCmp)
			.vec()
			.add(targetDistancePrediction);
		final direction:Vector2 = target
			.getComponent(PositionCmp)
			.vec()
			.add(targetDistancePrediction)
			.sub(position.vec())
			.normalized();

		EntFactory
			.instance()
			.spawnProjectile("DemonFireball", position.vec(), direction);
	}

	function tryShootTarget(target:Entity) {
		if (Application.frameClock - lastShotClock < cooldown) {
			return;
		}
		lastShotClock = Application.frameClock;
		shotCount--;

		shootTargetSmart(target);
	}

	override public function update() {
		if (stateFuncMap.get(currentState) != null) {
			stateFuncMap.get(currentState)();
		}
		pushBackWallForceVectors();
	}

	function pushBackWallForceVectors() {
		var tilemap:TileMap = GameContext
			.instance()
			.tilemap;
		var positionVec:Vector2 = getEntity()
			.getComponent(PositionCmp)
			.vec();
		for (vector in wallForcePushVectors) {
			pushbackSingleWallForceVector(tilemap, positionVec, vector);
		}
	}

	function pushbackSingleWallForceVector(tilemap:TileMap, myPos:Vector2, vector:Vector2) {
		var tilePos:Vector2 = myPos.add(vector);
		var tile:Tile = tilemap.getTileContainingVec2(tilePos);
		if (tile == null) {
			return;
		}
		if (tile.solid) {
			var velocity:VelocityCmp = getEntity()
				.getComponent(VelocityCmp);
			var direction:Vector2 = vector
				.normalized()
				.mult(-1);
			velocity.addVelX(direction.x * 1);
			velocity.addVelY(direction.y * 1);
		}
	}

	// === TRANSITIONS ===
	function transition(state:String) {
		if (state == ATTACKING) {
			shotCount = maxShotCount;
		} else if (state == IDLE) {
			idleStateTimer = 0;
		}
		currentState = state;
	}

	function getDirectionFromDijkstraMap():Vector2 {
		var dijkstraMap:DijkstraField = GameContext
			.instance()
			.dijkstraMap;
		var tilemap:TileMap = GameContext
			.instance()
			.tilemap;
		var myPosition:Vector2 = getEntity()
			.getComponent(PositionCmp)
			.vec();
		var direction:Vector2 = dijkstraMap.getTileContainingVec2(myPosition);
		if (direction == null) {
			direction = new Vector2(0, 0);
		}
		return direction;
	}

	// === STATES ===
	function idle() {
		var direction:Vector2 = getDirectionFromDijkstraMap()
			.mult(1);

		var velocity:VelocityCmp = getEntity()
			.getComponent(VelocityCmp);
		velocity.addVelX(direction.x);
		velocity.addVelY(direction.y);

		faceVelocity();

		idleStateTimer++;
		if (idleStateTimer > idleStateTimerMaxSecs * 60) {
			transition(ATTACKING);
			idleStateTimer = 0;
		}
	}

	function roaming() {
		var tilemap:TileMap = GameContext
			.instance()
			.tilemap;
		var myPosition:Vector2 = getEntity()
			.getComponent(PositionCmp)
			.vec();

		// get a point around me with radius 100
		var r:Float = Math.sqrt(100 * Math.random());
		var theta:Float = Math.random() * 2 * Math.PI;
		// var target
	}

	function attacking() {
		var followTarget:Entity = GameContext
			.instance()
			.beaconSystem.getOne("player");

		faceTarget(followTarget);
		if (shotCount <= 0) {
			transition(IDLE);
			return;
		} else {
			tryShootTarget(followTarget);
		}
	}
}
