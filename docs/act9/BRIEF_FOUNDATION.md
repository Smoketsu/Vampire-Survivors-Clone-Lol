# Act IX foundation (phase 1): briefs

The lead's briefs for the three Act IX foundation agents, who run at the same time in their own git worktrees. Each
agent reads **Common** and its own section in full before starting. This is the plan that built Acts V to VIII:
`docs/act8/BRIEF_FOUNDATION.md` is the closest model, and this brief only says what differs, with `concord` wherever
Act VIII had `city`. Act IX is the last planned act. It needs no new map system (it uses the scattered-obstacle arena,
not city blocks), but it adds one new kind of ground, **Terraforming**, and a new weapon path, **Beams**.

## Common (every agent)

You build part of **phase 1 of Act IX**, **the Concord of Stars**, of **Necropathy** (Godot 4.3, GDScript, Vampire
Survivors genre). Long ago something out in the dark seeded life on this world, and it comes back every few thousand
years to reap the dead. This time there is nothing to reap, because the necromancer has taken every soul. The Concord, a
coalition of alien races under the Harvesters who rule it, comes to find out why. The design is `docs/act9/PROPOSAL.md`
(owner-approved; read it in full). **The owner's answers at its top override the body:**

- **One coalition.** The Brood lead Stage 25, the Vrask Stage 26 and the Harvesters Stage 27. The Luminous are mixed into
  every stage.
- **The three shared rules are Beams, Abduction and Terraforming.** Terraforming replaces Adaptation: alien ground
  spreads over the arena during the run and heals Concord units standing on it, and the necromancer's spells burn it
  back. Ignore every line of the body about Adaptation, "ADAPTED" or Gravity Wells.
- **A plain finale.** The Harvester fights as written; no twist.
- **No epilogue part and no closing card.** The act keeps its number and stage numbers until the act order is settled.
  `docs/proposals/NEW_ACTS_AND_ORDER.md` mentions an Ark harvest log as a possible link to a later act: build nothing
  for it, and write nothing that contradicts it.
- **Concept art is approved** (three rounds): `art_source/concepts/act9_lineup.png`, `act9_boss.png` and
  `act9_stage.png`, with their `.txt` prompts. The `_r1` / `_r2` files are old rounds; don't use them.

### Read first
1. `CLAUDE.md`. It wins any conflict. In particular:
   - document every variable;
   - tunables only in `scripts/data/*.gd`, tagged `# TUNING (not in GDD)`;
   - static typing and determinism;
   - one path per modifier;
   - no physics engine for units: the spatial hash and `Arena` push-out only;
   - no shader may read the screen, and prefer textures over polygons redrawn every frame;
   - never call `AudioServer.add_bus()`;
   - **summons never get act-only rules**: the act's rules act on enemies, beams, saucers and the ground. Abduction is
     an enemy effect on a summon through the existing hooks (below), never a new summon rule;
   - co-op reads the necromancer through the bound slot.
2. `docs/GDD.md` §15.0: the Act VIII rows, from "Act VIII foundation (phase 1)" to "Act VIII art review, round 2", and
   "Building the rest of the planned content".
3. `README.md` and `docs/act8/BRIEF_FOUNDATION.md`.

### Process rules
As in Act VIII, with these Act IX specifics:
- Shared-file blocks are headed `# --- Act IX: the Concord of Stars ---` and go at the END of what they extend.
- **The base commit is the branch head the lead creates the worktrees from.** Record it (`git rev-parse HEAD` before
  your first commit) and name it in your report. Later commits on the lead's branch are docs and Act VIII playtest notes;
  the gate must see no difference.
- End each dict entry or `match` arm with a line unique to it.
- Commit messages end with exactly:

  ```
  Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
  Claude-Session: https://claude.ai/code/session_01TjA5CNwUWb95gMazj5Z3qp
  ```

- **Do not push.** Never read or print any API key.

### Fixed names (do not rename)
- **Stages:** act 9, STAGE key `concord` (true).

  | Stage id | Stage | Leads | Boss id |
  |---|---|---|---|
  | `crash_site` | Stage 25, the Crash Site | the Brood | `hive_mother` |
  | `proving_moon` | Stage 26, the Proving Moon | the Vrask | `vrask_tal` |
  | `ark` | Stage 27, the Ark of the Concord (the finale) | the Harvesters | `harvester` |

- **Races** (row key `race`; the Codex and the report group by it): `brood`, `harvesters`, `vrask`, `luminous`. The race
  id is plural `harvesters`, so it never reads as the boss id `harvester`.
- **Shared enemy kinds** (one or two of each race, every one used by a rule; the Luminous both):
  - `broodling` (brood): fodder; small, fast insects in swarms of 12.
  - `grey_drone` (harvesters): fodder; small greys in squads, a probe that fires a short beam (Beams).
  - `saucer` (harvesters): an elite flier; hovers over the ring and abducts (Abduction). Row `flies`: in flight only
    airborne summons, ranged attacks, casters, spells and volleys hit it, the Act VII Night Wings rule.
  - `vrask_hunter` (vrask): elite, male; cloaked while it moves (a shimmer), a three-dot plasma lock, then one shot (a
    short beam).
  - `lumen_sentinel` (luminous): ranged, male; sweeping beams; a shield that soaks the first hits.
  - `prism` (luminous): support, **the Star-Seer, female, figure style**; a beam that passes through her splits into
    three (Beams).

  These are **stage kinds for phase 2**: the Burrower and the Acid Spitter (the Crash Site), the Warbeast (the Proving
  Moon), the Grey Overseer and the Luminous Archon (the Ark), and the bosses' allies. Sprite keys are `concord/<id>` in
  `assets/sprites/concord/`: a still plus a walk strip (a hover strip for the saucer, a glide strip for the Luminous),
  with an idle strip for each figure-style female.
- **Structure:** `concord_terraformer`, a landing pod that roots and grows alien ground around it (Terraforming). Sprite
  `structures/concord_terraformer` with `_dead`.
- **Palette:** constants in `scripts/data/palette.gd` (Agent A); ramps in `tools/palette.json` (Agent B), exactly:
  - hull: `CONCORD_INK` #07080F (outline; starfield black), `CONCORD_HULL_SHADE` #AEB8C4, `CONCORD_HULL` #E8ECF0;
  - gunmetal: `CONCORD_GUNMETAL_DARK` #1E242C, `CONCORD_GUNMETAL` #3A424C;
  - plasma: `CONCORD_PLASMA_DARK` #1FA84A, `CONCORD_PLASMA` #3CFF6A;
  - laser: `CONCORD_LASER` #FF2FB8 (the beams' aiming lines and beams);
  - chitin: `CONCORD_CHITIN` #1B3A2A, `CONCORD_CHITIN_LIGHT` #2E6B45 (the Brood's carapace);
  - hive: `CONCORD_HIVE` #6A3FA0, `CONCORD_HIVE_BONE` #E0D2B0 (the Hive Mother only);
  - vrask: `CONCORD_VRASK` #2A8F7A;
  - lumen: `CONCORD_LUMEN` #FFE9A0 (the Luminous; a pale light, never the UI gold);
  - turf: `CONCORD_TURF_DARK` #1A1C22, `CONCORD_TURF` #5A2A6A (alien flesh ground).

  Gold keeps its meaning (evolution, chest, victory); crimson stays danger.
- **Music:** key `starsong`, score `SoundData.STARSONG_SCORE`, "The Reaping Stars".
- **Concord sound ids:** `beam_charge`, `beam_fire`, `beam_reflect`, `tractor_beam`, `abduction`, `saucer_down`,
  `ground_burn`, `brood_chitter`, `harvest_eye`.

## Agent A: the foundation code (branch `act9-foundation`, worktree `/home/user/wt/act9-foundation`)

- **Scratch dir:** `/tmp/claude-0/-home-user-Vampire-Survivors-Clone-Lol/b0031aa1-78e2-5d60-8763-4014a0c61c3c/scratchpad/act9/foundation/`
- **CPU:** at most 2 Godot processes at once.

### Also read
- The Act VIII code you copy the shape of: `scripts/enemies/city/` (`city_rules.gd`, `city_kit.gd`, `escalation.gd`,
  `martial_law.gd`), `city_enemy_data.gd`, `city_rules_data.gd`, the per-stage tables (`skid_row_enemy_data.gd` ...),
  `skid_row_stage.gd`, `CityGround`, `CityGlyphs`, `CityReport`, `EnemyDirector.city_def()` and `CITY_BOSS_DIR`,
  `CovenantKits.CITY_KIT_DIR`, `Game.city_rules()`.
- The beam and line precedents: `EmpireShots` (the packed-array storage, the cap, `_orb_stops()`: the Eclipsed Guard and
  `AbilityManager.try_intercept()`, the barrier test `barrier_hp`), `LockOn` (painted lines, the owner and target
  generation guards, the boss override) and `DivineWrath` (telegraphed hazards that hit both armies through
  `CombatResolver`).
- The hold precedents: `SummonedUnit.held_until`, the Netcaster (`netcaster_kit.gd`), the Chiropteran King's carry-off
  (`ChiropteranKingKit.carry()` and `_drop_all()`), Nightjar's grapple, `CombatResolver.stun_unit()`,
  `HordeDirector.on_unit_died(u, as_death)`.
- The ground precedents: `HellPits` (seeded cells, the live radius, textures at z -8, `open_pit()` for phase 2),
  `TerrainSlow`, and `CombatResolver.heal_enemy()` (the one enemy-heal path).
- Night Wings (`night_wings.gd`, `CourtKit.taken_mult()`, `FallenAngelKit.grounded_melee()`), the holy shield
  (`Enemy.holy_shield`), `HundredShadowsData.is_spell_source()`, the miniboss bar, the stage select, the Codex and
  `autotest.gd`.

### What you build

**Stages.** Three registered stub stages: `crash_site_stage.gd`, `proving_moon_stage.gd`, `ark_stage.gd`.
- act 9, `"playable": false`, chapters XXV to XXVII.
- The unlock chain: the Crash Site opens on Paragon (`liberty_heights`, boss kills 1), then each stage opens the next.
- Boss ids in `StageRegistry.BOSS_ARRIVALS`, each with a placeholder `script` until
  `scripts/enemies/concord/boss_<id>.gd` exists (`EnemyDirector.CONCORD_BOSS_DIR`).
- Zone names from the proposal (the Crater / the Hatchery / the Wreck / the Glass Spire; the Landing / the Craters / the
  Trophy Hall / the Duelling Ring; the Hangar / the Specimen Vaults / the Reactor / the Bridge of Stars).
- A placeholder timeline of the shared kinds, all four races on every stub so every rule shows.
- A placeholder floor `ConcordGround` (styles `ruins`, `moon`, `hull`) and obstacles `ConcordGlyphs`; the normal
  scattered-obstacle arena (no `blocks`).
- Music key `siren` for now, with a comment that the lead switches it to `starsong` at the merge.
- Soul Ash ×1 / ×1.25 / ×1.5.
- Enemy HP and damage a step above Liberty Heights' (HP ×2.15, damage 1.5); the step goes in HP.
- Reserve, and document in `StageRegistry`, the STAGE key `gravity` (the Proving Moon's knockback multiplier, phase 2).
  Do not read it yet.

**Stage select.** An **Act IX** tab; nine tabs must fit at 1280 × 600 layout px (shrink `ACT_TAB_COMPACT_SIZE` if they
don't). Check a screenshot.

**Faction data.**
- `ConcordEnemyData` holds the shared kinds, `concord_terraformer` and the Reckoning's own rows. `CrashSiteEnemyData`,
  `ProvingMoonEnemyData` and `ArkEnemyData` are empty, looked up by `EnemyDirector.concord_def()` after `city_def()`
  (also in `enemy_def()` and `is_known_kind()`).
- Kits load by name from `scripts/enemies/concord/<id>_kit.gd` through a `ConcordKit` base (`CovenantKits.CONCORD_KIT_DIR`
  after the City folder; ids unique across the eight folders).
- Row keys:
  - `race` (String, one of the race ids);
  - `beam` (Dictionary: the kind's beam style id plus overrides of its numbers; absent = fires none);
  - `abducts` (bool: a tractor beam, Abduction);
  - `cloak` (Dictionary: the Vrask cloak's numbers; absent = none);
  - `heals_on_turf` (bool, default true for every Concord kind; false for structures).
  Flying uses the existing `flies` / `phases` / `floating` keys and the shield the existing `holy_shield` path; add no
  second one.

**The shared rule object.** `game.concord` (`ConcordRules`, `scripts/enemies/concord/concord_rules.gd`), created only when
the STAGE has `concord`. It is null on Acts I-VIII, so stages 1-24 keep their same-seed summaries. A Concord kind forced
onto another stage with `--spawn=` creates it on first activation (`Game.concord_rules()`, as `Game.city_rules()` does),
with the terraformer pods and the Final Harvest off there; its beams, its abduction and its heal on turf still work. Its
numbers live in `scripts/data/concord_rules_data.gd`.

**The three shared rules, one code path each:**

1. **Beams** (`ConcordBeams`, a `Node2D` owned by `game.concord`, built like `EmpireShots` / `LockOn`).
   - **The one call:** `ConcordBeams.fire(owner, dir, style, overrides, boss_override)`. Every Concord beam goes through
     it: the drones' probes, the Vrask lock, the Sentinels' sweeps, the Reckoning's eye and phase 2's bosses. Never
     through `ProjectileManager` or `EmpireShots`.
   - **Phases:** a thin magenta aiming line for `aim` s (1.0; it tracks its target, then stops turning for the last
     0.3 s), then the beam holds for `hold` s (1.5) and sweeps `sweep` degrees (its side from the think slot, no RNG).
     Styles in `ConcordRulesData.BEAM_STYLES`: `probe` (short, thin, little sweep), `lock` (the Vrask: three red dots
     on the target for the aim, then a 0.15 s pulse), `sweep` (the Sentinel), `eye` (the Reckoning). Numbers: length,
     width, damage per second, tick.
   - **What it hits:** every summon and every necromancer on its line, each at most once per tick, through
     `damage_unit()` and `damage_player()` (Grave Step's i-frames dodge it). **The ring does not block it**, nor does
     a Bone Wall. Enemies are never hit by a Concord beam, except a reflected one.
   - **Reflection:** the first reflector along the line from the firer ends the beam there and sends a reflected beam
     back along the line to the firer, hitting every enemy on it through `damage_enemy()` with the reflection point as
     `origin` and source `beam_reflect`. Reflectors: an Orb Shield (the Eclipsed Guard, then one charge of
     `AbilityManager.try_intercept()`, once per beam, as `EmpireShots._orb_stops()`; co-op: every standing
     necromancer's, slot bound) and a summon with a Warder / Bishop barrier (`barrier_hp > 0`; the barrier takes that
     tick's hit as usual).
   - **Prisms:** a beam whose line passes through a `prism` ends there and splits into three beams of the remaining
     length (±25°), once per beam. Split beams don't count toward the cap.
   - **Cap:** at most 6 beams at once (a beam over the cap is refused and counted; the kit retries). A boss override goes
     up to 12, as LockOn's.
   - Stored in packed arrays with generation guards; drawn as textures (the `beam_*` strips when present), z 3, no
     polygons redrawn every frame.
   - Hooks for **Mirror Bones** (reflected beams deal more, summons take less beam damage): `ConcordRules.mirror_reflect_mult()`
     and `mirror_taken_mult()`, both exactly 1.0. Do not build the passive.
2. **Abduction** (`Abduction`, owned by `game.concord`). An enemy effect on a summon, through hooks that already exist.
   - **The one call:** `Abduction.lift(saucer, u)`. Any `abducts` kit calls it, and so do phase 2's Harvester (the
     Reaping) and the Final Harvest. The saucer kit hovers over the ring's edge, picks the nearest liftable summon
     (deterministic), shows a green tractor cone on the ground for `windup` s (1.0) and lifts it.
   - **Liftable:** never airborne, spawning, dead, charmed, compelled or already held; never a body larger than
     `lift_max_radius` (the Abomination, Colossus and Golem are too heavy: TUNING); never the necromancer. The
     proposal's "or a corpse" is dropped: corpses are not objects on the ground in this game.
   - **The hold:** the summon is held through `SummonedUnit.held_until`, renewed each tick by `Abduction.carry()`, the
     one place that moves it (it rises `lift_px` under the saucer, as `ChiropteranKingKit.carry()`), and kept out of the
     fight by one `CombatResolver.stun_unit(u, hold, "abduction")` at the lift (Oni's Resolve shortens that stun as it
     does every stun; the hold stays).
   - **Rescue:** if the saucer dies or is pooled during the hold, the summon drops at `Arena.free_point()` with a short
     daze (as the King's `_drop_all()`).
   - **Taken:** after `hold` s (8) the summon is gone: `u.director.on_unit_died(u, false)`. No death is counted, no
     corpse, no claim, and the class queue replaces it at its next replenish.
   - **Cap:** at most 3 summons held at once across both armies; the Final Harvest lifts the cap.
   - Hooks for **Anchored** (abductions last half as long and break when the saucer takes damage):
     `ConcordRules.anchored_hold_mult()` (exactly 1.0) and `anchored_breaks()` (false). Do not build the passive.
   - **The saucer in the air:** `ConcordKit.taken_mult()` applies the Night Wings test (`FallenAngelKit.grounded_melee()`):
     grounded melee blows deal `flight_melee_taken` (0); everything else lands in full.
3. **Terraforming** (`Terraforming`, a `Node2D` owned by `game.concord`, built like `HellPits`).
   - **The ground:** a sparse map of 64 px cells (Vector2i → state: growing, live, scorched), deterministic, drawn as
     textures at z -8 (the `tiles/concord_turf` and `_scorch` tiles when present, else a code glyph). Only cells within
     `active_radius` of a standing necromancer are drawn and simulated; at most `max_cells` live cells (the oldest go
     first).
   - **Where it comes from:** `concord_terraformer` pods. Every `pod_every` s (shorter each minute) a pod falls on a
     telegraphed streak (1.5 s) at a seeded point `pod_min`..`pod_max` px from a standing necromancer (seeded gameplay
     RNG, Act IX only), at most `max_pods` alive. A live pod grows its patch by one ring of cells every `spread_every`
     s, up to `pod_radius`. A destroyed pod stops growing; its ground stays until burnt. **The one public call for phase
     2:** `Terraforming.seed(at, radius, opts)` (the Hive Mother's crater, the Ark's vents).
   - **The heal:** every `tick` s, each Concord enemy whose row has `heals_on_turf` and who stands on a live cell heals
     `heal_frac` of its max HP per second through `CombatResolver.heal_enemy(e, amount)` (no healer, so a silence does not
     stop it). Bosses and minibosses heal at `boss_mult` (0 by default; a stage may raise it). The ground does nothing
     to summons or to the necromancer.
   - **The burn (ONE check):** `ConcordRules.burns_ground(source)`, which is `HundredShadowsData.is_spell_source(source)`.
     It is called once, at the end of `CombatResolver.damage_enemy()`, only while `game.concord != null`. A spell hit
     burns every cell within `burn_radius` of the enemy it hit (`Terraforming.burn(pos, r)`). A burnt cell is scorched
     black for `regrow_delay` s and nothing grows into it. Burns are capped per tick so a big area spell stays cheap.
     Nothing else burns the ground, and summons never do (they are the army, not the spells).
   - A green heal shimmer on a healed enemy (visual only).

**The Reckoning, the Final Harvest** (`FinalHarvest`, owned by `game.concord`, run when the RECKONING has a
`final_harvest` key). At 0:00 the mothership's eye opens over the arena: a sky overlay texture (`concord/mothership_eye`)
and every `eye_every` s (shorter each minute) an `eye` beam through `ConcordBeams.fire(..., boss_override = true)`,
long enough to cross the view, sweeping across the necromancer. Saucers fill the sky (the RECKONING `kind` is `saucer`;
companions: broodlings, grey drones, a Vrask hunter, a Lumen Sentinel), and the abduction cap is gone. The pods keep
falling.

**Codex.** A **Concord** tab, grouped by race (`concord_brood`, `concord_harvesters`, `concord_vrask`,
`concord_luminous`, `concord_bosses`).

**Sounds.** A map in `concord_rules_data.gd` that points at existing sounds for now, with the intended ids in comments.

**Autotest.**
- Flags: `--stage=crash_site|proving_moon|ark`, `--spawn=` with the new kinds, `--boss=hive_mother|vrask_tal|harvester`.
- A `ConcordReport` (`scripts/core/concord_report.gd`) with these lines, each only when `game.concord` exists:
  - `beams`: fired by style, refused, peak at once, hits on summons and the necromancer and their damage, reflections
    (orb / barrier) and the reflected damage to enemies, prism splits;
  - `abduction`: lifts, rescues (saucer killed), taken, refused (cap, too heavy), peak held, saucers shot down;
  - `terraforming`: pods landed and destroyed, cells grown, peak live cells, cells burnt, HP healed on turf (by race);
  - `final harvest`: eye beams, saucers spawned, lifts without the cap (only once the Reckoning ran);
  - `concord kinds`: spawns / kills of every Concord kind that spawned, its first appearance, its damage to the
    necromancer and to summons, by race;
  - `concord stage`: stub status, boss, Soul Ash, the Reckoning.
- The army bot steps out of beam lines during the aim if it is cheap to add (one `danger_push()`-style behaviour).

**Gate.** Stages 1-24 keep their same-seed summaries.
- `docs/act9/tools/gate.sh` is written: Act VIII's script plus a `liberty_heights` army run.
- Only catalog counts and "stages unlocked by this run: crash_site" (after Paragon) may differ.

**Playability.**
- Each stub, run `--policy=army --mortal`, reaches 0:00 with zero errors and `stuck_units=0`, and all three rules show
  activity in the summary.
- Also run one clean default Graveyard run, one `--mortal` run and one co-op bot run on a stub (the turf must match on
  both slots).

**Screenshots** at 1280×720 under xvfb: aiming lines and a sweeping beam through the ring, a beam reflected off an Orb
Shield and a barrier, a prism split, a saucer lifting a summon, terraformed ground with a healing Brood unit and a burnt
patch, the Final Harvest's eye, and the Act IX tab. Look at them yourself.

**Shared files you may touch:**
- everything listed under "Also read" (`combat_resolver.gd` only for the one burn check; `summoned_unit.gd` and
  `horde_director.gd` not at all: use the hooks as they are);
- `palette.gd` (the CONCORD block);
- `codex_data.gd`, `codex_entries.gd`, `front_door_data.gd`, `autotest.gd`;
- `README.md`, `docs/GDD.md`.

Not `sound_data.gd`, the synth files or `tools/palette.json`.

**GDD rows:** "Act IX foundation (phase 1)", "Beams", "Abduction", "Terraforming", "The Final Harvest".

## Agent B: the art (branch `act9-art`, worktree `/home/user/wt/act9-art`)

- **Scratch dir:** `.../scratchpad/act9/art/`
- **CPU:** at most 1 Godot process.

**Read:** as Act VIII's Agent B, and the ART_BIBLE Act VIII section as the model. The approved concepts are
`art_source/concepts/act9_lineup.png`, `act9_boss.png` and `act9_stage.png`, with their prompts.

**Rules for this act:** **every prompt names the figure's sex** (or says it is a creature or a machine). The male kinds
(the Vrask hunter, the Lumen Sentinel) and the greys are in the original style. Every female kind (the Prism and the
Hive Mother here; phase 2's female kinds and characters) is in the figure-redesign style: an exaggerated hourglass,
glamorous, **chest and hips covered**, never nude. The Prism wears the opaque, fully covering high-necked gown of the
approved lineup (no cut-outs). The Hive Mother's purple chitin fully covers her chest, arms and hips. **Insects and
machines keep their own colours**: the Brood is green-black chitin with acid green, the saucer is hull white and
gunmetal with plasma green. **Never the necromancer's violet and bone** on any Concord kind (the round 3 fix of the boss
concept); the Hive Mother's purple is her own ramp, not the player's violet.

**What you make:**
- **Ramps.** The `hull`, `gunmetal`, `plasma`, `laser`, `chitin`, `hive`, `vrask`, `lumen` and `turf` ramps in
  `tools/palette.json`, with exactly the Fixed-names hex values and their roles (one ramp per hue: the Act VIII
  lesson). Add a `concord` folder to `prepare_sprite.py`'s `FACTION_RAMPS`; `hive` only for the Hive Mother through
  `KEY_RAMPS` (it sits near the player's violet).
- **Sprites** for the shared kinds, each a still plus a strip:

  | Sprite | Size | What it is |
  |---|---|---|
  | `broodling` | ~22 px | a small insect creature; green-black carapace, claws; walk strip |
  | `grey_drone` | ~28 px | a small grey alien, big black-eyed head, silver jumpsuit, glowing probe; sex left unmarked (a drone); walk strip |
  | `saucer` | ~64 px | a white-hulled saucer with green plasma lights, top-down readable; hover strip (lights turn); the tractor beam is the code's |
  | `vrask_hunter` | ~46 px | male; reptilian, teal scales, dark armour, partial cloak, shoulder caster, glaive; walk strip |
  | `lumen_sentinel` | ~46 px | male; a being of white-gold light in crystal armour, beam staff; glide strip |
  | `prism` | ~44 px | **female**, figure style, the Star-Seer; pale lavender skin, white-gold hair, a floating prism; opaque white-and-magenta gown; glide strip and idle strip |
  | `bosses/hive_mother` | ~96 px | **female**, figure style; the Brood's queen as in the lineup (purple chitin covering her completely, horned helm, gold eyes, spined wings, egg-sac abdomen); idle strip. Phase 2 codes her and adds attack poses |

  The Prism and the Hive Mother get a `bust` rig, the hip `swish` (the Prism's gown) and an idle strip.
- **Structure.** `structures/concord_terraformer` (a landing pod rooted in alien turf, green vents) and `_dead`.
- **Ground and sky.** Tiling 64 px turf textures `tiles/concord_turf` (veined purple flesh ground with green spores, as
  in `act9_stage.png`; a centre plus edge and corner pieces so the patches have a soft border) and `tiles/concord_scorch`
  (burnt black). A sky overlay `concord/mothership_eye` (the eye of the mothership opening over the arena, seen from
  below; a texture the code fades in, no screen read). Beam strips `effects/beam_line` and `effects/beam_hit` as grey
  tint masks, tinted magenta by the code.
- **Data and docs.** Your Act IX blocks in `sprite_data.gd` and `walk_cycle.py`, an ART_BIBLE section "Act IX: the
  Concord of Stars, the shared kinds and the turf" and a GDD row "Act IX art: the shared kinds and the turf".
- **Generation.** Use `GEN_LEDGER=/home/user/wt/act9-art/docs/art/generation_ledger.csv python3 tools/gen_image.py ...`,
  with the approved concepts as references. Commit the ledger rows. Budget about $0.55.
- **Checks.** Run `art_check.py`, look at every sprite at game size, tile the turf on a 1280×720 mock (patches over the
  Crash Site's rubble, with scorched cells) to check the seams, and make a contact sheet.

**Shared files you may touch:** `tools/palette.json`, `tools/prepare_sprite.py`, `sprite_data.gd`, `tools/walk_cycle.py`,
`ART_BIBLE.md`, the ledger (append only) and `docs/GDD.md` (your row).

## Agent C: the music and sounds (branch `act9-audio`, worktree `/home/user/wt/act9-audio`)

- **Scratch dir:** `.../scratchpad/act9/audio/`
- **CPU:** at most 1 Godot process.

**Read:** as Act VIII's Agent C, plus the GDD row "Sirens at Midnight and the City sounds".

**What you make:**
1. **"The Reaping Stars"** (`SoundData.STARSONG_SCORE`, key `starsong` in `SCORES`, `SCORE_PACKS` `"starsong":
   "concord"`): a vast, cold space track, a slow pulse under glassy pads, a low drone, a high, choir-like synth line in
   an unusual mode, and a soft swelling "harvest" horn for the Reckoning; never shrill. It is synthesized and
   score-driven, and may add score jobs as Acts V to VIII did. **The loops of Acts I-VIII and the startup bank stay
   identical sample for sample**: its seed is `Sfx.SCORE_SEEDS["starsong"] = SYNTH_SEED - 9`, rendered lazily.
2. **The Concord sound pack** (`SoundData.CONCORD_SOUNDS`, lazy with `starsong`, `Sfx.PACK_SEED_OFFSETS["concord"] =
   6000`, the next free offset after the City's 5000):

   | Id | Sound |
   |---|---|
   | `beam_charge` | a thin rising whine (the aiming line) |
   | `beam_fire` | a held, buzzing laser tone that ends cleanly |
   | `beam_reflect` | a bright glassy ping with a short reversed tail |
   | `tractor_beam` | a low, wobbling hum |
   | `abduction` | a rising whoosh that thins out (a summon taken) |
   | `saucer_down` | a sputtering electric crash |
   | `ground_burn` | a soft sizzle and hiss |
   | `brood_chitter` | a short insect clicking, not loud |
   | `harvest_eye` | a deep opening groan and a low horn (the Final Harvest) |

3. **Tests.**
   - `--import` clean.
   - A default Graveyard run and a `--stage=liberty_heights --policy=army` run (seed 7) against the base commit, with
     identical `[autotest]` / `[metric]` lines.
   - A headless render check of the score and the pack.
4. **Docs.** A GDD row "The Reaping Stars and the Concord sounds" and README lines.

**Shared files you may touch:** `sound_data.gd`, the synth and `Sfx` files, `README.md`, `docs/GDD.md`.

## Final report (every agent)

- The branch, the base commit and your commits.
- The files you added.
- The shared files you touched.
- The extension points phase 2 must use (exact names).
- Your GDD rows.
- Test results: numbers and the gate diff.
- Every PNG and its cost.
- Anything left open or decided on your own.
