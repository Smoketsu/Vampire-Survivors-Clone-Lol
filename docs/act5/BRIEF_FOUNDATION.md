# Act V foundation (phase 1): briefs

These are the lead's briefs for the three Act V foundation agents. The three agents run at the same time, each in its
own git worktree. Before starting, each agent reads **Common** and its own section in full.

This is the same plan that built Act IV (`docs/act4/BRIEF_FOUNDATION.md`; read it, since this brief only says what
differs). After phase 1, three stage agents build the three stages on top of this work (phase 2). So make the shared
paths solid, documented and easy to extend.

## Common (every agent)

You build part of **phase 1 of Act V** of **Necropathy**, a Godot 4.3 GDScript game in the Vampire Survivors genre.
In Act V the necromancer fights **the Shogunate of the Rising Sun**:
- disciplined samurai and ashigaru by day;
- ninja in the shadows at dusk;
- the oni and yokai of the old stories at night.

The design is in `docs/act5/PROPOSAL.md` (owner-approved; read it in full). Phase 1 copies the shape of the **Act IV
foundation**. Read these too:
- GDD §15.0, the rows from "Act IV foundation (phase 1)" to "Act IV foundation review fixes";
- `docs/act4/BRIEF_FOUNDATION.md`;
- `docs/act4/HANDOFF.md` (the merge lesson: git keeps identical trailing lines once, so a dict entry can lose its
  last lines).

Follow the same structure, with `shogunate` wherever Act IV had `pantheon`.

### Read first
- `CLAUDE.md`. It wins any conflict. In particular:
  - document every variable;
  - data-driven numbers tagged `# TUNING (not in GDD)`;
  - static typing;
  - determinism;
  - one path per modifier;
  - no shader may read the screen;
  - never call `AudioServer.add_bus()`;
  - **summons never get act-only rules**;
  - co-op reads the necromancer through the bound slot.
- GDD §15.0, from "Act IV foundation (phase 1)" to the end.
- `README.md`.

### Process rules
These are exactly the Act IV ones (`docs/act4/BRIEF_FOUNDATION.md`, "Process rules"), with these changes:
- Shared-file blocks are headed `# --- Act V: the Shogunate of the Rising Sun ---`, at the END of the table or list
  they extend.
- The base commit is **`f044ab8`** (`main`, Act IV live). Build gate base logs from a clean `git worktree add` of it.
- Commit messages end with exactly these two lines:

  ```
  Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
  Claude-Session: https://claude.ai/code/session_01TjA5CNwUWb95gMazj5Z3qp
  ```

  Never mention model identifiers anywhere.
- **Do not push**; the lead merges your local branch.
- Never read, print, echo, search for or set any API key; the proxy injects it.

### Fixed names
All three agents rely on these; do not rename them.
- **Stage ids**, in order, all act 5, STAGE key `shogunate` (true):

  | Id | Stage | Boss id |
  |---|---|---|
  | `province` | Stage 13, the Burning Province | `kage` |
  | `kurogane` | Stage 14, Castle Kurogane | `shogun` |
  | `sun_road` | Stage 15, the Road to the Sun | `amaterasu` |
- **Shared enemy kinds** (ids):

  | Id | Role |
  |---|---|
  | `ashigaru` | day fodder, spear levy |
  | `samurai` | soldier, katana; its elite uses the Draw |
  | `teppo_gunner` | ranged, arquebus |
  | `ninja` | soldier, From the Shadows |
  | `onryo` | night fodder, a vengeful ghost; passes through obstacles and the ring |
  | `oni` | night heavy; also the Endless Night Reckoning's kind |

  Sprite keys are `shogunate/<id>` in `assets/sprites/shogunate/`:
  - `<id>.png`, the still;
  - `<id>_walk.png`, the walk (or glide) strip;
  - plus `<id>_idle.png` for a female in the figure-redesign style. None of the shared kinds is female; the kunoichi
    and kitsune come in phase 2.
- **Palette.** Constants in `scripts/data/palette.gd` (Agent A) and ramps in `tools/palette.json` (Agent B), exactly:

  | Ramp | Constants and values |
  |---|---|
  | lacquer | `SHOGUN_LACQUER_INK` #1A0B0C (outline), `SHOGUN_LACQUER_DARK` #6A1418, `SHOGUN_LACQUER` #B3262B, `SHOGUN_LACQUER_LIGHT` #E2594A |
  | indigo | `SHOGUN_INDIGO_DARK` #161D38, `SHOGUN_INDIGO` #2E3F74, `SHOGUN_INDIGO_LIGHT` #6A82C0 |
  | sakura | `SHOGUN_SAKURA_DARK` #A8546E, `SHOGUN_SAKURA` #E494AC, `SHOGUN_SAKURA_LIGHT` #F9D3DD |

  Steel uses the existing grey / chrome ramps. Gold stays the existing gold (evolution, chest, victory) and is also
  the sun.
- **Music** key `sun`: score `SoundData.SUN_SCORE`, title "The Setting Sun".
- **Shogunate sound ids:** `draw_flash`, `draw_cut`, `smoke_puff`, `teppo_volley`, `taiko_hit`, `lantern_lit`,
  `nightfall`, `oni_smash`.

## Agent A: the foundation code (branch `act5-foundation`, worktree `/home/user/wt/act5-foundation`)

- **Scratch dir:** `/tmp/claude-0/-home-user-Vampire-Survivors-Clone-Lol/b0031aa1-78e2-5d60-8763-4014a0c61c3c/scratchpad/act5/foundation/`.
- **CPU:** at most **2** Godot processes at once.

### Also read
- The Act IV code you copy the shape of:
  - `scripts/enemies/pantheon/` (`pantheon_rules.gd`, `pantheon_kit.gd`, `divine_wrath.gd`, `phalanx.gd`, `glory.gd`);
  - `scripts/data/pantheon_enemy_data.gd` and `pantheon_rules_data.gd`;
  - `scripts/data/stages/ilion_stage.gd`;
  - `PantheonGround`, `PantheonGlyphs`, `PantheonReport`;
  - `EnemyDirector.pantheon_def()`.
- Act III's `lock_on.gd` (the Draw is its melee cousin) and `empire_shots.gd`.
- `scripts/core/combat_resolver.gd`, `scripts/horde/horde_director.gd`.
- The stage select, the Codex files, `autotest.gd`.

### What you build

**Stages.** Three registered stub stages (`province_stage.gd`, `kurogane_stage.gd`, `sun_road_stage.gd`), act 5,
`"playable": false` ("Coming soon"). Each has:
- the unlock chain: the Province is opened by Hades (`underworld`, boss kills 1), then each stage opens the next;
- its boss id in `StageRegistry.BOSS_ARRIVALS`, with a placeholder `script` until
  `scripts/enemies/shogunate/boss_<id>.gd` exists. EnemyDirector loads a Shogunate boss by name after the Pantheon's
  folder.
- the four zone names from the proposal;
- a placeholder timeline of the shared kinds that follows the Sun's Course (night kinds only at night), so
  `--stage=<id>` runs a full autotest;
- a code-drawn placeholder floor (`ShogunateGround`: paddy mud / castle stone / shrine gravel) and a couple of
  placeholder obstacles drawn by `ShogunateGlyphs`, including a **stone lantern** obstacle kind (`stone_lantern`)
  that the Sun's Course lights at night;
- music key **`bronze` for now**, with a comment saying the lead switches it to `sun` at the merge;
- Soul Ash and enemy HP / damage placeholders a step above the Underworld's (×3.75, HP 1.5, damage 1.5). Lesson from
  Act IV: the step up goes in HP, not damage.

**Stage select.** An **Act V** tab. Five act tabs must fit at 1280 × 600 layout px, with room for a sixth. Check a
screenshot.

**Faction data and code.**
- `ShogunateEnemyData` (the shared kinds), plus one empty table per stage (`ProvinceEnemyData`, `KuroganeEnemyData`,
  `SunRoadEnemyData`), looked up by `EnemyDirector.shogunate_def()` after the Pantheon's tables.
- Kits load by name from `scripts/enemies/shogunate/<id>_kit.gd`, through a `ShogunateKit` base with the helpers
  phase 2 needs. Kit ids are unique across the Eye, Empire, Pantheon and Shogunate folders.
- Row keys:
  - `night` (bool): spawns only at night; the timeline helper enforces it;
  - `draws` (bool): can use the Draw;
  - `ambusher` (bool): enters From the Shadows;
  - `ethereal` (bool): passes through obstacles and the ring, like the onryō, through one documented path.

**The shared rule object.** `game.shogunate` (`ShogunateRules`). It is created only when the STAGE has `shogunate`
and is null on every other act: Acts I–IV never create any of it. Its numbers go in
`scripts/data/shogunate_rules_data.gd`.

**The three shared rules, one code path each:**

1. **The Sun's Course** (`SunCourse`, owned by `game.shogunate`): one path reading the run clock. It answers
   `phase()` (DAY 20:00–13:00, DUSK 13:00–7:00, NIGHT 7:00–0:00, ENDLESS_NIGHT in the Reckoning; boundaries in data,
   per-stage overrides through a STAGE key `sun` with `{}` = defaults) and `light_at(pos)`.
   - **Look.** Day is clear. Dusk shifts to orange with long shadows. At night everything beyond a **light radius**
     around the necromancer (and around each lit stone lantern, each lit for the whole night, and around spell flashes
     if cheap) goes dark.
     - Draw it as **overlay rects / a darkness texture with holes cut by light-pool sprites drawn in a blend mode**.
       **No shader may read the screen**, and no polygon may be redrawn every frame (Web GL id rule in CLAUDE.md;
       prefer textures).
     - The night must stay readable on a phone. Units in the dark are dimmed, never invisible: the darkness alpha is in
       data, about 0.55.
     - Phases blend over a few seconds on game time.
   - **Gameplay.** Light feeds the other two rules: ambush puffs are seen earlier in light, ninjas cannot appear inside
     a lit pool, and phase 2's kitsune decoys are revealed in light.
   - **Timeline.** Night-only kinds (row `night`) join at night through one helper the stage timelines use.
   - **Counter-passive hook.** Leave a documented hook for **Paper Lanterns** (a wider light radius; ambushes show
     earlier): one multiplier read in one place, default 1.0. Do not build the passive.
   - **Sound.** `nightfall` plays at the night transition.

2. **The Draw** (`DrawCuts`, owned by `game.shogunate`). Its pattern is Act III's `LockOn`.
   - A `draws` kind (the samurai's elite, later bosses) stops, and a thin white line flashes from it for 0.8 s, aimed at
     the necromancer.
   - Then one cut hits **every body on the line**, summons and the necromancer, through `CombatResolver`.
   - At most 3 lines at once, with a boss override like LockOn's. Length, width and damage go in data.
   - Warriors physically block nothing here: every body on the line is hit. The army bot steps out of the line
     (`danger_push()`-style).
   - Phase 2 reuses this path for the Shogun's iai duel (faster cuts, a triple cut), so give it a public
     `DrawCuts.draw(source, from, dir, opts)`.
   - Leave a documented hook for **Unbending** (Draw cuts hit summons for less): one multiplier, default 1.0.

3. **From the Shadows** (`ShadowAmbush`, owned by `game.shogunate`). Its pattern is the `spawn` wave events.
   - `ambusher` squads do not walk in from the edge. They appear at obstacle shadows near the necromancer (an obstacle
     within a radius, on its side away from the light), sometimes inside the Bone Ring, after a 1 s smoke puff.
   - The puff shows earlier (a longer warning) in light, and never inside a lit pool.
   - Positions are seeded and deterministic, and never inside an obstacle (`arena.gd` push-out).
   - Ambushes begin at dusk, through a timeline event type `ambush` and the trickle helper.
   - It is the one exception to "enemies walk in from the edge"; once they appear, they advance like everyone else.

**The shared kinds.** Fallback glyphs `ShogunateGlyphs` for every kind. The art agent makes the PNGs in parallel; use
them through `SpriteBank` when present.
- `ashigaru`: fodder in wide ranks.
- `samurai`: soldier; `draws` on its elite.
- `teppo_gunner`: ranged. A volley in a line every 6 s, then a long reload while still advancing. Its shots go
  through `ProjectileManager`; Line of Fire is Act III only.
- `ninja`: `ambusher`; shuriken, then dagger.
- `onryo`: night fodder; `ethereal`, drifts.
- `oni`: night heavy. An iron kanabō smash that stuns summons through `CombatResolver.stun_unit()` (the one summon
  stun path); flat armour.

**The Reckoning, the Endless Night.** The sun never rises: full night, every night kind at once (`oni` the heavy),
faster each minute. It is tunable per stage through its `RECKONING` keys, like Act IV's Twilight.

**Codex.** A **Shogunate** tab (kinds and bosses, silhouettes until met), like the Republic tab.

**Sounds.** A data map in `shogunate_rules_data.gd` (event → sound id) that **for now points at existing sounds**.
The audio agent adds the Fixed-names ids, and the lead switches the map at the merge. Leave a comment naming them.

**Autotest.**
- Options: `--stage=province|kurogane|sun_road`, `--spawn=` with the new kinds, `--boss=kage|shogun|amaterasu`.
- Summary lines (a `ShogunateReport`, only when the Shogunate ran):
  - `sun's course`: phase times, lanterns lit, ambushes revealed in light;
  - `the draw`: lines drawn, bodies cut by kind, damage to summons vs the necromancer, dodged by the bot;
  - `from the shadows`: squads, units, inside-the-ring count, average warning time;
  - `shogunate kinds`;
  - `shogunate stage`.

**Gate (required).** Stages 1–12 keep their same-seed summaries.
- Adapt `docs/act4/tools/gate.sh` into `docs/act5/tools/gate.sh`. It runs seed 7 on:
  - `graveyard`, default and `--policy=army`;
  - `harbour`, `spire`, `citadel` and `underworld`, all `--policy=army`.
- Run it on the base `f044ab8` and on your branch, and compare with `docs/act3/tools/same_seed_gate.py`.
- The only allowed diffs are catalog counts the new content adds: Codex totals, stage counts, and "stages unlocked by
  this run: province" after Hades. List them.

**Playability check.**
- `--stage=<each id> --policy=army` reaches 0:00 with zero `SCRIPT ERROR` / `ERROR:` / `WARNING:` lines and
  `stuck_units=0`.
- The summary must show all three phases, draws cutting, ambushes appearing (some inside the ring), and the night
  kinds only at night.
- The army bot must not die before 3:00 on any stub.
- Also run one clean `--mortal` default Graveyard run.

**Screenshots.** At 1280×720 under `xvfb-run` (see how Act IV did it in its scratch tools); look at them yourself:
- one day, one dusk and one night shot on a stub, with a Draw line, an ambush puff and a lit stone lantern;
- one of the Act V tab.
- Also one night shot at a phone-like small size (e.g. 844×390) to judge readability.

**Shared files you may touch:**
- everything in "Also read";
- `palette.gd` (your SHOGUN block);
- `sprite_data.gd`, only if code requires a key to exist;
- `codex_data.gd`, `unlock_data.gd` (the stage chain only), `autotest.gd` (additive);
- `README.md`, `docs/GDD.md`.

Not `sound_data.gd`, the synth files, `epilogue_data.gd` or `tools/palette.json`.

**GDD rows:** "Act V foundation (phase 1)", plus one per shared rule ("The Sun's Course", "The Draw", "From the
Shadows").

## Agent B: the art (branch `act5-art`, worktree `/home/user/wt/act5-art`)

- **Scratch dir:** `.../scratchpad/act5/art/`.
- **CPU:** at most **1** Godot process.
- **Read:** as Act IV's Agent B. The model for yours is the ART_BIBLE section "Act IV: the Olympian Republic, the
  shared kinds", including its pipeline notes: `prepare_sprite.py` straight on the source with `--ink-l 0.15` and
  explicit `--ramps`, not `pixelate_source.py`, for armour.
- **Concept art:** `art_source/concepts/act5_lineup.png` (the approved mixed lineup), `act5_boss.png` and
  `act5_stage.png`, with their prompts.

### What you make

**Ramps.** In `tools/palette.json`, the three ramps `lacquer`, `indigo` and `sakura` with exactly the Fixed-names hex
values, plus roles.

**Six sprites.** In `assets/sprites/shogunate/`, the six shared kinds, each a still plus a walk strip (a glide strip
for `onryo`), at game size. The prompt names each figure's sex.

| Kind | Size | Look |
|---|---|---|
| `ashigaru` | ~32 px fodder | male; jingasa hat, lacquer-red do, a long yari |
| `samurai` | ~50 px soldier | male; black and red lacquered armour, a kabuto with a crescent crest, a katana at the hip, the hand near the hilt; it must read as "about to draw" |
| `teppo_gunner` | ~46 px ranged | male; indigo and lacquer, an arquebus held level, a smouldering match cord |
| `ninja` | ~40 px soldier | male; indigo-black, masked, a shuriken in hand; must read on dark ground (an indigo-light rim) |
| `onryo` | ~34 px night fodder | female; a pale vengeful ghost, long black hair over the face, a white burial kimono; hovers, no feet. She is a ghost, not the figure-redesign style: no bust rig. |
| `oni` | ~80 px night heavy | male; a huge red-skinned ogre, horns, tiger-skin loincloth, an iron kanabō |

These set Act V's style for the stage agents: lacquer red and black, steel, indigo, sakura pink, gold for the sun,
and hard clean silhouettes against the undead's bone and teal.

**The stone lantern.** One obstacle sprite, `obstacles/stone_lantern` (a tōrō, ~40 px tall), in two states:
`stone_lantern.png` unlit and `stone_lantern_lit.png`, with a warm glow in the window. Agent A draws the glow pool;
you make the sprite only.

**Data and docs.**
- Your Act V block in `sprite_data.gd`, the walk / idle entries, and rigs in `walk_cycle.py`.
- An ART_BIBLE section "Act V: the Shogunate of the Rising Sun, the shared kinds", and a GDD §15.0 row "Act V art: the
  shared kinds".

**Image generation.**
- ALWAYS run `GEN_LEDGER=/home/user/wt/act5-art/docs/art/generation_ledger.csv python3 tools/gen_image.py ...` and
  commit the ledger rows.
- Budget about $0.40.
- Check every sprite with `tools/art_check.py`.
- Look at each one at game size and zoomed, next to the Act IV shared kinds and on a dark night ground.
- Make a contact sheet in your scratch dir.

**Shared files you may touch:** `tools/palette.json`, `sprite_data.gd`, `walk_data.gd` / `idle_data.gd`,
`tools/walk_cycle.py` (your rigs), `docs/art/ART_BIBLE.md`, `docs/art/generation_ledger.csv` (append only),
`docs/GDD.md` (your row). Nothing else.

## Agent C: the music and sounds (branch `act5-audio`, worktree `/home/user/wt/act5-audio`)

- **Scratch dir:** `.../scratchpad/act5/audio/`.
- **CPU:** at most **1** Godot process.
- **Read:**
  - `scripts/data/sound_data.gd` (`IRON_SCORE`, `BRONZE_SCORE`, `SCORES`, the Empire and Pantheon packs);
  - the synth files (`RunLoopSynth`, the score loop, `Sfx`, how the Pantheon pack loads lazily with its own seeds);
  - the GDD §15.0 row "Hymn of Bronze and the Pantheon sounds".

### What you make

1. **"The Setting Sun"** (`SoundData.SUN_SCORE`, key `sun` in `SCORES`): a synthesized, score-driven run loop like
   Hymn of Bronze. It needs a Japanese feel:
   - a pentatonic in or yo scale;
   - taiko drum patterns;
   - a koto-like plucked line;
   - a breathy shakuhachi-like lead;
   - a low drone.

   No sound files. **The loops of Acts I–IV and the startup bank must stay identical sample for sample**: render it as
   its own score with its own seed, lazily, like the Pantheon pack.
2. **The Shogunate sound pack** (`SoundData.SHOGUNATE_SOUNDS`, loaded lazily with the `sun` music, own seeds). Nothing
   plays these yet; the lead wires them.

   | Id | Sound |
   |---|---|
   | `draw_flash` | a thin steel ring as a blade leaves the saya |
   | `draw_cut` | a fast slicing whoosh with a sharp tail |
   | `smoke_puff` | a soft burst and hiss |
   | `teppo_volley` | a ragged crackle of matchlocks |
   | `taiko_hit` | one deep drum |
   | `lantern_lit` | a soft paper whump and flame |
   | `nightfall` | a low falling swell with a temple bell |
   | `oni_smash` | a heavy iron club impact |
3. **Tests:**
   - `--import` clean.
   - One default Graveyard autotest and one `--stage=underworld --policy=army` autotest (seed 7). Compare them with
     the same runs on base `f044ab8`; the `[autotest]` / `[metric]` lines must be identical.
   - A headless render check that the `sun` score and every pack sound render without errors.
4. **Docs:** a GDD §15.0 row "The Setting Sun and the Shogunate sounds", and README lines.

**Shared files you may touch:** `sound_data.gd`, the synth / `Sfx` files, `README.md`, `docs/GDD.md`. Nothing else.

## Final report (every agent)

Your last message covers:
- the branch and commits;
- what you built (files);
- the shared files you touched, and why;
- the extension points phase 2 must use (exact names);
- your GDD rows;
- test results: numbers and the gate diff;
- every new PNG and its cost;
- anything left open, decided on your own, or requested from the lead.
