package systems;
import refraction.core.Sys;
import components.Beacon;
import refraction.utils.FrameInterval;

class BeaconSys extends Sys<Beacon>
{
	private var sweepTicker:FrameInterval;

	public function new()
	{
		sweepTicker = new FrameInterval(function(){
			sweepRemoved();
		}, 10);
		super();
	}

	override public function update():Void
	{
		sweepTicker.tick();
	}
}