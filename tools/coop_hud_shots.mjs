// Screenshots of the co-op HUD in the Web build (GDD 15.0 "Co-op HUD and visuals"), on a phone in landscape
// (844 x 390 CSS px, touch, coarse pointer) or a desktop (1280 x 720).
//
// It serves build/web, opens the page with the autotest flags in the URL (?necro_autotest=...; GameState._web_args()):
//   --coop-bot,--seed=7,--coop-down=60,--coop-shots=<victory|defeat>[,--coop-down-slot=0]
// and presses the Play gate. The game's debug walk (CoopUiTest) prints "[coop-shot] NAME" and holds the world
// still (CoopHudData.TEST_WEB_HOLD s) at each state: the HUD with the partner plate, the off-screen arrow, the
// waiting panel, a notice banner, the downed partner (or "self_downed"), then the results card; this script
// screenshots the page during each hold into docs/coop/shots/coop_<NAME>_<view>.png and stops at "[coop-shot] done".
// The touch controls show because the walk adds them on a touch screen (a test run has none otherwise).
// Needs a Web export in build/web (CLAUDE.md "Local web export") and the Playwright package (local or global) with
// its Chromium (PLAYWRIGHT_BROWSERS_PATH); nothing is installed. Run with
//   node tools/coop_hud_shots.mjs <phone|desktop> <victory|defeat> [self|-] [seed, default 7]
// (the bots' paths differ per seed and viewport, so another seed may be needed for the off-screen arrow).
// Exit status 0 when every shot was taken.
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
const WEB_PORT = 8061;
// Where the screenshots go (committed).
const SHOTS = path.join(ROOT, "docs", "coop", "shots");
// Longest wait for the whole walk (ms).
const WALK_MS = 15 * 60000;
// Wait (ms) after a "[coop-shot]" line before the screenshot: a held frame has been drawn.
const SETTLE_MS = 2500;

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

const [view = "phone", ending = "defeat", self = "", seed = "7"] = process.argv.slice(2);
const phone = view === "phone";
const flags = ["--coop-bot", `--seed=${seed}`, "--coop-down=60", `--coop-shots=${ending}`];
if (self === "self") flags.push("--coop-down-slot=0");

// Starts a child process and resolves with it once a stdout / stderr line matches `ready`.
function start(cmd, args, ready) {
  return new Promise((resolve, reject) => {
    const p = spawn(cmd, args, { cwd: ROOT, stdio: ["ignore", "pipe", "pipe"] });
    let done = false;
    const onData = (d) => {
      if (!done && String(d).match(ready)) {
        done = true;
        resolve(p);
      }
    };
    p.stdout.on("data", onData);
    p.stderr.on("data", onData);
    p.on("exit", (c) => !done && reject(new Error(`${cmd} exited ${c}`)));
  });
}

async function main() {
  mkdirSync(SHOTS, { recursive: true });
  const web = await start("python3", ["-m", "http.server", String(WEB_PORT), "--bind", "127.0.0.1", "-d", "build/web"], /Serving HTTP/);
  const browser = await chromium.launch({
    args: ["--use-gl=angle", "--use-angle=swiftshader", "--enable-unsafe-swiftshader", "--ignore-gpu-blocklist", "--autoplay-policy=no-user-gesture-required"],
  });
  const ctx = await browser.newContext(phone
    ? { viewport: { width: 844, height: 390 }, deviceScaleFactor: 2, isMobile: true, hasTouch: true }
    : { viewport: { width: 1280, height: 720 }, deviceScaleFactor: 1 });
  const page = await ctx.newPage();
  const lines = [];
  let pending = []; // "[coop-shot] NAME" lines not yet shot.
  page.on("console", (msg) => {
    const t = msg.text();
    lines.push(t);
    if (/SCRIPT ERROR|^ERROR|WARNING/.test(t)) console.log(`[page] ${t}`);
    const m = t.match(/^\[coop-shot\] (\w+)$/);
    if (m) pending.push(m[1]);
    if (t.startsWith("[autotest] coop ui:")) console.log(t);
  });
  page.on("pageerror", (e) => console.log(`[page] pageerror ${e.message}`));
  await page.goto(`http://127.0.0.1:${WEB_PORT}/index.html?necro_autotest=${encodeURIComponent(flags.join(","))}`);
  const play = page.locator("#status-play");
  await play.waitFor({ state: "visible", timeout: 180000 });
  if (phone) await play.tap({ noWaitAfter: true });
  else await play.click({ noWaitAfter: true });
  const shots = [];
  const t0 = Date.now();
  let done = false;
  while (!done && Date.now() - t0 < WALK_MS) {
    await sleep(250);
    while (pending.length > 0) {
      const name = pending.shift();
      if (name === "done") {
        done = true;
        break;
      }
      await sleep(SETTLE_MS);
      const file = path.join(SHOTS, `coop_${name}_${view}.png`);
      await page.screenshot({ path: file });
      shots.push(file);
      console.log(`shot ${file} (${((Date.now() - t0) / 1000).toFixed(0)} s)`);
    }
  }
  await browser.close();
  web.kill();
  console.log(`${shots.length} shots, walk ${done ? "done" : "timed out"}`);
  process.exit(done && shots.length > 0 ? 0 : 1);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
