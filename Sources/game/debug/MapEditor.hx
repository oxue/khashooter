package game.debug;

import haxe.ds.StringMap;
import haxe.io.Mime;
import js.html.URL;
import js.Browser;
import haxe.Json;
import helpers.LevelLoader;
import hxblit.Camera;
import kha.Assets;
import kha.Color;
import kha.Framebuffer;
import kha.input.Mouse;
import kha.math.Vector2;
import refraction.core.Application;
import zui.Zui;

class MapEditor {

    static final FONTSIZE:Int = 16;

    var show:Bool;
    var levelLoader:LevelLoader;

    // element
    var tilePalette:TilePalette;
    var toolbox:Toolbox;
    var entityLibrary:EntityLibrary;
    var windowElements:Array<EditorWindow>;
    var windowElementsMap:StringMap<EditorWindow>;

    public function new(gameContext:GameContext, levelLoader:LevelLoader, ui:Zui) {
        show = false;

        tilePalette = new TilePalette(gameContext);
        toolbox = new Toolbox(this, levelLoader, gameContext);
        entityLibrary = new EntityLibrary(this, toolbox, levelLoader, gameContext);

        windowElements = [tilePalette, toolbox, entityLibrary];
        windowElementsMap = new StringMap<EditorWindow>();
        for (element in windowElements) {
            windowElementsMap.set(element.getName(), element);
        }

        importLayout();

        this.levelLoader = levelLoader;

        Application.addMouseDownListener((button, x, y) -> {
            if (!mouseShouldPaint()) {
                return;
            }
            var worldMousePos:Vector2 = gameContext.camera.worldMousePos();
            if (toolbox.selectedTool.toolDownFunc != null && !ui.isHovered) {
                toolbox.selectedTool.toolDownFunc(worldMousePos, tilePalette.tileSelected);
            }
        });
    }

    function saveFile(name:String, mime:Mime, data:String) {
        final blob = new js.html.Blob([data], {
            type: mime
        });
        final url = URL.createObjectURL(blob);
        final a = Browser.document.createElement("a");
        untyped a.download = name;
        untyped a.href = url;
        a.onclick = function(e) {
            e.cancelBubble = true;
            e.stopPropagation();
        }
        Browser.document.body.appendChild(a);
        a.click();
        Browser.document.body.removeChild(a);
        URL.revokeObjectURL(url);
    }

    public function importLayout() {
        var obj:Dynamic = Json.parse(Std.string(Assets.blobs.layout_json));

        for (element in cast(obj, Array<Dynamic>)) {
            var windowElement:EditorWindow = windowElementsMap.get(element.name);
            if (windowElement != null) {
                windowElement.setStartPositions(element.x, element.y);
            }
        }
    }

    public function exportLayoutConfig() {
        var layout:Array<Dynamic> = [];

        for (elements in windowElements) {
            layout.push(elements.getSettings());
        }

        trace(Json.stringify(layout));

        saveFile(
            "layout.json",
            Mime.ApplicationJson,
            Json.stringify(layout)
        );
    }

    function mouseShouldPaint():Bool {
        for (windowElement in windowElements) {
            if (windowElement.windowContainsCursor()) {
                return false;
            }
        }
        return true;
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

        entityLibrary.renderSelectedEntityDimension(f, context);
        f.g2.end();

        ui.begin(f.g2);
        renderUI(context, ui);
        ui.end();

        uiLogic(ui, context);
    }

    function uiLogic(ui:Zui, gameContext:GameContext) {
        if (Application.mouseIsDown) {
            mouseDownLogic(gameContext);
        }
    }

    function mouseDownLogic(gameContext) {
        var worldMousePos:Vector2 = gameContext.camera.worldMousePos();
        if (mouseShouldPaint()) {
            if (toolbox.selectedTool.toolPaintFunc != null) {
                toolbox.selectedTool.toolPaintFunc(worldMousePos, tilePalette.tileSelected);
            }
        }
    }

    public function renderUI(context:GameContext, ui:Zui) {
        tilePalette.render(ui, context);
        toolbox.render(ui, context);
        entityLibrary.render(ui, context);
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
            var tilePosition = i * tilesize;
            drawString(
                framebuffer,
                Std.string(i),
                tilePosition - cameraX,
                Math.max(0.0, -cameraY - FONTSIZE)
            );
            drawLine(framebuffer,
                tilePosition
                - cameraX,
                startIndY * tilesize
                - cameraY
                - tilesize / 2,
                tilePosition
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
