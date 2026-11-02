# Act VII foundation (phase 1): briefs

The lead's briefs for the three Act VII foundation agents, who run at the same time in their own git worktrees. Each
agent reads **Common** and its own section in full before starting. This is the plan that built Acts V and VI:
`docs/act6/BRIEF_FOUNDATION.md` is the closest model, and this brief only says what differs, with `court` wherever Act VI
had `inferno`.

## Common (every agent)

You build part of **phase 1 of Act VII**, **the Sanguine Court**, of **Necropathy** (Godot 4.3, GDScript, Vampire
Survivors genre): vampires, bats, bat-folk, werewolves and witches who kept their own will in death, and come for the
necromancer who emptied their table. The design is `docs/act7/PROPOSAL.md` (owner-approved, with the owner's answers at
its top; read it in full).

- **Bloodfeast is as written.** Vampires feed 50% and the others 25%; Rot and Wither halve it.
- **No epilogue part or closing card.**
- **Concept art is approved:** `art_source/concepts/act7_*.png`.

### Read first
1. `CLAUDE.md`. It wins any conflict. In particular:
   - document every variable;
   - tunables only in `scripts/data/*.gd`, tagged `# TUNING (not in GDD)`;
   - static typing and determinism;
   - one path per modifier;
   - no shader may read the screen, and prefer textures over polygons redrawn every frame;
   - never call `AudioServer.add_bus()`;
   - **summons never get act-only rules**: Night Wings is an enemy flag, and the enemy's own kit decides who can hit it,
     the way Act VI's Fallen Angel used `CovenantKit.taken_mult()`;
   - co-op reads the necromancer through the bound slot.
2. `docs/GDD.md` §15.0: the Act VI rows, from "Act VI foundation (phase 1)" to the last Act VI playtest row, and
   "Building the rest of the planned content".
3. `README.md` and `docs/act6/BRIEF_FOUNDATION.md`.

### Process rules
As in Act VI, with these Act VII specifics:
- Shared-file blocks are headed `# --- Act VII: the Sanguine Court ---` and go at the END of what they extend.
- **The base commit is `48ec479`.**
- End each dict entry or `match` arm with a line unique to it.
- Commit messages end with exactly:

  ```
  Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
  Claude-Session: https://claude.ai/code/session_01TjA5CNwUWb95gMazj5Z3qp
  ```

- **Do not push.** Never read or print any API key.

### Fixed names (do not rename)
- **Stages:** act 7, STAGE key `court` (true).

  | Stage id | Stage | Boss id |
  |---|---|---|
  | `ravensmoor` | Stage 19, Ravensmoor | `vargr` |
  | `witchwood` | Stage 20, the Witchwood | `isolde` |
  | `castle_sanguis` | Stage 21, Castle Sanguis | `carmilla` |

- **Shared enemy kinds:**
  - `blood_thrall`: fodder; bitten servants, pale and slow; they feed a little.
  - `vampire_bat`: flying fodder; swarms of 10; Night Wings.
  - `blood_knight`: soldier; halberd and blood-red plate; feeds on every hit.
  - `werewolf`: heavy. A human hunter with a silver crossbow until the Blood Moon or half HP, then a huge beast that
    lunges and feeds hard. Its sprites are `court/werewolf` and `court/werewolf_beast`.
  - `vampire_noble`: elite; the Countess, female, figure style. A blood-drain beam at range (a ranged feed); at low HP
    she turns to mist (1.5 s untargetable) and reforms nearer the necromancer.

  Sprite keys are `court/<id>` in `assets/sprites/court/`: a still plus a walk strip (a hover or glide strip for fliers
  and mist), with an idle strip for the figure-style female.
- **Palette:** constants in `scripts/data/palette.gd` (Agent A); ramps in `tools/palette.json` (Agent B), exactly:
  - blood: `COURT_BLOOD_INK` #12060A (outline), `COURT_BLOOD_DARK` #5A0A14, `COURT_BLOOD` #A3142A, `COURT_BLOOD_LIGHT` #E0384E;
  - velvet: `COURT_VELVET_DARK` #160F1C, `COURT_VELVET` #2B1E36, `COURT_VELVET_LIGHT` #4D3A5E;
  - moonlight: `COURT_MOON_DARK` #6E7A8C, `COURT_MOON` #B4C0D0, `COURT_MOON_LIGHT` #E6EEF7.

  Candle gold is the existing gold.
- **Music:** key `sanguine`, score `SoundData.SANGUINE_SCORE`, "Waltz of the Red Moon".
- **Court sound ids:** `bite_feed`, `blood_shield`, `bat_screech`, `moon_rise`, `moon_set`, `wolf_howl`, `coffin_creak`,
  `mist_form`.

## Agent A: the foundation code (branch `act7-foundation`, worktree `/home/user/wt/act7-foundation`)

- **Scratch dir:** `/tmp/claude-0/-home-user-Vampire-Survivors-Clone-Lol/b0031aa1-78e2-5d60-8763-4014a0c61c3c/scratchpad/act7/foundation/`
- **CPU:** at most 2 Godot processes at once.

### Also read
- The Act VI code you copy the shape of: `scripts/enemies/inferno/` (`inferno_rules.gd`, `hell_pits.gd`,
  `temptation.gd`, `inferno_kit.gd`), `inferno_enemy_data.gd`, `inferno_rules_data.gd`, `burning_gate_stage.gd`,
  `InfernoGround`, `InfernoGlyphs` and `InfernoReport`.
- How the Fallen Angel uses `CovenantKit.taken_mult()` (`scripts/enemies/inferno/fallen_angel_kit.gd`).
- The Act II tide surges (`TideDirector`), which are the model for the Blood Moon clock.
- `CombatResolver` (`damage_unit()`, `damage_player()`, enemy healing), the horde body-block code, the stage select, the
  Codex and `autotest.gd`.

### What you build

**Stages.** Three registered stub stages: `ravensmoor_stage.gd`, `witchwood_stage.gd`, `castle_sanguis_stage.gd`.
- act 7, `"playable": false`.
- The unlock chain: Ravensmoor opens on the Morning Star (`pandemonium`, boss kills 1), then each stage opens the next.
- Boss ids in `StageRegistry.BOSS_ARRIVALS`, each with a placeholder `script` until
  `scripts/enemies/court/boss_<id>.gd` exists.
- Zone names from the proposal.
- A placeholder timeline of the shared kinds.
- A placeholder floor `CourtGround` (moor, fen, castle stone) and obstacles `CourtGlyphs`.
- Music key `brimstone` for now, with a comment that the lead switches it to `sanguine` at the merge.
- Soul Ash ×1 / ×1.25 / ×1.5.
- Enemy HP and damage a step above Pandemonium's (HP ×1.85, damage 1.5); the step goes in HP.

**Stage select.** An **Act VII** tab; seven tabs must fit at 1280 × 600 layout px. Check a screenshot.

**Faction data.**
- `CourtEnemyData` holds the shared kinds; `RavensmoorEnemyData`, `WitchwoodEnemyData` and `CastleSanguisEnemyData` are
  empty, looked up by `EnemyDirector.court_def()` after `inferno_def()`.
- Kits load by name from `scripts/enemies/court/<id>_kit.gd` through a `CourtKit` base.
- Row keys:
  - `feeds` (float, the Bloodfeast share);
  - `flies` (bool, Night Wings);
  - `werebeast` (bool: transforms under the Blood Moon or at half HP);
  - `noble` (bool: mist form).

**The shared rule object.** `game.court` (`CourtRules`), created only when the STAGE has `court`. It is null on Acts
I–VI, so stages 1–18 keep their same-seed summaries. Its numbers live in `scripts/data/court_rules_data.gd`.

**The three shared rules, one code path each:**

1. **Bloodfeast** (`Bloodfeast`, owned by `game.court`).
   - Called once from `CombatResolver.damage_unit()` and once from `damage_player()`, only when the attacker is a Court
     enemy with `feeds` > 0.
   - It heals the attacker for `feeds` × the damage dealt, through the existing enemy-heal path.
   - Healing past full banks as a **blood shield** of up to 25% of max HP, absorbed before HP.
   - **Rot and Wither halve** feeding by the enemies they touch.
   - Draw a red thread from victim to attacker, as a texture.
   - Leave a hook for **Embalmed** (enemies heal half as much from hitting summons): one multiplier, default 1.0. Leave
     a hook for **Silver Bones** (summon hits on `werebeast` / `noble` kinds deal more, and mist lasts less): multipliers,
     default 1.0. Do not build those passives.
2. **Night Wings.**
   - `flies` kinds pass over the Bone Ring: the existing body-block code ignores them, so they reach the necromancer and
     the priests inside.
   - They must land to bite: a 0.5 s swoop shown by a ground shadow.
   - In flight, only airborne summons, ranged attacks and spells can hit them. Do this through the enemy's kit
     (`taken_mult()` / targetability), never through a summon rule.
   - One flag, one documented path.
3. **The Blood Moon** (`BloodMoon`, owned by `game.court`, a clock path like the tide surges).
   - Every 4:00 the moon turns red for 45 s, shown on the HUD 10 s ahead.
   - Under it, `werebeast` kinds transform, every Court enemy feeds twice as hard, and phase 2's witch covens can cast
     (expose `BloodMoon.is_up()`).
   - A tinted overlay as a blend-mode rect.
   - Overrides go in the STAGE key `moon`.
   - Expose `BloodMoon.force(duration)` for the bosses (Vargr and Isolde call their own moon).

**The Reckoning, the Endless Feast.** At 0:00 the Blood Moon rises and never sets. Feeding grows three times as hard each
minute, and coffins (a placeholder structure) open and release nobles. Tune it through the RECKONING keys.

**Codex.** A **Sanguine Court** tab.

**Sounds.** A map in `court_rules_data.gd` that points at existing sounds for now, with the intended ids in comments.

**Autotest.**
- Flags: `--stage=ravensmoor|witchwood|castle_sanguis`, `--spawn=`, `--boss=vargr|isolde|carmilla`.
- A `CourtReport` with these lines:
  - `bloodfeast`: healing done, blood shield banked and absorbed, feeding halved by Rot / Wither;
  - `night wings`: swoops, bites on the necromancer, hits taken in flight by allowed sources;
  - `blood moon`: moons, transforms, feeding under the moon;
  - `court kinds`;
  - `court stage`.
- The army bot saves Dread Rally for the moon if it is cheap to add.

**Gate.** Stages 1–18 keep their same-seed summaries.
- Write `docs/act7/tools/gate.sh`: Act VI's script plus a `pandemonium` army run.
- Base is `48ec479`. Only catalog counts and "stages unlocked by this run: ravensmoor" may differ.

**Playability.**
- Each stub, run `--policy=army --mortal`, reaches 0:00 with zero errors and `stuck_units=0`, and all three rules show
  activity in the summary.
- Also run one clean default Graveyard run, one `--mortal` run and one co-op bot run on a stub.

**Screenshots** at 1280×720 under xvfb: a red thread and blood shield, bats over the ring with landing shadows, the Blood
Moon overlay, and the Act VII tab. Look at them yourself.

**Shared files you may touch:**
- everything listed under "Also read";
- `palette.gd` (the COURT block);
- `codex_data.gd`, `autotest.gd`;
- `README.md`, `docs/GDD.md`.

Not `sound_data.gd`, the synth files or `tools/palette.json`.

**GDD rows:** "Act VII foundation (phase 1)", "Bloodfeast", "Night Wings", "The Blood Moon".

## Agent B: the art (branch `act7-art`, worktree `/home/user/wt/act7-art`)

- **Scratch dir:** `.../scratchpad/act7/art/`
- **CPU:** at most 1 Godot process.

**Read:** as Act VI's Agent B, and the ART_BIBLE Act VI section as the model. The approved concepts are
`art_source/concepts/act7_lineup.png`, `act7_boss.png` and `act7_stage.png`, with their prompts.

**What you make:**
- **Ramps.** The `blood`, `velvet` and `moonlight` ramps in `tools/palette.json`, with exactly the Fixed-names hex values
  and their roles. Add a `court` folder to `prepare_sprite.py`'s `FACTION_RAMPS`.
- **Sprites** for the shared kinds, each a still plus a walk or glide strip:

  | Sprite | Size | What it is |
  |---|---|---|
  | `blood_thrall` | ~30 px | male fodder; pale, bitten |
  | `vampire_bat` | ~20 px | flier, hover strip |
  | `blood_knight` | ~52 px | male soldier; halberd, blood-red plate |
  | `werewolf` | ~50 px | male human hunter, silver crossbow |
  | `werewolf_beast` | ~84 px | the transformed beast |
  | `vampire_noble` | ~50 px | **female**: the Countess |

  The Countess is in the figure-redesign style: exaggerated hourglass, a velvet gown with a high slit and a deep
  neckline, gothic and alluring, chest and hips covered. Give her a `bust` rig, the hip `swish` and an idle strip.
- **Coffin.** A coffin structure, `structures/court_coffin`, closed and opened (`_open`).
- **Data and docs.** Your Act VII blocks in `sprite_data.gd` and `walk_cycle.py`, an ART_BIBLE section "Act VII: the
  Sanguine Court, the shared kinds" and a GDD row "Act VII art: the shared kinds".
- **Generation.** Use `GEN_LEDGER=/home/user/wt/act7-art/docs/art/generation_ledger.csv python3 tools/gen_image.py ...`,
  with the approved concepts as references. Commit the ledger rows. Budget about $0.40.
- **Checks.** Run `art_check.py`, look at every sprite at game size, and make a contact sheet.

**Shared files you may touch:** `tools/palette.json`, `tools/prepare_sprite.py`, `sprite_data.gd`, `tools/walk_cycle.py`,
`ART_BIBLE.md`, the ledger (append only) and `docs/GDD.md` (your row).

## Agent C: the music and sounds (branch `act7-audio`, worktree `/home/user/wt/act7-audio`)

- **Scratch dir:** `.../scratchpad/act7/audio/`
- **CPU:** at most 1 Godot process.

**Read:** as Act VI's Agent C, plus the GDD row "Hymn of the Pit and the Inferno sounds".

**What you make:**
1. **"Waltz of the Red Moon"** (`SoundData.SANGUINE_SCORE`, key `sanguine` in `SCORES`): a gothic 3/4 waltz with a
   harpsichord arpeggio, a church organ, low strings and a slow heartbeat pulse, in a minor key. It is synthesized and
   score-driven, and may add score jobs as Acts V and VI did. **The loops of Acts I–VI and the startup bank stay identical
   sample for sample**: give it its own seed and render it lazily.
2. **The Court sound pack** (`SoundData.COURT_SOUNDS`, lazy with `sanguine`, its own seeds):

   | Id | Sound |
   |---|---|
   | `bite_feed` | a wet bite and a sip |
   | `blood_shield` | a dark shimmer |
   | `bat_screech` | a high chittering cry |
   | `moon_rise` | a low swell and a distant howl |
   | `moon_set` | a fading chord |
   | `wolf_howl` | a long howl |
   | `coffin_creak` | wood groaning open |
   | `mist_form` | a breathy whoosh |

3. **Tests.**
   - `--import` clean.
   - A default Graveyard run and a `--stage=pandemonium --policy=army` run (seed 7) against base `48ec479`, with
     identical `[autotest]` / `[metric]` lines.
   - A headless render check of the score and the pack.
4. **Docs.** A GDD row "Waltz of the Red Moon and the Court sounds" and README lines.

**Shared files you may touch:** `sound_data.gd`, the synth and `Sfx` files, `README.md`, `docs/GDD.md`.

## Final report (every agent)

- The branch and commits.
- The files you added.
- The shared files you touched.
- The extension points phase 2 must use (exact names).
- Your GDD rows.
- Test results: numbers and the gate diff.
- Every PNG and its cost.
- Anything left open or decided on your own.
