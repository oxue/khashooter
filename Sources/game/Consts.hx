package game;

/**
 * ...
 * @author worldedit
 */
class Consts {
	public static inline var ACTOR_DAMPING:Float = 0.7;
	public static inline var CHARACTER_FRAME_TIME:Int = 8;
	public static inline var SMOOTH_FRAME_TIME:Int = 2;

	public static inline var BREADCRUMB_ZOMBIE_MAX_ACCEL:Float = 0.8;
	public static inline var BREADCRUMB_ACCEPTANCE_DISTANCE:Float = 3;
	public static inline var BREADCRUMB_NPC_PACING_MAX_ACCEL:Float = 0.3;

	public static inline var CROSSBOW_PROJECTILE_SPEED:Float = 8;

	public static inline var RAD2A:Float = 180 / 3.1415926;
	public static inline var A2RAD:Float = 1 / RAD2A;

	public static inline var BEACON_SWEEP_INTERVAL = 300;

	// HITGROUPS
	public static inline var PLAYER_BOLT = "PLAYER_BOLT";
	public static inline var FIRE = "FIRE";
	public static inline var ZOMBIE = "ZOMBIE";
	public static inline var NEUTRAL_HP = "NEUTRAL_HP";
}
