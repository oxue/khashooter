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

	gameContext.hitTestSystem.onHit(HG_ENEMY, HG_PLAYER, function(z:Entity, p:Entity) {
		p.notify(MSG_DAMAGE, {amount: -1});
		entFactory.createGibSplash(1, p.getComponent(PositionCmp));
	});

	gameContext.hitTestSystem.onHit(
		HG_NEUTRAL_HP,
		HG_FIRE,
		function(neutralHpEntity:Entity, f:Entity) {
			neutralHpEntity.notify(MSG_DAMAGE, {
				amount: -gameContext.config.fireball_damage,
				type: HG_FIRE
			});
		}
	);

	gameContext.hitTestSystem.onHit(HG_ENEMY, HG_CROSSBOW_BOLT, function(enemy:Entity, bolt:Entity) {

		// notify
		enemy.notify(MSG_DAMAGE, {amount: -10});
		bolt.notify(MSG_COLLIDED);

		final knockbackRotation:Float = bolt
			.getComponent(PositionCmp)
			.rotationDegrees;

		// particle
		entFactory.createGibSplash(
			gameContext.config.single_hit_gibsplash_amount,
			enemy.getComponent(PositionCmp),
			Utils.a2rad(knockbackRotation)
		);

		knockback(enemy, knockbackRotation);
	});

	gameContext.hitTestSystem.onHit(HG_DEMON_FIREBALL, HG_PLAYER, function(fireball:Entity, player:Entity) {
		player.notify(MSG_DAMAGE, {amount: -gameContext.config.demon_fireball_damage});
		fireball.notify(MSG_COLLIDED);
		final knockbackRotation:Float = fireball
			.getComponent(PositionCmp)
			.rotationDegrees;
		knockback(player, knockbackRotation);
		entFactory.createGibSplash(
			gameContext.config.single_hit_gibsplash_amount,
			player.getComponent(PositionCmp),
			Utils.a2rad(knockbackRotation)
		);
	});
}

function knockback(entity:Entity, direction:Float, power:Float = 10) {
	var velocity:VelocityCmp = entity.getComponent(VelocityCmp);
	var rad:Float = Utils.a2rad(direction);
	velocity.addVelX(Math.cos(rad) * power);
	velocity.addVelY(Math.sin(rad) * power);
}
