package game.debug;

import hxblit.Camera;
import kha.Assets;
import kha.Color;
import kha.Framebuffer;
import kha.math.Vector2;
import refraction.core.Application;
import zui.Id;
import zui.Zui;

class MapEditor {

	static final FONTSIZE:Int = 16;
	static final TILEPALLET_START_X:Int = 20;
	static final TILEPALLET_START_Y:Int = 20;

	var show:Bool;
	var tilePaletteHandle:Handle;

	public function new() {
		show = false;

		tilePaletteHandle = Id.handle();
	}

	public function toggle() {
		show = !show;
	}

	public function render(context:GameContext, f:Framebuffer, ui:Zui) {
		if (!show) {
			return;
		}

		f.g2.begin(false);
		f.g2.pushOpacity(0.3);
		renderGrid(context, f);
		f.g2.popOpacity();
		f.g2.end();
		ui.begin(f.g2);
		renderUI(context, ui);
		ui.end();
	}

	public function getWindowMousePosition(ui:Zui, windowHandle:Handle):Vector2 {
		var windowPosition:Vector2 = new Vector2(
			TILEPALLET_START_X + ui.TAB_W(),
			TILEPALLET_START_Y + ui.HEADER_DRAG_H()
		);
		var windowDragPosition:Vector2 = new Vector2(windowHandle.dragX, windowHandle.dragY);
		windowPosition = windowPosition.add(windowDragPosition);
		var mousePosition:Vector2 = new Vector2(Application.mouseX, Application.mouseY);

		var windowMousePosition:Vector2 = mousePosition.sub(windowPosition);
		return windowMousePosition;
	}

	public function renderUI(context:GameContext, ui:Zui) {
		if (ui.window(
			tilePaletteHandle,
			TILEPALLET_START_X,
			TILEPALLET_START_Y,
			800,
			200,
			true
		)) {
			var tilePalletImgState:State = ui.image(
				Assets.images.tilesheet,
				0xffffffff,
				Assets.images.tilesheet.height * Application.getScreenZoom(),
			);
			if (tilePalletImgState == State.Down) {
				handleTilePaletteSelection(ui, context);
				
			}
		}
	}

	function handleTilePaletteSelection(ui:Zui, context:GameContext) {
		var windowMousePosition:Vector2 = getWindowMousePosition(ui, tilePaletteHandle);
		// var tileSelected:Int = context.tilemapData.getTileIndexAt(
		// 	windowMousePosition.x,
		// 	windowMousePosition.y
		// );
	}

	function drawString2(f:Framebuffer, s:String, x:Float, y:Float) {
		f.g2.fontSize = FONTSIZE;
		f.g2.drawString(s, x * 2, y * 2);
	}

	function drawLine2(f:Framebuffer, x1:Float, y1:Float, x2:Float, y2:Float, strength:Float = 1.0) {
		f.g2.drawLine(x1 * 2, y1 * 2, x2 * 2, y2 * 2, strength);
	}

	function renderGrid(context:GameContext, framebuffer:Framebuffer) {
		framebuffer.g2.font = Assets.fonts.monaco;
		framebuffer.g2.color = Color.White;
		var tilesize:Int = context.tilemap.getTilesize();

		var camera:Camera = context.camera;
		var cameraX:Float = camera.x;
		var cameraY:Float = camera.y;

		var startIndX:Int = cast Math.Math.floor(Math.max(0, camera.x) / tilesize);
		var startIndY:Int = cast Math.Math.floor(Math.max(0, camera.y) / tilesize);
		var endIndX:Int = cast Math.floor(camera.r() / tilesize) + 1;
		var endIndY:Int = cast Math.floor(camera.b() / tilesize) + 1;

		for (i in startIndX...endIndX) {
			drawString2(
				framebuffer,
				Std.string(i),
				i * tilesize - cameraX,
				Math.max(0.0, -cameraY - FONTSIZE)
			);
			drawLine2(
				framebuffer,
				i * tilesize - cameraX,
				Math.max(0.0, -cameraY),
				i * tilesize - cameraX,
				camera.h
			);
		}

		// horizontal lines
		for (i in startIndY...endIndY) {
			drawString2(
				framebuffer,
				Std.string(i),
				Math.max(0, -cameraX - FONTSIZE),
				i * tilesize - cameraY
			);
			drawLine2(
				framebuffer,
				Math.max(0, -cameraX),
				i * tilesize - cameraY,
				camera.w,
				i * tilesize - cameraY
			);
		}
	}
}
