package refraction.utils;

// import flash.Vector;

/**
 * ...
 * @author qwerber
 */
class ObjectPool<T> {
    public var size:UInt;
    public var pool:Array<T>;

    public function new() {
        pool = new Array<T>();
        size = 0;
    }

    public function get():T {
        if (size == 0)
            return null;
        else {
            return pool[--size];
        }
    }

    public function alloc(_o:T) {
        pool.push(_o);
        size++;
    }
}
