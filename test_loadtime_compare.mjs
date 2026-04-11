import { chromium } from 'playwright';

const PORT = 8081;

console.log('=== LOAD TIME COMPARISON (fresh contexts) ===\n');

async function measureLoad(url, label) {
  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage();
  let readyTime = null;
  let testModeActive = false;
  const start = Date.now();

  page.on('console', msg => {
    const text = msg.text();
    if (text.includes('[PERF]') && text.includes('time') && !readyTime) {
      readyTime = Date.now() - start;
    }
    if (text.includes('[GAME:TESTMODE]')) testModeActive = true;
  });

  await page.goto(url);
  try {
    await page.waitForEvent('console', {
      predicate: msg => msg.text().includes('time') && msg.text().includes('[PERF]'),
      timeout: 15000,
    });
  } catch {}

  console.log(`${label}: ${readyTime}ms ${testModeActive ? '(testmode)' : ''}`);
  await browser.close();
  return readyTime;
}

const normalTimes = [];
const testTimes = [];

for (let i = 0; i < 3; i++) {
  normalTimes.push(await measureLoad(`http://localhost:${PORT}`, `Normal #${i+1}`));
  testTimes.push(await measureLoad(`http://localhost:${PORT}?testmode=true`, `Test   #${i+1}`));
}

const avgNormal = normalTimes.filter(Boolean).reduce((a,b) => a+b, 0) / normalTimes.filter(Boolean).length;
const avgTest = testTimes.filter(Boolean).reduce((a,b) => a+b, 0) / testTimes.filter(Boolean).length;

console.log(`\nNormal avg: ${Math.round(avgNormal)}ms`);
console.log(`Test avg:   ${Math.round(avgTest)}ms`);
console.log(`Speedup:    ${Math.round((1 - avgTest/avgNormal) * 100)}%`);
console.log(`Savings:    ${Math.round(avgNormal - avgTest)}ms per tab`);
