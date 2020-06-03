package game;

import kha.Color;
import zui.Ext;
import zui.Id;
import zui.Zui;
import helpers.DebugLogger;
import pgr.dconsole.DConsole;
import pgr.dconsole.ui.DCInterface;

class Console implements DCInterface {
	public var console:DConsole;

	private var logger:String->Void;

	private var consoleText:Zui->Void;
	private var consoleTextVisible:Bool = true;

	public var consoleTextHandle:Handle;

	private var consoleWindowHandle:Handle;

	private var promptText:Zui->Void;
	private var promptHandle:Handle;
	private var promptTextVisible:Bool = true;
	private var promptWindowHandle:Handle;

	private var ui:Zui;

	public function new(_logger:String->Void, ui:Zui) {
		logger = _logger;
		this.ui = ui;
	}

	public function init() {
		logger("initializing console");
		createConsoleDisplay();
	}

	public function redraw() {
		consoleWindowHandle.redraws = 1;
		promptWindowHandle.redraws = 1;
	}

	function createConsoleDisplay() {
		consoleTextHandle = Id.handle();
		consoleWindowHandle = Id.handle();
		this.consoleText = (ui) -> {
			if (!consoleTextVisible) {
				return;
			}
			if (ui.window(consoleWindowHandle, 0, 0, 600, 600, false)) {
				Ext.textArea(ui, consoleTextHandle);
			}
		}

		promptHandle = Id.handle();
		promptWindowHandle = Id.handle();
		this.promptText = (ui) -> {
			if (!promptTextVisible) {
				return;
			}
			if (ui.window(promptWindowHandle, 0, 600, 600, 100, false)) {
				ui.textInput(promptHandle);
			}
		}
	}

	public function draw() {
		this.consoleText(ui);
		this.promptText(ui);
	}

	public function showConsole() {
		consoleTextVisible = true;
		promptTextVisible = true;
	}

	public function hideConsole() {
		promptTextVisible = false;
		consoleTextVisible = false;
	}

	public function log(data:Dynamic, color:Int) {
		var strData = Std.string(data);
		consoleTextHandle.text += (strData + '\n');
		var textHeight = consoleTextHandle.text
			.split('\n')
			.length * ui.ELEMENT_H();
		if (textHeight >= 600) {
			consoleWindowHandle.scrollOffset = 600 - textHeight;
		}

		if (color == -1) {
			consoleTextHandle.color = Color.fromValue(color);
			var l = strData.length;
		} else {
			consoleTextHandle.color = Color.White;
		}
	}

	public function setPromptFont(font:String = null, embed:Bool = false, size:Int = 16, bold:Bool = false,
		?italic:Bool = false, underline:Bool = false) {}

	public function setProfilerFont(font:String = null, embed:Bool = false, size:Int = 14,
		bold:Bool = false, ?italic:Bool = false, underline:Bool = false) {}

	public function setMonitorFont(font:String = null, embed:Bool = false, size:Int = 14, bold:Bool = false,
		?italic:Bool = false, underline:Bool = false) {}

	public function writeMonitorOutput(output:Array<String>) {}

	public function showMonitor() {}

	public function hideMonitor() {}

	public function writeProfilerOutput(output:String) {}

	public function showProfiler() {}

	public function hideProfiler() {}

	public function moveCarretToEnd() {}

	public function scrollConsoleUp() {
		consoleTextHandle.scrollOffset += ui.ELEMENT_H();
		if (consoleTextHandle.scrollOffset > 0) {
			consoleTextHandle.scrollOffset = 0;
		}
	}

	public function scrollConsoleDown() {
		consoleTextHandle.scrollOffset -= ui.ELEMENT_H();
	}

	function scrollToBottom() {
		var textHeight = consoleTextHandle.text
			.split('\n')
			.length * ui.ELEMENT_H();
		if (textHeight >= 600) {
			consoleWindowHandle.scrollOffset = 600 - textHeight;
		}
	}

	public function toFront() {}

	public function setConsoleFont(font:String = null, embed:Bool = false, size:Int = 14, bold:Bool = false,
		italic:Bool = false, underline:Bool = false) {}

	public function inputRemoveLastChar() {
		if (promptHandle.text.length > 0) {
			promptHandle.text = promptHandle.text.substr(0, promptHandle.text.length - 1);
		}
		redraw();
	}

	public function getInputTxt():String {
		redraw();
		return promptHandle.text;
	}

	public function setInputTxt(string:String) {
		promptHandle.text = string;
		redraw();
	}

	public function getConsoleText():String {
		return consoleTextHandle.text;
	}

	public function getMonitorText() {
		return {
			col1: "",
			col2: "",
		}
	}

	public function clearInput() {
		promptHandle.text = "";
		redraw();
	}

	public function clearConsole() {
		consoleTextHandle.text = "";
		redraw();
	}
}
