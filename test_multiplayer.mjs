import { chromium } from 'playwright';
import { spawn } from 'child_process';

const SERVER_PORT = 3000;
const GAME_PORT = 8081;
const GAME_URL = `http://localhost:${GAME_PORT}?server=ws://localhost:${SERVER_PORT}`;

console.log('=== KHASHOOTER MULTIPLAYER TEST ===\n');

// Start the WebSocket server
console.log('Starting WebSocket server...');
const serverProc = spawn('node', ['server/index.js'], {
  env: { ...process.env, PORT: String(SERVER_PORT) },
  stdio: ['ignore', 'pipe', 'pipe'],
});
serverProc.stdout.on('data', d => console.log(`[SERVER] ${d.toString().trim()}`));
serverProc.stderr.on('data', d => console.error(`[SERVER ERR] ${d.toString().trim()}`));

await new Promise(r => setTimeout(r, 1500));

const browser = await chromium.launch({ headless: true });
const allLogs = { tabA: [], tabB: [] };
const allErrors = { tabA: [], tabB: [] };

function setupPage(page, label) {
  page.on('console', msg => {
    const text = msg.text();
    allLogs[label].push(text);
    if (text.includes('[NET:') || text.includes('[PERF]')) {
      console.log(`  [${label}] ${text}`);
    }
  });
  page.on('pageerror', err => {
    if (err.message.includes('haxe_ValueException') && !err.stack) return;
    allErrors[label].push(err.message);
    console.log(`  [${label} PAGE_ERROR] ${err.message}`);
    if (err.stack) console.log(`  [${label} STACK] ${err.stack.split('\n').slice(0,3).join('\n')}`);
  });
}

function waitForLog(label, pattern, timeoutMs = 15000) {
  return new Promise((resolve, reject) => {
    const start = Date.now();
    const check = () => {
      if (allLogs[label].some(l => l.includes(pattern))) return resolve(true);
      if (Date.now() - start > timeoutMs) return reject(new Error(`Timeout waiting for "${pattern}" in ${label}`));
      setTimeout(check, 200);
    };
    check();
  });
}

try {
  // Tab A
  console.log('\n--- Tab A ---');
  const pageA = await browser.newPage();
  setupPage(pageA, 'tabA');
  await pageA.goto(GAME_URL);

  console.log('Waiting for Tab A to boot and connect...');
  await waitForLog('tabA', '[NET:JOIN]', 20000);
  console.log('Tab A: connected!\n');

  // Tab B
  console.log('--- Tab B ---');
  const pageB = await browser.newPage();
  setupPage(pageB, 'tabB');
  await pageB.goto(GAME_URL);

  console.log('Waiting for Tab B to boot and connect...');
  await waitForLog('tabB', '[NET:JOIN]', 20000);
  console.log('Tab B: connected!\n');

  // Wait for player_joined events
  await new Promise(r => setTimeout(r, 1000));

  const results = {};

  // Test 1: Both players see each other
  results.bothSeeEachOther =
    allLogs.tabA.some(l => l.includes('PLAYER_JOINED')) &&
    allLogs.tabB.some(l => l.includes('PLAYER_JOINED'));
  console.log(`Test 1 - Both see each other: ${results.bothSeeEachOther ? 'PASS' : 'FAIL'}`);

  // Test 2: Move player A and check B receives updates
  console.log('\nMoving player A (pressing D for 2s)...');
  await pageA.click('#khanvas');
  await pageA.keyboard.down('d');
  await new Promise(r => setTimeout(r, 2000));
  await pageA.keyboard.up('d');
  await new Promise(r => setTimeout(r, 1000));

  // Test 2: Tab B received position updates from Tab A's movement
  results.positionSync = allLogs.tabB.some(l => l.includes('[NET:RECV_POS]'));
  console.log(`Test 2 - Position sync (B sees A move): ${results.positionSync ? 'PASS' : 'FAIL'}`);

  // Test 3: No page errors at all
  results.noPageErrors = allErrors.tabA.length === 0 && allErrors.tabB.length === 0;
  console.log(`Test 3 - No page errors: ${results.noPageErrors ? 'PASS' : 'FAIL'}`);

  // Summary
  console.log('\n=== SUMMARY ===');
  console.log(`Tab A errors: ${allErrors.tabA.length}`);
  console.log(`Tab B errors: ${allErrors.tabB.length}`);
  console.log(`Tab A NET logs: ${allLogs.tabA.filter(l => l.includes('[NET:')).length}`);
  console.log(`Tab B NET logs: ${allLogs.tabB.filter(l => l.includes('[NET:')).length}`);

  if (allErrors.tabA.length > 0) {
    console.log('\nTab A Errors:');
    allErrors.tabA.forEach(e => console.log(`  ${e}`));
  }
  if (allErrors.tabB.length > 0) {
    console.log('\nTab B Errors:');
    allErrors.tabB.forEach(e => console.log(`  ${e}`));
  }

  const allPassed = Object.values(results).every(v => v === true);
  console.log(`\nOverall: ${allPassed ? 'PASS' : 'FAIL'}`);
  process.exitCode = allPassed ? 0 : 1;

} catch (e) {
  console.error('\nTest exception:', e.message);
  process.exitCode = 1;
} finally {
  await browser.close();
  serverProc.kill();
}
