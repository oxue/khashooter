package;

import haxe.Json;
import hxblit.KhaBlit;
import hxblit.Camera;
import kha.Assets;
import kha.Framebuffer;
import refraction.core.Application;
import refraction.core.State;
import refraction.ds2d.LightSource;
import refraction.generic.Position;
import refraction.tile.TilemapUtils;

import kha.Color;
import kha.input.Mouse;
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
	private var drawHitBoxes:Bool = false;
	private var mouse2WasDown:Bool = false;
	private var menuX:Int;
	private var menuY:Int;
	
	public function new() 
	{
		super();
	}
	
	private function loadResources():Void{
		ResourceFormat.init();
		ResourceFormat.beginAtlas("all");

		ResourceFormat.formatTileSheet("all_tiles", Assets.images.tilesheet, 16);
		ResourceFormat.formatTileSheet("modern", Assets.images.modern, 16);

		ResourceFormat.formatRotatedSprite("man", Assets.images.man, 26, 26).addTranslation(3,3);
		ResourceFormat.formatRotatedSprite("weapons", Assets.images.weapons, 36, 20).addTranslation(8, 0);
		ResourceFormat.formatRotatedSprite("mimi", Assets.images.mimi, 26, 26).addTranslation(3, 3);
		ResourceFormat.formatRotatedSprite("zombie", Assets.images.zombie, 32, 32).addTranslation(6, 6);
		ResourceFormat.formatRotatedSprite("shiro", Assets.images.shiro, 26, 26).addTranslation(3, 3);
		ResourceFormat.formatRotatedSprite("items", Assets.images.items, 32, 32);
		ResourceFormat.formatRotatedSprite("gyo", Assets.images.gyo, 29, 24).addTranslation(3, 4);
		ResourceFormat.formatRotatedSprite("weapons", Assets.images.crossbow ,26,26).addTranslation(3, 3).registration(-13,-6);
		ResourceFormat.formatRotatedSprite("projectiles", Assets.images.projectiles ,20,20).registration(10,10);
		
		ResourceFormat.endAtlas();
	}

	override public function load():Void 
	{
		super.load();
		
		isRenderingReady = false;
		
		Assets.loadEverything(function(){
			// Init Rendering
			KhaBlit.init(Application.width, Application.height, Application.zoom);
			
			Mouse.get().notify(mouseDown, null, null, null);

			ui = new Zui({font: Assets.fonts.OpenSans, khaWindowId:0, scaleFactor:1});
			
			var gameCamera = 
				new Camera(Std.int(Application.width/Application.zoom), Std.int(Application.height/Application.zoom));

			// Init Game Context
			gameContext = new GameContext(
				gameCamera,
				ui
			);

			Application.defaultCamera = gameCamera;

			// Load resources
			loadResources();
			
			// Init Ent Factory
			entFactory = EntFactory.instance(gameContext);
			
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
		var obj:Dynamic = Json.parse(Assets.blobs.modern_home_json.toString());
		entFactory.createTilemap(obj.data[0].length, obj.data.length, obj.tilesize, 1, obj.data, "modern");
		
		entFactory.createPlayer(obj.start.x, obj.start.y);
		entFactory.createItem(obj.start.x, obj.start.y);
		
		var i:Int = obj.lights.length;
		while (i-->0){
			gameContext.lightingSystem.addLightSource(new LightSource(obj.lights[i].x, obj.lights[i].y, obj.lights[i].color, obj.lights[i].radius));
		}
		entFactory.createNPC(obj.start.x, obj.start.y, "mimi");
		//entFactory.createZombie(obj.start.x, obj.start.y);
		
		for (p in TilemapUtils.computeGeometry(gameContext.tilemapData)){
			gameContext.lightingSystem.polygons.push(p);
		}
		
	}

	private function mouseDown(button:Int, x:Int, y:Int)
	{
		if (button == 0)
		{
			gameContext.interactSystem.update();
			var playerPos:Position = cast gameContext.playerEntity.getComponent(Position);
			
			gameContext.camera.shake(3,2);
			gameContext.playerEntity.getComponent(InventoryComponent).primary();		
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
			
			gameContext.breadCrumbsSystem.update();

			gameContext.hitCheckSystem.update();
			gameContext.aiSystem.update();
		}
	}
	
	override public function render(frame:Framebuffer) 
	{
		if (!isRenderingReady) return;
		
		gameContext.camera.updateShake();

		var playerPos:Position = cast gameContext.playerEntity.getComponent(Position);
		
		gameContext.camera.x += Std.int((playerPos.x - 200 - gameContext.camera.x)/8);
		gameContext.camera.y += Std.int((playerPos.y - 100 - gameContext.camera.y)/8);
		
		gameContext.worldMouseX = cast Application.mouseX / 2 + gameContext.camera.x;
		gameContext.worldMouseY = cast Application.mouseY / 2 + gameContext.camera.y;
		
		var g = frame.g4;
		
		g.begin();
		KhaBlit.setContext(frame.g4);
		KhaBlit.clear(0.1, 0, 0, 0, 1, 1);
		KhaBlit.setPipeline(KhaBlit.KHBTex2PipelineState, "KHBTex2PipelineState");
		KhaBlit.setUniformMatrix4("mproj", KhaBlit.matrix2);
		KhaBlit.setUniformTexture("tex", ResourceFormat.atlases.get("all").image);
		
		if(gameContext.currentMap != null){
			gameContext.currentMap.update();
		}
		
		gameContext.surface2RenderSystem.update();
		
		KhaBlit.draw();

		g.end();

		gameContext.lightingSystem.renderHXB(gameContext);
		
		g.begin();
		KhaBlit.setContext(frame.g4);
		KhaBlit.setPipeline(KhaBlit.KHBTex2PipelineState, "KHBTex2PipelineState");
		KhaBlit.setUniformMatrix4("mproj", KhaBlit.matrix2);
		KhaBlit.setUniformTexture("tex", ResourceFormat.atlases.get("all").image);

		gameContext.selfLitRenderSystem.update();

		KhaBlit.draw();

		g.end();
		
		//UI
		if (!mouse2WasDown && Application.mouse2IsDown)
		{
			showMenu = !showMenu;
			menuX = Application.mouseX + 5;
			menuY = Application.mouseY;
		}
		
		
		// ========== UI BEGIN ==========
		if(drawHitBoxes){
			frame.g2.begin(false);
			for(tc in gameContext.collisionSystem.components){
				tc.drawHitbox(gameContext.camera, frame.g2);
			}
			for(p in gameContext.hitCheckSystem.components){
				p.entity.getComponent(Position, "pos_comp").drawPoint(gameContext.camera, frame.g2);
			}
			frame.g2.end();
		}

		ui.begin(frame.g2);

		if (showMenu){
			var worldMenuX:Int = cast menuX / 2 + gameContext.camera.x;
			var worldMenuY:Int = cast menuY / 2 + gameContext.camera.y;
			
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

				if (ui.button("Spawn Several Gyo")) {
					showMenu = false;
					for(i in 0...5){
						entFactory.createGyo(worldMenuX+Std.int(Math.random()*5), worldMenuY+Std.int(Math.random()*5));
					}
				}
				
				if (ui.button("Spawn light Source")) {
					showMenu = false;
					gameContext.lightingSystem.addLightSource(new LightSource(worldMenuX, worldMenuY,
						[Color.Cyan, Color.Orange, Color.Pink, Color.White,Color.Green, Color.Yellow, Color.Red][Std.int(Math.random() * 7)].value & 0xFFFFFF));
				}
				gameContext.lightingSystem.setAmbientLevel(
					ui.slider(Id.handle({value: gameContext.lightingSystem.getAmbientLevel()}), "Ambient Level", 0, 1, false, 100, true));

				drawHitBoxes = ui.check(Id.handle(), "draw hitboxes");
			}
		}
		ui.end();
		
		frame.g2.begin(false);
		gameContext.tooltipSystem.draw(frame.g2);
		frame.g2.end();
		mouse2WasDown = Application.mouse2IsDown;
		gameContext.statusText.render(frame.g2);
		
	}
	
}