package net;

import refraction.display.AnimatedRenderCmp;
import refraction.generic.PositionCmp;

class NetTransformReceiver extends NetComponent {

    public var posX:SyncVar;
    public var posY:SyncVar;
    public var rotation:SyncVar;
    var position:PositionCmp;
    var animCmp:AnimatedRenderCmp;
    var lastAnimState:String;

    public function new() {
        super();
        posX = new SyncVar(0);
        posY = new SyncVar(0);
        rotation = new SyncVar(0);
        lastAnimState = "idle";
    }

    override public function load() {
        super.load();
        position = entity.getComponent(PositionCmp);
        animCmp = entity.getComponent(AnimatedRenderCmp);

        // Subscribe to position updates via entity message system
        entity.on("net:pos", function(data:Dynamic) {
            if (data.x != null) posX.applyRemote(data.x, 0);
            if (data.y != null) posY.applyRemote(data.y, 0);
            if (data.rot != null) rotation.applyRemote(data.rot, 0);
        });
    }

    override public function update() {
        if (position == null) return;
        posX.update(1.0 / 60.0);
        posY.update(1.0 / 60.0);
        rotation.update(1.0 / 60.0);

        position.x = posX.lerpValue;
        position.y = posY.lerpValue;
        position.rotationDegrees = rotation.lerpValue;

        // Animation sync based on position delta
        if (animCmp != null) {
            var isMoving = Math.abs(posX.value - posX.lerpValue) > 0.5 || Math.abs(posY.value - posY.lerpValue) > 0.5;
            var newAnim = isMoving ? "running" : "idle";
            if (newAnim != lastAnimState) {
                animCmp.curAnimation = newAnim;
                animCmp.frame = 0;
                lastAnimState = newAnim;
            }
        }
    }
}
