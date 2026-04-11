package game.debug;

import rendering.Camera;
import kha.graphics2.Graphics;

interface IDebugDrawable {
    function drawDebug(camera:Camera, g2:Graphics):Void;
}
