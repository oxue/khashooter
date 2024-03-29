package refraction.tilemap;

import hxblit.Camera;
import kha.graphics2.Graphics;
import kha.math.Vector2;
import refraction.core.Component;
import refraction.generic.DimensionsCmp;
import refraction.generic.PositionCmp;
import refraction.generic.VelocityCmp;

class TileCollisionCmp extends Component {

	public var targetTilemap:TileMap;
	public var hitboxPosition:Vector2;

	public var position:PositionCmp;
	public var dimensions:DimensionsCmp;
	public var velocity:VelocityCmp;
	public var enabled:Bool;

	public function new() {
		enabled = true;
		super();
	}

	override public function autoParams(_args:Dynamic) {
		targetTilemap = _args.tilemap;
		hitboxPosition = new Vector2(_args.hitboxX, _args.hitboxY);
	}

	public function drawHitbox(camera:Camera, g2:Graphics) {
		g2.color = kha.Color.Green;
		g2.drawRect(
			(position.x - camera.x + 1 + hitboxPosition.x) * 2,
			(position.y - camera.y - 1 + hitboxPosition.y) * 2,
			(dimensions.width) * 2,
			(dimensions.height) * 2,
			1.0
		);
	}

	override public function load() {
		position = entity.getComponent(PositionCmp);
		dimensions = entity.getComponent(DimensionsCmp);
		velocity = entity.getComponent(VelocityCmp);
	}
}
