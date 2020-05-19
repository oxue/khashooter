package refraction.systems;

// import flash.Vector;
import kha.math.FastVector2;
import refraction.generic.Position;
import refraction.generic.Velocity;
import refraction.core.Sys;
import refraction.core.Component;

/**
 * ...
 * @author worldedit
 */
class Spacing extends Component {
	public var p:Position;
	public var v:Velocity;
	public var radius:Float;

	public function new() {
		super();
	}

	override public function autoParams(_args:Dynamic):Void {
		radius = _args.radius;
	}

	override public function load():Void {
		p = entity.getComponent(Position);
		v = entity.getComponent(Velocity);
	}
}

class SpacingSys extends Sys<Spacing> {
	public function new() {
		super();
	}

	override public function update():Void {
		var i:Int = components.length;
		while (i-- > 0) {
			if (components[i].p.remove) {
				components[i] = components[components.length - 1];
				components.pop();
				continue;
			}
			var b:Position = components[i].p;
			var j:Int = components.length;
			var cx:Float = 0;
			var cy:Float = 0;
			while (j-- > 0) {
				var b2:Position = components[j].p;
				if (b2 == b)
					continue;

				var r2 = Math.pow(components[i].radius + components[j].radius, 2);

				if ((b2.x - b.x) * (b2.x - b.x) + (b2.y - b.y) * (b2.y - b.y) < r2) {
					if (b2.x == b.x && b2.y == b.y) {
						cx += Math.random() > 0.5 ? 1 : -1;
						cy += Math.random() > 0.5 ? 1 : -1;
					} else {
						var diffVec = new FastVector2(b2.x - b.x, b2.y - b.y);
						var penetrationDepth = components[i].radius + components[j].radius - diffVec.length;
						diffVec.normalize();
						var displace = diffVec.mult(-penetrationDepth);
						cx = cx + displace.x; // (b2.x - b.x);
						cy = cy + displace.y; // ;- (b2.y - b.y);
					}
				}
			}
			components[i].v.addVelX(cx / 8);
			components[i].v.addVelX(cy / 8);
		}
	}
}
