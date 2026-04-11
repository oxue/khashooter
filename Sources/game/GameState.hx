package game;

import net.NetState;
import net.NetState.RemotePlayerState;
import refraction.display.AnimatedRenderCmp;
import rendering.TextureAtlas;
import zui.Zui;
import haxe.Timer;
import refraction.tilemap.Tile;
import refraction.core.Entity;
import kha.math.Vector2i;
import refraction.utils.Interval;
import haxe.ds.Vector;
import refraction.tilemap.DijkstraField;
import kha.math.Vector2;
import game.CollisionBehaviours.defineCollisionBehaviours;
import game.debug.MapEditor;
import helpers.DebugLogger;
import helpers.LevelLoader;
import helpers.ZombieResourceLoader;
import rendering.Camera;
import rendering.KhaVertexIndexer;
import kha.Assets;
import kha.Framebuffer;
import kha.math.FastMatrix3;
import kha.graphics4.Graphics;
import kha.input.KeyCode;
import kha.input.Mouse;
import refraction.core.Application;
import refraction.display.ResourceFormat;
import refraction.generic.PositionCmp;

class GameState extends refraction.core.State {

    var isRenderingReady:Bool;

    var gameContext:GameContext;
    var entFactory:EntFactory;
    var mapEditor:MapEditor;

    var ui:Zui;
    var showMenu:Bool;

    var levelLoader:LevelLoader;

    var defaultMap:String;
    var intervals:Array<Interval>;

    public function new(map:String = "level2") {
        this.defaultMap = map;
        this.showMenu = false;
        super();
    }

    function formatResources() {
        ZombieResourceLoader.load();
    }

    function onLoadAssets() {
        // This is needed to make clicking work
        Mouse
            .get()
            .notify(mouseDown, null, null, null);

        this.ui = new Zui({
            font: Assets.fonts.fonts_monaco,
            khaWindowId: 0,
            scaleFactor: 1
        });

        var zoom:Int = Application.getScreenZoom();
        var gameCamera:Camera = new Camera(
            Std.int(Application.getScreenWidth() / zoom),
            Std.int(Application.getScreenHeight() / zoom)
        );

        // Init Game Context
        gameContext = GameContext.instance(gameCamera, ui);
        Application.defaultCamera = gameCamera;

        // Load resources
        formatResources();

        // Init Ent Factory
        entFactory = EntFactory.instance(gameContext, new ShooterComponentFactory(gameContext));

        // load map
        levelLoader = new LevelLoader(defaultMap, entFactory, gameContext);
        levelLoader.loadMap();

        // Init collision behaviours
        defineCollisionBehaviours(gameContext);

        // TODO: reset DC stuff

        mapEditor = new MapEditor(gameContext, levelLoader, ui);
        gameContext.dijkstraMap = new DijkstraField(
            gameContext.tilemap.width,
            gameContext.tilemap.height,
            gameContext.tilemap.tilesize,
            (i, j) -> {
                var tile:Tile = gameContext.tilemap.getTileAt(i, j);
                if (tile == null) {
                    return false;
                }
                tile.solid;
            }
        );

        intervals = initIntervals();

        configureDebugKeys();

        isRenderingReady = true;

        initMultiplayer();
        playMusic();
    }

    function playMusic() {
        // Audio.play(Assets.sounds.sound_song, true);
    }

    function initMultiplayer() {
        gameContext.netState = new NetState();
        gameContext.remotePlayers = new Map<Int, Entity>();

        gameContext.netState.onPlayerJoined = function(id:Int, x:Float, y:Float) {
            spawnRemotePlayer(id, x, y);
        };

        gameContext.netState.onPlayerLeft = function(id:Int) {
            removeRemotePlayer(id);
        };

        gameContext.netState.onHit = function(target:Int, source:Int, damage:Float, health:Float) {
            if (target == gameContext.netState.localId) {
                // Local player got hit
                var healthCmp = gameContext.playerEntity.getComponent(components.Health);
                if (healthCmp != null) {
                    healthCmp.value = Std.int(health);
                }
            }
        };

        gameContext.netState.onSpawn = function(id:Int, x:Float, y:Float) {
            if (id == gameContext.netState.localId) {
                var pos:PositionCmp = gameContext.playerEntity.getComponent(PositionCmp);
                pos.x = x;
                pos.y = y;
            }
        };

        // Connect to server - get URL from query param or default to localhost
        var serverUrl:String = "ws://localhost:3000";
        #if js
        var search:String = untyped js.Browser.window.location.search;
        if (search != null && search.indexOf("server=") >= 0) {
            var idx = search.indexOf("server=") + 7;
            var end = search.indexOf("&", idx);
            serverUrl = (end > 0) ? search.substring(idx, end) : search.substring(idx);
        }
        #end
        gameContext.netState.connect(serverUrl);
    }

    function spawnRemotePlayer(id:Int, x:Float, y:Float) {
        // Use autoBuild to get a fully set up Player entity
        var e:Entity = entFactory.autoBuild("Player");
        var pos:PositionCmp = e.getComponent(PositionCmp);
        pos.setPosition(x, y);

        // Disable input controls so this entity doesn't respond to local keyboard
        var keyCtrl = e.getComponent(refraction.control.KeyControl);
        if (keyCtrl != null) keyCtrl.remove = true;
        var rotCtrl = e.getComponent(refraction.control.RotationControl);
        if (rotCtrl != null) rotCtrl.remove = true;
        // Disable tile collision for remote players (server handles their position)
        var tileColl = e.getComponent(refraction.tilemap.TileCollisionCmp);
        if (tileColl != null) tileColl.remove = true;

        gameContext.remotePlayers.set(id, e);
    }

    function removeRemotePlayer(id:Int) {
        var e:Entity = gameContext.remotePlayers.get(id);
        if (e != null) {
            e.remove();
            gameContext.remotePlayers.remove(id);
        }
    }

    function initIntervals():Array<Interval> {
        var ret:Array<Interval> = [];

        ret.push(new Interval(() -> {
            var e:Entity = gameContext.beaconSystem.getOne("player");
            var p:PositionCmp = e.getComponent(PositionCmp);
            var t:Vector2i = gameContext.dijkstraMap.getTileIndexesContaining(p.x, p.y);
            gameContext.dijkstraMap.setTarget(t.y, t.x);
            gameContext.dijkstraMap.smoothen(1);
        }, 60 * 1));

        return ret;
    }

    function configureDebugKeys() {
        Application.addKeyDownListener((code) -> {
            if (KeyCode.F9 == code) {
                gameContext.reloadConfigs();
                DebugLogger.info("RESOURCE", "reloading configs");
            }
            if (KeyCode.F10 == code) {
                entFactory.reloadEntityBlobs();
                DebugLogger.info("RESOURCE", "reloading entities");
            }
            if (KeyCode.P == code) {
                mapEditor.toggle();
                gameContext.debugMenu.off();
            }
        });
    }

    override public function load() {
        super.load();
        isRenderingReady = false;

        var t:Float = Timer.stamp();
        Assets.loadEverything(this.onLoadAssets);
        DebugLogger.info(
            "PERF",
            "loading assets took " + (Timer.stamp() - t) + " seconds"
        );
    }

    public static function loadLevel(map:String) {
        EntFactory.destroyInstance();
        GameContext.destroyInstance();
        Application.resetKeyListeners();
        Application.setState(new GameState(map));
    }

    function mouseDown(button:Int, x:Int, y:Int) {
        if (!isRenderingReady) return;
        if (button == 0) {
            gameContext.interactSystem.update();
            var inventory:InventoryCmp = gameContext.playerEntity.getComponent(InventoryCmp);
            inventory.primaryAction();
        }
    }

    // =========
    // MAIN LOOP
    // =========

    override public function update() {
        if (!isRenderingReady) return;

        if (Application.keys.get(KeyCode.Equals)) {
            gameContext.lightingSystem.globalRadius += 1;
        }
        if (Application.keys.get(KeyCode.HyphenMinus)) {
            gameContext.lightingSystem.globalRadius -= 1;
        }

        if (gameContext != null) {
            gameContext.controlSystem.update();
            gameContext.spacingSystem.update();
            gameContext.dampingSystem.update();
            gameContext.velocitySystem.update();
            gameContext.collisionSystem.update();
            gameContext.environmentSystem.update();
            gameContext.lightSourceSystem.update();
            gameContext.particleSystem.update();

            gameContext.breadCrumbsSystem.update();

            gameContext.hitCheckSystem.update();
            gameContext.aiSystem.update();

            gameContext.hitTestSystem.update();
            gameContext.beaconSystem.update();

            for (interval in intervals) {
                interval.tick();
            }

            if (Application.mouseIsDown) {
                gameContext.playerEntity
                    .getComponent(InventoryCmp)
                    .persistentAction();
            }

            // Multiplayer sync
            updateNetworking();
        }
    }

    function updateNetworking() {
        var netState = gameContext.netState;
        if (netState == null || !netState.isConnected()) return;

        // Write local player state to SyncVars
        var pos:PositionCmp = gameContext.playerEntity.getComponent(PositionCmp);
        netState.localPosX.set(pos.x);
        netState.localPosY.set(pos.y);
        netState.localRotation.set(pos.rotationDegrees);

        // Update net state (sends updates, interpolates remote players)
        netState.update(1.0 / 60.0);

        // Apply remote player positions from interpolated SyncVars
        for (id => rp in netState.remotePlayers) {
            var entity:Entity = gameContext.remotePlayers.get(id);
            if (entity == null) {
                // Remote player joined but entity doesn't exist yet
                spawnRemotePlayer(id, rp.posX.value, rp.posY.value);
                entity = gameContext.remotePlayers.get(id);
            }
            if (entity != null) {
                var remotePos:PositionCmp = entity.getComponent(PositionCmp);
                if (remotePos != null) {
                    remotePos.x = rp.posX.lerpValue;
                    remotePos.y = rp.posY.lerpValue;
                    remotePos.rotationDegrees = rp.rotation.lerpValue;
                }
            }
        }
    }

    function updateCamera() {
        gameContext.camera.updateShake();
        var playerPos:PositionCmp = cast gameContext.playerEntity.getComponent(PositionCmp);

        gameContext.camera.follow(
            playerPos.x,
            playerPos.y,
            gameContext.config.camera_damping_speed
        );

        gameContext.worldMouseX = cast Application.mouseX / 2 + gameContext.camera.x;
        gameContext.worldMouseY = cast Application.mouseY / 2 + gameContext.camera.y;
    }

    override public function render(frame:Framebuffer) {
        if (!isRenderingReady) {
            return;
        }

        this.updateCamera();

        var g4:Graphics = frame.g4;

        // g4.begin();
        // KhaBlit.setContext(frame.g4);
        // KhaBlit.clear(0, 0, 0, 0, 0, 0);
        // g4.end();

        g4.begin();
        KhaVertexIndexer.setContext(frame.g4);
        KhaVertexIndexer.setPipeline(KhaVertexIndexer.Tex2PipelineState, "KHBTex2PipelineState");
        KhaVertexIndexer.setUniformMatrix4("mproj", KhaVertexIndexer.matrix2);
        KhaVertexIndexer.setUniformTexture("tex", ResourceFormat.atlases
            .get("all")
            .image
        );

        if (gameContext.tilemap != null) {
            gameContext.tilemap.render(gameContext.camera);
        }

        gameContext.renderSystem.update();

        KhaVertexIndexer.draw();

        g4.end();

        frame.g2.begin(false);
        var a:AnimatedRenderCmp = gameContext.playerEntity.getComponent(AnimatedRenderCmp);
        a.draw(gameContext.camera, frame);
        frame.g2.end();

        gameContext.lightingSystem.renderSceneWithLighting(gameContext, [gameContext.tilemapShadowPolys]);

        g4.begin();
        KhaVertexIndexer.setContext(frame.g4);
        KhaVertexIndexer.setPipeline(KhaVertexIndexer.Tex2PipelineState, "KHBTex2PipelineState");
        KhaVertexIndexer.setUniformMatrix4("mproj", KhaVertexIndexer.matrix2);
        KhaVertexIndexer.setUniformTexture("tex", ResourceFormat.atlases
            .get("all")
            .image
        );

        gameContext.selfLitRenderSystem.update();

        KhaVertexIndexer.draw();

        g4.end();

        // UI
        if (Application.mouse2JustDown) {
            mapEditor.off();
            gameContext.debugMenu.toggleMenu();
        }

        // ========== UI BEGIN ==========
        renderUI(frame, gameContext, ui);

        if (gameContext.reloadGraphics) {
            gameContext.reloadGraphics = false;
            isRenderingReady = false;
            reloadAssets();
        }
    }

    function reloadAssets() {
        Assets.loadEverything(() -> {
            ZombieResourceLoader.load();
            isRenderingReady = true;
        }, desc -> {
            final dateNow:Float = Date
                .now()
                .getTime();
            final reloadTime:String = Std.string(dateNow);
            var s:String = desc.files[0];
            s.split("?");
            if ("../../Assets" != s.substr(0, 12)) {
                desc.files[0] = "../../Assets/" + desc.files[0];
            }
            desc.files[0] = desc.files[0].split('?')[0] + "?t=" + reloadTime;
            true;
        });
    }

    function renderUI(f:Framebuffer, context:GameContext, ui:Zui) {
        renderGameUI(f, context, ui);
        renderDebugUI(f, context, ui);
    }

    function renderMiscDebug(f:Framebuffer, context:GameContext) {
        f.g2.begin(false);
        f.g2.pushTranslation(-context.camera.x, -context.camera.y);
        f.g2.pushTransformation(FastMatrix3.scale(Application.getScreenZoom(), Application.getScreenZoom()));
        for (d in context.debugDrawablesMisc) {
            d.drawDebug(context.camera, f.g2);
        }
        f.g2.popTransformation();
        f.g2.popTransformation();
        f.g2.end();
    }

    function renderDebugUI(f:Framebuffer, context:GameContext, ui:Zui) {
        if (context.shouldDrawHitBoxes) {
            renderHitBoxes(f, context);
            renderMiscDebug(f, context);
            renderDijkstraMap(f, context);
        }

        renderZuiElements(f, context, ui);
    }

    function renderZuiElements(f:Framebuffer, gc:GameContext, ui:Zui) {
        ui.begin(f.g2);
        mapEditor.render(gc, f, ui);
        gameContext.debugMenu.render(gc, ui);
        // gameContext.console.draw();
        ui.end();
    }

    function drawVecArrow(v:Vector2, x:Float, y:Float, gc:GameContext, f:Framebuffer) {
        f.g2.pushTranslation(-gc.camera.x, -gc.camera.y);
        f.g2.pushTransformation(FastMatrix3.scale(Application.getScreenZoom(), Application.getScreenZoom()));
        f.g2.color = 0xffebf2eb;
        f.g2.drawLine(x, y, x + v.x * 4, y + v.y * 4, 0.5);
        f.g2.color = 0xff00ff00;
        f.g2.drawLine(
            x + v.x * 4,
            y + v.y * 4,
            x + v.x * 2 - v.y * 1,
            y + v.y * 2 + v.x * 1,
            0.5
        );
        f.g2.drawLine(
            x + v.x * 4,
            y + v.y * 4,
            x + v.x * 2 + v.y * 1,
            y + v.y * 2 - v.x * 1,
            0.5
        );
        f.g2.popTransformation();
        f.g2.popTransformation();
    }

    function renderDijkstraMap(f:Framebuffer, gc:GameContext) {
        f.g2.begin(false);
        var dijkstraMap:Vector<Vector<Vector2>> = gc.dijkstraMap.data;
        for (i in 0...dijkstraMap.length) {
            for (j in 0...dijkstraMap[i].length) {
                var v:Vector2 = dijkstraMap[i][j];
                if (v != null) {
                    f.g2.color = 0xff00FF00;
                    final halfTilsize:Float = gc.tilemap.tilesize / 2;
                    drawVecArrow(
                        v,
                        j * gc.tilemap.tilesize + halfTilsize,
                        i * gc.tilemap.tilesize + halfTilsize,
                        gc,
                        f
                    );
                }
            }
        }
        f.g2.end();
    }

    function renderGameUI(f:Framebuffer, gc:GameContext, ui:Zui) {
        f.g2.begin(false);
        gameContext.healthBar.render(f);
        gameContext.dialogueManager.render(f);
        gameContext.statusText.render(f.g2);
        gameContext.tooltipSystem.draw(f.g2);
        f.g2.end();
    }

    function renderHitBoxes(f:Framebuffer, gc:GameContext) {
        if (!gc.shouldDrawHitBoxes) {
            return;
        }
        for (tc in gc.collisionSystem.components) {
            tc.drawHitbox(gc.camera, f.g2);
        }
        for (p in gc.hitCheckSystem.components) {
            p.entity
                .getComponent(PositionCmp)
                .drawPoint(gc.camera, f.g2);
        }
        gc.lightingSystem.debugDraw(gc.camera, f.g2, [gameContext.tilemapShadowPolys]);
    }
}
