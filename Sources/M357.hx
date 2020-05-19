package;

import flash.geom.Point;
import refraction.core.Component;
import refraction.core.Application;
import refraction.display.AnimatedRender;
import refraction.ds2d.LightSource;
import refraction.generic.Position;
import refraction.display.BlitComponentC;

/**
 * ...
 * @author worldedit
 */
class M357 extends Weapon {
	private var timer:Int;
	private var t:Int;
	private var canCast:Bool;

	public function new() {
		timer = 14;
		super(0, "M357");
	}

	override public function setAnimation(_anim:AnimatedRender):Void {
		_anim.curAnimaition = 2;
		_anim.frame = 0;
	}

	override public function getAmmo(_i:Inventory):Void {
		ammo = _i.secondaryAmmo;
	}

	override public function castWeapon(_position:Position):Void {
		if (!canCast)
			return;
		if (ammo.requestRound(1) != 1) {
			ammo.reload();
			return;
		}
		var p:Point = new Point(Application.mouseX / 2
			+ cast(Application.currentState, GameState)
				.canvas.camera.x
			- _position.x,
			Application.mouseY / 2
			+ cast(Application.currentState, GameState)
				.canvas.camera.y
			- _position.y);
		p.normalize(400);
		var p2:Point = p.clone();
		p2.normalize(20);
		p.x *= 400;
		p.y *= 400;
		var p3:Point = p.clone();
		p3.normalize(3);
		Factory.createBullet(_position.x + 10 + p2.x - p3.y, _position.y + 10 + p2.y + p3.x,
			_position.x + p.x, _position.y + p.y, 200);
		var l:LightSource = new LightSource(cast _position.x + 10, cast _position.y + 10, 0xffff77);
		l.remove = true;
		cast(Application.currentState, GameState)
			.shadowSystem.addLightSource(l);
		t = 0;
		canCast = false;
	}

	override public function update():Void {
		if (t < 100)
			t++;
		if (t >= timer) {
			canCast = true;
		}
	}

	override public function persistCast(_position:Position):Void {}
}
