package game;

import kha.input.KeyCode;
import refraction.core.Application;
import pgr.dconsole.DConsole;
import pgr.dconsole.input.DCInput;

class ConsoleInput implements DCInput {
	public var console:DConsole;
	public var enabled:Bool;

	public function new() {
		trace("one");
		enabled = false;
		Application.addKeyDownListener(onKeyDown);
	}

	public function init() {
		enable();
	}

	public function enable() {

	}

	public function disable() {

	}

	public function onKeyUp(key:KeyCode) {

	}

	public function onKeyDown(key:KeyCode) {
		if (Std.int(key) == console.consoleKey.keycode) {
			trace(console.visible);
			if (console.visible) {
				console.hideConsole();
			} else {
				console.showConsole();
			}
			return;
		}
		else if(!console.visible) {
			return;
		}

		if (Std.int(key) == KeyCode.Return)
			console.processInputLine();
		if (Std.int(key) == KeyCode.Up)
			console.nextHistory();
		if (Std.int(key) == KeyCode.Down)
			console.prevHistory();
		if (Std.int(key) == KeyCode.PageUp)
			console.scrollUp();
		if (Std.int(key) == KeyCode.PageDown)
			console.scrollDown();
	}
}