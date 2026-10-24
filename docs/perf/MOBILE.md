# Mobile Web performance and the minute-7 crash (Oct 24, 2026)

The owner's report: "another crash at minute 7 on stage 3 [the Sanctum of Judgment] ... the phone being on low power
mode and the amount of projectiles on screen". Played from the Home Screen icon; the page **reloaded to its Play
screen**, which on iOS means the WebContent process was killed for memory (jetsam), not a hang and not a lost WebGL
context. This file is the measurement, what was changed and the numbers before and after.

## Method

- **Builds.** "Before" is `integration` 3cbe21f plus the read-only probes of this branch (`--monitor`, inert
  `AdaptiveQuality`); "after" is branch `perf/mobile-web`. Both are the release Web export (no threads) with
  `tools/patch_web_audio.py` applied (after: it also applies `tools/patch_web_gl.py`).
- **Driver.** `tools/mobile_web_perf.js` serves `build/web/`, opens it in headless Chromium as an iPhone in landscape
  (844 × 390 CSS px, devicePixelRatio 3, touch, mobile), throttles the CPU through the DevTools protocol
  (`Emulation.setCPUThrottlingRate`, a stand-in for Low Power Mode), taps the Play gate and every 5 s samples the
  WebAssembly heap (`engine.rtenv.HEAPU8.length`), the **retained** JS heap (a forced GC, then
  `Runtime.getHeapUsage`), the canvas buffer size, the frame intervals and the WebGL objects the page created
  (`createBuffer` / `createVertexArray` / `createTexture` wrapped and counted). The run's own lines come from
  `--monitor=15` (`MonitorProbe`: Godot's object / node / resource counts, video / texture / buffer memory, canvas
  items, draw calls, primitives, the live shots / bursts / effects / particles / numbers, the frame times, the visual
  tier) and `--perf` (`PerfProbe`, tick times). `--draw-probe=T` hides one world layer at a time to see which one
  rebuilds its GL objects every frame.
- **Runs.** Sanctum, seed 7, to 14:00 (`--timeout=840`) or 10:00:
  - **A** `--policy=army --effects=reduced` (the phone default), CPU ×4, DPR 3, real-time windows at 6:40-7:10 and
    12:50-13:20 (`--perf-real=400-430,770-800`), the rest at the autotest's 8×;
  - **B** a volley-heavy forced build, `--policy=summon --classes=archer,mage,frost_wraith`, Effects Full, as A;
  - **C** `--policy=army`, Effects Full, CPU ×1, DPR 1 (fast software rendering, so many more frames per game
    minute: the per-frame counts and the memory growth per frame), `--speed=2` to 10:00.
  - All with `--adaptive=off` (the adaptive quality would otherwise react to the software renderer's slow frames;
    run F shows it on).
- **Caveat.** The container has no GPU: Chromium draws WebGL with SwiftShader on the CPU, so absolute frame times
  (0.1-3 s) say nothing about a phone's GPU; they scale with the pixels drawn and the GL calls made, so ratios
  between builds count. Heap sizes, WebGL object counts and WebAssembly tick times compare directly.

## What the measurement found

### 1. The leak: WebGL ids are never reused (the crash)

Emscripten's WebGL layer (inside Godot 4.3's Web export) gives every GL object an id from **one counter that only
counts up** (`GL.getNewId`) and pads each object table (buffers, vertex arrays, syncs, ...) with `null`s up to that
id; deleting an object only sets its slot to `null`. Godot's 2D renderer creates and deletes **a vertex array and
two buffers for every polygon** of every canvas item that redraws (`draw_circle`, `draw_arc`, thick `draw_line`,
`draw_colored_polygon`, ...). So every polygon drawn in a redrawn frame leaves slots behind forever.

| Run C (before), game time | GL ids created per frame | retained JS heap |
| --- | --- | --- |
| 1:15 | 197 | 10.2 MB |
| 3:47 | 752 | 16.2 MB |
| 5:33 | 1,670 | 33.9 MB |
| 7:04 | 2,517 | 46.4 MB |
| 9:21 | 2,867 | **87.5 MB** |

The retained JS heap grew **8.1 → 87.6 MB in 2,371 rendered frames** (about 34 KB a frame, and rising with the
fight). A phone draws 30 frames a second in Low Power Mode, 60 otherwise: at the Sanctum's 5-7 minute load that is
**60-140 MB a minute**, more in Safari (its arrays store 8 bytes a slot where V8 stores 4). Runs A and B, which drew
only about one frame a second, still reached a retained JS heap of 180 / 265 MB by 14:00. The growth follows
**frames × polygons per frame**, which is why it tracked busy screens full of projectiles; Low Power Mode does not
change it per frame but slows everything else. This is also the "JS heap grows to 0.4-0.9 GB over a run" seen in
the Act III Web check (GDD §15.0), which was blamed on sounds. **Fix:** `tools/patch_web_gl.py` (GDD §15.0 "Web GL
id leak patch").

### 1b. The Hellhounds (the owner's reproduction)

The owner reproduced the crash and pointed at the **Hellhounds** (Bone Hounds + Blood Scent Lv 5). Run H: Sanctum,
seed 7, `--policy=summon --classes=bone_hound --passives=blood_scent`, DPR 1, CPU ×1, `--speed=2`, to 12:00; the
Hellhound evolution arrives at **8:00** (the evolution gate), 12 hounds.

- Their **fire trail is bounded and pooled**: a patch every 0.3 s per running hound that has moved 26 px, 1.6 s
  life, one pooled `HordeHazards.Patch` list with a safety cap of 160 (never reached: 40-62 live, 0 dropped);
  burns are capped at 24 per hound and end with the hound; no effect nodes, no growth in Godot's object count.
- But the hazards node **redraws every patch every frame**, and each patch was 2 `draw_circle` + 3
  `draw_colored_polygon`: with the GL id leak above, the evolution multiplied the leak.

| Run H (before), game time | GL ids created per frame | retained JS heap |
| --- | --- | --- |
| 7:20 (bone hounds) | 2,467 | 46.4 MB |
| 8:05 (Hellhounds arrive) | 6,847 | 121.3 MB |
| 8:51 | 14,710 | 127.2 MB |
| 10:07 | 15,072 | 198.6 MB |
| 10:37 | 18,170 | **293.1 MB** (peak sample 434.9 MB) |

About **0.25 MB of JS heap per frame** after the evolution: at a phone's 30 fps, some 400 MB a minute, which iOS
cannot survive for long. That is the reload a minute or so after the Hellhounds appear. **After** (the GL patch, and
the fire patch drawn as two discs and three `draw_primitive` triangles, which batch): 290-1,340 GL ids a frame and
a retained JS heap of **8.2 → 8.8 MB** over the whole run (peak sample 8.8 MB); the same evolutions at the same
times (gameplay identical, natively too: the Hellhound run's same-seed summary is unchanged); primitives at 10:07
28,510 → 12,277, draw calls 1,468 → 1,171; 576 s instead of 665 s of wall time.

### 2. Where the polygons came from

`--draw-probe=380` (after the volley fix, before the shadow fix; each layer hidden for 30 frames between unhidden
phases, ~370 GL ids a frame unhidden): hiding the **enemies** dropped it to ~216, the **army** to ~202; volleys,
projectiles, pickups, particles, the HUD and the ground made no clear difference. The common part of every unit's
redraw is the **drop shadow** under its sprite (`SpriteBank.draw()`, a squashed `draw_circle`: a 64-point polygon),
and the units redraw often (walk / idle frames, hit flashes, facing flips). Before the volley fix, the glow circle
under every volley shot was the other big source (up to 320 a frame).

### 3. The canvas at devicePixelRatio 3

The page sized the drawing buffer at CSS × devicePixelRatio: **2532 × 1170 px** on an iPhone, filled every frame,
with Godot's own render buffers at the same size (`buf` = 21 MB in the monitor at DPR 3).

### 4. What does not grow

- **WebAssembly heap:** 165.6 MB at the start of a run (198.8 MB after the menu theme is rendered at the title
  screen), one step to 198.8 MB at about 9:00 in every run (texture memory rises by 16 MB then: large effect
  strips such as the Soul Nova's 5120 × 512 load and decode through the heap), flat otherwise; identical before and
  after. The heap never shrinks, so this is the high-water mark a phone keeps.
- **Godot objects / nodes / resources:** about 4,100-4,600 objects, 950-1,320 nodes, 560-640 resources at 6-14
  minutes, rising only with what the run meets (pools fill, new kinds load); no orphan nodes. The Stream audio
  playback of PR #1 keeps the object count flat.
- **Transients** are all capped: volley shots ≤ 320 (B reached the cap), bursts ≤ 96, cosmetic effects ≤ 220,
  particles ≤ 320, damage numbers ≤ 40.
- **Simulation (WASM ticks, CPU ×4):** 13-20 ms a tick at 5-14 minutes (A), so a throttled phone already needs
  most of a 33 ms frame for the two ticks of a 30 fps frame.

## What changed (all drawing / engine-glue only; gameplay untouched)

1. **`tools/patch_web_gl.py`** (run by `tools/patch_web_audio.py`, so CI and the one documented export step apply
   it): each GL table keeps a free list; deletes put the id on it, `getNewId` takes a free id first (as native GL
   drivers reuse names). GDD §15.0 "Web GL id leak patch".
2. **One disc texture for shadows and glows** (`SpriteBank.disc()` / `draw_disc()`): drop shadows, volley glows,
   the Hellhound fire patches (plus three `draw_primitive` triangles each), shard fields and boulder telegraphs
   are tinted textured rects (they batch, no GPU buffers rebuilt per redraw). Volleys draw all glows, then the
   masks grouped by style (additive blending: same picture), impacts before flashes, and skip what is more than
   48 px off screen; damage numbers draw outlines then fills and cache their text. GDD §15.0 "Disc texture for
   shadows and glows".
3. **Phone resolution cap**: at most 2 device px per CSS px on a phone (`TouchData.CANVAS_DPR_CAP`,
   `window.necroSetCanvasCap()` in the shell), with the CSS-size maths reading the real canvas scale. GDD §15.0
   "Phone resolution cap".
4. **Adaptive quality** (`AdaptiveQuality`, `EffectsData.TIER_*` / `ADAPT_*`): the drawn load steps down while the
   2 s median frame stays over 42 ms and back up after 8 s under 36 ms. GDD §15.0 "Adaptive quality".
5. **Web solo physics catch-up cap**: at most 3 ticks a frame (`FrameData.WEB_SOLO_MAX_STEPS`). GDD §15.0 "Web
   physics catch-up cap".

## Before / after

### Run C (DPR 1, CPU ×1, army, Effects Full, to 10:00)

| | Before | After |
| --- | --- | --- |
| GL ids created per frame, 5:30-9:30 | 1,670-2,870 | 180-660 (about 250 typical) |
| Retained JS heap at 9:30 | **87.5 MB** (from 8.1) | **8.6 MB** (from 8.1) |
| Peak WebAssembly heap | 198.8 MB | 198.8 MB |
| Draw calls / primitives at 6:00 | 1,432 / 29,014 | 1,353 / 21,753 |
| Draw calls / primitives at 10:00 | 1,460 / 29,416 | 1,237 / 17,789 |
| Wall time for 10 game minutes | 518 s | 380 s (-27%: fewer GL calls a frame) |

### Runs A and B (iPhone page at DPR 3, CPU ×4, to 14:00)

| | A before | A after | B before | B after |
| --- | --- | --- | --- | --- |
| Canvas buffer | 2532 × 1170 | **1688 × 780** | 2532 × 1170 | **1688 × 780** |
| Peak JS heap (sampled) | **180.2 MB** | **8.9 MB** | **265.0 MB** | **9.0 MB** |
| Peak WebAssembly heap | 198.8 MB | 198.8 MB | 198.8 MB | 198.8 MB |
| Godot video memory at 13:00 (textures) | 67.3 MB (46.1) | 56.0 MB (35.1) | 72.8 MB (51.7) | 61.5 MB (40.7) |
| Draw calls / primitives at 13:00 | 1,848 / 29,754 | 1,744 / 19,834 | 1,646 / 25,482 | 1,602 / 18,476 |
| Rendered frame, mean / p95 (software GL) | 1,025 / 1,569 ms | **502 / 636 ms** | 884 / 1,300 ms | **480 / 610 ms** |
| Wall time for 14 game minutes | 1,737 s | 1,236 s | 1,740 s | 1,208 s |
| Volley shots, peak | 123 | 123 | 320 (cap) | 320 (cap) |

The frames halve: 44% of the pixels and far fewer GL calls a frame. The browser's own canvas buffers (front and
back, not in Godot's video memory) shrink from about 24 MB to about 11 MB as well. The WebAssembly tick under ×4
throttling read 13-14 ms in both (12.7 / 14.1 ms mean over the run in A, 11.9 / 13.2 in B; the throttle pauses the
page's thread at random, more often when it renders more frames); natively the same seed's ticks are unchanged
(Sanctum army, `--perf`, run side by side: 2.22 vs 2.21 ms mean), and the gameplay is identical (gates below).

### Taps with the cap (`tools/mobile_tap_check.js`, DPR 3)

Uncapped (before) and capped (after) pages took the same taps at the same CSS points: the title's Play, the
Graveyard card, Begin, a joystick drag (the necromancer walked right), the pause button. The screenshots match in
CSS px (menus, the joystick ring, the four buttons), the canvas buffer is 2532 × 1170 before and 1688 × 780 after,
`window.necroCanvasScale` 2.

### Hellhound run at the iPhone page (H3: DPR 3 capped, CPU ×4, adaptive on)

Peak JS heap 9.1 MB, peak WebAssembly heap 198.8 MB, rendered frames 618 / 790 ms (mean / p95, software GL), the
same evolutions at the same times (Hellhound 8:00, Lich 9:44, Profane Bishop 10:25), 45-60 live fire patches. Its
adaptive quality never stepped: every software-rendered frame was longer than the first hitch filter (250 ms, "a
load, not the frame rate") and the window wanted 20 frames. Both were loosened (`ADAPT_HITCH_MS` 1000 ms,
`ADAPT_MIN_FRAMES` 5) so a device that only draws a few frames a second still steps down; run G (the same page, army
policy) then went Full → Minimal within its first 15 s of play.

### Adaptive quality on the Web build (run F, DPR 1, CPU ×1, default `--adaptive`)

Under the software renderer's ~90-140 ms frames it stepped down three times within the first 30 s (Full → Reduced
→ Light → Minimal) and stayed there (`[visual] adaptive quality: level 3, peak 3, steps down 3, up 0`), no errors.
Natively under the headless 8× autotest it stepped too (co-op bot: level 3; the Wastes: down 2, up 2) and every
same-seed summary stayed identical, which shows it touches drawing only.

## Gates

- `--import` clean; native seed 7 Graveyard default, `--mortal`, `--policy=army`, Sanctum army, Harbour army
  (Act II), Wastes army (Act III) and `--coop-bot`: **identical** `[autotest]` / `[metric]` summaries to 3cbe21f
  (`docs/act3/tools/same_seed_gate.py`), zero `SCRIPT ERROR` / `ERROR:` / `WARNING:`, `stuck_units=0`.
- Co-op lockstep: untouched by construction (the physics cap is solo only and the adaptive tier is drawing only;
  the co-op bot summary is identical).

## Conclusion

The minute-7 crash is, with high confidence, **memory growth from Emscripten never reusing WebGL ids**: every
polygon Godot redrew left table slots behind, thousands a frame in a busy Sanctum fight, so the page grew by tens
of MB a minute until iOS killed it. More projectiles meant more polygons a frame, which is why it felt tied to the
projectiles, and the Hellhounds' fire trail (about 50 patches redrawn as five polygons each, every frame) multiplied
it about sixfold the moment they evolved; Low Power Mode made each frame slower but did not cause the growth. The patch stops the growth (the
retained JS heap stays at 8-9 MB through the same fight instead of climbing past 85 MB), and the disc texture cuts
the per-frame GL objects by about 90%, which also lowers the CPU cost of each frame. The resolution cap, the adaptive
quality and the physics cap lower the per-frame load further on slow phones.

**Still needs the owner's real iPhone:** a long Sanctum (or Ul-Thalos) run from the Home Screen icon in Low Power
Mode on the GitHub Pages build (the crash should be gone; Safari's Web Inspector → Timelines → Memory shows the
page's footprint if not); whether the 2× canvas looks as crisp as before on the phone; how often the adaptive quality
steps down on the real GPU (a 30 fps cap alone should not trigger it); the audio under load.
