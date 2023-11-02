package game;

import game.CollisionBehaviours.defineCollisionBehaviours;
import game.debug.MapEditor;
import helpers.DebugLogger;
import helpers.LevelLoader;
import helpers.ZombieResourceLoader;
import hxblit.Camera;
import hxblit.KhaBlit;
import kha.Assets;
import kha.Framebuffer;
import kha.input.KeyCode;
import kha.input.Mouse;
import refraction.core.Application;
import refraction.display.ResourceFormat;
import refraction.generic.PositionCmp;
import zui.*;

class GameState extends refraction.core.State {

	var isRenderingReady:Bool;

	var gameContext:GameContext;
	var entFactory:EntFactory;
	var mapEditor:MapEditor;

	var ui:Zui;
	var showMenu:Bool;
	var shouldDrawHitBoxes:Bool;

	var levelLoader:LevelLoader;

	var defaultMap:String;

	public function new(defaultMap:String) {
		this.defaultMap = defaultMap;
		this.showMenu = false;
		this.shouldDrawHitBoxes = false;
		super();
	}

	function loadResources() {
		ZombieResourceLoader.load();
	}

	function onLoadAssets() {
		// TODO: Why is this here?
		Mouse
			.get()
			.notify(mouseDown, null, null, null);
		this.ui = new Zui({
			font: Assets.fonts.monaco,
			khaWindowId: 0,
			scaleFactor: 1
		});

		var gameCamera = new Camera(
			Std.int(
				Application.getScreenWidth() / Application.getScreenZoom()
			),
			Std.int(
				Application.getScreenHeight() / Application.getScreenZoom()
			)
		);

		// Init Game Context
		gameContext = GameContext.instance(gameCamera, ui);
		Application.defaultCamera = gameCamera;

		// Load resources
		loadResources();

		// Init Ent Factory
		entFactory = EntFactory.instance(
			gameContext,
			new ShooterComponentFactory(gameContext)
		);

		// load map
		levelLoader = new LevelLoader(entFactory, gameContext);
		levelLoader.loadMap(defaultMap);

		// Init collision behaviours
		defineCollisionBehaviours(gameContext);

		// TODO: reset DC stuff

		mapEditor = new MapEditor();

		isRenderingReady = true;
	}

	function configureDebugKeys() {
		Application.addKeyDownListener((code) -> {
			if (KeyCode.F9 == code) {
				gameContext.reloadConfigs();
				DebugLogger.info("RESOURCE", "reloading configs");
			}
			if (KeyCode.F10 == code) {
				entFactory.reloadEntityBlobs();
				DebugLogger.info("RESOURCE", "reloading entities");
			}
			if (KeyCode.P == code) {
				mapEditor.toggle();
			}
		});
	}

	override public function load() {
		super.load();
		isRenderingReady = false;

		Assets.loadEverything(this.onLoadAssets);
	}

	public function newState(map:String) {
		EntFactory.destroyInstance();
		GameContext.destroyInstance();
		Application.resetKeyListeners();
		Application.setState(new GameState(map));
	}

	function mouseDown(button:Int, x:Int, y:Int) {
		if (button == 0) {
			gameContext.interactSystem.update();
			var inventory:Inventory = gameContext.playerEntity.getComponent(
				Inventory
			);
			inventory.primaryAction();
		}
	}

	// =========
	// MAIN LOOP
	// =========

	override public function update() {
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
				trace("persistent action");
				gameContext.playerEntity
					.getComponent(Inventory)
					.persistentAction();
			}
		}
	}

	function updateCamera() {
		gameContext.camera.updateShake();
		var playerPos:PositionCmp = cast gameContext.playerEntity.getComponent(
			PositionCmp
		);

		gameContext.camera.follow(
			playerPos.x,
			playerPos.y,
			gameContext.config.camera_damping_speed
		);

		gameContext.worldMouseX = cast Application.mouseX / 2 + gameContext.camera.x;
		gameContext.worldMouseY = cast Application.mouseY / 2 + gameContext.camera.y;
	}

	override public function render(frame:Framebuffer) {
		if (!isRenderingReady) {
			return;
		}

		this.updateCamera();

		var g = frame.g4;

		g.begin();
		KhaBlit.setContext(frame.g4);
		KhaBlit.clear(0.1, 0, 0, 0, 1, 1);
		KhaBlit.setPipeline(
			KhaBlit.KHBTex2PipelineState,
			"KHBTex2PipelineState"
		);
		KhaBlit.setUniformMatrix4("mproj", KhaBlit.matrix2);
		KhaBlit.setUniformTexture(
			"tex",
			ResourceFormat.atlases
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
		KhaBlit.setPipeline(
			KhaBlit.KHBTex2PipelineState,
			"KHBTex2PipelineState"
		);
		KhaBlit.setUniformMatrix4("mproj", KhaBlit.matrix2);
		KhaBlit.setUniformTexture(
			"tex",
			ResourceFormat.atlases
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

	function renderUI(f:Framebuffer, context:GameContext, ui:Zui) { // === Game UI ===
		f.g2.begin(false);
		renderHitBoxes(f, context);
		renderGameUI(f, context, ui);
		f.g2.end();

		// === Debug UI ===
		ui.begin(f.g2);
		mapEditor.render(context, f, ui);
		gameContext.debugMenu.render(context, ui);
		// gameContext.console.draw();
		ui.end();
	}

	function renderGameUI(f:Framebuffer, gc:GameContext, ui:Zui) {
		gameContext.healthBar.render(f);
		gameContext.dialogueManager.render(f);
	}

	function renderHitBoxes(f:Framebuffer, gc:GameContext) {
		if (!shouldDrawHitBoxes) {
			return;
		}
		for (tc in gc.collisionSystem.components) {
			tc.drawHitbox(gc.camera, f.g2);
		}
		for (p in gc.hitCheckSystem.components) {
			p.entity
				.getComponent(PositionCmp)
				.drawPoint(gc.camera, f.g2);
		}
	}
}
