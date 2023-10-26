package game;

import components.Beacon;
import components.Health;
import components.HitCircle;
import components.Particle;
import game.GameContext;
import game.Inventory;
import refraction.control.BreadCrumbs;
import refraction.control.Damping;
import refraction.control.KeyControl;
import refraction.control.RotationControl;
import refraction.core.Component;
import refraction.core.ComponentFactory;
import refraction.core.Entity;
import refraction.display.AnimatedRender;
import refraction.generic.Dimensions;
import refraction.generic.Position;
import refraction.generic.Velocity;
import refraction.systems.SpacingSys.Spacing;
import refraction.tile.TileCollision;

class ShooterFactory extends ComponentFactory {
	public function new(_gameContext:GameContext) {
		super(_gameContext);
	}

	override public function get(_type:String, _e:Entity, _name:String = null):Component {
		switch _type {
			case "AnimatedRender":
				return cast gameContext.renderSystem.procure(_e, AnimatedRender, _name, new AnimatedRender());
			case "AnimatedRender/SelfLit":
				return cast gameContext.selfLitRenderSystem.procure(_e, AnimatedRender, _name, new AnimatedRender());
			case "RotationControl":
				return cast gameContext.controlSystem.procure(_e, RotationControl, _name, new RotationControl());
			case "KeyControl":
				return cast gameContext.controlSystem.procure(_e, KeyControl, _name, new KeyControl());
			case "TileCollision":
				return cast gameContext.collisionSystem.procure(_e, TileCollision, _name, new TileCollision());
			case "PlayerAnimation":
				return cast gameContext.controlSystem.procure(_e, PlayerAnimation, _name, new PlayerAnimation());
			case "Inventory":
				return _e.addComponent(new Inventory());
			case "Position":
				return _e.addComponent(new Position());
			case "Dimensions":
				return _e.addComponent(new Dimensions());
			case "Velocity":
				return cast gameContext.velocitySystem.procure(_e, Velocity, _name, new Velocity());
			case "Spacing":
				return cast gameContext.spacingSystem.procure(_e, Spacing, _name, new Spacing());
			case "Damping":
				return cast gameContext.dampingSystem.procure(_e, Damping, _name, new Damping());
			case "HitCircle":
				return cast gameContext.hitTestSystem.procure(_e, HitCircle, _name, new HitCircle());
			case "BreadCrumbs":
				return cast gameContext.breadCrumbsSystem.procure(_e, BreadCrumbs, _name, new BreadCrumbs());
			case "Beacon":
				return cast gameContext.beaconSystem.procure(_e, Beacon, _name, new Beacon());
			case "ZombieAI":
				return cast gameContext.aiSystem.procure(_e, ZombieAI, _name, new ZombieAI());
			case "MimiAI":
				return cast gameContext.aiSystem.procure(_e, MimiAI, _name, new MimiAI());
			case "Particle":
				return cast gameContext.particleSystem.procure(_e, Particle, _name, new Particle(10));
			case "Health":
				return _e.addComponent(new Health());
		}
		return null;
	}
}
