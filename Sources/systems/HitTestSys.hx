package systems;

import refraction.core.Sys;
import refraction.core.Entity;
import refraction.utils.Pair;
import refraction.core.Utils;
import components.HitCircle;
import haxe.ds.StringMap;

class CollisionHandler {
	public var tag1:String;
	public var tag2:String;
	public var handler:Entity->Entity->Void;

	public function new(_tag1:String, _tag2:String, _handler:Entity->Entity->Void) {
		tag1 = _tag1;
		tag2 = _tag2;
		handler = _handler;
	}
}

class HitTestSys extends Sys<HitCircle> {
	private var groups:StringMap<Array<HitCircle>>;
	private var handlers:StringMap<CollisionHandler>;

	public function new() {
		groups = new StringMap<Array<HitCircle>>();
		handlers = new StringMap<CollisionHandler>();
		super();
	}

	private function addToGroup(_tag:String, _hc:HitCircle):Void {
		if (!groups.exists(_tag)) {
			groups.set(_tag, new Array<HitCircle>());
		}
		groups
			.get(_tag)
			.push(_hc);
	}

	public function onHit(_tag1:String, _tag2:String, _handler:Entity->Entity->Void):Void {
		var tag = '${_tag1}/${_tag2}';
		if (!handlers.exists(tag)) {
			handlers.set(tag, new CollisionHandler(_tag1, _tag2, _handler));
		}
	}

	private function collideShapes(c1:HitCircle, c2:HitCircle, _handler:Entity->Entity->Void):Void {
		if (c1.hitTest(c2)) {
			_handler(c1.entity, c2.entity);
		}
	}

	private function collideGroupPair(_tag1:String, _tag2:String, _handler:Entity->Entity->Void):Void {
		var leftGroup = groups.get(_tag1);
		var rightGroup = groups.get(_tag2);
		if (leftGroup == null || rightGroup == null) {
			return;
		}
		var i = leftGroup.length;
		while (i-- > 0) {
			if (leftGroup[i].remove) {
				Utils.quickRemoveIndex(leftGroup, i);
				continue;
			}
			var j = rightGroup.length;
			while (j-- > 0) {
				if (rightGroup[j].remove) {
					Utils.quickRemoveIndex(rightGroup, j);
					continue;
				}
				collideShapes(leftGroup[i], rightGroup[j], _handler);
			}
		}
	}

	private function joinOrphans():Void {
		for (hc in components) {
			if (!hc.remove) {
				addToGroup(hc.tag, hc);
			}
		}
		components = [];
	}

	override public function update():Void {
		joinOrphans();
		for (colHandler in handlers) {
			collideGroupPair(colHandler.tag1, colHandler.tag2, colHandler.handler);
		}
	}
}
