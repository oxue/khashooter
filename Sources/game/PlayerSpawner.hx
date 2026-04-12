package game;

import components.Health;
import entbuilders.ItemBuilder.Items;
import net.NetDamageable;
import net.NetIdentity;
import net.NetShootReceiver;
import net.NetShootSender;
import net.NetTransformReceiver;
import net.NetTransformSender;
import refraction.core.Entity;
import refraction.generic.PositionCmp;
import ui.HealthBar;

class PlayerSpawner {
    var gameContext:GameContext;
    var entFactory:EntFactory;

    public function new(gameContext:GameContext, entFactory:EntFactory) {
        this.gameContext = gameContext;
        this.entFactory = entFactory;
    }

    public function spawnLocal(x:Float, y:Float):Entity {
        var e = entFactory.autoBuild("Player");
        var pos = e.getComponent(PositionCmp);
        if (pos != null) pos.setPosition(x, y);

        gameContext.playerEntity = e;
        gameContext.healthBar = new HealthBar(e.getComponent(Health));

        // Equip default weapon
        var inventory = e.getComponent(InventoryCmp);
        if (inventory != null) {
            inventory.pickup(Items.HuntersCrossbow);
        }

        // In multiplayer, disable Health default callback (server handles death)
        if (GameState.isMultiplayer()) {
            var health = e.getComponent(Health);
            if (health != null) {
                health._callback = function() {};
            }
        }

        return e;
    }

    public function spawnRemote(id:Int, x:Float, y:Float):Entity {
        var e = entFactory.autoBuild("RemotePlayer");
        var pos = e.getComponent(PositionCmp);
        if (pos != null) pos.setPosition(x, y);

        // Net components
        e.addComponent(new NetIdentity("player_" + id, id, false));
        var receiver = gameContext.netSys.procure(e, NetTransformReceiver);
        receiver.posX.applyRemote(x, 0);
        receiver.posY.applyRemote(y, 0);
        gameContext.netSys.procure(e, NetDamageable);
        gameContext.netSys.procure(e, NetShootReceiver);

        // In multiplayer, disable Health default callback (server handles death)
        var health = e.getComponent(Health);
        if (health != null) {
            health._callback = function() {};
        }

        gameContext.remotePlayers.set(id, e);
        return e;
    }

    public function addNetComponentsToLocal(id:Int) {
        var e = gameContext.playerEntity;
        if (e == null) return;
        e.addComponent(new NetIdentity("player_" + id, id, true));
        gameContext.netSys.procure(e, NetTransformSender);
        gameContext.netSys.procure(e, NetDamageable);
        gameContext.netSys.procure(e, NetShootSender);
    }

    public function despawn(entity:Entity) {
        if (entity == null) return;
        entity.remove();
    }

    public function respawnLocal(x:Float, y:Float):Entity {
        var oldEntity = gameContext.playerEntity;
        despawn(oldEntity);

        var e = spawnLocal(x, y);

        // Re-add net components if connected
        if (gameContext.netState != null && gameContext.netState.isConnected()) {
            addNetComponentsToLocal(gameContext.netState.localId);
        }

        return e;
    }

    public function respawnRemote(id:Int, x:Float, y:Float):Entity {
        var old = gameContext.remotePlayers.get(id);
        despawn(old);
        gameContext.remotePlayers.remove(id);
        return spawnRemote(id, x, y);
    }
}
