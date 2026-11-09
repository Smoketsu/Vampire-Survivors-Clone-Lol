# The Age of Titans, phase 2: brief for the three stage agents

Written by the foundation agent for the lead (branch `claude/determined-pasteur-hdy1g6`, base `c6b1bb0a`). The lead adds the
merge commit, the owner's phase 2 answers (below: "Questions for the owner") and the session line before handing it out.

Three agents run at the same time, one per stage, each in its own worktree on its own branch made from the lead's branch
that holds the merged foundation (code, art and audio). The lead merges the branches and runs one big test pass after.

This is the plan that built Acts IV to IX, the Dynasty and the Host: `docs/host/BRIEF_PHASE2.md` is the closest model. Its
"Process" section applies unchanged with the Titans' names, blocks headed
`# --- Act XIV (temporary number): <your stage> ---`, and your own scratch dir.

## Read first
1. **`CLAUDE.md`** (it wins). In particular: no shader may read the screen (the Extinction's white-out is flat rects drawn
   additively, never a screen read), textures over polygons redrawn every frame, never `AudioServer.add_bus()`, **summons
   never get act-only rules** (the trample, the bombs, the Tyrant's swallow, the Stormwing's gust are enemy effects
   through the one paths: `damage_unit()`, `CombatResolver.stun_unit()`, `SummonedUnit.held_until`; the Fossil Giants and
   the Fossil Host are temporary summons of existing classes through `HordeDirector.raise_corpse()`), co-op reads the
   necromancer through the bound slot.
2. **`docs/last_acts/PLAN.md`:** temporary act number 14, **tune for the final slot XIV** (above the Concord of Stars, Act
   IX: compare `docs/act9/playtest/`), no epilogue part and no closing card yet (The Day the Sky Fell only records the
   clear), female figures in the figure-redesign style (clothed; the playable characters, never the beasts), no humans in
   the enemy roster, the act's palette (fern green, volcanic orange, tar black, dust ochre, bone white).
3. **The design:** `docs/proposals/LAST_SIX_ACTS.md` section "XIV. The Age of Titans" (it wins) and
   `docs/proposals/NEW_ACTS_AND_ORDER.md` Part 2 (the full stage sections, the roster and the meteor's Option A). Concept
   art: `art_source/concepts/final5/titans_lineup.png`, `titans_bosses.png`, `titans_stage.png`.
4. **`docs/GDD.md` §15.0:** "The Age of Titans foundation (phase 1)", "Packs", "Herds", "Scavengers", "The Stampede of
   Ash", "The Age of Titans foundation gate", the Titans art and audio rows when they land, and the Host phase 2 rows.
5. **The code:** `README.md` (*Act XIV: the Age of Titans*), your stub `scripts/data/stages/<id>_stage.gd`, the folder
   `scripts/enemies/primeval/` (`primeval_rules.gd`, `pack_brain.gd`, `herds.gd`, `scavengers.gd`, `stampede_of_ash.gd`,
   `primeval_kit.gd`, `herd_beast_kit.gd` and the kits), `primeval_enemy_data.gd`, `primeval_rules_data.gd`,
   `scripts/core/primeval_report.gd` / `primeval_ground.gd` / `primeval_glyphs.gd`, your stage's empty table,
   `docs/titans/ART_MANIFEST.md`.

## Extension points of the foundation (use these; do not fork them)
- **The rule object.** `Game.primeval` (`PrimevalRules`) is created by the STAGE key `primeval`, null everywhere else.
  Parts: `packs` (`PackBrain`), `herds` (`Herds`), `scavengers` (`Scavengers`), `ash` (`StampedeOfAsh`).
  - `PrimevalRules.enabled` is true only on a Titans stage (a Titans kind forced elsewhere makes the rules with the herd
    clock and the Reckoning off; its pack, herd or dives still work). Stage-only things check the stage.
  - `PrimevalRules.danger_push(p)` is what the army bot reads (the stampedes' paths, the bombs). Add your hazards there,
    additively; a kit's own telegraph goes in its `danger_push(e, p)`.
  - `PrimevalRules.play_sound(event, pos, gap)`; events in `PrimevalRulesData.SOUNDS` (your own block at its end).
  - `PrimevalRules._draw()` is the act's one world-space telegraph layer (z 14); add your stage's draw call there if it
    has no node of its own, and keep `step()`'s redraw test in sync.
  - Each stage director goes in `scripts/enemies/primeval/<id>_director.gd`, switched on by its own STAGE key and created
    and stepped from `EnemyDirector` like `TwoTruthsDirector`.
- **Packs** (`game.primeval.packs`). A pack forms from the pack kinds (row `pack: true`, a `RazorclawKit`) that come on
  within `form_window` s; the first is its alpha. `steer(e, kit, delta)` is THE one steering call (STALK → CIRCLE → HOLD
  → RUSH → DONE; broken by the alpha's death). Scarmaw's **Hunt** ("she commands three packs in turn") spawns three
  groups and can read `packs.packs`; her **Blood Up** ("her pack respawns for every kill; kill her alpha-guard") is her own
  script's. A new pack kind extends `RazorclawKit` (or holds a `pack` field of its own and calls `steer()`; then widen the
  `is RazorclawKit` checks in `PrimevalRules` to a shared base, one place). STAGE `packs` overrides any `PACKS` key.
- **Herds** (`game.primeval.herds`). The herd kinds (row `herd: true`, a `HerdBeastKit`) are neutral; `steer()` owns their
  tick. `spawn_herd(center, n, kinds, launch_at)` brings a herd (launched at once when `launch_at` is given); `launch(h,
  toward)` is THE one stampede start (Ironbrow's **Herd**: "the front runs behind him" = launch his herd at the
  necromancer from his own position each charge; the Watering Hole: "fights near it start stampedes" = call `launch()`
  for the herds near it when a fight is close). `in_front()`, `sheltered()` and `_trample()` are the one trample path
  (Thick Marrow's hook is read there). The **Fossil Giant** rises in `on_killed()` (cap 2). The Fern Basin's **tar**
  ("herbivores get stuck in tar: a trapped Longneck is a free kill") goes through `TerrainSlow` (the one ground-slow path)
  plus one read in `Herds.steer()` (a beast in tar does not graze away), never a second movement path. STAGE `herds`
  overrides any `HERDS` key (`"cap": 0` = no herd of their own; the Canyon zone's narrow lanes are obstacles: shelter
  works as is).
- **Scavengers** (`game.primeval.scavengers`). Any row with `scavenger: true` and a `SkyraiderKit` dives; `find_pile()` /
  `pile_at()` / `snatch()` / `drop()` / `nested()` are the one path over the crystal pool (`XpManager.take()` is the one
  taking call; values never change). **Nothing Taken** (the Great Plain achievement: "finish without losing a crystal
  pile to a Skyraider") is the run stat `scav_nests == 0` on a clear (record it in your director or `RunRewards`).
  Thunderwing and the Stormwing are fliers (row `flies`), not thieves, unless the design says they snatch.
- **The Stampede of Ash** is the shared Reckoning of the Fern Basin and the Great Plain; tune it only through your
  RECKONING's `stampede_of_ash` keys and its `companions`.
- **The Extinction (the Last Day agent).** The owner took Option A: on the Last Day, at 0:00 the necromancer's meteor lands
  as the Reckoning: a 5 s telegraph (white-out rects and shock rings, the necromancer under a one-time ward), every enemy
  on the map dies (a boss still alive drops to 10% HP and does not give his spell), every corpse rises as a temporary
  **Fossil Host** (cap 60, 45 s; `raise_corpse()` in a capped loop), and the run ends in **Victory**. Build it as a new
  Reckoning key `extinction` on the Last Day's RECKONING (drop `stampede_of_ash` there), a class `Extinction` in the folder,
  owned by `PrimevalRules` beside `ash`, with its report line. The structure stays: the 20:00 clock, the boss at 3:00, and
  dying after 0:00 is a victory. Fire from the Sky (meteorites every 12 s, faster each zone; the HUD clock shows the meteor
  growing) is the Last Day's stage mechanic.
- **Counter-passive hooks are built and read** (neutral today). Build only the PassiveData rows, offered in this act only
  through the card row's `act` (use `14`; the reorder renumbers):
  - **Hoarder's Bones** (`PrimevalRulesData.HOARDERS_BONES`, key `safe_radius`, proposal 300 px; "a snatched pile drops
    sooner" is one more key read in `SkyraiderKit` / `Scavengers`): `PrimevalRules.hoarders_bones_reach()`, read by
    `Scavengers.safe_radius()`.
  - **Thick Marrow** (`THICK_MARROW`, key `trample_cut`): `PrimevalRules.thick_marrow_mult()`, read by `Herds._trample()`
    and `StampedeOfAsh._land()`; the Horncharger's charge and the Clubtail's sweep read it too.
- **Kits and rows.** Extend `PrimevalKit` (registration, `move()`); call `super.reset()` / `super.on_deactivate()` /
  `super.on_killed()`. Row keys: `group` (swarm, hunters, herds, fliers, titans), `pack`, `alpha_sprite`, `herd`, `fright`,
  `scavenger`, `fodder`. Kit ids must be unique across all kit folders. Bosses in
  `scripts/enemies/primeval/boss_<id>.gd` (`EnemyDirector.PRIMEVAL_BOSS_DIR`); remove your stub's `"script": "vael"`.
  Minibosses through `EnemyDirector.set_miniboss()`. New shared kinds: rows in your own block at the end of
  `PrimevalEnemyData`; stage-only things in your stage's table.
- **Art keys.** Sprites load from `assets/sprites/primeval/<kind_id>.png` (`docs/titans/ART_MANIFEST.md`);
  `summons/fossil_giant` is drawn as soon as it exists.
- **Report.** A per-stage file beside `primeval_report.gd` (`fern_basin_report.gd` ...), called from the marker in
  `PrimevalReport.print_lines()`, one line in your own block. **Codex:** your kinds in the `CodexData.PRIMEVAL_*` group lists.
- **Unlocks, spells, characters, classes, achievements** as in the Host (`UnlockData` / `Unlocks`, the one
  `NecroSpellBook` dispatch, `character_data.gd` with Hyper / Untouchable / Deathlord skins, one `SummonBehavior` per class,
  its Ossuary mastery). Ids must not collide with kinds, structures, source tags, sound or rule names (check
  `primeval_enemy_data.gd`, `PrimevalRulesData`, the sound packs; `stampede` is the spell's id, so the rule names stay
  `herds` / `herd_stampedes`; `primeval_trample`, `primeval_bomb`, `fossil_giant`, `packs`, `herds`, `scavengers` are taken).

## The new kinds, split across the stages
The foundation built `scuttler`, `razorclaw`, `frill_spitter`, `longneck`, `duckbill`, `skyraider` and `tyrant` (plain
heavy). The rest, one stage each:
- **The Fern Basin:** the **Bog Croc** (male; hides in tar and river tiles, lunges at the rail of the ring) as a shared row
  in `PrimevalEnemyData`; the miniboss **Ironjaw, the Nest Mother** (female) and her nest (spawns Scuttlers until
  destroyed) in `FernBasinEnemyData`; optionally the Razorclaw's leap ("over the first blocker, rakes the nearest summon")
  in `RazorclawKit` (the Fern Basin agent owns that kit).
- **The Great Plain:** the **Horncharger** (male; telegraphed charge that stuns summons, stuck in a rock 2 s on a miss) and
  the **Clubtail** (female; flat armour 5, a tail sweep that knocks summons back) as shared rows; the miniboss **Mother
  Clubtail** in `GreatPlainEnemyData`.
- **The Last Day:** the **Stormwing** (female; a wing gust that pushes the ring 100 px, lands to peck) as a shared row; the
  **Tyrant's** swallow (a summon held 4 s, cut out by damage) and roar (the ring stunned 1.2 s) in `TyrantKit`; the
  miniboss **Thunderwing, the Sky King** in `LastDayEnemyData`.

## Balance (the foundation's flags; seed 7)
- **The trample is the stubs' largest source of summon damage** (the Fern Basin army run: 45 stampedes, 988 summon hits,
  40,046 damage; it was 77 stampedes and 99,124 before the cooldown went to 45 s and the hit to 12). The army still won
  with its lowest HP 118/120. Builds without Warders and Menders will feel it more; tune the stage's `herds` first (`cooldown`,
  `fright`, `trample_summon`) rather than the rule.
- **Stampedes run at the necromancer** (the line points from the herd's centre at the necromancer who frightened it), so
  each one crosses the ring: shelter behind an obstacle is the answer the design gives. If the owner prefers "away from what
  hurt them", it is one line in `Herds.launch()`'s callers.
- **Scavengers took ~220 XP a run** (the Fern Basin army run: 121 dives, 99 piles to the nests, 217 XP lost; about 4.5% of
  the run's XP). The army bot never chases a carrier; Archers and spells kill some.
- **The Last Day stub is hard for the naive bot** (`--mortal`: died at 8:13, mostly to Frill-Spitter bolts and Scuttlers).
  Tune for slot XIV with your stage's data first.
- One Godot process at a time (`pgrep -c Godot` first). Each agent balances its own stage so the army bot ends healthy on
  seed 7 (`--policy=army --mortal`); the Fern Basin agent also checks seeds 1 and 2.

## Process
- Do not push; commit in steps; keep `"playable": false`. Commit messages end with the lead's co-author lines.
- Touching a shared path outside the Titans folder (`combat_resolver.gd`, `summoned_unit.gd`, `horde_director.gd`,
  `enemy.gd`, `xp_manager.gd`): also run the Graveyard default and the Silver Stair army runs of `docs/titans/tools/gate.sh`
  against your base, one at a time; their `[autotest]` / `[metric]` lines must be identical.

## Questions for the owner (answer before phase 2 starts)
1. **Which achievement opens which counter-passive?** Recommended: *Nothing Taken* → Hoarder's Bones, *Trampled* → Thick
   Marrow (each answers the rule its achievement is about).
2. **The stampede's direction:** at the necromancer (built; shelter is the counterplay) or away from what hurt the herd?
3. **The Extinction's length:** the proposal's 45 s scripted finale, or shorter (e.g. 20 s) so the victory screen comes
   sooner?
4. **Lit beacons** (the proposal's optional polish on the Last Day: three channelled beacons, each bringing the impact 30 s
   sooner for +10% Soul Ash): build in phase 2, or leave for later? Recommended: later.

---

## Agent A: the Fern Basin (`fern_basin`, final stage 40)
- **Stage:** a river basin deep in jungle; the sky still blue, the white streak faint. Zones: the Fern Floor, the Tar Seep,
  the River Ford, the Nesting Hollow. Four zone floors over the `fern` style, obstacles in both orientations.
- **Stage mechanic: Tar Seeps:** pools of tar slow everyone (`TerrainSlow`); herbivores get stuck (a trapped Longneck is
  a free kill and a free heavy corpse); Bog Crocs ambush from the seeps.
- **Miniboss: Ironjaw, the Nest Mother** (female): defends a nest that spawns Scuttlers until it is destroyed.
- **Boss: Scarmaw, the Great Raptor** (`boss_scarmaw.gd`, female alpha): **the Hunt** (three packs in turn, she leaps over
  the ring), **the Ambush** (she vanishes into marked fern patches and lunges from one every 8 s), **Blood Up** (at half
  health her pack respawns for every kill and she moves faster; kill her alpha-guard to end it).
- **Spell: Pack Leap** (three spectral raptors leap at marked enemies) → **Apex Pack** + **Pack Instinct**. **Character:
  the Fern Huntress** (female, figure style).

## Agent B: the Great Plain (`great_plain`, final stage 41)
- **Stage:** open grassland under a hot sky with a bright streak; herds dominate the screen. Zones: the Dust Flats, the
  Watering Hole, the Canyon, the Bone Gate. Floors over the `plain` style.
- **Stage mechanic: the Watering Hole:** a central lake gathers herds; fighting near it triggers stampedes; the Canyon
  zone makes the stampede lanes narrow.
- **Miniboss: Mother Clubtail** (female), an armoured matriarch who guards a herd.
- **Boss: Old Ironbrow, the Horned Titan** (`boss_ironbrow.gd`, male ceratopsian): **the Herd** (he leads a stampede; the
  front runs behind him), **the Charge** (straight-line charges at the necromancer; missing into a rock stuns him 3 s),
  **the Break** (he snaps one horn on a rock; the shards fly as 3 short lines, then he charges with the stump).
- **Spell: Stampede** (a spectral horned charger tramples a line) → **Herd of Ages** + **Calcified Hide**. **Character:
  the Herd-Warden** (male).
- **Achievement: Nothing Taken** (finish the Great Plain without losing a crystal pile to a Skyraider).

## Agent C: the Last Day (`last_day`, final stage 42, the act's finale)
- **Stage:** the impact basin; the sky white, the meteor the size of a moon, ash falling. Zones: the Scorched Plain, the
  Ash Forest, the Lava Fields, the Impact Rim. Floors over the `ash` style.
- **Stage mechanic: Fire from the Sky:** small meteorites strike telegraphed circles every 12 s, hurting both armies, the
  interval shrinking each zone; the HUD clock shows the meteor growing.
- **Miniboss: Thunderwing, the Sky King** (male), a giant pterosaur whose wing gusts clear the ring.
- **Boss: Old Gravejaw, the Tyrant King** (`boss_gravejaw.gd`, male): **the Roar** (stuns the ring and calls every beast
  on the map to him), **the Hunt** (he hunts the necromancer, ignoring summons; bites through the ring and swallows), **the
  Last Day** (the sky is white; he turns toward the impact and rampages toward the Mound). Only a Gravejaw killed before
  the impact gives his spell.
- **The Extinction** (above). **Spell: Meteor Call** (a telegraphed meteor lands on the densest group) → **Extinction
  Event** + **Cosmic Dust**. **Character: the Skywatcher** (female, figure style). **Summon class: the Bonehorn** (finale
  reward: a skeletal horned charger that tramples through a pack and trots back to the ring; evolution Fossil Tyrant; a
  class special that works everywhere; its Ossuary mastery).
- **Achievements: Trampled** (a stampede kills 100 enemies in one run: the run stat `trample_kills`; any Titans stage) and
  **The Day the Sky Fell** (reach the Extinction with no summon lost; it only records the clear until the reorder pass
  writes the epilogue part).

## Owner answers (Nov 9, 2026; GDD §15.0 "Wave 2 owner answers")
- Nothing Taken → Hoarder's Bones; Trampled → Thick Marrow.
- **Stampedes run AWAY from whatever hurt the herd**, not at the necromancer (overrides the "Stampedes run at the necromancer" note above; the Fern Basin agent changes `Herds.launch()`'s callers).
- **The Extinction lasts 30 s** (the Fossil Host's lifetime), not 45 s.
- Lit beacons on the Last Day: later, not in phase 2.
