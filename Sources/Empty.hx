package;

import kha.Canvas;
import kha.Framebuffer;
import kha.Color;
import kha.System;
import kha.Scheduler;

class Empty {

    public function new() {
		System.notifyOnRender(render);
		//Scheduler.addTimeTask(update, 0, 1 / 60);
		
	}

    public function render(frame:Framebuffer) {
        // A graphics object which lets us perform 3D operations
        var g = frame.g4;
        // Begin rendering
        g.begin();
        // Clear screen to black
        g.clear(Color.Red);
        // End rendering
        g.end();
    }
}
