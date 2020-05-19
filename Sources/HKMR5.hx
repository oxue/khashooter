package;

import flash.filters.ConvolutionFilter;
import flash.geom.Point;
import refraction.core.Component;
import refraction.core.Application;
import refraction.display.BlitComponentC;
import refraction.display.AnimatedRender;
import refraction.ds2d.LightSource;
import refraction.generic.Position;

/**
 * ...
 * @author worldedit
 */
class HKMR5 extends Weapon {
	private var timer:Int;
	private var t:Int;
	private var canCast:Bool;

	public function new() {
		timer = 3;
		super(1, "HKMR5");
	}

	override public function castWeapon(_position:Position):Void {}

	override public function getAmmo(_i:Inventory):Void {
		ammo = _i.primaryAmmo;
	}

	override public function setAnimation(_anim:AnimatedRender):Void {
		_anim.curAnimaition = 3;
		_anim.frame = 0;
	}

	override public function update():Void {
		if (t < 100)
			t++;
		if (t >= timer) {
			canCast = true;
		}
	}

	override public function persistCast(_position:Position):Void {
		if (!canCast)
			return;
		if (ammo.requestRound(1) != 1) {
			ammo.reload();
			return;
		}
		var p:Point = new Point(Application.mouseX / 2
			+ cast(Application.currentState, GameState)
				.canvas.camera.x
			- _position.x
			- 10,
			Application.mouseY / 2
			+ cast(Application.currentState, GameState)
				.canvas.camera.y
			- _position.y
			- 10);
		p.normalize(18);
		var fx:Float = p.x;
		var fy:Float = p.y;
		p.normalize(400);
		p.x *= 400;
		p.y *= 400;
		var p3:Point = p.clone();
		p3.normalize(3);
		var px:Int = cast _position.x + 10 - p3.y + fx;
		var py:Int = cast _position.y + 10 + p3.x + fy;
		Factory.createBullet(px, py, _position.x + p.x + 10, _position.y + p.y + 10, 20);
		var l:LightSource = new LightSource(Std.int(px + fx), Std.int(py + fy), 0xffff77, 20);
		l.remove = true;
		// cast(Application.currentState, GameState).shadowSystem.addLightSource(l);
		t = 0;
		canCast = false;
	}
}
