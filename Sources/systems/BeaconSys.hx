package systems;
import refraction.core.Sys;
import components.Beacon;
import refraction.utils.Interval;
import refraction.core.Entity;

class BeaconSys extends Sys<Beacon>
{
	private var sweepTicker:Interval;

	public function new()
	{
		sweepTicker = new Interval(function(){
			sweepRemoved();
		}, 10);
		super();
	}

	public function getOne(_tag:String):Entity
	{
		var matchingTags = components.filter(function(b:Beacon){ return b.tag == _tag; });
		if(matchingTags.length != 0) return matchingTags[0].entity;
		return null;
	}

	override public function update():Void
	{
		sweepTicker.tick();
	}
}