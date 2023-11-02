package game;

import game.debug.DebugMenu;
import game.dialogue.DialogueManager;
import helpers.DebugLogger;
import hxblit.Camera;
import pgr.dconsole.DC;
import refraction.control.Damping;
import refraction.core.Application;
import refraction.core.Component;
import refraction.core.Entity;
import refraction.core.Sys;
import refraction.core.TemplateParser;
import refraction.ds2d.DS2D;
import refraction.generic.VelocityCmp;
import refraction.systems.BreadCrumbsSys;
import refraction.systems.LightSourceSystem;
import refraction.systems.RenderSys;
import refraction.systems.SpacingSys;
import refraction.systems.TooltipSys;
import refraction.tile.TileCollisionSys;
import refraction.tile.TileRender;
import refraction.tile.TilemapData;
import systems.BeaconSys;
import systems.HitTestSys;
import systems.InteractSys;
import systems.ParticleSys;
import ui.HealthBar;
import zui.Zui;

/**
 * ...
 * @author
 */
class GameContext {

	private static var myInstance:GameContext = null;

	public static function instance(?_camera:Camera, ?_ui:Zui):GameContext {
		if (myInstance == null) {
			myInstance = new GameContext(_camera, _ui);
		}
		return myInstance;
	}

	public static function destroyInstance() {
		myInstance = null;
	}

	public var camera:Camera;
	public var currentMap:TileRender;
	public var tilemapData:TilemapData;

	public var playerEntity:Entity;

	public var statusText:StatusText;

	public var renderSystem:RenderSys;
	public var selfLitRenderSystem:RenderSys;
	public var controlSystem:Sys<Component>;
	public var velocitySystem:Sys<VelocityCmp>;
	public var dampingSystem:Sys<Damping>;
	public var collisionSystem:TileCollisionSys;
	public var interactSystem:InteractSys;
	public var breadCrumbsSystem:BreadCrumbsSys;
	public var aiSystem:Sys<Component>;
	public var lightSourceSystem:LightSourceSystem;
	public var beaconSystem:BeaconSys;
	public var particleSystem:ParticleSys;
	public var environmentSystem:Sys<Component>;

	public var spacingSystem:SpacingSys;
	public var tooltipSystem:TooltipSys;
	public var lightingSystem:DS2D;

	public var hitCheckSystem:Sys<Component>;
	public var hitTestSystem:HitTestSys;

	public var nullSystem:Sys<Component>;

	// TODO: Deprecate these ones.
	public var worldMouseX:Int;
	public var worldMouseY:Int;

	public var ui:Zui;
	public var healthBar:HealthBar;

	public var config:Dynamic;
	public var dialogueManager:DialogueManager;
	public var debugMenu:DebugMenu;
	public var console:Console;

	public var shouldDrawHitBoxes:Bool;

	public function new(_camera:Camera, _ui:Zui) {
		config = TemplateParser.parseConfig();

		camera = _camera;
		currentMap = null;
		ui = _ui;

		statusText = new StatusText();
		statusText.x = cast camera.w / 2 * Application.getScreenZoom();
		statusText.y = cast camera.h / 2 * Application.getScreenZoom();

		worldMouseX = worldMouseY = 0;

		renderSystem = new RenderSys(camera);
		selfLitRenderSystem = new RenderSys(camera);
		controlSystem = new Sys<Component>();
		velocitySystem = new Sys<VelocityCmp>();
		dampingSystem = new Sys<Damping>();
		collisionSystem = new TileCollisionSys();
		interactSystem = new InteractSys();
		breadCrumbsSystem = new BreadCrumbsSys();
		aiSystem = new Sys<Component>();
		lightSourceSystem = new LightSourceSystem();
		spacingSystem = new SpacingSys();
		beaconSystem = new BeaconSys();
		particleSystem = new ParticleSys();
		environmentSystem = new Sys<Component>();

		hitCheckSystem = new Sys<Component>();
		hitTestSystem = new HitTestSys();

		lightingSystem = new DS2D(
			Std.int(
				Application.getScreenWidth() / Application.getScreenZoom()
			),
			Std.int(
				Application.getScreenHeight() / Application.getScreenZoom()
			)
		);
		tooltipSystem = new TooltipSys(ui);

		dialogueManager = new DialogueManager("../../Assets/dialogue");
		debugMenu = new DebugMenu();
		// initConsole();
	}

	private function initConsole() {
		console = new Console((s) -> {
			DebugLogger.info("CONSOLE", s);
		}, ui);

		DC.init(300, "DOWN", null, new ConsoleInput(), console);

		DC.registerObject(config, "config");
		DC.registerObject(Application, "app");
		DC.registerObject(this, "context");

		DC.log("- Objects Available");
		DC.log("    - context:GameContext");
		DC.log("    - app:Application");
		DC.log("    - config:Application");
	}

	public function reloadConfigs() {
		TemplateParser.reloadConfigurations("../../Assets", (c) -> {
			DebugLogger.info("config", c);
			config = c;
		});
	}
}
