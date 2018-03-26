package helpers;

import haxe.Json;
import kha.Assets;
import refraction.generic.Position;
import ui.HealthBar;
import components.Health;
import refraction.ds2d.LightSource;
import refraction.tile.TilemapUtils;

class LevelLoader {
	private var levelData:Dynamic;
	
	private var ef:EntFactory;
	private var gc:GameContext;

	public function new(_ef:EntFactory, _gc:GameContext) {
		ef = _ef;
		gc = _gc;
	 }
	
	public function loadMap(_name:String) {
		getLevelData(_name);
		createLevelTilemap();
		spawnPlayer();
		spawnLights();
		
		// hardcode
		ef.createItem(levelData.start.x, levelData.start.y);
		ef.createNPC(levelData.start.x, levelData.start.y, "mimi");
		//ef.createZombie(levelData.start.x, levelData.start.y);
	}

	private function spawnLights() {
		if(levelData.lights == null) {
			return;
		}
		var i:Int = levelData.lights.length;
		while (i-->0){
			gc.lightingSystem.addLightSource(new LightSource(levelData.lights[i].x, levelData.lights[i].y, levelData.lights[i].color, levelData.lights[i].radius));
		}
		for (p in TilemapUtils.computeGeometry(gc.tilemapData)){
			gc.lightingSystem.polygons.push(p);
		}
	}

	public function spawnPlayer() {
		gc.playerEntity = ef.autoBuild("Player")
			.getComponent(Position).setPosition(levelData.start.x, levelData.start.y)
			.getEntity();
		gc.healthBar = new HealthBar(gc.playerEntity.getComponent(Health));
		definePlayerBehaviours();
	}

	private function definePlayerBehaviours() {
		gc.playerEntity.on("death", function(data){
			spawnPlayer();
		});
	}

	private function createLevelTilemap() {
		ef.createTilemap(
			levelData.data[0].length,
			levelData.data.length,
			levelData.tilesize,
			1,
			levelData.data,
			"all_tiles"
		);
	}

	private function getLevelData(_name:String) {
		var levelPath = Reflect.field(Assets.blobs, 'map_${_name}_json').toString();
		levelData = Json.parse(levelPath);
	}
}