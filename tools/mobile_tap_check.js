// mobile_tap_check.js: checks the Web build's touch input and layout on an iPhone-sized page
// (docs/perf/MOBILE.md, the phone resolution cap). It serves build/web/, opens it at 844 x 390 CSS
// px with devicePixelRatio 3 (touch, mobile), taps the Play gate, then runs a list of steps: a tap
// at a CSS point, a finger drag, a wait, or a screenshot, and logs the canvas buffer size and the
// page's window.necroCanvasScale. Screenshots go to <out_dir>/<name>.png (CSS px size), so a build
// with and one without the cap can be compared: the same taps must land on the same buttons.
// Usage: node tools/mobile_tap_check.js <build_dir> <out_dir> "<steps>"
//   steps, separated by ";": "wait:MS", "tap:X,Y", "drag:X1,Y1,X2,Y2,MS", "shot:NAME"
//   (coordinates in CSS px of the 844 x 390 page).
// Chromium comes from PLAYWRIGHT_BROWSERS_PATH (/opt/pw-browsers); nothing is installed.
const http = require('http');
const fs = require('fs');
const path = require('path');
const { chromium } = require('playwright');

const [buildDir, outDir, steps] = process.argv.slice(2);
const TYPES = { '.html': 'text/html', '.js': 'application/javascript', '.wasm': 'application/wasm',
  '.pck': 'application/octet-stream', '.png': 'image/png', '.json': 'application/json' };
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
  fs.mkdirSync(outDir, { recursive: true });
  await new Promise((r) => server.listen(0, '127.0.0.1', r));
  const browser = await chromium.launch({ headless: true });
  const context = await browser.newContext({ viewport: { width: 844, height: 390 }, deviceScaleFactor: 3,
    isMobile: true, hasTouch: true });
  const page = await context.newPage();
  const cdp = await context.newCDPSession(page);
  page.on('console', (m) => { const t = m.text(); if (/error|warning/i.test(t)) console.log('console: ' + t); });
  page.on('pageerror', (e) => console.log('PAGEERROR ' + e.message));
  await page.goto(`http://127.0.0.1:${server.address().port}/index.html`);
  const play = page.locator('#status-play');
  await play.waitFor({ state: 'visible', timeout: 300000 });
  await play.tap();
  // One finger through the DevTools protocol (Playwright's tap is a single point; a drag needs moves).
  const touch = async (type, x, y) => cdp.send('Input.dispatchTouchEvent', { type, touchPoints: type === 'touchEnd' ? [] : [{ x, y }] });
  for (const step of steps.split(';').map((s) => s.trim()).filter((s) => s)) {
    const [kind, arg] = step.split(':');
    const n = (arg || '').split(',').map(parseFloat);
    if (kind === 'wait') {
      await page.waitForTimeout(n[0]);
    } else if (kind === 'tap') {
      await touch('touchStart', n[0], n[1]);
      await page.waitForTimeout(80);
      await touch('touchEnd', n[0], n[1]);
    } else if (kind === 'drag') {
      const [x1, y1, x2, y2, ms] = n;
      await touch('touchStart', x1, y1);
      const k = 12;  // Move events along the drag.
      for (let i = 1; i <= k; i++) {
        await touch('touchMove', x1 + (x2 - x1) * i / k, y1 + (y2 - y1) * i / k);
        await page.waitForTimeout(ms / k);
      }
      await touch('touchEnd', x2, y2);
    } else if (kind === 'shot') {
      const info = await page.evaluate(() => {
        const c = document.getElementById('canvas');
        return `canvas ${c.width}x${c.height}, css ${c.style.width}x${c.style.height}, necroCanvasScale ${window.necroCanvasScale}, dpr ${window.devicePixelRatio}`;
      });
      await page.screenshot({ path: path.join(outDir, arg + '.png'), scale: 'css' });
      console.log(`shot ${arg}: ${info}`);
    }
  }
  await browser.close();
  server.close();
})();
