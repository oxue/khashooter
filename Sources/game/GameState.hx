package game;

import kha.input.KeyCode;
import helpers.DebugLogger;
import hxblit.KhaBlit;
import hxblit.Camera;
import kha.Assets;
import kha.Framebuffer;
import refraction.core.Application;
import refraction.core.State;
import refraction.core.Entity;
import refraction.display.ResourceFormat;
import refraction.generic.Position;
import kha.math.Vector2;
import components.Particle;
import helpers.ZombieResourceLoader;
import kha.input.Mouse;
import zui.*;
import helpers.LevelLoader;
import game.GameContext;
import game.EntFactory;
import game.Inventory;
import game.ShooterFactory;
import game.debug.MapEditor;

/**
 * ...
 * @author
 */
class GameState extends refraction.core.State {
	private var isRenderingReady:Bool;

	private var gameContext:GameContext;
	private var entFactory:EntFactory;
	private var mapEditor:MapEditor;

	private var ui:Zui;
	private var showMenu:Bool = false;
	private var shouldDrawHitBoxes:Bool = false;

	private var levelLoader:LevelLoader;

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

			var gameCamera = new Camera(Std.int(Application.width / Application.zoom),
				Std.int(Application.height / Application.zoom));

			// Init Game Context
			gameContext = GameContext.instance(gameCamera, ui);
			Application.defaultCamera = gameCamera;

			// Load resources
			loadResources();

			// Init Ent Factory
			entFactory = EntFactory.instance(gameContext, new ShooterFactory(gameContext));

			// Init Lighting
			// var i = 0;
			// while(i-->0)
			// gameContext.lightingSystem.addLightSource(new LightSource(100, 100, 0xffffff,1000));

			// load map
			levelLoader = new LevelLoader(entFactory, gameContext);
			levelLoader.loadMap(defaultMap);

			// Init collision behaviours
			defineBehaviours();

			// TODO: reset DC stuff

			mapEditor = new MapEditor();

			Application.addKeyDownListener((code) -> {
				if (KeyCode.F9 == code) {
					gameContext.reloadConfigs();
					DebugLogger.info("RESOURCE", "reloading configs");
				}
				if (KeyCode.F10 == code) {
					entFactory.reloadEntityBlobs();
					DebugLogger.info("RESOURCE", "reloading entities");
				}
				if (KeyCode.F11 == code) {
					mapEditor.toggle();
				}
			});

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
		gameContext.hitTestSystem.onHit(Consts.ZOMBIE, "player", function(z:Entity, p:Entity) {
			p.notify("damage", {amount: -1});
		});
		gameContext.hitTestSystem.onHit(Consts.NEUTRAL_HP, Consts.FIRE, (n, f) -> {
			trace("HIT");
			n.notify("damage", {
				amount: -2,
				type: Consts.FIRE
			});
		});
		gameContext.hitTestSystem.onHit(Consts.ZOMBIE, Consts.PLAYER_BOLT, function(z:Entity, b:Entity) {
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

		gameContext.camera.x += Std.int((playerPos.x
			+ gameContext.config.camera_offset.x
			- gameContext.camera.x) / 8);
		gameContext.camera.y += Std.int((playerPos.y
			+ gameContext.config.camera_offset.y
			- gameContext.camera.y) / 8);

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
		if (Application.mouse2JustDown) {
			gameContext.debugMenu.toggleMenu();
		}

		// ========== UI BEGIN ==========
		renderUI(frame, gameContext, ui);

		frame.g2.begin(false);
		gameContext.tooltipSystem.draw(frame.g2);
		frame.g2.end();
		gameContext.statusText.render(frame.g2);
	}

	private function renderUI(f:Framebuffer, context:GameContext, ui:Zui) {
		// === Game UI ===
		f.g2.begin(false);
		renderHitBoxes(f, context);
		renderGameUI(f, context, ui);
		f.g2.end();

		// === Debug UI ===
		ui.begin(f.g2);
		mapEditor.render(context, f, ui);
		gameContext.debugMenu.render(context, ui);
		gameContext.console.draw();
		ui.end();
	}

	private function renderGameUI(f:Framebuffer, gc:GameContext, ui:Zui) {
		gameContext.healthBar.render(f);
		gameContext.dialogueManager.render(f);
	}

	private function renderHitBoxes(f:Framebuffer, gc:GameContext) {
		if (!shouldDrawHitBoxes) {
			return;
		}
		for (tc in gc.collisionSystem.components) {
			tc.drawHitbox(gc.camera, f.g2);
		}
		for (p in gc.hitCheckSystem.components) {
			p.entity
				.getComponent(Position)
				.drawPoint(gc.camera, f.g2);
		}
	}
}
