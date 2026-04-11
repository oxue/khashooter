import { chromium } from 'playwright';
const browser = await chromium.launch({ headless: true });
const page = await browser.newPage();
page.on('pageerror', err => {
  console.log('ERROR:', err.message);
  if (err.stack) console.log('STACK:', err.stack.split('\n').slice(0, 8).join('\n'));
});
page.on('console', msg => {
  if (msg.text().includes('TESTMODE') || msg.text().includes('ERROR') || msg.type() === 'error') {
    console.log(`[${msg.type()}] ${msg.text()}`);
  }
});
await page.goto('http://localhost:8081?testmode=true');
await new Promise(r => setTimeout(r, 4000));
await browser.close();
