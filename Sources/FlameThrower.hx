package ;
import flash.geom.Point;
import refraction.core.Application;
import refraction.display.AnimatedRender;
import refraction.ds2d.LightSource;
import refraction.generic.Position;

/**
 * ...
 * @author qwerber
 */

class FlameThrower extends Weapon
{

	private var timer:Int;
	private var t:Int;
	private var canCast:Bool;
	
	public function new() 
	{
		timer = 3;
		super(1, "FlameThrower");
	}
	
	override public function getAmmo(_i:Inventory):Void 
	{
		ammo = _i.primaryAmmo;
	}
	
	override public function setAnimation(_anim:AnimatedRender):Void 
	{
		_anim.curAnimaition = 4;
		_anim.frame = 0;
	}
	
	override public function update():Void
	{
		if (t < 100)
		t++;
		if (t >= timer)
		{
			canCast = true;
		}
	}
	
	override public function persistCast(_position:Position):Void 
	{
		if (!canCast)
		return;
		var p:Point = new Point(Application.mouseX / 2 + cast(Application.currentState, GameState).canvas.camera.x - _position.x - 10, 
								Application.mouseY / 2 + cast(Application.currentState, GameState).canvas.camera.y - _position.y - 10);
		p.x *= 400;
		p.y *= 400;
		var p3:Point = p.clone();
		p3.normalize(6);
		var px:Int = cast _position.x + 10 - p3.y + p3.x;
		var py:Int = cast _position.y + 10 + p3.x + p3.y;
		Factory.createFireball(px-5, py-5,_position.x + p.x-5,_position.y + p.y-5);
		var l:LightSource = new LightSource(cast px, py, 0xaaaa77,50);
		l.remove = true;
		cast(Application.currentState, GameState).shadowSystem.addLightSource(l);
		t = 0;
		canCast = false;
	}
	
}