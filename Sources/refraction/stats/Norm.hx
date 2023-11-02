package refraction.stats;

function randNorm(mean:Float, std:Float = 1):Float {
	var bm:Array<Float> = boxMuller();
	var z0:Float = bm[0];
	var z1:Float = bm[1];
	return mean + z0 * std;
}

function boxMuller():Array<Float> {
	var u1:Float = Math.random();
	var u2:Float = Math.random();
	var z0:Float = Math.sqrt(-2 * Math.log(u1)) * Math.cos(2 * Math.PI * u2);
	var z1:Float = Math.sqrt(-2 * Math.log(u1)) * Math.sin(2 * Math.PI * u2);

	return [z0, z1];
}
