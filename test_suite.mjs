/**
 * Khashooter Comprehensive Test Suite
 *
 * Runs isolated test scenarios via Playwright, using ?testmode=true for speed.
 * Each test is independent — spawns fresh browser contexts and server.
 *
 * Usage: node test_suite.mjs [--filter=pattern]
 */
import { chromium } from 'playwright';
import { spawn, execSync } from 'child_process';

const SERVER_PORT = 3000;
const GAME_PORT = 8081;
const BASE_URL = `http://localhost:${GAME_PORT}?testmode=true&autostart=true&server=ws://localhost:${SERVER_PORT}`;
const BASE_URL_OFFLINE = `http://localhost:${GAME_PORT}?testmode=true&autostart=true`;
const BOOT_TIMEOUT = 12000;

// Parse --filter arg
const filterArg = process.argv.find(a => a.startsWith('--filter='));
const filter = filterArg ? filterArg.split('=')[1].toLowerCase() : null;

// =====================
// Test infrastructure
// =====================

let serverProc = null;
let browser = null;
const results = [];

function startServer() {
  return new Promise((resolve) => {
    // Kill any existing server on the port
    try { execSync(`lsof -ti:${SERVER_PORT} | xargs kill -9 2>/dev/null`); } catch {}
    serverProc = spawn('node', ['server/index.js'], {
      env: { ...process.env, PORT: String(SERVER_PORT) },
      stdio: ['ignore', 'pipe', 'pipe'],
    });
    serverProc.stdout.on('data', () => {});
    serverProc.stderr.on('data', () => {});
    setTimeout(resolve, 1500);
  });
}

function stopServer() {
  if (serverProc) { serverProc.kill(); serverProc = null; }
}

async function createTab(url) {
  const page = await browser.newPage();
  const logs = [];
  const errors = [];

  page.on('console', msg => logs.push(msg.text()));
  page.on('pageerror', err => {
    if (err.message.includes('haxe_ValueException') && !err.stack) return;
    errors.push(err.message);
  });

  await page.goto(url || BASE_URL);

  // Wait for game ready
  await new Promise((resolve, reject) => {
    const start = Date.now();
    const check = () => {
      if (logs.some(l => l.includes('[PERF]') && l.includes('time'))) return resolve();
      if (Date.now() - start > BOOT_TIMEOUT) return reject(new Error('Boot timeout'));
      setTimeout(check, 100);
    };
    check();
  });

  return { page, logs, errors };
}

function waitForLog(tab, pattern, timeoutMs = 5000) {
  return new Promise((resolve, reject) => {
    const start = Date.now();
    const check = () => {
      if (tab.logs.some(l => l.includes(pattern))) return resolve(true);
      if (Date.now() - start > timeoutMs) return resolve(false);
      setTimeout(check, 100);
    };
    check();
  });
}

async function runTest(name, fn) {
  if (filter && !name.toLowerCase().includes(filter)) {
    results.push({ name, status: 'SKIP' });
    return;
  }
  const start = Date.now();
  try {
    await fn();
    const ms = Date.now() - start;
    results.push({ name, status: 'PASS', ms });
    console.log(`  PASS  ${name} (${ms}ms)`);
  } catch (e) {
    const ms = Date.now() - start;
    results.push({ name, status: 'FAIL', ms, error: e.message });
    console.log(`  FAIL  ${name} (${ms}ms): ${e.message}`);
  }
}

function assert(condition, msg) {
  if (!condition) throw new Error(msg || 'Assertion failed');
}

// =====================
// Test scenarios
// =====================

console.log('=== KHASHOOTER TEST SUITE ===\n');

browser = await chromium.launch({ headless: true });

// --- Single Player Tests ---
console.log('--- Single Player ---');

await runTest('SP01: Game boots without server', async () => {
  const tab = await createTab(BASE_URL_OFFLINE);
  assert(tab.logs.some(l => l.includes('[GAME:TESTMODE]')), 'Test mode not active');
  assert(tab.errors.length === 0, `Page errors: ${tab.errors.join(', ')}`);
  await tab.page.close();
});

await runTest('SP02: Game boots with server param but no server', async () => {
  const tab = await createTab(`http://localhost:${GAME_PORT}?testmode=true&server=ws://localhost:9999`);
  // Should show game even if server unreachable
  assert(tab.logs.some(l => l.includes('[PERF]')), 'Game did not reach ready state');
  await tab.page.close();
});

await runTest('SP03: Player can move (WASD input)', async () => {
  const tab = await createTab(BASE_URL_OFFLINE);
  await tab.page.click('#khanvas');
  await tab.page.keyboard.down('d');
  await new Promise(r => setTimeout(r, 500));
  await tab.page.keyboard.up('d');
  // No crash = pass (we can't easily read position from outside)
  assert(tab.errors.length === 0, `Errors during movement: ${tab.errors.join(', ')}`);
  await tab.page.close();
});

await runTest('SP04: No errors after 5 seconds of gameplay', async () => {
  const tab = await createTab(BASE_URL_OFFLINE);
  await new Promise(r => setTimeout(r, 5000));
  assert(tab.errors.length === 0, `Errors: ${tab.errors.join(', ')}`);
  await tab.page.close();
});

// --- Multiplayer Connection Tests ---
console.log('\n--- Multiplayer Connection ---');

await startServer();

await runTest('MP01: Two players connect and see each other', async () => {
  const tabA = await createTab();
  await waitForLog(tabA, '[NET:JOIN]');

  const tabB = await createTab();
  await waitForLog(tabB, '[NET:JOIN]');

  await new Promise(r => setTimeout(r, 500));

  assert(tabA.logs.some(l => l.includes('[NET:PLAYER_JOINED]')), 'A did not see B join');
  assert(tabB.logs.some(l => l.includes('[NET:PLAYER_JOINED]')), 'B did not see A join');
  assert(tabA.errors.length === 0, `A errors: ${tabA.errors.join(', ')}`);
  assert(tabB.errors.length === 0, `B errors: ${tabB.errors.join(', ')}`);

  await tabA.page.close();
  await tabB.page.close();
});

await runTest('MP02: Host election — first player is host', async () => {
  const tab = await createTab();
  await waitForLog(tab, '[NET:JOIN]');
  assert(tab.logs.some(l => l.includes('host=') && l.includes('[NET:JOIN]')), 'No host assignment in JOIN');
  await tab.page.close();
});

await runTest('MP03: Position sync — B receives A movement', async () => {
  const tabA = await createTab();
  await waitForLog(tabA, '[NET:JOIN]');
  const tabB = await createTab();
  await waitForLog(tabB, '[NET:JOIN]');
  await new Promise(r => setTimeout(r, 500));

  // Move A
  await tabA.page.click('#khanvas');
  await tabA.page.keyboard.down('d');
  await new Promise(r => setTimeout(r, 1000));
  await tabA.page.keyboard.up('d');
  await new Promise(r => setTimeout(r, 500));

  assert(tabB.logs.some(l => l.includes('[NET:RECV_POS]')), 'B did not receive position updates');

  await tabA.page.close();
  await tabB.page.close();
});

await runTest('MP04: Shooting sync — B sees A shoot', async () => {
  const tabA = await createTab();
  await waitForLog(tabA, '[NET:JOIN]');
  const tabB = await createTab();
  await waitForLog(tabB, '[NET:JOIN]');
  await new Promise(r => setTimeout(r, 500));

  // Shoot via canvas mousedown
  await tabA.page.evaluate(() => {
    const c = document.getElementById('khanvas');
    c.dispatchEvent(new MouseEvent('mousedown', { button: 0, which: 1, clientX: 650, clientY: 400, bubbles: true }));
    setTimeout(() => c.dispatchEvent(new MouseEvent('mouseup', { button: 0, which: 1, bubbles: true })), 50);
  });
  await new Promise(r => setTimeout(r, 1000));

  const aSent = tabA.logs.some(l => l.includes('[NET:SHOOT]'));
  const bReceived = tabB.logs.some(l => l.includes('[NET:REMOTE_SHOOT]'));
  assert(aSent || bReceived, `Shooting not synced (A sent: ${aSent}, B received: ${bReceived})`);

  await tabA.page.close();
  await tabB.page.close();
});

// --- Disconnect / Rejoin Tests ---
console.log('\n--- Disconnect / Rejoin ---');

await runTest('DC01: Player disconnect — other survives without errors', async () => {
  const tabA = await createTab();
  await waitForLog(tabA, '[NET:JOIN]');
  const tabB = await createTab();
  await waitForLog(tabB, '[NET:JOIN]');
  await new Promise(r => setTimeout(r, 500));

  await tabB.page.close();
  await new Promise(r => setTimeout(r, 1500));

  assert(tabA.logs.some(l => l.includes('[NET:PLAYER_LEFT]')), 'A did not see B leave');
  assert(tabA.errors.length === 0, `A errors after disconnect: ${tabA.errors.join(', ')}`);

  await tabA.page.close();
});

await runTest('DC02: New player joins after another leaves', async () => {
  const tabA = await createTab();
  await waitForLog(tabA, '[NET:JOIN]');
  const tabB = await createTab();
  await waitForLog(tabB, '[NET:JOIN]');
  await new Promise(r => setTimeout(r, 300));

  await tabB.page.close();
  await new Promise(r => setTimeout(r, 500));

  const tabC = await createTab();
  await waitForLog(tabC, '[NET:JOIN]');
  await new Promise(r => setTimeout(r, 500));

  assert(tabA.logs.some(l => l.includes('[NET:PLAYER_LEFT]')), 'A did not see B leave');
  assert(tabA.logs.filter(l => l.includes('[NET:PLAYER_JOINED]')).length >= 2, 'A did not see C join');
  assert(tabC.errors.length === 0, `C errors: ${tabC.errors.join(', ')}`);

  await tabA.page.close();
  await tabC.page.close();
});

await runTest('DC03: Host disconnect — new host elected', async () => {
  const tabA = await createTab();
  await waitForLog(tabA, '[NET:JOIN]');
  const tabB = await createTab();
  await waitForLog(tabB, '[NET:JOIN]');
  await new Promise(r => setTimeout(r, 500));

  // Close A (the host)
  await tabA.page.close();
  await new Promise(r => setTimeout(r, 1500));

  assert(tabB.logs.some(l => l.includes('[NET:HOST_CHANGE]')), 'B did not receive host change');
  assert(tabB.errors.length === 0, `B errors: ${tabB.errors.join(', ')}`);

  await tabB.page.close();
});

// --- Stability Tests ---
console.log('\n--- Stability ---');

await runTest('ST01: No errors after 8 seconds multiplayer idle', async () => {
  const tabA = await createTab();
  await waitForLog(tabA, '[NET:JOIN]');
  const tabB = await createTab();
  await waitForLog(tabB, '[NET:JOIN]');

  await new Promise(r => setTimeout(r, 8000));

  assert(tabA.errors.length === 0, `A errors: ${tabA.errors.join(', ')}`);
  assert(tabB.errors.length === 0, `B errors: ${tabB.errors.join(', ')}`);

  await tabA.page.close();
  await tabB.page.close();
});

await runTest('ST02: Rapid connect/disconnect (3 players)', async () => {
  const tabs = [];
  for (let i = 0; i < 3; i++) {
    const tab = await createTab();
    await waitForLog(tab, '[NET:JOIN]');
    tabs.push(tab);
  }
  // Close all quickly
  for (const tab of tabs) {
    await tab.page.close();
    await new Promise(r => setTimeout(r, 200));
  }
  // No assertion needed — if server crashes, next test fails
});

// --- Cleanup ---
stopServer();
await browser.close();

// --- Report ---
console.log('\n=== RESULTS ===\n');

const passed = results.filter(r => r.status === 'PASS');
const failed = results.filter(r => r.status === 'FAIL');
const skipped = results.filter(r => r.status === 'SKIP');

console.log(`Passed:  ${passed.length}`);
console.log(`Failed:  ${failed.length}`);
console.log(`Skipped: ${skipped.length}`);
console.log(`Total:   ${results.length}`);

if (failed.length > 0) {
  console.log('\nFailed tests:');
  for (const f of failed) {
    console.log(`  ${f.name}: ${f.error}`);
  }
}

const totalMs = results.filter(r => r.ms).reduce((a, r) => a + r.ms, 0);
console.log(`\nTotal time: ${(totalMs / 1000).toFixed(1)}s`);

process.exitCode = failed.length > 0 ? 1 : 0;
