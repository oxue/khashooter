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

	public function new(lightingSystem:DS2D, _color:Int = 0xff0000, _radius:Int = 100, _offsetX:Int,
			_offsetY:Int) {
		light = new LightSource(0, 0, _color, _radius);
		lightingSystem.addLightSource(light);
		offset = new FastVector2(_offsetX, _offsetY);

		super();
	}

	override public function load() {
		position = entity.getComponent(PositionCmp);
	}

	// TODO : remove funct
	override public function unload() {
		light.remove = true;
	}
}
