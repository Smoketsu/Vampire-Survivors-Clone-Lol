# CLAUDE.md: Gravebound

Guidance for Claude Code (and any agent) working in this repo. Read this first, then `README.md`
(how the game works, the architecture, the autotest) and `docs/GDD.md` (the design).

## What this is

**Gravebound** is a Vampire Survivors-style game. You play a necromancer who commands an autonomous undead
horde (Warriors, Archers, Mages, the Mender
and Warder priest orders, plus Abominations, Rogues, Gargoyles and Frost Wraiths) against the holy Crimson Covenant. It is built in **Godot 4.3**
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

- **Run structure:** a 20:00 countdown on every stage. The stage boss (Sir Alaric, Marshal Vael)
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
  owned and the run has reached 8:00 elapsed. Summon evolutions (Death Knight, Lich, Profane Bishop)
  use the same delivery and gate with their own recipes (`summon_evolution_data.gd`).
- **Shadow Bolt** has a Nearest/Strongest aim toggle (T / pad Y).
- **Spells:** Shadow Bolt, Orb Shield, Shadow Blast, plus Bone Spear, Soul Siphon, Corpse Explosion
  and Plague Cloud (`scripts/abilities/spells/`, one dispatch through `NecroSpellBook`). 11 actives
  (7 spells, 8 offerable summon classes) compete for 6 active slots.
- **Soul Ash is kept on death.** Profane Pact (in-run) and Profane Oath (Ossuary) trade difficulty
  for rewards.

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
  `bone_spear,soul_siphon,corpse_explosion,plague_cloud`)
- `--stage=graveyard|crimson_march` (default graveyard; stage locks are ignored)
- `--difficulty=initiate|necromancer|lich|deathlord` (GDD §8.4; default necromancer = today's game)
- `--modifiers=a,b` (GDD §8.5 run modifiers, e.g. `hardened_faith,scarcity`, or `all`)
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
policies, a Crimson March autotest, the
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
  save section and kept by Restart; `--difficulty=` and `--modifiers=`.

**Next, in priority order:**
1. **Playtest feedback** from the owner and friends; it outranks everything below.
2. **Small fixes:** menu key hints should reflect rebinds. (Archers now hold their ground: user
   decision, GDD §15.0.)
3. **Real art (Phase 2), in progress:** **pixel art** style, locked by the approved necromancer.
   The owner generates sprites in ChatGPT from `docs/art/ART_BIBLE.md` (manifest of every asset,
   with file keys and sizes); process each with `python3 tools/prepare_sprite.py <image> <key>`.
   `SpriteBank` draws `assets/sprites/<key>.png` when present and falls back to the glyph, so art
   lands piecemeal. Done: `player/necromancer`; every summon and evolution (incl. `risen`); every enemy soldier (incl. the
   Reckoning's `inquisitor`). Still to do: the bosses, structures and pickups. Effects are
   short animations (`prepare_sprite.py --anim <sheet or GIF> <id>` → `assets/sprites/effects/`,
   timing in `anim_data.gd`); only `shadow_blast` is hooked so far (test), hook the rest via
   `EffectManager.ring(..., anim)` / `Effect.anim_id` as their art arrives. Pickups, ground tiles and obstacles come later.
4. **Rest of Stage 1's content:**
   - the remaining passives (Bone Plating, Unholy Precision, Unholy Resilience, Bound Souls);
   - evolutions for the Archer and the four later classes, if wanted;
   - a dash and an ultimate.
5. **Phase 3 campaign:** Stage 3 (Sanctum of Judgment,
   Grand Inquisitor Seraphine); skins; achievement rewards.
6. **Phase 4 polish:** accessibility, profiling on real hardware, and the **final balance pass**.
   The owner is happy with balance for now and wants value tweaks deferred to this pass (naive-bot
   death rates above target on both stages and spell-only builds lacking single-target damage are
   known and accepted until then).

**Pace:** the owner is watching usage. Run **one agent at a time** with tight scopes and minimal
test batches (sanity checks only) until told otherwise.
