# The last six acts: the lead's build plan

Owner decisions (Nov 7, 2026): build all six acts of `docs/proposals/LAST_SIX_ACTS.md` now, aiming to finish within the
week; the owner answered the doc's open questions in the doc: every recommendation is taken **except two**: the Norse act's first rule is
**the Long Winter** (the cold closes in, braziers are warmth; the Choosing is dropped), and the act select has **three Parts of five acts**
(I–V the living, VI–X gods, hell and heaven, XI–XV beyond and before; the Host ends Part Two). Use subagents
with the cheapest model that does the job. GDD §15.0 rows "The last five acts and the act order", "The fifteenth act: the
Celestial Host" and "Building the last six acts" record it.

The design of each act is its section in `docs/proposals/LAST_SIX_ACTS.md`. The Black Tide, the Necropolis Dynasty and
the Age of Titans have full proposals in `docs/proposals/NEW_ACTS_AND_ORDER.md` (Parts 1, 3 and 2); where the two
documents differ, LAST_SIX_ACTS.md wins (it carries the owner's decisions). The build follows the plan that built Acts
IV to IX: `docs/act9/BRIEF_FOUNDATION.md` and `docs/act9/BRIEF_PHASE2.md` are the models (Act IX is the newest; it
says what differed from Act VIII, and so on back to `docs/act5/`).

## Fixed names (do not rename)

| Act (final slot) | Folder | Stage key / `game.<key>` / rules class | Stage ids (three, in order) | Boss ids | Temporary act number |
| --- | --- | --- | --- | --- | --- |
| The Black Tide (II) | `docs/tide/` | `corsair` / `game.corsair` / `CorsairRules` | `cutter`, `galleon`, `maelstrom` | `crow`, `marrec`, `vandermere` | 10 |
| The Hall of the Slain (VI) | `docs/norse/` | `norse` / `game.norse` / `NorseRules` | `barrow_fields`, `valgard`, `vigrid` | `hrimgar`, `sigrun`, `odin` | 11 |
| The Necropolis Dynasty (VII) | `docs/dynasty/` | `dynasty` / `game.dynasty` / `DynastyRules` | `necropolis`, `lioness_temple`, `two_truths` | `anubis`, `sekhmet`, `osiris` | 12 |
| The Celestial Host (X) | `docs/host/` | `host` / `game.host` / `HostRules` | `silver_stair`, `wheel_of_thrones`, `empyrean` | `seraiel`, `throne`, `voice` | 13 |
| The Age of Titans (XIV) | `docs/titans/` | `primeval` / `game.primeval` / `PrimevalRules` | `fern_basin`, `great_plain`, `last_day` | `scarmaw`, `ironbrow`, `gravejaw` | 14 |
| The Turning Year (XV) | `docs/year/` | `wild` / `game.wild` / `WildRules` | `greenwood`, `fae_court`, `world_tree` | `stag_king`, `summer_queen`, `green_mother` | 15 |

Sprite folders: `assets/sprites/<key>/` (e.g. `corsair/`), concept art in `art_source/concepts/final5/` and
`art_source/concepts/act15/host_*` (approved by the owner's go-ahead). Kits load by name from
`scripts/enemies/<key>/`, as `scripts/enemies/concord/` does for Act IX.

## Until the reorder

- **Temporary act numbers 10–15** (table above): each new act gets its own act tab after the Concord's, in final
  relative order. The unlock chain runs Harvester → Crow → ... in that order, and an act that is not built yet shows
  "Coming soon", like Acts II–IX did. The reorder pass (last) renumbers everything from one ordered list.
- **Tune each act for its final slot**, not its temporary number: the Black Tide between the Covenant and the Sanguine
  Court (an early act: easier than the Court); the Hall of the Slain and the Dynasty at the Shogunate / Olympus level; the
  Celestial Host at or just above the Inferno; the Age of Titans above the Concord; the Turning Year the hardest act in the
  game. Use the stage difficulty data the built acts use; compare with their playtest reports in `docs/act*/playtest/`.
- **Soul Ash** keeps the per-act restart (×1 / ×1.25 / ×1.5 per stage).
- **No epilogue part and no closing card** for any act until the reorder pass writes them all together.
- **Names:** real mythology names for Egypt and the Norse act (Anubis, Sekhmet, Osiris, Ammit, Odin, Fenrir); original
  names for the Host (Seraiel, the Throne, the Voice). Every figure's sex is named in its art prompt; female figures use
  the figure-redesign style (CLAUDE.md), fully clothed. The Host uses starlight white, pale silver, cerulean and dawn rose,
  never crimson or warm gold.

## The gate every phase passes

Stages 1–27 keep their same-seed autotest summaries (`docs/act9/tools/gate.sh` is the model; extend it to the new
stages). `--import` and the touched autotests show zero `SCRIPT ERROR` / `ERROR:` / `WARNING:` lines; `stuck_units=0`.

## Process rules for every agent

- Godot is at `/home/user/tools/godot/Godot_v4.3-stable_linux.x86_64`. The machine has 4 cores and several agents run at
  once: **run at most one Godot process at a time yourself**, in the foreground, and keep runs lean (CLAUDE.md "Test
  lean"). Art and audio agents run no Godot at all; the lead's integration step imports their files.
- Work only in your own worktree on your own branch; commit there with clear messages (no model identifiers, the
  co-author lines from CLAUDE.md's commit convention). **Never push** and never touch `main`; the lead merges.
- Keep shared-file edits small and additive and put new work in new files, so merges stay clean.
- Document every variable, constant and exported field (CLAUDE.md convention 1); numbers in `scripts/data/*.gd` tagged
  `# TUNING (not in GDD)`; static typing; deterministic per seed; pooled.
- Append your GDD §15.0 rows; update README (stage list, autotest `--stage=` list) and the CLAUDE.md autotest list.
- Final report: what you built, files touched, test results (the exact commands and their summary lines), anything the
  owner must decide, anything you could not finish. Keep it under 400 words.

## Waves

1. **Wave 1 (now):** foundations of the Black Tide (with the deck shown on a screenshot for the owner), the Hall of the
   Slain and the Necropolis Dynasty; one code agent (Opus) and one art + audio agent (Sonnet) per act.
2. **Wave 1b:** the three stages of each of those acts (one Opus agent per stage), an integration merge each, then art
   review pages for the owner and bot playtest passes (Haiku runs the batches, Opus reads them).
3. **Wave 2:** the Celestial Host and the Age of Titans, the same way; **wave 3:** the Turning Year (its Last Claim phase
   replays one rule from every act, so it comes last).
4. **The reorder pass:** one ordered act list, renumbered stages and acts, the unlock chain, Part-grouped act tabs, the
   save migration, the closing cards and epilogue parts, a bot pass per moved act, CI jobs for every new stage.
