package game;

import net.RoomClient;
import kha.Assets;
import kha.Color;
import kha.Framebuffer;
import kha.Font;
import kha.input.KeyCode;
import refraction.core.Application;

class MenuState extends refraction.core.State {

    var selectedButton:Int;
    var buttons:Array<String>;

    // Sub-screens
    var screen:String; // "main", "create", "join"
    var activeField:String; // which text field is active: "name", "code"
    var playerName:String;
    var selectedMap:Int;
    var maps:Array<String>;
    var roomCode:String;
    var statusMessage:String;

    var assetsLoaded:Bool;
    var font:Font;
    var titleFont:Font;

    var hoverButton:Int; // which button the mouse is over (-1 for none)

    override public function load() {
        buttons = ["Single Player", "Create Room", "Join Room"];
        screen = "main";
        activeField = "name";
        playerName = "Player";
        selectedMap = 0;
        maps = ["level2", "bloodstrike_zm", "modern_home", "rooms"];
        roomCode = "";
        statusMessage = "";
        selectedButton = -1;
        hoverButton = -1;
        assetsLoaded = false;

        Assets.loadEverything(onAssetsLoaded);
    }

    function onAssetsLoaded() {
        font = Assets.fonts.fonts_OpenSans;
        titleFont = Assets.fonts.fonts_OpenSans;
        assetsLoaded = true;

        Application.addKeyDownListener(onKeyDown);
        Application.addMouseDownListener(onMouseDown);
    }

    override public function unload() {
        Application.resetKeyListeners();
    }

    // =====================
    // INPUT
    // =====================

    function onMouseDown(button:Int, x:Int, y:Int) {
        if (button != 0) return;
        if (!assetsLoaded) return;

        var screenW:Float = Application.getScreenWidth();
        var screenH:Float = Application.getScreenHeight();

        if (screen == "main") {
            var btnW:Float = 300;
            var btnH:Float = 50;
            var startY:Float = screenH * 0.4;
            var spacing:Float = 70;
            var btnX:Float = (screenW - btnW) / 2;

            for (i in 0...buttons.length) {
                var btnY:Float = startY + i * spacing;
                if (x >= btnX && x <= btnX + btnW && y >= btnY && y <= btnY + btnH) {
                    handleMainButton(i);
                    return;
                }
            }
        } else if (screen == "create") {
            handleCreateClick(x, y, screenW, screenH);
        } else if (screen == "join") {
            handleJoinClick(x, y, screenW, screenH);
        }
    }

    function handleMainButton(index:Int) {
        switch (index) {
            case 0:
                // Single Player
                Application.setState(new GameState("level2"));
            case 1:
                // Create Room
                screen = "create";
                activeField = "name";
                statusMessage = "";
            case 2:
                // Join Room
                screen = "join";
                activeField = "name";
                roomCode = "";
                statusMessage = "";
        }
    }

    function handleCreateClick(mx:Int, my:Int, screenW:Float, screenH:Float) {
        var centerX:Float = screenW / 2;
        var baseY:Float = screenH * 0.35;

        // Name field click
        var fieldX:Float = centerX - 50;
        var fieldW:Float = 200;
        var nameFieldY:Float = baseY;
        if (mx >= fieldX && mx <= fieldX + fieldW && my >= nameFieldY && my <= nameFieldY + 30) {
            activeField = "name";
            return;
        }

        // Map left arrow
        var mapY:Float = baseY + 60;
        var arrowLeft:Float = centerX - 80;
        if (mx >= arrowLeft && mx <= arrowLeft + 30 && my >= mapY && my <= mapY + 30) {
            selectedMap = (selectedMap - 1 + maps.length) % maps.length;
            return;
        }
        // Map right arrow
        var arrowRight:Float = centerX + 80;
        if (mx >= arrowRight && mx <= arrowRight + 30 && my >= mapY && my <= mapY + 30) {
            selectedMap = (selectedMap + 1) % maps.length;
            return;
        }

        // Create button
        var btnY:Float = baseY + 140;
        var createBtnX:Float = centerX - 130;
        if (mx >= createBtnX && mx <= createBtnX + 120 && my >= btnY && my <= btnY + 45) {
            handleCreateRoom();
            return;
        }
        // Back button
        var backBtnX:Float = centerX + 10;
        if (mx >= backBtnX && mx <= backBtnX + 120 && my >= btnY && my <= btnY + 45) {
            screen = "main";
            return;
        }
    }

    function handleJoinClick(mx:Int, my:Int, screenW:Float, screenH:Float) {
        var centerX:Float = screenW / 2;
        var baseY:Float = screenH * 0.35;

        // Name field
        var fieldX:Float = centerX - 50;
        var fieldW:Float = 200;
        var nameFieldY:Float = baseY;
        if (mx >= fieldX && mx <= fieldX + fieldW && my >= nameFieldY && my <= nameFieldY + 30) {
            activeField = "name";
            return;
        }
        // Room code field
        var codeFieldY:Float = baseY + 60;
        if (mx >= fieldX && mx <= fieldX + fieldW && my >= codeFieldY && my <= codeFieldY + 30) {
            activeField = "code";
            return;
        }

        // Join button
        var btnY:Float = baseY + 140;
        var joinBtnX:Float = centerX - 130;
        if (mx >= joinBtnX && mx <= joinBtnX + 120 && my >= btnY && my <= btnY + 45) {
            handleJoinRoom();
            return;
        }
        // Back button
        var backBtnX:Float = centerX + 10;
        if (mx >= backBtnX && mx <= backBtnX + 120 && my >= btnY && my <= btnY + 45) {
            screen = "main";
            return;
        }
    }

    function onKeyDown(key:KeyCode) {
        if (!assetsLoaded) return;

        if (key == KeyCode.Escape) {
            if (screen != "main") {
                screen = "main";
            }
            return;
        }

        if (screen == "main") {
            return;
        }

        // Text input handling for sub-screens
        if (key == KeyCode.Backspace) {
            if (activeField == "name" && playerName.length > 0) {
                playerName = playerName.substr(0, playerName.length - 1);
            } else if (activeField == "code" && roomCode.length > 0) {
                roomCode = roomCode.substr(0, roomCode.length - 1);
            }
            return;
        }

        if (key == KeyCode.Return) {
            if (screen == "create") {
                handleCreateRoom();
            } else if (screen == "join") {
                handleJoinRoom();
            }
            return;
        }

        if (key == KeyCode.Tab) {
            // Cycle active field
            if (screen == "join") {
                activeField = (activeField == "name") ? "code" : "name";
            }
            return;
        }

        // Map character keys to text
        var ch:String = keyCodeToChar(key);
        if (ch != null) {
            if (activeField == "name" && playerName.length < 16) {
                playerName += ch;
            } else if (activeField == "code" && roomCode.length < 4) {
                roomCode += ch.toUpperCase();
            }
        }
    }

    function getServerUrl():String {
        var url:String = "ws://localhost:4000";
        #if js
        var search:String = untyped js.Browser.window.location.search;
        if (search != null && search.indexOf("server=") >= 0) {
            var idx = search.indexOf("server=") + 7;
            var end = search.indexOf("&", idx);
            url = (end > 0) ? search.substring(idx, end) : search.substring(idx);
        }
        #end
        return url;
    }

    function handleCreateRoom() {
        var mapName:String = maps[selectedMap];
        var name:String = playerName;
        var wsUrl:String = getServerUrl();

        RoomClient.createRoom(name, mapName, function(code:String) {
            RoomClient.updateRoom(code, cast {serverUrl: wsUrl}, function(room:Dynamic) {});
            Application.setState(new GameState(mapName, wsUrl, name, code));
        });
    }

    function handleJoinRoom() {
        if (roomCode.length == 0) {
            statusMessage = "Enter a room code!";
            return;
        }
        statusMessage = "Looking up room...";
        var name:String = playerName;
        RoomClient.getRoom(roomCode, function(room:Dynamic) {
            if (room == null) {
                statusMessage = "Room not found!";
                return;
            }
            var wsUrl:String = untyped room.serverUrl;
            if (wsUrl == null) wsUrl = "ws://localhost:4000";
            var mapName:String = untyped room.map;
            if (mapName == null) mapName = "level2";
            Application.setState(new GameState(mapName, wsUrl, name));
        });
    }

    function keyCodeToChar(key:KeyCode):String {
        // Letters A-Z
        var code:Int = cast key;
        var a:Int = cast KeyCode.A;
        var z:Int = cast KeyCode.Z;
        var zero:Int = cast KeyCode.Zero;
        var nine:Int = cast KeyCode.Nine;
        if (code >= a && code <= z) {
            var shifted:Bool = Application.keys.get(KeyCode.Shift) == true;
            var base:String = String.fromCharCode(code);
            return shifted ? base.toUpperCase() : base.toLowerCase();
        }
        // Numbers 0-9
        if (code >= zero && code <= nine) {
            return String.fromCharCode(code);
        }
        // Space
        if (key == KeyCode.Space) return " ";
        return null;
    }

    // =====================
    // UPDATE
    // =====================

    override public function update() {
        if (!assetsLoaded) return;

        // Update hover state
        var screenW:Float = Application.getScreenWidth();
        var screenH:Float = Application.getScreenHeight();
        var mx:Int = Application.mouseX;
        var my:Int = Application.mouseY;

        hoverButton = -1;
        if (screen == "main") {
            var btnW:Float = 300;
            var btnH:Float = 50;
            var startY:Float = screenH * 0.4;
            var spacing:Float = 70;
            var btnX:Float = (screenW - btnW) / 2;

            for (i in 0...buttons.length) {
                var btnY:Float = startY + i * spacing;
                if (mx >= btnX && mx <= btnX + btnW && my >= btnY && my <= btnY + btnH) {
                    hoverButton = i;
                    break;
                }
            }
        }
    }

    // =====================
    // RENDER
    // =====================

    override public function render(frame:Framebuffer) {
        var g = frame.g2;
        g.begin(true, Color.Black);

        if (!assetsLoaded) {
            g.end();
            return;
        }

        var screenW:Float = Application.getScreenWidth();
        var screenH:Float = Application.getScreenHeight();

        if (screen == "main") {
            renderMainScreen(g, screenW, screenH);
        } else if (screen == "create") {
            renderCreateScreen(g, screenW, screenH);
        } else if (screen == "join") {
            renderJoinScreen(g, screenW, screenH);
        }

        g.end();
    }

    function renderMainScreen(g:kha.graphics2.Graphics, w:Float, h:Float) {
        // Title
        g.font = titleFont;
        g.fontSize = 48;
        g.color = Color.White;
        var title:String = "K H A S H O O T E R";
        var titleW:Float = titleFont.width(48, title);
        g.drawString(title, (w - titleW) / 2, h * 0.15);

        // Subtitle
        g.fontSize = 16;
        g.color = Color.fromFloats(0.5, 0.5, 0.5, 1.0);
        var subtitle:String = "a top-down shooter";
        var subtitleW:Float = titleFont.width(16, subtitle);
        g.drawString(subtitle, (w - subtitleW) / 2, h * 0.15 + 60);

        // Buttons
        var btnW:Float = 300;
        var btnH:Float = 50;
        var startY:Float = h * 0.4;
        var spacing:Float = 70;
        var btnX:Float = (w - btnW) / 2;

        g.font = font;
        g.fontSize = 22;

        for (i in 0...buttons.length) {
            var btnY:Float = startY + i * spacing;
            var isHover:Bool = (hoverButton == i);

            // Button background
            if (isHover) {
                g.color = Color.fromFloats(0.3, 0.3, 0.4, 1.0);
            } else {
                g.color = Color.fromFloats(0.15, 0.15, 0.2, 1.0);
            }
            g.fillRect(btnX, btnY, btnW, btnH);

            // Button border
            g.color = isHover ? Color.fromFloats(0.6, 0.6, 0.8, 1.0) : Color.fromFloats(0.3, 0.3, 0.4, 1.0);
            g.drawRect(btnX, btnY, btnW, btnH, 2.0);

            // Button text
            g.color = isHover ? Color.White : Color.fromFloats(0.8, 0.8, 0.8, 1.0);
            var textW:Float = font.width(22, buttons[i]);
            g.drawString(buttons[i], btnX + (btnW - textW) / 2, btnY + (btnH - 22) / 2);
        }
    }

    function renderCreateScreen(g:kha.graphics2.Graphics, w:Float, h:Float) {
        var centerX:Float = w / 2;
        var baseY:Float = h * 0.35;

        // Header
        g.font = titleFont;
        g.fontSize = 32;
        g.color = Color.White;
        var header:String = "CREATE ROOM";
        var headerW:Float = titleFont.width(32, header);
        g.drawString(header, (w - headerW) / 2, baseY - 80);

        g.font = font;
        g.fontSize = 18;

        // Name field
        g.color = Color.fromFloats(0.7, 0.7, 0.7, 1.0);
        g.drawString("Your name:", centerX - 170, baseY + 5);
        renderTextField(g, centerX - 50, baseY, 200, 30, playerName, activeField == "name");

        // Map selector
        g.color = Color.fromFloats(0.7, 0.7, 0.7, 1.0);
        g.drawString("Map:", centerX - 170, baseY + 65);

        // Left arrow
        var mapY:Float = baseY + 60;
        g.color = Color.fromFloats(0.5, 0.5, 0.7, 1.0);
        g.fillRect(centerX - 80, mapY, 30, 30);
        g.color = Color.White;
        g.fontSize = 20;
        g.drawString("<", centerX - 72, mapY + 3);

        // Map name
        g.fontSize = 18;
        g.color = Color.White;
        var mapName:String = maps[selectedMap];
        var mapNameW:Float = font.width(18, mapName);
        g.drawString(mapName, centerX - mapNameW / 2, mapY + 5);

        // Right arrow
        g.color = Color.fromFloats(0.5, 0.5, 0.7, 1.0);
        g.fillRect(centerX + 80, mapY, 30, 30);
        g.color = Color.White;
        g.fontSize = 20;
        g.drawString(">", centerX + 88, mapY + 3);

        // Buttons
        var btnY:Float = baseY + 140;
        renderButton(g, centerX - 130, btnY, 120, 45, "Create");
        renderButton(g, centerX + 10, btnY, 120, 45, "Back");

        // Status message
        if (statusMessage.length > 0) {
            g.fontSize = 14;
            g.color = Color.fromFloats(1.0, 0.5, 0.5, 1.0);
            var msgW:Float = font.width(14, statusMessage);
            g.drawString(statusMessage, (w - msgW) / 2, btnY + 60);
        }
    }

    function renderJoinScreen(g:kha.graphics2.Graphics, w:Float, h:Float) {
        var centerX:Float = w / 2;
        var baseY:Float = h * 0.35;

        // Header
        g.font = titleFont;
        g.fontSize = 32;
        g.color = Color.White;
        var header:String = "JOIN ROOM";
        var headerW:Float = titleFont.width(32, header);
        g.drawString(header, (w - headerW) / 2, baseY - 80);

        g.font = font;
        g.fontSize = 18;

        // Name field
        g.color = Color.fromFloats(0.7, 0.7, 0.7, 1.0);
        g.drawString("Your name:", centerX - 170, baseY + 5);
        renderTextField(g, centerX - 50, baseY, 200, 30, playerName, activeField == "name");

        // Room code field
        g.color = Color.fromFloats(0.7, 0.7, 0.7, 1.0);
        g.drawString("Room code:", centerX - 170, baseY + 65);
        renderTextField(g, centerX - 50, baseY + 60, 200, 30, roomCode, activeField == "code");

        // Buttons
        var btnY:Float = baseY + 140;
        renderButton(g, centerX - 130, btnY, 120, 45, "Join");
        renderButton(g, centerX + 10, btnY, 120, 45, "Back");

        // Status message
        if (statusMessage.length > 0) {
            g.fontSize = 14;
            g.color = Color.fromFloats(1.0, 0.5, 0.5, 1.0);
            var msgW:Float = font.width(14, statusMessage);
            g.drawString(statusMessage, (w - msgW) / 2, btnY + 60);
        }
    }

    function renderTextField(g:kha.graphics2.Graphics, x:Float, y:Float, w:Float, h:Float, text:String, active:Bool) {
        // Background
        g.color = Color.fromFloats(0.1, 0.1, 0.15, 1.0);
        g.fillRect(x, y, w, h);

        // Border
        if (active) {
            g.color = Color.fromFloats(0.5, 0.5, 1.0, 1.0);
        } else {
            g.color = Color.fromFloats(0.3, 0.3, 0.4, 1.0);
        }
        g.drawRect(x, y, w, h, 2.0);

        // Text
        g.color = Color.White;
        g.fontSize = 18;
        var displayText:String = text;
        if (active) {
            // Blinking cursor
            var blink:Bool = (Application.frameClock % 60) < 30;
            displayText = text + (blink ? "|" : "");
        }
        g.drawString(displayText, x + 8, y + 5);
    }

    function renderButton(g:kha.graphics2.Graphics, x:Float, y:Float, w:Float, h:Float, label:String) {
        var mx:Int = Application.mouseX;
        var my:Int = Application.mouseY;
        var isHover:Bool = (mx >= x && mx <= x + w && my >= y && my <= y + h);

        // Background
        if (isHover) {
            g.color = Color.fromFloats(0.3, 0.3, 0.4, 1.0);
        } else {
            g.color = Color.fromFloats(0.15, 0.15, 0.2, 1.0);
        }
        g.fillRect(x, y, w, h);

        // Border
        g.color = isHover ? Color.fromFloats(0.6, 0.6, 0.8, 1.0) : Color.fromFloats(0.3, 0.3, 0.4, 1.0);
        g.drawRect(x, y, w, h, 2.0);

        // Label
        g.color = isHover ? Color.White : Color.fromFloats(0.8, 0.8, 0.8, 1.0);
        g.fontSize = 18;
        var textW:Float = font.width(18, label);
        g.drawString(label, x + (w - textW) / 2, y + (h - 18) / 2);
    }
}
