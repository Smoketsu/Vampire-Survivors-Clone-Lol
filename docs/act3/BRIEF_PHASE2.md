# Act III phase 2: brief for the three stage agents

Lead's brief. Read it in full, then the section for YOUR stage. Three agents run at once, one per stage, each in its
own git worktree on its own branch made from `integration` (which holds the merged phase 1 foundation). The lead
merges the three branches on `integration` afterwards, runs the gates and the balance pass.

## Read first
1. `CLAUDE.md`: every convention. In short:
   - document EVERY variable and constant (units, ranges); every script starts with a header comment;
   - tunables only in `scripts/data/*.gd`, tagged `# TUNING (not in GDD)` (or `# GDD §N`);
   - static typing; determinism per seed (no wall clock, instance ids or unseeded RNG);
   - one path per modifier; pooling with `generation` checks; no physics engine;
   - autotest friendly (headless, no `user://` without `--meta-save`);
   - the UI rules (Jersey 10 at 19/28/38/57, Jacquard 24 at 43 through `UiTheme.Tier`, chamfered corners,
     `InputHints` chips, colour meanings);
   - **no shader may read the screen**; **never call `AudioServer.add_bus()`**;
   - **summons never get act-only rules** (Content wave 2 row): the act's rules act on enemies and shots.
2. `docs/act3/PROPOSAL.md`: the owner-approved design. Your stage's section and your rewards are the spec.
3. `docs/GDD.md` §15.0: the rows "Act III foundation (phase 1)", "Line of Fire", "Lock-On", "Steel has no soul"
   (the shared systems you build on), and the Act II phase 2 rows "Gullhaven Harbour (Act II phase 2)" through
   "Act II integration (phase 2)" (how a stage, its kinds, boss, spell, character and class were built last time).
4. `README.md` (architecture, autotest options), your stage stub `scripts/data/stages/<id>_stage.gd`, the Act II
   stage that is closest to yours (`harbour_stage.gd` with `TideDirector` / `HarbourDirector`, `archive_stage.gd`,
   `spire_stage.gd`), `scripts/enemies/empire/` (EmpireKit, EmpireShots, LockOn, EmpireRules), `empire_enemy_data.gd`,
   `empire_rules_data.gd`, and the Act II boss you are closest to (`scripts/enemies/eye/boss_*.gd`).
5. Art: `docs/art/ART_BIBLE.md` (the "Act III: the Electronic Empire, the shared kinds" section sets the style:
   chrome bodies, signal-amber lights, hard clean silhouettes) and `docs/act3/ART_PIPELINE_NOTES.md`.

## Extension points of the foundation (use these, do not fork them)
- **Kinds:** add rows to YOUR stage's table (`WastesEnemyData` / `AssemblyEnemyData` / `CitadelEnemyData`, looked up
  by `EnemyDirector.empire_def()`); every row has `body` = `"machine"` or `"cyborg"`. A shared kind you own (see
  your table) goes in your stage's table too; the lead moves it to `EmpireEnemyData` at the merge if another stage
  uses it (other stages may still spawn it by id, so give it a unique id).
- **Kits:** `scripts/enemies/empire/<id>_kit.gd`, extending `EmpireKit` (marching fire through `fire_ranged()`;
  `fire_shot()` / `fire_arc_at()` for special shots; override `physics()` for a windup). Kit ids must be unique
  across the Eye and Empire folders.
- **Shots:** only `EmpireShots` (`Game.empire.shots.fire()` / `fire_arc()`); new looks are new `SHOT_STYLES`
  entries in `empire_rules_data.gd`, added in their own commented block for your stage. Line of Fire applies to
  every non-arc shot; never route an Empire shot through `ProjectileManager`.
- **Lock-On:** `Game.empire.lock_on.paint(...)`; a boss passes `boss_override` to exceed the 3-line cap.
- **Corpses:** `Enemy.leaves_corpse()` / `rises_as_gunner()` and `HordeDirector.raise_corpse()` are the only gates.
- **Bosses:** `scripts/enemies/empire/boss_<id>.gd` (extends `Boss`); replace your stub's placeholder `script` key.
- **Reckoning:** the Purge Protocol is shared; tune it only through your stage's `RECKONING["orbital"]` keys.
- **Ground rules:** any slow or push on the ground goes through `TerrainSlow` (the one ground path); add a push to it
  rather than a second path (Assembly owns that change; see its section).
- **Suppression / jamming:** `HordeDirector.add_suppression()`. Stuns: `CombatResolver.stun_enemy()`. Debuffs on
  enemies: `CombatResolver.weaken_enemy()`. Every damage, heal, kill, XP and drop: `CombatResolver`.
- **Minibosses:** register through `EnemyDirector.set_miniboss()`; `ChestManager` drops its chest.
- **Unlocks:** `UnlockData` / `Unlocks` (spells and classes unlocked by bosses, counter-passives by achievements,
  Act III only through the card row's `act`). Characters: `character_data.gd` rows, innate hooks through
  `game.character.innate_value()`.
- **Report:** add your stage's line to `EmpireReport` (one function per stage, your own block) plus a line per new
  system; keep the six foundation lines unchanged.

## Shared files: keep edits small, additive and in your own block
Three branches will be merged, so in every shared file put your additions in a block headed with a comment naming
your stage (e.g. `# --- Act III: the Assembly Halls ---`), placed at the END of the table or list it extends, never
reordering or reformatting existing lines. Shared files you will likely touch: `stage_registry.gd` (only your stage's
`BOSS_ARRIVALS` entry), `codex_data.gd`, `unlock_data.gd`, `passive_data.gd`, `grave_spell_data.gd` and the spell
book's id lists, `character_data.gd`, `skin_data.gd`, the summon class data, `sound_data.gd`, `sprite_data.gd`,
`autotest.gd` (only additive flags), `README.md`, `docs/GDD.md` (your own rows at the end of §15.0, just before
`### 15.1`), `docs/art/ART_BIBLE.md` (your own section) and `docs/art/generation_ledger.csv` (append only).
Do not tune any data another stage owns, and do not touch the Act I / Act II stages' data.

## What each agent builds (the stage, its share of the shared content, all of it finished)
- the stage: four clock-driven zones with their names, floors (4 zone floors as tiles), obstacles in both
  orientations, its stage systems, its miniboss and its boss with full kits and telegraphs, the stage timeline
  (with your melee kinds the act reaches about 60% ranged, per the proposal), its achievement and reward;
- the kinds, spell (with evolution and paired passive), character and (where listed) summon class from your row;
- art for all of it (stills, walk / glide strips, boss attack poses, structures, obstacles, floors, effects, icons;
  characters with their Hyper skin and the universal **Untouchable** and **Deathlord** skins, drawn, never a tint);
- synthesized sounds (no sound files; add to `SoundData.EMPIRE_SOUNDS` or a stage block beside it);
- Codex entries, autotest summary lines, README, GDD rows, ART_BIBLE rows.

**Keep your stage `"playable": false`.** The lead flips it after the multi-seed check and the owner's playtest. The
autotest ignores stage locks, so `--stage=<id>` runs it.

**Difficulty target** (for your own sanity runs; the lead does the real balance pass): a step harder than Ul-Thalos;
`--policy=army` should usually reach 0:00 and kill your boss. Don't spend long tuning.

## Art rules
- ALWAYS: `GEN_LEDGER=/home/user/vampire-survivors-clone-lol/docs/art/generation_ledger.csv python3 tools/gen_image.py ...`
  (keep the path exactly as written). **Never read, print, echo, search for or set any API key** (the proxy injects
  it). Commit the ledger lines you add. Budget about $1.20 of generation for your stage; say if you need more.
- True pixel art at 1 art px = 1 screen px; `prepare_sprite.py`, `art_check.py`, `walk_cycle.py`, `make_tile.py`,
  `pixelate_source.py` (small detailed figures first), `mesh_props.py` for thin meshes, grids and lattices (they do not
  survive conversion otherwise).
- Owner notes: details big enough to read at game size, no busy specks; faces read clearly; machines chrome with
  signal-amber / warning-red lights; the undead's colours (bone, soul teal) never on an enemy.
- **Every female character in the figure-redesign style**: exaggerated hourglass figure, big bust, wide hips, fully
  clothed, never explicit; a bust bounce in the walk / glide strip (`walk_cycle.py` rig key `bust`; check the bounce
  box sits on the bust, not the belt) and a 24-frame idle breathing strip (`walk_cycle.py idle`, `IdleData`).
- Look at your own art at game size (screenshots) before you call it done. The owner reviews all of it on a review
  page after the merge, so keep a list of every new PNG (path, what it is, cost) in your final report.

## Testing (lean; owner rule)
- While building: `--headless --import` clean and your stage's autotests only.
- Before your final report: `--import` clean; `--stage=<id> --policy=army` and `--stage=<id>` (naive) on 2 seeds with
  zero `SCRIPT ERROR` / `ERROR:` / `WARNING:` and `stuck_units=0`; one default Graveyard run; and the same-seed gate
  for the other acts: `docs/act3/tools/gate.sh <your worktree> <outdir>` on your branch vs the lead's base summaries
  (path given in your prompt), diffed with `docs/act3/tools/same_seed_gate.py`. Allowed diffs: catalog counts only
  (Codex totals, recipe / stage / skin counts). Your new spell / class / passive must not change Act I / II runs
  unless forced, so they stay locked (unlocked by your boss / achievement) and out of the default card pool.
- **CPU: at most ONE Godot process at a time** (three agents share 4 cores). Godot binary:
  `/home/user/tools/godot/Godot_v4.3-stable_linux.x86_64`. Autotest:
  `--headless --fixed-fps 60 --quit-after 15000 -- --autotest [options]`. Use a timeout of 900 s per run.
- Screenshot your stage at 1280x720 under xvfb (zones, the miniboss, the boss phases, the new kinds) and look at
  them yourself.

## Process
- Work only in your worktree, on your branch. Commit in sensible steps; push the branch as a backup
  (`git push -u origin <branch>`). Never push to `main` or `integration`. Never mention model identifiers.
- Commit messages via `git commit -F <file>`, ending with exactly the two attribution lines given in your prompt.
- Logs and screenshots go in the scratchpad folder given in your prompt, not in the repo.
- Decisions the proposal doesn't cover: make a sensible one, record it in your GDD row as "own decision", and list it
  in your report. Don't stop to ask unless something blocks you.

## Final report (your last message)
Branch and commits; what you built (files); shared files touched and why; GDD rows; test results (numbers, the gate
diff); every new PNG with its cost; open questions and own decisions for the owner.

---

## Agent A: the Scrap Wastes (`wastes`, Stage 7)
- **Stage:** zones the Slag Fields, the Wreck Gullies (narrow paths between fallen titans), Pylon Ridge, the Outer
  Wall. **Signal Pylons** (structures with a Soul Ash bounty: while one stands, enemies near it fire from 30% farther;
  destroying it shrinks their range in that area for the rest of the run; one path, read by EmpireKit's reach).
  **Scrap storms** (every few minutes, 20 s: everyone's sight range halved; a window to close in). Miniboss **the
  Trojan Horse** (four-legged drone tank, slow homing rockets your summons can intercept, at low HP its hull splits
  and Scout Drones pour out). Boss **Kestrel, the Dead Pixel** (cyborg markswoman, figure-redesign style: sniper
  perches, triple Lock-On lines, decoy drones, last phase twin blades and a charge).
- **Achievement** Static in the Wastes (clear the Wastes) → counter-passive **Lead-Lined Bones** (ranged hits on your
  summons deal less; offered only in Act III through the card row's `act`; one path in `CombatResolver.damage_unit()`
  for ranged sources).
- **Kinds:** Aegis Bot (soldier, machine, melee; frontal energy shield that stops your projectiles: hit from the
  side or above, area spells, stomps) and Mortar Walker (heavy, machine; arcing shells with landing circles via
  `fire_arc_at()`, ignore Line of Fire).
- **Spell:** Death Ray (unlocked by Kestrel; soul laser sweeping a full circle around the necromancer every few
  seconds, ~420 px, moves with you; a beam kill sparks lightning to one nearby enemy) / evolution **Event Horizon**
  (two opposite beams; kills set off chain lightning through up to 4) + paired passive **Conductive Marrow** (longer,
  wider beam). Through `NecroSpellBook`'s one dispatch.
- **Character:** the **Lightning Abbess** (figure-redesign style; innate: beam kills spark lightning to one more
  enemy), Hyper skin, Untouchable and Deathlord skins.

## Agent B: the Assembly Halls (`assembly`, Stage 8)
- **Stage:** zones the Loading Docks, the Conveyor Floor, the Fabricator Hall, the Furnace. **Conveyors** (belt
  lanes push everyone along: add the push to `TerrainSlow`, the one ground path, so it stays one rule).
  **Fabricators** (structures that build a new enemy every few seconds until smashed; each destroyed thins the waves
  for the rest of the run). **Furnace channels** (floor strips that burn anything in them, enemies included).
  Miniboss **the Beta Build** (an unfinished mech that patches itself from any fabricator still standing). Boss **the
  Motherboard** (construction titan with two crane arms: grabs summons and hurls them, press-stamps on telegraphed
  squares, magnet-pulls the army out of the ring, builds turrets mid-fight: its own small boss-turret kind in your
  table, since the Sentry Turret belongs to the Citadel agent).
- **Achievement** Cold Assembly (destroy every fabricator in one run) → counter-passive **Signal Ghost** (Lock-On lines
  take longer to paint on the necromancer; the hook exists: `LockOn.paint_time()` reads `PassiveData` row
  `signal_ghost` value `paint_time`; Act III only).
- **Kinds:** Arc Engineer (support, cyborg, medium range; repairs machines, briefly jams nearby summons for 2 s
  through `HordeDirector.add_suppression()`; a priority target) and Juggernaut (heavy elite, machine; armoured
  flamethrower walker, flat armour like the Sanctified Sentinel).
- **Spell:** Hollow Puppet (unlocked by the Motherboard; curses the strongest nearby non-boss enemy: it fights for
  you 8 s, then dies) / **Puppet King** (two puppets; a puppet that dies explodes) + **Strings of the Dead**.
- **Character:** the **Marionette** (figure-redesign style; innate: puppets last 25% longer and hit harder), Hyper
  skin, Untouchable and Deathlord skins.
- **Summon class:** **Grave Drone** (unlocked by the Motherboard; a flying swarm of skull drones, three to a card,
  hovering over the army firing bone darts; cannot be body-blocked) / evolution **Wraith Drone** + paired passive
  **Overclock**. One `SummonBehavior`, works the same on every stage.

## Agent C: the Iron Citadel (`citadel`, Stage 9, the finale)
- **Stage:** zones the Shield Gates, the Laser Courts, the Spire Lifts, the Core. **Shield gates** (energy walls
  blocking the way into each new zone until their two generators fall; enemies pour out while it holds). **Laser
  grids** (sweeping beams on a fixed rhythm, telegraphed 1 s, hurt enemies too). **Citadel guns** (orbital strikes on
  telegraphed circles, more often the deeper you go; reuse the Purge Protocol's strike code in `EmpireRules`, don't
  copy it). Sentry Turrets as fixed structures (Soul Ash bounty). Miniboss **Valkyrie 2.0** (jet dash, shield bash,
  blade storm; figure-redesign style). Boss **Deus Ex Machina** with **Varn, the Root User**: the three phases of the
  proposal (the Walker with four breakable leg plates, chaingun sweep under Line of Fire, a four-line missile salvo
  through `boss_override`, stomps; the Siege Core with shield drones, the Judgment Lance that summons body-block,
  hangar doors; the Founder with escalating overload pulses and teleports), the banner **"Nothing is deathless.
  Everything is mine."** and the ending text (like Vhal'Neth's).
- **Achievement** Nothing Is Deathless (defeat Deus Ex Machina) → title **"Breaker of Engines"** (`TitleData`) and the
  flag that opens the Act III epilogue (the lead builds the 4 epilogue panels at integration; leave a documented hook
  in `epilogue_data.gd`).
- **Kinds:** Valkyrie Duelist (elite, cyborg, female, figure-redesign style; jet-assisted lunge through the ring
  toward the necromancer with an arm blade; blockers stop it) and Sentry Turret (structure, machine; fixed, the one
  exception to "always advance"; Soul Ash bounty).
- **Spell:** Scrap Swarm (unlocked by Deus Ex Machina; bone-and-scrap drones orbiting OUTSIDE the Bone Ring, ~40 px
  past its outer edge, so the orbit widens with the army; they shoot enemies before they reach the army) /
  **Deathless Swarm** (more drones; each kill adds one for 10 s) + **Machine Soul**.
- **Character:** the **Rust Prophet** (an Empire engineer who defected to death; innate: every temporary Risen fires a
  scrap bolt every few seconds, through `spawn_temporary()`), Hyper skin, Untouchable and Deathlord skins.
- **Summon class:** **Iron Revenant** (the finale's reward; a reanimated war walker holding a back post on the Bone
  Ring, suppressive fire that slows) / evolution **Deus Revenant** (twin cannons, a missile salvo) + paired passive
  **Recoil Frame**.
