package helpers;

import components.Health;
import entbuilders.ItemBuilder.Items;
import game.EntFactory;
import game.GameContext;
import haxe.Json;
import kha.Assets;
import refraction.ds2d.LightSource;
import refraction.generic.PositionCmp;
import refraction.tile.TilemapUtils;
import ui.HealthBar;

class LevelLoader {
	var entityFactory:EntFactory;
	var gameContext:GameContext;

	public function new(_ef:EntFactory, _gc:GameContext) {
		entityFactory = _ef;
		gameContext = _gc;
	}

	public function loadMap(_name:String) {
		var levelData:Dynamic = getLevelData(_name);
		spawnTilemap(entityFactory, levelData);
		spawnPlayer(levelData);
		spawnLights(levelData);

		// hardcode
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
		for (p in TilemapUtils.computeGeometry(gameContext.tilemapData)) {
			gameContext.lightingSystem.polygons.push(p);
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
		if (tilesetName == null) {
			tilesetName = "all_tiles";
		}
		entFactory.createTilemap(
			levelData.data[0].length,
			levelData.data.length,
			levelData.tilesize,
			1,
			levelData.data,
			tilesetName
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
