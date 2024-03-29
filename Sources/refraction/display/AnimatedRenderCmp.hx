package refraction.display;

import haxe.ds.StringMap;
import hxblit.Camera;
import hxblit.KhaBlit;
import kha.math.Vector2;
import refraction.core.Component;
import refraction.generic.PositionCmp;

/**
 * ...
 * @author worldedit
 */
class AnimatedRenderCmp extends Component {

	public var frameTime:Int;

	public var frame:Int;
	public var animations:StringMap<Array<Int>>;

	public var numRot:Int;
	public var curAnimation:String;

	var time:Int;

	var coordX:Int;
	var coordY:Int;
	var surface2Set:SurfaceSetCmp;
	var position:PositionCmp;

	var surface:String;

	public function new(?_surface:String) {
		super();
		surface = _surface;
		numRot = 64;

		coordX = coordY = 0;
		animations = new StringMap<Array<Int>>();
		frameTime = 4;
		curAnimation = "";
		frame = 0;
	}

	public inline function setCurrentAnimation(_animation) {
		this.curAnimation = _animation;
	}

	override public function autoParams(_args:Dynamic) {
		var i:Int = _args.animations.length;
		while (i-- > 0) {
			var item = _args.animations[i];
			animations.set(item.name, item.frames);
		}
		curAnimation = _args.initialAnimation;
		frameTime = _args.frameTime;
		surface = _args.surface;
		frame = 0;
		surface2Set = entity.getComponent(SurfaceSetCmp, surface);
	}

	override public function load() {
		surface2Set = entity.getComponent(SurfaceSetCmp, surface);
		position = entity.getComponent(PositionCmp);
	}

	public function draw(camera:Camera) {
		time++;
		var animation:Array<Int> = animations.get(curAnimation);
		coordY = animation[frame];
		if (time == frameTime) {
			time = 0;
			frame = (frame + 1) % animation.length;
		}
		if (position.rotationDegrees < 0) {
			position.rotationDegrees += 360;
		} else if (position.rotationDegrees >= 360) {
			position.rotationDegrees -= 360;
		}
		var offsetX = 0.0;
		var offsetY = 0.0;

		coordX = Math.round(position.rotationDegrees / 360 * numRot) % numRot;

		if (surface2Set.registrationX != 0 || surface2Set.registrationY != 0) {
			var halfs = new Vector2(
				surface2Set.surfaces[0].width / 2,
				surface2Set.surfaces[0].height / 2
			);
			var translation = new Vector2(surface2Set.translateX, surface2Set.translateY);
			var center = halfs.sub(translation);
			var reg = center.sub(
				new Vector2(
					surface2Set.registrationX,
					surface2Set.registrationY
				)
			);

			var a = coordX / numRot * 2 * 3.1415;
			var cs = Math.cos(a);
			var sn = Math.sin(a);
			offsetX = reg.x * cs - reg.y * sn;
			offsetY = reg.x * sn + reg.y * cs;

			offsetX -= center.x;
			offsetY -= center.y;
		}

		KhaBlit.blit(
			surface2Set.surfaces[cast coordX + coordY * numRot],
			cast(Math.round(position.x - surface2Set.translateX) - camera.roundedX() + offsetX),
			cast(Math.round(position.y - surface2Set.translateY) - camera.roundedY() + offsetY)
		);
	}
}
