package;

import hxblit.KhaBlit;
import hxblit.Utils;
import kha.Assets;
import kha.Color;
import kha.Framebuffer;
import refraction.core.Application;
import refraction.core.State;

/**
 * ...
 * @author ...
 */
class KhaBlitTestState extends State
{
	private var paused:Bool;

	public function new() 
	{
		super();
	}
	
	override public function load():Void 
	{
		// Pause so we can do our HXB initialization
		paused = true;
		
		Assets.loadEverything(start);
	}
	
	private function start():Void
	{
		// There is no need for a callback in KhaBlit, that part is done by Kha's System::init
		KhaBlit.init(
			Utils.nbpo2(Application.width), 
			Utils.nbpo2(Application.height), 
			Application.zoom);
		paused = false;
	}
	
	override public function render(frame:Framebuffer) 
	{
		if (paused) return;
		
		var g = frame.g4;
		g.begin();
		KhaBlit.setContext(frame.g4);
		KhaBlit.clear(0, 0, 0, 0, 1, 1);
		KhaBlit.setPipeline(KhaBlit.KHBTex2PipelineState);
		KhaBlit.setUniformMatrix4("mproj", KhaBlit.matrix2);
		KhaBlit.setUniformTexture("tex", Assets.images.tilesheet);
		
		KhaBlit.blit(
        g.end();
	}
	
}