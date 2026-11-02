// web_smoke.js: CI's smoke test of the exported Web build (GDD 15.0 "CI publishing safety"). It serves
// <build_dir> (build/web: index.html + .js + .wasm + .pck, after tools/patch_web_audio.py) on a free local
// port, opens it in headless Chromium at the 1280 x 720 layout size, waits for the page's Play gate
// (#status-play, web/mobile_shell.html), presses it, and then waits for the engine's own startup line
// ("Godot Engine v4.3...", printed to the console once the engine runs). It passes when that line comes within
// STARTUP_LIMIT_MS of the press and no error shows up until LINGER_MS later (the title screen loading): no
// uncaught page error, no console.error (Godot prints its SCRIPT ERROR / ERROR: lines through it), no page
// crash and no failed request. Every console line is echoed, so a red run shows why.
// Usage: node tools/web_smoke.js <build_dir>
// Exit status 0 = pass, 1 = fail. Needs the Playwright Node package and its Chromium (CI installs both; locally
// PLAYWRIGHT_BROWSERS_PATH and a global install work, as for tools/mobile_web_perf.js, whose static server this
// reuses).
const http = require('http');
const fs = require('fs');
const path = require('path');
const { chromium } = require('playwright');

const buildDir = process.argv[2] || 'build/web';  // The exported Web build folder.
const LOAD_LIMIT_MS = 180000;  // Longest wait for the Play gate (ms): downloading and compiling the .wasm.
const STARTUP_LIMIT_MS = 60000;  // Longest wait from the Play press to the engine's startup line (ms).
const LINGER_MS = 10000;  // Time after the startup line still watched for errors (ms): the title screen loads.
const STARTUP_LINE = /^Godot Engine v4\./;  // The engine's first console line once it runs.
// File extension -> the Content-Type served for it (the .wasm one is what streaming compilation needs).
const TYPES = { '.html': 'text/html', '.js': 'application/javascript', '.wasm': 'application/wasm',
  '.pck': 'application/octet-stream', '.png': 'image/png', '.svg': 'image/svg+xml', '.json': 'application/json' };

// The static server (the same as tools/mobile_web_perf.js); /favicon.ico gets an empty answer, so a browser's
// own icon request is never a failed request.
const server = http.createServer((req, res) => {
  const url = decodeURIComponent(req.url.split('?')[0]);
  if (url === '/favicon.ico') { res.writeHead(204); res.end(); return; }
  const file = path.join(buildDir, url === '/' ? 'index.html' : url);
  fs.readFile(file, (err, data) => {
    if (err) { res.writeHead(404); res.end(); return; }
    res.writeHead(200, { 'Content-Type': TYPES[path.extname(file)] || 'application/octet-stream' });
    res.end(data);
  });
});

(async () => {
  const errors = [];  // Every error seen, as text (any one fails the test).
  let started = 0;  // Date.now() when the startup line came (0 = not yet).
  if (!fs.existsSync(path.join(buildDir, 'index.html'))) {
    console.log(`FAIL: no index.html in ${buildDir}`);
    process.exit(1);
  }
  await new Promise((r) => server.listen(0, '127.0.0.1', r));
  const port = server.address().port;  // The free port the server got.
  // --enable-unsafe-swiftshader: WebGL 2 on the CPU (a CI runner has no GPU; newer Chromium needs the flag).
  const browser = await chromium.launch({ headless: true, args: ['--enable-unsafe-swiftshader'] });
  const page = await browser.newPage({ viewport: { width: 1280, height: 720 } });
  page.on('console', (m) => {
    const t = m.text();
    console.log(`[console.${m.type()}] ${t}`);
    if (m.type() === 'error') errors.push(`console.error: ${t}`);
    if (!started && STARTUP_LINE.test(t)) started = Date.now();
  });
  page.on('pageerror', (e) => { console.log(`[pageerror] ${e.message}`); errors.push(`page error: ${e.message}`); });
  page.on('crash', () => errors.push('page crashed'));
  page.on('requestfailed', (r) => errors.push(`request failed: ${r.url()} (${r.failure() && r.failure().errorText})`));
  page.on('response', (r) => { if (r.status() >= 400) errors.push(`HTTP ${r.status()}: ${r.url()}`); });

  let verdict = '';  // Why the test failed ('' = it passed).
  try {
    await page.goto(`http://127.0.0.1:${port}/index.html`);
    const play = page.locator('#status-play');
    await play.waitFor({ state: 'visible', timeout: LOAD_LIMIT_MS });
    await play.click();
    const pressed = Date.now();  // When Play was pressed (ms).
    while (!started && errors.length === 0 && Date.now() - pressed < STARTUP_LIMIT_MS) {
      await page.waitForTimeout(250);
    }
    if (!started && errors.length === 0) verdict = `no engine startup line within ${STARTUP_LIMIT_MS / 1000} s of Play`;
    if (started) await page.waitForTimeout(LINGER_MS);
  } catch (e) {
    verdict = `page did not load: ${e.message}`;
  }
  if (!verdict && errors.length > 0) verdict = errors.join('\n  ');
  await browser.close();
  server.close();
  if (verdict) {
    console.log(`FAIL: ${verdict}`);
    process.exit(1);
  }
  console.log(`PASS: the engine started and ran ${LINGER_MS / 1000} s without errors`);
  process.exit(0);
})();
