package game.debug;

import haxe.Timer;
import helpers.DebugLogger;
import kha.Color;
import kha.math.Vector2;
import zui.Zui;
import kha.Image;
import kha.Assets;
import refraction.core.Application;

class TilePalette extends EditorWindow {

    var tilesheetAsset:Image;

    public var tileSelected:Int;

    public function new(context:GameContext) {
        tilesheetAsset = Assets.images.get(context.tilemap.tilesheet.originalSpriteName);
        super(
            "tile_palette",
            0,
            0,
            tilesheetAsset.width + 20,
            tilesheetAsset.height + 20,
            true
        );

        tileSelected = 0;
    }

    public function render(ui:Zui, context:GameContext) {
        if (windowActive(ui)) {
            var tilePaletteImgState:State = ui.image(
                tilesheetAsset,
                0xffffffff,
                tilesheetAsset.height,
            );
            drawTilePaletteSelector(ui, context);
            if (tilePaletteImgState == State.Down) {
                handleTilePaletteSelection(ui, context);
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

    function handleTilePaletteSelection(ui:Zui, context:GameContext) {
        var windowMousePosition:Vector2 = getWindowMousePosition(ui, windowHandle);

        tileSelected = context.tilemap.tilesheet.getTileIndex(windowMousePosition.x, windowMousePosition.y);

        DebugLogger.info("EDITOR", "selected tile: " + tileSelected);
    }

    function drawTilePaletteSelector(ui:Zui, context:GameContext) {
        var tilesheetAsset:Image = Assets.images.get(context.tilemap.tilesheet.originalSpriteName);
        var tilesize:Float = context.tilemap.tilesize;
        var textCoords:Vector2 = context.tilemap.tilesheet.tileIndexToTexCoords(tileSelected, 1);
        var sheetHeight:Int = tilesheetAsset.height;
        var alpha:Int = Std.int((Timer.stamp() % 1.0) * 256) << 24;
        ui.rect(
            textCoords.x + ui.TAB_W(),
            textCoords.y - sheetHeight,
            tilesize,
            tilesize,
            Color.Magenta,
            3
        );
    }
}
