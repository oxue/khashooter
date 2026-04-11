package net;

class SyncVar {

    public var value:Float;
    public var delta:Float;
    public var lerpValue:Float;
    public var dirty:Bool;

    public function new(initialValue:Float = 0) {
        value = initialValue;
        delta = 0;
        lerpValue = initialValue;
        dirty = false;
    }

    public function set(v:Float) {
        if (v != value) {
            value = v;
            dirty = true;
        }
    }

    public function setDelta(d:Float) {
        if (d != delta) {
            delta = d;
            dirty = true;
        }
    }

    // Call every frame for interpolation
    public function update(dt:Float) {
        value += delta * dt;
        lerpValue += (value - lerpValue) * 0.3;
    }

    // Apply remote update: [value, delta]
    public function applyRemote(v:Float, d:Float) {
        value = v;
        delta = d;
    }

    // Serialize as [value, delta]
    public function serialize():Array<Float> {
        return [value, delta];
    }
}
