// Playwright check of the co-op lobby screens in the Web build (GDD 15.0 "Online co-op: relay and lobby").
//
// Two browser pages against the local relay (tools/coop_relay.py), each its own game:
//   * the HOST on a 1280x720 desktop viewport: title screen -> Co-op -> Host (keyboard), lobby waiting;
//   * the GUEST on an 844x390 phone in landscape (touch, coarse pointer): opened from the shared link
//     `?join=CODE`, so the Join letter pad opens filled in; a finger taps Delete, then the last letter on the
//     pad, then Join, then Ready; the host presses Start, and both pages must log the run's start with the
//     same seed.
// Screenshots go to docs/coop/shots/. Needs a Web export in build/web (see CLAUDE.md "Local web export") and the
// Playwright Node package (local or global npm install) with its Chromium (PLAYWRIGHT_BROWSERS_PATH); run with
//   node tools/coop_lobby_shots.mjs
// Exit status 0 when the whole flow passed.
import { execSync, spawn } from "node:child_process";
import { mkdirSync } from "node:fs";
import path from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";

// The Playwright package: a local install, else the global one (`npm root -g`).
async function loadPlaywright() {
  try {
    return await import("playwright");
  } catch (_e) {
    const g = execSync("npm root -g").toString().trim();
    return await import(pathToFileURL(path.join(g, "playwright", "index.mjs")).href);
  }
}
const { chromium } = await loadPlaywright();

// Repository root.
const ROOT = path.dirname(path.dirname(fileURLToPath(import.meta.url)));
// Static server port for build/web.
const WEB_PORT = 8060;
// Where the four committed screenshots go, and the extra ones (build/ is not committed).
const SHOTS = path.join(ROOT, "docs", "coop", "shots");
const EXTRA = path.join(ROOT, "build", "coop_shots");
// Longest wait for one step (ms).
const STEP_MS = 90000;

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

// Starts a child process and resolves with it once a stdout line matches `ready` (and the match).
function start(cmd, args, ready) {
  return new Promise((resolve, reject) => {
    const p = spawn(cmd, args, { cwd: ROOT, stdio: ["ignore", "pipe", "pipe"] });
    let done = false;
    const onData = (d) => {
      const m = String(d).match(ready);
      if (m && !done) {
        done = true;
        resolve({ p, m });
      }
    };
    p.stdout.on("data", onData);
    p.stderr.on("data", onData);
    p.on("exit", (c) => !done && reject(new Error(`${cmd} exited ${c}`)));
  });
}

// A page whose console lines are collected (and echoed with `tag`).
async function gamePage(browser, tag, contextOptions) {
  const ctx = await browser.newContext(contextOptions);
  const page = await ctx.newPage();
  page.logs = [];
  page.on("console", (msg) => {
    const t = msg.text();
    page.logs.push(t);
    if (t.includes("[coop]") || /ERROR|SCRIPT/.test(t)) console.log(`[${tag}] ${t}`);
  });
  page.on("pageerror", (e) => console.log(`[${tag}] pageerror ${e.message}`));
  return page;
}

// Waits until a console line of `page` matches `re`; returns the match.
async function waitLog(page, re, ms = STEP_MS) {
  const t0 = Date.now();
  while (Date.now() - t0 < ms) {
    for (const l of page.logs) {
      const m = l.match(re);
      if (m) return m;
    }
    await sleep(200);
  }
  throw new Error(`timed out waiting for ${re}`);
}

// Opens the game at `query`, presses the page's Play gate and waits for the title screen.
async function boot(page, query) {
  await page.goto(`http://127.0.0.1:${WEB_PORT}/index.html${query}`);
  await page.waitForSelector("#status-play", { state: "visible", timeout: STEP_MS });
  await page.click("#status-play");
  await waitLog(page, /\[audio\]/);
  await sleep(2500); // The title screen's entrance.
}

// A key press on the page's canvas (focus first).
async function key(page, k, times = 1) {
  for (let i = 0; i < times; i++) {
    await page.keyboard.press(k);
    await sleep(250);
  }
}

// Touch points (CSS px) on the 844x390 phone page, read off its screenshots (the mobile UI scale and the
// screens' fit_to_screen() shrink make them differ from the 1280x720 layout): the Join pad's Delete and Join,
// its first letter key (B) and the key pitch, and the lobby's Ready. A missed tap fails the flow (no join).
const PHONE = {
  delete: [364, 306],
  join: [472, 306],
  firstKey: [330, 163.5],
  keyPitch: [45.5, 35],
  ready: [525, 329],
  setup: [414, 329],
};
// Code letters in pad order (CoopNetData.CODE_ALPHABET) and the pad's columns.
const ALPHABET = "BCDFGHJKMNPQRSTVWXYZ";
const PAD_COLUMNS = 5;

// A finger tap at CSS point `p` of `page`.
async function tap(page, p) {
  await page.touchscreen.tap(p[0], p[1]);
  await sleep(400);
}

// The phone pad key of letter `ch`.
function keyPoint(ch) {
  const i = ALPHABET.indexOf(ch);
  return [PHONE.firstKey[0] + (i % PAD_COLUMNS) * PHONE.keyPitch[0], PHONE.firstKey[1] + Math.floor(i / PAD_COLUMNS) * PHONE.keyPitch[1]];
}

async function main() {
  mkdirSync(SHOTS, { recursive: true });
  mkdirSync(EXTRA, { recursive: true });
  const relay = await start("python3", ["tools/coop_relay.py", "--port", "0"], /LISTENING \S+ (\d+)/);
  const relayUrl = `ws://127.0.0.1:${relay.m[1]}`;
  const web = await start("python3", ["-m", "http.server", String(WEB_PORT), "--bind", "127.0.0.1", "-d", "build/web"], /Serving HTTP/);
  const browser = await chromium.launch({
    args: ["--use-gl=angle", "--use-angle=swiftshader", "--enable-unsafe-swiftshader", "--ignore-gpu-blocklist", "--autoplay-policy=no-user-gesture-required"],
  });
  let ok = false;
  try {
    const host = await gamePage(browser, "host", { viewport: { width: 1280, height: 720 } });
    await boot(host, `?relay=${encodeURIComponent(relayUrl)}`);
    await key(host, "ArrowDown"); // Play -> Co-op.
    await key(host, "Enter"); // Co-op screen (Host focused).
    await sleep(800);
    await key(host, "Enter"); // Host.
    const code = (await waitLog(host, /\[coop\] lobby ([A-Z]{5}), seat 0/))[1];
    await sleep(1500);
    await host.screenshot({ path: path.join(SHOTS, "lobby_host_waiting.png") });
    console.log(`host lobby ${code}`);

    const guest = await gamePage(browser, "guest", {
      viewport: { width: 844, height: 390 }, deviceScaleFactor: 2, isMobile: true, hasTouch: true,
    });
    await boot(guest, `?relay=${encodeURIComponent(relayUrl)}&join=${code}`);
    await sleep(1500);
    await guest.screenshot({ path: path.join(SHOTS, "join_pad_phone.png") });
    // Touch: Delete removes the last letter, its pad key types it back, Join joins.
    await tap(guest, PHONE.delete);
    await tap(guest, keyPoint(code.slice(-1)));
    await tap(guest, PHONE.join);
    await waitLog(guest, /\[coop\] lobby [A-Z]{5}, seat 1/);
    await waitLog(host, /\[coop\] partner joined: seat 1/);
    await sleep(3000); // Loadouts, settings, a ping or two.
    await guest.screenshot({ path: path.join(SHOTS, "lobby_two_players_phone.png") });
    // Host Setup (Start -> Left -> Setup): the solo pre-run screen with "Done"; Done returns to the lobby.
    await key(host, "ArrowLeft");
    await key(host, "Enter");
    await sleep(1500);
    await host.screenshot({ path: path.join(EXTRA, "host_setup.png") });
    await key(host, "Enter"); // Done (focused on open).
    await sleep(1200);
    // Guest Setup (a finger): the run part is the host's, read-only.
    await tap(guest, PHONE.setup);
    await sleep(1500);
    await guest.screenshot({ path: path.join(EXTRA, "guest_setup_phone.png") });
    await key(guest, "Enter"); // Done (focused on open).
    await sleep(1500);
    await host.screenshot({ path: path.join(EXTRA, "lobby_after_setup_host.png") });
    await key(host, "ArrowRight"); // Back to Start.
    await tap(guest, PHONE.ready); // Ready (a finger).
    await sleep(2500);
    await host.screenshot({ path: path.join(SHOTS, "lobby_guest_ready_host.png") });
    await key(host, "Enter"); // Start (focused on open).
    await waitLog(host, /\[coop\] run starts: seed (\d+), seat 0/);
    const g = await waitLog(guest, /\[coop\] run starts: seed (\d+), seat 1/);
    const h = await waitLog(host, /\[coop\] run starts: seed (\d+), seat 0/);
    if (g[1] !== h[1]) throw new Error(`seeds differ: ${h[1]} vs ${g[1]}`);
    await sleep(4000);
    await guest.screenshot({ path: path.join(EXTRA, "run_started_phone.png") });
    const bad = [...host.logs, ...guest.logs].filter((l) => /SCRIPT ERROR|^ERROR:|^WARNING:/.test(l));
    if (bad.length) throw new Error(`error lines: ${bad[0]}`);
    console.log(`PASS: both pages started the run with seed ${h[1]}`);
    ok = true;
  } catch (e) {
    console.log(`FAIL: ${e.message}`);
  } finally {
    await browser.close();
    relay.p.kill();
    web.p.kill();
  }
  process.exit(ok ? 0 : 1);
}

main();
