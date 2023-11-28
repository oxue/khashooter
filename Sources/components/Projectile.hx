package components;

import game.CollisionBehaviours.MSG_COLLIDED;
import kha.math.Vector2;
import refraction.core.Component;
import refraction.generic.PositionCmp;
import refraction.tilemap.TileMap;

/**
 * ...
 * @author
 */
class Projectile extends Component {

	var position:PositionCmp;

	public var tilemapData:TileMap;

	public function new(_tilemapData:TileMap) {
		tilemapData = _tilemapData;
		super();
	}

	override public function load() {
		position = entity.getComponent(PositionCmp);
		this.on(MSG_COLLIDED, function(data) {
			entity.remove();
		});
	}

	override public function update() {
		if (tilemapData.hitTestPoint(new Vector2(position.x, position.y))) {
			entity.remove();
		}
	}
}
