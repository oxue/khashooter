package game.debug;

import kha.input.KeyCode;
import refraction.generic.PositionCmp;
import kha.math.Vector2;
import refraction.display.SurfaceSetCmp;
import refraction.display.AnimatedRenderCmp;
import kha.Color;
import haxe.Timer;
import kha.Framebuffer;
import refraction.core.Application;
import refraction.generic.DimensionsCmp;
import refraction.core.Entity;
import haxe.ds.StringMap;
import zui.Id;
import zui.Zui;
import zui.Zui.Handle;
import helpers.LevelLoader;

class EntityLibrary extends EditorWindow {

    var selectedHandle:Handle;
    var levelLoader:LevelLoader;
    var selectedEntity:Dynamic;
    var selectedEntityProto:Entity;
    var toolbox:Toolbox;

    static final START_X:Int = 0;
    static final START_Y:Int = 0;
    static final WIDTH:Int = 200;
    static final HEIGHT:Int = 200;

    public function new(editor:MapEditor, toolbox:Toolbox, levelLoader:LevelLoader, gameContext:GameContext) {
        this.levelLoader = levelLoader;
        this.toolbox = toolbox;
        this.selectedEntity = null;

        super("entity_library", START_X, START_Y, WIDTH, HEIGHT);

        selectedHandle = Id.handle();
        selectedHandle.text = 'None';

        Application.addKeyDownListener((key) -> {
            if (key == Escape) {
                entityPlacerDeactivate();
            }
        });

        Application.addMouseDownListener((button, x, y) -> {
            if (button == 0 && isEntityPlacerActive()) {
                var mouse:Vector2 = EntFactory.instance().worldMouse();
                var entity:Entity = EntFactory.instance().autoBuild(selectedEntity.entity_name);
                entity.getComponent(PositionCmp).setPosition(mouse.x, mouse.y);
                if (!Application.keys.get(KeyCode.Shift)) {
                    entityPlacerDeactivate();
                }
            }
        });
    }

    public function renderUiElements(ui:Zui, context:GameContext) {
        if (windowActive(ui)) {
            if (ui.panel(Id.handle({selected: true}), "Entity Library")) {
                ui.text(selectedHandle.text);
                renderTemplateButtons(ui, context);
            }
        }
    }

    public function render(ui:Zui, context:GameContext) {
        renderUiElements(ui, context);
    }

    public function renderSelectedEntityDimension(f:Framebuffer, context:GameContext) {
        if (selectedEntity != null) {
            var size:Dynamic = getEntitySize(selectedEntity);
            var alpha:Int = Std.int(Math.abs(Timer.stamp() % 0.5 - 0.25)/0.25 * 255) << 24;
            f.g2.color = 0xffffff | alpha;
            var zoom:Int = Application.getScreenZoom();
            var lockMouseCoords:Vector2 = lockMouseCoordsToGrid(8);

            f.g2.fillRect(
                lockMouseCoords.x,
                lockMouseCoords.y,
                size.w * zoom,
                size.h * zoom,
            );
        }
    }

    function lockMouseCoordsToGrid(gridSize:Int):Vector2 {
        var mouse:Vector2 = EntFactory.instance().worldMouse();
        mouse.x = Std.int(mouse.x / gridSize) * gridSize;
        mouse.y = Std.int(mouse.y / gridSize) * gridSize;
        return mouse.sub(GameContext.instance().camera.position()).mult(Application.getScreenZoom());
    }

    function getEntitySize(Entity):Dynamic {
        var dim:DimensionsCmp = selectedEntityProto.getComponent(DimensionsCmp);
        if (dim != null) {
            return {
                w: dim.width,
                h: dim.height,
            }
        }
        var surfaceSet:SurfaceSetCmp = selectedEntityProto.linSearchType(SurfaceSetCmp);
        if (surfaceSet != null) {
            return {
                w: surfaceSet.frame.w,
                h: surfaceSet.frame.h,
            }
        }
        return {
            w: 1,
            h: 1,
        };
    }

    public function entityPlacerDeactivate() {
        selectedEntity = null;
        selectedHandle.text = 'None';
    }

    public function isEntityPlacerActive():Bool {
        return selectedEntity != null;
    }

    function renderTemplateButtons(ui:Zui, context:GameContext) {
        var entityTemplates:StringMap<Dynamic> = EntFactory
            .instance()
            .getEntityTemplates();
        for (key => value in entityTemplates) {
            entityButton(ui, key, value);
        }
    }

    function entityButton(ui:Zui, key:String, value:Dynamic) {
        if (ui.button(value.entity_name, Align.Left)) {
            selectedEntity = value;
            selectedHandle.text = selectedEntity.entity_name;
            selectedEntityProto = EntFactory
                .instance()
                .autoBuild(selectedEntity.entity_name);
            selectedEntityProto.remove();
        }
    }
}
