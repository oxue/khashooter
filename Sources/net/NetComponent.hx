package net;

import refraction.core.Component;

class NetComponent extends Component {

    public var netIdentity:NetIdentity;

    public function new() {
        super();
    }

    override public function load() {
        netIdentity = entity.getComponent(NetIdentity);
    }
}
