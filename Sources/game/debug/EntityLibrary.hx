package game.debug;

import haxe.ds.StringMap;
import zui.Id;
import zui.Zui;
import zui.Zui.Handle;
import helpers.LevelLoader;

class EntityLibrary extends EditorWindow {

    var selectedHandle:Handle;
    var levelLoader:LevelLoader;
    var selectedEntity:Dynamic;
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
    }

    public function render(ui:Zui, context:GameContext) {
        if (windowActive(ui)) {
            if (ui.panel(Id.handle({selected: true}), "Entity Library")) {
                ui.text(selectedHandle.text);
                renderTemplateButtons(ui, context);
            }
        }
    }

    public function entityPlacerActive():Bool {
        return selectedEntity != null;
    }

    function renderTemplateButtons(ui:Zui, context:GameContext) {
        var entityTemplates:StringMap<Dynamic> = EntFactory
            .instance()
            .getEntityTemplates();
        for (key => value in entityTemplates) {
            if (ui.button(value.entity_name, Align.Left)) {
                selectedEntity = value;
                selectedHandle.text = selectedEntity.entity_name;
            }
        }
    }
}
