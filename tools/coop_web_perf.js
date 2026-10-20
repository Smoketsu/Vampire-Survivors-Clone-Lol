// coop_web_perf.js: measures the Web build's frame and tick times in headless Chromium
// (docs/coop/PERF.md, the co-op performance question). It serves build/web/ on a local
// port, opens the page with the autotest flags in the URL (?necro_autotest=...; read by
// GameState._web_args()), presses the Play gate, waits for the run to end and saves the
// console (the "[perf]" table and the autotest summary) to a log file.
// Usage: node tools/coop_web_perf.js <build_dir> <out.log> <viewport: phone|desktop>
//        "<comma-separated autotest flags>" [timeout_minutes]
// Chromium comes from /opt/pw-browsers (PLAYWRIGHT_BROWSERS_PATH); nothing is installed.
const http = require('http');
const fs = require('fs');
const path = require('path');
const { chromium } = require('playwright');

const [buildDir, outLog, view, flags, timeoutMin] = process.argv.slice(2);
const TYPES = { '.html': 'text/html', '.js': 'application/javascript', '.wasm': 'application/wasm',
  '.pck': 'application/octet-stream', '.png': 'image/png', '.svg': 'image/svg+xml', '.json': 'application/json' };

const server = http.createServer((req, res) => {
  const url = decodeURIComponent(req.url.split('?')[0]);
  const file = path.join(buildDir, url === '/' ? 'index.html' : url);
  fs.readFile(file, (err, data) => {
    if (err) { res.writeHead(404); res.end(); return; }
    res.writeHead(200, { 'Content-Type': TYPES[path.extname(file)] || 'application/octet-stream' });
    res.end(data);
  });
});

(async () => {
  await new Promise((r) => server.listen(0, '127.0.0.1', r));
  const port = server.address().port;
  const browser = await chromium.launch({ headless: true, args: ['--use-gl=angle', '--use-angle=swiftshader', '--enable-unsafe-swiftshader'] });
  const phone = view === 'phone';
  const context = await browser.newContext(phone
    ? { viewport: { width: 844, height: 390 }, deviceScaleFactor: 3, isMobile: true, hasTouch: true }
    : { viewport: { width: 1280, height: 720 }, deviceScaleFactor: 1 });
  const page = await context.newPage();
  const lines = [];
  let done = false;
  page.on('console', (msg) => {
    const t = msg.text();
    lines.push(t);
    if (t.includes('[perf] volley shots:') || t.includes('[perf] rendered frames')) done = done || t.includes('[perf] rendered frames');
  });
  page.on('pageerror', (e) => lines.push('PAGEERROR ' + e.message));
  await page.goto(`http://127.0.0.1:${port}/index.html?necro_autotest=${encodeURIComponent(flags)}`);
  const play = page.locator('#status-play');
  await play.waitFor({ state: 'visible', timeout: 120000 });
  if (phone) { await play.tap(); } else { await play.click(); }
  const deadline = Date.now() + (parseFloat(timeoutMin || '60') * 60000);
  while (!done && Date.now() < deadline) {
    await page.waitForTimeout(5000);
    if (lines.some((l) => l.includes('[perf] volley shots:'))) {
      await page.waitForTimeout(3000);  // The frame lines follow the table.
      break;
    }
  }
  fs.writeFileSync(outLog, lines.join('\n') + '\n');
  await browser.close();
  server.close();
})();
