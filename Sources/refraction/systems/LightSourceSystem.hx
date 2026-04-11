package refraction.systems;

import refraction.ds2d.DS2D;
import refraction.core.Entity;
import refraction.core.Sys;
import refraction.display.LightSourceCmp;

/**
 * ...
 * @author
 */
class LightSourceSystem extends Sys<LightSourceCmp> {

    var lightingSystem:DS2D;

    public function new(
        lightingSystem:DS2D
    ) {
        this.lightingSystem = lightingSystem;
        super();
    }

    override function procure<G:LightSourceCmp>(e:Entity, _type:Class<G>, ?_name:String, ?_default:G):G {
        var comp:G = super.procure(e, _type, _name, _default);
        lightingSystem.addLightSource(comp.light);
        return comp;
    }

    override public function updateComponent(comp:LightSourceCmp) {
        comp.light.position.x = comp.position.x;
        comp.light.position.y = comp.position.y;
    }
}
