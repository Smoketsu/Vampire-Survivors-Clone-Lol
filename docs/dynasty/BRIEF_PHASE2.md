# The Necropolis Dynasty, phase 2: brief for the three stage agents

Written by the foundation agent for the lead (branch `dynasty-foundation`, base `a3e4f5b`). The lead adds the merge
commit, the owner's phase 2 answers (if any) and the session line before handing it out.

Three agents run at the same time, one per stage, each in its own worktree on its own branch made from the lead's branch
that holds the merged foundation (code, art and audio). The lead merges the branches and runs one big test pass after.

This is the plan that built Acts IV to IX: `docs/act9/BRIEF_PHASE2.md` is the model, and through it the Act VI–VIII phase 2
briefs. Read the Act VI brief's "Shared files, testing and process" section: it applies unchanged with the Dynasty's
names, blocks headed `# --- Act XII (temporary number): <your stage> ---`, and your own scratch dir.

## Read first
1. **`CLAUDE.md`** (it wins). In particular: no shader may read the screen (the Sandstorm is a flat rect and one image
   texture), textures over polygons redrawn every frame, never `AudioServer.add_bus()`, **summons never get act-only
   rules** (curses, slows, drags and stuns are enemy effects through the one paths: `CombatResolver.curse_unit()`,
   `stun_unit()`, `TerrainSlow` / `FenWater.wade()`, `damage_unit()`), co-op reads the necromancer through the bound slot.
2. **`docs/last_acts/PLAN.md`:** temporary act number 12, **tune for the final slot VII** (Shogunate / Olympus level),
   no epilogue part and no closing card, real mythology names, female figures in the figure-redesign style (clothed),
   enemies in the duller bronze-gold (true gold is the player's reward colour).
3. **The design:** `docs/proposals/NEW_ACTS_AND_ORDER.md` Part 3 (your stage's section and its rewards are the spec) and
   the Dynasty section of `docs/proposals/LAST_SIX_ACTS.md`, which wins where they differ. Concept art:
   `art_source/concepts/final5/dynasty_lineup.png`, `dynasty_bosses.png`, `dynasty_stage.png`.
4. **`docs/GDD.md` §15.0:** "The Necropolis Dynasty foundation (phase 1)", "Rebirth", "The Black Land", "Heka", "The
   Devourer's Hour", the Dynasty art and audio rows, and the Act IX phase 2 rows for how a stage was built last time.
5. **The code:** `README.md` (*Act XII: the Necropolis Dynasty*), your stub `scripts/data/stages/<id>_stage.gd`, the
   folder `scripts/enemies/dynasty/` (`dynasty_rules.gd`, `rebirth.gd`, `quicksand.gd`, `sandstorm.gd`, `heka.gd`,
   `devourers_hour.gd`, `dynasty_kit.gd` and the kits), `dynasty_enemy_data.gd`, `dynasty_rules_data.gd`,
   `scripts/core/dynasty_report.gd` / `dynasty_ground.gd` / `dynasty_glyphs.gd`, your stage's empty table, and the
   closest built stage (the Crash Site's director and egg hook for the Necropolis; Olympus's god trial and Ilion's
   structures for the Temple; Castle Sanguis or the Ark for the finale).

## Extension points of the foundation (use these; do not fork them)
- **The rule object.** `Game.dynasty` (`DynastyRules`) is created by the STAGE key `dynasty`, null everywhere else. Parts:
  `rebirth`, `quicksand`, `sandstorm`, `heka`, `devourer`, plus the `embalmers` list.
  - `DynastyRules.enabled` is true only on a Dynasty stage (a Dynasty kind forced elsewhere makes the rules with the
    clocks off). Stage-only things check the stage, not just `game.dynasty != null`.
  - `DynastyRules.danger_push(p)` is what the army bot reads (today the Devourer's lanes). Add your hazards there,
    additively; a kit's own telegraph goes in its `danger_push(e, p)` (the khopesh spin is the model).
  - `DynastyRules.play_sound(event, pos, gap)`; events in `DynastyRulesData.SOUNDS` (your own block at its end).
  - Each stage director goes in `scripts/enemies/dynasty/<id>_director.gd`, switched on by its own STAGE key and created
    and stepped from `EnemyDirector` like `CrashSiteDirector`.
- **Rebirth** (`game.dynasty.rebirth`). The kill hook, the smash and the raise steal are built; never add a second one.
  - Row key `rebirth: true` makes a kind return (guardians and mummies only; beasts and statues never).
  - `place_jar(at)` puts a Canopic Jar down (the Necropolis's jars beside the tombs). A stage that places its own jars
    sets STAGE `"jars": {"every": 0.0}` to turn the stub clock off.
  - STAGE `rebirth` overrides any `REBIRTH` key: `jars_required` (only Names a jar holds return: Anubis's Procession),
    `duration` (the Scales' "Rebirth timers 2 s shorter" through a phase-time override is yours to add as ONE method on
    `Rebirth`, e.g. `set_duration_bonus()`), `max_returns`, `damage_mult`.
  - `unlimited` (the Devourer's Hour sets it; Osiris may for a phase), `eat(c)` (Ammit's corpse eating), `on_raise(pos)`
    (counts toward the Scales' "each raise tips it"), the counters (`laid`, `returned`, `stolen`, `smashed`, `crumbled`,
    `eaten`) for the Scales and the achievements (Names Taken, No Jars Left).
  - The Embalmer's haste reads `DynastyRules.embalm_rate()`; Anubis's "the Embalmer: the cartouche timer is 3 s while he
    does" is one more condition there (one method, your block).
- **The Black Land.**
  - `quicksand.add_patch(at, radius, life)` (the Crocodile Warden rises from it; Sekhmet's dunes). STAGE `quicksand`
    overrides (`"chance": 0.0` = no fixed patches, e.g. inside the Temple's halls).
  - `sandstorm.force(duration)` (Sekhmet's Red Wind: "she calls a Sandstorm early"), `is_up()`, `reach_mult()`. Enemy
    rows with `storm_silenced: true` hold their shots while it blows (the Nile Archer). STAGE `sandstorm` overrides any
    key (the Necropolis's Sandstorm Pass may blow longer).
- **Heka.** `heka.write(priest, u)` is the one call (Osiris's "Heka glyphs at speed"); `heka.set_jump_speed(2.0)` is
  the Red Wind's "the glyph spreads at double speed". Never write `SummonedUnit.heka_*` directly.
- **The Devourer's Hour** is the shared Reckoning; tune it only through your RECKONING's `devourers_hour` keys and its
  `companions`.
- **Counter-passive hooks are built** (exactly neutral today). Build only the PassiveData rows, offered in this act only
  through the card row's `act` (use `12`; the reorder renumbers):
  - **Embalmed Bones** (`DynastyRulesData.EMBALMED_BONES`, keys `glyph_shed`, `cursed_damage_cut`): `embalmed_shed_mult(u)`
    is read by `Heka.write()`; `embalmed_taken_mult(u)` is NOT read yet: add its one read in `CombatResolver.damage_unit()`
    (a cursed summon, `u.heka_until > game.elapsed`, only while `game.dynasty != null`) with the passive.
  - **Dune Walkers** (`DUNE_WALKERS`, keys `sand_slow_cut`, `storm_reach_kept`): read by `Quicksand` and
    `army_reach_mult()`.
- **Kits and rows.** Extend `DynastyKit` (`returns`, the storm on a ranged bow, the fire weakness `fire_taken`, the
  registration); call `super.reset()` / `super.physics()` / `super.on_deactivate()` / `super.taken_mult()`. Row keys:
  `group` (dead, beasts, guard, priests, stone), `rebirth`, `fire_taken`, `embalms`, `holds_names`, `storm_silenced`.
  Kit ids must be unique across all nine kit folders. Bosses in `scripts/enemies/dynasty/boss_<id>.gd`
  (`EnemyDirector.DYNASTY_BOSS_DIR`); remove your stub's `"script": "vael"`. Minibosses through
  `EnemyDirector.set_miniboss()`. New shared kinds: rows in your own block at the end of `DynastyEnemyData`; stage-only
  things in your stage's table.
- **Art keys.** Sprites load from `assets/sprites/dynasty/<kind_id>.png` (the art pass names: `mummy`, `mummy_female`,
  `scarab_swarm`, `khopesh_guard`, `nile_archer`, `heka_priest`, `embalmer`, `jackal_warrior`, `bastet_hunter`,
  `crocodile_warden`, `ushabti_statue`, `canopic_jar`, `sand_colossus`, `lion_warden`). `dynasty/cartouche` and
  `dynasty/heka_glyph` replace the code icons when they exist; `tiles/dynasty_quicksand` the quicksand discs.
- **Report.** A per-stage file beside `dynasty_report.gd` (`necropolis_report.gd` ...), called from the marker in
  `DynastyReport.print_lines()`, one line in your own block. **Codex:** your kinds in the `CodexData.DYNASTY_*` group
  lists (statues in `DYNASTY_STONE`, beasts in `DYNASTY_BEASTS`), your miniboss with its group.
- **Unlocks, spells, characters, classes, achievements** as in Acts VI–IX (`UnlockData` / `Unlocks`, the one
  `NecroSpellBook` dispatch, `character_data.gd` with Hyper / Untouchable / Deathlord skins, one `SummonBehavior` per
  class, its Ossuary mastery). Ids must not collide with kinds, structures, source tags, sound or rule names (check
  `dynasty_enemy_data.gd`, `DynastyRulesData`, the sound packs; `rebirth`, `heka`, `sandstorm`, `devourer` are taken).

## The new kinds, split across the stages
The foundation built `mummy`, `mummy_female`, `scarab_swarm`, `khopesh_guard`, `heka_priest`, `embalmer`, `canopic_jar`
(and the `cartouche`). The rest of the roster, one stage each:
- **The Necropolis of Sand:** the **Nile Archer** (female, figure style, ranged, `storm_silenced`) and the **Jackal
  Warrior** (male, jackal-headed, elite, Rebirth, a fast lunge, packs of two) as shared rows in `DynastyEnemyData`; the
  miniboss **Sand Colossus** (a statue; ground slam) in `NecropolisEnemyData` (the Temple reuses it).
- **The Temple of the Lioness:** the **Bastet Hunter** (female, figure style, cat-masked elite duellist: vanishes into the
  sand, ambushes a ranged summon; area damage reveals her) and the **Ushabti Statue** (stone servant, armour 5, no
  Rebirth) as shared rows; the miniboss **Lion Warden** (male statue-warrior in a doorway) in `LionessTempleEnemyData`.
- **The Hall of Two Truths:** the **Crocodile Warden** (male, heavy, armour 3, rises from the quicksand through
  `add_patch()`, drags a summon in) as a shared row; the miniboss **the Devourer's Whelp** (eats corpses: `Rebirth.eat()`
  on the cartouches near it) in `TwoTruthsEnemyData`.

## Balance (the foundation's flags)
- The stubs are easy for the army bot (seed 7: lowest HP 116/120 on the Necropolis); the stage content is where the
  difficulty comes from. Tune for slot VII with your stage's data first (timeline, HP / damage multipliers, your rows).
- **Heka is cleansed fast** when the army has Menders (seed 7: 184 glyphs, 144 Mender cleanses, under a second each). If
  priests should matter more, the levers are `HEKA.heal_priority` (shared, GDD note) and the priests' numbers.
- **Summons spend many blows on cartouches** (≈2,000 summon smashes a run): it is the counter working. If it starves the
  army's damage, lower the cartouche's `target_priority` (shared row, GDD note) rather than changing the rule.
- **The khopesh spin** is the stubs' largest source of summon damage; the Sandstorm halves the army's ranged reach for
  40 s of every 5 minutes. Watch both in your playtests.
- One Godot process at a time (`pgrep -c Godot` first). Each agent balances its own stage so the army bot ends healthy on
  seed 7 (`--policy=army --mortal`); the Necropolis agent also checks seeds 1 and 2.

## Process
- Do not push; commit in steps; keep `"playable": false`. Commit messages end with the lead's co-author lines.
- Touching a shared path outside the Dynasty folder (`combat_resolver.gd`, `summoned_unit.gd`, `horde_director.gd`,
  `enemy.gd`): also run the Graveyard default and the Ark army runs of `docs/dynasty/tools/gate.sh` against your base,
  one at a time; their `[autotest]` / `[metric]` lines must be identical.

---

## Agent A: the Necropolis of Sand (`necropolis`, final stage 19)
- **Stage:** the tomb road at dusk: dunes, rock-cut tombs and mortuary temples, the outer edge of the Dynasty. Zones: the
  Dunes, the Tomb Road, the Sandstorm Pass, the Mortuary Temple. Four zone floors over the `sand` style, obstacles in
  both orientations (tombs, dune rocks, obelisks, tomb doors).
- **Stage mechanic: Canopic Jars** (teaches the core rule): jars beside the tombs (`Rebirth.place_jar()`, the stub clock
  off); break one and Rebirth stops in its radius.
- **Miniboss: the Sand Colossus** (a statue; ground slam; burst it, stay at range).
- **Boss: Anubis, Opener of the Way** (`boss_anubis.gd`, male, jackal-headed):
  - **the Procession:** he leads a funeral march of mummies; every jar must be broken to end Rebirth (`jars_required`
    for the phase, or one Rebirth method of yours);
  - **the Embalmer:** he wraps the fallen across the map; the cartouche timer is 3 s while he does (`embalm_rate()`);
  - **the Jackal:** he drops the wrapped pose and duels: fast, afterimage lunges.
- **Spell: Linen Bind** (spectral bandages wrap up to 5 enemies and hold them 1.2 s; wrapped enemies that die rise as
  temporary Mummies, through `HordeDirector.raise_corpse()`, so they also steal Names) → **Eternal Shroud** + **Natron
  Salts**. **Character: the Embalmer** (female, figure style).
- **Achievement: No Jars Left** (break every Canopic Jar on the Necropolis); it unlocks a counter-passive (the lead says
  which: Embalmed Bones or Dune Walkers).

## Agent B: the Temple of the Lioness (`lioness_temple`, final stage 20)
- **Stage:** a sun-baked temple of colonnades and statue-lined courts, sacred to the goddess of war and plague. Zones:
  the Avenue of Statues, the Courtyard, the Hypostyle Hall, the Sanctuary. Floors over the `temple` style.
- **Stage mechanic: Awakening Statues:** statues are ordinary Arena obstacles until a zone change or an event wakes a row
  (eyes glow 2 s): each becomes an Ushabti or a Sand Colossus enemy and leaves a gap in the layout (remove the obstacle
  through the arena's own path; record it). No enemy appears from outside; the stone itself walks.
- **Miniboss: the Lion Warden** (male), a huge statue-warrior in a doorway who must be killed to pass.
- **Boss: Sekhmet, the Lioness of Retribution** (`boss_sekhmet.gd`, female, lioness-masked, figure style):
  - **the Hunt:** she leaps between pillars and rakes the ring on a landing circle;
  - **the Red Wind:** `sandstorm.force()` early and `heka.set_jump_speed(2.0)` (reset it after);
  - **the Feast:** enraged, unstoppable; three red-wine jars (structures) fill the arena; break all three while she drinks
    and she stumbles for 4 s, the only window she can be hurt.
- **Spell: Burning Eye** (a solar eye fires a beam that sweeps a 90° arc; a spell source, so it counts as fire for the
  mummies if you add it to `FIRE_SOURCES` with a GDD note) → **Eye of Retribution** + **Desert Fury**. **Character: the
  Lion-Priestess** (female, figure style).
- **Achievement:** the lead names it with the counter-passive split.

## Agent C: the Hall of Two Truths (`two_truths`, final stage 21, the act's finale)
- **Stage:** the judgment hall of the dead: the gate of reeds, the river of fire, the great scales. Zones: the Gate of
  Reeds, the River of Fire, the Hall of the Scales, the Throne of Osiris. Floors over the `hall` style.
- **Stage mechanic: the Scales:** a Balance bar on the HUD (a label like the Sandstorm's line, or a bar; never a screen
  effect). Each Rebirth return tips it toward the Dynasty, each raise (`Rebirth.on_raise()`; read its counters or add
  one notify hook) toward the necromancer. Past a threshold: toward the necromancer, Dynasty enemies deal −15% (ONE read,
  e.g. in `DynastyKit` through `Enemy.hit_mult()`'s existing weaken path or one multiplier of yours); toward the Dynasty,
  +15% and Rebirth timers 2 s shorter.
- **Miniboss: the Devourer's Whelp** (a young hippo-lion-crocodile beast) who eats corpses (`Rebirth.eat()`).
- **Boss: Osiris, Lord of the Dead, and Ammit the Devourer** (`boss_osiris.gd`; Osiris male, Ammit a monster):
  - **the Judge:** Osiris on the throne; Heka glyphs and Rebirth at speed; his court fills the hall;
  - **the Weighing:** the necromancer's heart on the scales for 60 s; ending toward the Dynasty, Ammit eats 30% of the
    summons (through `HordeDirector.on_unit_died(u, false)` or `damage_unit()`; record which); toward the necromancer,
    Osiris's shield breaks by 25%;
  - **the Devourer:** Ammit takes the throne, eats every corpse on the map (`Rebirth.eat()` on every cartouche), charging
    in lanes (the Devourer's lane look); slay her and the throne is empty.
  When Osiris falls, a short ending text only ("no old master has a claim on the dead"); no epilogue part.
- **Spell: Feather's Verdict** (a gold feather lands on the strongest enemy and executes weak enemies in a ring; the
  feather is the player's, so true gold is right here) → **Heart Devoured** + **Heavy Heart**. **Character: the
  Pharaoh's Shade** (male). **Summon class: the Ushabti Sentinel** (finale reward: a stone servant that reassembles once
  every 25 s at half health; evolution Eternal Guard; a class special that works everywhere; its Ossuary mastery).
- **Achievement: A Light Heart** (win the Weighing with the Balance toward the necromancer). It only records the clear
  until the reorder pass writes the epilogue parts.
