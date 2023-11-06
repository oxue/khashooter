package refraction.tile;

/*import flash.geom.Rectangle;
	import flash.Vector; */
import hxblit.Camera;
import hxblit.TextureAtlas.FloatRect;
import kha.graphics2.Graphics;
import kha.math.Vector2;
import refraction.control.KeyControl;
import refraction.core.Component;
import refraction.generic.DimensionsCmp;
import refraction.generic.PositionCmp;
import refraction.generic.VelocityCmp;

/**
 * ...
 * @author worldedit
 */
class TileCollision extends Component {
	public var targetTilemap:Tilemap;
	public var hitboxPosition:Vector2;

	public var position:PositionCmp;
	public var dimensions:DimensionsCmp;
	public var velocity:VelocityCmp;

	public function new() {
		super();
	}

	override public function autoParams(_args:Dynamic) {
		targetTilemap = _args.tilemap;
		hitboxPosition = new Vector2(_args.hitboxX, _args.hitboxY);
	}

	public function drawHitbox(camera:Camera, g2:Graphics) {
		g2.color = kha.Color.Green;
		g2.drawRect((position.x - camera.x + 1 + hitboxPosition.x) * 2,
			(position.y - camera.y - 1 + hitboxPosition.y) * 2, (dimensions.width) * 2,
			(dimensions.height) * 2, 1.0);
	}

	override public function load() {
		position = entity.getComponent(PositionCmp);
		dimensions = entity.getComponent(DimensionsCmp);
		velocity = entity.getComponent(VelocityCmp);
	}
}
