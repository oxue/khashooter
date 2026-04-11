package net;

import refraction.core.Component;

class NetIdentity extends Component {

    public var netId:String;
    public var ownerId:Int;
    public var isLocal:Bool;

    public function new(netId:String, ownerId:Int, isLocal:Bool) {
        super();
        this.netId = netId;
        this.ownerId = ownerId;
        this.isLocal = isLocal;
    }

    override public function load() {
        NetManager.instance().register(netId, entity);
    }

    override public function unload() {
        NetManager.instance().deregister(netId);
    }
}
