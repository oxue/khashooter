package refraction.display;
import flash.display.BitmapData;

/**
 *	"Extremely Fast Line Algorithm"
 *	@author 	Po-Han Lin (original version: http://www.edepot.com/algorithm.html)
 *	@author 	Simo Santavirta (AS3 port: http://www.simppa.fi/blog/?p=521)
 *	@author 	Jackson Dunstan (minor formatting: http://jacksondunstan.com/articles/506)
 * 	@author 	skyboy (optimization for 10.1+)
 *	@param  BitmapData: bmd	Bitmap to draw on
 *	@param 	Int: x			X component of the start poInt
 *	@param 	Int: y			Y component of the start poInt
 *	@param 	Int: x2			X component of the end poInt
 *	@param 	Int: y2			Y component of the end poInt
 *	@param 	UInt: color		Color of the line
 */
class EFLA
{
	public static function efla(bmd:BitmapData, x:Int, y:Int, x2:Int, y2:Int, color:UInt):Void {
		var shortLen:Int = y2 - y;
		var longLen:Int = x2 - x;
		if (longLen==0) if (shortLen==0) return;
		var i:Int = 0, id:Int = 0, inc:Int = 0;
		var multDiff:Float;

		bmd.lock();

		// TODO: check for this above, swap x/y/len and optimize loops to ++ and -- (operators twice as fast, still only 2 loops)
		if ((shortLen ^ (shortLen >> 31)) - (shortLen >> 31) > (longLen ^ (longLen >> 31)) - (longLen >> 31)) {
			if (shortLen < 0) {
				inc = -1;
				id = -shortLen % 4;
			} else {
				inc = 1;
				id = shortLen % 4;
			}
			multDiff = shortLen==0 ? longLen : longLen / shortLen;

			if (id!=0) {
				bmd.setPixel32(x, y, color);
				i += inc;
				if (--id!=0) {
					bmd.setPixel32(Std.int(x + i * multDiff), y + i, color);
					i += inc;
					if (--id!=0) {
						bmd.setPixel32(Std.int(x + i * multDiff), y + i, color);
						i += inc;
					}
				}
			}
			while (i != shortLen) {
				bmd.setPixel32(Std.int(x + i * multDiff), y + i, color);
				i += inc;
				bmd.setPixel32(Std.int(x + i * multDiff), y + i, color);
				i += inc;
				bmd.setPixel32(Std.int(x + i * multDiff), y + i, color);
				i += inc;
				bmd.setPixel32(Std.int(x + i * multDiff), y + i, color);
				i += inc;
			}
		} else {
			if (longLen < 0) {
				inc = -1;
				id = -longLen % 4;
			} else {
				inc = 1;
				id = longLen % 4;
			}
			multDiff = longLen==0 ? shortLen : shortLen / longLen;

			if (id!=0) {
				bmd.setPixel32(x, y, color);
				i += inc;
				if (--id!=0) {
					bmd.setPixel32(x + i, Std.int(y + i * multDiff), color);
					i += inc;
					if (--id!=0) {
						bmd.setPixel32(x + i, Std.int(y + i * multDiff), color);
						i += inc;
					}
				}
			}
			while (i != longLen) {
				bmd.setPixel32(x + i, Std.int(y + i * multDiff), color);
				i += inc;
				bmd.setPixel32(x + i, Std.int(y + i * multDiff), color);
				i += inc;
				bmd.setPixel32(x + i, Std.int(y + i * multDiff), color);
				i += inc;
				bmd.setPixel32(x + i, Std.int(y + i * multDiff), color);
				i += inc;
			}
		}

		bmd.unlock();
	}
}