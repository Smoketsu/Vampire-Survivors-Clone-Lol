// mobile_web_perf.js: measures the Web build on a phone-sized page in headless Chromium for the
// mobile Web performance pass (docs/perf/MOBILE.md). It serves build/web/ on a local port, opens
// the page as an iPhone in landscape (844 x 390 CSS px, devicePixelRatio 3, touch, mobile) with the
// autotest flags in the URL (?necro_autotest=...; GameState._web_args()), throttles the CPU through
// the DevTools protocol (Emulation.setCPUThrottlingRate, a stand-in for iOS Low Power Mode), taps the
// Play gate and, every few seconds, samples the page: the WebAssembly heap (engine.rtenv.HEAPU8),
// the JS heap (CDP Runtime.getHeapUsage), the canvas drawing buffer size and the frame intervals the
// browser's requestAnimationFrame saw. The run's own "[mon]" lines (MonitorProbe, --monitor=N) and
// "[perf]" table (--perf) come from the console. Everything is written to the log file; a short
// progress line goes to stdout.
// Usage: node tools/mobile_web_perf.js <build_dir> <out.log> "<comma-separated autotest flags>"
//        [cpu_throttle=4] [timeout_minutes=60] [dpr=3]
// Chromium comes from PLAYWRIGHT_BROWSERS_PATH (/opt/pw-browsers); nothing is installed. Headless
// Chromium draws with SwiftShader (on the CPU), so frame times are a pessimistic upper bound that
// scales with the drawing buffer's pixel count; heap sizes and WebAssembly tick times compare.
const http = require('http');
const fs = require('fs');
const path = require('path');
const { chromium } = require('playwright');

const [buildDir, outLog, flags, throttleArg, timeoutMin, dprArg] = process.argv.slice(2);
const throttle = parseFloat(throttleArg || '4');  // CPU slow-down factor (1 = none).
const dpr = parseFloat(dprArg || '3');  // Device px per CSS px of the emulated phone.
const SAMPLE_MS = 5000;  // Real ms between two page samples.
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
  const browser = await chromium.launch({ headless: true, args: ['--enable-precise-memory-info'] });
  const context = await browser.newContext({ viewport: { width: 844, height: 390 }, deviceScaleFactor: dpr,
    isMobile: true, hasTouch: true });
  const page = await context.newPage();
  const cdp = await context.newCDPSession(page);
  const lines = [];
  page.on('console', (msg) => lines.push(msg.text()));
  page.on('pageerror', (e) => lines.push('PAGEERROR ' + e.message));
  page.on('crash', () => lines.push('PAGECRASH'));
  // Frame intervals as the browser's own animation frames see them (same main thread as Godot).
  // Also counts the WebGL objects the engine creates (each one takes a new id in the engine's GL tables).
  await page.addInitScript(() => {
    window.__frames = [];
    window.__gl = { buffers: 0, vaos: 0, textures: 0, delBuffers: 0 };
    let last = 0;
    const tick = (t) => { if (last > 0) { window.__frames.push(t - last); } last = t; requestAnimationFrame(tick); };
    requestAnimationFrame(tick);
    const P = window.WebGL2RenderingContext && WebGL2RenderingContext.prototype;
    if (P) {
      const wrap = (name, key) => { const f = P[name]; P[name] = function () { window.__gl[key]++; return f.apply(this, arguments); }; };
      wrap('createBuffer', 'buffers');
      wrap('createVertexArray', 'vaos');
      wrap('createTexture', 'textures');
      wrap('deleteBuffer', 'delBuffers');
    }
  });
  const t0 = Date.now();
  await page.goto(`http://127.0.0.1:${port}/index.html?necro_autotest=${encodeURIComponent(flags)}`);
  const play = page.locator('#status-play');
  await play.waitFor({ state: 'visible', timeout: 300000 });
  if (throttle > 1) {
    await cdp.send('Emulation.setCPUThrottlingRate', { rate: throttle });
  }
  await play.tap();
  const deadline = Date.now() + parseFloat(timeoutMin || '60') * 60000;
  let peakHeap = 0;
  let peakJs = 0;
  while (Date.now() < deadline) {
    await page.waitForTimeout(SAMPLE_MS);
    let s;
    try {
      s = await page.evaluate(() => {
        const f = window.__frames.splice(0).sort((a, b) => a - b);
        const c = document.getElementById('canvas');
        const heap = (typeof engine !== 'undefined' && engine.rtenv && engine.rtenv.HEAPU8) ? engine.rtenv.HEAPU8.length : 0;
        const gl = Object.assign({}, window.__gl);
        return { heap, gl, n: f.length, med: f.length ? f[f.length >> 1] : 0, p95: f.length ? f[Math.min(f.length - 1, Math.floor(f.length * 0.95))] : 0,
          max: f.length ? f[f.length - 1] : 0, cw: c.width, ch: c.height, css: `${c.style.width}x${c.style.height}` };
      });
    } catch (e) {
      lines.push('[web] sample failed: ' + e.message);
      break;
    }
    await cdp.send('HeapProfiler.collectGarbage').catch(() => {});  // Retained JS heap, not garbage.
    const hu = await cdp.send('Runtime.getHeapUsage').catch(() => ({ usedSize: 0, totalSize: 0 }));
    peakHeap = Math.max(peakHeap, s.heap);
    peakJs = Math.max(peakJs, hu.usedSize);
    const mon = lines.filter((l) => l.startsWith('[mon] t=')).pop() || '';
    const at = ((Date.now() - t0) / 1000).toFixed(0);
    const row = `[web] ${at} s heap=${(s.heap / 1048576).toFixed(1)}MB js=${(hu.usedSize / 1048576).toFixed(1)}/${(hu.totalSize / 1048576).toFixed(1)}MB canvas=${s.cw}x${s.ch} gl buf=${s.gl.buffers} vao=${s.gl.vaos} tex=${s.gl.textures} del=${s.gl.delBuffers} raf n=${s.n} med=${s.med.toFixed(1)} p95=${s.p95.toFixed(1)} max=${s.max.toFixed(1)} ms | ${mon.slice(0, 60)}`;
    lines.push(row);
    console.log(row);
    if (lines.some((l) => l.startsWith('[mon] peak') || l.startsWith('PAGECRASH'))) {
      await page.waitForTimeout(2000);
      break;
    }
  }
  lines.push(`[web] wall ${((Date.now() - t0) / 1000).toFixed(0)} s, throttle ${throttle}x, dpr ${dpr}, peak heap ${(peakHeap / 1048576).toFixed(1)} MB, peak JS ${(peakJs / 1048576).toFixed(1)} MB, flags ${flags}`);
  fs.writeFileSync(outLog, lines.join('\n') + '\n');
  await browser.close();
  server.close();
})();
