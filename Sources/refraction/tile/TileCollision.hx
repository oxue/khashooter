package refraction.tile;

/*import flash.geom.Rectangle;
	import flash.Vector; */
import hxblit.Camera;
import hxblit.TextureAtlas.FloatRect;
import kha.graphics2.Graphics;
import kha.math.Vector2;
import refraction.control.KeyControl;
import refraction.core.Component;
import refraction.generic.Dimensions;
import refraction.generic.Position;
import refraction.generic.Velocity;

/**
 * ...
 * @author worldedit
 */
class TileCollision extends Component {
	public var targetTilemap:TilemapData;
	public var hitboxPosition:Vector2;

	public var position:Position;
	public var dimensions:Dimensions;
	public var velocity:Velocity;

	public function new() {
		super();
	}

	override public function autoParams(_args:Dynamic):Void {
		targetTilemap = _args.tilemap;
		hitboxPosition = new Vector2(_args.hitboxX, _args.hitboxY);
	}

	public function drawHitbox(camera:Camera, g2:Graphics):Void {
		g2.color = kha.Color.Green;
		g2.drawRect((position.x - camera.x + 1 + hitboxPosition.x) * 2,
			(position.y - camera.y - 1 + hitboxPosition.y) * 2, (dimensions.width) * 2,
			(dimensions.height) * 2, 1.0);
	}

	override public function load():Void {
		position = entity.getComponent(Position);
		dimensions = entity.getComponent(Dimensions);
		velocity = entity.getComponent(Velocity);
	}
}
