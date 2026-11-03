# Making Necropathy leaner: findings and proposal (Nov 3, 2026)

This is a read-only survey of `main` plus the review branch (`claude/adversarial-code-review-kpdm1y`). Nothing has
been changed. The codebase has very little dead code: all 570 scripts are reachable, and only about 250 lines of
unused functions and constants turned up. The weight is elsewhere:

| Where | Today | Who pays for it |
|---|---|---|
| `art_source/` (finished-art inputs) | 766 MB in the working tree; most of the 1.1 GB `.git` | every clone, every CI job, every cloud session |
| `CLAUDE.md` | 64 KB, about 16k tokens; 43 KB of it is the "Development plan" history | every Claude session and every agent, before any work starts |
| Web build | 35 MB stock engine `.wasm` + 15 MB `.pck` | every player's first load, phones most of all |
| CI | ~17 jobs, each doing a full checkout (about 850 MB with `art_source/` and `docs/`) and a cold import | the push-to-live time |
| Code | 137k lines (87k code, 38k comments). About 5k lines are duplication or never-reached fallback drawing | maintenance, agent reading time |
| `docs/` | 43 MB, about 27 MB of it finished review pages and screenshots | clones |

The comment share (about 30%) is the owner's documentation rule and stays.

---

## 1. Lean `CLAUDE.md` (biggest win per minute of work)

**Finding.**
- `CLAUDE.md` is 701 lines / 64 KB.
- Its "Development plan" section (the "Done" lists for v0.3 through Act V) is 43 KB.
- That history is already in GDD §15.0 and the README, yet it is loaded into every session and every subagent.

**Proposal.**
- Move the "Done" lists to `docs/HISTORY.md`.
- Keep in `CLAUDE.md` only:
  - the conventions;
  - the design pillars;
  - the tools and "Done means";
  - the balance targets;
  - the "Next, in priority order" list;
  - one line pointing to the history.
- Also trim the CI paragraph to what an agent needs: job names, gates and the publish rules.

**Effect.** About 64 KB → 18-20 KB, so about 11k fewer tokens per session and per agent. A five-agent batch saves
about 55k tokens before anyone reads a file. **Risk:** none for the game. Agents lose nothing, because the history
stays one link away.

## 2. CI: stop moving and re-importing 800 MB per job

**Finding.**
- Every job runs a plain `actions/checkout@v4`. That is a shallow clone, but still the full working tree, including
  `art_source/` (766 MB) and `docs/` (43 MB), which are `.gdignore`d and never used in CI.
- Every Godot job also re-imports 1,731 PNGs from scratch, because `.godot/imported` is not cached.

**Proposal.**
- **Sparse checkout:** `with: sparse-checkout: |` listing `scripts`, `scenes`, `assets`, `tools`, `server`, `web`,
  `project.godot`, `export_presets.cfg` and `.github`, plus `sparse-checkout-cone-mode: true`. That is about 40 MB
  instead of about 850 MB per job.
- **Import cache:** `actions/cache` on `.godot/imported` and `.godot/*.cfg`, keyed on
  `hashFiles('assets/**', 'project.godot')`. The import step still runs and checks scripts, but with nothing to
  re-import.

**Effect.** Likely 30-90 s saved per job across about 17 parallel jobs. That is less runner time and a shorter path
to the live build, and it also lowers the risk of hitting runner disk limits. **Risk:** low. Check that no CI step
reads `docs/`. One does: the release job's notes file under `docs/release_notes/`, so keep that path in the release
job's checkout. **Effort:** S.

## 3. Repository size: `art_source/` out of the main tree

**Finding.**
- `art_source/` holds 1,089 source PNGs (concepts, raw generations, epilogue sources) for an art pass that is done.
- The game never reads them.
- Its 24 `.py` / 3 `.sh` generators (~127 KB, e.g. `make_menu_art.py`) are the only part tools reference.

**Options** (the owner's call):
1. **Move the PNGs to a separate `necropathy-art` repository** (or a release asset / cloud folder) and keep the
   generators here. New clones and cloud sessions at `clone_depth 50` stop carrying the 766 MB once the move commit is
   older than the clone depth. **No history rewrite needed.** Effort S.
2. **Git LFS for `art_source/**/*.png`.** This keeps everything in one repo, but LFS bandwidth is metered on GitHub's
   free plan.
3. **Also rewrite history** (`git filter-repo`) to drop the old blobs, which takes `.git` from 1.1 GB to about
   100 MB. This is destructive: every clone and open branch must be re-cloned or rebased. Only worth it if clone size
   still hurts after option 1.

**Recommendation:** option 1 now. Treat option 3 as optional later.

**Docs, same idea:**
- Finished art-review pages: `docs/art/*_review/`, 17 MB.
- `docs/ossuary/shots/` (3.7 MB) and `docs/text_review/` (1.9 MB).
- `docs/itch/` (3.8 MB): itch.io publishing was dropped, so this is certain dead.

All of these can move with the art. Keep `docs/media/v0.5.0/hero.gif`, the README image.

## 4. Web build: a smaller engine for phones

**Finding.** The page downloads the **stock** Godot 4.3 Web template: 35.4 MB of `.wasm` plus a 15.3 MB `.pck`. The
game is 2D, uses the GL Compatibility renderer and no physics engine for units.

**Proposal.** Build a custom no-threads Web export template once in CI, cached by Godot version, with:
- `disable_3d=yes`;
- `optimize=size`;
- unused modules off: 3D physics, navigation, OpenXR, WebRTC, GLTF/FBX, CSG, GridMap, Theora, text-server-advanced if
  the fonts allow it (Jersey / Jacquard are Latin-only).

Use it through `export_presets.cfg`'s `custom_template`.

**Effect.** Typically about 35 → 15-20 MB of `.wasm`: a much faster first load and less memory on the phones that
already reload under pressure. **Risk:**
- **Co-op:** Web vs Web must still match. Both sides run the same build, and mixed platforms are refused anyway.
- **Features:** must re-check everything the game uses (WebSocket is needed for co-op, so keep `websocket`). The
  headless Chromium smoke test, `coop_web_lockstep.js` and an iPhone check gate it.

**Effort:** M, because the template build takes CI time once per Godot version.

## 5. Code: about 5,000 lines that can go without touching the same-seed gate

Everything in 5a-5e is drawing-only, text-only or dead. Headless runs skip `_draw()`, so the same-seed summaries stay
identical by construction. Confirm anyway with the usual default / `--mortal` / army runs.

| # | What | Lines | Risk | Effort |
|---|---|---|---|---|
| 5a | **Unused symbols:** 23 functions and 27 constants with zero references (e.g. `HordeDirector.apply_stance`, `Game.bind_slot`, `Sfx.active_voices`, `UiTheme.header_band`, `Sfx.MUSIC_TIDE/IRON/BRONZE/SUN`, 4 dropped `UltimateData.PICKER_*` layout constants), plus the stance **flavour bonus** that is permanently off (`StanceData.BONUSES_ENABLED = false`, `ArmyStance.bonus()`, its two always-0 reads in `compute_stats`). Keep `CharacterData.INNATE_KEYS`: unused by code, but it documents the innate keys. | ~280 | none | S |
| 5b | **Stub floors:** `empire_ground.gd`, `pantheon_ground.gd` and `shogunate_ground.gd` are unreachable (no stage uses those `ground` ids any more), along with their three `match` arms in `game.gd` and the placeholder `FLOOR` dicts in 9 stage files. | ~370 | none | S |
| 5c | **One telegraph routine:** `CovenantFx` and `EmpireFx` each implement the same circle / line / cone telegraph; use one routine with a style table. | ~80 | none (visual) | S |
| 5d | **A `ZonedGround` base:** 14 `*_ground.gd` files repeat the same five members and `_draw` preamble. The code-drawn floor branch is never reached, because every zone style in use has its tile PNG. | ~600 | none (visual) | S-M |
| 5e | **`StageDirectorBase` + `TimeFmt.clock()`:** `_clock()` copied 9×, `_log()` 16×, `seek_point` 10×; the `"%d:%02d"` format in 17 files. Output text stays byte-identical. | ~200 | none if text matches | S |
| 5f | **Glyph fallbacks:** the `_draw` code that only runs when a PNG is missing. All 105 enemy kinds with art, all 41 summons, and 541 of 549 literal sprite keys have PNGs. Replace it with one visible "missing art" placeholder in `SpriteBank`. **Policy change:** CLAUDE.md keeps `_draw` "as the fallback for any missing PNG". Confirm first with `--art-misses` on all 15 stages. | ~2,800-3,200 | none for gameplay; owner decision | M |
| 5g | **Data-driven director list** in `EnemyDirector`: create / step / objective / event dispatch for 17 directors, plus the matching chain in `autotest.gd`. Step and priority order must stay exactly as today. | ~220 | medium: run the gate | M |
| 5h | **Enemy table defaults:** five `*_def()` `.has()` chains become one ordered table list. Fields that are almost always their default (`heal_*` in 103 of 105 rows, `projectile_speed` in 90, `undead_damage_mult` in 95) move to a cached `DEFAULTS` merge. 18 direct `ENEMIES[...]` reads must route through `enemy_def()`. | ~550 | medium: run the gate | M |
| 5i | **Area-hit helpers** `summons_in()` / `players_in()` for 86 + 79 hand-rolled query-and-filter loops. Iteration order must stay identical. | ~150-250 | medium-high: file by file, gate after each | M-L |

Smaller items: share `Meta._read_int`-style typed readers with `settings.gd`, and add an `ActReport` helper for the
three act reports (~50 lines). Splitting `autotest.gd` (1,932 lines) into a bot and a summary file reads better but
saves no lines.

**Already lean, no action:**
- UI construction (all through `UiTheme`).
- The kit hierarchy.
- The act rules classes (they differ in substance).
- The `generation` checks (one-liners).
- `assets/`: no sprite is provably unused, because keys are built from parts.

## 6. Tools

- **Needed (keep):**
  - the CI and test tools: `coop_*`, `patch_web_*`, `web_smoke.js`, `enemy_pool_check`, `ossuary_check` and its
    three part files;
  - the shared art pipeline: `prepare_sprite.py`, `make_tile.py`, `walk_cycle.py`, `ui_kit.py`, `pixelate_source.py`,
    `art_check.py`, `gen_image.py`, `palette.json`;
  - the documented measurement tools.
- **One-off, about 0.45 MB:** `act3_projectiles.py`, the `*aoe_art.py` family and `aoe_preview*`, the
  `*_props.py` set, `chest_beacon_art.py`, `relic_badges.py`, `skin_cap.py`, `epilogue_face.py`, `epilogue_panel.py`,
  the two `coop_*_shots.mjs`, and `text_review/`. These could move with `art_source/`.
  - Except `mesh_props.py` and `volley_art.py`: CLAUDE.md and the GDD name them as the way to remake that art.

## Suggested order

1. **CLAUDE.md trim (§1) and CI sparse checkout + import cache (§2).** No game risk; both pay back on every session
   and every push.
2. **Code batch 1 (5a-5e, about 1,500 lines).** One branch, gate-safe by construction; the default / `--mortal` /
   army runs plus the same-seed set to confirm.
3. **Owner decisions:**
   - move `art_source/` PNGs and the finished review docs out (§3);
   - drop the glyph fallbacks (5f);
   - build the custom Web template (§4).
4. **Code batch 2 (5g-5i).** One item per branch, the full same-seed gate after each.

Expected total:
- **Clones and CI:** about 850 MB lighter.
- **Each agent:** about 11k fewer tokens per session.
- **Phones:** about 15-20 MB less to download.
- **Code:** about 4-5k fewer lines, with the game's behaviour unchanged.
