# Act VI foundation (phase 1): briefs

These are the lead's briefs for the three Act VI foundation agents, who run at the same time in their own git worktrees.
Each agent reads **Common** and its own section in full before starting.

This is the plan that built Acts IV and V. `docs/act5/BRIEF_FOUNDATION.md` is the closest model; read it. This brief
only says what differs, with `inferno` wherever Act V had `shogunate`. After phase 1, three stage agents build the three
stages on this work, so make the shared paths solid, documented and easy to extend.

## Common (every agent)

You build part of **phase 1 of Act VI** of **Necropathy**, a Godot 4.3 GDScript game in the Vampire Survivors genre. Act
VI is **the Inferno**: hell comes to collect the souls the necromancer raised, and its demons fight for them.

The design is `docs/act6/PROPOSAL.md` (owner-approved; read it in full, including the owner's decisions at its top).
**No epilogue part and no closing card** for this act: the owner holds those until the act order is settled.

### Read first
1. `CLAUDE.md`. It wins any conflict. In particular:
   - document every variable;
   - tunables only in `scripts/data/*.gd`, tagged `# TUNING (not in GDD)`;
   - static typing and determinism;
   - one path per modifier;
   - no shader may read the screen, and prefer textures over polygons redrawn every frame;
   - never call `AudioServer.add_bus()`;
   - **summons never get act-only rules**: the act's rules act on enemies, hazards and the ground. Charming a summon is an
     enemy effect on a unit, like Act II's Claims, not a summon rule;
   - co-op reads the necromancer through the bound slot.
2. `docs/GDD.md` §15.0: the Act V rows ("Act V foundation (phase 1)" to "Act V goes live") and "Act VI and the act order".
3. `README.md`, and `docs/act5/BRIEF_FOUNDATION.md`.

### Process rules
- As in Act V. Shared-file blocks are headed `# --- Act VI: the Inferno ---` and go at the END of what they extend.
- **Base commit: `7079925`.** Build the gate base logs from a clean `git worktree add` of it.
- Lesson from the Act IV merge: git keeps identical trailing lines only once. End each dict entry or `match` arm you add
  with a line unique to it, such as a comment naming the kind.
- Commit messages end with exactly:

  ```
  Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
  Claude-Session: https://claude.ai/code/session_01TjA5CNwUWb95gMazj5Z3qp
  ```

  Never mention model identifiers.
- **Do not push**; the lead merges your local branch.
- Never read, print, echo, search for or set any API key.

### Fixed names
All three agents rely on these; do not rename them.

- **Stages.** Act 6, STAGE key `inferno` (true):

  | Stage id | Stage | Boss id |
  |---|---|---|
  | `burning_gate` | Stage 16, the Burning Gate | `moloch` |
  | `silk_palace` | Stage 17, the Palace of Silk and Ash | `lilith` |
  | `pandemonium` | Stage 18, Pandemonium | `morning_star` |

- **Shared enemy kinds:**

  | Kind id | Role |
  |---|---|
  | `damned` | fodder: chained wailing souls; they burn in pits too |
  | `imp` | fodder flier: pitchfork; flies over pits |
  | `hell_knight` | soldier: burning greatsword, ember armour |
  | `succubus` | elite, female, at the approved Act VI style: charms summons (Temptation); flies |
  | `demon_brute` | heavy, four arms, a ground slam, flat armour; also the Reckoning's heavy |

  Sprite keys are `inferno/<id>` in `assets/sprites/inferno/`: `<id>.png`, `<id>_walk.png` (a glide or hover strip for
  fliers), and `<id>_idle.png` for a figure-style female.
- **A demon-portal structure kind:** `demon_portal`. Sprite `inferno/demon_portal`, with a looping glow drawn in code.
- **Palette.** Constants in `scripts/data/palette.gd` (Agent A); ramps in `tools/palette.json` (Agent B), exactly:

  | Ramp | Constants and values |
  |---|---|
  | obsidian | `INFERNO_OBSIDIAN_INK` #0B0A10 (outline), `INFERNO_OBSIDIAN_DARK` #1E1A26, `INFERNO_OBSIDIAN` #352E40, `INFERNO_OBSIDIAN_LIGHT` #5A5068 |
  | lava | `INFERNO_LAVA_DARK` #8A2A08, `INFERNO_LAVA` #E0601A, `INFERNO_LAVA_LIGHT` #FFB347 |
  | demon (skin) | `INFERNO_DEMON_DARK` #5C1A3A, `INFERNO_DEMON` #9B2D5E, `INFERNO_DEMON_LIGHT` #D45C8A |
  | charm | `INFERNO_CHARM` #FF6FB5, `INFERNO_CHARM_LIGHT` #FFB8DD (the act's signature colour: Temptation) |

  Gold keeps its meaning (evolution, chest, victory).
- **Music** key `brimstone`, score `SoundData.BRIMSTONE_SCORE`, title "Hymn of the Pit".
- **Inferno sound ids:** `pit_open`, `pit_burn`, `portal_open`, `portal_seal`, `charm_kiss`, `charm_break`, `imp_cackle`,
  `brute_slam`.

## Agent A: the foundation code (branch `act6-foundation`, worktree `/home/user/wt/act6-foundation`)

- **Scratch dir:** `/tmp/claude-0/-home-user-Vampire-Survivors-Clone-Lol/b0031aa1-78e2-5d60-8763-4014a0c61c3c/scratchpad/act6/foundation/`.
- **CPU:** at most **2** Godot processes at once.

### Also read
- The Act V code you copy the shape of:
  - `scripts/enemies/shogunate/` (`shogunate_rules.gd`, `sun_course.gd`, `draw_cuts.gd`, `shadow_ambush.gd`, `shogunate_kit.gd`);
  - `shogunate_enemy_data.gd`, `shogunate_rules_data.gd`, `province_stage.gd`;
  - `ShogunateGround`, `ShogunateGlyphs`, `ShogunateReport`;
  - `EnemyDirector.shogunate_def()`.
- Act II's Claims (`HordeDirector.claim_fallen()`, `EyeClaims`, `game.claims`) and the summon hooks `compel()` /
  `misdirect()` / `held_until`: Temptation is built on that pattern.
- Act III's furnace channels and `TerrainSlow`: the Hell Pits are one ground path like them.
- `CombatResolver`, the horde director, the stage select, the Codex, `autotest.gd`.

### What you build

**Stages.** Three registered stub stages (`burning_gate_stage.gd`, `silk_palace_stage.gd`, `pandemonium_stage.gd`), act
6, `"playable": false`. Each has:
- its place in the unlock chain: the Burning Gate opens on Amaterasu (`sun_road`, boss kills 1), then each stage opens the
  next;
- its boss id in `StageRegistry.BOSS_ARRIVALS`, with a placeholder `script` until `scripts/enemies/inferno/boss_<id>.gd`
  exists. EnemyDirector loads an Inferno boss by name after the Shogunate's folder.
- the four zone names from the proposal;
- a placeholder timeline of the shared kinds;
- a code-drawn placeholder floor (`InfernoGround`: ash plain, velvet and marble, obsidian city) and placeholder obstacles
  (`InfernoGlyphs`);
- music key `sun` for now, with a comment saying the lead switches it to `brimstone` at the merge;
- Soul Ash ×1 / ×1.25 / ×1.5 (the per-act rule);
- enemy HP / damage a step above the Road to the Sun's (HP 1.65, damage 1.5). The step goes in HP.

**Stage select.** An **Act VI** tab. Six act tabs must fit at 1280 × 600 layout px. Check a screenshot.

**Faction data.**
- `InfernoEnemyData` (the shared kinds), plus empty per-stage tables `BurningGateEnemyData`, `SilkPalaceEnemyData`,
  `PandemoniumEnemyData`, looked up by `EnemyDirector.inferno_def()` after the Shogunate's.
- Kits by name from `scripts/enemies/inferno/<id>_kit.gd`, through an `InfernoKit` base. Kit ids are unique across all
  faction folders.
- Row keys:
  - `demon` (bool): immune to the Hell Pits;
  - `flier` (bool): crosses pits and obstacles, drawn hovering;
  - `charmer` (bool): uses Temptation;
  - `damned` (bool): burns in pits, dragged in by demons.

**The shared rule object.** `game.inferno` (`InfernoRules`). It is created only when the STAGE has `inferno` and is null
on Acts I–V, so stages 1–15 keep their same-seed summaries. Its numbers go in `scripts/data/inferno_rules_data.gd`.

**The three shared rules, one code path each:**

1. **Hell Pits** (`HellPits`, owned by `game.inferno`). Burning pools on the ground that damage anyone standing in them,
   demons excepted: the necromancer, summons, the damned, the living.
   - Some are fixed per zone; some open on a telegraph (a glowing rim for 1.5 s) and close again.
   - Damage goes through `CombatResolver` on a tick.
   - Draw them as textures (no polygons redrawn every frame).
   - The army's ring flows around them: the formation avoids pit cells the way it avoids obstacles. Use one documented
     avoid check the horde reads; it is not a summon rule.
   - A STAGE key `pits` overrides the numbers (`{}` = defaults).
   - A public `HellPits.open_pit(at, radius, life, opts)` for phase 2: the Lilim Witch, Moloch and the Brimstone spell.
   - The counter-passive hook **Salt Circle**: one multiplier on pit damage to summons, default 1.0. Do not build the
     passive.
2. **Portals** (`DemonPortals`, owned by `game.inferno`). `demon_portal` structures that pour out a squad every few seconds
   from the stage's portal table.
   - They can be destroyed by damage.
   - They can be **sealed**: the necromancer (either one, in co-op) stands inside a portal's ring for 3 s. That closes it
     at once and pays a Soul Ash bounty through the existing bounty path.
   - Draw a sealing progress ring.
   - Spawn positions are seeded. Phase 2 places portals through a timeline event type `portal`, plus `DemonPortals.open(at, opts)`.
   - **The army bot must learn to seal**: walk into a ring when its army holds and it is safe. Keep this to one bot
     behaviour, `danger_push()`-style.
3. **Temptation** (`HordeDirector.charm()`, on the Claims pattern). A `charmer` kind charms a summon:
   - a charmed summon shows pink hearts and **fights for hell for 6 s**, then comes back;
   - at most **3** charmed at once;
   - killing the charmer breaks its charms;
   - the necromancer can't be charmed;
   - a charmed summon attacks summons and the necromancer through the normal combat paths, and it is a valid target for
     the army.

   One path: `HordeDirector.charm(unit, by, duration)` and `break_charms(by)`. The counter-passive hook **Faithless** is
   one multiplier on the charm duration, default 1.0; do not build the passive. In co-op, a charmed summon belongs to its
   owner's slot.

**The shared kinds.** Fallback glyphs `InfernoGlyphs` for every kind. The art agent makes the PNGs; use them through
`SpriteBank` when present.

**The Reckoning, the Last Judgment.** At 0:00 every portal opens at once and pits open faster each minute, while
`demon_brute`s step out. **The Adversary's hand** reaches up through the floor: a telegraphed grab every few seconds that
hits what is under it. It is tunable per stage through its `RECKONING` keys.

**Codex.** An **Inferno** tab.

**Sounds.** A data map in `inferno_rules_data.gd` that points at existing sounds for now; the intended ids go in comments.

**Autotest.**
- `--stage=burning_gate|silk_palace|pandemonium`, `--spawn=` with the new kinds, `--boss=moloch|lilith|morning_star`.
- An `InfernoReport` with these lines:
  - `hell pits`: pits opened, damage to summons / necromancer / enemies, the damned burned;
  - `portals`: opened, destroyed, sealed (with bounties), squads poured;
  - `temptation`: charms, peak charmed at once, broken by the charmer's death, damage done by charmed summons;
  - `inferno kinds`;
  - `inferno stage`.

**Gate (required).** Stages 1–15 keep their same-seed summaries.
- Copy `docs/act5/tools/gate.sh` to `docs/act6/tools/gate.sh` and add `sun_road` (army).
- Run it on base `7079925` and on your branch.
- The only allowed diffs are catalog counts and "stages unlocked by this run: burning_gate" after Amaterasu. List them.

**Playability.**
- On each stub, `--policy=army --mortal` reaches 0:00 with zero `SCRIPT ERROR` / `ERROR:` / `WARNING:` lines and
  `stuck_units=0`. The summary must show pits, portals (some sealed by the bot) and charms.
- One clean default Graveyard run, one `--mortal` run and one co-op bot run on a stub.

**Screenshots.** 1280×720 under xvfb: pits with a telegraph, a portal being sealed, a charmed summon, and the Act VI tab.
Look at them yourself.

**Shared files you may touch:**
- what "Also read" lists;
- `palette.gd` (your INFERNO block);
- `codex_data.gd`, `unlock_data.gd` (the chain), `autotest.gd`;
- `README.md`, `docs/GDD.md`.

Not `sound_data.gd`, the synth files or `tools/palette.json`.

**GDD rows:** "Act VI foundation (phase 1)", plus one per rule ("Hell Pits", "Portals", "Temptation").

## Agent B: the art (branch `act6-art`, worktree `/home/user/wt/act6-art`)

- **Scratch dir:** `.../scratchpad/act6/art/`.
- **CPU:** at most 1 Godot process.
- **Read:**
  - as Act V's Agent B;
  - the ART_BIBLE Act V shared-kinds section, as the model;
  - the concept art `art_source/concepts/act6_units.png` (**the approved target**: owner "perfect"), `act6_lineup.png`,
    `act6_boss.png`, `act6_stage.png`, and the prompts beside them.

### What you make
- **Ramps.** `tools/palette.json`: the ramps `obsidian`, `lava`, `demon`, `charm`, with exactly the Fixed-names hex values
  and roles. Add an `inferno` folder to `prepare_sprite.py`'s `FACTION_RAMPS`.
- **Sprites.** The five shared kinds, each a still plus a walk strip (hover strips for the imp and the succubus), at game
  size:

  | Kind | Size | Description |
  |---|---|---|
  | `damned` | ~30 px fodder, male | a wailing grey soul in chains |
  | `imp` | ~26 px | a small winged red imp with a pitchfork |
  | `hell_knight` | ~52 px soldier, male | obsidian armour with ember cracks, a burning greatsword |
  | `succubus` | ~48 px elite, **female** | bat wings, horns, a tail |
  | `demon_brute` | ~84 px heavy, male | four arms, demon skin, horns |

  The succubus is drawn at the approved `act6_units.png` level:
  - the most exaggerated hourglass figure in the game;
  - a sultry pose;
  - a lingerie-styled corset, a bare back, shoulders, midriff and thighs;
  - stockings and thigh-high boots;
  - **chest and hips always covered**, no nudity.

  Give her a `bust` rig, the hip-swaying walk the owner liked on the Amazon (`bust_axis="x"` hip box plus `swish`), and an
  idle strip.
- **The portal.** A demon-portal structure sprite, `inferno/demon_portal` (~64 px): a ring of obsidian and lava with a
  charm-pink swirl.
- **Data and docs.** Your Act VI block in `sprite_data.gd` and the rigs in `walk_cycle.py`. Add an ART_BIBLE section "Act
  VI: the Inferno, the shared kinds" and a GDD §15.0 row "Act VI art: the shared kinds".
- **Image generation.**
  - Always run `GEN_LEDGER=/home/user/wt/act6-art/docs/art/generation_ledger.csv python3 tools/gen_image.py ...`, using
    `act6_units.png` / `act6_lineup.png` crops as references, and commit the ledger.
  - Budget: about $0.40.
  - The image API refuses anything past the line: if a prompt is refused, dial the wording back and say so.
- **Checks.**
  - Run `tools/art_check.py`.
  - Look at every sprite at game size and zoomed, next to the Act V shared kinds.
  - Make a contact sheet in your scratch dir.

**Shared files you may touch:** `tools/palette.json`, `tools/prepare_sprite.py` (`FACTION_RAMPS`), `sprite_data.gd`,
`tools/walk_cycle.py`, `docs/art/ART_BIBLE.md`, `docs/art/generation_ledger.csv` (append only), and `docs/GDD.md` (your
row).

## Agent C: the music and sounds (branch `act6-audio`, worktree `/home/user/wt/act6-audio`)

- **Scratch dir:** `.../scratchpad/act6/audio/`.
- **CPU:** at most 1 Godot process.
- **Read:** as Act V's Agent C, plus the GDD row "The Setting Sun and the Shogunate sounds".

### What you make
1. **"Hymn of the Pit"** (`SoundData.BRIMSTONE_SCORE`, key `brimstone` in `SCORES`): a synthesized, score-driven run loop
   that sounds infernal.
   - Instruments:
     - a heavy low pipe-organ drone;
     - slow pounding war drums;
     - a dissonant choir pad (tritones, Phrygian / Locrian);
     - a snarling distorted bass pulse;
     - bells.
   - It can reuse the existing score jobs and add new ones like the Act V `taiko`, `koto` and `flute` jobs.
   - No sound files.
   - **Acts I–V loops and the startup bank must stay identical sample for sample**: render it as its own score with its
     own seed, lazily.
2. **The Inferno sound pack** (`SoundData.INFERNO_SOUNDS`, loaded lazily with `brimstone`, own seeds):

   | Sound id | What it sounds like |
   |---|---|
   | `pit_open` | a rumbling crack and a lava hiss |
   | `pit_burn` | a short sizzle |
   | `portal_open` | a deep whoosh with a choir swell |
   | `portal_seal` | a heavy slam and a bell |
   | `charm_kiss` | a soft kiss with a shimmering chime |
   | `charm_break` | a glassy snap |
   | `imp_cackle` | a short chittering laugh |
   | `brute_slam` | a ground-shaking impact |
3. **Tests:**
   - `--import` clean.
   - A default Graveyard run and a `--stage=sun_road --policy=army` run (seed 7) compared with base `7079925`. The
     `[autotest]` / `[metric]` lines must be identical.
   - A headless render check of the score and every pack sound.
4. **Docs:** a GDD §15.0 row "Hymn of the Pit and the Inferno sounds", and README lines.

**Shared files you may touch:** `sound_data.gd`, the synth / `Sfx` files, `README.md`, `docs/GDD.md`.

## Final report (every agent)

Your last message covers:
- the branch and commits;
- the files;
- the shared files you touched;
- the extension points phase 2 must use (exact names);
- your GDD rows;
- test results (numbers, gate diff);
- every PNG and its cost;
- anything left open or decided on your own.
