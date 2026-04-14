package game;

import refraction.display.LightSourceCmp;
import game.behaviours.LesserDemonBehaviour;
import components.Beacon;
import components.Health;
import components.HitCircleCmp;
import components.ParticleCmp;
import game.behaviours.MimiAI;
import game.behaviours.ZombieAI;
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
import net.NetIdentity;
import net.NetTransformSender;
import net.NetTransformReceiver;
import net.NetDamageable;
import net.NetShootSender;
import net.NetShootReceiver;

class ShooterComponentFactory extends ComponentFactory {

    public function new(_gameContext:Dynamic) {
        super(_gameContext);
    }

    // Direct switch instead of lambda map — Haxe generics need concrete types
    // at each call site for JS target. Lambda-captured procure() calls lose
    // the generic specialization and compile to non-existent method names.
    override public function get(_type:String, _e:Entity, ?_name:String):Component {
        var gc:GameContext = cast gameContext;

        switch (_type) {
            case "AnimatedRender":
                return gc.renderSystem.procure(_e, AnimatedRenderCmp, _name);
            case "AnimatedRender/SelfLit":
                return gc.selfLitRenderSystem.procure(_e, AnimatedRenderCmp, _name);
            case "RotationControl":
                return gc.controlSystem.procure(_e, RotationControl, _name);
            case "KeyControl":
                return gc.controlSystem.procure(_e, KeyControl, _name);
            case "TileCollision":
                return gc.collisionSystem.procure(_e, TileCollisionCmp, _name);
            case "PlayerAnimation":
                return gc.controlSystem.procure(_e, PlayerAnimation, _name);
            case "Inventory":
                return _e.addComponent(new InventoryCmp());
            case "Position":
                return _e.addComponent(new PositionCmp());
            case "Dimensions":
                return _e.addComponent(new DimensionsCmp());
            case "Health":
                return _e.addComponent(new Health());
            case "Velocity":
                return gc.velocitySystem.procure(_e, VelocityCmp, _name);
            case "Spacing":
                return gc.spacingSystem.procure(_e, SpacingCmp, _name);
            case "Damping":
                return gc.dampingSystem.procure(_e, Damping, _name);
            case "HitCircle":
                return gc.hitTestSystem.procure(_e, HitCircleCmp, _name);
            case "BreadCrumbs":
                return gc.breadCrumbsSystem.procure(_e, BreadCrumbs, _name);
            case "Beacon":
                return gc.beaconSystem.procure(_e, Beacon, _name);
            case "ZombieAI":
                return gc.aiSystem.procure(_e, ZombieAI, _name);
            case "MimiAI":
                return gc.aiSystem.procure(_e, MimiAI, _name);
            case "LesserDemonBehaviour":
                return gc.aiSystem.procure(_e, LesserDemonBehaviour, _name);
            case "Particle":
                return gc.particleSystem.procure(_e, ParticleCmp, _name);
            case "LightSource":
                return gc.lightSourceSystem.procure(_e, LightSourceCmp, _name);
            case "NetIdentity":
                return _e.addComponent(new NetIdentity("", -1, false));
            case "NetTransformSender":
                return gc.netSys.procure(_e, NetTransformSender, _name);
            case "NetTransformReceiver":
                return gc.netSys.procure(_e, NetTransformReceiver, _name);
            case "NetDamageable":
                return gc.netSys.procure(_e, NetDamageable, _name);
            case "NetShootSender":
                return gc.netSys.procure(_e, NetShootSender, _name);
            case "NetShootReceiver":
                return gc.netSys.procure(_e, NetShootReceiver, _name);
            default:
                throw "Component type does not exist: " + _type;
        }
        return null;
    }
}
