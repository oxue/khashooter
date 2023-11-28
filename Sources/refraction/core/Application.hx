package refraction.core;

import hxblit.Camera;
import kha.Framebuffer;
import kha.Scheduler;
import kha.System;
import kha.input.KeyCode;
import kha.input.Keyboard;
import kha.input.Mouse;
import kha.math.Vector2;

class Application {

	static var width:Int;
	static var height:Int;
	static var zoom:Int;

	public static var currentState:State;

	public static var mouseIsDown:Bool;
	public static var mouse2IsDown:Bool;
	public static var mouseX:Int;
	public static var mouseY:Int;

	public static var mouseJustDown:Bool;
	public static var mouse2JustDown:Bool;
	public static var mouseJustUp:Bool;
	public static var mouse2JustUp:Bool;

	public static var defaultCamera:Camera;

	public static var keys:Map<Int, Bool>;
	public static var frameClock:Int;

	static var lastTime:Float;

	static var keyDownListeners:Array<KeyCode -> Void>;
	static var keyUpListeners:Array<KeyCode -> Void>;
	static var mouseDownListeners:Array<(Int, Int, Int) -> Void>;
	static var mouseUpListeners:Array<(Int, Int, Int) -> Void>;

	static var mouseWasDown:Bool;
	static var mouse2WasDown:Bool;

	public static function init(_title:String, _width:Int = 800, _height:Int = 600, _zoom:Int = 2,
			__callback:Void -> Void) {
		currentState = new State();
		keys = new Map<Int, Bool>();

		width = _width;
		height = _height;
		zoom = _zoom;

		mouseX = mouseY = 0;
		mouseIsDown = mouseWasDown = mouse2IsDown = mouse2WasDown = false;

		frameClock = 0;

		keyDownListeners = [];
		keyUpListeners = [];
		mouseDownListeners = [];
		mouseUpListeners = [];

		System.start(
			{title: _title, width: _width, height: _height},
			(window) -> {
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
			}
		);
	}

	/**
	 * width in pixels of the window, not the graphics
	 * @return Int
	 */
	public static function getScreenWidth():Int {
		return width;
	}

	/**
	 * height in pixels of the window, not the graphics
	 * @return Int
	 */
	public static function getScreenHeight():Int {
		return height;
	}

	/**
	 * zoom of the graphics, width and height divided by zoom is the window size
	 * @return Int
	 */
	public static function getScreenZoom():Int {
		return zoom;
	}

	public static function resetKeyListeners() {
		keyDownListeners = keyUpListeners = [];
	}

	public static function mouseCoords():Vector2 {
		return new Vector2(mouseX, mouseY);
	}

	static function mouseMove(x:Int, y:Int, dX:Int, dY:Int) {
		mouseX = x;
		mouseY = y;
	}

	static function mouseDown(button:Int, x:Int, y:Int) {
		for (method in mouseDownListeners) {
			method(button, x, y);
		}
		if (button == 0)
			mouseIsDown = true;
		if (button == 1)
			mouse2IsDown = true;
	}

	static function mouseUp(button:Int, x:Int, y:Int) {
		for (method in mouseUpListeners) {
			method(button, x, y);
		}
		if (button == 0)
			mouseIsDown = false;
		if (button == 1)
			mouse2IsDown = false;
	}

	static function keyDown(key:KeyCode) {
		keys.set(key, true);
		for (method in keyDownListeners) {
			method(key);
		}
	}

	static function keyUp(key:KeyCode) {
		// if(char != null)
		keys.set(key, false);
		for (method in keyUpListeners) {
			method(key);
		}
	}

	public static function setState(_state:State) {
		currentState.unload();
		currentState = _state;
		_state.load();
	}

	static function update() {
		var m2:Bool = mouse2IsDown;
		var m:Bool = mouseIsDown;

		currentState.update();
		mouse2JustDown = m2 && !mouse2WasDown;
		mouseJustDown = m && !mouseWasDown;

		mouse2JustUp = !m2 && mouse2WasDown;
		mouseJustUp = !m && mouseWasDown;

		mouse2WasDown = m2;
		mouseWasDown = m;

		frameClock++;
	}

	public static function render(frame:Array<Framebuffer>) {
		currentState.render(frame[0]);
	}

	public static function addKeyUpListener(method:KeyCode -> Void) {
		keyUpListeners.push(method);
	}

	public static function addKeyDownListener(method:KeyCode -> Void) {
		keyDownListeners.push(method);
	}

	public static function addMouseDownListener(method:(Int, Int, Int) -> Void) {
		mouseDownListeners.push(method);
	}

	public static function addMouseUpListener(method:(Int, Int, Int) -> Void) {
		mouseUpListeners.push(method);
	}
}
