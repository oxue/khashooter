import { chromium } from 'playwright';

const GAME_PORT = 8081;

const scenarios = [
  { name: 'Default (no server)', url: `http://localhost:${GAME_PORT}` },
  { name: 'With server param', url: `http://localhost:${GAME_PORT}?server=ws://localhost:3000` },
];

console.log('=== LOAD TIME ANALYSIS ===\n');

const browser = await chromium.launch({ headless: true });

for (const scenario of scenarios) {
  console.log(`--- ${scenario.name} ---`);
  const page = await browser.newPage();

  const timestamps = {};
  const assetCounts = { yaml: 0, json: 0, font: 0, png: 0, js: 0, other: 0 };
  const assetSizes = { yaml: 0, json: 0, font: 0, png: 0, js: 0, other: 0 };

  page.on('console', msg => {
    const text = msg.text();
    const now = Date.now();
    if (text.includes('[PERF] loading assets took')) {
      timestamps.assetsStarted = now;
      const match = text.match(/took ([\d.]+)/);
      if (match) timestamps.assetLoadSyncMs = parseFloat(match[1]) * 1000;
    }
    if (text.includes('[PERF] {') && text.includes('time')) {
      timestamps.gameReady = now;
      const match = text.match(/time\s*:\s*([\d.]+)/);
      if (match) timestamps.gameReadyInternalSec = parseFloat(match[1]);
    }
    if (text.includes('[NET:CONNECT] connecting')) {
      timestamps.netConnectStart = now;
    }
    if (text.includes('[NET:JOIN]')) {
      timestamps.netJoined = now;
    }
    if (text.includes('[NET:ERROR]') || text.includes('[NET:DISCONNECT]')) {
      timestamps.netFailed = now;
    }
  });

  page.on('response', resp => {
    const url = resp.url();
    const size = parseInt(resp.headers()['content-length'] || '0');
    if (url.endsWith('.yaml')) { assetCounts.yaml++; assetSizes.yaml += size; }
    else if (url.endsWith('.json')) { assetCounts.json++; assetSizes.json += size; }
    else if (url.endsWith('.ttf')) { assetCounts.font++; assetSizes.font += size; }
    else if (url.endsWith('.png')) { assetCounts.png++; assetSizes.png += size; }
    else if (url.endsWith('.js')) { assetCounts.js++; assetSizes.js += size; }
    else { assetCounts.other++; }
  });

  timestamps.navigationStart = Date.now();
  await page.goto(scenario.url);
  timestamps.pageLoaded = Date.now();

  // Wait for game ready
  try {
    await page.waitForEvent('console', {
      predicate: msg => msg.text().includes('time') && msg.text().includes('[PERF]'),
      timeout: 20000,
    });
  } catch { }

  // Wait a bit more for net events
  await new Promise(r => setTimeout(r, 2000));

  const navToPage = timestamps.pageLoaded - timestamps.navigationStart;
  const navToReady = timestamps.gameReady ? timestamps.gameReady - timestamps.navigationStart : null;
  const navToNet = timestamps.netJoined ? timestamps.netJoined - timestamps.navigationStart : null;

  console.log(`  Page loaded:        ${navToPage}ms`);
  console.log(`  Game ready:         ${navToReady ? navToReady + 'ms' : 'N/A'}`);
  console.log(`  Internal load time: ${timestamps.gameReadyInternalSec ? timestamps.gameReadyInternalSec.toFixed(2) + 's' : 'N/A'}`);
  console.log(`  Net joined:         ${navToNet ? navToNet + 'ms' : 'N/A (no server or failed)'}`);
  console.log(`  Asset sync load:    ${timestamps.assetLoadSyncMs ? timestamps.assetLoadSyncMs.toFixed(1) + 'ms' : 'N/A'}`);
  console.log('');
  console.log('  Asset breakdown:');
  for (const [type, count] of Object.entries(assetCounts)) {
    if (count > 0) {
      console.log(`    ${type.padEnd(6)}: ${String(count).padStart(3)} files, ${(assetSizes[type] / 1024).toFixed(0).padStart(5)} KB`);
    }
  }

  // Measure which assets take longest by checking individual load times
  console.log('');
  await page.close();
}

// Now test with a minimal config to see the lower bound
console.log('--- Analysis ---');
console.log('');
console.log('The game loads ALL assets upfront via Assets.loadEverything().');
console.log('This includes every entity YAML, every map JSON, every PNG sprite,');
console.log('every font — even ones not used by the current level.');
console.log('');
console.log('For faster test iterations, we need a test-specific configuration');
console.log('that loads fewer assets or uses a minimal level.');

await browser.close();
