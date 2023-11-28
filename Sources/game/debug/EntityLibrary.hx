package game.debug;

import haxe.ds.StringMap;
import zui.Id;
import zui.Zui;
import zui.Zui.Handle;
import helpers.LevelLoader;

class EntityLibrary {

	var windowHandle:Handle;
	var selectedHandle:Handle;
	var levelLoader:LevelLoader;

	static final START_X:Int = 0;
	static final START_Y:Int = 0;
	static final WIDTH:Int = 200;
	static final HEIGHT:Int = 200;

	public function new(editor:MapEditor, levelLoader:LevelLoader, gameContext:GameContext) {
		this.levelLoader = levelLoader;
		windowHandle = Id.handle();
		selectedHandle = Id.handle();
		selectedHandle.text = 'None';
	}

	public function render(ui:Zui, context:GameContext) {
		var windowActive:Bool = ui.window(
			windowHandle,
			START_X,
			START_Y,
			WIDTH,
			HEIGHT,
			true
		);
		if (windowActive) {
			if (ui.panel(Id.handle({selected: true}), "Entity Library")) {
				ui.text(selectedHandle.text);

				renderTemplateButtons(ui, context);
			}
		}
	}

	function renderTemplateButtons(ui:Zui, context:GameContext) {
		var entityTemplates:StringMap<Dynamic> = EntFactory
			.instance()
			.getEntityTemplates();
		for (key => value in entityTemplates) {
			if (ui.button(key, Align.Left)) {
				selectedHandle.text = key;
			}
		}
	}
}
