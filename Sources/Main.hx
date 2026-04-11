package;

import kha.Scheduler;
import kha.input.Keyboard;
import kha.input.Mouse;
import kha.System;
import game.PhysState;
import game.GameState;
import rendering.KhaVertexIndexer;
import kha.Assets;
import refraction.core.Application;
import refraction.display.ResourceFormat;
import yaml.Yaml;

class Main {

    public static function main() {
        // Application.init("Physics Test", 600, 400, 1, function() {
        //     Application.setState(new PhysState());
        // });

        var width = 1300;
        var height = 800;

        #if kha_osx
        width *= 2;
        height *= 2;
        #end

        System.start(
            {title: "Pew Pew", width: width, height: height},
            (window) -> {
                Mouse
                    .get()
                    .notify(
                        Application.mouseDown,
                        Application.mouseUp,
                        Application.mouseMove,
                        null
                    );
                Keyboard
                    .get()
                    .notify(Application.keyDown, Application.keyUp);

                Scheduler.addTimeTask(Application.update, 0, 1 / 60);
                System.notifyOnFrames(Application.render);

                Application.init("Pew Pew", 1300, 800, 2, () -> {
                    KhaVertexIndexer.init(
                        Application.getScreenWidth(),
                        Application.getScreenHeight(),
                        Application.getScreenZoom()
                    );
                    ResourceFormat.init();
                    Application.setState(new GameState());
                });
            }
        );
    }
}
