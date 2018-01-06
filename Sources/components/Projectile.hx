package components;

import kha.math.Vector2;
import refraction.tile.TilemapData;
import refraction.core.Component;
import refraction.generic.Position;
import refraction.generic.Velocity;


/**
 * ...
 * @author 
 */
class Projectile extends Component
{
	private var position:Position;
	public var tilemapData:TilemapData;
	
	public function new(_tilemapData:TilemapData) 
	{
		tilemapData = _tilemapData;
		super();
	}
	
	override public function load():Void 
	{
		position = entity.getComponent(Position);
		this.on("collided", function(data){
			entity.remove();
		});
	}

	override public function update():Void
	{
		//position.x = position.y = 0;
		if(tilemapData.hitTestPoint(new Vector2(position.x, position.y))){
			entity.remove();
			//entity.getComponent(Velocity).remove = true;
			//this.remove = true;
		}
	}
	
}