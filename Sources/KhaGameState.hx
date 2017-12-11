package;

import haxe.Json;
import hxblit.KhaBlit;
import hxblit.TextureAtlas.IntRect;
import kha.Assets;
import kha.Framebuffer;
import refraction.core.Application;
import refraction.core.State;
import refraction.ds2d.LightSource;
import refraction.generic.PositionComponent;
import refraction.tile.TilemapUtils;
import kha.Color;
import zui.*;

/**
 * ...
 * @author 
 */
 
class KhaGameState extends refraction.core.State
{

	private var isRenderingReady:Bool;
	
	private var gameContext:GameContext;
	private var entFactory:EntFactory;
	
	private var ui:Zui;
	private var showMenu:Bool = false;
	private var mouse2WasDown:Bool = false;
	private var menuX:Int;
	private var menuY:Int;
	
	public function new() 
	{
		super();
	}
	
	override public function load():Void 
	{
		super.load();
		
		isRenderingReady = false;
		
		Assets.loadEverything(function(){
			// Init Rendering
			KhaBlit.init(Application.width, Application.height, Application.zoom);
			
			ui = new Zui({font: Assets.fonts.OpenSans, khaWindowId:0, scaleFactor:1});
			
			var gameCamera = 
				new IntRect(0, 0, Std.int(Application.width/Application.zoom), Std.int(Application.height/Application.zoom));

			// Init Game Context
			gameContext = new GameContext(
				gameCamera,
				ui
			);
			
			// Init Ent Factory
			entFactory = new EntFactory(gameContext);
			
			// Init Lighting 
			var i = 1;
			while(i-->0)
			gameContext.lightingSystem.addLightSource(new LightSource(100, 100, 0x111111));
			
			// load map
			loadMap("blookd");
			
			isRenderingReady = true;
		});
	}
	
	public function loadMap(_name:String)
	{
		var obj:Dynamic = Json.parse(Assets.blobs.rooms_json.toString());
		entFactory.createTilemap(obj.data[0].length, obj.data.length, obj.tilesize, 1, obj.data, "all_tiles");
		
		entFactory.createPlayer(obj.start.x, obj.start.y);
		entFactory.createItem(obj.start.x, obj.start.y);
		
		var i:Int = obj.lights.length;
		while (i-->0){
			gameContext.lightingSystem.addLightSource(new LightSource(obj.lights[i].x, obj.lights[i].y, obj.lights[i].color, obj.lights[i].radius));
		}
		entFactory.createNPC(obj.start.x, obj.start.y, "mimi");
		//entFactory.createZombie(obj.start.x, obj.start.y);
		
		for (p in TilemapUtils.computeGeometry(gameContext.currentTilemapData)){
			gameContext.lightingSystem.polygons.push(p);
		}
		
	}
	
	// =========
	// MAIN LOOP 
	// =========
	
	override public function update():Void 
	{
		super.update();
		
		if (gameContext != null){
			
			gameContext.controlSystem.update();
			gameContext.spacingSystem.update();
			gameContext.dampingSystem.update();
			gameContext.velocitySystem.update();
			gameContext.collisionSystem.update();
			gameContext.lightSourceSystem.update();
			
			gameContext.npcSystem.update();
			gameContext.breadCrumbsSystem.update();
			gameContext.aiSystem.update();
		}
	}
	
	override public function render(frame:Framebuffer) 
	{
		if (!isRenderingReady) return;
		
		var playerPos:PositionComponent = cast gameContext.playerEntity.components.get("pos_comp");
		
		gameContext.cameraRect.x += Std.int((playerPos.x - 200 - gameContext.cameraRect.x)/8);
		gameContext.cameraRect.y += Std.int((playerPos.y - 100 - gameContext.cameraRect.y)/8);
		
		gameContext.worldMouseX = cast Application.mouseX / 2 + gameContext.cameraRect.x;
		gameContext.worldMouseY = cast Application.mouseY / 2 + gameContext.cameraRect.y;
		
		var i:Int = 0;
		//if (Application.mouseIsDown) i = 2;
		while(i-->0){
			gameContext.lightingSystem.lights[i].position.x =  cast Application.mouseX / 2 + gameContext.cameraRect.x + Std.int(i/4) * 2;
			gameContext.lightingSystem.lights[i].position.y = cast Application.mouseY / 2 + gameContext.cameraRect.y + i%4 * 2;
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

		gameContext.lightingSystem.renderHXB(gameContext);
		
		
		//UI
		if (!mouse2WasDown && Application.mouse2IsDown)
		{
			showMenu = !showMenu;
			menuX = Application.mouseX + 5;
			menuY = Application.mouseY;
		}
		
		
		// ========== UI BEGIN ==========
		ui.begin(frame.g2);

		gameContext.tooltipSystem.update(frame.g2);

		if (showMenu){
			var worldMenuX:Int = cast menuX / 2 + gameContext.cameraRect.x;
			var worldMenuY:Int = cast menuY / 2 + gameContext.cameraRect.y;
			
			if (ui.window(Id.handle(), menuX, menuY, 200, 300, false)) {
				
				if (ui.button("Teleport Here")){
					showMenu = false;
					playerPos.x = worldMenuX;
					playerPos.y = worldMenuY;
				}
				
				if (ui.button("Spawn Hell Minion")) {
					showMenu = false;
					entFactory.createZombie(worldMenuX,
											worldMenuY);
				}
				
				if (ui.button("Spawn light Source")) {
					showMenu = false;
					gameContext.lightingSystem.addLightSource(new LightSource(worldMenuX, worldMenuY,
						[Color.Cyan, Color.Orange, Color.Pink, Color.White,Color.Green, Color.Yellow, Color.Red][Std.int(Math.random() * 7)].value & 0xFFFFFF));
				}
				gameContext.lightingSystem.setAmbientLevel(
					ui.slider(Id.handle({value: gameContext.lightingSystem.getAmbientLevel()}), "Ambient Level", 0, 1, false, 100, true));

			}
		}
		ui.end();
		
		
		mouse2WasDown = Application.mouse2IsDown;
		//gameContext.statusText.render(frame.g2);
		
	}
	
}