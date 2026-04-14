package game;

import refraction.core.Entity;
import refraction.core.Utils;
import refraction.generic.PositionCmp;
import refraction.generic.VelocityCmp;

final MSG_DAMAGE:String = "damage";
final MSG_COLLIDED:String = "collided";

// ENTITIES
final HG_PLAYER:String = "player";
final HG_ENEMY:String = "enemy";
final HG_NEUTRAL_HP:String = "neutral_hp";
final HG_PICKUPABLE:String = "pickupable";

// SHOTS
final HG_FIRE:String = "fire";
final HG_CROSSBOW_BOLT:String = "crossbow_bolt";
final HG_DEMON_FIREBALL:String = "demon_fireball";

function defineCollisionBehaviours(gameContext:GameContext) {
	var entFactory:EntFactory = EntFactory.instance();

	// Host authority gate: in single-player always true; in multiplayer only the host
	// applies gameplay effects (damage, knockback). All clients run visual effects
	// (gib splashes, bolt collided notifications) for responsive feel.
	var isHost = function():Bool {
		return !GameState.isMultiplayer() || (gameContext.netState != null && gameContext.netState.isHost());
	};

	// Enemy touches player — contact damage
	gameContext.hitTestSystem.onHit(HG_ENEMY, HG_PLAYER, function(z:Entity, p:Entity) {
		// Visual — all clients
		entFactory.createGibSplash(1, p.getComponent(PositionCmp));
		// Gameplay — host only
		if (isHost()) {
			p.notify(MSG_DAMAGE, {amount: -1});
		}
	});

	// Fire hits neutral HP entity (e.g. destructible objects)
	gameContext.hitTestSystem.onHit(
		HG_NEUTRAL_HP,
		HG_FIRE,
		function(neutralHpEntity:Entity, f:Entity) {
			// Gameplay — host only
			if (isHost()) {
				neutralHpEntity.notify(MSG_DAMAGE, {
					amount: -gameContext.config.fireball_damage,
					type: HG_FIRE
				});
			}
		}
	);

	// Crossbow bolt hits enemy
	gameContext.hitTestSystem.onHit(HG_ENEMY, HG_CROSSBOW_BOLT, function(enemy:Entity, bolt:Entity) {
		final knockbackRotation:Float = bolt
			.getComponent(PositionCmp)
			.rotationDegrees;

		// Visual — all clients
		bolt.notify(MSG_COLLIDED);
		entFactory.createGibSplash(
			gameContext.config.single_hit_gibsplash_amount,
			enemy.getComponent(PositionCmp),
			Utils.a2rad(knockbackRotation)
		);

		// Gameplay — host only
		if (isHost()) {
			enemy.notify(MSG_DAMAGE, {amount: -10});
			knockback(enemy, knockbackRotation);
		}
	});

	// Crossbow bolt hits player (multiplayer — other players are HG_PLAYER)
	gameContext.hitTestSystem.onHit(HG_CROSSBOW_BOLT, HG_PLAYER, function(bolt:Entity, player:Entity) {
		// Visual — all clients
		bolt.notify(MSG_COLLIDED);
		entFactory.createGibSplash(
			gameContext.config.single_hit_gibsplash_amount,
			player.getComponent(PositionCmp),
			Utils.a2rad(bolt.getComponent(PositionCmp).rotationDegrees)
		);
		// Gameplay — host only (damage is relayed via NetDamageable)
		// NO direct damage or knockback here — server/host sends hit event,
		// victim applies knockback via NetDamageable
	});

	// Demon fireball hits player
	gameContext.hitTestSystem.onHit(HG_DEMON_FIREBALL, HG_PLAYER, function(fireball:Entity, player:Entity) {
		final knockbackRotation:Float = fireball
			.getComponent(PositionCmp)
			.rotationDegrees;

		// Visual — all clients
		fireball.notify(MSG_COLLIDED);
		entFactory.createGibSplash(
			gameContext.config.single_hit_gibsplash_amount,
			player.getComponent(PositionCmp),
			Utils.a2rad(knockbackRotation)
		);

		// Gameplay — host only
		if (isHost()) {
			player.notify(MSG_DAMAGE, {amount: -gameContext.config.demon_fireball_damage});
			knockback(player, knockbackRotation);
		}
	});
}

function knockback(entity:Entity, direction:Float, power:Float = 10) {
	var velocity:VelocityCmp = entity.getComponent(VelocityCmp);
	if (velocity == null) return; // Remote players have no VelocityCmp
	var rad:Float = Utils.a2rad(direction);
	velocity.addVelX(Math.cos(rad) * power);
	velocity.addVelY(Math.sin(rad) * power);
}
