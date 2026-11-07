# The Hall of the Slain phase 2: brief for the three stage agents

The foundation agent wrote this brief with the foundation (branch `norse-foundation`, base `a3e4f5b`). The lead adjusts it
after the merge and the owner's phase 2 answers, if any.

Three agents run at the same time, one per stage, each in its own worktree on its own branch made from the lead's branch
that holds the merged foundation. The lead has the branches merged and runs one big test pass afterwards.

This is the Act IX plan: read `docs/act9/BRIEF_PHASE2.md` and, through it, the Act VIII / VII / VI phase 2 briefs. Their
"Shared files, testing and process" sections apply here unchanged, with these substitutions:
- the Norse names (stage key `norse`, `game.norse`, `NorseRules`, folder `scripts/enemies/norse/`);
- blocks headed `# --- Act XI (temporary): <your stage> ---`;
- your own scratch dir under the session's scratchpad.

The act is **temporarily Act XI** (stages 31–33 in the current registry order, stages 16–18 in the final order) and is
tuned for its **final slot VI**: between the Shogunate (Act V) and Olympus (Act IV), not at Act XI's place in the list
(`docs/last_acts/PLAN.md`). No epilogue part and no closing card until the reorder pass.

## Read first
1. **`CLAUDE.md`.** Every convention applies, in particular:
   - no shader may read the screen, and prefer textures over polygons redrawn every frame;
   - never call `AudioServer.add_bus()`;
   - **summons never get act-only rules.** The cold, the curse, the cold touch, the bashes and the dives are enemy or
     world effects on units through the existing one paths: `TerrainSlow.slow_summon()`, `CombatResolver.chill_unit()`,
     `blind_unit()`, `stun_unit()` and `damage_unit()`;
   - co-op reads the necromancer through the bound slot.
2. **`docs/proposals/LAST_SIX_ACTS.md`, section "VI. The Hall of the Slain"**, with the **owner decisions of Nov 7, 2026**
   that override it (GDD §15.0 "The Long Winter replaces the Choosing"):
   - **There is no Choosing.** No valkyrie carries bodies off; no Einherjar return from a kill; no Risen Einherjar. Valkyries
     are a flying spear-diving elite. Ignore every line of the proposal about good deaths, inglorious kills, *Inglorious*
     and *None Chosen*.
   - **The first rule is the Long Winter** (below). Its counter-passive is **Fur-Lined Bones** (the cold slows summons half
     as much; replaces *Inglorious*), its achievement **Keep the Fires** (finish the Barrow Fields with no brazier ever out
     for more than 30 s; replaces *None Chosen*).
   - **Sigrun's last phase** is "the Doors of the Hall: every Einherjar of the hall marches out at her side", a scripted
     wave of Einherjar (`NorseKit.make_einherjar()`), not a replay of the run's kills.
   - Real names (Odin, Fenrir). Every figure's sex is named in its art prompt; female figures (the shield-maiden, the
     valkyrie, the seer, Sigrun, the Rune-Seer, the Shield-Maiden character) are in the figure-redesign style, fully
     clothed.
3. **`docs/GDD.md` §15.0**: the rows from "The Hall of the Slain foundation (phase 1)" to "Ragnarök", and the Act IX phase 2
   rows for how a stage was built last time.
4. **The code**: `README.md`; your stub `scripts/data/stages/<id>_stage.gd`; the folder `scripts/enemies/norse/`
   (`norse_rules.gd`, `long_winter.gd`, `rune_stones.gd`, `ragnarok.gd`, `norse_kit.gd` and the kits);
   `scripts/data/norse_enemy_data.gd`, `norse_rules_data.gd` and your stage's empty table; `scripts/core/norse_report.gd`,
   `norse_ground.gd` and `norse_glyphs.gd`.
5. **Art**: the approved concepts `art_source/concepts/final5/norse_lineup.png`, `norse_bosses.png` and `norse_stage.png`, and
   the art agent's `norse/` sprites (`assets/sprites/norse/<kind>.png`: the code loads them by kind id; a missing PNG falls
   back to `NorseGlyphs`). Odin may move further from a wizard silhouette (an eyepatch, a darker cloak), as the proposal notes.

## Extension points of the foundation (use these; do not fork them)
- **The rule object.** `Game.norse` (`NorseRules`) is created by the STAGE key `norse`; null on every other act. Its parts:
  `winter` (`LongWinter`), `stones` (`RuneStones`), `ragnarok` (`Ragnarok`), plus `first_seen` and `furies`.
  - `NorseRules.enabled` is true only on a Norse stage; a Norse kind forced elsewhere makes the rules with the cold, the
    braziers, the timeline stones and Ragnarök off. Stage-only additions check the stage.
  - `NorseRules.danger_push(p)` is what the army bot reads (zero today; the dives and boulders use the shared telegraph
    circles and the kits' `danger_push()`). Add your hazards there, additively.
  - `NorseRules.play_sound(event, pos, gap)`; events in `NorseRulesData.SOUNDS` (existing sounds for now; the audio pass
    brings the Norse pack and the lead switches the ids and the stub's music key `bronze`).
  - **A further rule slots in the same way** as `winter` and `stones`: its own child node created in `NorseRules._init()`,
    stepped in `step()`, numbers in `NorseRulesData`, a line in `NorseReport`.
  - Each stage director goes in `scripts/enemies/norse/<id>_director.gd`, switched on by its own STAGE key and created and
    stepped from `EnemyDirector` like `CrashSiteDirector`.
- **The Long Winter** (`LongWinter`, STAGE key `long_winter` overrides any key of `NorseRulesData.LONG_WINTER`):
  - the cold level `level` (0 → 3, a step every 5:00); `cold_slow()`, `cold_bite()`, `is_warm(p)`;
  - `place(at)` is THE brazier call; the stub places six on a seeded ring around the start: **place yours by the stage's
    map** with the STAGE `long_winter` `"points"` (offsets from the start) or `place()` from your director;
  - the douse reads the row key `douses` (the frost giant and the seer today; give it to your kinds that should);
  - `fur_mult()` is the **Fur-Lined Bones** hook (`NorseRulesData.FUR_LINED_BONES` = `"fur_lined_bones"`, key `FUR_KEY` =
    `"cold_slow_cut"`, 0.5 at full): build only the PassiveData row, offered in this act only through the card row's `act`;
  - `longest_out()` is what **Keep the Fires** reads (`NorseRulesData.KEEP_THE_FIRES_MAX_OUT` = 30 s; the Barrow Fields
    agent builds the achievement);
  - Vigrid's **Fading Light** (the proposal's "Long Winter" stage feature: the light fades zone by zone) is a stage effect
    of its own; it may raise the cold through a STAGE override (e.g. a faster `step_every`) but must not fork the rule.
- **Berserkergang**: `Enemy.berserk` is THE one enemy stat, written only by `NorseRules.enter_fury(e, wounded)`. Rows with
  `warrior: true` go berserk below 40% HP (`NorseRules.on_enemy_hit()`, called once from `damage_enemy()`); rows with
  `berserk_always` start in it. Hrimgar's draugr and Sigrun's valkyrie wing are not warriors unless you say so in their rows.
  **Calm Blood** (berserk enemies deal 20% less damage to summons) is a counter-passive to build as a hook read where
  `Enemy.hit_mult()` reads the fury, exactly 1 while not owned.
- **Rune-Stones** (`RuneStones`, STAGE key `rune_stones`): `raise_stone(at, opts)` is THE call (the timeline event type
  `"rune_stone"` with `count`; `opts.table` gives a stone its own horn squads); the signal **`horn_blown(at)`** is where
  Valgard's **Feast** wakes the Einherjar at the tables; `ward_mult(e)`, `warded(p)`, `nearest_taken()`, `carve()`.
- **The Einherjar**: `NorseKit.make_einherjar(e)` turns a just-spawned elite warrior gold and stronger
  (`NorseRulesData.EINHERJAR`). Use it for the Feast, the Einherjar Champion and Sigrun's Doors of the Hall.
- **Ragnarök** (`Ragnarok`, RECKONING `ragnarok`): the dark red wash, the hall's Einherjar march (`einherjar`,
  `einherjar_kinds`), fire-giants from the south edge (`giants`, `giant_every`), every valkyrie dives
  (`NorseValkyrieKit.force_dive()`). Tune only through your stage's RECKONING `ragnarok` keys and `companions`. Vigrid's
  "the Reckoning's dark arrives early in the last zone" is Vigrid's own effect.
- **Kits and row keys.** Extend `NorseKit` (`super.physics()` first). Ids must be unique across all nine kit folders: the
  Empire already owns `valkyrie` (hence `norse_valkyrie`). Row keys: `group` (`warriors`, `hall`, `wilds`), `warrior`,
  `berserk_always`, `douses`, `flight_melee_taken` (the Night Wings test; `landed()` lets blows land), and each kit's own
  numbers. Bosses go in `scripts/enemies/norse/boss_<id>.gd` (`hrimgar`, `sigrun`, `odin`; `EnemyDirector.NORSE_BOSS_DIR`);
  remove your stub's `"script": "vael"`. Minibosses register through `EnemyDirector.set_miniboss()`. New shared kinds are rows
  in `NorseEnemyData` (your own block at the end); stage-only ones go in your stage's table.
- **Summon paths you may use**: `CombatResolver.chill_unit(u, fraction, duration, source)` (the one enemy slow on a summon,
  the draugr's cold touch), `blind_unit()` (the seer's curse), `stun_unit()` (the Barrow-Wight's howl), `damage_unit()`.
- **Report**: a per-stage report file beside `norse_report.gd`, called from the marker in `NorseReport.print_lines()`.
- **Codex**: new kinds in `CodexData.NORSE_WARRIORS` / `NORSE_HALL` / `NORSE_WILDS`; bosses are already listed.
- **Unlocks, spells, characters, classes, counter-passives and achievements** work as in Acts VI–IX (`UnlockData`, the one
  `NecroSpellBook` dispatch, `character_data.gd`, one `SummonBehavior` per class, Ossuary masteries).

## The new kinds, split across the stages
The foundation built the whole roster as shared kinds: `raider`, `shield_maiden`, `berserker`, `skald`, `valkyrie`, `seer`,
`draugr`, `wolf_of_the_wastes`, `frost_giant`, `fire_giant`, and the `rune_stone` and `brazier` structure rows. Phase 2 adds:
- **The Barrow Fields:** the open barrows (a structure that lets draugr out until broken), the miniboss **Barrow-Wight**.
- **Valgard:** the feasting **Einherjar** at the tables (obstacles that wake on every horn), the miniboss **Einherjar
  Champion**, Sigrun's valkyrie wing.
- **Vigrid:** the miniboss **Fire-Giant of the south** (extends `FireGiantKit`, the burning tracks), Odin's ravens, Fenrir.

## Balance
Tune for slot VI: the stubs use HP ×1.6 / 1.65 / 1.7 and damage ×1.4 / 1.45 / 1.5 from 7:00 (a hair above the Shogunate's
HP, between Olympus's and the Shogunate's damage). Compare with `docs/act4/playtest/` and `docs/act5/playtest/`. The army bot
on seed 7 must end healthy; watch the cold (the `long winter` line's "army summon-s" and frostbite) and the Rune-Stones' horns
(`rune-stones` line) first. One Godot process at a time.

---

## Agent A: the Barrow Fields (`barrow_fields`, Stage 16 in the final order)
Snowfields of burial mounds above a frozen fjord. Zones: the Longshore, the Barrows, the Frozen Fjord (snow slows everyone
through `TerrainSlow`), the Jarl's Hall. The draugr lead the timeline.
- **The braziers** placed by the map (`long_winter` `"points"`), and **Keep the Fires** (no brazier out more than 30 s).
- **Open barrows:** mounds that crack open on a 2 s telegraph and let draugr out until the mound is broken.
- **Miniboss, the Barrow-Wight:** a draugr chieftain whose howl stuns the ring for 1 s (`stun_unit()`).
- **Boss, Hrimgar the Draugr-King** (male): he rises three times; each time he falls he sinks into his barrow and returns
  stronger 20 s later, unless the necromancer breaks the barrow while he is down. Phases: the Grave (frost mist and draugr
  from every mound), the Barrow Lord (a cleaving greatsword), the Last Rising (he drags summons into the mound with him: an
  enemy hold through the existing hooks).
- **Rewards:** **Barrow Grasp** (cold hands burst from the ground in a ring and hold enemies) → *Barrow-Lord's Embrace* (+ Grave
  Frost); **the Rune-Seer** (female, figure style); counter-passive **Fur-Lined Bones**; achievement **Keep the Fires**.

## Agent B: Valgard, the Hall of Heroes (`valgard`, Stage 17)
A vast feast hall at the edge of the sky, long tables and shields on the walls. Zones: the Shield Yard, the Mead Hall, the
Hall of Spears, the Valkyries' Gate. Warriors and valkyries lead.
- **The Feast:** Einherjar sit at the long tables as obstacles that wake whenever a horn blows (`RuneStones.horn_blown`), then
  fight (`make_einherjar()`).
- **Miniboss, the Einherjar Champion,** a gold-lit hero of a thousand years in the hall.
- **Boss, Sigrun, the Shield-Queen** (female, figure style): **the Charge** (spear dives across the ring on telegraphed lines
  with her valkyrie wing), **the Holmgang** (a square of hazel rods closes around her and the necromancer for 15 s; summons
  cannot enter; spells and Grave Step only), **the Doors of the Hall** (every Einherjar of the hall marches out at her side: a
  scripted wave).
- **Rewards:** **Valkyrie Spear** (a spectral spear dives on the strongest enemy and chains to the next) → *Chooser of the
  Slain* (+ Einherjar's Oath); **the Shield-Maiden** (female, figure style); counter-passive **Calm Blood**; achievement
  **Holmgang** (win Sigrun's duel without Grave Step).

## Agent C: Vigrid, the Last Field (`vigrid`, Stage 18, the act's finale)
The plain where the last battle is fought, under a sky going out. Zones: the Frozen Sea, the Ash Plain, the Giants' March, the
Field of Vigrid. Giants and wolves lead.
- **The Fading Light:** the light fades zone by zone, and the Reckoning's dark arrives early in the last zone.
- **Miniboss, a Fire-Giant of the south,** who leaves burning tracks.
- **Boss, Odin and Fenrir** (the one-eyed god, male, and the great wolf): **the Wolf** (Fenrir breaks his chain and hunts the
  ring; he swallows a summon whole and spits it out 4 s later: an enemy hold through the existing hooks), **the All-Father**
  (Gungnir, a throw at the strongest summon that no blocker stops, dodged only by Grave Step or a Bone Wall; his ravens mark
  the necromancer), **Ragnarök** (both at once, the arena burning, until one falls; the other follows within 30 s).
- **Rewards:** **Gungnir** (a spear thrown at the strongest enemy on screen that pierces everything in its line) → *Spear of the
  Hanged* (+ Runecraft); **the Berserker** (male); the finale summon class **the Draugr Thane** (a heavy undead jarl, a blocker
  whose frost-axe slows what it hits; evolution *Barrow King*); achievement **Twilight of the Wolf** (beat Odin and Fenrir).
