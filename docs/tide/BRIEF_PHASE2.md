# The Black Tide phase 2: brief for the three stage agents

Written by the foundation agent at the end of phase 1 (branch `tide-foundation`), for the lead to hand on once the
foundation, the art and the audio are merged. The lead may amend it (the owner's answers win).

Three agents run at the same time, one per stage, each in its own worktree on its own branch made from the lead's branch
that holds the merged foundation. The lead merges and runs one big test pass afterwards.

This is the plan that built Acts V to IX: read `docs/act9/BRIEF_PHASE2.md` (and through it Acts VIII to VI). Its
"Process" rules apply unchanged with Black Tide names, blocks headed `# --- Act X: <your stage> ---`, and **at most ONE
Godot process at a time** (run `pgrep -c Godot` first). The act number is **temporary** (10): the reorder pass moves the
act to slot II. Never write "Act II" for it in code, and never hard-code 10 outside the stage files' `"act"` key.

## Read first
1. **`CLAUDE.md`.** In particular: textures over polygons redrawn every frame (lanes, strike circles, waves, broadsides
   are textures or rects), no screen-reading shader, never `AudioServer.add_bus()`, co-op through the bound slot, and
   **summons never get act-only rules**: the deck, the rail, the drag overboard and every shove are enemy or world
   effects through the existing paths (`DeckBounds`, `held_until`, `stun_unit()`, `TerrainSlow.push_summon()`,
   `damage_unit()`).
2. **The design.** `docs/proposals/NEW_ACTS_AND_ORDER.md` Part 1 (the full proposal) and the Black Tide section of
   `docs/proposals/LAST_SIX_ACTS.md` (it wins where they differ). `docs/last_acts/PLAN.md` (fixed names, tuning for the
   final slot II, no epilogue part and no closing card until the reorder).
3. **GDD §15.0:** the rows from "Act X foundation: the Black Tide (phase 1)" to "The Black Tide (Reckoning)", and the
   Act IX phase 2 rows for how a stage was built last time.
4. **The code:** `scripts/enemies/corsair/` (every file), `corsair_enemy_data.gd`, `corsair_rules_data.gd`, your stub
   `scripts/data/stages/<id>_stage.gd` and its empty table, `scripts/core/corsair_report.gd`, `corsair_ground.gd`,
   `corsair_glyphs.gd`, and the hooks in `arena.gd` (`_fixed_obstacle()`, the deck clamp), `stance_formations.gd`
   (`_place()`), `enemy_director.gd` (the `route_spawn()` calls, `spawn_routed()`, `regular_alive()`) and `game.gd`
   (`corsair_rules()`, `deck`, the camera clamp).
5. **Art:** the approved concepts `art_source/concepts/final5/tide_lineup.png`, `tide_bosses.png`, `tide_stage.png`
   (with their `.txt` prompts), the art pass's `corsair` ramps (`tools/palette.json`; constants `Palette.CORSAIR_*`),
   the ART_BIBLE Black Tide section and `docs/tide/deck_spike.png` / `deck_spike_rail.png` (the deck in the game).
   Every prompt names the figure's sex (or says it is a creature). Female figures are in the figure-redesign style,
   fully clothed (chest and hips covered), with a `bust` rig and an idle strip. Never soul-teal for the water,
   never Gullhaven's drowned green or biolume.

## Extension points of the foundation (use these; do not fork them)
- **The rule object.** `Game.corsair` (`CorsairRules`) is made by the STAGE key `corsair`; `CorsairRules.enabled` is
  true only on an Act X stage with a `deck` (a Black Tide kind forced elsewhere makes the rules with `enabled` false: no
  deck, no boats, no sea, and `routes()` false). Anything stage-only you add checks the stage, not just
  `game.corsair != null`. Parts: `deck` (also `Game.deck`), `boarding`, `sea`, `tide`.
  - `CorsairRules.danger_push(p)`: the army bot's one danger read (the rail, the strike circles, the wave). Add your
    hazards there, additively (barrels about to blow, broadside lines, the fire ship's patches, the Heave's low rail).
  - `CorsairRules.play_sound(event, pos, gap)`: events in `CorsairRulesData.SOUNDS` (your block at the END).
  - `CorsairRules.powder_blast(at, keg, skip)`: THE blast that hurts both sides and knocks everyone `push` px (enemies
    by knockback, so a blast at the rail drowns them). Use it for the Cutter's Powder Barrels and the Gunnery Mate's
    grenadoes if they knock. Not for the Powder Wraith: it is a summon class, so its burst goes through its own
    `SummonBehavior` and `damage_enemy()` (summons never get act rules); it may knock enemies back like any class
    special, and the deck drowns them by itself.
  - Each stage director goes in `scripts/enemies/corsair/<id>_director.gd`, switched on by its own STAGE key, created
    and stepped from `EnemyDirector` like `RavensmoorDirector` / `CrashSiteDirector`.
- **The Deck** (`DeckBounds`, `Game.deck`): THE bounds path. Never clamp anything to the deck yourself.
  - `clamp_point(p, r)` (a negative `r` = a band outside the rail), `walkable_point(p, toward, r)`, `violation(p, r)`,
    `inside(p, r)`, `is_water(p)`, `rail_depth(p)`, `nearest_rail(p)` ([point, outward normal]), `rail_point(x, side)`,
    `straight_rail_length()`, `perimeter_point(s)` / `perimeter_normal(s)` / `perimeter_s(p)`, `camera_point()`.
  - `contain_all()` runs last in `Arena.resolve_all()`: players and walking summons stop at the rail; fliers (summons
    `airborne` / `flies`, enemies `flies`) keep within `flier_band` (120 px) past it; a deck enemy pushed past the rail
    drowns (its centre `drown_slack` px beyond the rail line, or pressed on the rail with outward knockback >=
    `drown_knock` px/s); bosses, minibosses, structures and objectives never drown. **To push enemies overboard, give
    them knockback** (the Heave, a broadside, a ram); to move the necromancer and the army use
    `TerrainSlow.push_player()` / `push_summon()` x `CorsairRules.sea_legs_mult(u)`.
  - The water test is ONE function: `CorsairKit.is_in_water(e)` (a kit's `in_water`). A body in the water is moved by
    its owner only.
  - The stage's deck shape is its STAGE `deck` (any `CorsairRulesData.DECK` key). A quarterdeck step or a raised
    forecastle is furniture (obstacles), not a second outline.
- **Furniture.** The ARENA's `"fixed"` list (`Arena._fixed_obstacle()`): `{kind, at, size, vertical}`; **at most one per
  256 px cell, each at least 80 px (`ArenaData.CELL_MARGIN`) from its cell's edges** (the one-lookup push-out only sees
  the obstacle of a body's own cell). Draw your kinds through `EnvironmentArt` sprites (`obstacles/<kind>_...`) or a
  glyph hook before `CorsairGlyphs.draw_obstacle()`. A zone may change the list through the usual `set_layout()`.
- **Boarding** (`BoardingParty`): THE ONLY SPAWN ROUTE of the timeline on a corsair stage. Every trickle, wave event
  and Reckoning spawn goes through `CorsairRules.route_spawn()`: a crew kind waits in the queue and comes aboard by
  boat (`EnemyDirector.spawn_routed()` at the plank); a `water` kind goes to `SeaStrikes.spawn_swimmer()`.
  - STAGE `boarding`: any `CorsairRulesData.BOARDING` key, `points` ([x, side] on the straight rail), `whole_rail`,
    `boats` (the tier cap; sizes in `BOAT_CREW` / `BOAT_PLANKS`, kinds `skiff` / `longboat` / `raider_ship`).
  - Fields and calls: `boats` (each boat's dictionary: state LANE / HOOKED / DRIFT / LEAVE, `rail`, `n`, `boat`,
    `hooks`, `crew`), `queue`, `enqueue()`, `on_boat_killed()`, `on_hook_killed()`, `waiting()`. A new boat kind is a
    row with `"boat": true` and kit `corsair_boat` plus its `BOAT_CREW` entry (your block at the end).
  - Stage directors and bosses may still spawn with `EnemyDirector.spawn_at()` (it lands on the deck through
    `Arena.free_point()`): a boss's own boarding party, a ram longboat. Say in your GDD row when you bypass the boats.
  - Co-op: `max_boats` and `queue_cap` grow with the co-op alive cap.
- **Strikes from the Sea** (`SeaStrikes`): THE strike scheduler. Swimmers (row `water`, a `strike` dictionary with a
  `type` and any `CorsairRulesData.SEA` override) circle the hull submerged (`Enemy.untargetable`), surface to strike,
  and are capped at 8.
  - Types: `leap` (lands as a deck enemy through `CorsairKit.leave_water()`) and `tentacle` (the grab through
    `held_until` + one `stun_unit(u, hold, "tentacle_grab")`, dragged overboard by `on_unit_died(u, false)`). Add a
    type in your block of `_land()` / `_target()` (the serpent's line breach, the crab's climb) rather than a second
    scheduler.
  - `strike(at, overrides)`: an ownerless circle (the Voodoo Navigator's marks, the serpent, the Reckoning).
  - `grabbable(u)`, `release_all(arm)`, `alive()`, `swimmers`, `grabs`.
- **The Black Tide** (`BlackTide`, the shared Reckoning): tune it only through your RECKONING `black_tide` keys and its
  `companions`. Gunboats' shelling in lines and the kraken surfacing are yours to add there (the Galleon agent adds the
  Gunboat's lines, the Maelstrom agent the kraken), in a block at its end.
- **Counter-passive hooks are built:** `CorsairRules.sea_legs_mult(u)` (Sea Legs, id `sea_legs`, key `drift_cut`;
  read by the powder push and the wave; the Heave and the Grappler's pull must read it too) and
  `CorsairRules.barnacle_mult()` (Barnacle Bones, id `barnacle_bones`, key `sea_damage`; read by
  `CorsairKit.taken_mult()` on boats, hooks and swimmers). Build only the PassiveData rows, Act X only through the
  card row's `act` (Kevlar Bones is the model; mind that the act number is 10 until the reorder).
- **Kits and rows.** Extend `CorsairKit` (`scripts/enemies/corsair/<id>_kit.gd`; ids unique across the nine kit folders).
  Row keys: `crew`, `water`, `strike`, `boat`, `hook`, `keg`, `lunge`, `fodder`, `elite_kind`, `figure`. Shared kinds go
  in your block at the end of `CorsairEnemyData`, stage-only ones in your table (`CutterEnemyData`, `GalleonEnemyData`,
  `MaelstromEnemyData`). Sprites load by key `corsair/<kind_id>`. Fallback glyphs: your block before the shared kinds in
  `CorsairGlyphs.draw_enemy()`.
- **Bosses** in `scripts/enemies/corsair/boss_<id>.gd` (`crow`, `marrec`, `vandermere`; `EnemyDirector.CORSAIR_BOSS_DIR`);
  remove your stub's `"script": "vael"`. A boss on the deck is clamped like any deck body (it never drowns). Minibosses
  register through `EnemyDirector.set_miniboss()`.
- **Report:** a `<id>_report.gd` beside `corsair_report.gd`, called from its "Phase 2" marker, one line in your block.
- **Codex:** `CodexData.CORSAIR_CREW` / `CORSAIR_SEA` / `CORSAIR_BOATS` (and `CORSAIR_BOSSES`); descriptions in your block.
- **Music:** the stubs play `tide` until the lead switches them to the audio pass's `shanty` at the merge.

## The kinds, split across the stages
The foundation built `deckhand`, `musketeer`, `powder_runner`, `swashbuckler` (female, figure style),
`boarding_bruiser`, `reef_shark`, `kraken_arm`, the boats `skiff` / `longboat` / `raider_ship` and the `boarding_hook`.
The rest of the proposal's roster, one stage each:
- **The Cutter:** the **Grappler** (male; a hook line that drags one summon to the rail: an enemy pull on a summon through
  `held_until` + `TerrainSlow.push_summon()` x Sea Legs) and the **Boatswain** (male, support: a bellow of +20% speed and a
  short shield to crew within 200 px through `Enemy.apply_buff()` / `holy_shield`), shared rows; the **Powder Barrel**
  (a structure) and **Bosun Gorran** with the **Ram Longboat** in `CutterEnemyData`.
- **The Galleon:** the **Gunnery Mate** (female, figure style; arcing grenadoes on a landing circle that ignore the ring),
  the **Voodoo Navigator** (female, figure style; marks a strike on the ring through `SeaStrikes.strike()`, cancelled if
  she dies), the **Gunboat** (a boat row that never boards and shells the deck in lines) and the **Hull Crab** (a giant
  swimmer that climbs the hull and boards at the rail band, armour 4: a new strike type), shared rows; **Old Hollow-Eye**
  in `GalleonEnemyData`.
- **The Maelstrom:** the **Sea Serpent** (a swimmer heavy that breaches in a line across the rail band, a new strike type),
  a shared row; the **ghost crew** (spectral deckhands and gunners that DO leave corpses, the act's raise reward) and the
  **Ghost Bosun** in `MaelstromEnemyData`.

The lead may add the later kinds to the other stages' timelines at the merge.

## Balance (from the foundation's runs)
- Tune for the act's **final slot II**: between the Sanctum (HP 1.1) and Ravensmoor (1.85). The stubs use HP 1.3 / 1.4 / 1.5
  and damage 1.15 / 1.2 / 1.25 from 7:00, Soul Ash x1 / x1.25 / x1.5.
- Seed 7 army runs (`--mortal`): all three stubs reached 0:00 untouched (HP 120 / 120 at 20:00, `stuck_units=0`). The
  boarding points are natural choke points: few enemies stand on the deck at once (about 6-16) and the army kills the
  crews as they step aboard. The stubs are probably too easy for slot II; make the stages threaten through their own
  systems (broadsides, the Heave, the swimmers, multiple planks) before raising HP. Reports: the `boarding`, `deck`,
  `sea strikes` and `black tide` lines.
- Drowning is strong in the Reckoning (the waves drowned 19-65 enemies a run) and mild before it (40-110 overboard a
  run, mostly powder blasts). It is the act's counterplay: keep it.
- Each agent checks its own stage on seed 7 (`--policy=army --mortal`); the Cutter agent also seeds 1 and 2 and one naive
  run (it is the act's first stage).

## Agent A: the Smuggler's Cutter (`cutter`)
Branch `tide-cutter`, worktree `/home/user/wt/tide-cutter`.
- **Stage:** a small night-time sloop slips out of a ruined harbour, the Covenant's coast burning behind it. Deck 960 x 360,
  a single mast, one hatch, powder barrels along the rails (the stub's fixed layout is a start). Boarding points: two per
  side. Tier cap: skiffs and longboats. Zones: the Harbour Mouth, Open Water, the Fog Bank, the Cove (the camera does
  not move: the zones change the look and the timeline, not the map).
- **Powder Barrels:** structures stacked against the rails; any hit breaks one: `CorsairRules.powder_blast()` with a
  120 px push (overboard near the rail). Respawn them per zone; count blasts and drownings.
- **The Fog Bank:** boats hidden until 2 s before their lane shows (BoardingParty's lane draw; one flag on the boat
  dictionary, your block), so the stage teaches "watch the rail".
- **Miniboss: Bosun Gorran and the Ram Longboat** (male): a heavy longboat rams the hull (a stagger: every summon knocked
  back through `push_summon()`) before it boards.
- **Boss: Captain Ezekiel Crow, the Gull King** (male): **Broadside** (his sloop alongside, three telegraphed cannon lines
  across the deck every 20 s while his crew boards double), **the Duel** (he swings aboard with a cutlass and a pistol and
  leaps the ring on a landing circle), **the Fire Ship** (he sets his ship ablaze and rams; burning planks spread as short
  fire patches through the Hell Pits ground path, not a new one, until he falls).
- **Rewards:** spell **Chain Shot** (a spectral chain-shot spins through a line and returns) -> **Keelhauler** + passive
  **Bosun's Whistle**; character **the Marooned Quartermaster** (male).
- **Achievement: Not One Aboard** (sink five boats before a single crewman climbs aboard, on the Cutter); suggested unlock:
  the counter-passive **Barnacle Bones** (build its PassiveData row on the hook). Record the mapping in your GDD row.

## Agent B: the Treasure Galleon (`galleon`)
Branch `tide-galleon`, worktree `/home/user/wt/tide-galleon`.
- **Stage:** a captured galleon on open water at dawn: quarterdeck, forecastle, three masts, eight deck cannons. Deck
  1,500 x 540 (the camera scrolls). Five boarding points. Tier cap up to raider ships and gunboats. Zones: the Convoy Lane,
  the Reef, the Storm, the Gun Deck.
- **Broadsides:** every 70 s an enemy galleon alongside fires a 6-line broadside (1.5 s telegraph, both armies; knockback on
  enemies). **The deck cannons** are obstacles the army uses: a cannon any unit stands next to for 3 s fires once at the
  nearest boat (a seeded pick). This is a world rule (any summon or the necromancer), never a class rule. The quarterdeck
  steps are a choke point the ring flows around (furniture).
- **Miniboss: Old Hollow-Eye**, the kraken's arm (tentacles in the rail band, every tentacle grabs: `SeaStrikes` with a
  boss-sized `tentacle`).
- **Boss: Admiral Isabeau Marrec, the Sea Wolf** (female, figure style): **the Fleet** (her flagship's broadsides on a 30 s
  rhythm, a raider ship boards with a plank), **the Boarding** (she leads her marines across the plank; cut both hooks and
  the plank falls with her crew in the water: `on_hook_killed()` / the repel), **Gold Fever** (cursed coins that become
  short barriers round her marines; area damage clears them; then a duel on the quarterdeck).
- **Rewards:** spell **Cannonade** (spectral cannonballs arc down on three marked groups) -> **Dead Men's Broadside** +
  passive **Black Powder**; character **the Corsair Queen** (female, figure style).
- **Achievement: Walked the Plank** (push 200 enemies overboard in one run: the `overboard_total` stat); suggested unlock:
  **Sea Legs** (build its PassiveData row on the hook).

## Agent C: the Maelstrom (`maelstrom`, the act's finale)
Branch `tide-maelstrom`, worktree `/home/user/wt/tide-maelstrom`.
- **Stage:** the ghost ship *Hollow Queen*, caught in a whirlpool at midnight, deck 1,300 x 500, rotting. Boarding: the
  whole rail. Tier cap: the full roster, ghost crews included. Zones: the Fog of Ships, the Gyre, the Eye of the Storm, the
  Drowned Helm.
- **The Heave:** the whirlpool tilts the deck: everyone slides toward the low side at 30 px/s (players and summons through
  `push_*()` x Sea Legs; enemies through knockback, so the low rail drowns the careless); the low side flips every 12 s with
  a 3 s creaking telegraph and a HUD arrow (text, never a screen effect). Units near the low rail are in the strikes' band.
- **Ghost crews leave corpses** (they are the dead of the sea): the necromancer raises the Brotherhood's own dead here.
- **Miniboss: the Ghost Bosun** (male), whose whistle summons a spectral longboat (BoardingParty, a ghost boat kind).
- **Boss: Captain Cornelius Vandermere, Master of the Hollow Queen** (male): **the Crew** (spectral crew, ghost boats
  circling), **the Maelstrom** (the tilt peaks; kraken arms strike the low rail whenever the deck leans toward them),
  **Dead Men's Oath** (lashed to the wheel behind an Oath shield; every ghost crewman the army raises chips the Oath 2%;
  empty, he is vulnerable for 15 s, then it refills). When he falls the whirlpool closes: a short ending text only.
- **Rewards:** spell **Anchor Drop** (a spectral anchor slams the strongest enemy, stuns it and shocks a ring; no pull) ->
  **Abyssal Mooring** + passive **Dead Reckoning**; character **the Ghost Helmsman** (male); the finale's summon class
  **the Powder Wraith** (a skeleton with a lit keg that walks into a pack and bursts, area damage and a 60 px knockback,
  reforming at the ring after 12 s; evolution **Magazine Lord**; one `SummonBehavior` that works on every stage; its
  Ossuary mastery).
- **Achievement: Dead Men Tell Tales** (beat Vandermere with the Oath broken three times). It would open the act's
  epilogue part: **build no epilogue part and no closing card** (the reorder pass writes them); record the clear only.
