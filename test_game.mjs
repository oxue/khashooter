import { chromium } from 'playwright';

const url = process.argv[2] || 'http://localhost:8081';
const duration = parseInt(process.argv[3] || '5') * 1000;

const browser = await chromium.launch({ headless: false });
const context = await browser.newContext();
const page = await context.newPage();

const errors = [];
const warnings = [];
const logs = [];

page.on('console', msg => {
  const type = msg.type();
  const text = msg.text();
  if (type === 'error') {
    // Ignore favicon 404
    if (text.includes('favicon')) return;
    if (text.includes('404')) return; // browser-level 404 messages lack URL detail
    errors.push(text);
    console.log(`[ERROR] ${text}`);
  } else if (type === 'warning') {
    warnings.push(text);
    console.log(`[WARN] ${text}`);
  } else {
    logs.push(text);
    console.log(`[LOG] ${text}`);
  }
});

page.on('pageerror', err => {
  // YAML parser throws/catches internally during type resolution — ignore
  if (err.message.includes('haxe_ValueException') && !err.stack) return;
  errors.push(err.message + '\n' + err.stack);
  console.log(`[PAGE_ERROR] ${err.message}`);
  console.log(`[STACK] ${err.stack}`);
});

page.on('requestfailed', req => {
  console.log(`[REQ_FAILED] ${req.url()} - ${req.failure()?.errorText}`);
});

page.on('response', resp => {
  if (resp.status() >= 400) {
    console.log(`[HTTP_${resp.status()}] ${resp.url()}`);
  }
});

console.log(`Opening ${url} for ${duration/1000}s...`);
await page.goto(url);

// Click the canvas to give it focus
await page.click('#khanvas');

// Wait for the specified duration
await new Promise(r => setTimeout(r, duration));

console.log('\n=== SUMMARY ===');
console.log(`Errors: ${errors.length}`);
console.log(`Warnings: ${warnings.length}`);
console.log(`Logs: ${logs.length}`);

if (errors.length > 0) {
  console.log('\n=== ERRORS ===');
  for (const e of errors) console.log(e);
}

await browser.close();
process.exit(errors.length > 0 ? 1 : 0);
