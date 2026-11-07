# Act IX phase 2: brief for the three stage agents

The lead wrote this brief after the foundation merged (`957a8f5`) and the owner answered the phase 2 questions (Nov 3,
2026).

Three agents run at the same time, one per stage. Each works in its own worktree on its own branch, made from the lead's
branch that holds the merged foundation (`957a8f5` or later). The lead has the branches merged and runs one big test pass
afterwards.

This is the Act VIII plan: see `docs/act8/BRIEF_PHASE2.md` and, through it, `docs/act7/BRIEF_PHASE2.md` and
`docs/act6/BRIEF_PHASE2.md`. Read them. The Act VI brief's "Shared files, testing and process" section applies here
unchanged, with three substitutions:
- Act IX names;
- blocks headed `# --- Act IX: <your stage> ---`;
- the scratch dir `/tmp/claude-0/-home-user-Vampire-Survivors-Clone-Lol/b0031aa1-78e2-5d60-8763-4014a0c61c3c/scratchpad/act9/<id>/`.

Act IX is the last planned act. Read this brief in full, then your stage's section.

## Read first
1. **`CLAUDE.md`.** Every convention applies, in particular:
   - no shader may read the screen, and prefer textures over polygons redrawn every frame (beams, turf, eggs, acid and
     tractor cones are textures);
   - never call `AudioServer.add_bus()`;
   - **summons never get act-only rules.** Lifts, stuns, psionic pulses and acid are enemy effects on units. They go
     through the existing one paths: `Abduction.lift()` (the held hook), `CombatResolver.stun_unit()`,
     `TerrainSlow.slow_summon()` and `damage_unit()`;
   - co-op reads the necromancer through the bound slot.
2. **`docs/act9/PROPOSAL.md`.** The owner's answers are at the top: those of Oct 31 and the **phase 2 answers of Nov 3**,
   which override the stage sections and the rules below them. Your stage's section and its rewards are the spec, with
   these answers applied:
   - **One coalition.** The Brood lead the Crash Site, the Vrask the Proving Moon and the Harvesters the Ark. The
     Luminous are in every stage.
   - **The three shared rules are Beams, Abduction and Terraforming.** Ignore every line about Adaptation, "ADAPTED" or
     Gravity Wells.
   - **A plain finale.** The Harvester fights as written; no twist.
   - **No epilogue part, no closing card and no epilogue hook.** The Last Harvest only records the clear. Build nothing
     for the "Ark harvest log" that `docs/proposals/NEW_ACTS_AND_ORDER.md` mentions, and write nothing that contradicts
     it.
   - Every prompt names the figure's sex (or says it is a creature or a machine). Female kinds and characters are in the
     figure-redesign style (clothed; chest and hips covered, no nudity).
   - **No Concord unit is ever in the necromancer's violet and bone.** Insects and machines keep their own colours (the
     Brood green-black chitin with acid green, the Harvesters hull white and gunmetal with plasma green, the Vrask teal,
     the Luminous pale white-gold). The Hive Mother's purple is her own `hive` ramp.
3. **`docs/GDD.md` §15.0.** Read these rows:
   - the Act IX rows from "Act IX build starts" and "Act IX foundation (phase 1)" to the last Act IX row: Beams,
     Abduction, Terraforming, the Final Harvest, the art and "The Reaping Stars and the Concord sounds";
   - "Act IX phase 2: owner answers";
   - the Act VIII phase 2 rows (from "Skid Row (Act VIII phase 2)" on), for how a stage was built last time.
4. **The code.** Read these:
   - `README.md`;
   - your stub `scripts/data/stages/<id>_stage.gd`;
   - the Concord folder `scripts/enemies/concord/` (`concord_rules.gd`, `concord_beams.gd`, `abduction.gd`,
     `terraforming.gd`, `final_harvest.gd`, `concord_kit.gd` and the kits), `concord_enemy_data.gd` and
     `concord_rules_data.gd`;
   - `scripts/core/concord_report.gd`, `concord_ground.gd` and `concord_glyphs.gd`;
   - your stage's empty table;
   - the Act VII or VIII stage closest to yours (its director, boss, report and data): Ravensmoor's Ghoul hook for the
     Crash Site, Vargr's leaps and Broken Arrow's countdown for the Proving Moon, Castle Sanguis and Liberty Heights for
     the Ark.
5. **Art.** Read these:
   - ART_BIBLE "Act IX: the Concord of Stars, the shared kinds and the turf";
   - the owner-approved concepts `art_source/concepts/act9_lineup.png`, `act9_boss.png` and `act9_stage.png` (match
     them; the `_r1` / `_r2` files are old rounds);
   - the contact sheet `docs/act9/art_contact_sheet.png` and the turf mock `docs/act9/art_mock_turf.png`.

   Convert with `prepare_sprite.py` on the source and the `concord/` ramps (`hull`, `gunmetal`, `plasma`, `laser`,
   `chitin`, `vrask`, `lumen`, `lavender`, `turf`; `hive` and `hive_bone` only for the Hive Mother through `KEY_RAMPS`).
   Female figures get a `bust` rig, the hip `swish` and an idle strip. Fliers glide or hover.

## Extension points of the foundation (use these; do not fork them)
- **The rule object.** `Game.concord` (`ConcordRules`) is created by the STAGE key `concord`. It is null on Acts I–VIII.
  Its parts are `beams`, `abduction`, `terraforming` and `harvest`, plus the `prisms` list.
  - `ConcordRules.enabled` is true only on an Act IX stage; a Concord kind forced elsewhere makes the rules with the pods
    and the Final Harvest off. Anything stage-only you add checks the stage, not just `game.concord != null`.
  - `ConcordRules.danger_push()` is what the army bot reads to step out of danger (today it forwards to
    `ConcordBeams.danger_push()`). Add your new hazards there, additively: burrow mounds, acid pools, the Hive Mother's
    eruptions, Vrask'Tal's bomb, the Ark's hazards.
  - `ConcordRules.on_enemy_hit(e, source)` is the one burn check, called once at the end of `damage_enemy()`.
  - `ConcordRules.play_sound(event, pos, gap)` plays a Concord event (events in `ConcordRulesData.SOUNDS`).
  - Each stage director goes in `scripts/enemies/concord/<id>_director.gd`. It is switched on by its own STAGE key and
    created and stepped from `EnemyDirector` like `SkidRowDirector` and `RavensmoorDirector`.
- **Beams.** `ConcordBeams.fire(owner, dir, style, overrides, boss_override)` is THE beam path. Every new Concord beam goes
  through it: the Archon's, Vrask'Tal's, the Harvester's, the Hive Mother's if she has one.
  - Styles live in `ConcordRulesData.BEAM_STYLES` (`probe`, `lock`, `sweep`, `eye`). A kind picks one with its row's
    `beam` (the style id plus overrides of its numbers). A new style is a row in your own block at the end of
    `BEAM_STYLES`.
  - `overrides.target` is what the aim tracks. `boss_override` raises the cap from 6 to 12.
  - Helpers: `has_beam(owner)`, `is_firing(owner)`, `danger_push(p)`.
  - `ConcordKit.on_beam_fired(e)` is the kit's hook when its beam fires (the Vrask hunter uses it to reveal itself).
  - Reflections (Orb Shields, barriers) and prism splits are automatic. Never hit enemies with a Concord beam except
    through a reflection.
  - **Only the Crash Site agent edits `concord_beams.gd`** (the Bone Wall stop, below). The other two agents read it
    and ask the lead if they need a change there.
- **Abduction.** `Abduction.lift(saucer, u)` is THE lift (any `Enemy` can be the "saucer": a Harvester emitter too).
  - Before lifting, check `has_room()` and `liftable(u)`. `pick(at, reach)` is the deterministic choice.
  - `holding(saucer)` and `release_all(saucer)` handle the hold. The saucer dying or being pooled drops what it holds
    through `ConcordRules.note_gone()`.
  - `uncapped` lifts the cap of 3 (the Final Harvest sets it; the Harvester's Reaping may set it for its phase and
    clear it after).
  - `Abduction.carry()` is the one place that moves a lifted summon. The hold is `SummonedUnit.held_until`, plus one
    `stun_unit(u, hold, "abduction")`.
- **Terraforming.** `game.concord.terraforming` (STAGE key `terraforming` overrides any key of
  `ConcordRulesData.TERRAFORMING`; `{}` keeps the defaults).
  - `seed(at, radius, opts)` grows turf (`"live": true` makes it live at once; `"tag"` names the report stat). Use it
    for the Hive Mother's crater, the Ark's vents and the Harvester's Gardener phase.
  - `burn(pos, r)` scorches turf; `live_at(p)` tests a point.
  - `add_pod(e)` and `pod_destroyed(e)` are the pods' calls (`ConcordTerraformerKit`).
  - The heal goes through `CombatResolver.heal_enemy()`. Bosses and minibosses heal at `boss_mult` (0 by default).
- **The counter-passive hooks are built.** Build only the PassiveData rows, offered in Act IX only through the card row's
  `act` (Kevlar Bones' row is the model):
  - **Mirror Bones:** `ConcordRules.mirror_reflect_mult()` and `mirror_taken_mult(u)`. Ids `ConcordRulesData.MIRROR_BONES`
    (`"mirror_bones"`), keys `MIRROR_REFLECT_KEY` (`"reflect_damage"`) and `MIRROR_TAKEN_KEY` (`"beam_reduction"`).
  - **Anchored:** `ConcordRules.anchored_hold_mult(u)` and `anchored_breaks(u)` (read by `Abduction.on_saucer_hit()`).
    Id `ConcordRulesData.ANCHORED` (`"anchored"`), key `ANCHORED_KEY` (`"hold_cut"`, 0.5 at full: "half as long").
- **Kits and row keys.** Extend `ConcordKit`. Put kits in `scripts/enemies/concord/<id>_kit.gd`; ids must be unique
  across all eight kit folders.
  - Row keys: `race` (one of `brood`, `harvesters`, `vrask`, `luminous`), `beam`, `abducts`, `cloak` (the Vrask cloak's
    numbers), `heals_on_turf` (default true; false for structures and eggs), `flight_melee_taken` (the Night Wings test
    for fliers), `lumen_shield` (a share of max HP through `Enemy.holy_shield`) and `prism`. Flying uses the existing
    `flies` / `phases` / `floating` keys.
  - Put bosses in `scripts/enemies/concord/boss_<id>.gd` (`hive_mother`, `vrask_tal`, `harvester`;
    `EnemyDirector.CONCORD_BOSS_DIR`), and remove your stub's placeholder `"script": "vael"`.
  - Minibosses register through `EnemyDirector.set_miniboss()`.
  - New shared kinds are rows in `ConcordEnemyData` (your own block at the end), so any stage may use them. Stage-only
    things go in your stage's table: `CrashSiteEnemyData`, `ProvingMoonEnemyData` or `ArkEnemyData`.
- **The reserved STAGE key `gravity`** (the Proving Moon's 2.0) is read only by the Proving Moon agent (below).
- **The Final Harvest** (`FinalHarvest`) is the shared Reckoning. Tune it only through your stage's RECKONING
  `final_harvest` keys and its `companions`.
- **Sounds.** New sounds go in your own block at the END of `SoundData.CONCORD_SOUNDS`; pack seeds depend on order, so
  never insert in the middle. Map their events in your own block at the end of `ConcordRulesData.SOUNDS`.
- **Report.** Put a per-stage report file beside `concord_report.gd` (`crash_site_report.gd`, ... as Act VIII's
  `skid_row_report.gd`), called from the marker in `ConcordReport.print_lines()` ("# Phase 2: each Act IX stage's own
  lines go here"), one line in your own block.
- **Codex.** Put new kinds in the `CodexData.CONCORD_*` race lists (`CONCORD_BROOD`, `CONCORD_HARVESTERS`,
  `CONCORD_VRASK`, `CONCORD_LUMINOUS`); place minibosses as Acts VII and VIII placed theirs. Add the achievement →
  counter-passive map (`"no_witnesses": "kevlar_bones"` is the model).
- **Unlocks, spells, characters, classes, counter-passives and achievements** work as in Acts VI–VIII:
  - `UnlockData` / `Unlocks` and the one `NecroSpellBook` dispatch. A spell works on every stage. Its sources join
    `NecroSpellBook.SOURCES`, so `HundredShadowsData.is_spell_source()` counts them: they burn turf and clear eggs.
  - `character_data.gd`, with a Hyper skin and the Untouchable and Deathlord skins.
  - One `SummonBehavior` per class that works the same on every stage.
  - PassiveData rows offered only in Act IX through the card row's `act`.
  - Each new class's Ossuary mastery in `mastery_data.gd`, and the price total in `tools/ossuary_check.gd`.
  - **Ids must not collide with enemy kinds, structures, source tags or the Concord sound and rule names.** Check
    `concord_enemy_data.gd`, your table, `ConcordRulesData` and `SoundData.CONCORD_SOUNDS`. For example, `tractor_beam`
    and `abduction` are already sound, source and class names, so the Harvester's spell and its evolution take other
    ids (below).

## The new kinds, split across the stages
The foundation built `broodling`, `grey_drone`, `saucer`, `vrask_hunter`, `lumen_sentinel`, `prism` and the
`concord_terraformer` structure. The rest of the proposal's roster is built by one stage each (as the foundation brief
planned):
- **The Crash Site:** the **Burrower** and the **Acid Spitter** (the Brood), shared rows in `ConcordEnemyData`; the
  miniboss **Brood Matriarch** and the egg in `CrashSiteEnemyData`.
- **The Proving Moon:** the **Warbeast** (the miniboss), in `ProvingMoonEnemyData`.
- **The Ark:** the **Grey Overseer** (the Harvesters), a shared row in `ConcordEnemyData`; the miniboss **Luminous
  Archon** in `ArkEnemyData`.

Built in parallel, the Ark's Council uses the foundation's shared kinds (broodlings, Vrask hunters, Lumen Sentinels). The
lead may add the Burrowers and Acid Spitters to the other stages' timelines at the merge.

## Balance (the foundation's flags)
- **Reflected beams are still very strong:** 12 dps base × the enemies' HP scaling, through Orb Shields and barriers.
  Each agent reports the reflected damage (`beams` line) and its share of the run's damage on its stage. The Crash Site
  agent alone may change the shared `ConcordRulesData` beam numbers, with a GDD note. The other two tune their own
  kinds' `beam` overrides and their stage data.
- **The Lumen Sentinels were softened** after their first numbers wiped the seed-7 Crash Site army at 9:00 (sweep 3.5 dps
  every 6.5 s, a 30% shield, about half their weight). Don't raise them back without a check.
- **Each stage agent balances its own stage** so the army bot ends healthy on seed 7 (`--policy=army --mortal`); the
  Crash Site agent also checks seeds 1 and 2, since it is the first stage. Use your stage's data first: timeline weights
  and counts, its HP and damage scaling, your kinds' rows, the STAGE `terraforming` overrides. Change a shared row only
  with a GDD note. One process at a time.

## Process (in addition to the Act VI section)
- **Do not push.** Commit in steps on your branch.
- **CPU: at most ONE Godot process at a time.** Run `pgrep -c Godot` first and wait while another agent's run is going.
- Image generation: `GEN_LEDGER=<your worktree>/docs/art/generation_ledger.csv python3 tools/gen_image.py ...`, absolute
  path. Budget about $0.70. Commit the ledger rows.
- **Never read, print, echo, search for or set any API key.**
- If you touch a shared path outside the Concord folder (the kill hook in `combat_resolver.gd`, the knockback in
  `enemy.gd`), also run the Graveyard default and the Liberty Heights army runs of `docs/act9/tools/gate.sh` against your
  base commit, one at a time: their `[autotest]` / `[metric]` lines must be identical.
- Keep `"playable": false`.
- Commit messages end with exactly:

  ```
  Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
  Claude-Session: https://claude.ai/code/session_01TjA5CNwUWb95gMazj5Z3qp
  ```

---

## Agent A: the Crash Site (`crash_site`, Stage 25)
Branch `act9-crash-site`, worktree `/home/user/wt/act9-crash-site`.

- **Stage:** a Harvester scout ship lies broken in the ruins of the capital, and the Brood hatch from it. The Brood lead
  (heavier in the timeline), with the Luminous mixed in. Zones: the Crater, the Hatchery, the Wreck, the Glass Spire.
  - Four zone floors as tiles over the `ruins` style (rubble, the crater's glassed rock, the hatchery's resin, the
    wreck's hull plates), and obstacles in both orientations (rubble, hull shards, glass spires).
  - Seed the crater's turf with `Terraforming.seed()` at the stage's start (a `"tag"` such as `crater`).
- **Infestation (owner answer, Nov 3).** The game has no lingering corpses, so the eggs sit where Concord enemies fall.
  - When a Concord enemy dies on the Crash Site, an egg sits where it fell for 6 s. Any spell or summon hit on that spot
    clears it. Otherwise a broodling hatches.
  - **The one hook:** record the death spot from the kill path in `CombatResolver.damage_enemy()`, beside
    `GhoulKit.claim_corpse()`, only while `game.concord != null`. Do it in one call (for example
    `CrashSiteDirector.on_concord_death(game, e)`), which returns at once off the Crash Site.
  - **Which deaths lay:** Concord kinds that are not structures, bosses or eggs. Broodlings hatched from an egg lay none
    (no chains). Cap the eggs alive (for example 24; over the cap, no egg; count the skips).
  - **The egg** (the lead's suggestion): a 1 HP structure row `brood_egg` in `CrashSiteEnemyData`, so every hit that
    reaches it clears it: spells, summons and volleys alike. It never attacks or moves, heals on no turf, gives no XP,
    drop or corpse, and does not count as a kill for achievements. If you keep the eggs out of the enemy pool instead,
    one documented check must clear them from spell and summon hits (spell sources through
    `HundredShadowsData.is_spell_source()`, summon sources through `SynergyData.SOURCE_CLASS`).
  - Make the egg readable: a pulsing egg sprite and a hatch strip (textures, slow pulse).
  - Report: eggs laid, cleared (by spell / summon), hatched, skipped.
- **Bone Walls block beams (owner answer, Nov 3).** You are the only agent who edits `concord_beams.gd`.
  - In `ConcordBeams._resolve_line()`, a Bone Wall segment ends the beam's main segment where it first touches the line,
    when it is nearer than the orb, barrier or prism found there. No reflection, no split past it.
  - **Reuse the same segment test:** `BoneWall.shot_block_t(a, b, r)` through the per-slot loop of
    `EmpireShots._wall_block_t()` (co-op: every player's walls; the spell's walls, Bastion rings and an Ossuary Titan's
    wall alike). Don't write a second segment test. Share the loop or call the same function; don't copy the maths.
  - It applies to every Concord beam: split beams and the Final Harvest's eye too. A reflected beam (the necromancer's)
    is not stopped.
  - Draw the hit flare at the wall. `danger_push()` must use the shortened line. Count `beam_wall_stops` in the `beams`
    line.
  - Update the README line; the GDD "Beams (Act IX)" row already says it.
- **Miniboss: the Brood Matriarch**, a winged queen-guard who spits egg sacs over the ring.
  - She is an insect creature (female by name, drawn as an insect in the Brood's green-black chitin, as the queen-guard
    of the approved `act9_boss.png`; not in the figure style), and a flier (`flies`).
  - Her sacs arc over the ring and land as **Infestation eggs** (the same egg path). Show a landing telegraph.
- **Boss: the Hive Mother** (`boss_hive_mother.gd`, **female**, figure style; the foundation's 96 px sprite with its idle
  strip; add the glide / flight strip and attack poses), three phases:
  - **the Brood:** egg waves (through the egg path) and Burrowers from every side;
  - **the Burrow:** she dives under the arena and erupts beneath the ring on a telegraph (a mound texture, like the
    Burrower's, larger);
  - **the Flight:** she tears loose and takes to the air (`flies` while airborne), raining acid that leaves the Acid
    Spitter's pools.

  When she falls, show a short ending text only (no epilogue).
- **Kinds** (shared rows in `ConcordEnemyData`, your block at the end):
  - **Burrower** (brood, soldier): it tunnels in and bursts up inside the ring. A dirt mound shows 1 s ahead (a
    texture). Underground it cannot be hit or body-blocked; it surfaces among the summons. Blockers inside the ring are
    the answer.
  - **Acid Spitter** (brood, ranged): it lobs acid that leaves a burning puddle. The lob is arcing, so it ignores the
    ring. The puddles hurt summons and the necromancer through `damage_unit()` / `damage_player()`, never enemies.
    Keep them in ONE pooled list owned by `game.concord` (for example an `AcidPools` child added in your block of
    `concord_rules.gd`), so the kind works on any stage. Draw them as textures and add them to `danger_push()`.
- **Spell: Bone Beetles** (`bone_beetles`), unlocked by the Hive Mother: slain enemies burst into bone beetles that bite
  the next enemy. It evolves into **Hive of Bone** with the paired passive **Chitin** (`chitin`).
- **Character: the Broodbound** (**female**, figure style), a woman who wed the swarm, starting with Bone Beetles. Her
  chitin is the Brood's green-black, not the player's violet and bone.
- **Counter-passive: Anchored** (`anchored`, key `hold_cut`, Act IX only). Build its PassiveData row on the existing
  hook (0.5 at full: abductions last half as long and break when the saucer takes damage).
- **Achievement: Nothing Hatched.** No egg hatches on the Crash Site, from the start until the Hive Mother falls, and
  you beat her. It unlocks **Anchored**. Report the eggs hatched on seed 7. If even a strong build cannot earn it, say
  so in your report with the numbers; don't change what counts on your own.

## Agent B: the Proving Moon (`proving_moon`, Stage 26)
Branch `act9-proving-moon`, worktree `/home/user/wt/act9-proving-moon`.

- **Stage:** the Vrask take the necromancer to their hunting ground on the moon, to see what he is worth. The Vrask lead,
  with the Luminous mixed in. Zones: the Landing, the Craters, the Trophy Hall, the Duelling Ring.
  - Four zone floors as tiles over the `moon` style (grey regolith, crater rims, the trophy hall's dark stone floor with
    hanging skulls as decals, the duelling ring's marked circle), obstacles in both orientations (boulders, crater rims,
    trophy pillars).
- **Low gravity: the STAGE key `gravity`** (2.0, reserved by the foundation). Knockback goes twice as far for everyone,
  both armies, and leaps are longer. You build its read:
  - **One accessor**, for example `ConcordRules.gravity()` = the STAGE's `gravity` (1.0 when absent), read nowhere when
    `game.concord` is null. Every read multiplies or divides by exactly 1.0 off the moon, so stages 1–25 and 27 do not
    change.
  - **Enemies:** the one knockback decay in `Enemy` (`EnemyData.KNOCKBACK_DECAY`, where `knockback` moves toward zero)
    is divided by `gravity`, so every existing knockback travels twice as far (linear decay: the distance scales with
    1 / decay). Don't touch the many knockback writers.
  - **Summons and the necromancer:** the shoves enemies give them (the shared rush's `charge_knockback` and your kits'
    shoves) are multiplied by `gravity`.
  - **Leaps:** your kits' leaps (the Warbeast's pounce, Vrask'Tal's glaive leap) are multiplied by `gravity`. Grave Step
    is a shadow step, not a leap: it stays as it is.
  - Record each read in your GDD row. Run the gate's two runs (you touch `enemy.gd`).
- **Miniboss: the Warbeast**, the Vrask's armoured hunting animal (a creature, teal and dark armour plates, never violet
  and bone). It has a pounce (a telegraphed leap, longer under low gravity) and `flat_armor` or a `lumen_shield`-style
  plate (your choice; record it). It is a row in `ProvingMoonEnemyData`, keeping its body radius sensible.
- **Boss: Vrask'Tal, the Hunt-Lord** (`boss_vrask_tal.gd`, **male**; reptilian, as the Vrask hunter but larger, with a
  skull belt), three phases:
  - **the Stalk:** cloaked (the `cloak` rule's shimmer, through the Vrask hunter's mechanism), he picks summons off the
    ring's edge. Each kill hangs a skull on his belt (drawn; a small, capped damage step per skull is your call, record
    it). Spell hits reveal him as they reveal hunters.
  - **the Duel:** he drops his cloak and fights the necromancer with a glaive, leaping over the ring (the leap ignores
    the body-block, as Vargr's did).
  - **the Last Trophy:** he arms the bomb on his wrist: a 20 s countdown on screen (HUD text, never a screen effect)
    that he tries to finish standing next to the necromancer.
    - Kill him in time and the bomb is off.
    - If it ends, it blows up where he stands, through one documented path. The lead's suggestion, as Broken Arrow: it
      leaves the necromancer in its radius badly hurt (down to a share of max HP, never lethal by itself; Grave Step does
      not dodge it) and destroys summons in its radius through `damage_unit()`. Decide what it does to Vrask'Tal himself
      (the lead's suggestion: it kills him, counted as a boss kill for the unlock chain but not for the achievement) and
      record it.
    - The army bot steps away from him while the countdown runs (`danger_push()`).
- **Lock beams:** his plasma caster and the hunters' use the `lock` style through `ConcordBeams.fire()`. Tune your
  boss's beams through overrides; ask the lead before you need a `concord_beams.gd` change.
- **Spell: Soul Caster** (`soul_caster`), unlocked by Vrask'Tal: a shoulder cannon that locks three targets with three
  dots and fires. The dots are in the spell's own soul colour, not the Vrask's red, so a player never mistakes his own
  lock for a hunter's. It evolves into **Apex Predator** with the paired passive **Trophy Rack** (`trophy_rack`).
- **Character: the Blooded** (**female**, figure style), the one human who survived the Hunt, starting with Soul Caster.
- **Counter-passive: Mirror Bones** (`mirror_bones`, keys `reflect_damage` and `beam_reduction`, Act IX only). Build its
  PassiveData row on the existing hooks; you don't edit `concord_beams.gd`. Mind the reflection flag above: keep
  `reflect_damage` modest.
- **Achievement: The Hunter Hunted.** Beat Vrask'Tal before the Last Trophy's countdown ends. It unlocks **Mirror Bones**.

## Agent C: the Ark of the Concord (`ark`, Stage 27, the act's finale)
Branch `act9-ark`, worktree `/home/user/wt/act9-ark`.

- **Stage:** the mothership in orbit over the dead world, the Concord's capital and its harvest vault. The Harvesters
  lead, with the Luminous mixed in. Zones: the Hangar, the Specimen Vaults, the Reactor, the Bridge of Stars.
  - Four zone floors as tiles over the `hull` style (hangar deck plates with landing marks, the vaults' tank rows, the
    reactor's glowing grating, the bridge's starfield glass), obstacles in both orientations (crates, consoles, pillars).
  - **The Specimen Vaults:** break the tanks (structures) to free the captured beasts inside, which attack everyone.
    - A freed beast is an enemy. It fights the army as every enemy does, and it also strikes Concord units near it,
      through `damage_enemy()` with its own source tag (for example `vault_beast`). Use ONE documented check for whom it
      attacks: the nearest of summons, the necromancer and Concord enemies.
    - Freed beasts don't heal on turf. Tell them apart in the report.
  - **The Reactor:** vents that seed turf (`Terraforming.seed()`, tag `vents`) on a timer. They are structures; breaking
    one stops it.
- **Miniboss: the Luminous Archon**, a being of pure light (**male**, as the Lumen Sentinel but larger, in white-gold
  crystal), whose every attack is a beam to reflect (`ConcordBeams.fire()`, `boss_override`). It is a row in
  `ArkEnemyData` with a `lumen_shield`.
- **Boss: the Harvester** (`boss_harvester.gd`; the oldest of its kind, the one who planted the world; a tall grey, sex
  unmarked as the greys are, floating above a throne of rings as in `act9_boss.png`), three phases:
  - **the Council:** it fights with the Concord's powers in turn: the Brood's swarms (broodling waves), the Vrask's
    cloak (it cloaks through the `cloak` rule), the Luminous beams (`sweep` / `eye` beams through `ConcordBeams`).
  - **the Reaping:** it opens a tractor beam over the whole ring, and every summon starts rising. Four beam emitters
    around the arena (structures) must be destroyed before the army is gone.
    - Each emitter lifts through `Abduction.lift(emitter, u)` on a steady rhythm. Set `Abduction.uncapped` for the
      phase and clear it after.
    - A destroyed emitter drops what it holds through the rescue path (`release_all`). With all four destroyed, the
      Reaping ends. Anchored applies as usual.
  - **the Gardener:** it reveals its true form, a vast being of light and rings, and turns the world below into its
    weapon: rings of live turf grow across the arena (`Terraforming.seed()`) and heal its adds; spells burn them back.
    Whether the Harvester heals on its own turf in this phase is your call (it is 0 by default); record it.

  When it falls, the stars go dark too: a short ending text only, no epilogue.
- **Kind: the Grey Overseer** (harvesters, support; a shared row in `ConcordEnemyData`). A psionic pulse stuns summons
  near it for 1 s (`stun_unit()`, telegraphed), and it shields the greys near it (the `holy_shield` path). It is a
  priority target.
- **Spell: Tractor Beam** (id `tractor_lift`, since `tractor_beam` is a Concord sound and event id), unlocked by the
  Harvester: it lifts the strongest enemy into the air and slams it down. It evolves into **Abduction** (id
  `star_abduction`, since `abduction` is the rule's source tag and class name; its display name stays "Abduction") with
  the paired passive **Starseed** (`starseed`).
  - Bosses, minibosses and structures are never lifted. On them the spell slams in place.
  - The lift holds the enemy through `CombatResolver.stun_enemy()`. Build ONE enemy-lift helper and share it with the
    Ghost Saucer (below).
- **Character: the Starborn** (**female**, figure style), a Harvester who deserted, starting with Tractor Beam. She is a
  grey in a covering suit, in hull white, gunmetal and plasma green, never violet and bone.
- **Summon class: the Ghost Saucer** (`ghost_saucer`, the finale's reward, unlocked by the Harvester as Blood Spawn and
  the Fallen Hero were by their bosses): a flying ranged summon (airborne, so never liftable) that fires short beams and
  lifts small enemies.
  - Its beams are summon attacks through `damage_enemy()` with its class source, drawn as textures. They never go
    through `ConcordBeams`, which is the enemies' path.
  - Its lift uses the shared enemy-lift helper: small, non-elite enemies only (never bosses, minibosses, structures or
    Reckoning enemies).
  - It works the same on every stage (one `SummonBehavior`).
  - Its evolution is **Black Mothership**. Name the paired passive (unique among every existing name) and record it.
  - Give it its Ossuary mastery.
- **Achievement: The Last Harvest.** Beat the Harvester. No epilogue: it only records the clear (a title, as Acts VI–VIII
  did).
