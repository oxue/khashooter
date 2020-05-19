package systems;

import refraction.core.Sys;
import components.Beacon;
import refraction.utils.Interval;
import refraction.core.Entity;
import helpers.DebugLogger;

class BeaconSys extends Sys<Beacon> {
	private var sweepTicker:Interval;

	public function new() {
		sweepTicker = new Interval(function() {
			sweepRemoved();
			DebugLogger.info("ROUTINE", "beacon system dead object sweep");
		}, Consts.BEACON_SWEEP_INTERVAL);
		super();
	}

	public function getOne(_tag:String):Entity {
		var matchingTags = components.filter(function(b:Beacon) {
			return b.tag == _tag && !b.remove;
		});
		if (matchingTags.length != 0)
			return matchingTags[0].entity;
		return null;
	}

	override public function update():Void {
		sweepTicker.tick();
	}
}
