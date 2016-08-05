package;

import haxe.Json;
import hxblit.KhaBlit;
import hxblit.TextureAtlas.IntRect;
import kha.Assets;
import kha.Framebuffer;
import kha.network.Entity;
import kha.network.Session;
import refraction.core.Application;
import refraction.core.State;
import refraction.display.Canvas;
import refraction.ds2d.DS2D;
import refraction.ds2d.LightSource;
import refraction.ds2d.Polygon;
import refraction.tile.TilemapUtils;

/**
 * ...
 * @author 
 */
class Pos implements Entity
{
	@replicated 
	public var x:Float = 0;
	
	@replicated 
	public var y:Float = 0;
}
 
class KhaGameState extends State
{

	private var isRenderingReady:Bool;
	
	private var gameContext:GameContext;
	private var entFactory:EntFactory;
	
	private var shadowSystem:DS2D;
	
	private var pos:Pos;
	private var session:Session;
	
	public function new() 
	{
		super();
	}
	
	override public function load():Void 
	{
		super.load();
		
		isRenderingReady = false;
		
		session = new Session(2);
		
		session.waitForStart(function(){
			Assets.loadEverything(function(){
				// Init Rendering
				KhaBlit.init(Application.width, Application.height, Application.zoom);
				
				// Init Game Context
				gameContext = 
					new GameContext(
					new IntRect(0, 0, Std.int(Application.width/Application.zoom), Std.int(Application.height/Application.zoom)));
				
				// Init Ent Factory
				entFactory = new EntFactory(gameContext);
				
				shadowSystem = new DS2D();
				shadowSystem.addLightSource(new LightSource(200, 200, 0xffffff));

				loadMap("blookd");
				
				
				
				isRenderingReady = true;
			});
			
			//trace(session.me.id);
		});
	}
	
	public function loadMap(_name:String)
	{
		var obj:Dynamic = Json.parse(Assets.blobs.rooms_json.toString());
		entFactory.createTilemap(obj.data[0].length, obj.data.length, obj.tilesize, 1, obj.data);
		
		entFactory.createPlayer(obj.start.x, obj.start.y);
		
		for (p in TilemapUtils.computeGeometry(gameContext.currentTilemapData)){
			shadowSystem.polygons.push(p);
		}
		
		//shadowSystem.polygons.push(new Polygon(3, 20, 100, 100));
	}
	
	override public function update():Void 
	{
		super.update();
		
		if(gameContext != null){
			gameContext.controlSystem.update();
			gameContext.dampingSystem.update();
			gameContext.velocitySystem.update();
			gameContext.collisionSystem.update();
		}
	}
	
	override public function render(frame:Framebuffer) 
	{
		if (!isRenderingReady) return;
		
		var i:Int = 1;
		while(i-->0){
			shadowSystem.lights[i].position.x =  cast Application.mouseX / 2 + i % 4 * 2;
			shadowSystem.lights[i].position.y = cast Application.mouseY / 2 + Std.int(i/4) * 2;
		}
		var g = frame.g4;
		g.begin();
		KhaBlit.setContext(frame.g4);
		KhaBlit.clear(0.1, 0, 0, 0, 1, 1);
		KhaBlit.setPipeline(KhaBlit.KHBTex2PipelineState);
		KhaBlit.setUniformMatrix4("mproj", KhaBlit.matrix2);
		KhaBlit.setUniformTexture("tex", ResourceFormat.atlases.get("all").image);
		
		if(gameContext.currentMap != null){
			gameContext.currentMap.update();
		}
		
		gameContext.surface2RenderSystem.update();
		
		KhaBlit.draw();

		g.end();

		shadowSystem.renderHXB(gameContext);
		
	}
	
}