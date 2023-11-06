package game;

import components.Beacon;
import components.Health;
import components.HitCircleCmp;
import components.Particle;
import game.behaviours.MimiAI;
import game.behaviours.ZombieAI;
import haxe.Constraints.Function;
import helpers.DebugLogger;
import refraction.control.BreadCrumbs;
import refraction.control.Damping;
import refraction.control.KeyControl;
import refraction.control.RotationControl;
import refraction.core.Component;
import refraction.core.ComponentFactory;
import refraction.core.Entity;
import refraction.display.AnimatedRenderCmp;
import refraction.generic.DimensionsCmp;
import refraction.generic.PositionCmp;
import refraction.generic.VelocityCmp;
import refraction.systems.SpacingSys.SpacingCmp;
import refraction.tilemap.TileCollisionCmp;

class ShooterComponentFactory extends ComponentFactory {

	var typeToMethodMap:Map<String, Function>;

	public function new(_gameContext:GameContext) {
		super(_gameContext);
		typeToMethodMap = new Map<String, Function>();
		typeToMethodMap.set("AnimatedRender", (e:Entity, name:String) -> gameContext.renderSystem.procure(e, AnimatedRenderCmp, name));
		typeToMethodMap.set("AnimatedRender/SelfLit", (e:Entity, name:String) -> gameContext.selfLitRenderSystem.procure(e, AnimatedRenderCmp, name));
		typeToMethodMap.set("RotationControl", (e:Entity, name:String) -> gameContext.controlSystem.procure(e, RotationControl, name));
		typeToMethodMap.set("KeyControl", (e:Entity, name:String) -> gameContext.controlSystem.procure(e, KeyControl, name));
		typeToMethodMap.set("TileCollision", (e:Entity, name:String) -> gameContext.collisionSystem.procure(e, TileCollisionCmp, name));
		typeToMethodMap.set("PlayerAnimation", (e:Entity, name:String) -> gameContext.controlSystem.procure(e, PlayerAnimation, name));
		typeToMethodMap.set("Inventory", (e:Entity, name:String) -> e.addComponent(new InventoryCmp()));
		typeToMethodMap.set("Position", (e:Entity, name:String) -> e.addComponent(new PositionCmp()));
		typeToMethodMap.set("Dimensions", (e:Entity, name:String) -> e.addComponent(new DimensionsCmp()));
		typeToMethodMap.set("Health", (e:Entity, name:String) -> e.addComponent(new Health()));
		typeToMethodMap.set("Velocity", (e:Entity, name:String) -> gameContext.velocitySystem.procure(e, VelocityCmp, name));
		typeToMethodMap.set("Spacing", (e:Entity, name:String) -> gameContext.spacingSystem.procure(e, SpacingCmp, name));
		typeToMethodMap.set("Damping", (e:Entity, name:String) -> gameContext.dampingSystem.procure(e, Damping, name));
		typeToMethodMap.set("HitCircle", (e:Entity, name:String) -> gameContext.hitTestSystem.procure(e, HitCircleCmp, name));
		typeToMethodMap.set("BreadCrumbs", (e:Entity, name:String) -> gameContext.breadCrumbsSystem.procure(e, BreadCrumbs, name));
		typeToMethodMap.set("Beacon", (e:Entity, name:String) -> gameContext.beaconSystem.procure(e, Beacon, name));
		typeToMethodMap.set("ZombieAI", (e:Entity, name:String) -> gameContext.aiSystem.procure(e, ZombieAI, name));
		typeToMethodMap.set("MimiAI", (e:Entity, name:String) -> gameContext.aiSystem.procure(e, MimiAI, name));
		typeToMethodMap.set("Particle", (e:Entity, name:String) -> gameContext.particleSystem.procure(e, Particle, name));
	}

	override public function get(_type:String, _e:Entity, ?_name:String):Component {
		if (typeToMethodMap.exists(_type)) {
			return cast typeToMethodMap.get(_type)(_e, _name);
		}
		DebugLogger.info("WARN", "Does not exist in Shooter Factory");
		return null;
	}
}
