package helpers;

import components.Health;
import entbuilders.ItemBuilder.Items;
import game.EntFactory;
import game.GameContext;
import game.InventoryCmp;
import haxe.Json;
import haxe.io.Mime;

import kha.Assets;
import refraction.ds2d.LightSource;
import refraction.generic.PositionCmp;
import refraction.tilemap.TilemapUtils;
import ui.HealthBar;

#if kha_html5
import js.Browser;
import js.html.URL;
#end

class LevelLoader {
    var entityFactory:EntFactory;
    var gameContext:GameContext;
    var name:String;

    public function new(name:String, _ef:EntFactory, _gc:GameContext) {
        this.name = name;
        entityFactory = _ef;
        gameContext = _gc;
    }

    public static function saveFile(name:String, mime:Mime, data:String) {
        #if kha_html5
        final blob = new js.html.Blob([data], {
            type: mime
        });
        final url = URL.createObjectURL(blob);
        final a = Browser.document.createElement("a");
        untyped a.download = name;
        untyped a.href = url;
        a.onclick = function(e) {
            e.cancelBubble = true;
            e.stopPropagation();
        }
        Browser.document.body.appendChild(a);
        a.click();
        Browser.document.body.removeChild(a);
        URL.revokeObjectURL(url);
        #end
    }

    public function export() {
        var levelData:Dynamic = getLevelData(name);
        if (levelData == null) return;
        levelData.data = gameContext.tilemap.getTileArray();
        var filename:String = '${name}.json';
        saveFile(
            filename,
            "application/json",
            Json.stringify(levelData)
        );
    }

    public function loadMap() {
        var levelData:Dynamic = getLevelData(name);
        if (levelData == null) {
            trace("LevelLoader: failed to load level data for: " + name);
            return;
        }
        spawnTilemap(entityFactory, levelData);
        spawnPlayer(levelData);
        gameContext.tilemapShadowPolys = TilemapUtils.computeGeometry(gameContext.tilemap);
        spawnLights(levelData);

        // TODO: remove hardcode
        entityFactory.createItem(
            levelData.start.x,
            levelData.start.y,
            Items.HuntersCrossbow
        );

        entityFactory.createItem(
            levelData.start.x + 30,
            levelData.start.y,
            Items.Flamethrower
        );

        entityFactory.createItem(
            levelData.start.x + 60,
            levelData.start.y,
            Items.MachineGun
        );

        if (!game.GameState.testMode) {
            entityFactory.createNPC(levelData.start.x, levelData.start.y, "mimi");
        }
    }

    function spawnLights(levelData:Dynamic) {
        if (levelData.lights == null) {
            return;
        }
        var i:Int = levelData.lights.length;
        while (i-- > 0) {
            gameContext.lightingSystem.addLightSource(
                new LightSource(
                    levelData.lights[i].x,
                    levelData.lights[i].y,
                    levelData.lights[i].color,
                    levelData.lights[i].radius
                )
            );
        }
        
    }

    public function spawnPlayer(levelData:Dynamic) {
        gameContext.playerEntity = entityFactory
            .autoBuild("Player")
            .getComponent(PositionCmp)
            .setPosition(levelData.start.x, levelData.start.y)
            .getEntity();
        gameContext.healthBar = new HealthBar(
            gameContext.playerEntity.getComponent(Health)
        );

        // Spawn with crossbow equipped (CS2D style)
        var inventory:InventoryCmp = gameContext.playerEntity.getComponent(InventoryCmp);
        if (inventory != null) {
            inventory.pickup(Items.HuntersCrossbow);
        }

        definePlayerBehaviours(levelData);
    }

    function definePlayerBehaviours(levelData:Dynamic) {
        gameContext.playerEntity.on("death", function(data) {
            spawnPlayer(levelData);
        });
    }

    function spawnTilemap(entFactory:EntFactory, levelData:Dynamic) {
        if (levelData.data == null || levelData.data.length == 0) {
            trace("LevelLoader: level data has no tile data");
            return;
        }
        var tilesetName:String = levelData.tileset_name;
        var colIndex:Null<Int> = levelData.col_index;

        if (tilesetName == null) {
            tilesetName = "all_tiles";
        }
        if (colIndex == null) {
            colIndex = 1;
        }
        entFactory.createTilemap(
            levelData.data[0].length,
            levelData.data.length,
            levelData.tilesize,
            colIndex,
            levelData.data,
            tilesetName,
            levelData.original_tilesheet_name
        );
    }

    function getLevelData(_name:String):Dynamic {
        var blob:Dynamic = Reflect.field(Assets.blobs, 'map_${_name}_json');
        if (blob == null) {
            trace("LevelLoader: map asset not found: " + _name);
            return null;
        }
        var levelPath:String = blob.toString();
        var ret:Dynamic = Json.parse(levelPath);
        return ret;
    }
}
