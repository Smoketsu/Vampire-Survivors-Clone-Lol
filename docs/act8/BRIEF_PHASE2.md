# Act VIII phase 2: brief for the three stage agents

The lead wrote this brief after the foundation merged and the owner answered the phase 2 questions (Nov 2, 2026).

Three agents run at the same time, one per stage. Each works in its own worktree on its own branch, made from the lead's
branch that holds the merged foundation (`3f39d0e` or later). The lead has the branches merged and runs one big test pass
afterwards.

This is the Act VII plan: see `docs/act7/BRIEF_PHASE2.md` and, through it, `docs/act6/BRIEF_PHASE2.md`. Read both. The
Act VI brief's "Shared files, testing and process" section applies here unchanged, with three substitutions:
- Act VIII names;
- blocks headed `# --- Act VIII: <your stage> ---`;
- the scratch dir `/tmp/claude-0/-home-user-Vampire-Survivors-Clone-Lol/b0031aa1-78e2-5d60-8763-4014a0c61c3c/scratchpad/act8/<id>/`.

Read this brief in full, then your stage's section.

## Read first
1. **`CLAUDE.md`.** Every convention applies, in particular:
   - no shader may read the screen, and prefer textures over polygons redrawn every frame (the city's crowds already
     cost ~5 ms a tick: watch it);
   - never call `AudioServer.add_bus()`;
   - **summons never get act-only rules.** Grapples, carry-offs, run-overs, stuns and gas are enemy effects on units.
     They go through the existing one paths: `CombatResolver.stun_unit()`, the held / misdirect hooks,
     `TerrainSlow.slow_summon()` and `Convoy.run_over()`;
   - co-op reads the necromancer through the bound slot.
2. **`docs/act8/PROPOSAL.md`.** The owner's answers are at the top: those of Oct 31 and the **phase 2 answers of Nov 2**,
   which override the stage sections and the rewards below them. Your stage's section and its rewards are the spec, with
   these answers applied:
   - **No Wanted Level anywhere and no radio masts.** No stars, no "cut the comms" and no mast structures. The tiers are
     the plain clock (`Escalation`).
   - **No epilogue part, no closing card and no epilogue hook.** No More Heroes only records the clear.
   - **Supers are open parody nods.** No trademarked names, logos, emblems or exact costumes, and no real cities,
     agencies or flags anywhere (no real police or army insignia either).
   - **Police lights pulse slowly**, at 1 Hz at most, as a soft fade and never a screen flash (the squad car's light bar
     is 0.8 Hz; `CityRulesData.ANTENNA_PULSE_HZ` is 0.35).
   - Every prompt names the figure's sex. Female kinds and characters are in the figure-redesign style (clothed; chest
     and hips covered, no nudity).
3. **`docs/GDD.md` §15.0.** Read these rows:
   - the Act VIII rows from "Act VIII foundation (phase 1)" to "Act VIII foundation integration (phase 1)": City blocks,
     Armour, Supers, Civilians, the escalation, the art and the sounds;
   - "Act VIII phase 2: owner answers";
   - the Act VII phase 2 rows ("Ravensmoor (Act VII phase 2)" through "Act VII integration (phase 2)"), for how a stage
     was built last time.
4. **The code.** Read these:
   - `README.md`;
   - your stub `scripts/data/stages/<id>_stage.gd`;
   - the City folder `scripts/enemies/city/`, `city_enemy_data.gd`, `city_rules_data.gd` and `city_block_data.gd`;
   - `scripts/core/city_blocks.gd` and `city_report.gd`;
   - your stage's empty table;
   - the Act VII stage closest to yours (its director, boss and data).
5. **Art.** Read these:
   - ART_BIBLE "Act VIII" (the shared kinds and the city blocks);
   - the owner-approved concepts `art_source/concepts/act8_lineup.png`, `act8_boss.png` and `act8_stage.png` (match
     them);
   - the contact sheet `docs/act8/art_contact_sheet.png` and the grid mock `docs/act8/art_mock_city.png`.

   Convert with `prepare_sprite.py` on the source and the `city/` ramps (asphalt, concrete, olive, hazard, neon_*,
   police, siren_red, hero). Female figures get a `bust` rig, the hip `swish` and an idle strip. Fliers glide or hover.
   Vehicles use the cart rock as their walk strip.

## Extension points of the foundation (use these; do not fork them)
- **The rule object.** `Game.city` (`CityRules`) is created by the STAGE key `city`. It is null on Acts I–VII. Its
  parts are `escalation`, `armour`, `convoy`, `supers`, `civilians`, `shells`, `lamps` and `martial`.
  - `CityRules.blast(pos, radius, dmg, source, both)` is the one area blast. It never hits civilians, bosses or
    structures (`hits_enemy()`).
  - `CityRules.danger_push()` is what the army bot reads to step out of danger. Add your new hazards there, or to
    `Convoy` / `CityShells`, which it already reads.
  - Each stage director goes in `scripts/enemies/city/<id>_director.gd`. It is switched on by its own STAGE key and
    stepped like `RavensmoorDirector`.
- **City blocks.** `CityBlocks` (`game.arena.city_blocks`, numbers `CityBlockData`).
  - `lane(pos, dir)` returns the street centre line. Hearse Run, carpet bombing and the minigun sweep use it.
  - `street_dir()` is the one enemy steering hint; `steer()` is the bot's slide.
  - `add_wreck(pos, half, now)` and `wreck_of(o)` handle wrecks. There is no remove yet: Liberty Heights adds one,
    additively.
  - `free_point()` / `free_point_toward()` find free points, and `set_zone()` changes the looks and the open-lot share
    (a zone never moves a street).
  - **Every body that walks the streets has a radius of at most `MAX_BODY_RADIUS` (36 px, elite size included).** The
    stage-load check covers segments, events, the Reckoning and Supers, but **not bosses**. Keep each boss's and
    miniboss's collision radius within 36 px too, and draw the sprite larger.
- **The escalation and the tier caps.** `game.city.escalation`: `tier()`, `reached(id)` and `time_of(id)` are THE tests.
  - A stage caps its ladder through the STAGE `escalation` dictionary, which overrides any key of
    `CityRulesData.ESCALATION`. `"last"` is the last tier.
  - `"times"` replaces the whole start table. A tier left out of it is skipped, and the order is built from the tiers
    the table holds, up to `last`.
  - The escalation only holds the tier (HUD badge, banners, report). From `heroes` it also sends a Super every 90 s
    (`SuperRoster.call_next()` over STAGE `supers`). **Your timeline spawns only your tiers' kinds**; Martial Law's
    RECKONING `companions` still bring every tier.
  - The civilians' trickle stops when the `army` tier begins, so it never stops on Skid Row (intended).
- **Armour.** `CityRules.armour_mult(e, origin, shot, source)` → `Armour.front_mult()` is called once from
  `CombatResolver.damage_enemy()`.
  - A row's `armour_front` (0..1) is cut from a hit inside ±60° of the kit's `facing`.
  - `Armour.hit_from_front()` is the act's one facing test. Arcing hits (`FROM_ABOVE`) and undirected hits ignore it.
  - Flat armour is the existing `flat_armor` path.
  - Any new shielded or armoured row uses `armour_front`: the limo, Mammoth, Harrow's armour, a SWAT shield.
  - **Kevlar Bones** is hooked already: `Armour.kevlar_mult(source)`, read once in `damage_unit()` (PassiveData
    `kevlar_bones` / `CityRulesData.KEVLAR_KEY` `ranged_reduction`). A ranged City hit is a `ranged` row's kind id or a
    `CityEnemyData.RANGED_SOURCES` tag. **Add every new ranged source tag to `RANGED_SOURCES`** in your own block: the
    machine gun, the helicopter's rockets, the minigun, the carpet bombs, Aurora's blasts.
  - **Armour-Piercing Bones** is not built. Fort Kessler builds it, in ONE place: inside `Armour.front_mult()`, the
    row's `front` becomes `front × (1 − v)`.
    - `v` is the bound player's `game.abilities.passive_value(CityRulesData.ARMOUR_PIERCING, CityRulesData.PIERCE_KEY)`
      (`"armour_piercing_bones"` / `"front_pierce"`, new constants beside the Kevlar ones).
    - It applies only when the hit's `source` is a summon-class source (`SynergyData.SOURCE_CLASS.has(source)`; volleys
      carry their class's source). Spells, the necromancer's own attacks and flat armour are unchanged.
    - The result is exactly 1× when the passive is not owned. Count `armour_pierced_dmg`.
- **Supers.** One base, `SuperKit` (extends `CityKit`), plus `SuperRoster` (`game.city.supers`).
  - A Super is an `always_elite` row with `super` (its plate text, and optionally its stun and window).
  - It stays guarded (×0.6 damage taken) until `SuperKit.expose(e, by)`. That is THE path: a 1 s stun, then ×1.5 for
    4 s, the crack and the sound. Each Super's weakness calls `expose()` with its own `by` tag.
  - `call_super(id, at)` brings a Super in and adds it to `met`. `call_next()` brings the stage's next one.
  - Supers take the HUD's miniboss bar when no miniboss stands. A stage miniboss Super registers through
    `EnemyDirector.set_miniboss()` as usual.
  - Blitz (`BlitzKit`) is the model for the other Supers.
- **The Convoy and vehicles.** A row with `vehicle` gets the drive in `CityKit`: it snaps to a lane, drives past the
  necromancer by 520 px, turns, shows headlights 1 s ahead and rams wrecks.
  - `Convoy.run_over()` is the one run-over path (`run_damage`, every 1.2 s per body).
  - A dead vehicle becomes a burning wreck that explodes 3 s later (`Convoy.wreck_vehicle()`).
  - Vehicles skip the ring's body-block. Run-over boxes come from `half_length()` / `half_width()` (car 52 × 26, tank
    68 × 44).
- **CityShells** (`game.city.shells.add(at, delay, radius, dmg, source, both, stun)`) is THE telegraphed landing circle
  (blasts and flashbangs). Every new one goes through it: Mammoth's turrets, the carpet bombing, the rocket pods,
  Atlas's thrown wreck, Paragon's craters, the minigun's sweep if it lands as circles.
- **Civilians.** `game.city.civilians` (`Civilians`, `CivilianKit`, STAGE `civilians` overrides `CityRulesData.CIVILIANS`)
  handles the opening crowd of 36 at 0:00, then the trickle until `army`. No sparing and no penalty. They flee along the
  streets, leave once 900 px from every necromancer, and are never healed, never blasted and never body-block.
- **Martial Law** (`MartialLaw`) is the shared Reckoning. Tune it only through your stage's RECKONING `martial_law` keys
  and its `companions`. It brings back only the Supers in the met list.
- **Kits and bosses.** Extend `CityKit` (or `SuperKit`). Put kits in `scripts/enemies/city/<id>_kit.gd`; ids must be
  unique across all seven kit folders.
  - Put bosses in `scripts/enemies/city/boss_<id>.gd` (`don_marrow`, `harrow`, `paragon`), and remove your stub's
    placeholder `"script": "vael"`.
  - Minibosses register through `EnemyDirector.set_miniboss()`.
  - New shared kinds are rows in `CityEnemyData` (your own block at the end), so any stage may use them. Stage-only
    things go in your stage's table: `SkidRowEnemyData`, `FortKesslerEnemyData` or `LibertyHeightsEnemyData`.
- **Sounds.** `CityRules.play_sound(event, pos, gap)`, with events mapped in `CityRulesData.SOUNDS`. New sounds go in
  your own block at the END of `SoundData.CITY_SOUNDS`; pack seeds depend on order, so never insert in the middle. Map
  their events in your own block at the end of `CityRulesData.SOUNDS`.
- **Report:** a stage block in `CityReport.print_lines()`. **Codex:** the `CodexData.CITY_*` tier lists (new kinds
  under their tier; minibosses as Act VII placed theirs) and the achievement → counter-passive map (`"coffin_nails":
  "silver_bones"` is the model).
- **Unlocks, spells, characters, classes, counter-passives and achievements** work as in Acts VI–VII:
  - `UnlockData` / `Unlocks` and the one `NecroSpellBook` dispatch. A spell works on every stage: off a blocks layout,
    a "lane" is the straight line through the necromancer.
  - `character_data.gd`, with a Hyper skin and the Untouchable and Deathlord skins.
  - One `SummonBehavior` per class that works the same on every stage.
  - PassiveData rows offered only in Act VIII through the card row's `act`.
  - Each new class's Ossuary mastery in `mastery_data.gd`, and the price total in `tools/ossuary_check.gd`.
  - **Ids must not collide with enemy kinds, structures or source tags.** Check `city_enemy_data.gd` and your table. For
    example, the spell `bone_mines` against Fort Kessler's `kessler_mine`, and the class `fallen_hero` against any Super
    row.

## The new kinds and the Supers, split across the stages
The foundation built `civilian`, `street_thug`, `gang_gunner`, `riot_cop`, `squad_car`, `swat_breacher`, `field_medic`,
`rifleman`, `tank` and `blitz`. The rest of the proposal's roster is built by one stage each, as rows in `CityEnemyData`
(your own block at the end) with their kits. Any stage may then use them.
- **Skid Row:** no new roster kind (it stops at SWAT). It finishes the police tier's missing piece, the Riot Cop's
  **tear gas** (the data's "Phase 2 adds the tear gas"): a short gas cloud thrown at the ring that slows summons through
  `TerrainSlow.slow_summon()`, the one ground-slow path. It edits only `riot_cop_kit.gd` and the cop's row.
- **Fort Kessler:** the **Machine Gunner** and the **Attack Helicopter** (both army tier).
- **Liberty Heights:** the three remaining Supers, **Atlas**, **Aurora** and **Nightjar** (heroes tier). With Blitz,
  they are the stage's four zone minibosses.

---

## Agent A: Skid Row (`skid_row`, Stage 22)
Branch `act8-skid-row`, worktree `/home/user/wt/act8-skid-row`.

- **Stage:** the docks and back streets, where the dead first come up out of the sewers. Zones: the Alleys, the Night
  Market, the Overpass, the Precinct.
  - The zones are looks over the same block grid (`set_zone()`): four roof / decal styles, lit market stalls in open
    lots, overpass pillars as decals, a precinct roof. No masts.
  - The STAGE `escalation`: `"last": "swat"` (gangs 0:00, police 4:00, SWAT 8:00, or your tuned times). The timeline
    holds only gang, police and SWAT kinds. Martial Law's companions keep every tier.
  - **Balance.** On seed 7 the foundation's army bot died at ~12:00–13:00 once the SWAT tier started at 8:00 (lowest HP
    2%). It is marginal: seeds 1 and 2 win (17%, 90%), and the foundation's own runs died in three of six. With the
    army tier gone, balance the stage so the army bot ends healthy, as Ravensmoor's agent did. Do it through Skid Row's
    own data first: segment weights and counts, the SWAT start, the breacher and medic share, the HP and damage
    scaling. Change a shared row only with a GDD note (Fort Kessler uses the breacher too). Check seeds 7, 1 and 2 with
    `--mortal`, one process at a time.
  - **Wrecks** (you own this fix): the wreck's collision rect is 52 × 36 (`add_wreck` half 26 × 18), but the burning
    wreck sprite `structures/city_wreck` is only 32 px wide (× 34), so bodies stop on air. Redraw `city_wreck` and
    `_burnt` to cover the 52 × 36 rect. Don't shrink the rect: the integration's trial of the art's size made Skid Row
    harder.
- **Miniboss: Big Sal and the Armoured Limo.** An enforcer who rams the ring while his crew shoots from the windows.
  - The limo is a `vehicle` row with `armour_front` and its run-over box. Its crew fires gang-gunner sprays sideways
    while it drives, and Big Sal rides inside (one body).
  - When it dies it leaves a wreck. Big Sal climbs out for a short melee finish; kill him to end the miniboss.
- **Boss: Don Marrow, the Kingpin** (`boss_don_marrow.gd`, male), three phases:
  - **the Bounty:** he raises a bounty board, a structure that is a priority target. While it stands, gang spawns double
    (Skid Row's director doubles its gang segment counts). Break the board to end it.
  - **the Call** (the lead's call, recorded in GDD §15.0): the police and SWAT tiers arrive at once for the rest of his
    fight. Squads of riot cops, squad cars, breachers and medics come in together and keep coming until he falls. The
    tier badge does not change.
  - **the Last Stand:** he fights from behind the limo's armour (an `armour_front` facing the ring) with a gold-plated
    minigun. It sweeps the arena along telegraphed street lanes (`lane()`), and each sweep is dodgeable with Grave Step.
- **Spell: Hearse Run** (`hearse_run`), unlocked by Don Marrow: a spectral hearse drives a lane through the enemies
  (`CityBlocks.lane()` on blocks; a straight line elsewhere). It evolves into **Funeral Procession** with the paired
  passive **Black Car** (`black_car`).
- **Character: the Undertaker** (male), the city's mortician-mobster, starting with Hearse Run.
- **Counter-passive: Kevlar Bones** (`kevlar_bones`, key `ranged_reduction`, Act VIII only). Build its PassiveData row on
  the existing hook.
- **Achievement: No Witnesses.** Kill every civilian of the opening crowd (the 36 at 0:00) before they flee the streets.
  Add the counters to `Civilians` additively (`crowd_left`, `crowd_fled`): it fails as soon as one of the crowd leaves
  the field. It unlocks **Kevlar Bones**.

## Agent B: Fort Kessler (`fort_kessler`, Stage 23)
Branch `act8-fort-kessler`, worktree `/home/user/wt/act8-fort-kessler`.

- **Stage:** a military base on the edge of the city, the army's last line against the dead. Zones: the Checkpoints, the
  Minefield, the Airfield, the Command Bunker. Use the `bunker` roof style, open lots for the airfield's apron, and sandbag
  and checkpoint decals.
  - The STAGE `escalation`: `"last": "army"` (gangs, police, SWAT, army; tune the times). There are no Supers in the
    timeline.
  - **Minefields:** blinking mines in open lots and on chosen streets of the Minefield zone. They blow up under anyone,
    both armies (`CityRules.blast(..., both = true)`; never civilians). Luring the riflemen over them is the counterplay.
    - ONE ground path, like Act VI's pits: a `Minefields` object of your director with `mine_at(p, r)` and
      `avoid_point(p, r)`.
    - The Bone Ring flows around them through one check in `StanceFormations._place()`, beside the pits' check
      (terrain, not a summon rule).
    - The bot steps off them through `danger_push()`.
    - Mines blink slowly (≤ 1 Hz). The kind or structure id must not collide with the spell `bone_mines` (use, for
      example, `kessler_mine`).
- **Miniboss: Mammoth**, a super-heavy tank with two turrets. It is a `vehicle` with `armour_front` and `flat_armor`,
  and its collision radius stays at most 36 px. Each turret has its own cooldown through `CityShells`, and its wreck is
  the largest of the act.
- **Boss: General Vance Harrow, "the Hammer"** (`boss_harrow.gd`, male):
  - **phase 1:** he commands from a command vehicle (a `vehicle` body) and calls carpet-bombing lines across the arena
    (`lane()` + `CityShells`, like Martial Law's artillery);
  - **phase 2:** a tank column (tanks through the Convoy) and his own power armour (`armour_front`);
  - **phase 3, Broken Arrow:** he orders a strike on his own position, with a 30 s countdown on screen (HUD text, never a
    screen effect).
    - Kill him in time and the strike is called off.
    - Fail and the blast hits everything on screen, his army included, through one documented path. It leaves the
      necromancer badly hurt (the lead's suggestion: down to a share of max HP, never lethal by itself; Grave Step does
      not dodge it) and most of the army gone (summons through `damage_unit()`).
    - Decide what it does to Harrow himself and record it.
- **Kinds:**
  - **Machine Gunner** (army, ranged heavy): he sets up and sweeps a telegraphed fire lane (a gradient texture). Grave
    Step dodges it, and a Bone Wall segment in the lane stops it (`BoneWall.covers()`).
  - **Attack Helicopter** (army, vehicle, flying: the row flag `flies`): it makes strafing runs over the ring along a
    lane, fires rocket pods through `CityShells`, and Gargoyles, Archers and spells answer it. It takes no wreck on a
    building: it crashes onto the nearest street cell.
- **Spell: Bone Mines** (`bone_mines`), unlocked by Harrow: bone mines dropped along the necromancer's path, set off by
  enemies (never by summons). It evolves into **Killing Ground** with the paired passive **Tripwire** (`tripwire`).
- **Character: the Fallen Sergeant** (female, figure style), a soldier killed at Fort Kessler, starting with Bone Mines.
- **Counter-passive: Armour-Piercing Bones** (`armour_piercing_bones`, key `front_pierce`, Act VIII only). Build the hook
  in `Armour.front_mult()` as specified above, plus its PassiveData row; you are the only agent who edits `armour.gd`.
- **Achievement: Broken Arrow.** Kill the General before the countdown ends. It unlocks **Armour-Piercing Bones**.

## Agent C: Liberty Heights (`liberty_heights`, Stage 24, the act's finale)
Branch `act8-liberty-heights`, worktree `/home/user/wt/act8-liberty-heights`.

- **Stage:** the heart of the city: the plaza, the skyline and the Heroes' Tower. Zones: the Plaza, the Rooftops, the
  Tower Lobby, the Watchtower. Use the `tower` roof style and more open lots (25%: plazas, fountains).
  - The STAGE `escalation`: the only stage that reaches the heroes. The proposal has it start high, so the lead's
    suggestion is a `times` of `{"army": 0.0, "heroes": 900.0}` (the civilians' trickle then stops at once; the opening
    crowd still flees). Tune it.
  - STAGE `supers`: `["blitz", "aurora", "atlas", "nightjar"]`.
- **The Supers come in turn, one per zone, as its miniboss**, brought in by your director through
  `SuperRoster.call_super()` (so they join `met`) and registered with `set_miniboss()`:
  - Plaza → **Blitz** (built);
  - Rooftops → **Aurora** (female, figure style; she flies);
  - Tower Lobby → **Atlas** (male);
  - Watchtower → **Nightjar** (male, as in the concept lineup).

  The order is the lead's choice: Aurora on the rooftops because she flies, Nightjar on the vigilante's perch. Each
  Super gets one power and one weakness on its plate, and the weakness calls `expose()`:
  - **Atlas** ("Strong. Slow to throw."): he picks up a wreck (add `CityBlocks.remove_wreck()` additively) or a parked
    car and throws it, with a long wind-up and a `CityShells` landing circle. A stun during the wind-up exposes him.
  - **Aurora** ("Flies. Falls when stunned."): an energy blaster on the `flies` flag. Her blasts are ranged sources
    (add them to `RANGED_SOURCES`). Any stun drops her out of the sky, and she is exposed until she rises again.
  - **Nightjar** ("Grapples. Must land to strike."): he grapples summons out of the ring through the held hook, as the
    Chiropteran King's carry-off did. He must land to strike, and a blocker or a stun while he is landed exposes him.
- **Boss: Paragon, the Last Hero** (`boss_paragon.gd`, male; white and silver, blue cape, matching `act8_boss.png`;
  nothing closer to a famous hero), three phases:
  - **the Hero:** flight, heat-vision beams that cut lines through the ring (textures, telegraphed), and a punch that
    sends a summon across the arena (an enemy effect, a shove to a free point);
  - **Hope:** every Super of the stage's roster not killed this run flies in to his side (`call_super()`). Kill them
    earlier and this phase is short. Add a `fallen` list to `SuperRoster` additively.
  - **No Restraint:** he stops holding back. The sky turns white (a blend-mode rect, no screen-reading shader, a slow
    fade), and he dives from orbit onto telegraphed craters (`CityShells`) that crack the arena (decals).

  When he falls, show a short ending text only: the world of the living has no one left to defend it. No epilogue.
- **Spell: Hero's Fist** (`heros_fist`), unlocked by Paragon: a spectral fist slams the strongest enemy and sends it
  flying through the rest. It evolves into **Doomsday** with the paired passive **Secret Identity** (`secret_identity`).
- **Character: the Revenant Heroine** (female, figure style), a raised superheroine, starting with Hero's Fist. Like
  every Act VIII character she has a Hyper skin and the Untouchable and Deathlord skins, and her costume is a nod with
  no emblem.
- **Summon class: the Fallen Hero** (`fallen_hero`, the finale's reward): a raised Super who flies around the ring and
  slams into packs (a class special, the same on every stage). Its evolution is **Black Paragon**; name the paired
  passive and record it. Give it its Ossuary mastery.
- **Achievement: No More Heroes.** Beat Paragon with no Super at his side: every roster Super killed before Hope begins.
  No epilogue: it only records the clear (a title, as Acts VI–VII did).
