package game;

import kha.Assets;
import kha.Color;
import kha.graphics2.Graphics;
import refraction.core.Application;

class Scoreboard {

    var visible:Bool;
    var stats:Map<Int, PlayerStats>;

    public function new() {
        visible = false;
        stats = new Map<Int, PlayerStats>();
    }

    public function toggleVisible() {
        visible = !visible;
    }

    public function addKill(killerId:Int, killedId:Int) {
        if (!stats.exists(killerId)) {
            stats.set(killerId, {kills: 0, deaths: 0});
        }
        if (!stats.exists(killedId)) {
            stats.set(killedId, {kills: 0, deaths: 0});
        }
        stats.get(killerId).kills++;
        stats.get(killedId).deaths++;
    }

    public function render(g2:Graphics, localId:Int, remotePlayers:Map<Int, Dynamic>) {
        if (!visible) return;

        var font = Assets.fonts.fonts_OpenSans;
        var fontSize:Int = 16;
        g2.font = font;
        g2.fontSize = fontSize;

        var screenW:Float = Application.getScreenWidth();
        var screenH:Float = Application.getScreenHeight();

        // Collect all player IDs
        var playerIds:Array<Int> = [];
        playerIds.push(localId);
        if (remotePlayers != null) {
            for (id in remotePlayers.keys()) {
                playerIds.push(id);
            }
        }
        // Also include players in stats who may have disconnected
        for (id in stats.keys()) {
            var found = false;
            for (pid in playerIds) {
                if (pid == id) { found = true; break; }
            }
            if (!found) playerIds.push(id);
        }

        // Layout
        var colPlayerW:Float = 200;
        var colKillsW:Float = 80;
        var colDeathsW:Float = 80;
        var tableW:Float = colPlayerW + colKillsW + colDeathsW;
        var rowH:Float = 28;
        var headerH:Float = 40;
        var tableH:Float = headerH + rowH + rowH * playerIds.length; // title + header row + player rows
        var tableX:Float = (screenW - tableW) / 2;
        var tableY:Float = (screenH - tableH) / 2;

        // Dark semi-transparent background
        g2.color = Color.fromFloats(0, 0, 0, 0.75);
        g2.fillRect(tableX - 16, tableY - 16, tableW + 32, tableH + 32);

        // Header: "SCOREBOARD"
        g2.color = Color.fromFloats(1, 1, 1, 1);
        g2.fontSize = 20;
        var titleText:String = "SCOREBOARD";
        var titleW:Float = font.width(20, titleText);
        g2.drawString(titleText, (screenW - titleW) / 2, tableY);
        g2.fontSize = fontSize;

        // Column headers
        var headY:Float = tableY + headerH;
        g2.color = Color.fromFloats(0.7, 0.7, 0.7, 1);
        g2.drawString("Player", tableX, headY);
        g2.drawString("Kills", tableX + colPlayerW, headY);
        g2.drawString("Deaths", tableX + colPlayerW + colKillsW, headY);

        // Separator line
        headY += rowH - 4;
        g2.color = Color.fromFloats(0.5, 0.5, 0.5, 0.8);
        g2.fillRect(tableX, headY, tableW, 1);

        // Player rows
        var y:Float = headY + 6;
        for (id in playerIds) {
            var s = stats.get(id);
            var kills:Int = (s != null) ? s.kills : 0;
            var deaths:Int = (s != null) ? s.deaths : 0;
            var name:String = "Player " + Std.string(id);

            if (id == localId) {
                // Highlight local player
                g2.color = Color.fromFloats(0.2, 0.4, 0.8, 0.3);
                g2.fillRect(tableX - 4, y - 2, tableW + 8, rowH);
                g2.color = Color.fromFloats(0.4, 0.8, 1, 1);
            } else {
                g2.color = Color.fromFloats(1, 1, 1, 0.9);
            }

            g2.drawString(name, tableX, y);
            g2.drawString(Std.string(kills), tableX + colPlayerW, y);
            g2.drawString(Std.string(deaths), tableX + colPlayerW + colKillsW, y);

            y += rowH;
        }

        // Reset color
        g2.color = Color.White;
    }
}

typedef PlayerStats = {
    kills:Int,
    deaths:Int
};
