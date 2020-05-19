package;

import hxblit.Camera;
import refraction.control.Damping;
import refraction.core.Application;
import refraction.core.Component;
import refraction.core.Entity;
import refraction.core.Sys;
import refraction.ds2d.DS2D;
import refraction.generic.Velocity;
import refraction.systems.BreadCrumbsSys;
import refraction.systems.LightSourceSystem;
import refraction.systems.RenderSys;
import refraction.systems.SpacingSys;
import refraction.systems.TooltipSys;
import refraction.tile.TileRender;
import refraction.tile.TileCollisionSys;
import refraction.tile.TilemapData;
import systems.InteractSys;
import systems.HitTestSys;
import systems.BeaconSys;
import zui.Zui;
import systems.ParticleSys;
import ui.HealthBar;

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

	public var camera:Camera;
	public var currentMap:TileRender;
	public var tilemapData:TilemapData;

	public var playerEntity:Entity;

	public var statusText:StatusText;

	public var renderSystem:RenderSys;
	public var selfLitRenderSystem:RenderSys;
	public var controlSystem:Sys<Component>;
	public var velocitySystem:Sys<Velocity>;
	public var dampingSystem:Sys<Damping>;
	public var collisionSystem:TileCollisionSys;
	public var interactSystem:InteractSys;
	public var breadCrumbsSystem:BreadCrumbsSys;
	public var aiSystem:Sys<Component>;
	public var lightSourceSystem:LightSourceSystem;
	public var beaconSystem:BeaconSys;
	public var particleSystem:ParticleSys;

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

	public function new(_camera:Camera, _ui:Zui) {
		camera = _camera;
		currentMap = null;
		ui = _ui;

		statusText = new StatusText();

		worldMouseX = worldMouseY = 0;

		renderSystem = new RenderSys(camera);
		selfLitRenderSystem = new RenderSys(camera);
		controlSystem = new Sys<Component>();
		velocitySystem = new Sys<Velocity>();
		dampingSystem = new Sys<Damping>();
		collisionSystem = new TileCollisionSys();
		interactSystem = new InteractSys();
		breadCrumbsSystem = new BreadCrumbsSys();
		aiSystem = new Sys<Component>();
		lightSourceSystem = new LightSourceSystem();
		spacingSystem = new SpacingSys();
		beaconSystem = new BeaconSys();
		particleSystem = new ParticleSys();

		hitCheckSystem = new Sys<Component>();
		hitTestSystem = new HitTestSys();

		lightingSystem = new DS2D(Std.int(Application.width / Application.zoom),
			Std.int(Application.height / Application.zoom));
		tooltipSystem = new TooltipSys(ui);
	}
}
