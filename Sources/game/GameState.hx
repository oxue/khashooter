package game;

import helpers.DebugLogger;
import hxblit.KhaBlit;
import hxblit.Camera;
import kha.Assets;
import kha.Framebuffer;
import refraction.core.Application;
import refraction.core.State;
import refraction.core.Entity;
import refraction.ds2d.LightSource;
import refraction.display.ResourceFormat;
import refraction.generic.Position;
import kha.math.Vector2;
import components.Particle;
import helpers.ZombieResourceLoader;
import kha.Color;
import kha.input.Mouse;
import zui.*;
import helpers.LevelLoader;
import game.GameContext;
import game.EntFactory;
import game.Inventory;
import game.ShooterFactory;
import pgr.dconsole.DC;
import game.Console;
import game.ConsoleInput;
import game.dialogue.DialogueManager;

/**
 * ...
 * @author
 */
class GameState extends refraction.core.State {
	private var isRenderingReady:Bool;

	private var gameContext:GameContext;
	private var entFactory:EntFactory;
	private var dialogueManager:DialogueManager;

	private var ui:Zui;
	private var showMenu:Bool = false;
	private var drawHitBoxes:Bool = false;
	private var mouse2WasDown:Bool = false;
	private var menuX:Int;
	private var menuY:Int;

	private var levelLoader:LevelLoader;

	private var console:Console;
	private var defaultMap:String;

	public function new(defaultMap:String) {
		this.defaultMap = defaultMap;
		super();
	}

	private function loadResources():Void {
		ZombieResourceLoader.load();
	}

	override public function load():Void {
		super.load();
		isRenderingReady = false;

		Assets.loadEverything(function() {
			Mouse
				.get()
				.notify(mouseDown, null, null, null);

			ui = new Zui({font: Assets.fonts.monaco, khaWindowId: 0, scaleFactor: 1});

			console = new Console((s)->{
				DebugLogger.info("CONSOLE", s);
			}, ui);

			DC.init(300,"DOWN",null,new ConsoleInput(),console);
			DC.log("This text will be logged.");

			var gameCamera = new Camera(Std.int(Application.width / Application.zoom),
				Std.int(Application.height / Application.zoom));

			// Init Game Context
			gameContext = GameContext.instance(gameCamera, ui);
			Application.defaultCamera = gameCamera;

			// Load resources
			loadResources();

			// Init Ent Factory
			entFactory = EntFactory.instance(gameContext, new ShooterFactory(gameContext));
			dialogueManager = new DialogueManager("../../Assets/dialogue");
			dialogueManager.loadDialogue("dialogue1");

			// Init Lighting
			// var i = 0;
			// while(i-->0)
			// gameContext.lightingSystem.addLightSource(new LightSource(100, 100, 0xffffff,1000));

			// load map
			levelLoader = new LevelLoader(entFactory, gameContext);
			levelLoader.loadMap(defaultMap);

			// Init collision behaviours
			defineBehaviours();

			DC.registerObject(gameContext.configurations, "config");
			DC.registerObject(levelLoader, "loader");
			DC.registerObject(Application, "app");
			DC.registerFunction(newState, "loadGameState", "reload the game state with the provided map");
			DC.registerObject(this, "gameState");
			// TODO: reset DC stuff

			isRenderingReady = true;
		});
	}

	public function newState(map:String) {
		EntFactory.destroyInstance();
		GameContext.destroyInstance();
		Application.resetKeyListeners();
		Application.setState(new GameState(map));
	}

	private function defineBehaviours():Void {
		gameContext.hitTestSystem.onHit("zombie", "player", function(z:Entity, p:Entity) {
			p.notify("damage", {amount: -1});
		});
		gameContext.hitTestSystem.onHit("zombie", Consts.PLAYER_BOLT, function(z:Entity, b:Entity) {
			z.notify("damage", {amount: -10});
			b.notify("collided");
			for (i in 0...10) {
				entFactory
					.autoBuild("Blood")
					.getComponent(Position)
					.setFromPosition(z.getComponent(Position))
					.getEntity()
					.getComponent(Particle)
					.randomDirection(Math.random() * 10 + 5);
			}
		});
	}

	private function buildDebugPoly():Void {
		var poly = new refraction.ds2d.Polygon(2, 10, 100, 100);
		poly.faces = [
			new refraction.ds2d.Face(new Vector2(100, 100), new Vector2(100, 120)),
			new refraction.ds2d.Face(new Vector2(100, 125), new Vector2(100, 145))
		];
		gameContext.lightingSystem.polygons.push(poly);
	}

	private function mouseDown(button:Int, x:Int, y:Int) {
		if (button == 0) {
			gameContext.interactSystem.update();
			// var playerPos:Position = cast gameContext.playerEntity.getComponent(Position);

			gameContext.playerEntity
				.getComponent(Inventory)
				.primary();
		}
	}

	// =========
	// MAIN LOOP
	// =========

	override public function update():Void {
		super.update();

		if (gameContext != null) {
			gameContext.controlSystem.update();
			gameContext.spacingSystem.update();
			gameContext.dampingSystem.update();
			gameContext.velocitySystem.update();
			gameContext.collisionSystem.update();
			gameContext.environmentSystem.update();
			gameContext.lightSourceSystem.update();
			gameContext.particleSystem.update();

			gameContext.breadCrumbsSystem.update();

			gameContext.hitCheckSystem.update();
			gameContext.aiSystem.update();

			gameContext.hitTestSystem.update();
			gameContext.beaconSystem.update();

			if (Application.mouseIsDown) {
				gameContext.playerEntity
					.getComponent(Inventory)
					.persist();
			}
		}
	}

	override public function render(frame:Framebuffer) {
		if (!isRenderingReady)
			return;

		gameContext.camera.updateShake();

		var playerPos:Position = cast gameContext.playerEntity.getComponent(Position);

		gameContext.camera.x += Std.int((playerPos.x + gameContext.configurations.camera_offset.x - gameContext.camera.x) / 8);
		gameContext.camera.y += Std.int((playerPos.y + gameContext.configurations.camera_offset.y - gameContext.camera.y) / 8);

		gameContext.worldMouseX = cast Application.mouseX / 2 + gameContext.camera.x;
		gameContext.worldMouseY = cast Application.mouseY / 2 + gameContext.camera.y;

		var g = frame.g4;

		g.begin();
		KhaBlit.setContext(frame.g4);
		KhaBlit.clear(0.1, 0, 0, 0, 1, 1);
		KhaBlit.setPipeline(KhaBlit.KHBTex2PipelineState, "KHBTex2PipelineState");
		KhaBlit.setUniformMatrix4("mproj", KhaBlit.matrix2);
		KhaBlit.setUniformTexture("tex", ResourceFormat.atlases
			.get("all")
			.image
		);

		if (gameContext.currentMap != null) {
			gameContext.currentMap.update();
		}

		gameContext.renderSystem.update();

		KhaBlit.draw();

		g.end();

		gameContext.lightingSystem.renderHXB(gameContext);

		g.begin();
		KhaBlit.setContext(frame.g4);
		KhaBlit.setPipeline(KhaBlit.KHBTex2PipelineState, "KHBTex2PipelineState");
		KhaBlit.setUniformMatrix4("mproj", KhaBlit.matrix2);
		KhaBlit.setUniformTexture("tex", ResourceFormat.atlases
			.get("all")
			.image
		);

		gameContext.selfLitRenderSystem.update();

		KhaBlit.draw();

		g.end();

		// UI
		if (!mouse2WasDown && Application.mouse2IsDown) {
			showMenu = !showMenu;
			menuX = Application.mouseX + 5;
			menuY = Application.mouseY;
		}

		// ========== UI BEGIN ==========
		renderUI(frame, gameContext, ui);

		frame.g2.begin(false);
		gameContext.tooltipSystem.draw(frame.g2);
		frame.g2.end();
		mouse2WasDown = Application.mouse2IsDown;
		gameContext.statusText.render(frame.g2);
	}

	private function renderUI(f:Framebuffer, gc:GameContext, ui:Zui) {
		renderHitBoxes(f, gc);
		renderGameUI(f, gc, ui);

		ui.begin(f.g2);
		renderDebugMenu(gc, ui);
		console.draw();
		ui.end();
	}

	private function renderGameUI(f:Framebuffer, gc:GameContext, ui:Zui) {
		f.g2.begin(false);
		gameContext.healthBar.render(f);
		dialogueManager.render(f);
		f.g2.end();
	}

	private function renderDebugMenu(gc:GameContext, ui:Zui) {
		var playerPos:Position = cast gc.playerEntity.getComponent(Position);
		if (showMenu) {
			var worldMenuX:Int = cast menuX / 2 + gameContext.camera.x;
			var worldMenuY:Int = cast menuY / 2 + gameContext.camera.y;

			if (ui.window(Id.handle(), menuX, menuY, 200, 300, false)) {
				if (ui.button("dia")) {
					dialogueManager.playDialogue("dialogue1");
				}

				if (ui.button("Teleport Here")) {
					showMenu = false;
					playerPos.x = worldMenuX;
					playerPos.y = worldMenuY;
					trace(gameContext.beaconSystem.getOne("player"));
				}

				if (ui.button("Spawn Hell Minion")) {
					showMenu = false;
					entFactory
						.autoBuild("Zombie")
						.getComponent(Position)
						.setPosition(worldMenuX, worldMenuY);
				}

				if (ui.button("Reload Entity Blobs")) {
					showMenu = false;
					EntFactory
						.instance()
						.reloadEntityBlobs();
				}

				if (ui.button("Reload Config Blobs")) {
					showMenu = false;
					gameContext.reloadConfigs();
				}

				if (ui.button("Spawn Several Gyo")) {
					showMenu = false;
					for (i in 0...5) {
						entFactory
							.autoBuild("Gyo")
							.getComponent(Position)
							.setPosition(worldMenuX + Std.int(Math.random() * 5),
								worldMenuY + Std.int(Math.random() * 5));
					}
				}

				if (ui.button("Spawn light Source")) {
					showMenu = false;
					gameContext.lightingSystem.addLightSource(new LightSource(worldMenuX, worldMenuY, [
						Color.Cyan,
						Color.Orange,
						Color.Pink,
						Color.White,
						Color.Green,
						Color.Yellow,
						Color.Red
					][Std.int(Math.random() * 7)].value & 0xFFFFFF));
				}

				if (ui.button("Blood Particles")) {
					showMenu = false;
					for (i in 0...10) {
						entFactory
							.autoBuild("Blood")
							.getComponent(Position)
							.setPosition(worldMenuX, worldMenuY)
							.getEntity()
							.getComponent(Particle)
							.randomDirection(Math.random() * 10 + 5);
					}
				}

				gameContext.lightingSystem.setAmbientLevel(ui.slider(Id.handle({value: gameContext.lightingSystem.getAmbientLevel()}),
					"Ambient Level", 0, 1,
					false, 100, true));

				if (ui.button("Clear Lights")) {
					showMenu = false;
					gameContext.lightingSystem.lights = [];
				}

				if (ui.button("Hide Menu")) {
					showMenu = false;
				}

				drawHitBoxes = ui.check(Id.handle(), "draw hitboxes");
			}
		}
	}

	private function renderHitBoxes(f:Framebuffer, gc:GameContext) {
		if (drawHitBoxes) {
			f.g2.begin(false);
			for (tc in gc.collisionSystem.components) {
				tc.drawHitbox(gc.camera, f.g2);
			}
			for (p in gc.hitCheckSystem.components) {
				p.entity
					.getComponent(Position)
					.drawPoint(gc.camera, f.g2);
			}
			f.g2.end();
		}
	}
}
