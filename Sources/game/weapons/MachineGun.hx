package game.weapons;

import kha.Assets;
import kha.audio1.Audio;
import entbuilders.ItemBuilder.Items;
import refraction.core.Application;
import refraction.generic.PositionCmp;

class MachineGun extends Weapon {

	var lastShotClock:Int;
	var cooldown:Int;

	public function new() {
		super(Items.MachineGun);

		cooldown = 5;
		lastShotClock = 0;
	}

	override public function persistCast(_position:PositionCmp) {
		if (Application.frameClock - lastShotClock < cooldown) {
			return;
		}
		Audio.play(Assets.sounds.sound_gun);
 		lastShotClock = Application.frameClock;
		EntFactory
			.instance()
			.createBullet(calcMuzzlePosition(_position), muzzleDirection(_position));
		Application.defaultCamera.shake(6, 4);
	}
}
