package;

import haxe.Json;
import haxe.Timer;
import hxblit.KhaBlit;
import hxblit.Surface2;
import hxblit.TextureAtlas;
import hxblit.Utils;
import kha.Assets;
import kha.Color;
import kha.FastFloat;
import kha.Framebuffer;
import kha.Image;
import kha.math.FastVector2;
import refraction.core.Application;
import refraction.core.Entity;
import refraction.core.State;
import refraction.display.Canvas;
import refraction.display.Surface2RenderComponentC;
import refraction.display.Surface2SetComponent;
import refraction.generic.DimensionsComponent;
import refraction.generic.PositionComponent;
import refraction.generic.TransformComponent;
import refraction.tile.Surface2TileRenderComponent;

/**
 * ...
 * @author ...
 */
class KhaBlitTestState extends State
{
	private var paused:Bool;
	private var atlas:TextureAtlas;
	private var baked:Image;
	private var isFirstRun:Bool = true;
	
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
	
	private var te:Entity;
	
	private function start():Void
	{
		paused = false;
		// There is no need for a callback in KhaBlit, that part is done by Kha's System::init
		KhaBlit.init(
			Application.width, 
			Application.height, 
			Application.zoom);
		
		trace("unpaused");
		
		if (isFirstRun)
		{
			trace("ASD");
			isFirstRun = false;
			trace("first run");
			/*atlas = new TextureAtlas();
			//baked = TextureAtlas.bakeForAnimation(Assets.images.zombie,new IntRect(0,0,20,20),8);
		
			atlas.add(TextureAtlas.bakeForAnimation(Assets.images.zombie,new IntRect(0,0,20,20),8), 0);
			atlas.add(TextureAtlas.bakeForAnimation(Assets.images.man,new IntRect(0,0,20,20),8), 1);
			atlas.add(Assets.images.weapons, 2);
			atlas.add(Assets.images.tilesheet, 3);
			atlas.binpack(); 
			*/
			EntFactory.init();
			EntFactory.beginAtlas("new");
			var fm = EntFactory.formatTileSheet("ts", Assets.images.tilesheet, 16);
			r = EntFactory.formatRotatedSprite("zom", Assets.images.zombie, 20, 20);
			//var r2 = EntFactory.formatRotatedSprite("man", Assets.images.man, new IntRect(0, 0, 20, 20));
			//var r3 = EntFactory.formatRotatedSprite("weap", Assets.images.weapons, new IntRect(0, 0, 36, 20));
			EntFactory.endAtlas();
			
			e = new Entity();
			e.addDataComponent(new PositionComponent(10, 10));
			e.addDataComponent(new DimensionsComponent(20, 20));
			e.addDataComponent(t = new TransformComponent());
			e.addDataComponent(r);
			
			s2r = new Surface2RenderComponentC();
			e.addActiveComponent(s2r);
			s2r.animations[0] = [0,1,0,2];
			s2r.frame = 0;
			s2r.frameTime = 10;
			s2r.curAnimaition = 0;
			s2r.targetCamera = new Canvas(400, 200, 2);
			//trace(EntFactory.atlases.get("new").assets.get(0));
			var obj:Dynamic = Json.parse(Assets.blobs.bloodstrike_zm_json.toString());
			
			te = EntFactory.createTilemap(obj.data[0].length, obj.data.length, obj.tilesize, 1, obj.data, fm);
		}
	}
	
	private var e:Entity;
	private var s2r:Surface2RenderComponentC;
	private var t:TransformComponent;
	private var r:Surface2SetComponent;
	
	override public function render(frame:Framebuffer) 
	{
		var f:Float = Timer.stamp();
		if (paused) return;
		
		var g = frame.g4;
		g.begin();
		KhaBlit.setContext(frame.g4);
		KhaBlit.clear(0.1, 0, 0, 0, 1, 1);
		KhaBlit.setPipeline(KhaBlit.KHBTex2PipelineState);
		KhaBlit.setUniformMatrix4("mproj", KhaBlit.matrix2);
		KhaBlit.setUniformTexture("tex", EntFactory.atlases.get("new").image);
		
		
		//var im:Surface2 = atlas.assets.get(0);
		var i:Int = 4096;
		//while(i-->0)
		//KhaBlit.blit(atlas.assets.get(0), Application.mouseX/2, Application.mouseY/2);
		//KhaBlit.blit(atlas.assets.get(1), 100, 0);
		/*KhaBlit.blit(atlas.assets.get(2), 100, 100);
		KhaBlit.blit(atlas.assets.get(3), 0, 100);
		KhaBlit.blit(atlas.assets.get(4), 0, 0);*/
		cast(te.components.get("surface2tilerender_comp"), Surface2TileRenderComponent).update();
		t.rotation += 3;
		s2r.update();
		var i:Int = 0;
		while (i < r.indexes.length){
			//KhaBlit.blit(r.surfaces[i], i%32 * 20, Std.int(i/32) * 25);
			i++;
		}
		
		KhaBlit.draw();

        g.end();	
		
		frame.g2.begin(false);
		//frame.g2.drawImage(atlas.image, 0, 0);
		
		//frame.g2.drawImage(EntFactory.atlases.get("new").image, 400, 0);
		frame.g2.end();
		//trace(Std.int((Timer.stamp() - f)*1000));
	}
	
}