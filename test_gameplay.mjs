/**
 * Gameplay smoke tests — simulate real gameplay scenarios and assert correctness.
 * Each test injects JS into the game to read actual entity state.
 */
import { chromium } from 'playwright';
import { spawn, execSync } from 'child_process';

const SERVER_PORT = 3000;
const GAME_PORT = 8081;
const BASE = `http://localhost:${GAME_PORT}?testmode=true&autostart=true&server=ws://localhost:${SERVER_PORT}`;
const BOOT_TIMEOUT = 15000;

let serverProc, browser;
const results = [];

async function setup() {
  try { execSync(`lsof -ti:${SERVER_PORT} | xargs kill -9 2>/dev/null`); } catch {}
  serverProc = spawn('node', ['server/index.js'], {
    env: { ...process.env, PORT: String(SERVER_PORT) },
    stdio: ['ignore', 'pipe', 'pipe'],
  });
  serverProc.stdout.on('data', () => {});
  serverProc.stderr.on('data', () => {});
  await new Promise(r => setTimeout(r, 1500));
  browser = await chromium.launch({ headless: true });
}

async function teardown() {
  await browser.close();
  serverProc.kill();
}

async function bootTab(url) {
  const page = await browser.newPage();
  const logs = [];
  const errors = [];
  page.on('console', msg => logs.push(msg.text()));
  page.on('pageerror', err => {
    if (err.message.includes('haxe_ValueException') && !err.stack) return;
    errors.push(err.message);
  });
  await page.goto(url || BASE);

  // Wait for game ready (PERF log from GameState.onLoadAssets — autostart bypasses menu)
  await new Promise((resolve, reject) => {
    const start = Date.now();
    const check = () => {
      if (logs.some(l => l.includes('[PERF]') && l.includes('time'))) return resolve();
      if (Date.now() - start > BOOT_TIMEOUT) return reject(new Error('Boot timeout'));
      setTimeout(check, 100);
    };
    check();
  });

  // Wait for net connection
  await new Promise((resolve) => {
    const start = Date.now();
    const check = () => {
      if (logs.some(l => l.includes('[NET:JOIN]'))) return resolve();
      if (Date.now() - start > 5000) return resolve();
      setTimeout(check, 100);
    };
    check();
  });
  return { page, logs, errors };
}

// Read game state from inside the browser
async function readGameState(page) {
  return await page.evaluate(() => {
    try {
      const app = window.__gameApp;
      if (!app) return { error: 'no Application' };

      const gc = app.currentState?.gameContext;
      if (!gc) return { error: 'no gameContext' };
      const result = {
        hasPlayer: gc.playerEntity != null,
        playerRemoved: gc.playerEntity ? gc.playerEntity.components == null : true,
      };

      // Player position
      if (gc.playerEntity) {
        for (const [key, comp] of Object.entries(gc.playerEntity.components?.h || {})) {
          if (key.includes('PositionCmp')) {
            result.playerX = comp.x;
            result.playerY = comp.y;
          }
          if (key.includes('Health')) {
            result.playerHealth = comp.value;
            result.playerMaxHealth = comp.maxValue;
          }
        }
      }

      // Remote players (Haxe IntMap uses .h object with numeric keys)
      result.remotePlayerCount = 0;
      result.remotePlayers = {};
      if (gc.remotePlayers && gc.remotePlayers.h) {
        for (const id of Object.keys(gc.remotePlayers.h)) {
          const entity = gc.remotePlayers.h[id];
          result.remotePlayerCount++;
          const rp = { exists: entity != null };
          if (entity && entity.components && entity.components.h) {
            rp.removed = false;
            for (const [key, comp] of Object.entries(entity.components.h)) {
              if (key.includes('PositionCmp')) { rp.x = comp.x; rp.y = comp.y; }
              if (key.includes('Health')) { rp.health = comp.value; }
            }
          }
          result.remotePlayers[id] = rp;
        }
      }

      // Net state
      if (gc.netState) {
        result.connected = gc.netState.isConnected();
        result.localId = gc.netState.localId;
        result.isHost = gc.netState.isHost();
        result.remoteNetPlayers = 0;
        if (gc.netState.remotePlayers && gc.netState.remotePlayers.h) {
          result.remoteNetPlayers = Object.keys(gc.netState.remotePlayers.h).length;
        }
      }

      // Render system component count
      result.renderComponents = gc.renderSystem?.components?.length || 0;
      result.hitCheckComponents = gc.hitCheckSystem?.components?.length || 0;

      return result;
    } catch (e) {
      return { error: e.message };
    }
  });
}

async function runTest(name, fn) {
  const start = Date.now();
  try {
    await fn();
    results.push({ name, status: 'PASS', ms: Date.now() - start });
    console.log(`  PASS  ${name} (${Date.now() - start}ms)`);
  } catch (e) {
    results.push({ name, status: 'FAIL', ms: Date.now() - start, error: e.message });
    console.log(`  FAIL  ${name} (${Date.now() - start}ms): ${e.message}`);
  }
}

function assert(cond, msg) { if (!cond) throw new Error(msg); }

// ========================================
console.log('=== GAMEPLAY SMOKE TESTS ===\n');
await setup();

// ---------- Scenario 1: Basic two-player connection ----------
console.log('--- Scenario 1: Two players connect ---');

await runTest('G01: Both players have valid game state after connecting', async () => {
  const a = await bootTab();
  const b = await bootTab();
  await new Promise(r => setTimeout(r, 2000));

  const stateA = await readGameState(a.page);
  const stateB = await readGameState(b.page);

  console.log('    A:', JSON.stringify(stateA));
  console.log('    B:', JSON.stringify(stateB));

  assert(!stateA.error, `A error: ${stateA.error}`);
  assert(!stateB.error, `B error: ${stateB.error}`);
  assert(stateA.hasPlayer, 'A has no player entity');
  assert(stateB.hasPlayer, 'B has no player entity');
  assert(stateA.connected, 'A not connected');
  assert(stateB.connected, 'B not connected');
  assert(stateA.playerHealth > 0, `A health: ${stateA.playerHealth}`);
  assert(stateB.playerHealth > 0, `B health: ${stateB.playerHealth}`);
  assert(stateA.remotePlayerCount >= 1 || stateA.remoteNetPlayers >= 1, 'A sees no remote players');
  assert(stateB.remotePlayerCount >= 1 || stateB.remoteNetPlayers >= 1, 'B sees no remote players');

  await a.page.close();
  await b.page.close();
});

// ---------- Scenario 2: Movement changes position ----------
console.log('\n--- Scenario 2: Movement ---');

await runTest('G02: WASD movement changes player position', async () => {
  const a = await bootTab();
  await new Promise(r => setTimeout(r, 500));

  const before = await readGameState(a.page);
  assert(before.playerX != null, 'No player position');

  // Move right
  await a.page.keyboard.down('d');
  await new Promise(r => setTimeout(r, 1000));
  await a.page.keyboard.up('d');
  await new Promise(r => setTimeout(r, 200));

  const after = await readGameState(a.page);
  assert(after.playerX > before.playerX + 5, `Player didn't move right: ${before.playerX} -> ${after.playerX}`);

  await a.page.close();
});

// ---------- Scenario 3: Kill and respawn cycle ----------
console.log('\n--- Scenario 3: Kill/Respawn ---');

await runTest('G03: Player survives multiple kill/respawn cycles', async () => {
  const a = await bootTab();
  const b = await bootTab();
  await new Promise(r => setTimeout(r, 2000));

  for (let cycle = 0; cycle < 3; cycle++) {
    // Simulate server kill event on player B
    await b.page.evaluate((c) => {
      const gc = window.__gameApp?.currentState?.gameContext;
      if (gc && gc.netState && gc.netState.localId >= 0) {
        // Simulate receiving a kill message for local player
        const id = gc.netState.localId;
        const entity = gc.playerEntity;
        if (entity) {
          entity.notify('net:kill', { killer: 999 });
          // Then simulate spawn
          setTimeout(() => {
            entity.notify('net:spawn', { x: 30 + c * 10, y: 100 });
          }, 200);
        }
      }
    }, cycle);

    await new Promise(r => setTimeout(r, 500));

    const stateB = await readGameState(b.page);
    assert(stateB.hasPlayer, `Cycle ${cycle}: B has no player entity`);
    assert(!stateB.playerRemoved, `Cycle ${cycle}: B player entity was removed`);
    assert(stateB.playerHealth > 0, `Cycle ${cycle}: B health is ${stateB.playerHealth}`);
  }

  // Verify A still sees B
  const stateA = await readGameState(a.page);
  assert(stateA.remotePlayerCount >= 1 || stateA.remoteNetPlayers >= 1, 'A lost sight of B after respawns');
  assert(!stateA.error, `A error: ${stateA.error}`);

  await a.page.close();
  await b.page.close();
});

await runTest('G04: After kill, player entity still has components', async () => {
  const a = await bootTab();
  await new Promise(r => setTimeout(r, 1000));

  // Simulate kill on self
  await a.page.evaluate(() => {
    const gc = window.__gameApp?.currentState?.gameContext;
    if (gc && gc.playerEntity) {
      gc.playerEntity.notify('net:kill', { killer: 999 });
    }
  });
  await new Promise(r => setTimeout(r, 300));

  const state = await readGameState(a.page);
  assert(state.hasPlayer, 'Player entity gone after kill');
  assert(!state.playerRemoved, 'Player entity components removed after kill');

  // Simulate respawn
  await a.page.evaluate(() => {
    const gc = window.__gameApp?.currentState?.gameContext;
    if (gc && gc.playerEntity) {
      gc.playerEntity.notify('net:spawn', { x: 50, y: 50 });
    }
  });
  await new Promise(r => setTimeout(r, 300));

  const after = await readGameState(a.page);
  assert(after.playerHealth > 0, `Health after respawn: ${after.playerHealth}`);

  await a.page.close();
});

// ---------- Scenario 4: Remote player visibility after disconnect/reconnect ----------
console.log('\n--- Scenario 4: Disconnect handling ---');

await runTest('G05: After B disconnects, A has zero remote players', async () => {
  const a = await bootTab();
  const b = await bootTab();
  await new Promise(r => setTimeout(r, 2000));

  const before = await readGameState(a.page);
  assert(before.remotePlayerCount >= 1, 'A should see B initially');

  await b.page.close();
  await new Promise(r => setTimeout(r, 2000));

  const after = await readGameState(a.page);
  console.log('    A after disconnect:', JSON.stringify(after));
  assert(after.remotePlayerCount === 0, `A still sees ${after.remotePlayerCount} remote players`);
  assert(after.hasPlayer, 'A lost own player');
  assert(a.errors.length === 0, `A errors: ${a.errors.join(', ')}`);

  await a.page.close();
});

// ---------- Scenario 5: Render system integrity ----------
console.log('\n--- Scenario 5: Render integrity ---');

await runTest('G06: No page errors after 10 seconds of two-player gameplay', async () => {
  const a = await bootTab();
  const b = await bootTab();
  await new Promise(r => setTimeout(r, 2000));

  // Both move around
  await a.page.click('#khanvas');
  await b.page.click('#khanvas');
  await a.page.keyboard.down('d');
  await b.page.keyboard.down('a');
  await new Promise(r => setTimeout(r, 2000));
  await a.page.keyboard.up('d');
  await b.page.keyboard.up('a');

  // Shoot
  for (let i = 0; i < 3; i++) {
    await a.page.evaluate(() => {
      document.getElementById('khanvas').dispatchEvent(
        new MouseEvent('mousedown', { button: 0, which: 1, clientX: 650, clientY: 400, bubbles: true })
      );
      setTimeout(() => document.getElementById('khanvas').dispatchEvent(
        new MouseEvent('mouseup', { button: 0, which: 1, bubbles: true })
      ), 50);
    });
    await new Promise(r => setTimeout(r, 500));
  }

  await new Promise(r => setTimeout(r, 3000));

  const stateA = await readGameState(a.page);
  const stateB = await readGameState(b.page);

  assert(a.errors.length === 0, `A errors: ${a.errors.join('; ')}`);
  assert(b.errors.length === 0, `B errors: ${b.errors.join('; ')}`);
  assert(stateA.hasPlayer, 'A lost player');
  assert(stateB.hasPlayer, 'B lost player');
  assert(stateA.renderComponents > 0, `A render components: ${stateA.renderComponents}`);
  assert(stateB.renderComponents > 0, `B render components: ${stateB.renderComponents}`);

  await a.page.close();
  await b.page.close();
});

// ========================================
await teardown();

console.log('\n=== RESULTS ===\n');
const passed = results.filter(r => r.status === 'PASS').length;
const failed = results.filter(r => r.status === 'FAIL').length;
console.log(`Passed: ${passed}  Failed: ${failed}  Total: ${results.length}`);
if (failed > 0) {
  console.log('\nFailed:');
  results.filter(r => r.status === 'FAIL').forEach(r => console.log(`  ${r.name}: ${r.error}`));
}
process.exitCode = failed > 0 ? 1 : 0;
