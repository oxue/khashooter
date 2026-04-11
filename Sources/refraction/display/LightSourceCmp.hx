package refraction.display;

import kha.math.FastVector2;
import refraction.core.Component;
import refraction.ds2d.DS2D;
import refraction.ds2d.LightSource;
import refraction.generic.PositionCmp;

/**
 * ...
 * @author
 */
class LightSourceCmp extends Component {

    public var light:LightSource;
    public var offset:FastVector2;
    public var position:PositionCmp;

    public function new(lightingSystem:DS2D = null, _color:Int = 0xffff0000, _radius:Int = 100, _offsetX:Int = 0,
            _offsetY:Int = 0) {
        light = new LightSource(0, 0, _color, _radius);
        if (lightingSystem != null) lightingSystem.addLightSource(light);
        offset = new FastVector2(_offsetX, _offsetY);

        super();
    }

    override public function autoParams(_args:Dynamic) {
        light.setColorHex(_args.color);
        light.radius = _args.radius;
        offset.x = _args.offsetX;
        offset.y = _args.offsetY;
    }

    override public function load() {
        position = entity.getComponent(PositionCmp);
        light.position.x = position.x;
        light.position.y = position.y;
    }

    // TODO : remove funct
    override public function unload() {
        light.remove = true;
    }
}
