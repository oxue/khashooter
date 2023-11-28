package refraction.display;

import hxblit.Surface2D;
import hxblit.TextureAtlas.FloatRect;
import refraction.core.Component;

/**
 * ...
 * @author qwerber
 */
class SurfaceSetCmp extends Component {

	public var surfaces:Array<Surface2D>;
	public var indexes:Array<Int>;
	public var translateX:Float;
	public var translateY:Float;
	public var registrationX:Float;
	public var registrationY:Float;
	public var frame:FloatRect;

	public function new() {
		super();
		registrationX = registrationY = 0;
	}

	public function addTranslation(x:Float, y:Float):SurfaceSetCmp {
		translateX += x;
		translateY += y;
		return this;
	}

	public function registration(x:Float, y:Float):SurfaceSetCmp {
		registrationX = x;
		registrationY = y;
		return this;
	}
}
