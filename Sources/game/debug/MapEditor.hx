package game.debug;

import refraction.core.Utils;
import helpers.LevelLoader;
import hxblit.Camera;
import kha.Assets;
import kha.Color;
import kha.Framebuffer;
import kha.Image;
import kha.input.Mouse;
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
	var tileSelected:Int;
	var levelLoader:LevelLoader;

	// element
	var toolbox:Toolbox;
	var entityLibrary:EntityLibrary;

	public function new(gameContext:GameContext, levelLoader:LevelLoader, ui:Zui) {
		show = false;

		tilePaletteHandle = Id.handle();
		toolbox = new Toolbox(this, levelLoader, gameContext);
		entityLibrary = new EntityLibrary(this, levelLoader, gameContext);

		tileSelected = 0;
		this.levelLoader = levelLoader;

		Application.addMouseDownListener((button, x, y) -> {
			if (mouseOverPalette() || toolbox.mouseOverToolbox()) {
				return;
			}
			var worldMousePos:Vector2 = gameContext.camera.worldMousePos();
			if (toolbox.selectedTool.toolDownFunc != null && !ui.isHovered) {
				toolbox.selectedTool.toolDownFunc(worldMousePos, tileSelected);
			}
		});
	}

	public function toggle() {
		show = !show;
		if (!show) {
			Mouse
				.get()
				.setSystemCursor(MouseCursor.Default);
		}
	}

	public function off() {
		show = false;
		Mouse
			.get()
			.setSystemCursor(MouseCursor.Default);
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

		uiLogic(ui, context);
	}

	function uiLogic(ui:Zui, gameContext:GameContext) {
		if (Application.mouseIsDown) {
			var worldMousePos:Vector2 = gameContext.camera.worldMousePos();
			if (toolbox.selectedTool.toolPaintFunc != null && !ui.isHovered) {
				toolbox.selectedTool.toolPaintFunc(worldMousePos, tileSelected);
			}
		}
	}

	public function getWindowMousePosition(ui:Zui, windowHandle:Handle):Vector2 {
		var windowPosition:Vector2 = new Vector2(0 + ui.TAB_W(), 0 + ui.HEADER_DRAG_H());
		var windowDragPosition:Vector2 = new Vector2(windowHandle.dragX, windowHandle.dragY);
		windowPosition = windowPosition.add(windowDragPosition);
		var mousePosition:Vector2 = new Vector2(Application.mouseX, Application.mouseY);

		var windowMousePosition:Vector2 = mousePosition.sub(windowPosition);
		return windowMousePosition;
	}

	public function mouseOverPalette():Bool {
		return Utils.windowContains(
			tilePaletteHandle,
			Application.mouseX,
			Application.mouseY
		);
	}

	public function renderPalette(context:GameContext, ui:Zui) {
		var zoom:Int = Application.getScreenZoom();
		var tilesheetAsset:Image = Assets.images.get(context.tilemap.tilesheet.originalSpriteName);

		var paletteWindow:Bool = ui.window(
			tilePaletteHandle,
			0,
			0,
			tilesheetAsset.width * zoom + 20,
			tilesheetAsset.height * zoom + 20,
			true
		);

		if (paletteWindow) {
			var tilePaletteImgState:State = ui.image(
				tilesheetAsset,
				0xffffffff,
				tilesheetAsset.height * zoom,
			);
			drawTilePaletteSelector(ui, context);
			if (tilePaletteImgState == State.Down) {
				handleTilePaletteSelection(ui, context);
			}
		}
	}

	public function renderUI(context:GameContext, ui:Zui) {
		renderPalette(context, ui);
		toolbox.render(ui, context);
		entityLibrary.render(ui, context);
	}

	function drawTilePaletteSelector(ui:Zui, context:GameContext) {
		var tilesheetAsset:Image = Assets.images.get(context.tilemap.tilesheet.originalSpriteName);
		var zoom:Int = Application.getScreenZoom();
		var tilesize:Float = context.tilemap.tilesize;
		var textCoords:Vector2 = context.tilemap.tilesheet.tileIndexToTexCoords(tileSelected, zoom);
		var sheetHeight:Int = tilesheetAsset.height * zoom;
		ui.rect(
			textCoords.x + ui.TAB_W(),
			textCoords.y - sheetHeight,
			tilesize * zoom,
			tilesize * zoom,
			Color.Yellow,
			2
		);
	}

	function handleTilePaletteSelection(ui:Zui, context:GameContext) {
		var windowMousePosition:Vector2 = getWindowMousePosition(ui, tilePaletteHandle);
		var zoom:Int = Application.getScreenZoom();

		tileSelected = context.tilemap.tilesheet.getTileIndex(
			windowMousePosition.x / zoom,
			windowMousePosition.y / zoom
		);

		trace("selected tile: " + tileSelected);
	}

	function drawString(f:Framebuffer, s:String, x:Float, y:Float) {
		var zoom:Int = Application.getScreenZoom();
		f.g2.fontSize = FONTSIZE;
		f.g2.drawString(s, x * zoom, y * zoom);
	}

	function drawLine(f:Framebuffer, x1:Float, y1:Float, x2:Float, y2:Float, strength:Float = 1.0) {
		var zoom:Int = Application.getScreenZoom();
		f.g2.drawLine(
			x1 * zoom,
			y1 * zoom,
			x2 * zoom,
			y2 * zoom,
			strength
		);
	}

	function renderGrid(context:GameContext, framebuffer:Framebuffer) {
		framebuffer.g2.font = Assets.fonts.fonts_monaco;
		framebuffer.g2.color = Color.White;
		var tilesize:Int = context.tilemap.getTilesize();

		var camera:Camera = context.camera;
		var cameraX:Float = camera.x;
		var cameraY:Float = camera.y;

		var worldMousePos:Vector2 = context.camera.worldMousePos();

		var startIndX:Int = cast Math.floor(worldMousePos.x / tilesize) - 1;
		var startIndY:Int = cast Math.floor(worldMousePos.y / tilesize) - 1;
		var endIndX:Int = startIndX + 4;
		var endIndY:Int = startIndY + 4;

		for (i in startIndX...endIndX) {
			drawString(
				framebuffer,
				Std.string(i),
				i * tilesize - cameraX,
				Math.max(0.0, -cameraY - FONTSIZE)
			);
			drawLine(framebuffer,
				i * tilesize
				- cameraX,
				startIndY * tilesize
				- cameraY
				- tilesize / 2,
				i * tilesize
				- cameraX,
				endIndY * tilesize
				- cameraY
				- tilesize / 2);
		}

		// horizontal lines
		for (i in startIndY...endIndY) {
			drawString(
				framebuffer,
				Std.string(i),
				Math.max(0, -cameraX - FONTSIZE),
				i * tilesize - cameraY
			);
			drawLine(framebuffer,
				startIndX * tilesize
				- cameraX
				- tilesize / 2,
				i * tilesize
				- cameraY,
				endIndX * tilesize
				- cameraX
				- tilesize / 2,
				i * tilesize
				- cameraY);
		}
	}
}
