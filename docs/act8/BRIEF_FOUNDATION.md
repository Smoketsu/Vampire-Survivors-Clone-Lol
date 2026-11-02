# Act VIII foundation (phase 1): briefs

The lead's briefs for the three Act VIII foundation agents, who run at the same time in their own git worktrees. Each
agent reads **Common** and its own section in full before starting. This is the plan that built Acts V, VI and VII:
`docs/act7/BRIEF_FOUNDATION.md` is the closest model, and this brief only says what differs, with `city` wherever Act VII
had `court`. Act VIII adds one system no act had: **city-block maps**. It is the code agent's biggest job; build it first.

## Common (every agent)

You build part of **phase 1 of Act VIII**, **the Last Line**, of **Necropathy** (Godot 4.3, GDScript, Vampire Survivors
genre): the last great cities of the living fight back, in rising order: the gangs who own the blocks, then the police,
then the army, and at the end the superheroes. The design is `docs/act8/PROPOSAL.md` (owner-approved; read it in full).
**The owner's answers at its top override the body:**

- **No Wanted Level:** the escalation is a plain clock (gangs → police → SWAT and the Guard → army → heroes). No stars,
  no radio masts, no "cut the comms". **The three shared rules are Armour, Supers and Civilians.**
- **Civilians** flee through the streets from the start; the army kills them like any enemy; each drops XP. No sparing,
  no penalty.
- **City-block maps:** a grid of rectangular building blocks with streets and narrow alleys, not scattered obstacles.
- **Supers are open parody nods** (no trademarked names, logos, emblems or exact costumes); **no real cities, agencies,
  insignia or flags** anywhere.
- **Police lights pulse slowly** (at most 1 Hz, a soft fade, never a full-screen flash; photosensitivity).
- **No epilogue part or closing card.** **Concept art is approved:** `art_source/concepts/act8_*.png` and their prompts.

### Read first
1. `CLAUDE.md`. It wins any conflict. In particular:
   - document every variable;
   - tunables only in `scripts/data/*.gd`, tagged `# TUNING (not in GDD)`;
   - static typing and determinism;
   - one path per modifier;
   - no physics engine for units: the spatial hash and `Arena` push-out only;
   - no shader may read the screen, and prefer textures over polygons redrawn every frame;
   - never call `AudioServer.add_bus()`;
   - **summons never get act-only rules**: the act's rules act on enemies, vehicles, hazards and the ground;
   - co-op reads the necromancer through the bound slot.
2. `docs/GDD.md` §15.0: the Act VII rows, from "Act VII foundation (phase 1)" to "Act VII playtest pass 2", and
   "Building the rest of the planned content".
3. `README.md` and `docs/act7/BRIEF_FOUNDATION.md`.

### Process rules
As in Act VII, with these Act VIII specifics:
- Shared-file blocks are headed `# --- Act VIII: the Last Line ---` and go at the END of what they extend.
- **The base commit is `29f3fbf`** (later commits on this branch are docs only; the gate sees no difference).
- End each dict entry or `match` arm with a line unique to it.
- Commit messages end with exactly:

  ```
  Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
  Claude-Session: https://claude.ai/code/session_01TjA5CNwUWb95gMazj5Z3qp
  ```

- **Do not push.** Never read or print any API key.

### Fixed names (do not rename)
- **Stages:** act 8, STAGE keys `city` (true) and `blocks` (the city-block layout, below).

  | Stage id | Stage | Boss id |
  |---|---|---|
  | `skid_row` | Stage 22, Skid Row | `don_marrow` |
  | `fort_kessler` | Stage 23, Fort Kessler | `harrow` |
  | `liberty_heights` | Stage 24, Liberty Heights | `paragon` |

- **The escalation tiers** (ids, in order): `gangs`, `police`, `swat` (SWAT and the Guard), `army`, `heroes`.
- **Shared enemy kinds:**
  - `civilian`: not a fighter. Flees, never attacks; male and female looks (`city/civilian`, `city/civilian_woman`).
  - `street_thug` (gangs): fodder; bats and pipes, in crowds.
  - `gang_gunner` (gangs): ranged fodder; pistols sprayed sideways while walking in; poor aim, many bullets.
  - `riot_cop` (police): soldier; shield and baton in a line. The shield is a front (`armour_front`); tear gas that
    slows summons is phase 2's.
  - `squad_car` (police): a vehicle (Armour); drives a street lane and runs over what is in it.
  - `swat_breacher` (swat): soldier; a flashbang that stuns summons in a circle for 1 s, a shotgun.
  - `field_medic` (swat): support, **female, figure style**; heals soldiers near her through the existing enemy-heal path.
  - `rifleman` (army): ranged; squads of 4, short bursts while advancing.
  - `tank` (army): a vehicle; front armour and flat armour, a cannon shell with a landing circle.
  - `blitz` (heroes): the reference Super, male; a speedster who dashes through the ring and can't turn mid-dash.
    "Fast. Can't turn." Phase 2 adds Atlas, Aurora and Nightjar (Liberty Heights) on the same base.

  The Machine Gunner, the Attack Helicopter and the bosses' allies are stage kinds for phase 2. Sprite keys are
  `city/<id>` in `assets/sprites/city/`: a still plus a walk strip (a drive strip for vehicles, a dash strip for Blitz),
  with an idle strip for each figure-style female.
- **Structure:** `city_wreck` (a burning vehicle wreck), sprite `structures/city_wreck` with `_burnt`.
- **Palette:** constants in `scripts/data/palette.gd` (Agent A); ramps in `tools/palette.json` (Agent B), exactly:
  - asphalt: `CITY_INK` #101114 (outline), `CITY_ASPHALT_DARK` #1E2024, `CITY_ASPHALT` #3A3D44;
  - concrete: `CITY_CONCRETE` #55595F, `CITY_CONCRETE_LIGHT` #7A7F87;
  - neon: `CITY_SODIUM` #E8A43A, `CITY_NEON_PINK` #FF4FA8, `CITY_NEON_CYAN` #3FE0E8;
  - olive: `CITY_OLIVE_DARK` #4B5330, `CITY_OLIVE` #6B7545, `CITY_HAZARD` #F2C418;
  - siren: `CITY_POLICE_BLUE` #2E5FD0, `CITY_SIREN_RED` #D82A2A, `CITY_HERO_ORANGE` #F07A1E.

  Gold keeps its meaning (evolution, chest, victory); crimson stays danger.
- **Music:** key `siren`, score `SoundData.SIREN_SCORE`, "Sirens at Midnight".
- **City sound ids:** `siren_wail`, `gun_burst`, `engine_rev`, `vehicle_wreck`, `crowd_panic`, `super_arrive`,
  `weakness_crack`, `tier_alarm`.

## Agent A: the foundation code (branch `act8-foundation`, worktree `/home/user/wt/act8-foundation`)

- **Scratch dir:** `/tmp/claude-0/-home-user-Vampire-Survivors-Clone-Lol/b0031aa1-78e2-5d60-8763-4014a0c61c3c/scratchpad/act8/foundation/`
- **CPU:** at most 2 Godot processes at once.

### Also read
- The Act VII code you copy the shape of: `scripts/enemies/court/` (`court_rules.gd`, `bloodfeast.gd`, `night_wings.gd`,
  `blood_moon.gd`, `endless_feast.gd`, `court_kit.gd`), `court_enemy_data.gd`, `court_rules_data.gd`,
  `ravensmoor_stage.gd`, `CourtGround`, `CourtGlyphs`, `CourtReport`, `EnemyDirector.court_def()`.
- Act IV's Phalanx: `PantheonRules.directed_hit_mult()` and its one call in `CombatResolver.damage_enemy()`. Armour's
  front is built the same way.
- `scripts/core/arena.gd`, `scripts/data/arena_data.gd`, `spatial_hash.gd`, `scripts/horde/stance_formations.gd` (the
  ring posts go through `Arena.free_point()`), and the Assembly Halls' `free_bands` and Ul-Thalos' `shore` (the two
  earlier layout hooks).
- The flat armour path (`Enemy.flat_armor`), the miniboss bar (`EnemyDirector.set_miniboss()`), the summon target score
  (`SummonedUnit._score_enemy()`, the row's `target_priority`), the stage select, the Codex and `autotest.gd`.

### What you build

**Stages.** Three registered stub stages: `skid_row_stage.gd`, `fort_kessler_stage.gd`, `liberty_heights_stage.gd`.
- act 8, `"playable": false`.
- The unlock chain: Skid Row opens on Carmilla (`castle_sanguis`, boss kills 1), then each stage opens the next.
- Boss ids in `StageRegistry.BOSS_ARRIVALS`, each with a placeholder `script` until
  `scripts/enemies/city/boss_<id>.gd` exists.
- Zone names from the proposal.
- A placeholder timeline of the shared kinds on the escalation clock (below).
- A placeholder floor `CityGround` (docks asphalt, base concrete, downtown plaza) and buildings `CityGlyphs`.
- Music key `sanguine` for now, with a comment that the lead switches it to `siren` at the merge.
- Soul Ash ×1 / ×1.25 / ×1.5.
- Enemy HP and damage a step above Castle Sanguis's (HP ×2.0, damage 1.5); the step goes in HP.

**Stage select.** An **Act VIII** tab; eight tabs must fit at 1280 × 600 layout px. Check a screenshot.

**Faction data.**
- `CityEnemyData` holds the shared kinds and `city_wreck`; `SkidRowEnemyData`, `FortKesslerEnemyData` and
  `LibertyHeightsEnemyData` are empty, looked up by `EnemyDirector.city_def()` after `court_def()`.
- Kits load by name from `scripts/enemies/city/<id>_kit.gd` through a `CityKit` base; Supers through `SuperKit`
  (extends `CityKit`).
- Row keys:
  - `tier` (String, one of the tier ids; the Codex and the report group by it);
  - `armour_front` (float 0..1, the share cut from a hit landing on the front; 0 = none);
  - `vehicle` (bool: drives lanes, runs over, leaves a wreck);
  - `super` (Dictionary: `power` and `weakness`, the two short plate lines, plus the weakness numbers);
  - `civilian` (bool: flees, never attacks).
  Flat armour uses the existing `flat_armor` key and path; add no second one.

**The city-block layout** (`CityBlocks`, `scripts/core/city_blocks.gd`, numbers in `scripts/data/city_block_data.gd`).
ONE path: `Arena` owns it. When the stage's zone layout carries a `blocks` dictionary (the STAGE `blocks` defaults
merged in; `{}` = defaults), `Arena.obstacle_at()` asks `CityBlocks` instead of the per-cell scatter. Everything else
already goes through `obstacle_at()`: `resolve_all()` push-out and slide, `free_point()`, `is_blocked()`,
`clear_length()`, `avoid_vector()`, spawns, recalls and landings. No physics engine; no stage without `blocks` changes.
- **The grid.** The plane is tiled with lots of one building each, axis-aligned rects. The gaps between buildings
  alternate in each axis: a **street** 192 px between faces (a 144 px roadway, two 24 px sidewalks), then an **alley**
  80 px between faces, then a street. So a block is 2 × 2 buildings with a cross of alleys through it. Buildings are
  256 × 192 px (lot pitch 392 × 328 px). All TUNING; the stage may override any of them.
- **One lookup per body, analytically.** Lot index = floor(pos / pitch); the building of that lot is the only one a body
  in it can touch, because half an alley (40 px) is more than any body radius. State that invariant in
  `CityBlockData.MAX_BODY_RADIUS` (36 px) and `push_error()` at stage load for any kind on the stage whose radius is
  above it. Lots are cached like cells; co-op drawing uses the uncached `_peek()` path, as now.
- **Open lots.** A seeded share of lots (default 0.2, by `layout_seed`) has no building: plazas, parking lots, a park.
  The run's start keeps `clear_radius` open as today; keep the start on a crossing of two streets next to an open lot.
- **Zones** keep the grid and change only the building looks and the open-lot share, so a zone change never moves a
  street. A body caught in a new building is pushed out by the next `resolve_all()`, as today.
- **The Bone Ring in streets.** The ring's radius is 60-150 px, so a large ring does not fit in a street and some posts
  fall inside buildings. On a `blocks` layout only, ring posts go through `Arena.free_point_toward(post, necromancer,
  r)`: a post inside a building is pulled back along the line toward the necromancer to the first free point, so the
  ring flattens along the street instead of sending summons around the block. With no `blocks` it is exactly
  `free_point()`, so stages 1-21 are unchanged. This is terrain, not a summon rule.
- **Spawns stay in streets.** Spawn points go through `free_point()` as now; check that no kind spawns stuck in an alley
  dead end (there are none in the grid, keep it that way).
- **Pathing.** Enemies keep advancing straight at the nearest necromancer and slide along faces through the existing
  slide memory. Measure it: report the seconds enemies spent in contact with a building face per minute. If enemies pile
  against faces, add ONE documented street-steering hint, `CityBlocks.street_dir(pos, target)`, read by the enemy
  advance step and the autotest bots only on a `blocks` layout. Never a navmesh.
- **Lanes.** `CityBlocks.lane(pos, dir)` returns the street centre line through `pos` along `dir` (vehicles, artillery
  lines and phase 2's Hearse Run use it).
- **Wrecks.** `CityBlocks.add_wreck(pos, half)` places a wreck obstacle (rect, half-size at most 28 px) snapped to the
  centre of its 128 px wreck cell, only in a street and only if it fits; at most one per wreck cell, at most 24 in all
  (the oldest burns away). `obstacle_at()` returns the building of the lot or the wreck of the wreck cell, whichever the
  body overlaps more. Wrecks are seeded only by game events, so the layout stays deterministic.
- **Drawing.** `CityGround` draws asphalt, lane lines, crosswalks, curbs and alleys from the same `CityBlocks` geometry;
  `Arena` draws each building in view as tiled rooftop textures through `CityGlyphs.draw_building()` (the
  `tiles/city_roof_<style>` PNGs when present, else the code glyph). Textures only, no polygons redrawn every frame.
  Buildings do not block shots or spells, like every obstacle.

**The shared rule object.** `game.city` (`CityRules`), created only when the STAGE has `city`. It is null on Acts I-VII,
so stages 1-21 keep their same-seed summaries. A City kind forced onto another stage with `--spawn=` creates it on first
activation (as `Game.court_rules()` does), with the escalation, the civilians and Martial Law off there. Its numbers live
in `scripts/data/city_rules_data.gd`.

**The escalation** (`Escalation`, owned by `game.city`, a clock path). It holds the current tier for the HUD and the
report; the timeline itself spawns the tier's kinds, as on every stage.
- Default tier times (elapsed): `gangs` 0:00, `police` 4:00, `swat` 8:00, `army` 12:00, `heroes` 15:00. From
  `heroes`, a Super arrives every 90 s, at most one alive.
- A tier badge on the HUD and a banner 10 s ahead ("The police are coming"), with `tier_alarm`.
- The STAGE key `escalation` overrides the times and the last tier. Phase 2 sets each stage's ladder from the proposal's
  stage caps (Skid Row up to SWAT, Fort Kessler up to the army, Liberty Heights from the army to the heroes); the
  foundation's stubs all use the full default ladder so every rule shows.
- Police lights: a slow texture pulse on the car (`CityRulesData.SIREN_PULSE_HZ` ≤ 1.0), never a screen effect.

**The three shared rules, one code path each:**

1. **Armour** (`Armour`, owned by `game.city`).
   - **The front.** `CityRules.armour_mult(e, origin, shot, source)`, called once in `CombatResolver.damage_enemy()`
     after the Phalanx block, only when `game.city != null`, the hit has an origin and the row has `armour_front` > 0. A
     hit inside the front arc (±60° of the facing) is cut by `armour_front`; arcing and from-above hits ignore it. One
     facing test, like `PantheonRules.hit_from_front()`.
   - **Vehicles** (`Convoy`). A `vehicle` kind drives straight along a street lane (`CityBlocks.lane()`) toward the
     necromancer's street, with headlights showing its lane 1 s ahead (a texture strip). It runs over everything in the
     lane: summons through `CombatResolver.damage_unit()` with a sideways knockback, the necromancer through
     `damage_player()` (Grave Step's i-frames dodge it). At the lane's end it turns and comes again. It is an enemy
     attack, not a summon rule.
   - **Wrecks.** A vehicle that dies becomes a burning `city_wreck` through `CityBlocks.add_wreck()`, solid for the rest
     of the run, and explodes 3 s later, hurting both sides within 64 px through `CombatResolver`. Off a `blocks` stage
     there is no wreck; it only explodes. A vehicle that rams a wreck stops and takes damage.
   - Hook for **Kevlar Bones** (summons take less ranged damage from City kinds): one multiplier, default 1.0. Do not
     build the passive.
2. **Supers** (`SuperKit` and `SuperRoster`, owned by `game.city`).
   - A Super is an elite with a **plate** over it: its name, its power and its weakness ("Fast. Can't turn."), drawn as
     a label texture, and the HUD miniboss bar through `set_miniboss()`.
   - **Guarded and exposed.** Until its weakness is triggered a Super takes ×0.6 damage (`SuperKit.taken_mult()`). The
     weakness calls `SuperKit.expose(e, seconds)`, the one path: stunned 1 s, then ×1.5 damage taken for 4 s, a
     `weakness_crack` sound and a crack mark. Reading the weakness beats raw damage.
   - **Blitz:** dashes along a street through the ring; he cannot turn mid-dash, and a dash that ends on a building face,
     a wreck, a Bone Wall segment or a blocker summon exposes him.
   - **Met list.** `SuperRoster.met` keeps every Super the run has met, alive or dead (for Paragon's Hope and Martial
     Law); `SuperRoster.call(id, at)` brings one in. Phase 2 adds Supers as rows plus kits.
3. **Civilians** (`Civilians`, owned by `game.city`).
   - At 0:00 a crowd (default 36) appears in the streets beyond the clear radius, then a trickle (one every 2 s, at most
     24 alive) until the `army` tier, when the city is evacuated. The STAGE key `civilians` overrides it.
   - They flee: away from the nearest necromancer and the nearest summon, along streets (`CityBlocks.lane()`), and are
     recycled with no XP past 900 px from every necromancer. The one exception to "enemies always advance", owner-approved.
   - They never attack, never body-block the ring and are never hit by the city's own forces.
   - The army kills them like any enemy. **Summons treat them as ordinary enemies with the row's `target_priority` 0**
     and never `targeting_player`, so the existing target score ranks every threat above them; no summon code changes.
   - A kill goes through the normal kill path: an XP crystal (fodder value), Rally charge, kill counts. No sparing, no
     penalty, no Soul Ash line.
   - Their own alive cap; they never take a slot from the enemy cap. In co-op they flee from the nearest necromancer.

**The Reckoning, Martial Law.** At 0:00 every tier's kinds spawn at once; artillery walks across the arena in
telegraphed lines of shell circles along the streets, hurting both sides; every Super in `SuperRoster.met` returns, one
every 20 s. Tune it through the RECKONING `martial_law` keys; the heavy is the `tank`.

**Codex.** A **Last Line** tab, grouped by tier.

**Sounds.** A map in `city_rules_data.gd` that points at existing sounds for now, with the intended ids in comments.

**Autotest.**
- Flags: `--stage=skid_row|fort_kessler|liberty_heights`, `--spawn=` with the new kinds, `--boss=don_marrow|harrow|paragon`.
- A `CityReport` with these lines:
  - `city blocks`: lots and open lots built, building push-outs, ring posts pulled toward the necromancer, building
    contact seconds per minute, wrecks placed and burnt away;
  - `armour`: front hits and damage cut, flat armour absorbed, vehicles driven, run-overs on summons and the necromancer;
  - `supers`: arrived, exposed (by what), damage taken exposed and guarded, met list;
  - `civilians`: spawned, fled, killed by the army, XP dropped;
  - `escalation`: the time each tier began;
  - `city kinds`;
  - `city stage`.
- The army bot keeps out of headlight lanes if it is cheap to add (one `danger_push()`-style behaviour).

**Gate.** Stages 1-21 keep their same-seed summaries.
- `docs/act8/tools/gate.sh` is written: Act VII's script plus a `castle_sanguis` army run.
- Base is `29f3fbf`. Only catalog counts and "stages unlocked by this run: skid_row" (after Carmilla) may differ.

**Playability.**
- Each stub, run `--policy=army --mortal`, reaches 0:00 with zero errors and `stuck_units=0`, and all three rules and
  the city blocks show activity in the summary.
- Also run one clean default Graveyard run, one `--mortal` run and one co-op bot run on a stub (the lots must match on
  both slots).

**Screenshots** at 1280×720 under xvfb: the city grid with streets and alleys, the Bone Ring at 20 and at 45 summons
flattened in a street and round at a crossing, a vehicle with its headlight lane and a wreck, Blitz's plate exposed,
fleeing civilians, and the Act VIII tab. Look at them yourself.

**Shared files you may touch:**
- everything listed under "Also read" (`arena.gd` and `stance_formations.gd` only through the `blocks` branch);
- `palette.gd` (the CITY block);
- `codex_data.gd`, `autotest.gd`;
- `README.md`, `docs/GDD.md`.

Not `sound_data.gd`, the synth files or `tools/palette.json`.

**GDD rows:** "Act VIII foundation (phase 1)", "City blocks", "Armour", "Supers", "Civilians", "The escalation".

## Agent B: the art (branch `act8-art`, worktree `/home/user/wt/act8-art`)

- **Scratch dir:** `.../scratchpad/act8/art/`
- **CPU:** at most 1 Godot process.

**Read:** as Act VII's Agent B, and the ART_BIBLE Act VII section as the model. The approved concepts are
`art_source/concepts/act8_lineup.png`, `act8_boss.png` and `act8_stage.png`, with their prompts.

**Rules for this act:** **every prompt names the figure's sex.** Male gangs, police, SWAT and soldiers are in the
original style; every female kind (the field medic, the woman civilian, phase 2's female Supers) is in the
figure-redesign style (an exaggerated hourglass, glamorous, **chest and hips covered**, never nude). No real badges,
flags, letters or place names: uniforms read by colour and shape. Supers carry no emblems, logos, letters, bat shapes or
lightning bolts (the concept redo is the rule).

**What you make:**
- **Ramps.** The `asphalt`, `concrete`, `neon`, `olive` and `siren` ramps in `tools/palette.json`, with exactly the
  Fixed-names hex values and their roles. Add a `city` folder to `prepare_sprite.py`'s `FACTION_RAMPS`.
- **Sprites** for the shared kinds, each a still plus a walk strip (drive strips for vehicles, a dash strip for Blitz):

  | Sprite | Size | What it is |
  |---|---|---|
  | `civilian` | ~28 px | male; ordinary clothes, running in panic |
  | `civilian_woman` | ~28 px | **female**, figure style; ordinary clothes, running |
  | `street_thug` | ~30 px | male fodder; hoodie, bat |
  | `gang_gunner` | ~30 px | male; bandana, two pistols |
  | `riot_cop` | ~44 px | male; black riot armour, clear shield, baton |
  | `squad_car` | ~64 px | a police car, no markings but colour; light bar drawn unlit (the code pulses it) |
  | `swat_breacher` | ~44 px | male; helmet, visor, vest, shotgun |
  | `field_medic` | ~44 px | **female**, figure style; white-and-green medic uniform, satchel |
  | `rifleman` | ~40 px | male; olive drab, helmet, rifle |
  | `tank` | ~80 px | an olive tank, turret readable from the top-down view |
  | `blitz` | ~44 px | male speedster; orange-and-white suit, winged silver helmet, goggles |

  The two female kinds get a `bust` rig, the hip `swish` and an idle strip.
- **Wreck.** `structures/city_wreck`, burning, and `_burnt`.
- **The city blocks.** Tiling rooftop textures for the buildings, `tiles/city_roof_<style>` (`tenement`, `warehouse`,
  `bunker`, `tower`): a tileable centre plus edge and corner pieces (a parapet), with small rooftop details (vents, AC
  units, a water tank) as separate decal sprites so roofs do not repeat. Street tiles: `tiles/city_street` (asphalt with
  lane lines), `tiles/city_crosswalk`, `tiles/city_sidewalk` (curb edge), `tiles/city_alley`, `tiles/city_plaza`. Strict
  top-down, as in `act8_stage.png`; sizes fit the Fixed grid (buildings 256 × 192, streets 192, alleys 80).
- **Data and docs.** Your Act VIII blocks in `sprite_data.gd` and `walk_cycle.py`, an ART_BIBLE section "Act VIII: the
  Last Line, the shared kinds and the city blocks" and a GDD row "Act VIII art: the shared kinds and the city blocks".
- **Generation.** Use `GEN_LEDGER=/home/user/wt/act8-art/docs/art/generation_ledger.csv python3 tools/gen_image.py ...`,
  with the approved concepts as references. Commit the ledger rows. Budget about $0.55.
- **Checks.** Run `art_check.py`, look at every sprite at game size, tile the roofs and streets on a 1280×720 mock of the
  grid to check the seams, and make a contact sheet.

**Shared files you may touch:** `tools/palette.json`, `tools/prepare_sprite.py`, `sprite_data.gd`, `tools/walk_cycle.py`,
`ART_BIBLE.md`, the ledger (append only) and `docs/GDD.md` (your row).

## Agent C: the music and sounds (branch `act8-audio`, worktree `/home/user/wt/act8-audio`)

- **Scratch dir:** `.../scratchpad/act8/audio/`
- **CPU:** at most 1 Godot process.

**Read:** as Act VII's Agent C, plus the GDD row "Waltz of the Red Moon and the Court sounds".

**What you make:**
1. **"Sirens at Midnight"** (`SoundData.SIREN_SCORE`, key `siren` in `SCORES`): a dark urban night track, a driving
   drum-machine beat, a sub bass, a minor synth arpeggio, low brass stabs for the army, and a distant siren as a slow,
   soft pitch glide (never shrill, never fast). It is synthesized and score-driven, and may add score jobs as Acts V to
   VII did. **The loops of Acts I-VII and the startup bank stay identical sample for sample**: give it its own seed and
   render it lazily.
2. **The City sound pack** (`SoundData.CITY_SOUNDS`, lazy with `siren`, its own seeds):

   | Id | Sound |
   |---|---|
   | `siren_wail` | a slow, distant siren rise and fall |
   | `gun_burst` | a short dry burst of shots |
   | `engine_rev` | an engine revving up |
   | `vehicle_wreck` | a crunch of metal and a fire whoomp |
   | `crowd_panic` | a short alarmed crowd shout, not graphic |
   | `super_arrive` | a rising whoosh and a bright chord |
   | `weakness_crack` | a glassy crack |
   | `tier_alarm` | a radio squelch and a low klaxon |

3. **Tests.**
   - `--import` clean.
   - A default Graveyard run and a `--stage=castle_sanguis --policy=army` run (seed 7) against base `29f3fbf`, with
     identical `[autotest]` / `[metric]` lines.
   - A headless render check of the score and the pack.
4. **Docs.** A GDD row "Sirens at Midnight and the City sounds" and README lines.

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
