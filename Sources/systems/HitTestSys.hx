package systems;

import components.HitCircleCmp;
import haxe.ds.StringMap;
import refraction.core.Entity;
import refraction.core.Sys;
import refraction.core.Utils;

class CollisionHandler {

	public var tag1:String;
	public var tag2:String;
	public var handler:Entity -> Entity -> Void;

	public function new(_tag1:String, _tag2:String, _handler:Entity -> Entity -> Void) {
		tag1 = _tag1;
		tag2 = _tag2;
		handler = _handler;
	}
}

class HitTestSys extends Sys<HitCircleCmp> {

	var groups:StringMap<Array<HitCircleCmp>>;
	var handlers:StringMap<CollisionHandler>;

	public function new() {
		groups = new StringMap<Array<HitCircleCmp>>();
		handlers = new StringMap<CollisionHandler>();
		super();
	}

	function addToGroup(_tag:String, _hc:HitCircleCmp) {
		if (!groups.exists(_tag)) {
			groups.set(_tag, []);
		}
		groups
			.get(_tag)
			.push(_hc);
	}

	public static function getHandlerIdForTags(_tag1:String, _tag2:String):String {
		return '${_tag1}/${_tag2}';
	}

	public function onHit(_tag1:String, _tag2:String, _handler:Entity -> Entity -> Void) {
		var tag:String = getHandlerIdForTags(_tag1, _tag2);
		if (!handlers.exists(tag)) {
			handlers.set(
				tag,
				new CollisionHandler(_tag1, _tag2, _handler)
			);
		} else {
			throw 'Collision handler already exists for tags ${_tag1} and ${_tag2}';
		}
	}

	function collideShapes(c1:HitCircleCmp, c2:HitCircleCmp, _handler:Entity -> Entity -> Void) {
		if (c1.hitTest(c2)) {
			_handler(c1.entity, c2.entity);
		}
	}

	function collideGroupPair(_tag1:String, _tag2:String, _handler:Entity -> Entity -> Void) {
		var leftGroup:Array<HitCircleCmp> = groups.get(_tag1);
		var rightGroup:Array<HitCircleCmp> = groups.get(_tag2);
		if (leftGroup == null || rightGroup == null) {
			return;
		}
		var i:Int = leftGroup.length;
		while (i-- > 0) {
			if (leftGroup[i].remove) {
				Utils.quickRemoveIndex(leftGroup, i);
				continue;
			}
			var j:Int = rightGroup.length;
			while (j-- > 0) {
				if (rightGroup[j].remove) {
					Utils.quickRemoveIndex(rightGroup, j);
					continue;
				}
				collideShapes(leftGroup[i], rightGroup[j], _handler);
			}
		}
	}

	function joinOrphans() {
		for (hc in components) {
			if (!hc.remove) {
				addToGroup(hc.tag, hc);
			}
		}
		components = [];
	}

	override public function update() {
		joinOrphans();
		for (colHandler in handlers) {
			collideGroupPair(
				colHandler.tag1,
				colHandler.tag2,
				colHandler.handler
			);
		}
	}
}
