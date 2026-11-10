# The Turning Year, phase 2: brief for the stage agents

Written by the foundation agent for the lead (branch `claude/determined-pasteur-hdy1g6`, base `916c8db1`). The lead adds the
merge commit, the owner's phase 2 answers (below: "Questions for the owner") and the session line before handing it out.

**The stages are built one at a time on this branch** (the Greenwood, then the Fae Court, then the World-Tree), each by its
own agent working on the lead's branch directly (no worktree, no merge), so the World-Tree agent finds the first two built.
The lead runs one big test pass at the end. This is the plan that built Acts IV to IX, the Dynasty, the Host and the Titans:
`docs/titans/BRIEF_PHASE2.md` is the closest model. Its "Process" section applies with the Wild's names, blocks headed
`# --- Act XV (temporary number): <your stage> ---`, and your own scratch dir.

## Read first
1. **`CLAUDE.md`** (it wins). In particular: no shader may read the screen (the blizzard is a radial texture and rects,
   the Last Claim's flashes flat rects), textures over polygons redrawn every frame, never `AudioServer.add_bus()`,
   **summons never get act-only rules** (the roots, the thorns, the burial and the Treant's root are enemy / world effects
   through the one paths: `SummonedUnit.held_until`, `damage_unit()`, `CombatResolver.stun_unit()`; the Ossuary Oak is a
   summon class that works everywhere), co-op reads the necromancer through the bound slot (`WildRules.slow_player()`
   binds it for `TerrainSlow`).
2. **`docs/last_acts/PLAN.md`:** temporary act number 15, **tune for the final slot XV: the hardest act of the game** (above
   the Age of Titans and the Ark: compare `docs/titans/playtest/` and `docs/act9/playtest/`), no epilogue part and no closing
   card yet (The First Spring only records the clear), female figures in the figure-redesign style (clothed), playable
   characters violet necromancers, the act's palette (moss, bark, blossom pink, gold-leaf amber, frost white; the blight a
   strong dead grey).
3. **The design:** `docs/proposals/LAST_SIX_ACTS.md` section "XV. The Turning Year" (it wins) and its "Open questions"
   (every recommendation taken except the two in PLAN.md). Concept art: `art_source/concepts/final5/year_lineup.png`,
   `year_bosses.png`, `year_stage.png`.
4. **`docs/GDD.md` §15.0:** "The Turning Year foundation (phase 1)", "The Turning Year (seasons)", "Bloom and Blight",
   "Overgrowth", "Spring Returns", "The Turning Year foundation gate", the art and audio rows when they land, and the Titans
   phase 2 rows.
5. **The code:** `README.md` (*Act XV: the Turning Year*), your stub `scripts/data/stages/<id>_stage.gd`, the folder
   `scripts/enemies/wild/` (`wild_rules.gd`, `season_cycle.gd`, `bloom_field.gd`, `thickets.gd`, `spring_returns.gd`,
   `season_wheel.gd`, `wild_kit.gd`, `dryad_kit.gd` and the kits), `wild_enemy_data.gd`, `wild_rules_data.gd`,
   `scripts/core/wild_report.gd` / `wild_ground.gd` / `wild_glyphs.gd`, `Arena.add_obstacle()`, your stage's empty table,
   `docs/year/ART_MANIFEST.md`.

## Extension points of the foundation (use these; do not fork them)
- **The rule object.** `Game.wild` (`WildRules`) is created by the STAGE key `wild`, null everywhere else. Parts:
  `seasons` (`SeasonCycle`), `bloom` (`BloomField`), `thickets` (`Thickets`), `returns` (`SpringReturns`).
  - `WildRules.enabled` is true only on a Wild stage (a Wild kind forced elsewhere makes the rules with the year, the
    blight and the Reckoning off; a dryad's seeds still grow). Stage-only things check the stage.
  - `WildRules.danger_push(p)` is what the army bot reads (the wildfires today). Add your hazards there, additively.
  - `WildRules.play_sound(event, pos, gap)`; events in `WildRulesData.SOUNDS` (your own block at its end).
  - Two draw layers: `WildRules._draw()` (z 14, over the units: roots, fronts, blizzard) and the under layer
    `_draw_under()` (z −8: blight, sprouts). Add your stage's draw calls there if it has no node of its own, and keep
    `step()`'s redraw tests in sync.
  - Each stage director goes in `scripts/enemies/wild/<id>_director.gd`, switched on by its own STAGE key and created and
    stepped from `EnemyDirector` like `LastDayDirector`.
- **The Turning Year** (`game.wild.seasons`). `season()` is THE season read (SPRING / SUMMER / AUTUMN / WINTER / RETURNS in
  `WildRulesData`, -1 off the act). `set_override(season, until)` forces a season: the Winter Prince's "one minute of
  winter into her summer", the Green Mother's **Turning** ("she casts one season after another, each a different attack"),
  the Last Claim's slots. The roots, wildfires, rot, snow and blizzard all follow `season()`, so an override switches them
  too. `corpse_life()` is the one corpse-life read (Corpse Explosion asks it). Who comes: a row's `season` keeps a kind to
  one season, a segment's `season_weights[season]` adds kinds (the timeline helper; waves through `filter_groups()`).
  STAGE `seasons` overrides `length`. **The Fae Court's endless summer** ("a court of endless summer under a sky that
  never sets"): an override to SUMMER for the whole run except the Winter Prince's minute is one call each.
- **Bloom and Blight** (`game.wild.bloom`). `blight_at(p)` / `is_dead(p)` are THE ground read; `wipe()` grows it all back.
  The **sacred groves** (the Greenwood: "blighting a grove, holding the ring in it for 10 s, kills it for the run") read
  `blight_at()` over the grove's ring, never a second grid. The **Spore Mother's** "blight-killing mould" lowers cells
  through one new `BloomField` method (add it here, not in the kit). **Scorched Earth** ("blight half the Greenwood in one
  run") reads `peak_cells` against the stage's area (decide the area in your director). STAGE `bloom` overrides any key.
- **Overgrowth** (`game.wild.thickets`). `plant(at, grow, by)` is THE planting path (dryads, spreads, Spring Returns, the
  Stag King's **Rut**: "charges that crack trees into new thickets", the **Antler Crown**'s ring, the Green Mother's
  **Burial**: "each buried summon becomes a thicket until the ring cuts it free"). Thickets are arena obstacles through
  `Arena.add_obstacle()` (one per arena cell; a crown or burial ring that needs several close together is a kit-drawn ring
  of its own, not more arena obstacles). `burn_at(at, r)` is the hook for the **burning spells, Rot and Wither** ("Fire,
  Rot and Wither burn them back"): phase 2 calls it from the fire sources (the Hellhound's trail, Death Ray, Brimstone,
  Meteor Call...), from `CombatResolver.rot_enemy()`'s area and the Wither aura, one call each, guarded by
  `game.wild != null`. `burn_line()` is the wildfire's. STAGE `thickets` overrides any key.
- **Spring Returns** is the shared Reckoning; tune it only through your RECKONING's `spring_returns` keys and its
  `companions`. The World-Tree's ending ("she takes the necromancer's dead back into the soil ... the campaign ends on the
  first spring") is its own Reckoning key if the World-Tree agent needs one (owned by `WildRules` beside `returns`, as the
  Titans' Extinction).
- **Counter-passive hooks are built and read** (neutral today). Build only the PassiveData rows, offered in this act only
  through the card row's `act` (use `15`; the reorder renumbers):
  - **Deadwood** (`WildRulesData.DEADWOOD`, key `hold_cut`, proposal "half as long" = 0.5 at Lv 5):
    `WildRules.deadwood_mult()`, read by the roots, the thorns and the burial (and the Treant's root when built).
  - **Fallow Ground** (`FALLOW_GROUND`, key `blight_rise`, proposal "twice as fast" = 1.0 at Lv 5): `WildRules.fallow_mult()`,
    read by `BloomField._rise()`.
- **Kits and rows.** Extend `WildKit`; call `super.reset()`. Row keys: `group` (growth, fae, hunt, spirits), `season`,
  `no_bloom`, `plant_*`, `fodder`. Kit ids must be unique across all kit folders. Bosses in
  `scripts/enemies/wild/boss_<id>.gd` (`EnemyDirector.WILD_BOSS_DIR`); remove your stub's `"script": "vael"`. Minibosses
  through `EnemyDirector.set_miniboss()`. New shared kinds: rows in your own block at the end of `WildEnemyData`;
  stage-only things in your stage's table.
- **The shared kinds' specials** (all phase 2; the Greenwood agent owns them unless a later stage needs one first): the
  **Treant** roots the summon it strikes (`held_until`), the **Fae Knight** blinks through the ring, the **Great Stag**'s
  telegraphed antler charge scatters the ring, the **Rider of the Wild Hunt** sweeps the arena in a line with two hounds
  (row `wild/hunt_hound`), the **Will-o'-Wisp** lures summons through `SummonedUnit.misdirect()`, the **Spore Mother**'s
  spores rot summons and her mould kills blight, the **Corpse-Bloom** eats corpses (Corpse Explosion's store) and buds
  Thornlings, the **Winter Fae**'s bolt chills.
- **Art keys.** Sprites load from `assets/sprites/wild/<kind_id>.png` (`docs/year/ART_MANIFEST.md`); the thicket's
  `obstacles/wild_thicket_m` as soon as it exists.
- **Report.** A per-stage file beside `wild_report.gd` (`greenwood_report.gd` ...), called from the marker in
  `WildReport.print_lines()`, one line in your own block; every new damage source gets its own tag so `wild damage`
  names it. **Codex:** your kinds in the `CodexData.WILD_*` group lists.
- **Unlocks, spells, characters, classes, achievements** as in the Titans (`UnlockData` / `Unlocks`, the one
  `NecroSpellBook` dispatch, `character_data.gd` with Hyper / Untouchable / Deathlord skins, one `SummonBehavior` per class,
  its Ossuary mastery). Ids must not collide with kinds, structures, source tags, sound or rule names (check
  `wild_enemy_data.gd`, `WildRulesData`, the sound packs; **`wild_hunt` is the spell's id, so the Rider's kind is
  `wild_rider` and the Hunt's rule names stay `hunt_*`**; `wild_wildfire`, `wild_burial`, `wild_thicket`, `seasons`,
  `bloom`, `thickets`, `returns` are taken).

## The new kinds, split across the stages
The foundation built `thornling`, `dryad` (the seeds), `treant`, `corpse_bloom`, `fae_knight`, `winter_fae` (winter only),
`great_stag`, `wild_rider`, `will_o_wisp` and `spore_mother` (the plain AI). The rest, one stage each:
- **The Greenwood:** the shared kinds' specials (above), the **sacred groves** (structures or a director's rings), the
  miniboss **the Huntsman of the Wild Hunt** (three riders in a sweeping line) in `GreenwoodEnemyData`, the Stag King.
- **The Fae Court:** the **fairy rings** ("time runs at half speed for whatever is inside, both armies": an enemy slow and
  `TerrainSlow` for the necromancer and summons, plus the attack timers if the owner wants it truly half-speed), the
  miniboss **the Winter Prince** (`set_override(WINTER, now + 60)`), the Summer Queen and **the Bargain** (two cards, the
  run paused in solo through the level-up pause, a lockstep command in co-op).
- **The World-Tree:** the miniboss **the Gardener of Roots** ("calls every root in reach": roots grab regardless of the
  season near him, through `SeasonCycle`'s roots, one new radius rule), the Green Mother (the Turning, the Burial, the Last
  Claim, below) and the ending.

## The Last Claim (the World-Tree agent)
The Green Mother's third phase (owner: the Morning Star's cut Throne phase, brought back): "she remembers every power that
ever claimed the dead, and the arena replays one signature rule of every act for about 10 s each, in campaign order ... She
can be hurt throughout." Build it as `scripts/enemies/wild/last_claim.gd` (`LastClaim`, owned by the boss), data in
`green_mother_data.gd` (`LAST_CLAIM`: the slot list, each slot's seconds and numbers).

**How a slot calls another act without changing any other stage.** Every act's rule has ONE path, but each of those
components reaches back to its own `game.<key>` (checked in the foundation: `BoardingParty`, `BloodMoon`, `Escalation`,
`DrawCuts`, `LongWinter`, `Rebirth`, `DivineWrath`, `HellPits`, `Judgment`, `LockOn`, `ConcordBeams`, `Herds` all read
`game.corsair` / `game.court` / ... at least once), so a bare `HellPits.new(game)` would break. Each slot therefore uses the
act's EXISTING forced-kind switch, `game.<key>_rules()` (the one every act's kit already calls when its kind is
`--spawn=`ed onto another stage): on the World-Tree the STAGE has none of those keys, so the act's rules object is built
with **`enabled == false`: no clock of its own runs** (no Blood Moon timer, no escalation, no herds of their own, no
Reckoning), and only the one call the slot makes does anything. Nothing here is created at load or on any other stage:
`LastClaim` calls the switch only when its slot begins, only on the World-Tree, so the solo same-seed summaries of
stages 1–44 cannot change (the World-Tree's own summary changes, as phase 2 always does). An act whose one path refuses to
run with `enabled == false` gets ONE additive line in its own file (a `force()` / guest entry like `BloodMoon.force()`
already is), never a second path. After its slot a rules object stays alive but inert for the rest of the run (no clock);
the `last claim` report line counts each slot's effect.

| # | Act (final slot) | Rule replayed (10 s) | The call (through that act's one path) |
|---|---|---|---|
| 1 | I The Covenant | the Covenant's march: a shield line advances | `EnemyDirector.spawn_formation("line", groups)` with the Crimson March kinds (`shieldbearer`, `banner_bearer`, `halberdier`; `MarchEnemyData`): Act I has no rules object at all |
| 2 | II The Black Tide | a boarding | `game.corsair_rules().boarding.launch_boat(size, kinds, hp_scale)` if it runs without a deck; else the boarding kinds (Grapplers, a Boatswain) through `spawn_formation()`, their `CorsairKit` bringing the disabled rules |
| 3 | III The Sanguine Court | the Blood Moon | `game.court_rules().moon.force(10.0)` (the bosses' own moon call; Bloodfeast and blood shields follow the moon) |
| 4 | IV The Last Line | the Wanted stars | the escalation's top tier as a squad (SWAT, army, a Super; `CityEnemyData`) through `spawn_formation()`, Armour through their `CityKit`; `Escalation` has no force call: add `Escalation.force(tier, until)` in its own file only if the owner wants the HUD stars |
| 5 | V The Shogunate | the Draw | `game.shogunate_rules().draws.draw(boss, from, dir, opts)`: the Green Mother draws iai lines across the ring |
| 6 | VI The Hall of the Slain | **the Choosing was dropped by the owner** (the Norse act's first rule is the Long Winter): recommended **Berserkergang** (the Long Winter repeats the Wild's own winter) | `game.norse_rules().enter_fury(e, true)` on every Wild enemy within reach as the slot opens |
| 7 | VII The Necropolis Dynasty | Rebirth: the dead rise again | `game.dynasty_rules().rebirth.on_death(e)` for every Wild kind that dies in the slot (check its `enabled` gate) |
| 8 | VIII The Olympian Republic | the Wrath of the Gods | `game.pantheon_rules().wrath.strike(kind, at)` / `open_fissure(a, b)` on telegraphed points round the ring |
| 9 | IX The Inferno | the hell pits | `game.inferno_rules().pits.open_pit(at, radius, life)` |
| 10 | X The Celestial Host | the Judgment | `game.host_rules().judgment.fill()` (a Verdict) or `add(amount)` per raise in the slot |
| 11 | XI The Ancient Eye | the Claims | `game.claims_rules()` (Hades' switch) and `EyeClaims.mark(u, until, life, tint, name)` on the summons she reaches: a marked summon that dies rises as her Thrall |
| 12 | XII The Electronic Empire | the Lock-On lines | `game.empire_rules().lock_on.paint(boss, target, damage, speed, reach, source, ...)`, three lines at once (the boss override) |
| 13 | XIII The Concord of Stars | the beams | `game.concord_rules().beams.fire(boss, dir, style, overrides, true)` (only Bone Walls stop them, barriers reflect) |
| 14 | XIV The Age of Titans | a stampede | `game.primeval_rules().herds.spawn_herd(at, 4, kinds, necromancer.position)` (launched at once; the Herds rule's own trample and shelter) |

Rules for the slots: each lasts `LAST_CLAIM` seconds (10 by the proposal; see the owner question on its length), a banner
names the act ("The Covenant marches again"), the boss can be hurt throughout and keeps her base attacks light during a
slot, every effect's damage keeps its own act's source tag (so `wild damage` shows which replay hurt most), the army bot's
`danger_push` sees each through the act's own `danger_push()` once its rules object exists, and co-op runs the same calls
in the lockstep simulation (no machine-local state). Exact member names above (`boarding`, `moon`, `draws`, `rebirth`,
`wrath`, `pits`, `judgment`, `lock_on`, `beams`, `herds`) are the rules objects' fields today; confirm each before use.

## Balance (the foundation's flags; seed 7)
- **The thickets fill their cap** (the Greenwood army run: 214 seeds, 73 grown, peak 30 at once, 559 summon catches): the
  spread is the main source once a few stand. Tune `spread_every` and `cap` per stage (the Greenwood gentler, the
  World-Tree a maze) before touching the rule.
- **The Wild's heal on living ground** healed 65,926 HP in the Greenwood army run at 1% max HP a second (2% let a naive
  army never kill a Treant on the World-Tree). Blight is the counter; check the spell-only builds, whose small army
  blights little.
- **Roots never caught the bot** (`roots: you 0`): the bot never stands still 2 s; summons were caught 160 times and enemies
  63 (the ring stands still while the necromancer does). A player who stands to cast will feel it more.
- **Wildfires** burned summons 291 times for 2,682 dealt damage in the Greenwood army run (13 fronts); the bot dodged every
  front. **Spring Returns' burials** dealt 2,140.
- **The World-Tree stub is hard for the naive bot** (`--mortal`: died at ~8:30, mostly to Fae Knights, Thornlings and
  Treants; enemy ×2.6 HP / ×1.8 damage are placeholders). Tune for slot XV with your stage's data first.
- One Godot process at a time (`pgrep -c Godot` first). Each agent balances its own stage so the army bot ends healthy on
  seed 7 (`--policy=army --mortal`); the hardest act may leave the naive bot dying more often than other acts.

## Process
- Do not push; commit in steps (WIP commits at each milestone: the container can restart); keep `"playable": false` until
  the lead's integration. Commit messages end with the lead's co-author lines.
- Touching a shared path outside the Wild folder (`combat_resolver.gd`, `summoned_unit.gd`, `horde_director.gd`,
  `enemy.gd`, `arena.gd`, a spell): also run the Graveyard default and the Last Day army runs of `docs/year/tools/gate.sh`
  against your base, one at a time; their `[autotest]` / `[metric]` lines must be identical. The World-Tree agent runs the
  whole gate (the Last Claim touches thirteen acts' rules objects).

## Questions for the owner (answer before phase 2 starts)
1. **The Last Claim's length** (the doc asked, with no recommendation: "Keep it that long, or cut it to one rule per
   Part-Two act?"). Recommended: **all fourteen acts, 8 s each (about 2 minutes)**, starting when she drops to a third of
   her health, so it fits the 3:00 before 0:00; if 0:00 comes first, Spring Returns begins as on every Wild stage.
2. **The Norse slot of the Last Claim:** the Choosing was dropped. Recommended: **Berserkergang** (a wounded Wild enemy
   goes into a fury), since the Long Winter's cold repeats the Wild's own winter.
3. **Which achievement opens which counter-passive?** Recommended: *Scorched Earth* → Fallow Ground (both about the blight),
   *A Fair Bargain* → Deadwood; *The First Spring* opens the final epilogue part (written in the reorder pass).
4. **The blizzard:** drawing only (built: sight cut to 400 px for the player's eyes), or also a gameplay cut (the
   necromancer's spells and the ranged summons target nothing beyond 400 px)? Recommended: drawing only.
5. **The roots on the necromancer:** a strong slow (built: 85% for 1.5 s, Grave Step breaks free) or a true hold?
   Recommended: the slow.

---

## Agent A: the Greenwood (`greenwood`, final stage 43)
- **Stage:** an old forest that has never been cut. Zones: the Glade, the Deep Wood, the Hunting Grounds, the Stag's Hollow.
  Four zone floors over the `greenwood` style (neutral under the season tints), obstacles in both orientations.
- **Stage mechanic: sacred groves:** rings of standing trees that heal the Wild inside them; blighting a grove (holding the
  ring in it for 10 s) kills it for the run (`blight_at()`).
- **Miniboss: the Huntsman of the Wild Hunt** (male), who leads three riders in a sweeping line.
- **Boss: the Stag King** (`boss_stag_king.gd`, male, stag-headed): **the Hunt** (he leads the Wild Hunt across the arena
  in sweeping lines), **the Rut** (charges that crack trees into new thickets: `Thickets.plant()`), **the Antler Crown**
  (his antlers grow a thicket ring around him that must be burned through before he can be hurt: `burn_at()` from the fire
  sources, or broken by damage to the ring).
- **Spell: Wild Hunt** (spectral riders sweep across the screen in a line) → **The Endless Hunt** + **Horn of the Hunt**.
  **Character: the Horned Herald** (male). **Achievement: Scorched Earth** (blight half the Greenwood in one run).
- Also the shared kinds' specials (above).

## Agent B: the Fae Court (`fae_court`, final stage 44)
- **Stage:** a court of endless summer under a sky that never sets (`set_override(SUMMER, ...)`). Zones: the Rose Maze, the
  Revel, the Mirror Lake, the Throne of Blossoms. Floors over the `fae` style.
- **Stage mechanic: fairy rings:** mushroom circles where time runs at half speed for whatever is inside, both armies.
- **Miniboss: the Winter Prince** (male), the Summer Queen's rival, who brings one minute of winter into her summer.
- **Boss: the Summer Queen** (`boss_summer_queen.gd`, female, figure style): **the Masque** (glamour: she and her court
  change faces, and only hits reveal which is real), **the Bargain** (a real choice on screen: a strong boon at a price,
  e.g. +30% army damage for 60 s while the army no longer heals; refuse and she attacks harder; two cards, the run paused
  in solo, a lockstep pick in co-op), **the Court in Bloom** (she floods the arena with blossoms and thorns until she falls).
- **Spell: Glamour** (illusory copies of the necromancer draw enemy attacks) → **Court of Masks** + **Changeling**.
  **Character: the Changeling Princess** (female, figure style). **Achievement: A Fair Bargain** (accept every bargain and
  still win).

## Agent C: the World-Tree (`world_tree`, final stage 45, the campaign finale)
- **Stage:** the tree at the centre of the world. Zones: the Roots, the Trunk Stair, the Crown, the Seed. The year turns
  twice as fast (built: STAGE `seasons` `length` 150). Floors over the `tree` style.
- **Miniboss: the Gardener of Roots**, a treant that tends the tree and calls every root in reach.
- **Boss: the Green Mother** (`boss_green_mother.gd`, female, figure style, a colossal goddess grown from the tree): **the
  Turning** (one season after another, each a different attack: `set_override()`), **the Burial** (she pulls summons into
  the earth one by one; each becomes a thicket until the ring cuts it free), **the Last Claim** (above). **The ending:**
  beaten, she does not die; she takes the necromancer's dead back into the soil and gives him the one claim left: the dead
  are planted, and in spring they rise to him; the campaign ends on the first spring.
- **Spell: Root and Rot** (a ring of roots at the strongest enemy rots everything inside) → **Return to Earth** + **Compost
  Heart**. **Character: the Gravegardener** (female, figure style). **Summon class: the Ossuary Oak** (finale reward: a slow
  tree of bone that roots in place as a blocker and lashes everything around it with thorns; evolution World-Root Warden; a
  class special that works everywhere; its Ossuary mastery). **Achievement: The First Spring** (beat the Green Mother; it
  only records the clear until the reorder pass writes the final epilogue part).

## Owner answers (Nov 2026; GDD §15.0 "Wave 3 owner answers")
- **The Last Claim replays a random 7 of the 14 acts** (pick them with the run's seeded RNG, each act at most once, in a
  seeded order; 8 s each, from a third of the Green Mother's HP). Not all 14. The other acts' slots stay written, only 7 run.
- The Norse slot is **Berserkergang**.
- **Scorched Earth → Fallow Ground, A Fair Bargain → Deadwood.**
- The blizzard is **drawn only**.
- Spring roots on the necromancer: the built **85% slow that Grave Step breaks** (not a true hold).
