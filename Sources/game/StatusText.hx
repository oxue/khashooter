package game;

import kha.Assets;
import kha.graphics2.Graphics;

/**
 * ...
 * @author
 */
class StatusText {
	public var text:String;
	public var x:Int;
	public var y:Int;

	public function new() {
		x = y = 0;
		text = "";
	}

	public function render(g2:Graphics) {
		if (text != "") {
			g2.begin(false);
			g2.font = Assets.fonts.OpenSans;
			g2.fontSize = 32;
			g2.drawString(text, x, y);
			g2.end();
		}
	}
}
