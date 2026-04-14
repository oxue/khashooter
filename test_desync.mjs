/**
 * Desync detection test — simulates real gameplay and detects position divergence.
 *
 * Runs two players for 45 seconds:
 * - Both move randomly (WASD)
 * - Both shoot at each other periodically
 * - Every second, reads BOTH views of BOTH positions
 * - Detects desync: when what A thinks A's position is diverges from what B thinks A's position is
 *
 * Usage: node test_desync.mjs
 */
import { chromium } from 'playwright';
import { spawn, execSync } from 'child_process';

const SERVER_PORT = 4000;
const GAME_PORT = 8081;
const DURATION_MS = 45000;
const SAMPLE_INTERVAL_MS = 1000;
const DESYNC_THRESHOLD_PX = 80; // positions this far apart = desync

// Start server
try { execSync(`lsof -ti:${SERVER_PORT} | xargs kill -9 2>/dev/null`); } catch {}
const srv = spawn('node', ['server/index.js'], {
  env: { ...process.env, PORT: String(SERVER_PORT) },
  stdio: ['ignore', 'pipe', 'pipe'],
});
srv.stdout.on('data', () => {});
await new Promise(r => setTimeout(r, 1500));

const browser = await chromium.launch({ headless: true });
const URL = `http://localhost:${GAME_PORT}?testmode=true&autostart=true&server=ws://localhost:${SERVER_PORT}`;

// Read full position state from a tab
async function readPositions(page) {
  return await page.evaluate(() => {
    const gc = window.__gameApp?.currentState?.gameContext;
    if (!gc) return { error: 'no gc' };

    const result = { localId: gc.netState?.localId ?? -1 };

    // Local player position
    if (gc.playerEntity?.components?.h) {
      for (const [k, c] of Object.entries(gc.playerEntity.components.h)) {
        if (k.includes('PositionCmp')) {
          result.localX = Math.round(c.x);
          result.localY = Math.round(c.y);
        }
        if (k.includes('Health')) {
          result.localHealth = c.value;
        }
      }
    }

    // Remote player positions
    result.remotes = {};
    if (gc.remotePlayers?.h) {
      for (const [id, entity] of Object.entries(gc.remotePlayers.h)) {
        if (entity?.components?.h) {
          const rp = {};
          for (const [k, c] of Object.entries(entity.components.h)) {
            if (k.includes('PositionCmp')) {
              rp.x = Math.round(c.x);
              rp.y = Math.round(c.y);
            }
          }
          result.remotes[id] = rp;
        }
      }
    }

    // Net state info
    result.connected = gc.netState?.isConnected?.() ?? false;
    result.remoteCount = Object.keys(result.remotes).length;

    return result;
  });
}

// Simulate random input on a page
async function randomInput(page, key, durationMs) {
  await page.keyboard.down(key);
  await new Promise(r => setTimeout(r, durationMs));
  await page.keyboard.up(key);
}

async function shoot(page) {
  await page.evaluate(() => {
    const c = document.getElementById('khanvas');
    if (c) {
      c.dispatchEvent(new MouseEvent('mousedown', { button: 0, which: 1, clientX: 650, clientY: 400, bubbles: true }));
      setTimeout(() => c.dispatchEvent(new MouseEvent('mouseup', { button: 0, which: 1, bubbles: true })), 50);
    }
  });
}

console.log('=== DESYNC DETECTION TEST ===\n');
console.log(`Duration: ${DURATION_MS / 1000}s, Sample interval: ${SAMPLE_INTERVAL_MS}ms, Threshold: ${DESYNC_THRESHOLD_PX}px\n`);

// Boot both tabs
async function bootTab(label) {
  const page = await browser.newPage();
  const errors = [];
  const logs = [];
  page.on('console', m => logs.push(m.text()));
  page.on('pageerror', e => { if (!e.message.includes('ValueException')) errors.push(e.message); });
  console.log(`Booting Tab ${label}...`);
  await page.goto(URL);
  // Wait for game to be ready (NET:JOIN or PERF with time)
  await new Promise((res, rej) => {
    const s = Date.now();
    const c = () => {
      if (logs.some(l => l.includes('[NET:JOIN]') || (l.includes('[PERF]') && l.includes('time')))) return res();
      if (Date.now() - s > 20000) return rej(new Error(`${label} boot timeout`));
      setTimeout(c, 200);
    };
    c();
  });
  await new Promise(r => setTimeout(r, 1500));
  console.log(`Tab ${label} booted.`);
  return { page, errors };
}

const tabA = await bootTab('A');
const pageA = tabA.page;
const errorsA = tabA.errors;

const tabB = await bootTab('B');
const pageB = tabB.page;
const errorsB = tabB.errors;
await new Promise(r => setTimeout(r, 1000));
console.log('');

// Gameplay loop
const samples = [];
const desyncs = [];
const keys = ['w', 'a', 's', 'd'];
const startTime = Date.now();
let sampleCount = 0;
let shootCount = 0;

console.log('Starting gameplay simulation...\n');

while (Date.now() - startTime < DURATION_MS) {
  // Random movement for both players
  const keyA = keys[Math.floor(Math.random() * 4)];
  const keyB = keys[Math.floor(Math.random() * 4)];
  const moveDuration = 200 + Math.floor(Math.random() * 300);

  // Move both simultaneously
  const movePromises = [
    randomInput(pageA, keyA, moveDuration),
    randomInput(pageB, keyB, moveDuration),
  ];

  // Shoot periodically (every ~3 seconds)
  if (Math.random() < 0.15) {
    movePromises.push(shoot(pageA));
    shootCount++;
  }
  if (Math.random() < 0.15) {
    movePromises.push(shoot(pageB));
    shootCount++;
  }

  await Promise.all(movePromises);

  // Sample positions
  sampleCount++;
  const stateA = await readPositions(pageA);
  const stateB = await readPositions(pageB);

  if (stateA.error || stateB.error) {
    console.log(`  [${sampleCount}] ERROR: A=${stateA.error || 'ok'} B=${stateB.error || 'ok'}`);
    continue;
  }

  const sample = {
    t: Math.round((Date.now() - startTime) / 1000),
    a: { id: stateA.localId, x: stateA.localX, y: stateA.localY, hp: stateA.localHealth, remotes: stateA.remoteCount },
    b: { id: stateB.localId, x: stateB.localX, y: stateB.localY, hp: stateB.localHealth, remotes: stateB.remoteCount },
  };

  // Compare: what A thinks A's pos is vs what B thinks A's pos is
  const aIdStr = String(stateA.localId);
  const bIdStr = String(stateB.localId);
  const bViewOfA = stateB.remotes[aIdStr];
  const aViewOfB = stateA.remotes[bIdStr];

  if (bViewOfA) {
    const dxA = Math.abs(stateA.localX - bViewOfA.x);
    const dyA = Math.abs(stateA.localY - bViewOfA.y);
    sample.desyncA = Math.round(Math.sqrt(dxA * dxA + dyA * dyA));
  } else {
    sample.desyncA = -1; // B doesn't see A
  }

  if (aViewOfB) {
    const dxB = Math.abs(stateB.localX - aViewOfB.x);
    const dyB = Math.abs(stateB.localY - aViewOfB.y);
    sample.desyncB = Math.round(Math.sqrt(dxB * dxB + dyB * dyB));
  } else {
    sample.desyncB = -1; // A doesn't see B
  }

  samples.push(sample);

  // Report desyncs
  const isDesynced = sample.desyncA > DESYNC_THRESHOLD_PX || sample.desyncB > DESYNC_THRESHOLD_PX ||
                     sample.desyncA === -1 || sample.desyncB === -1;
  if (isDesynced) {
    desyncs.push(sample);
    console.log(`  [t=${sample.t}s] *** DESYNC *** A_drift=${sample.desyncA}px B_drift=${sample.desyncB}px`);
    console.log(`    A(${stateA.localId}) local=(${stateA.localX},${stateA.localY}) hp=${stateA.localHealth} sees ${stateA.remoteCount} remotes`);
    console.log(`    B(${stateB.localId}) local=(${stateB.localX},${stateB.localY}) hp=${stateB.localHealth} sees ${stateB.remoteCount} remotes`);
    if (bViewOfA) console.log(`    B sees A at (${bViewOfA.x},${bViewOfA.y})`);
    else console.log(`    B does NOT see A!`);
    if (aViewOfB) console.log(`    A sees B at (${aViewOfB.x},${aViewOfB.y})`);
    else console.log(`    A does NOT see B!`);
  } else if (sampleCount % 5 === 0) {
    // Periodic status every 5 samples
    console.log(`  [t=${sample.t}s] OK drift: A=${sample.desyncA}px B=${sample.desyncB}px | A=(${stateA.localX},${stateA.localY}) B=(${stateB.localX},${stateB.localY}) | shots=${shootCount}`);
  }

  // Page errors check
  if (errorsA.length > 0 || errorsB.length > 0) {
    console.log(`  [t=${sample.t}s] PAGE ERRORS: A=${errorsA.length} B=${errorsB.length}`);
    if (errorsA.length > 0) console.log(`    A: ${errorsA[errorsA.length - 1]}`);
    if (errorsB.length > 0) console.log(`    B: ${errorsB[errorsB.length - 1]}`);
    break; // Stop on page errors
  }
}

// Summary
console.log('\n=== RESULTS ===\n');
console.log(`Duration: ${Math.round((Date.now() - startTime) / 1000)}s`);
console.log(`Samples: ${samples.length}`);
console.log(`Shots fired: ${shootCount}`);
console.log(`Desyncs detected: ${desyncs.length}`);
console.log(`Page errors: A=${errorsA.length} B=${errorsB.length}`);

if (desyncs.length > 0) {
  console.log('\nDesync timeline:');
  for (const d of desyncs) {
    console.log(`  t=${d.t}s: A_drift=${d.desyncA}px B_drift=${d.desyncB}px`);
  }
}

// Compute average drift
const validSamples = samples.filter(s => s.desyncA >= 0 && s.desyncB >= 0);
if (validSamples.length > 0) {
  const avgDriftA = Math.round(validSamples.reduce((s, x) => s + x.desyncA, 0) / validSamples.length);
  const avgDriftB = Math.round(validSamples.reduce((s, x) => s + x.desyncB, 0) / validSamples.length);
  const maxDriftA = Math.max(...validSamples.map(s => s.desyncA));
  const maxDriftB = Math.max(...validSamples.map(s => s.desyncB));
  console.log(`\nPosition drift stats:`);
  console.log(`  A: avg=${avgDriftA}px max=${maxDriftA}px`);
  console.log(`  B: avg=${avgDriftB}px max=${maxDriftB}px`);
}

const passed = desyncs.length === 0 && errorsA.length === 0 && errorsB.length === 0;
console.log(`\nOverall: ${passed ? 'PASS' : 'FAIL'}`);

await browser.close();
srv.kill();
process.exitCode = passed ? 0 : 1;
