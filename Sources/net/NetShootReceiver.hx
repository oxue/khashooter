package net;

class NetShootReceiver extends NetComponent {

    override public function load() {
        super.load();
        entity.on("net:shoot", onRemoteShoot);
    }

    function onRemoteShoot(data:Dynamic) {
        var rad:Float = data.dir * (Math.PI / 180);
        var dirVec = new kha.math.Vector2(Math.cos(rad), Math.sin(rad));
        var posVec = new kha.math.Vector2(data.x, data.y);
        var ef = game.EntFactory.instance();
        if (ef == null) return;

        if (data.weapon == "crossbow") ef.createProjectile(posVec, dirVec);
        else if (data.weapon == "machinegun") ef.createBullet(posVec, dirVec);
        else if (data.weapon == "flamethrower") ef.createFireball(posVec, dirVec);
    }
}
