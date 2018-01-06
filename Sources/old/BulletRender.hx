package ;
import refraction.core.Component;
import refraction.display.Canvas;
import refraction.display.EFLA;
import refraction.generic.Position;

/**
 * ...
 * @author worldedit
 */

class BulletRender extends Component
{

	public var position:Position;
	public var projectile:LineProjectile;
	
	public var targetCanvas:Canvas;
	
	public function new() 
	{
		super("asdd");
	}
	
	override public function load():Void 
	{
		projectile = cast entity.components.get("proj_comp");
		position = cast entity.components.get("pos_comp");
	}
	
	override public function update():Void 
	{
		EFLA.efla(targetCanvas.displayData, 
				  cast position.oldX - targetCanvas.camera.x, 
				  cast position.oldY - targetCanvas.camera.y, 
				  cast projectile.collidePoint.x - targetCanvas.camera.x, 
				  cast projectile.collidePoint.y - targetCanvas.camera.y, 
				  0x33ffff00);
	}
	
}