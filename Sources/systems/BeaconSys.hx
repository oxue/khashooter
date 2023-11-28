package systems;

import components.Beacon;
import game.Consts;
import helpers.DebugLogger;
import refraction.core.Entity;
import refraction.core.Sys;
import refraction.utils.Interval;

class BeaconSys extends Sys<Beacon> {

	var sweepTicker:Interval;

	public function new() {
		sweepTicker = new Interval(
			function() {
				sweepRemoved();
				// DebugLogger.info("ROUTINE", "beacon system dead object sweep");
			},
			Consts.BEACON_SWEEP_INTERVAL
		);
		super();
	}

	public function getOne(_tag:String):Entity {
		var matchingTags:Array<Beacon> = components.filter(function(b:Beacon) {
			return b.tag == _tag && !b.remove;
		});
		if (matchingTags.length != 0) {
			return matchingTags[0].entity;
		}
		return null;
	}

	override public function update() {
		sweepTicker.tick();
	}
}
