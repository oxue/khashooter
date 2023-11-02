package game.debug;

import components.Particle;
import kha.Color;
import refraction.core.Application;
import refraction.core.Entity;
import refraction.ds2d.LightSource;
import refraction.generic.PositionCmp;
import zui.Id;
import zui.Zui;

class DebugMenu {
	private var showMenu:Bool;
	private var menuX:Int;
	private var menuY:Int;

	public function new() {
		showMenu = false;
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

		if (entityCrate != null) {
			// entityCrate.getComponent(Position).rotation += 1;
		}

		var worldMenuX:Int = cast menuX / 2 + context.camera.x;
		var worldMenuY:Int = cast menuY / 2 + context.camera.y;

		if (ui.window(Id.handle(), menuX, menuY, 200, 300, false)) {
			if (ui.button("Spawn Crate")) {
				entityCrate = EntFactory
					.instance()
					.autoBuild("Crate");

				entityCrate
					.getComponent(PositionCmp)
					.setPosition(worldMenuX, worldMenuY);
				context.lightingSystem.addLightSource(
					new LightSource(
						worldMenuX,
						worldMenuY,
						0x005B6F,
						15
					)
				);
			}

			if (ui.button("Play Dialogue")) {
				context.dialogueManager.playDialogue("dialogue1");
				showMenu = false;
			}

			if (ui.button("Advance Dialogue")) {
				context.dialogueManager.advanceDialogue();
				showMenu = false;
			}

			if (ui.button("Teleport Here")) {
				showMenu = false;
				playerPos.x = worldMenuX;
				playerPos.y = worldMenuY;
				trace(context.beaconSystem.getOne("player"));
			}

			if (ui.button("Spawn Hell Minion")) {
				showMenu = false;
				EntFactory
					.instance()
					.autoBuild("Zombie")
					.getComponent(PositionCmp)
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
				context.reloadConfigs();
			}

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

			if (ui.button("Spawn light Source")) {
				showMenu = false;
				context.lightingSystem.addLightSource(
					new LightSource(worldMenuX, worldMenuY, [
						Color.Cyan,
						Color.Orange,
						Color.Pink,
						Color.White,
						Color.Green,
						Color.Yellow,
						Color.Red
					][Std.int(Math.random() * 7)].value & 0xFFFFFF)
				);
			}

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

			context.lightingSystem.setAmbientLevel(
				ui.slider(
					Id.handle(
						{value: context.lightingSystem.getAmbientLevel()}
					),
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

			context.shouldDrawHitBoxes = ui.check(
				Id.handle(),
				"draw hitboxes"
			);
		}
	}
}
