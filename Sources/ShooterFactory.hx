import refraction.core.ComponentFactory;
import refraction.display.AnimatedRender;
import refraction.control.RotationControl;
import refraction.control.KeyControl;
import refraction.tile.TileCollision;
import refraction.generic.Position;
import refraction.generic.Velocity;
import refraction.generic.Dimensions;
import refraction.systems.SpacingSys.Spacing;
import refraction.control.Damping;
import components.HitCircle;
import components.Beacon;
import refraction.control.BreadCrumbs;
import components.Particle;
import refraction.core.Entity;
import refraction.core.Component;
import components.Health;

class ShooterFactory extends ComponentFactory {
	public function new(_gameContext:GameContext) {
		super(_gameContext);
	}

	override public function get(_type:String, _e:Entity, _name:String = null):Component {
		switch _type {
			case "AnimatedRender":
				return cast gameContext.renderSystem.procure(_e, AnimatedRender, _name);
			case "AnimatedRender/SelfLit":
				return cast gameContext.selfLitRenderSystem.procure(_e, AnimatedRender, _name);
			case "RotationControl":
				return cast gameContext.controlSystem.procure(_e, RotationControl, _name);
			case "KeyControl":
				return cast gameContext.controlSystem.procure(_e, KeyControl, _name);
			case "TileCollision":
				return cast gameContext.collisionSystem.procure(_e, TileCollision, _name);
			case "PlayerAnimation":
				return cast gameContext.controlSystem.procure(_e, PlayerAnimation, _name);
			case "Inventory":
				return _e.addComponent(new Inventory());
			case "Position":
				return _e.addComponent(new Position());
			case "Dimensions":
				return _e.addComponent(new Dimensions());
			case "Velocity":
				return cast gameContext.velocitySystem.procure(_e, Velocity, _name);
			case "Spacing":
				return cast gameContext.spacingSystem.procure(_e, Spacing, _name);
			case "Damping":
				return cast gameContext.dampingSystem.procure(_e, Damping, _name);
			case "HitCircle":
				return cast gameContext.hitTestSystem.procure(_e, HitCircle, _name);
			case "BreadCrumbs":
				return cast gameContext.breadCrumbsSystem.procure(_e, BreadCrumbs, _name);
			case "Beacon":
				return cast gameContext.beaconSystem.procure(_e, Beacon, _name);
			case "ZombieAI":
				return cast gameContext.aiSystem.procure(_e, ZombieAI, _name);
			case "MimiAI":
				return cast gameContext.aiSystem.procure(_e, MimiAI, _name);
			case "Particle":
				return cast gameContext.particleSystem.procure(_e, Particle, _name);
			case "Health":
				return _e.addComponent(new Health());
		}
		return null;
	}
}
