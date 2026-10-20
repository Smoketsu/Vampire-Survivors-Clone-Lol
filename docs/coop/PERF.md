# Co-op performance: two armies' volleys (milestone 1 measurements)

The owner's worry: with two players, both armies' volleys at once might hurt performance. This file answers it
with numbers from the co-op simulation (`--coop-bot`, both slots by the army bot) against solo (`--policy=army`),
same seed (7), same build (`coop-sim` on top of `integration` 18f72a5).

## Method

- **Simulation cost (headless, native Linux build):** `--perf` (PerfProbe, `scripts/coop/perf_probe.gd`) times every
  physics tick with `Time.get_ticks_usec()` around `Game._physics_process()` (co-op: `CoopSession.step()`), and
  files it under its game minute and under the busy moments: **boss** (the stage boss alive), **reckoning** (past
  0:00), **barrage** (a Rally Barrage running), **barrage2** (both armies' Rally Barrages at once), **late** (15:00 to
  0:00: full builds, full volleys). It also times six sections of the tick (army + spells, enemies with the stage
  directors, obstacles, projectiles, volleys, pickups + effects). Budget: one tick must fit in **16.7 ms** (60 Hz).
  Runs: `godot --headless --fixed-fps 60 --quit-after 30000 -- --autotest --seed=7 [--coop-bot] --perf`, at the
  autotest's 8x speed (each tick is still 1/60 s of game time, so the cost per tick is the real cost).
  Machine: the 4-core cloud container, another agent's work sharing it (expect +-10% noise; spikes over 40 ms are
  mostly the scheduler, they move between same-seed runs).
- **Web build (WASM) in headless Chromium:** the release Web export (no-threads, patched audio) served locally and
  driven by Playwright (`tools/coop_web_perf.js`); the page URL carries the autotest flags
  (`?necro_autotest=--coop-bot,--perf,...`, read by `GameState._web_args()`), the Play gate is tapped / clicked.
  Viewports: phone landscape 844x390 at deviceScaleFactor 3 with touch, and desktop 1280x720. Effects Full and
  Reduced (`--effects=reduced`). The run goes at 8x, except three real-time windows (`--perf-real=600-630,1050-1080,1200-1215`:
  10:00, the boss fight / late game at 17:30, the Reckoning) where the rendered-frame intervals are recorded.
  Caveat: headless Chromium has no GPU, it renders through SwiftShader on the CPU, so **frame times are a
  pessimistic upper bound** (a phone GPU draws this scene far faster); the **WASM tick times are the comparable
  number** to a real browser. Two browsers ran at once on the 4 cores.

## Headless simulation, ms per tick (mean / p95 / max), seed 7

### The Desecrated Graveyard

| Minute | Solo army | enemies / summons / shots | Co-op, 2 armies | enemies / summons / shots |
| --- | --- | --- | --- | --- |
| 05 | 1.21 / 1.59 / 50.9 | 46 / 22 / 6 | 3.65 / 5.61 / 47.7 | 82 / 58 / 20 |
| 10 | 2.19 / 3.29 / 8.7 | 63 / 39 / 37 | 5.37 / 8.56 / 58.2 | 117 / 82 / 80 |
| 13 | 3.26 / 4.92 / 47.2 | 101 / 47 / 68 | 7.12 / 10.62 / 31.0 | 179 / 90 / 113 |
| 15 (busiest) | 3.81 / 5.74 / 19.0 | 142 / 45 / 69 | **10.55 / 16.26 / 53.6** (4.1% of ticks over 16.7) | 317 / 91 / 107 |
| 16 | 3.25 / 4.79 / 13.5 | 120 / 46 / 53 | 8.99 / 13.72 / 31.8 | 243 / 94 / 105 |
| 17 (boss) | 2.98 / 4.58 / 13.5 | 71 / 50 / 53 | 5.98 / 9.35 / 67.2 | 107 / 93 / 106 |
| 19 | 3.15 / 4.56 / 40.2 | 86 / 45 / 54 | 6.28 / 9.23 / 17.0 | 137 / 90 / 96 |
| 20 (Reckoning) | 3.34 / 4.82 / 19.5 | 89 / 38 / 54 | 7.77 / 11.46 / 47.5 | 203 / 68 / 94 |
| **whole run** | **2.21 / 4.21 / 50.9** | | **5.38 / 10.38 / 79.4** (0.3% over) | |

| Moment | Solo | Co-op |
| --- | --- | --- |
| boss alive | 3.06 / 4.62 / 13.5 | 6.21 / 10.25 / 67.2 |
| Reckoning | 3.34 / 4.82 / 19.5 | 7.77 / 11.46 / 47.5 |
| a Rally Barrage | 3.46 / 5.06 / 19.5 | 6.66 / 11.69 / 67.2 |
| **both armies' Rally Barrages at once** | (n/a) | **8.49 / 13.32 / 67.2** (893 ticks, 193 shots in flight) |
| 15:00 to 0:00 | 3.11 / 4.89 / 40.2 | 7.62 / 12.80 / 67.2 (1.2% over) |

### The Scrap Wastes (Act III)

| Minute / moment | Solo army | Co-op |
| --- | --- | --- |
| 10 | 3.43 / 5.15 / 17.4 | 6.65 / 9.82 / 35.3 |
| 13 | 4.17 / 6.34 / 17.4 | 9.15 / 14.22 / 26.8 |
| 16 (busiest) | 4.42 / 6.57 / 24.6 | 9.65 / 14.79 / 39.4 (1.7% over) |
| boss alive | 3.12 / 4.58 / 20.8 | 7.09 / 10.76 / 31.4 |
| Reckoning | 3.11 / 4.59 / 30.5 | 7.51 / 11.18 / 15.8 |
| both Rally Barrages | (n/a) | 5.48 / 9.00 / 15.7 |
| **whole run** | **2.66 / 5.08 / 46.1** | **6.16 / 11.12 / 78.0** (0.3% over) |

Gullhaven Harbour (Act II) co-op: whole run 5.71 / 10.04 / 49.6, both barrages 8.78 / 12.61 / 23.9 (solo was not
re-timed there).

### Where the time goes (mean ms per tick, 15:00 to 0:00)

| Section | Graveyard solo | Graveyard co-op | Wastes solo | Wastes co-op |
| --- | --- | --- | --- | --- |
| army + spells (both slots) | 1.20 | 2.35 | 1.25 | 2.68 |
| **enemies** (AI, movement, blocking, stage directors) | **1.09** | **3.35** | **1.31** | **3.60** |
| obstacles | 0.29 | 0.57 | 0.26 | 0.50 |
| projectiles (+ Empire shots) | 0.18 | 0.44 | 0.27 | 0.69 |
| **volleys** (both armies) | **0.26** | **0.49** | **0.32** | **0.57** |
| pickups + effects | 0.08 | 0.41 | 0.10 | 0.27 |
| total | 3.10 | 7.61 | 3.51 | 8.31 |

## The volley shot cap

`VolleyData.SHOT_CAP` (320) is per `VolleyDirector`, and in co-op **each army has its own director** (its volleys
belong to its slot: Rally Barrage, spell echoes, class levels), so the two armies do **not** share one cap: each
army's volleys look exactly as in solo. Measured: peak in flight 588 (Graveyard) / 385 (Wastes) for both armies
together, 320 / 316 for one army; the cap thinned 4 and 1 volleys in a whole run (solo: 0). The volleys cost
0.5 ms of a co-op tick, about 6%: **they are not the bottleneck**. Drawing on Effects = Reduced is capped at 160 shots
per director, so up to 320 drawn in co-op.

## Web build (WASM, headless Chromium)

Graveyard, co-op (both army bots), phone viewport 844x390 @3x with touch. Tick = the simulation in WASM
(comparable to a real browser); frames = SwiftShader on the CPU (an upper bound, see the method).

| Minute / moment | Co-op, Effects Full | Co-op, Effects Reduced | enemies / summons / shots |
| --- | --- | --- | --- |
| 05 | 5.00 / 7.40 / 78.0 | 5.09 / 7.80 / 77.3 | 79 / 57 / 22 |
| 10 | 7.68 / 12.00 / 59.0 | 7.48 / 11.70 / 49.0 | 106 / 82 / 77 |
| 13 | 10.69 / 16.30 / 204.7 | 10.69 / 15.40 / 376.9 | 161 / 92 / 114 |
| **15 (busiest)** | **14.58 / 22.00 / 135.3 (20.9% of ticks over 16.7)** | 14.17 / 21.50 / 73.3 (19.7% over) | 287 / 91 / 108 |
| 16 | 13.44 / 20.60 / 70.8 (16.2% over) | 12.99 / 21.00 / 97.7 (14.8% over) | 223 / 94 / 114 |
| 17 | 9.43 / 15.00 / 86.6 | 9.80 / 15.70 / 100.6 | 110 / 93 / 121 |
| 20 (Reckoning) | 9.78 / 14.30 / 239.0 | 9.53 / 14.50 / 164.3 | 180 / 61 / 76 |
| boss alive | 9.46 / 14.60 / 86.6 | 9.63 / 15.00 / 193.3 | 118 / 93 / 114 |
| both Rally Barrages | 12.69 / 19.70 / 86.6 (10.8% over) | 12.77 / 18.50 / 28.0 (11.9% over) | 156 / 96 / 177 |
| 15:00 to 0:00 | 11.14 / 18.50 / 135.3 (8.4% over) | 10.95 / 18.60 / 193.3 (7.8% over) | 179 / 92 / 108 |
| **whole run** | **7.82 / 15.00 / 239.0 (3.0% over)** | 7.69 / 14.70 / 376.9 (2.8% over) | |
| sections, 15:00-0:00 | army 3.31, **enemies 4.72**, obstacles 0.87, projectiles 0.78, volleys 0.74, pickups 0.71 | the same within 0.15 | |
| rendered frames (real-time windows) | 488 / 655 / 850 ms | 488 / 679 / 918 ms | |

WASM ticks cost about 1.4x native ones (whole run 7.8 vs 5.4 ms). Effects Reduced changes the tick by nothing
(drawing only) and did not change the SwiftShader frame either: at 2532x1170 device pixels the CPU rasteriser,
not the shot count, sets the frame time (a phone GPU would not be in that regime); a real-phone measurement on
the GitHub Pages build is the next step. Desktop 1280x720 and the solo phone comparison: PENDING (running when
this file was written; the next session adds them).

**Determinism note:** the same seed played out slightly differently in WASM than natively from the first minutes
(79 vs 82 enemies alive at 5:00): the Web and desktop simulations are not bit-identical, so as the design doc
feared, lockstep across web and desktop would desync. Mixed platforms must be refused unless a checksum test
proves otherwise (two Web peers, or two desktop peers, are fine).

## Conclusion

- **Desktop (native): co-op fits the budget.** Two armies cost 2.4x a solo tick (whole run 5.4 vs 2.2 ms;
  Wastes 6.2 vs 2.7). The worst minute (Graveyard 15:00, 317 enemies alive against the doubled cap of 360) averages
  10.6 ms with p95 16.3 ms; 0.3% of all ticks pass 16.7 ms.
- **Both armies' volleys are not the problem.** Each army keeps its own 320-shot cap (no sharing, so neither army's
  volleys look halved); together they peak at ~590 shots and cost 0.5-0.7 ms a tick. Both Rally Barrages at once
  cost 8.5 ms natively, 12.7 ms in WASM.
- **The cost is the doubled enemies** (enemies section 3.4 ms native / 4.7 ms WASM late in the run, superlinear
  with the alive count) and the two armies (2.4 / 3.3 ms).
- **Web: over budget at the late-game peaks.** WASM averages 7.8 ms over the run, but 14-15 ms at 15:00-16:00 with
  15-21% of ticks over 16.7 ms (the run then slows a little: a tick is not dropped, the game time stretches).
  On a phone CPU (slower than this container) it will be worse.

**Recommendation (not applied yet):**
1. A **co-op alive cap** below 2x: `CoopData.SCALING.alive_cap` 2.0 -> 1.6 (hard cap 288) and keep the trickle x2:
   the busiest minutes are exactly the ones at the cap, and enemies dominate the cost. Try 1.6 and 1.4 with
   `--perf` on the Web build first.
2. Keep the **per-army shot cap 320** (gameplay parity with solo; volleys are cheap). On Effects Reduced give the
   two armies one shared draw budget (160 total, 80 each) only if real phones show drawing as the limit.
3. Profile the enemy step for the second biggest win: the separation / blocking queries scale with crowd density;
   a 10 Hz stagger of `resolve_blocking()` for enemies that are not touching a blocker would cut it.
4. Measure on real phones (iOS Safari first) with `?necro_autotest=--coop-bot,--perf,--perf-real=...` on the Pages
   build; the frame numbers above are SwiftShader's and say nothing about a GPU.
