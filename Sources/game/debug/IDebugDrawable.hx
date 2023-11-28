package game.debug;

import hxblit.Camera;
import kha.graphics2.Graphics;

interface IDebugDrawable {
	function drawDebug(camera:Camera, g2:Graphics):Void;
}
