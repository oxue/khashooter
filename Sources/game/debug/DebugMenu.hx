package game.debug;

import components.Particle;
import haxe.ds.StringMap;
import kha.Color;
import refraction.core.Application;
import refraction.core.Entity;
import refraction.ds2d.LightSource;
import refraction.generic.PositionCmp;
import zui.Id;
import zui.Zui;

class DebugMenu {

	var showMenu:Bool;
	var menuX:Int;
	var menuY:Int;

	var buttons:StringMap<(GameContext,Zui) -> Void>;

	public function new() {
		showMenu = false;
		buttons = new StringMap<(GameContext,Zui) -> Void>();
		buttons.set("Reload Graphics", reloadGraphics);
		buttons.set("Spawn Wall Man", spawnWallMan);
		buttons.set("Spawn Crate", spawnCrate);
		buttons.set("Play Dialogue", playDialogue);
		buttons.set("Advance Dialogue", advanceDialogue);
		buttons.set("Teleport Here", teleportHere);
		buttons.set("Spawn Hell Minion", spawnHellMinion);
		buttons.set("Reload Entity Blobs", reloadEntityBlobs);
		buttons.set("Reload Config Blobs", reloadConfigBlobs);
		buttons.set("Spawn Several Gyo", spawnSeveralGyo);
		buttons.set("Spawn light Source", spawnlightSource);
		buttons.set("Blood Particles", bloodParticles);
	}

	function reloadGraphics(gameContext:GameContext, ui:Zui) {
		if (ui.button("Reload Graphics")) {
			gameContext.reloadGraphics = true;
		}
	}

	function spawnWallMan(gameContext:GameContext, ui:Zui) {
		var worldMenuX:Int = cast menuX / 2 + gameContext.camera.x;
		var worldMenuY:Int = cast menuY / 2 + gameContext.camera.y;
		if (ui.button("Spawn Wall Man")) {
			var entityWallMan:Entity = EntFactory
				.instance()
				.autoBuild("Wallman");
			entityWallMan
				.getComponent(PositionCmp)
				.setPosition(worldMenuX, worldMenuY)
				.rotation = Math.random() * 360 - 180;
		}
	}

	function spawnCrate(gameContext:GameContext, ui:Zui) {
		var worldMenuX:Int = cast menuX / 2 + gameContext.camera.x;
		var worldMenuY:Int = cast menuY / 2 + gameContext.camera.y;
		if (ui.button("Spawn Crate")) {
			entityCrate = EntFactory
				.instance()
				.autoBuild("Crate");

			entityCrate
				.getComponent(PositionCmp)
				.setPosition(worldMenuX, worldMenuY);
			gameContext.lightingSystem.addLightSource(
				new LightSource(worldMenuX, worldMenuY, 0x005B6F, 15)
			);
		}
	}

	function playDialogue(gameContext:GameContext, ui:Zui) {
		if (ui.button("Play Dialogue")) {
			gameContext.dialogueManager.playDialogue("dialogue1");
			showMenu = false;
		}
	}

	function advanceDialogue(gameContext:GameContext, ui:Zui) {
		if (ui.button("Advance Dialogue")) {
			gameContext.dialogueManager.advanceDialogue();
			showMenu = false;
		}
	}

	function teleportHere(gameContext:GameContext, ui:Zui) {
		// var worldMenuX:Int = cast menuX / 2 + gameContext.camera.x;
		// var worldMenuY:Int = cast menuY / 2 + gameContext.camera.y;
		// if (ui.button("Teleport Here")) {
		// 	showMenu = false;
		// 	playerPos.x = worldMenuX;
		// 	playerPos.y = worldMenuY;
		// 	trace(gameContext.beaconSystem.getOne("player"));
		// }
	}

	function spawnHellMinion(gameContext:GameContext, ui:Zui) {
		var worldMenuX:Int = cast menuX / 2 + gameContext.camera.x;
		var worldMenuY:Int = cast menuY / 2 + gameContext.camera.y;
		if (ui.button("Spawn Hell Minion")) {
			showMenu = false;
			EntFactory
				.instance()
				.autoBuild("Zombie")
				.getComponent(PositionCmp)
				.setPosition(worldMenuX, worldMenuY);
		}
	}

	function reloadEntityBlobs(gameContext:GameContext, ui:Zui) {
		if (ui.button("Reload Entity Blobs")) {
			showMenu = false;
			EntFactory
				.instance()
				.reloadEntityBlobs();
		}
	}

	function reloadConfigBlobs(gameContext:GameContext, ui:Zui) {
		if (ui.button("Reload Config Blobs")) {
			showMenu = false;
			gameContext.reloadConfigs();
		}
	}

	function spawnSeveralGyo(gameContext:GameContext, ui:Zui) {
		var worldMenuX:Int = cast menuX / 2 + gameContext.camera.x;
		var worldMenuY:Int = cast menuY / 2 + gameContext.camera.y;
		if (ui.button("Spawn Several Gyo")) {
			showMenu = false;
			for (i in 0...5) {
				EntFactory
					.instance()
					.autoBuild("Gyo")
					.getComponent(PositionCmp)
					.setPosition(
						worldMenuX + Std.int(Math.random() * 5),
						worldMenuY + Std.int(Math.random() * 5)
					);
			}
		}
	}

	function spawnlightSource(gameContext:GameContext, ui:Zui) {
		var worldMenuX:Int = cast menuX / 2 + gameContext.camera.x;
		var worldMenuY:Int = cast menuY / 2 + gameContext.camera.y;
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
	}

	function bloodParticles(gameContext:GameContext, ui:Zui) {
		var worldMenuX:Int = cast menuX / 2 + gameContext.camera.x;
		var worldMenuY:Int = cast menuY / 2 + gameContext.camera.y;
		if (ui.button("Blood Particles")) {
			showMenu = false;
			for (i in 0...10) {
				EntFactory
					.instance()
					.autoBuild("Blood")
					.getComponent(PositionCmp)
					.setPosition(worldMenuX, worldMenuY)
					.getEntity()
					.getComponent(Particle)
					.randomDirection(Math.random() * 10 + 5);
			}
		}
	}

	public function toggleMenu() {
		showMenu = true;
		if (showMenu) {
			menuX = Application.mouseX;
			menuY = Application.mouseY;
		}
	}

	var entityCrate:Entity;

	public function render(context:GameContext, ui:Zui) {
		if (!showMenu) {
			return;
		}
		var playerPos = context.playerEntity.getComponent(PositionCmp);

		if (ui.window(Id.handle(), menuX, menuY, 400, 600, false)) {
			for (kv in buttons.keyValueIterator()) {
				kv.value(context, ui);
			}

			context.lightingSystem.setAmbientLevel(
				ui.slider(
					Id.handle({value: context.lightingSystem.getAmbientLevel()}),
					"Ambient Level",
					0,
					1,
					false,
					100,
					true
				)
			);

			if (ui.button("Clear Lights")) {
				showMenu = false;
				context.lightingSystem.lights = [];
			}

			if (ui.button("Hide Menu")) {
				showMenu = false;
			}

			context.shouldDrawHitBoxes = ui.check(Id.handle(), "draw hitboxes");
		}
	}
}
