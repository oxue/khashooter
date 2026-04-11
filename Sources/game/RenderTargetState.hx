package game;

import kha.Image;
import kha.Color;
import kha.Framebuffer;
import refraction.core.State;

class RenderTargetState extends State {

    public function new() {
        super();
    }

    override function load() {
    }

    override function update() {
    }

    override function render(frame:Framebuffer) {
        var i:Image = Image.createRenderTarget(100, 100);
        frame.g2.begin(true, Color.Black);
        frame.g2.drawImage(i, 0, 0);
        frame.g2.end();
    }
}
