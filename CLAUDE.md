# CLAUDE.md: Gravebound

Guidance for Claude Code (and any agent) working in this repo. Read this first, then `README.md`
(how the game works, the architecture, the autotest) and `docs/GDD.md` (the design).

## What this is

**Gravebound** is a Vampire Survivors-style game. You play a necromancer who commands an autonomous undead
horde (Warriors, Archers, Mages, the Mender
and Warder priest orders, plus Abominations, Rogues, Gargoyles, Frost Wraiths, Bone Hounds,
Banshees and Corpse Catapults) against the holy Crimson Covenant. It is built in **Godot 4.3**
with **GDScript**, top-down 2D and the GL Compatibility renderer. There are no external assets: art is
drawn in code (`_draw`), and sound and music are synthesized at startup.

## Sources of truth

- `docs/GDD.md` is the formal design doc. **Section 15.0, "Resolved Decisions", overrides everything
  else in the GDD.** Every design decision made by the user or during development is recorded there.
- `docs/Gravebound_Complete_Game_Design_and_Horde_Spec.txt` is the original raw spec, the source of
  record for the GDD.
- `README.md` covers player-facing behaviour, the architecture tree, the autotest options and known
  limitations.
- When you make a design decision the GDD doesn't cover, **append a row to GDD §15.0**, and mark an
  open question as resolved if your decision answers it.

## Non-negotiable conventions

1. **Document everything.** Every script starts with a header comment explaining its role. **Every**
   member variable, constant and exported field has a comment saying what it is, with units and ranges.
   This is a standing requirement from the project owner. Non-obvious logic gets comments too.
2. **Data-driven numbers.** All tunable values live in `scripts/data/*.gd`, with no logic there. Tag
   each one `# GDD §N` (taken from the spec) or `# TUNING (not in GDD)` (invented). Never hard-code
   balance numbers in logic scripts.
3. **Static typing** in all GDScript.
4. **Single paths for modifiers.** Stats flow through one path per concern; don't scatter checks:
   - `scripts/core/meta_modifiers.gd`: Soul Ash upgrades.
   - `scripts/core/difficulty_modifiers.gd`: the difficulty level (its own multiplier) and the opt-in
     modifiers (the run modifiers, Profane Pact and Oath, added together and applied once).
   - The horde director's effective-stat code: summon stats.
   - `scripts/core/combat_resolver.gd`: all damage, healing, kills, XP, drops and stats.
5. **Pooling and determinism.** Enemies, summons, projectiles, crystals, effects and drops are pooled,
   and stored references are checked against a `generation` counter. Runs must stay **deterministic
   per seed**. Never use instance IDs, wall-clock time or unseeded RNG in gameplay logic.
6. **No physics engine for units.** Use the spatial hash (`spatial_hash.gd`) and `arena.gd` push-out.
7. **Autotest friendliness.** New systems must work headless and must not break `--autotest`. Hit-stop
   and saving are disabled under the autotest, which also never touches `user://` unless `--meta-save`
   is passed. Add summary stats for new systems.
8. **Commits** must not mention model identifiers. Keep README and GDD §15.0 in sync with changes.

## Design pillars and decisions to preserve (see GDD §15.0)

- **Run structure:** a 20:00 countdown on every stage. The stage boss (Sir Alaric, Marshal Vael, Seraphine)
  arrives with 3:00 left. At 0:00 the **Reckoning**
  begins: escalating, near-unbeatable enemies that end the run. Dying after 0:00 is a victory, and
  dying before 0:00 is a defeat.
- **Power curve:** a strong build should be **nigh unkillable** before 0:00, and a careless build can
  die. Players must **not become too powerful too quickly**: a build completes around 16-18 min, and
  evolutions arrive mostly at 10-14 min.
- **Undead don't dodge.** They body-block for the player, and Warriors physically block enemies.
- **Enemies always advance** on the player; nobody kites.
- **Priests** are split: **Menders** heal allies and the necromancer, **Warders** ward the
  necromancer and put barriers on allies; with Dark Benediction both merge into the Profane Bishop.
- **Evolutions** come only from **treasure chests**, once the base spell is Lv5, the paired passive is
  **at Lv5 too** (owner rule: every evolution, spell or summon, needs its paired passive maxed) and the
  run has reached 8:00 elapsed. Summon evolutions (Death Knight, Lich, Profane Bishop) use the same
  delivery and gate with their own recipes (`summon_evolution_data.gd`).
- **Shadow Bolt** has a Nearest/Strongest aim toggle (T / pad Y).
- **Army stances** (keys 1-4 / right-stick flicks, 1.5 s lockout): Escort (default, exactly the
  original formation and leash), Onslaught, Spearhead (Ossuary unlock) and Bone Ring only override
  numbers the horde AI already uses (`stance_data.gd`, read by the horde director); the hard recall
  never changes, the flavour bonuses stay off, and the stance resets to Escort every run.
- **Spells:** Shadow Bolt, Orb Shield, Shadow Blast, plus Bone Spear, Soul Siphon, Corpse Explosion
  and Plague Cloud, plus Death Mark, Bone Wall, Soul Chains, Wither and Raise Dead
  (`scripts/abilities/spells/`, one dispatch through `NecroSpellBook`). 24 actives
  (12 spells, 12 offerable summon classes) compete for 6 active slots.
- **Soul Ash is kept on death.** Profane Pact (in-run) and Profane Oath (Ossuary) trade difficulty
  for rewards.
- **Playable characters** (one per spell, `character_data.gd`): each starts with its own spell, has
  **one innate passive only** (no exclusive cards) and a few stat modifiers, all through ONE path
  (`RunConfig.character_id` → `CharacterModifiers` as `game.character` → `CharacterInnates` as
  `game.innates`). **The Gravecaller is the default with no innate and baseline stats**: with him the
  game must stay bit-for-bit identical (same-seed autotest summaries). A character unlocks the first
  time its spell reaches Lv 5 in any run (Meta `[characters]`).

## Tools and commands

Godot binary (cloud sessions): `/home/user/tools/godot/Godot_v4.3-stable_linux.x86_64`. If it is
missing, download the official 4.3-stable Linux build. Export templates go in
`~/.local/share/godot/export_templates/4.3.stable/`.

```bash
godot --headless --import                       # parse/import check: must print no errors
# Full automated 20-minute playthrough (about 90-110 s wall time). Exit 0 = run completed.
godot --headless --fixed-fps 60 --quit-after 15000 -- --autotest [options]
```

Autotest options (full table in the README):
- `--mortal`: the player can die before 0:00.
- `--seed=N`
- `--policy=naive|army|evolve|summon|pact`
- `--classes=a,b` (force summon classes, e.g. `abomination,rogue,gargoyle,frost_wraith`)
- `--spells=a,b` (force spells and their evolution passives, e.g.
  `bone_spear,soul_siphon,corpse_explosion,plague_cloud` or `death_mark,bone_wall,soul_chains`)
- `--passives=a,b` (force passives the same way, e.g. `unholy_precision,unholy_resilience`)
- `--stage=graveyard|crimson_march|sanctum` (default graveyard; stage locks are ignored)
- `--boss=alaric|vael|seraphine` (puts that boss in the stage's slot, e.g. test Seraphine on the Graveyard)
- `--difficulty=initiate|necromancer|lich|deathlord` (GDD §8.4; default necromancer = today's game)
- `--modifiers=a,b` (GDD §8.5 run modifiers, e.g. `hardened_faith,scarcity`, or `all`)
- `--stance=escort|onslaught|spearhead|bone_ring` (force an army stance for the whole run)
- `--character=ID` (playable character, default `gravecaller`; locks bypassed, e.g. `bone_oracle`;
  characters whose spell is missing are refused)
- `--spawn=kind@T[xN],...` (force-spawn any enemy kind at T game seconds on any stage, e.g.
  `sanctified_sentinel@120x3,high_confessor@180x2,cathedral_guardian@300`)
- `--pact`
- `--meta=none|mid|max`
- `--oath=0-5`
- `--speed=N` (default 8)
- `--meta-save`

**"Done" means:**
- `--import` and the autotest runs you touched (at least default, `--mortal`, `--policy=army`) show
  **zero** `SCRIPT ERROR` / `ERROR:` / `WARNING:` lines;
- `stuck_units=0`;
- for balance-affecting changes, a multi-seed check against the targets below.

CI (`.github/workflows/ci.yml`) runs the import, the Graveyard autotest with the naive and army
policies, a Crimson March autotest, a Sanctum of Judgment autotest (army policy), the
Windows/Linux exports and an exported-build smoke test. Pushing a `v*` tag publishes a GitHub Release
with both zips.

## Balance targets (check with multi-seed batches, `--mortal`)

| Profile | Target |
|---|---|
| Fresh save, `--policy=army` | 0 deaths before 0:00, min HP 60+ (ideally 90+), kills Alaric ~100% |
| Fresh save, naive | dies ~20-40%, kills Alaric ~25-50% |
| `--meta=max` | clearly easier; the Reckoning still ends every run (~30-90 s past 0:00) |
| Pacing (meta none) | first level-up ~0:20-0:30; build complete ~16-18 min; evolutions mostly 10-14 min; ~5-8 chests |
| Soul Ash | good run ~450; death at ~9-11 min ~100-150; all upgrades ~17-20 good runs |
| Profane Pact (strong build) | harder but viable, noticeably more Soul Ash |
| Difficulty, `--policy=army` | Initiate clearly safer; Deathlord clearly harder but the army usually still reaches 0:00 |

Screen changes with 8 seeds on the relevant configs, and confirm with 16. The machine usually has
4 cores: run at most 4 Godot processes in parallel. Prefer a few principled data changes over many
tiny tweaks.

## Working with agents (how this project has been built)

- Use **Opus** subagents for implementation, balance and review. Run independent features in parallel
  in **git worktrees**, then merge on an `integration` branch, run the full verification, and only
  then fast-forward `main`.
- Brief agents to keep shared-file edits small and additive and to put new work in new files, so
  merges stay clean. Avoid two agents tuning the same data at once.
- Never push unverified work to `main`. Back up long-running work to a branch if needed.

## Development plan

**Done (v0.3):** Stage 1 (the Desecrated Graveyard) is complete:
- the horde AI;
- 3 spells with evolutions;
- 7 passives plus the Profane Pact;
- synergies;
- Sir Alaric's full kit;
- the stage events;
- obstacles;
- power-ups, chests and the Soul Nova;
- Soul Ash and the Ossuary, with the Profane Oath;
- audio, game feel and settings;
- CI and export.

**Done (after v0.3):**
- the priest split: the Grave Mender (heals) and the Crypt Warder (wards the player, barriers on
  allies), which merge into the Profane Bishop;
- the summon evolutions Death Knight (Warriors), Lich (Mages) and Profane Bishop (Menders +
  Warders), delivered by chests like the spell evolutions;
- the passives Forbidden Knowledge and Dark Benediction;
- four more summon classes, each with a `SummonBehavior` special: the Corpse Abomination (blocker,
  stomp), Grave Rogue (dash strike, bleed), Crypt Gargoyle (airborne swoop) and Frost Wraith
  (chill, Deep Freeze);
- four more spells with evolutions and paired passives: Bone Spear / Ossuary Lance (Shade Stride),
  Soul Siphon / Soul Rapture (Vampiric Rite), Corpse Explosion / Grave Eruption (Necrotic
  Expanse), Plague Cloud / Pestilence (Lingering Malediction), plus the Rot status;
- autotest `--policy=summon`, `--classes=a,b` and `--spells=a,b`;
- a combined balance pass across both stages (owned-only chests, card weights, outlier nerfs);
- Stage 2, **the Crimson March**, on a multi-stage framework: stage data in
  `scripts/data/stages/` behind `StageRegistry` (read through `game.stage_def`; `wave_data.gd` and
  `arena_data.gd` keep only shared rules), a RunConfig and stage select, the Meta `[stages]` save
  section, four clock-driven battle zones, outposts, Holy Ward Generators, supply carts, the
  Shieldbearer, Banner Bearer and Halberdier, a `Boss` base class, Marshal Vael, and ×1.25 Soul Ash;
  `--stage=graveyard|crimson_march`;
- the GDD §8.4 **difficulty levels** (Initiate, Necromancer = the standard game, Lich, Deathlord;
  `difficulty_data.gd`) and the eight §8.5 **run modifiers** (`run_modifier_data.gd`), chosen on a
  pre-run setup screen after the stage select that shows the total Soul Ash multiplier; both go
  through `difficulty_modifiers.gd` with the Pact and Oath, are remembered in the Meta `[prerun]`
  save section and kept by Restart; `--difficulty=` and `--modifiers=`;
- the four later horde passives **Bone Plating** (flat damage off each hit on a minion), **Unholy
  Precision** (seeded minion crits), **Unholy Resilience** (less area / holy damage to minions) and
  **Bound Souls** (minion speed, leash, faster return), hooked into `CombatResolver` and
  `HordeDirector.compute_stats()`; their cards name the summon evolutions they will unlock (Bone
  Colossus, Gravebow, Cathedral Horror, Shadow Reaper; Soul Recycling → Winter Revenant), all built
  below; and the owner rule that **every evolution needs its paired passive at Lv 5**;
- the **recipe book**: evolutions are meant to be discovered (owner decision, no card or HUD hints),
  so the pause menu's **Recipes** view (`recipes_panel.gd`) shows only the recipes obtained in some
  run, saved in the Meta `[recipes]` section, and locked "?" placeholders for the rest; it is
  built from the recipe data (`evolution_recipes.gd`), so new evolutions appear automatically.
- the **Winter Revenant** (Frost Wraith + Soul Recycling Lv 5, "transform"): Deep Freeze radius
  +35% (`special_mult`), frozen enemies **shatter** on death (no chains, per-tick cap) and a
  fallen Revenant releases a freezing **death nova** (`scripts/horde/winter_revenant.gd`).
- the summon evolutions **Shadow Reaper** (Rogue + Bound Souls: halved dash cooldown, chained
  dashes, stacking bleeds, dash-kill reset) and **Cathedral Horror** (Gargoyle + Unholy
  Resilience: wider swoop, dive stun via `CombatResolver.stun_enemy()`, stone form after landing),
  upgrading the class specials through the `special_mult` / `special_set` recipe overlays.
- two of those summon evolutions: the **Gravebow** (Archers + Unholy Precision: piercing,
  splitting, cursing arrows; the curse status lives in `combat_resolver.gd`) and the **Bone
  Colossus** (Abominations + Bone Plating: bigger stomp and body, taunt, bone shrapnel on death),
  in `gravebow_kit.gd` / `colossus_kit.gd`.
- the GDD §5.5 **dash and ultimate**: **Grave Step** (Shift / RB, `scripts/player/grave_step.gd`:
  110 px obstacle-clamped shadow step, 0.2 s i-frames, 5 s cooldown, from the first run; Ossuary
  Twin Shadow = second charge, Restless Shade = 5 → 3.5 s) and **Dread Rally** (Space / LB,
  `scripts/player/dread_rally.gd`: a kill-charged soul meter; surge, 30% heal, +40% damage and
  attack speed for 8 s through `compute_stats`, knockback); numbers in `player_ability_data.gd`,
  HUD in `hud_abilities.gd`, rebindable, used by every autotest bot.
- **army stances** (Escort, Onslaught, Spearhead, Bone Ring; `stance_data.gd`, `army_stance.gd`,
  `stance_formations.gd`): keys 1-4 / right-stick flicks, a HUD stance bar, banner, command sound
  and ground outline, a pause-menu line per stance, Spearhead bought in the Ossuary (Spearhead
  Doctrine); the flavour bonuses exist but are off until the final balance pass; `--stance=`, and
  the army / summon / evolve bots switch by a simple rule (`stance_bot.gd`; naive / pact keep Escort).
- **Stage 3, the Sanctum of Judgment**, the last stage of the campaign: `sanctum_stage.gd`
  (unlocked by Marshal Vael, ×1.5 Soul Ash), four clock-driven zones through `MarchDirector`
  (`SanctumGround`, `SanctumTerrainGlyphs`), and `SanctumDirector` for the two sanctified chambers
  (ward crystals, 25% weaker undead hits inside), the Cathedral Guardian, three optional sacred
  altars (−6% soldier HP each, `Game.altars_destroyed`), floor corruption and Dawn's Wrath (Sun
  Paladins with the Reckoning); achievement *Dawn Extinguished*. Its **Covenant kinds**
  (`sanctum_enemy_data.gd`, one `CovenantKit` each in `scripts/enemies/sanctum/`, usable by any
  stage; the timeline names them through `SanctumStage.KINDS` aliases): the Sanctified Sentinel
  (flat armour 6, telegraphed sweep), Radiant Inquisitor (holy zones, suppression), High Confessor
  (heals, holy shields, revival every 12 s, max 3, interruptible gold pillar), Sun Paladin (Templar
  charge, 20% sun ward aura) and the **Cathedral Guardian** miniboss (slams, sweeping beam; its kit
  registers it with `EnemyDirector.set_miniboss()` for the HUD's one miniboss bar, `ChestManager`
  drops its chest). Its boss **Grand Inquisitor Seraphine** (`boss_seraphine.gd`, hazards in
  `seraphine_hazards.gd`, data in `seraphine_data.gd`, arrival `SeraphineData.ARRIVAL`): three
  phases, High Confessor attendants (3 − altars destroyed; her regen is the one healing path),
  Sanctified Sentinel constructs, teleports, beams, the safe-zone nova, the collapsing arena with a
  Templar and Sun Paladin guard, the relic shatter and the ending text. Every suppression (Radiant
  Inquisitor, Seraphine) goes through the one `HordeDirector.add_suppression()` path; flat armour,
  holy shields, the sun ward, suppression and the chamber penalty each have their own stat in
  `CombatResolver.damage_enemy()`. `--stage=sanctum`, `--spawn=`, `--boss=`; CI runs a Sanctum
  autotest.
- **five more spells** (owner-approved; 12 in all), same `NecroSpellBook` dispatch, fixed rules in
  `grave_spell_data.gd`: **Death Mark** / Doom Brand (+ new passive Grim Ledger: damage to elites,
  minibosses and bosses in `CombatResolver`; the brand is a plain DoT, no damage-taken bonus, and a
  branded death raises a temporary Risen), **Bone Wall** / Charnel Bastion (+ Grave Dominion; segments
  push enemies out after the obstacles, `NecroSpellBook.after_physics()`, enemies only, never inside
  obstacles, bosses / minibosses / Reckoning / structures not held), **Soul Chains** / Chains of the
  Damned (+ new Spirit Binding: longer slows, chills, freezes and stuns in `CombatResolver`; owner
  change: arcing soul lightning), **Wither** / Necrotic Blight (+ Necrotic Vigor; aura with an armour
  shred, `Enemy.wither_until`), **Raise Dead** / Legion of Bones (+ new Restless Dead: every temporary
  summon lasts longer and hits harder, in `HordeDirector.spawn_temporary()`); autotest "later spells"
  line.
- three more summon classes (owner-approved; 9 -> 12 offerable), one `SummonBehavior` each:
  **Bone Hounds** (3 -> 9 cheap, fast pack beasts; Pack Hunt: a shared prey, +15% bite per
  packmate, max +45%), the **Banshee** (a floating, hittable support caster; Dirge: a telegraphed
  wail that slows and cuts enemy damage through the one debuff path
  `CombatResolver.weaken_enemy()`, read by `Enemy.hit_mult()`) and the **Corpse Catapult**
  (formation "back", holds its ground; Bone Barrage: led, arcing boulders with a landing
  telegraph, structures / elites / dense packs first, pooled in `horde_hazards.gd`). Their
  evolutions and NEW paired passives: **Hellhound** (Blood Scent: fast classes, base speed >= 95,
  move and attack faster; burning bites, fire trail, split pack), **Keening Lady** (Mournsong:
  every weakening effect lasts longer, `CombatResolver.debuff_time()`; three Dirge waves that
  silence priests' heals) and **Ossuary Engine** (Siegecraft: more summon damage to structures,
  elites, minibosses; three boulders a volley, burning bone-shard fields). Glyphs in
  `warband_glyphs.gd`, card / autotest text in `class_passives.gd`.
- **Playable characters** (owner-approved, one per spell): `character_data.gd` (12 characters),
  `CharacterModifiers` (the one character path: starting spell, stats applied once, innate values),
  `CharacterInnates` (Eclipsed Guard, Echoing Dark, Ossuary Ward, Grave Harvest, Stolen Grace,
  Contagion; Restless in `HordeDirector.spawn_temporary()`), a picker on the pre-run setup screen
  (`character_picker.gd`, portraits in `character_glyphs.gd`: the necromancer tinted until art
  exists), the unlock rule (Lv 5 with the spell in any run, Meta `[characters]`, end-screen banner),
  `[prerun] character`, `--character=`. The five characters of the later spells (Doomsayer, Barrow
  Warden, Soulbinder, Wither Witch, Grave Herald) have `game.character.innate_value()` hooks inside
  those spells (GDD §15.0).

**Next, in priority order:**
1. **Playtest feedback** from the owner and friends (actively playtesting); it outranks everything below.
2. **Small fixes:** menu key hints should reflect rebinds. (Archers now hold their ground: user
   decision, GDD §15.0.)
3. **Real art (Phase 2), in progress:** **pixel art** style, locked by the approved necromancer.
   The owner generates sprites in ChatGPT from `docs/art/ART_BIBLE.md` (manifest of every asset,
   with file keys and sizes); process each with `python3 tools/prepare_sprite.py <image> <key>`.
   `SpriteBank` draws `assets/sprites/<key>.png` when present and falls back to the glyph, so art
   lands piecemeal. Done: `player/necromancer`; every summon and the first three evolutions (incl. `risen`); every enemy soldier (incl. the
   Reckoning's `inquisitor`); both `bosses/`; all five `structures/`. Still to do: the pickups, the five newer evolutions (Gravebow, Bone Colossus, Shadow Reaper, Cathedral Horror, Winter Revenant), the three newest classes with their evolutions (Bone Hound / Hellhound, Banshee / Keening Lady, Corpse Catapult / Ossuary Engine), the eleven playable characters (`player/<id>`, drawn as the tinted necromancer until then), and the five later spells' icons (spells, evolutions, passives) and effects (`soul_lightning`, `bone_wall_rise`, `bone_wall_burst`, `wither_aura`, `doom_burst`, `raise_dead`, `legion_burst`, already hooked). Effects are
   short animations (`prepare_sprite.py --anim <sheet or GIF> <id>` → `assets/sprites/effects/`,
   timing in `anim_data.gd`); `shadow_blast` (test), `dread_rally` and `grave_step_trail` are hooked so far, hook the rest via
   `EffectManager.ring(..., anim)` / `Effect.anim_id` as their art arrives. Pickups, ground tiles and obstacles come later.
4. **Content candidates** (owner to choose): achievement rewards / the Bone Golem (and the
   campaign epilogue that *Dawn Extinguished* should unlock), synergies for the newer classes, more
   ultimates, a victory screen after the Reckoning.
5. **Phase 3 campaign:** Stage 3 is done (the Sanctum of Judgment and Grand Inquisitor Seraphine);
   left: skins, achievement rewards, the campaign epilogue, art for the Sanctum kinds, structures
   and Seraphine.
6. **Phase 4 polish:** accessibility, profiling on real hardware, and the **final balance pass**.
   The owner is happy with balance for now and wants value tweaks deferred to this pass (naive-bot
   death rates above target on both stages and spell-only builds lacking single-target damage are
   known and accepted until then).

**Pace:** the owner lifted the one-agent limit (Oct 2026): independent features may run as parallel
agents in worktrees, merged on `integration`. Keep test batches proportionate (sanity checks plus
the multi-seed screens a change needs), and at most 4 Godot processes on the 4-core machine.
