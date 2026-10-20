// coop_web_lockstep.js: the co-op lockstep between the Web build and a native process, or between two Web pages
// (co-op milestone 2, GDD 15.0 "Co-op lockstep: Web and desktop mixing"). It starts tools/coop_relay.py on a free
// port, serves build/web/ on another, and plays ONE co-op run through the lockstep:
//   native-web : a headless native Godot process hosts (`--autotest --coop-net=host`), a headless Chromium page
//                joins (the same flags through ?necro_autotest=, the relay through ?relay=);
//   web-web    : one page hosts, a second page (its own browser context) joins.
// Each side's army bot plays its own slot; both compare a state checksum every 60 ticks (CoopLockstep) and print
// the same final state when the simulations agree. Headless Chromium draws on the CPU, so keep the run short
// (--timeout=, game seconds). Prints PASS when both sides end at the same tick with the same final state, the same
// checksum chain and no desync.
// Usage: node tools/coop_web_lockstep.js <build_dir> <native-web|web-web> <out_prefix> [game_seconds] [seed]
// Chromium comes from PLAYWRIGHT_BROWSERS_PATH (/opt/pw-browsers); nothing is installed.
const http = require('http');
const fs = require('fs');
const path = require('path');
const { spawn } = require('child_process');
const { chromium } = require('playwright');

const [buildDir, mode, outPrefix, gameSecArg, seedArg] = process.argv.slice(2);
const ROOT = path.dirname(__dirname);
const GODOT = process.env.GODOT || '/home/user/tools/godot/Godot_v4.3-stable_linux.x86_64';
const gameSec = parseFloat(gameSecArg || '180');
const seed = parseInt(seedArg || '7', 10);
const TYPES = { '.html': 'text/html', '.js': 'application/javascript', '.wasm': 'application/wasm',
  '.pck': 'application/octet-stream', '.png': 'image/png', '.svg': 'image/svg+xml', '.json': 'application/json' };
const WALL_LIMIT_MS = 90 * 60000;  // Whole test (ms).

function serve() {
  const server = http.createServer((req, res) => {
    const url = decodeURIComponent(req.url.split('?')[0]);
    const file = path.join(buildDir, url === '/' ? 'index.html' : url);
    fs.readFile(file, (err, data) => {
      if (err) { res.writeHead(404); res.end(); return; }
      res.writeHead(200, { 'Content-Type': TYPES[path.extname(file)] || 'application/octet-stream' });
      res.end(data);
    });
  });
  return new Promise((r) => server.listen(0, '127.0.0.1', () => r(server)));
}

function startRelay() {
  return new Promise((resolve, reject) => {
    const p = spawn('python3', [path.join(ROOT, 'tools', 'coop_relay.py'), '--port', '0', '--quiet']);
    let buf = '';
    p.stdout.on('data', (d) => {
      buf += d.toString();
      const m = buf.match(/LISTENING (\S+) (\d+)/);
      if (m) resolve({ proc: p, url: `ws://127.0.0.1:${m[2]}` });
    });
    p.on('error', reject);
  });
}

// Flags both sides share (the run), then the role's own.
function runFlags() {
  // --coop-mixed: the lobby lets the other platform in (the game itself refuses it, CoopNetData.ALLOW_MIXED_PLATFORMS).
  return [`--seed=${seed}`, '--speed=8', '--stage=graveyard', '--policy=army', `--timeout=${gameSec}`, '--coop-mixed'];
}

async function openPage(browser, port, relay, flags, lines, tag) {
  const context = await browser.newContext({ viewport: { width: 1280, height: 720 }, deviceScaleFactor: 1 });
  const page = await context.newPage();
  page.on('console', (msg) => { const t = msg.text(); lines.push(t); if (/^\[coop\]|^COOP_|lockstep|^\[autotest\] t=/.test(t)) console.log(`[${tag}] ${t}`); });
  page.on('pageerror', (e) => lines.push('PAGEERROR ' + e.message));
  const q = `necro_autotest=${encodeURIComponent(flags.join(','))}&relay=${encodeURIComponent(relay)}`;
  await page.goto(`http://127.0.0.1:${port}/index.html?${q}`);
  const play = page.locator('#status-play');
  await play.waitFor({ state: 'visible', timeout: 300000 });
  await play.click();
  return page;
}

function waitFor(pred, ms) {
  return new Promise((resolve) => {
    const t0 = Date.now();
    const h = setInterval(() => {
      const v = pred();
      if (v || Date.now() - t0 > ms) { clearInterval(h); resolve(v); }
    }, 500);
  });
}

function pick(lines, prefix) { return lines.filter((l) => l.startsWith(prefix)); }

(async () => {
  const t0 = Date.now();
  const server = await serve();
  const port = server.address().port;
  const relay = await startRelay();
  console.log(`relay ${relay.url}, mode ${mode}, ${gameSec} game s, seed ${seed}`);
  const browser = await chromium.launch({ headless: true });
  const hostLines = [];
  const joinLines = [];
  let native = null;
  if (mode === 'native-web') {
    native = spawn(GODOT, ['--headless', '--path', ROOT, '--fixed-fps', '60', '--', '--autotest', `--relay=${relay.url}`,
      '--coop-net=host', '--character=gravecaller', ...runFlags()]);
    let buf = '';
    native.stdout.on('data', (d) => {
      buf += d.toString();
      let i;
      while ((i = buf.indexOf('\n')) >= 0) {
        const l = buf.slice(0, i); buf = buf.slice(i + 1); hostLines.push(l);
        if (/^\[coop\]|^COOP_|lockstep|^\[autotest\] t=|ERROR|WARNING/.test(l)) console.log(`[native] ${l}`);
      }
    });
  } else {
    await openPage(browser, port, relay.url, ['--coop-net=host', '--character=gravecaller', ...runFlags()], hostLines, 'web-host');
  }
  const code = await waitFor(() => { const l = hostLines.find((x) => x.startsWith('COOP_CODE=')); return l ? l.slice(10, 15) : null; }, 300000);
  if (!code) { console.log('FAIL: no lobby code'); process.exit(1); }
  await openPage(browser, port, relay.url, ['--coop-net=join', `--coop-code=${code}`, '--character=bone_oracle', ...runFlags()], joinLines, 'web-join');
  const done = (ls) => ls.some((l) => l.startsWith('[autotest] coop lockstep:'));
  await waitFor(() => done(hostLines) && done(joinLines), WALL_LIMIT_MS);
  await new Promise((r) => setTimeout(r, 3000));
  fs.writeFileSync(`${outPrefix}_host.log`, hostLines.join('\n') + '\n');
  fs.writeFileSync(`${outPrefix}_join.log`, joinLines.join('\n') + '\n');
  const endH = pick(hostLines, '[coop] run ended');
  const endJ = pick(joinLines, '[coop] run ended');
  const lsH = pick(hostLines, '[autotest] coop lockstep:');
  const lsJ = pick(joinLines, '[autotest] coop lockstep:');
  const chain = (l) => { const m = (l || '').match(/ticks (\d+) .*chain ([0-9a-f]+)/); return m ? m[1] + ':' + m[2] : null; };
  const desync = hostLines.concat(joinLines).filter((l) => l.includes('DESYNC'));
  // Errors before the run ended (a page error after it, e.g. the audio context gone after the engine quit, is not the test's).
  const beforeEnd = (ls) => { const i = ls.findIndex((l) => l.startsWith('[coop] run ended')); return i < 0 ? ls : ls.slice(0, i); };
  const bad = beforeEnd(hostLines).concat(beforeEnd(joinLines)).filter((l) => /SCRIPT ERROR|^ERROR:|PAGEERROR/.test(l));
  const late = hostLines.concat(joinLines).filter((l) => /PAGEERROR/.test(l)).length - bad.filter((l) => /PAGEERROR/.test(l)).length;
  if (late > 0) console.log(`(${late} page error(s) after the run ended, ignored)`);
  console.log(`--- result (wall ${((Date.now() - t0) / 1000).toFixed(0)} s) ---`);
  for (const l of endH.concat(endJ, lsH, lsJ, desync, bad.slice(0, 5))) console.log(l);
  const ok = endH.length > 0 && endH[0] === endJ[0] && chain(lsH[0]) === chain(lsJ[0]) && desync.length === 0 && bad.length === 0;
  console.log(ok ? 'PASS' : 'FAIL');
  await browser.close();
  server.close();
  relay.proc.kill();
  if (native) native.kill();
  process.exit(ok ? 0 : 1);
})();
