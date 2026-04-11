package game.weapons;

import kha.Assets;
import kha.audio1.Audio;
import entbuilders.ItemBuilder.Items;
import refraction.core.Application;
import game.GameContext;
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
        // Audio.play(Assets.sounds.sound_gun);
        lastShotClock = Application.frameClock;
        var muzzlePos = calcMuzzlePosition(_position);
        var muzzleDir = muzzleDirection(_position);
        EntFactory
            .instance()
            .createBullet(
                muzzlePos,
                muzzleDir
            );
        Application.defaultCamera.shake(6, 4);

        var gc = GameContext.instance();
        if (gc.playerEntity != null) {
            var dirDeg:Float = Math.atan2(muzzleDir.y, muzzleDir.x) * (180 / 3.1415926);
            gc.playerEntity.notify("weapon_fired", {weapon: "machinegun", x: muzzlePos.x, y: muzzlePos.y, dir: dirDeg, damage: 5});
        }
    }
}
