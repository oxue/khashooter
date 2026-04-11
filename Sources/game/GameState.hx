package game;

import net.NetManager;
import net.NetState;
import net.NetDamageable;
import net.NetIdentity;
import net.NetTransformReceiver;
import refraction.display.AnimatedRenderCmp;
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

    public static var testMode:Bool = false;

    var isRenderingReady:Bool;

    var gameContext:GameContext;
    var entFactory:EntFactory;
    var mapEditor:MapEditor;

    var ui:Zui;
    var showMenu:Bool;

    var levelLoader:LevelLoader;

    var defaultMap:String;
    var serverUrl:String;
    var multiplayerName:String;
    var roomCode:String;
    var intervals:Array<Interval>;

    public function new(map:String = "level2", ?serverUrl:String, ?playerName:String, ?roomCode:String) {
        this.defaultMap = map;
        this.serverUrl = serverUrl;
        this.multiplayerName = playerName;
        this.roomCode = roomCode;
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

        // Detect test mode from query param
        #if js
        var search:String = untyped js.Browser.window.location.search;
        if (search != null && search.indexOf("testmode=true") >= 0) {
            testMode = true;
        }
        if (testMode) untyped __js__("console.log('[GAME:TESTMODE] active')");
        #end

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

        if (!testMode) {
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
        } else {
            intervals = [];
        }

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
        gameContext.netManager = NetManager.instance();
        gameContext.remotePlayers = new Map<Int, Entity>();

        gameContext.netState.onPlayerJoined = function(id:Int, x:Float, y:Float) {
            spawnRemotePlayer(id, x, y);
        };

        gameContext.netState.onPlayerLeft = function(id:Int) {
            removeRemotePlayer(id);
        };

        gameContext.netState.onKill = function(killed:Int, killer:Int) {
            // Scoreboard and kill feed (game-wide UI, not entity-specific)
            var killerName:String = "Player " + Std.string(killer);
            var victimName:String = "Player " + Std.string(killed);
            gameContext.killFeed.addKill(killerName, victimName);
            gameContext.scoreboard.addKill(killer, killed);
        };

        gameContext.netState.onSpawn = function(id:Int, x:Float, y:Float) {
            // Re-create remote player entity if it was killed (entity.remove marks components)
            if (id != gameContext.netState.localId) {
                // Always re-create remote players on spawn — they were removed on kill
                gameContext.remotePlayers.remove(id);
                spawnRemotePlayer(id, x, y);
            }
        };

        gameContext.netState.onChat = function(fromId:Int, name:String, text:String) {
            gameContext.chatSystem.addMessage(name, text);
        };

        gameContext.netState.onReady = function(id:Int) {
            // Add net components to local player once we know our localId
            if (gameContext.playerEntity != null) {
                gameContext.playerEntity.addComponent(new NetIdentity("player_" + id, id, true));
                gameContext.netSys.procure(gameContext.playerEntity, net.NetTransformSender);
                gameContext.netSys.procure(gameContext.playerEntity, NetDamageable);
                gameContext.netSys.procure(gameContext.playerEntity, net.NetShootSender);
            }

            // Send chosen name to server
            if (multiplayerName != null && multiplayerName.length > 0) {
                gameContext.netState.client.send({type: "set_name", name: multiplayerName});
            }
        };

        // Connect to server - use passed URL, query param, or default to localhost
        var connectUrl:String = this.serverUrl;
        if (connectUrl == null) {
            connectUrl = "ws://localhost:3000";
            #if js
            var search:String = untyped js.Browser.window.location.search;
            if (search != null && search.indexOf("server=") >= 0) {
                var idx = search.indexOf("server=") + 7;
                var end = search.indexOf("&", idx);
                connectUrl = (end > 0) ? search.substring(idx, end) : search.substring(idx);
            }
            #end
        }
        gameContext.netState.connect(connectUrl);
    }

    function spawnRemotePlayer(id:Int, x:Float, y:Float) {
        // Build from RemotePlayer template — no input/physics, just render + net
        var e:Entity = entFactory.autoBuild("RemotePlayer");
        var pos:PositionCmp = e.getComponent(PositionCmp);
        if (pos != null) pos.setPosition(x, y);

        // Add networking components
        e.addComponent(new NetIdentity("player_" + id, id, false));
        var receiver:NetTransformReceiver = gameContext.netSys.procure(e, NetTransformReceiver);
        receiver.posX.applyRemote(x, 0);
        receiver.posY.applyRemote(y, 0);
        gameContext.netSys.procure(e, NetDamageable);
        gameContext.netSys.procure(e, net.NetShootReceiver);

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
            if (e == null) return;
            var p:PositionCmp = e.getComponent(PositionCmp);
            if (p == null) return;
            var t:Vector2i = gameContext.dijkstraMap.getTileIndexesContaining(p.x, p.y);
            gameContext.dijkstraMap.setTarget(t.y, t.x);
            gameContext.dijkstraMap.smoothen(1);
        }, 60 * 1));

        return ret;
    }

    function configureDebugKeys() {
        Application.addKeyDownListener((code) -> {
            // When chat input is active, route all keys to chat system
            if (gameContext.chatSystem.isInputActive) {
                gameContext.chatSystem.handleKeyDown(code);
                return;
            }

            // T opens chat
            if (KeyCode.T == code) {
                gameContext.chatSystem.handleKeyDown(code);
                return;
            }

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
            if (KeyCode.Tab == code) {
                gameContext.scoreboard.toggleVisible();
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

    public static function loadLevel(map:String, ?serverUrl:String, ?playerName:String) {
        EntFactory.destroyInstance();
        GameContext.destroyInstance();
        NetManager.destroy();
        Application.resetKeyListeners();
        Application.setState(new GameState(map, serverUrl, playerName));
    }

    function mouseDown(button:Int, x:Int, y:Int) {
        if (!isRenderingReady) return;
        if (button == 0) {
            gameContext.interactSystem.update();
            if (gameContext.playerEntity == null) return;
            var inventory:InventoryCmp = gameContext.playerEntity.getComponent(InventoryCmp);
            if (inventory != null) inventory.primaryAction();
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
            var isHost = gameContext.netState == null || !gameContext.netState.isConnected() || gameContext.netState.isHost();

            // Local player systems (always run)
            if (!gameContext.chatSystem.isInputActive) {
                gameContext.controlSystem.update();
            }
            gameContext.spacingSystem.update();
            gameContext.dampingSystem.update();
            gameContext.velocitySystem.update();
            gameContext.collisionSystem.update();

            // Visual systems (always run on all clients)
            gameContext.environmentSystem.update();
            gameContext.lightSourceSystem.update();
            gameContext.particleSystem.update();
            gameContext.hitCheckSystem.update(); // Projectile wall collision — must run on all clients

            // Host-authoritative systems (only host runs AI, pathfinding, hit detection)
            if (isHost) {
                gameContext.hitCheckSystem.hostUpdate(); // gameplay (damage) on host only
                gameContext.breadCrumbsSystem.update();
                gameContext.aiSystem.update();
                gameContext.hitTestSystem.update();
            }

            gameContext.beaconSystem.update();
            gameContext.netSys.update();

            for (interval in intervals) {
                if (isHost) interval.tick();
            }

            if (Application.mouseIsDown && gameContext.playerEntity != null) {
                var inv:InventoryCmp = gameContext.playerEntity.getComponent(InventoryCmp);
                if (inv != null) inv.persistentAction();
            }

            // Multiplayer sync
            updateNetworking();
        }
    }

    function updateNetworking() {
        var netState = gameContext.netState;
        if (netState == null || !netState.isConnected()) return;

        // Position sending is handled by NetTransformSender component

        // Update net state (sends updates, interpolates remote players)
        netState.update(1.0 / 60.0);

        // Ensure remote player entities exist for all known remote players
        for (id => rp in netState.remotePlayers) {
            var entity:Entity = gameContext.remotePlayers.get(id);
            if (entity == null) {
                spawnRemotePlayer(id, rp.posX.value, rp.posY.value);
            }
        }

        // Host sends NPC positions to other clients
        if (netState.isHost()) {
            sendNpcPositions();
        } else {
            // Non-host applies NPC positions from network
            applyNpcPositions();
        }
    }

    function sendNpcPositions() {
        var npcs:Array<Dynamic> = [];
        var idx:Int = 0;
        for (comp in gameContext.aiSystem.components) {
            if (comp.entity != null) {
                var npcPos:PositionCmp = comp.entity.getComponent(PositionCmp);
                if (npcPos != null) {
                    npcs.push({
                        id: idx,
                        x: npcPos.x,
                        y: npcPos.y,
                        rot: npcPos.rotationDegrees
                    });
                }
            }
            idx++;
        }
        if (npcs.length > 0) {
            gameContext.netState.sendNpcStates(npcs);
        }
    }

    function applyNpcPositions() {
        var npcStates = gameContext.netState.npcStates;
        if (npcStates == null) return;
        var idx:Int = 0;
        for (comp in gameContext.aiSystem.components) {
            var state = npcStates.get(Std.string(idx));
            if (state != null && comp.entity != null) {
                var npcPos:PositionCmp = comp.entity.getComponent(PositionCmp);
                if (npcPos != null) {
                    npcPos.x = state.posX.lerpValue;
                    npcPos.y = state.posY.lerpValue;
                    npcPos.rotationDegrees = state.rotation.lerpValue;
                }
            }
            idx++;
        }
    }

    function updateCamera() {
        gameContext.camera.updateShake();
        if (gameContext.playerEntity == null) return;
        var playerPos:PositionCmp = cast gameContext.playerEntity.getComponent(PositionCmp);
        if (playerPos == null) return;

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
        if (gameContext.playerEntity != null) {
            var a:AnimatedRenderCmp = gameContext.playerEntity.getComponent(AnimatedRenderCmp);
            if (a != null) a.draw(gameContext.camera, frame);
        }
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

        // Player name labels (after entities, before UI)
        renderPlayerLabels(frame, gameContext);

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

    function renderPlayerLabels(f:Framebuffer, gc:GameContext) {
        var zoom:Int = Application.getScreenZoom();
        var camX:Float = gc.camera.x;
        var camY:Float = gc.camera.y;
        var font = Assets.fonts.fonts_OpenSans;
        var fontSize:Int = 13;

        f.g2.begin(false);
        f.g2.font = font;
        f.g2.fontSize = fontSize;

        // Draw local player label
        if (gc.playerEntity != null) {
            var pos:PositionCmp = gc.playerEntity.getComponent(PositionCmp);
            if (pos != null) {
                var label:String = (multiplayerName != null && multiplayerName.length > 0) ? multiplayerName : "You";
                var screenX:Float = (pos.x - camX) * zoom;
                var screenY:Float = (pos.y - camY - 20) * zoom;
                var textWidth:Float = font.width(fontSize, label);
                f.g2.color = 0xffffffff;
                f.g2.drawString(label, screenX - textWidth / 2, screenY);
            }
        }

        // Draw remote player labels
        if (gc.netState != null && gc.remotePlayers != null) {
            for (id => entity in gc.remotePlayers) {
                if (entity != null) {
                    var rpos:PositionCmp = entity.getComponent(PositionCmp);
                    if (rpos != null) {
                        var rlabel:String = "Player " + Std.string(id);
                        var rscreenX:Float = (rpos.x - camX) * zoom;
                        var rscreenY:Float = (rpos.y - camY - 20) * zoom;
                        var rtextWidth:Float = font.width(fontSize, rlabel);
                        f.g2.color = 0xffaaaaff;
                        f.g2.drawString(rlabel, rscreenX - rtextWidth / 2, rscreenY);
                    }
                }
            }
        }

        f.g2.end();
    }

    function renderConnectionStatus(f:Framebuffer, gc:GameContext) {
        var font = Assets.fonts.fonts_OpenSans;
        var fontSize:Int = 13;
        var x:Float = 10;
        var y:Float = 10;
        var lineHeight:Float = 18;

        f.g2.font = font;
        f.g2.fontSize = fontSize;

        if (gc.netState != null && gc.netState.isConnected()) {
            // Connection status line
            f.g2.color = 0xff44ff44;
            var statusLine:String = "Connected: Player " + Std.string(gc.netState.localId);
            f.g2.drawString(statusLine, x, y);

            // Player count
            var playerCount:Int = 1; // local player
            if (gc.netState.remotePlayers != null) {
                for (_ in gc.netState.remotePlayers) {
                    playerCount++;
                }
            }
            y += lineHeight;
            f.g2.color = 0xffcccccc;
            f.g2.drawString("Players online: " + Std.string(playerCount), x, y);

            // Host badge
            if (gc.netState.isHost()) {
                y += lineHeight;
                f.g2.color = 0xffffcc00;
                f.g2.drawString("[HOST]", x, y);
            }
        } else {
            f.g2.color = 0xffff4444;
            f.g2.drawString("Offline", x, y);
        }
    }

    function renderRoomCode(f:Framebuffer) {
        if (roomCode == null || roomCode.length == 0) return;
        var font = Assets.fonts.fonts_OpenSans;
        var screenW:Float = Application.getScreenWidth();
        // Top center
        f.g2.font = font;
        f.g2.fontSize = 24;
        var label:String = "Room: " + roomCode;
        var labelW:Float = font.width(24, label);
        // Background
        f.g2.color = 0x88000000;
        f.g2.fillRect((screenW - labelW) / 2 - 10, 5, labelW + 20, 30);
        // Text
        f.g2.color = 0xff55ccff;
        f.g2.drawString(label, (screenW - labelW) / 2, 7);
    }

    function renderGameUI(f:Framebuffer, gc:GameContext, ui:Zui) {
        f.g2.begin(false);
        gameContext.healthBar.render(f);
        gameContext.dialogueManager.render(f);
        gameContext.statusText.render(f.g2);
        gameContext.tooltipSystem.draw(f.g2);
        gameContext.killFeed.render(f.g2, f.width);
        renderConnectionStatus(f, gc);
        renderRoomCode(f);
        var localId:Int = (gc.netState != null && gc.netState.isConnected()) ? gc.netState.localId : 0;
        gc.scoreboard.render(f.g2, localId, gc.netState != null ? gc.netState.remotePlayers : null);
        gc.chatSystem.render(f.g2);
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
            if (p.entity != null) {
                var ppos:PositionCmp = p.entity.getComponent(PositionCmp);
                if (ppos != null) ppos.drawPoint(gc.camera, f.g2);
            }
        }
        gc.lightingSystem.debugDraw(gc.camera, f.g2, [gameContext.tilemapShadowPolys]);
    }
}
