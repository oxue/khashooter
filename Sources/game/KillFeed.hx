package game;

import kha.Assets;
import kha.Color;
import kha.graphics2.Graphics;
import haxe.Timer;

class KillFeed {

    var messages:Array<KillMessage>;

    public function new() {
        messages = [];
    }

    public function addKill(killerName:String, victimName:String) {
        messages.push({
            text: killerName + " killed " + victimName,
            timestamp: Timer.stamp()
        });
    }

    public function render(g2:Graphics, screenWidth:Int) {
        // Remove expired messages (older than 5 seconds)
        var now:Float = Timer.stamp();
        while (messages.length > 0 && now - messages[0].timestamp > 5.0) {
            messages.shift();
        }

        if (messages.length == 0) return;

        g2.font = Assets.fonts.fonts_OpenSans;
        g2.fontSize = 18;

        var yOffset:Float = 10.0;
        for (msg in messages) {
            var age:Float = now - msg.timestamp;
            var alpha:Float = 1.0;
            if (age > 3.5) {
                alpha = 1.0 - (age - 3.5) / 1.5;
            }
            if (alpha <= 0) continue;

            var textWidth:Float = g2.font.width(g2.fontSize, msg.text);
            var x:Float = screenWidth - textWidth - 16;
            var y:Float = yOffset;

            // Draw background
            g2.color = Color.fromFloats(0, 0, 0, 0.5 * alpha);
            g2.fillRect(x - 4, y - 2, textWidth + 8, 22);

            // Draw text
            g2.color = Color.fromFloats(1, 0.3, 0.3, alpha);
            g2.drawString(msg.text, x, y);

            yOffset += 24;
        }

        g2.color = Color.White;
    }
}

typedef KillMessage = {
    text:String,
    timestamp:Float
};
