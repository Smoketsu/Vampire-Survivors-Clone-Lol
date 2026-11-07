# Act IV foundation (phase 1): briefs

Lead's briefs for the three Act IV foundation agents, who run at the same time in their own git worktrees. Each
agent reads **Common** and its own section in full before starting. After phase 1, three stage agents build the
three stages on top of this work (phase 2), so make the shared paths solid, documented and easy to extend.

## Common (every agent)

You build part of **phase 1 of Act IV** of **Necropathy**, a Godot 4.3 GDScript game in the Vampire Survivors genre.
Act IV pits the necromancer against **the Olympian Republic**: Greek gods commanding Roman discipline. The design is
`docs/act4/PROPOSAL.md` (owner-answered; read it in full). Phase 1 copies the shape of the **Act III foundation**:
read GDD §15.0 rows "Act III foundation (phase 1)", "Line of Fire", "Lock-On", "Steel has no soul" and
`docs/act3/BRIEF_FOUNDATION.md` (how that foundation was briefed), and follow the same structure.

### Read first
1. `CLAUDE.md` (all conventions; they win any conflict). In short: document EVERY variable and constant with units
   and ranges, every script starts with a header comment; tunables only in `scripts/data/*.gd` tagged
   `# TUNING (not in GDD)` (or `# GDD §N`); static typing; determinism per seed (no wall clock, instance ids or
   unseeded RNG); one path per modifier; pooling with `generation` checks; no physics engine; autotest friendly
   (headless, no `user://` without `--meta-save`); the UI rules; **no shader may read the screen**; **never call
   `AudioServer.add_bus()`**; **summons never get act-only rules** (the act's rules act on enemies, hazards and shots,
   never by changing how a summon class works in one act); co-op: gameplay reads the necromancer through the bound
   slot and stays deterministic across machines.
2. `docs/GDD.md` §15.0, the rows from "Act III foundation (phase 1)" to the end of the table.
3. `README.md` (architecture tree, autotest options).

### Process rules
- Work only in your worktree, on your local branch (named in your section). Commit in sensible steps. **Do not push
  anything** (the lead merges your local branch). Never touch `main`, `integration` or another agent's branch.
- Commit messages via `git commit -F <file>`, ending with exactly these two lines:
  `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`
  `Claude-Session: https://claude.ai/code/session_01TjA5CNwUWb95gMazj5Z3qp`
  Never mention model identifiers anywhere.
- Godot binary: `/home/user/tools/godot/Godot_v4.3-stable_linux.x86_64`. Run `--headless --path <worktree> --import`
  once first (a fresh worktree has no import cache). Autotest: `--headless --path <worktree> --fixed-fps 60
  --quit-after 15000 -- --autotest [options]`. **CPU budget** (4 cores shared by three agents): your limit on parallel
  Godot processes is in your section; never exceed it.
- Logs, screenshots and scratch files go under your scratch dir (in your section), never in the repo.
- Shared files: keep edits small, additive and in a block headed with a comment naming Act IV (e.g.
  `# --- Act IV: the Olympian Republic ---`), at the END of the table or list it extends. Never reorder or reformat
  existing lines. Only touch the shared files your section allows; anything else, write in your final report as a
  request to the lead.
- Docs: your own GDD §15.0 row(s) at the end of the table (just before `### 15.1`), README lines for what you add,
  ART_BIBLE rows for new art. Leave CLAUDE.md to the lead.

### Fixed names (all three agents rely on these; do not rename)
- Stage ids, in order: `ilion` (Stage 10, the Shores of Ilion), `olympus` (Stage 11, Mount Olympus),
  `underworld` (Stage 12, the Asphodel Underworld). Act 4. STAGE key `pantheon` (true). Boss ids `achilles`, `zeus`,
  `hades`.
- Shared enemy kinds (ids): `shade_of_dead` (Shade of the Dead), `hoplite`, `hero`, `bronze_titan` (the Reckoning's
  Bronze Titan). Sprite keys `pantheon/<id>` in `assets/sprites/pantheon/` (`<id>.png` still, `<id>_walk.png` strip,
  plus `<id>_idle.png` for a figure-redesign female).
- Palette constants in `scripts/data/palette.gd` (owned by the foundation agent) and ramps in `tools/palette.json`
  (owned by the art agent), with exactly these values:
  - bronze: `PANTHEON_BRONZE_INK` #1E1408 (outline), `PANTHEON_BRONZE_DARK` #6B4423, `PANTHEON_BRONZE` #A8702E,
    `PANTHEON_BRONZE_LIGHT` #E0A955;
  - marble: `PANTHEON_MARBLE_DARK` #8E8A86, `PANTHEON_MARBLE` #CFCBC4, `PANTHEON_MARBLE_LIGHT` #F4F1EA;
  - aegean: `PANTHEON_AEGEAN_DARK` #123E66, `PANTHEON_AEGEAN` #2C77B8, `PANTHEON_AEGEAN_LIGHT` #6FB6E8.
  Gold stays the existing gold (evolution / chest / victory meaning, and Glory).
- Music key `bronze` (score `SoundData.BRONZE_SCORE`). Pantheon sound ids: `wrath_wave`, `wrath_thunder`,
  `wrath_fissure`, `shield_lock`, `shield_break`, `glory_gain`, `hoplite_step`, `titan_rise`.

## Agent A: the foundation code (branch `act4-foundation`, worktree `/home/user/wt/act4-foundation`)

Scratch dir: `/tmp/claude-0/-home-user-Vampire-Survivors-Clone-Lol/b0031aa1-78e2-5d60-8763-4014a0c61c3c/scratchpad/act4/foundation/`.
CPU: at most **2** Godot processes at once.

### Also read
`scripts/data/stage_registry.gd`, `scripts/data/stages/*_stage.gd` (closely: `wastes_stage.gd`, `citadel_stage.gd`),
`scripts/enemies/enemy_director.gd` (`empire_def()`, `eye_def()`, kit and boss loading by name), `scripts/enemies/enemy.gd`
(`leaves_corpse()`), the Empire folder `scripts/enemies/empire/` (`empire_kit.gd`, `empire_rules.gd`, `lock_on.gd`,
`empire_shots.gd`), `scripts/data/empire_enemy_data.gd`, `empire_rules_data.gd`, `scripts/core/combat_resolver.gd`,
`scripts/horde/horde_director.gd` (`raise_corpse()`, `spawn_temporary()`, `add_suppression()`), `TerrainSlow`,
`scripts/ui/stage_select.gd`, `scripts/ui/codex_*.gd`, the `EmpireReport` and `autotest.gd`.

### What you build
**Stages.** Three registered stub stages (`scripts/data/stages/ilion_stage.gd`, `olympus_stage.gd`,
`underworld_stage.gd`), act 4, `"playable": false` ("Coming soon"), each with: the unlock chain (Ilion opened by
Deus Ex Machina, then each stage opens the next); its boss id in `StageRegistry.BOSS_ARRIVALS` with a placeholder
`script` (an existing boss, as Act III did) until `scripts/enemies/pantheon/boss_<id>.gd` exists (EnemyDirector loads a
Pantheon boss by name after the Empire's folder); four zone names from the proposal; a placeholder timeline of the
shared kinds so `--stage=<id>` runs a full autotest; a simple code-drawn placeholder floor (a `PantheonGround` like
`EmpireGround`: sand / marble / asphodel ash) and a couple of placeholder obstacles drawn by `PantheonGlyphs`;
music key **`iron` for now** (the audio agent adds `bronze`; the lead switches it at the merge: leave a comment);
Soul Ash multiplier and enemy HP / damage scaling placeholders a step above the Iron Citadel's.

**Stage select.** An **Act IV** tab (`StageRegistry.ACTS[4]`). The tab row must still fit at 1280 × 600 layout px
with room for six act tabs later (shorter tabs if needed); check a screenshot.

**Faction data and code.** `PantheonEnemyData` (shared kinds) plus one empty table per stage (`IlionEnemyData`,
`OlympusEnemyData`, `UnderworldEnemyData`), looked up by a `EnemyDirector.pantheon_def()` after the Empire's tables;
kits load by name from `scripts/enemies/pantheon/<id>_kit.gd` (a `PantheonKit` base with the helpers phase 2 needs).
Row keys: `bronze` (bool: bronze-clad, draws Zeus's lightning), `phalanx` (bool: can lock shields), `hero` (bool:
carries Glory), `facing` handled by the kit. Kit ids must be unique across the Eye, Empire and Pantheon folders.

**The shared rule object.** `game.pantheon` (`PantheonRules`), created only when the STAGE has `pantheon`; null on
every other act (Acts I–III never create any of it). Numbers in `scripts/data/pantheon_rules_data.gd`.

**The three shared rules, one code path each:**
1. **Wrath of the Gods** (`DivineWrath`, owned by `game.pantheon`): one scheduler, the stage's STAGE key `wrath`
   picks the hazard kind and its numbers (`{}` = defaults), telegraphed, hitting **both armies** through
   `CombatResolver` (enemies, summons and the necromancer). Build all three kinds now, one per stub stage, since phase 2
   and the Reckoning use them:
   - `waves` (Ilion): a wall of water from one edge every 90 s, a 3 s foam-line telegraph, pushes everyone it crosses
     about 140 px, drowns fodder. Pushes go through the one ground path (`TerrainSlow` or its push) or a documented
     single push path; units must never end inside obstacles (`arena.gd` push-out); the Bone Ring re-forms.
   - `lightning` (Olympus): bolts on marked circles with a 1.2 s warning; a strike chains to `bronze` enemies nearby
     (chain count and range in data).
   - `fissures` (Underworld): red telegraph lines that open into cracks, burn whoever stands on them, **swallow
     corpses** (no corpse or raise on them: gate it inside the one raise path `HordeDirector.raise_corpse()` /
     `Enemy.leaves_corpse()`, not a second gate), and spit `shade_of_dead` for a few seconds.
   Leave a documented hook for the counter-passive **Grounded Bones** (less lightning and wave damage to the army):
   one multiplier read in one place, default 1.0; do not build the passive.
2. **Phalanx.** `phalanx` kinds standing shoulder to shoulder (3+ within 28 px, facing the same way: data) lock
   shields: hits **from the front** by projectiles, volleys and spell projectiles are stopped or heavily reduced and
   cause no knockback; the locked wall advances as one (shared pace); hits from the side or behind deal full damage and
   break the lock for a moment; arcing hits (catapult boulders, anything marked arcing) and area / stomp damage ignore
   the front. Put the direction test in ONE helper (e.g. `PantheonRules.hit_from_front(enemy, origin)`) because
   phase 2 reuses it for Achilles' heel and the Legionary's testudo, and apply it once in
   `CombatResolver.damage_enemy()` (which needs the hit's origin: find the cleanest way the existing callers can pass
   it, defaulting to "no direction" = full damage). Leave a documented hook for **Bronze Breaker** (summon hits on
   shielded fronts deal more): one multiplier, default 1.0. Draw the locked state clearly (a bronze shield line).
3. **Glory.** `hero` kinds gain a Glory stack when they kill a summon (hook the kill in `CombatResolver`): +10% damage
   and +10% size per stack, cap 10, a growing gold aura; killed at 5+ stacks they drop a chest (through `ChestManager`)
   and a Soul Ash bounty that grows with the stacks (through the existing Soul Ash path). Named variants (Ajax,
   Hector, Atalanta) as display names in data.

**The shared kinds** (fodder `shade_of_dead`: fast, weak, swarms, pale; soldier `hoplite`: spear and round shield,
`phalanx`, `bronze`; elite `hero`: `hero`, `bronze`, a strong melee demigod; the Reckoning's `bronze_titan`: a slow
huge bronze heavy). Fallback glyphs `PantheonGlyphs` for every kind (the art agent makes the PNGs in parallel at
`pantheon/<id>`; your code must use them when present through the normal `SpriteBank` path and fall back to glyphs).

**Reckoning, the Twilight of the Gods** (shared, like the Purge Protocol): at 0:00 the stage's wrath plus the other two
kinds fire together and faster each minute, while `bronze_titan`s step out of the ground. Tunable per stage through
its `RECKONING` keys.

**Codex.** An **Olympian Republic** tab (kinds and bosses; silhouettes until met), like the Empire tab.

**Sounds.** Call sounds through a data map in `pantheon_rules_data.gd` (event → sound id) that **for now points at
existing sounds**; the audio agent adds the `wrath_*` / `shield_*` / `glory_gain` / ... ids and the lead switches the
map at the merge. Leave a comment naming the intended ids (Fixed names above).

**Autotest.** `--stage=ilion|olympus|underworld`, `--spawn=` with the new kinds, `--boss=achilles|zeus|hades`.
Summary lines (a `PantheonReport`, only when the Pantheon ran): `divine wrath` (strikes by kind, damage to enemies vs
summons vs player, fodder drowned, corpses swallowed, lightning chains), `phalanx` (locks formed, front hits stopped,
flank breaks), `glory` (stacks gained, peak stacks, heroes killed by stacks, chests and bounty paid), `pantheon kinds`,
`pantheon stage`. The army bot steps out of telegraphs the way it does for Act III (`danger_push()`-style), so it
doesn't stand in every wave.

**Gate (required).** Stages 1–9 keep their same-seed summaries. Base: commit `7ab1c74` (build the base logs from a
clean `git worktree add` of that commit). Adapt `docs/act3/tools/gate.sh` into `docs/act4/tools/gate.sh` that runs
seed 7 on `graveyard` (default and `--policy=army`), `harbour` and `spire` (army) and `citadel` (army), and diff the
`[autotest]` / `[metric]` lines. The only allowed diffs are catalog counts the new content adds (Codex totals,
stage counts, "stages unlocked by this run: ilion" after Deus Ex Machina). List them.

**Playability check.** `--stage=<each id> --policy=army` reaches 0:00 with zero `SCRIPT ERROR` / `ERROR:` /
`WARNING:` lines and `stuck_units=0`, and the summary shows every wrath kind striking, phalanx locks forming and
breaking, Glory stacks gained and paid out. Don't balance; just make sure it isn't broken (the army bot should not
die before 3:00 on any stub). Also one `--mortal` default Graveyard run clean.

**Screenshot.** One 1280×720 screenshot per stub under xvfb (`xvfb-run`; you may need a small helper scene or the
autotest with a capture flag, look at how earlier phases did it in `tools/` or write a tiny one in your scratch dir):
a wrath telegraph, a locked phalanx, a Hero with Glory. Look at them yourself. Plus one of the stage select's Act IV
tab.

**Shared files you may touch:** everything listed in "Also read" above, `palette.gd` (your PANTHEON block),
`sprite_data.gd` **only** if code requires a key to exist (prefer the art agent's entries; say so in your report),
`codex_data.gd`, `unlock_data.gd` (only the stage unlock chain if it lives there), `autotest.gd` (additive flags),
`README.md`, `docs/GDD.md`. Not `sound_data.gd`, `sfx` / synth files, `epilogue_data.gd` or `tools/palette.json`.

**GDD rows:** "Act IV foundation (phase 1)" plus one per shared rule ("Wrath of the Gods", "Phalanx", "Glory").

## Agent B: the art (branch `act4-art`, worktree `/home/user/wt/act4-art`)

Scratch dir: `.../scratchpad/act4/art/` (same scratchpad root as above). CPU: at most **1** Godot process (only for
`--import` checks).

### Also read
`docs/art/ART_BIBLE.md` (all of it; the section "Act III: the Electronic Empire, the shared kinds" is the model for
yours), `docs/act3/ART_PIPELINE_NOTES.md`, `tools/gen_image.py`, `prepare_sprite.py`, `pixelate_source.py`,
`walk_cycle.py`, `art_check.py`, `tools/palette.json`, `scripts/data/sprite_data.gd`, `walk_data.gd`, `idle_data.gd`.
The concept art `art_source/concepts/act4_lineup.png` (the approved mixed lineup: hoplite, legionary, wolf, centaur,
Amazon, Medusa, Cyclops, Achilles), `act4_boss.png` and `act4_stage.png`, prompts beside them.

### What you make
- `tools/palette.json`: the three ramps `bronze`, `marble`, `aegean` with exactly the hex values in Fixed names (plus
  roles), so `pixel_palette.py` / `prepare_sprite.py` lock sprites to them.
- Sprites in `assets/sprites/pantheon/` for the four shared kinds, each a still and a walk (or glide / hover) strip
  made with the pipeline, at game size:
  - `shade_of_dead`: fodder (~30 px), a pale, wispy fleeing ghost of a Greek dead soul (marble greys, aegean-pale
    glow; must read against the dark ground and NOT look like the undead's soul-teal); glides, no feet.
  - `hoplite`: soldier (~50 px), male, bronze Corinthian helmet with a crest, a big round bronze shield (aspis) held
    forward, spear; the shield must read clearly because Phalanx is about its front.
  - `hero`: elite (~58 px), male demigod (a Hector-like champion), bronze and gold, a cloak in Aegean blue, plumed
    helmet; looks grander than the hoplite.
  - `bronze_titan`: Reckoning heavy (~96 px), a huge walking bronze colossus stepping out of the ground, marble and
    bronze, glowing eyes.
  These four set Act IV's style for the stage agents: bronze, marble, Aegean blue and gold, hard clean silhouettes
  against the undead's bone and teal.
- Their `sprite_data.gd` height rows (your Act IV block), `walk_data.gd` (and anything else the walk strips need)
  entries, ART_BIBLE section "Act IV: the Olympian Republic, the shared kinds" and a GDD §15.0 row "Act IV art: the
  shared kinds".
- Image generation: ALWAYS run `GEN_LEDGER=/home/user/wt/act4-art/docs/art/generation_ledger.csv python3
  tools/gen_image.py ...` (absolute path) and commit the ledger rows. **Never read, print, echo, search for or set any
  API key or OPENAI_API_KEY**; the proxy injects the key. Budget about $0.40.
- Owner art notes: details big enough to read at game size, no busy specks; faces read clearly; thin lattices don't
  survive conversion; flyers / ghosts hover (a bob), they don't walk; the prompt must name each figure's sex (the
  figure-redesign instruction spread to every figure in the first concept lineups).
- Check every sprite with `tools/art_check.py` and look at each one yourself, at game size and zoomed, next to the
  Act III shared kinds. Make a contact sheet PNG in your scratch dir.

**Shared files you may touch:** `tools/palette.json`, `sprite_data.gd`, `walk_data.gd` / `idle_data.gd` (Act IV
block), `docs/art/ART_BIBLE.md`, `docs/art/generation_ledger.csv` (append only), `docs/GDD.md` (your row). Not
`palette.gd` (Agent A owns it) or any `.gd` outside `scripts/data/`.

## Agent C: the music, sounds and the closing card (branch `act4-audio`, worktree `/home/user/wt/act4-audio`)

Scratch dir: `.../scratchpad/act4/audio/`. CPU: at most **1** Godot process.

### Also read
`scripts/data/sound_data.gd` (`TIDE_SCORE`, `IRON_SCORE`, `SCORES`, `EMPIRE_SOUNDS`), the synth files
(`RunLoopSynth`, the ScoreLoop, `Sfx`, how the Empire sound pack loads lazily with its own seeds),
`scripts/data/epilogue_data.gd` and the epilogue screen (`EpilogueScreen`), GDD §15.0 rows on "Below the Tide",
"Iron Requiem", the Act III epilogue and "The Act II closing card stays the knights".

### What you make
1. **"Hymn of Bronze"** (`SoundData.BRONZE_SCORE`, key `bronze` in `SCORES`): a synthesized, score-driven run loop
   like the Iron Requiem: a martial, ancient feel (a low drone, a war drum pulse, a plucked lyre-like arpeggio in a
   Dorian or Phrygian mode, a brassy horn swell). No sound files. **The Act I, II and III loops and the startup bank
   must stay identical sample for sample**: render it as its own score with its own seed, lazily like the Empire pack.
2. **The Pantheon sound pack** (`SoundData.PANTHEON_SOUNDS`, loaded lazily when the `bronze` music is asked for, own
   seeds): `wrath_wave` (a rolling surf crash), `wrath_thunder` (a sharp thunder crack), `wrath_fissure` (a grinding
   rock split with a low hiss), `shield_lock` (bronze shields clanging into place), `shield_break` (a bronze clang and
   scrape), `glory_gain` (a short bright brass chime), `hoplite_step` (a heavy armoured step), `titan_rise` (a deep
   bronze groan). Nothing else plays them yet (the foundation agent maps them; the lead wires it).
3. **Closing cards, one per act** (owner: "tie everything together nicely"; `docs/act4/PROPOSAL.md` "Closing cards").
   Turn `EpilogueData.CLOSING` into one card per act, each with its `after` key, keeping Act II's card ("The Beacons
   Burn", the knights panel) exactly as it is and shown exactly when it is shown today. Add the card after Act III:
   **"The River Runs Dry"**, its line from the proposal, tag "To be continued.", shown after the Act III part once that
   part is open. Its panel: one image made with the pipeline (ART_BIBLE "Epilogue panels", `tools/gen_image.py` then
   `tools/epilogue_panel.py`; `art_source/epilogue/close_act3.png`, prompt beside it): far below the world, a dry
   riverbed of the dead in grey underworld light, an empty ferry boat beached on cracked mud, a lone ferryman's lamp;
   high above, on a marble mountain in golden light, the silhouettes of gods watching. It names the next enemy
   without showing it clearly. ALWAYS `GEN_LEDGER=/home/user/wt/act4-audio/docs/art/generation_ledger.csv python3
   tools/gen_image.py ...` (absolute path), commit the ledger row; **never read, print, echo, search for or set any
   API key**. Budget about $0.10. Look at the panel at game size. Check the epilogue screen still works headless (and
   `--victory-preview` or whatever previews the epilogue, if one exists) and take one 1280×720 screenshot of the new
   card under `xvfb-run`.
4. Tests: `--import` clean; one default Graveyard autotest and one `--stage=citadel --policy=army` autotest (seed 7),
   compared with the same runs on base `7ab1c74` (a clean `git worktree add` in your scratch dir): `[autotest]` /
   `[metric]` lines identical. A headless render check that the `bronze` score and every pack sound render without
   errors (a tiny script in your scratch dir is fine).
5. Docs: GDD §15.0 rows "Hymn of Bronze and the Pantheon sounds" and "Closing cards, one per act"; README lines;
   ART_BIBLE row for the panel.

**Shared files you may touch:** `sound_data.gd`, the synth / `Sfx` files, `epilogue_data.gd`, the epilogue screen,
`docs/art/*`, `README.md`, `docs/GDD.md`. Nothing else.

## Final report (every agent)
Your last message: branch and commits; what you built (files); shared files touched and why; the extension points
phase 2 must use (exact names); GDD rows; test results (numbers, gate diff); every new PNG and its cost; anything left
open, decided on your own, or requested from the lead.
