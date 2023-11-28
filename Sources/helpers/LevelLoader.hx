package helpers;

import components.Health;
import entbuilders.ItemBuilder.Items;
import game.EntFactory;
import game.GameContext;
import haxe.Json;
import haxe.io.Mime;
import js.Browser;
import js.html.URL;
import kha.Assets;
import refraction.ds2d.LightSource;
import refraction.generic.PositionCmp;
import refraction.tilemap.TilemapUtils;
import ui.HealthBar;

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
	}

	public function export() {
		var levelData:Dynamic = getLevelData(name);
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

		entityFactory.createNPC(levelData.start.x, levelData.start.y, "mimi");
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
		definePlayerBehaviours(levelData);
	}

	function definePlayerBehaviours(levelData:Dynamic) {
		gameContext.playerEntity.on("death", function(data) {
			spawnPlayer(levelData);
		});
	}

	function spawnTilemap(entFactory:EntFactory, levelData:Dynamic) {
		var tilesetName:String = levelData.tileset_name;
		var colIndex:Int = levelData.col_index;

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
		var levelPath:String = Reflect
			.field(Assets.blobs, 'map_${_name}_json')
			.toString();
		var ret:Dynamic = Json.parse(levelPath);
		return ret;
	}
}
