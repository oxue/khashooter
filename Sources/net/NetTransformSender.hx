package net;

import refraction.generic.PositionCmp;

class NetTransformSender extends NetComponent {

    var position:PositionCmp;

    public function new() {
        super();
    }

    override public function load() {
        super.load();
        position = entity.getComponent(PositionCmp);
    }

    override public function update() {
        if (position == null || netIdentity == null) return;
        var netState = game.GameContext.instance().netState;
        if (netState == null) return;
        netState.localPosX.set(position.x);
        netState.localPosY.set(position.y);
        netState.localRotation.set(position.rotationDegrees);
    }
}
