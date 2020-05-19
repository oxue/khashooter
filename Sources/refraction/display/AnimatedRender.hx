package refraction.display;

import hxblit.KhaBlit;
import hxblit.TextureAtlas.FloatRect;
import hxblit.TextureAtlas.IntRect;
import hxblit.Camera;
import refraction.core.Component;
import refraction.generic.Position;
import kha.math.Vector2;
import haxe.ds.StringMap;

/**
 * ...
 * @author worldedit
 */
class AnimatedRender extends Component {
	public var frameTime:Int;

	private var time:Int;

	public var frame:Int;
	public var animations:StringMap<Array<Int>>;

	private var coordX:Int;
	private var coordY:Int;
	private var surface2Set:SurfaceSet;
	private var position:Position;

	public var numRot:Int;
	public var curAnimaition:String;

	private var surface:String;

	public function new(_surface:String = null) {
		super();
		surface = _surface;
		numRot = 32;

		coordX = coordY = 0;
		animations = new StringMap<Array<Int>>();
		frameTime = 4;
		curAnimaition = "";
		frame = 0;
	}

	override public function autoParams(_args:Dynamic):Void {
		var i:Int = _args.animations.length;
		while (i-- > 0) {
			var item = _args.animations[i];
			animations.set(item.name, item.frames);
		}
		curAnimaition = _args.initialAnimation;
		frameTime = _args.frameTime;
		surface = _args.surface;
		surface2Set = entity.getComponent(SurfaceSet, surface);
	}

	override public function load():Void {
		surface2Set = entity.getComponent(SurfaceSet, surface);
		position = entity.getComponent(Position);
	}

	public function draw(camera:Camera):Void {
		time++;
		if (time == frameTime) {
			time = 0;
			frame++;
			if (frame == animations
				.get(curAnimaition)
				.length
			) {
				frame = 0;
			}
			coordY = animations.get(curAnimaition)[frame];
		}
		if (position.rotation < 0) {
			position.rotation += 360;
		} else if (position.rotation >= 360) {
			position.rotation -= 360;
		}
		var offsetX = 0.0;
		var offsetY = 0.0;

		coordX = Math.round(position.rotation / 360 * numRot) % numRot;

		if (surface2Set.registrationX != 0 || surface2Set.registrationY != 0) {
			var halfs = new Vector2(surface2Set.surfaces[0].width / 2, surface2Set.surfaces[0].height / 2);
			var translation = new Vector2(surface2Set.translateX, surface2Set.translateY);
			var center = halfs.sub(translation);
			var reg = center.sub(new Vector2(surface2Set.registrationX, surface2Set.registrationY));

			var a = coordX / numRot * 2 * 3.1415;
			var cs = Math.cos(a);
			var sn = Math.sin(a);
			offsetX = reg.x * cs - reg.y * sn;
			offsetY = reg.x * sn + reg.y * cs;

			offsetX -= center.x;
			offsetY -= center.y;
		}

		KhaBlit.blit(surface2Set.surfaces[cast coordX + coordY * numRot],
			cast(Math.round(position.x - surface2Set.translateX) - camera.X() + offsetX),
			cast(Math.round(position.y - surface2Set.translateY) - camera.Y() + offsetY));
	}
}
