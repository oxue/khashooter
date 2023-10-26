package refraction.core;

import haxe.Constraints.Constructible;
import refraction.core.Entity;

class NullSystem<T:Component> {
	public function new() {}

	@:generic
	public function procure<G:Constructible<Dynamic> & T>(e:Entity, _type:Class<G>):G {
		var ret:G = null;
		e.addComponent(ret);
		return ret;
	}
}

/**
 * ...
 * @author worldedit
 */
@:generic
class Sys<T:Component> {
	public var components:Array<T>;

	private var l:Int;

	public function new() {
		components = new Array<T>();
	}

	@:generic
	public function procure<G:Constructible<Dynamic> & T & Component>
		(
			e:Entity, 
			_type:Class<G>,
			_name:String = null,
			_default:G = null
		):G {
		var ret:G = cast produce();
		if (ret == null) {
			ret = _default;
		}
		if (ret == null) {
			var instance: G = Type.createInstance(_type, []);
			ret = instance;
		}
		e.addComponent(ret, _name);
		addComponent(ret);
		return ret;
	}

	public function sweepRemoved() {
		components = components.filter(function(c) return !c.remove);
	}

	public function removeIndex(_i:Int, _pool:Array<T> = null):Void {
		if (_pool != null) {
			components[_i].reset();
			_pool.push(components[_i]);
		}
		components[_i] = components[components.length - 1];
		components.pop();
	}

	public function produce():T {
		return null;
	}

	public inline function addComponent(_c:T):Void {
		components.push(_c);
	}

	public function updateComponent(comp:T) {
		// abstract function
		comp.update();
	}

	public function update():Void {
		l = components.length;
		var i:Int = 0;
		while (i < l) {
			var c:T = components[i];
			if (components[i].remove) {
				components[i] = components[--l];
				continue;
			}
			updateComponent(c);
			++i;
		}
		while (components.length > l) {
			components.pop();
		}
	}
}
