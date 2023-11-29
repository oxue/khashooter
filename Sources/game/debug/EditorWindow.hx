package game.debug;

import refraction.core.Application;
import zui.Zui;
import zui.Zui.Handle;

class EditorWindow {

    var name:String;
    var windowHandle:Handle;

    var startX:Int;
    var startY:Int;
    var width:Int;
    var height:Int;
    var draggable:Bool;

    public function new(name:String, startX:Int, startY:Int, width:Int, height:Int, draggable:Bool = true) {
        this.name = name;
        this.startX = startX;
        this.startY = startY;
        this.width = width;
        this.height = height;
        this.draggable = draggable;

        this.windowHandle = new Handle();
    }

    public function windowContainsCursor():Bool {
        return windowContains(Application.mouseX, Application.mouseY);
    }

    public function getName():String {
        return name;
    }

    public function setStartPositions(x:Int, y:Int) {
        startX = x;
        startY = y;
    }

    public function windowContains(x:Float, y:Float):Bool {
        return (x >= windowHandle.dragX + startX
            && x <= windowHandle.dragX + startX
            && y >= windowHandle.dragY + startY
            && y <= windowHandle.dragY + startY + height);
    }

    public function windowActive(ui:Zui):Bool {
        return ui.window(
            windowHandle,
            startX,
            startY,
            width,
            height,
            draggable
        );
    }

    public function getSettings():Dynamic {
        return {
            name: name,
            x: startX + windowHandle.dragX,
            y: startY + windowHandle.dragY,
        };
    }
}
