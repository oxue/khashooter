package refraction.core;

import pgr.dconsole.DC;
import hxblit.Camera;
import kha.Framebuffer;
import kha.input.KeyCode;
import kha.Scheduler;
import kha.System;
import kha.input.Keyboard;
import kha.input.Mouse;
import kha.math.Vector2;

class Application {
	public static var width:Int;
	public static var height:Int;
	public static var zoom:Int;

	public static var currentState:State;

	public static var mouseIsDown:Bool;
	public static var mouse2IsDown:Bool;
	public static var mouseX:Int;
	public static var mouseY:Int;

	public static var defaultCamera:Camera;

	public static var keys:Map<Int, Bool>;

	private static var lastTime:Float;

	private static var keyDownListeners:Array<KeyCode -> Void>;
	private static var keyUpListeners:Array<KeyCode -> Void>;

	public static function init(_title:String, _width:Int = 800, _height:Int = 600, _zoom:Int = 2,
			__callback:Void->Void):Void {
		currentState = new State();
		keys = new Map<Int, Bool>();

		width = _width;
		height = _height;
		zoom = _zoom;

		mouseX = mouseY = 0;
		mouseIsDown = false;
		 
		keyDownListeners = [];
		keyUpListeners = [];

		System.start({title: _title, width: _width, height: _height}, (window) -> {
			Mouse
				.get()
				.notify(mouseDown, mouseUp, mouseMove, null);
			Keyboard
				.get()
				.notify(keyDown, keyUp);

			Scheduler.addTimeTask(update, 0, 1 / 60);
			System.notifyOnFrames(render);

			lastTime = Scheduler.time();
			__callback();
		});
	}

	static public function resetKeyListeners() {
		keyDownListeners = keyUpListeners = [];
	}

	static public function mouseCoords():Vector2 {
		return new Vector2(mouseX, mouseY);
	}

	static private function mouseMove(x:Int, y:Int, dX:Int, dY:Int) {
		mouseX = x;
		mouseY = y;
	}

	static private function mouseDown(button:Int, x:Int, y:Int) {
		if (button == 0)
			mouseIsDown = true;
		if (button == 1)
			mouse2IsDown = true;
	}

	static private function mouseUp(button:Int, x:Int, y:Int) {
		if (button == 0)
			mouseIsDown = false;
		if (button == 1)
			mouse2IsDown = false;
	}

	static private function keyDown(key:KeyCode) {
		// if (char != null)
		keys.set(key, true);
		for(method in keyDownListeners) {
			method(key);
		}
	}

	static private function keyUp(key:KeyCode) {
		// if(char != null)
		keys.set(key, false);
		for(method in keyUpListeners) {
			method(key);
		}
	}

	public static function setState(_state:State) {
		currentState.unload();
		currentState = _state;
		_state.load();
	}

	private static function update() {
		currentState.update();
	}

	public static function render(frame:Array<Framebuffer>) {
		currentState.render(frame[0]);
	}

	public static function addKeyUpListener(method:KeyCode->Void){
		keyUpListeners.push(method);
	}

	public static function addKeyDownListener(method:KeyCode->Void){
		keyDownListeners.push(method);
	}
}


