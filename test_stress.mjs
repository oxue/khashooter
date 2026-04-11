import { chromium } from 'playwright';
import { spawn } from 'child_process';

const SERVER_PORT = 3000;
const GAME_PORT = 8081;
const GAME_URL = `http://localhost:${GAME_PORT}?server=ws://localhost:${SERVER_PORT}`;

console.log('=== STRESS TEST: Connect/Disconnect/Rejoin ===\n');

const serverProc = spawn('node', ['server/index.js'], {
  env: { ...process.env, PORT: String(SERVER_PORT) },
  stdio: ['ignore', 'pipe', 'pipe'],
});
serverProc.stdout.on('data', d => console.log(`[SERVER] ${d.toString().trim()}`));
serverProc.stderr.on('data', d => console.error(`[SERVER ERR] ${d.toString().trim()}`));

await new Promise(r => setTimeout(r, 1500));

const browser = await chromium.launch({ headless: true });
const errors = [];

function setupPage(page, label) {
  page.on('console', msg => {
    const text = msg.text();
    if (text.includes('[NET:')) console.log(`  [${label}] ${text}`);
  });
  page.on('pageerror', err => {
    if (err.message.includes('haxe_ValueException') && !err.stack) return;
    errors.push({ label, msg: err.message, stack: err.stack?.split('\n').slice(0, 3).join('\n') });
    console.log(`  [${label} ERROR] ${err.message}`);
  });
}

function waitForLog(page, label, pattern, timeoutMs = 20000) {
  return new Promise((resolve, reject) => {
    const logs = [];
    const handler = msg => { logs.push(msg.text()); };
    page.on('console', handler);
    const start = Date.now();
    const check = () => {
      if (logs.some(l => l.includes(pattern))) { page.off('console', handler); return resolve(true); }
      if (Date.now() - start > timeoutMs) { page.off('console', handler); return reject(new Error(`Timeout: ${pattern} in ${label}`)); }
      setTimeout(check, 200);
    };
    check();
  });
}

try {
  // Test 1: Connect two players, disconnect one, check other survives
  console.log('--- Test 1: Disconnect one player ---');
  const p1 = await browser.newPage();
  setupPage(p1, 'P1');
  await p1.goto(GAME_URL);
  await waitForLog(p1, 'P1', '[NET:JOIN]');
  console.log('P1 connected');

  const p2 = await browser.newPage();
  setupPage(p2, 'P2');
  await p2.goto(GAME_URL);
  await waitForLog(p2, 'P2', '[NET:JOIN]');
  console.log('P2 connected');

  await new Promise(r => setTimeout(r, 1000));

  // Close P2
  console.log('Closing P2...');
  await p2.close();
  await new Promise(r => setTimeout(r, 2000));

  // P1 should still work without errors
  const p1ErrorsAfterDisconnect = errors.filter(e => e.label === 'P1').length;
  console.log(`P1 errors after P2 disconnect: ${p1ErrorsAfterDisconnect}`);

  // Test 2: P1 still alive, new P3 joins
  console.log('\n--- Test 2: New player joins after disconnect ---');
  const p3 = await browser.newPage();
  setupPage(p3, 'P3');
  await p3.goto(GAME_URL);
  await waitForLog(p3, 'P3', '[NET:JOIN]');
  console.log('P3 connected');

  await new Promise(r => setTimeout(r, 2000));

  const p1ErrorsAfterRejoin = errors.filter(e => e.label === 'P1').length;
  const p3Errors = errors.filter(e => e.label === 'P3').length;
  console.log(`P1 errors after P3 join: ${p1ErrorsAfterRejoin}`);
  console.log(`P3 errors: ${p3Errors}`);

  await p1.close();
  await p3.close();

  // Summary
  console.log('\n=== SUMMARY ===');
  console.log(`Total errors: ${errors.length}`);
  if (errors.length > 0) {
    for (const e of errors) {
      console.log(`  [${e.label}] ${e.msg}`);
      if (e.stack) console.log(`    ${e.stack}`);
    }
  }
  console.log(`Overall: ${errors.length === 0 ? 'PASS' : 'FAIL'}`);
  process.exitCode = errors.length === 0 ? 0 : 1;

} catch (e) {
  console.error('Test exception:', e.message);
  process.exitCode = 1;
} finally {
  await browser.close();
  serverProc.kill();
}
