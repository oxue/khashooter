package game.debug;

import zui.Id;
import refraction.tile.TilemapData;
import kha.math.FastMatrix3;
import kha.Color;
import kha.Assets;
import zui.Zui;
import kha.Framebuffer;

class MapEditor {
	private var show:Bool;

	public function new() {
		show = false;
	}

	public function toggle() {
		show = !show;
	}

	public function render(context:GameContext, f:Framebuffer, ui:Zui) {
		if (!show) {
			return;
		}

		f.g2.begin(false);
		f.g2.pushOpacity(0.5);
		renderGrid(context, f);
		f.g2.popOpacity();
		f.g2.end();
		ui.begin(f.g2);
		renderUI(context, ui);
		ui.end();
	}

	public function renderUI(context:GameContext, ui:Zui) {
		if (ui.window(Id.handle(), 20, 20, 800, 100, true)) {
			if (ui.image(Assets.images.tilesheet) == State.Down) {
				trace("ZUI DOWN");
			}
		}
	}

	private function drawString2(f:Framebuffer, s:String, x:Float, y:Float) {
		f.g2.drawString(s, x * 2, y * 2);
	}

	private function drawLine2(f:Framebuffer, x:Float, y:Float, z:Float, w:Float, s:Float = 1.0) {
		f.g2.drawLine(x * 2, y * 2, z * 2, w * 2, s);
	}

	private function renderGrid(context:GameContext, f:Framebuffer) {
		f.g2.font = Assets.fonts.monaco;
		f.g2.color = Color.White;
		var tilesize = context.tilemapData.tilesize;

		var camera = context.camera;
		var cameraX = camera.x - 1;
		var cameraY = camera.y + 1;

		var startIndX:Int = cast Math.max(0, Math.floor(camera.x / tilesize));
		var startIndY:Int = cast Math.max(0, Math.floor(camera.y / tilesize));
		var endIndX:Int = cast Math.floor((camera.x + camera.w) / tilesize) + 1;
		var endIndY:Int = cast Math.floor((camera.y + camera.h) / tilesize) + 1;

		for (i in startIndX...endIndX) {
			drawString2(f, Std.string(i), i * tilesize - cameraX, Math.max(0.0, -cameraY) - 20);

			drawLine2(f, i * tilesize - cameraX, Math.max(0.0, -cameraY), i * tilesize - cameraX, camera.h);
		}

		for (i in startIndY...endIndY) {
			drawString2(f, Std.string(i), Math.max(0, -cameraX) - 10, i * tilesize - cameraY);

			drawLine2(f, Math.max(0, -cameraX), i * tilesize - cameraY, camera.w, i * tilesize - cameraY);
		}
	}
}
