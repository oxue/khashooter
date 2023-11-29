package game.debug;

import refraction.core.Utils;
import helpers.LevelLoader;
import kha.Assets;
import kha.input.KeyCode;
import kha.input.Mouse;
import kha.math.Vector2;
import refraction.core.Application;
import refraction.tilemap.Tile;
import refraction.tilemap.TileMap;
import zui.Id;
import zui.Zui;

enum ToolType {
    Cursor;
    Brush;
    Bucket;
    RecomputePolys;
    ChangeMapWidth;
    IncreaseMapHeight;
    ExportMap;
	ExportLayoutConfig;
}

@:structInit
typedef Tool = {
    toolNum:Int,
    toolType:ToolType,
    toolLabel:String,
    toolDescription:String,
    ?toolCursor:MouseCursor,
    toolFunc:(Tool, GameContext) -> Void,
    ?toolPaintFunc:(Vector2, Int) -> Void,
    ?toolDownFunc:(Vector2, Int) -> Void
}

class Toolbox extends EditorWindow {

    public var selectedTool:Tool;

    var levelLoader:LevelLoader;
    var tools:Array<Tool>;
    var redrawToolChange:Bool;

    public function new(editor:MapEditor, levelLoader:LevelLoader, gameContext:GameContext) {
        this.levelLoader = levelLoader;
        var toolnumCounter = 0;
        redrawToolChange = false;

        function setToolFunc(tool:Tool, context:GameContext) {
            this.selectedTool = tool;
            if (tool.toolCursor != null) {
                Mouse
                    .get()
                    .setSystemCursor(tool.toolCursor);
            } else {
                Mouse
                    .get()
                    .setSystemCursor(MouseCursor.Default);
            }
        }

        this.tools = [
            {
                toolNum: ++toolnumCounter,
                toolType: ToolType.Cursor,
                toolLabel: "Cursor",
                toolDescription: "Cursor",
                toolFunc: setToolFunc
            },
            {
                toolNum: ++toolnumCounter,
                toolType: ToolType.Brush,
                toolLabel: "Brush",
                toolDescription: "Brush",
                toolFunc: setToolFunc,
                toolCursor: MouseCursor.Custom(Assets.images.brush),
                toolPaintFunc: function(worldPos:Vector2, tileSelected:Int) {
                    var tile:Tile = gameContext.tilemap.getTileContainingVec2(worldPos);
                    if (tile != null) {
                        tile.imageIndex = tileSelected;
                        tile.solid = tileSelected > gameContext.tilemap.colIndex;
                    }
                }
            },
            {
                toolNum: ++toolnumCounter,
                toolType: ToolType.Bucket,
                toolLabel: "Bucket",
                toolDescription: "Paint Bucket",
                toolFunc: setToolFunc,
                toolCursor: MouseCursor.Custom(Assets.images.bucket),
                toolPaintFunc: function(worldPos:Vector2, tileSelected:Int) {
                    var tm:TileMap = gameContext.tilemap;
                    var tx:Int = tm.getIndexAtFloat(worldPos.x);
                    var ty:Int = tm.getIndexAtFloat(worldPos.y);
                    floodFill(
                        tm,
                        tx,
                        ty,
                        tileSelected,
                        tm
                            .getTileAt(ty, tx)
                            .imageIndex
                    );
                }
            },
            {
                toolNum: ++toolnumCounter,
                toolType: ToolType.ChangeMapWidth,
                toolLabel: "Map Width",
                toolDescription: "Change Map Width",
                toolFunc: setToolFunc,
                toolDownFunc: function(worldPos:Vector2, tileSelected:Int) {
                    var tm:TileMap = gameContext.tilemap;
                    var tx:Int = tm.getIndexAtFloat(worldPos.x);
                    var ty:Int = tm.getIndexAtFloat(worldPos.y);
                    tm.genericResizeFunc(tx, ty, () -> new Tile(1, false));
                    gameContext.dijkstraMap.genericResizeFunc(tx, ty, () -> null);
                }
            },
            {
                toolNum: ++toolnumCounter,
                toolType: ToolType.RecomputePolys,
                toolLabel: "Re-Poly",
                toolDescription: "Recompute Shadow Polys",
                toolFunc: function(tool:Tool, context:GameContext) {
                    context.recomputeShadowPolys();
                }
            },
            {
                toolNum: ++toolnumCounter,
                toolType: ToolType.ExportMap,
                toolLabel: "Export",
                toolDescription: "Export Map",
                toolFunc: function(tool:Tool, context:GameContext) {
                    this.levelLoader.export();
                }
            },
            {
                toolNum: ++toolnumCounter,
                toolType: ToolType.ExportLayoutConfig,
                toolLabel: "Export Layout",
                toolDescription: "Export Editor Layout",
                toolFunc: function(tool:Tool, context:GameContext) {
                    editor.exportLayoutConfig();
                }
            }
        ];
        selectedTool = this.tools[0];

        super("tool_box", 0, 0, 100, 500, true);

        Application.addKeyDownListener((code:KeyCode) -> {
            if (isNumKey(code)) {
                var toolIndex:Int = code - cast One;
                this.tools[toolIndex].toolFunc(this.tools[toolIndex], gameContext);
            }
            windowHandle.redraws = 1;
        });

        windowHandle = Id.handle();
    }

    function isNumKey(code:KeyCode):Bool {
        var codeInt:Int = Std.int(code);
        return (codeInt >= Std.int(Zero)) && (codeInt <= Std.int(Nine));
    }

    function getToolLabel(t:Tool):String {
        var selectionIndicator:String = '${t.toolNum}';
        if (selectedTool.toolType == t.toolType) {
            selectionIndicator = '> ${t.toolNum}';
        }
        return '${selectionIndicator} ${Std.string(t.toolLabel)}';
    }

    function floodFill(tm:TileMap, tx:Int, ty:Int, tileSelected:Int, targetIndex:Int) {
        var tile:Tile = tm.getTileAt(ty, tx);
        if (tile != null) {
            if (tile.imageIndex == targetIndex && targetIndex != tileSelected) {
                tile.imageIndex = tileSelected;
                tile.solid = tileSelected > tm.colIndex;
                floodFill(tm, tx - 1, ty, tileSelected, targetIndex);
                floodFill(tm, tx + 1, ty, tileSelected, targetIndex);
                floodFill(tm, tx, ty - 1, tileSelected, targetIndex);
                floodFill(tm, tx, ty + 1, tileSelected, targetIndex);
            }
        }
    }

    public function mouseOverToolbox():Bool {
        return Utils.windowContains(
            windowHandle,
            Application.mouseX,
            Application.mouseY
        );
    }

    public function render(ui:Zui, context:GameContext) {
        if (windowActive(ui)) {
            for (t in this.tools) {
                var buttonLabel:String = getToolLabel(t);
                if (ui.button(buttonLabel)) {
                    t.toolFunc(t, context);
                }
                if (ui.isHovered) {
                    ui.tooltip(buttonLabel);
                }
            }
        }
    }
}
