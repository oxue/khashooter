package game;

import kha.Assets;
import kha.Color;
import kha.graphics2.Graphics;
import kha.input.KeyCode;
import haxe.Timer;

class ChatSystem {

    var messages:Array<ChatMessage>;
    public var isInputActive:Bool;
    public var inputBuffer:String;

    static inline var MAX_MESSAGES:Int = 20;
    static inline var MESSAGE_LIFETIME:Float = 30.0;
    static inline var FONT_SIZE:Int = 14;
    static inline var LINE_HEIGHT:Float = 18.0;

    public function new() {
        messages = [];
        isInputActive = false;
        inputBuffer = "";
    }

    public function addMessage(name:String, text:String) {
        messages.push({
            name: name,
            text: text,
            timestamp: Timer.stamp()
        });
        if (messages.length > MAX_MESSAGES) {
            messages.shift();
        }
    }

    public function handleKeyDown(code:KeyCode) {
        if (!isInputActive) {
            if (code == KeyCode.T) {
                isInputActive = true;
                inputBuffer = "";
            }
            return;
        }

        // Chat input is active
        if (code == KeyCode.Return) {
            // Send message
            if (inputBuffer.length > 0) {
                var gc = GameContext.instance();
                if (gc.netState != null && gc.netState.isConnected()) {
                    gc.netState.sendChat(inputBuffer);
                } else {
                    // Offline: show locally
                    addMessage("You", inputBuffer);
                }
            }
            inputBuffer = "";
            isInputActive = false;
            return;
        }

        if (code == KeyCode.Escape) {
            inputBuffer = "";
            isInputActive = false;
            return;
        }

        if (code == KeyCode.Backspace) {
            if (inputBuffer.length > 0) {
                inputBuffer = inputBuffer.substr(0, inputBuffer.length - 1);
            }
            return;
        }

        // Map key codes to characters
        var ch:String = keyCodeToChar(code);
        if (ch != null) {
            inputBuffer += ch;
        }
    }

    function keyCodeToChar(code:KeyCode):String {
        var c:Int = cast code;
        var a:Int = cast KeyCode.A;
        var z:Int = cast KeyCode.Z;
        var zero:Int = cast KeyCode.Zero;
        var nine:Int = cast KeyCode.Nine;

        // Letters A-Z
        if (c >= a && c <= z) {
            return String.fromCharCode(97 + (c - a)); // lowercase
        }
        // Numbers 0-9
        if (c >= zero && c <= nine) {
            return String.fromCharCode(48 + (c - zero));
        }
        if (code == KeyCode.Space) return " ";
        if (code == KeyCode.Period) return ".";
        if (code == KeyCode.Comma) return ",";
        if (code == KeyCode.Slash) return "/";
        if (code == KeyCode.HyphenMinus) return "-";
        if (code == KeyCode.Semicolon) return ";";
        if (code == KeyCode.Equals) return "=";
        return null;
    }

    public function render(g2:Graphics) {
        var now:Float = Timer.stamp();

        // Remove expired messages
        while (messages.length > 0 && now - messages[0].timestamp > MESSAGE_LIFETIME) {
            messages.shift();
        }

        var font = Assets.fonts.fonts_OpenSans;
        g2.font = font;
        g2.fontSize = FONT_SIZE;

        var x:Float = 10.0;
        var baseY:Float = 750.0; // near bottom of 800px screen
        var inputHeight:Float = isInputActive ? LINE_HEIGHT + 4 : 0;
        var startY:Float = baseY - inputHeight - messages.length * LINE_HEIGHT;

        // Draw messages
        for (i in 0...messages.length) {
            var msg = messages[i];
            var age:Float = now - msg.timestamp;
            var alpha:Float = 1.0;
            // Fade out in last 5 seconds unless input is active (show all when chatting)
            if (!isInputActive && age > MESSAGE_LIFETIME - 5.0) {
                alpha = 1.0 - (age - (MESSAGE_LIFETIME - 5.0)) / 5.0;
            }
            if (alpha <= 0) continue;

            var line:String = msg.name + ": " + msg.text;
            var textWidth:Float = font.width(FONT_SIZE, line);
            var y:Float = startY + i * LINE_HEIGHT;

            // Background
            g2.color = Color.fromFloats(0, 0, 0, 0.5 * alpha);
            g2.fillRect(x - 2, y - 1, textWidth + 6, LINE_HEIGHT);

            // Text
            g2.color = Color.fromFloats(1, 1, 1, alpha);
            g2.drawString(line, x, y);
        }

        // Draw input prompt
        if (isInputActive) {
            var promptText:String = "Say: " + inputBuffer;
            var promptWidth:Float = font.width(FONT_SIZE, promptText + "_");
            var promptY:Float = baseY - 2;

            // Background
            g2.color = Color.fromFloats(0, 0, 0, 0.7);
            g2.fillRect(x - 2, promptY - 1, promptWidth + 6, LINE_HEIGHT + 2);

            // Text with blinking cursor
            g2.color = Color.White;
            var cursorBlink:Bool = Std.int(now * 2) % 2 == 0;
            var displayText:String = cursorBlink ? promptText + "_" : promptText;
            g2.drawString(displayText, x, promptY);
        }

        g2.color = Color.White;
    }
}

typedef ChatMessage = {
    name:String,
    text:String,
    timestamp:Float
};
