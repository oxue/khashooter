package net;

class NetShootSender extends NetComponent {

    override public function load() {
        super.load();
        entity.on("weapon_fired", onWeaponFired);
    }

    function onWeaponFired(data:Dynamic) {
        var netState = game.GameContext.instance().netState;
        if (netState != null && netState.isConnected()) {
            netState.sendShoot(data.weapon, data.x, data.y, data.dir, data.damage);
        }
    }
}
