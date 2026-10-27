# CLAUDE.md: Necropathy

Guidance for Claude Code (and any agent) working in this repo. Read this first, then `README.md`
(how the game works, the architecture, the autotest) and `docs/GDD.md` (the design).

## What this is

**Necropathy** (working title Gravebound; renamed Oct 2026, saves carried over by `save_migration.gd`) is a Vampire Survivors-style game. You play a necromancer who commands an autonomous undead
horde (Warriors, Archers, Mages, the Mender
and Warder priest orders, plus Abominations, Rogues, Gargoyles, Frost Wraiths, Bone Hounds,
Banshees and Corpse Catapults) against the holy Crimson Covenant. It is built in **Godot 4.3**
with **GDScript**, top-down 2D and the GL Compatibility renderer. Art is true pixel art (PNGs in `assets/`, made in the Oct 2026 art pass;
the code drawings in `_draw` stay as the fallback for any missing PNG), and sound and music are synthesized in-engine
(the sounds and the run loop at startup, the menu theme lazily the first time the menu shows; on the no-threads
Web build both in small per-frame steps, bit-identical). It also runs in desktop browsers and on phones /
tablets in landscape (the `Web` export preset; touch controls, mobile UI scale, GDD §15.0 "Mobile browser support").

## Sources of truth

- `docs/GDD.md` is the formal design doc. **Section 15.0, "Resolved Decisions", overrides everything
  else in the GDD.** Every design decision made by the user or during development is recorded there.
- `docs/Gravebound_Complete_Game_Design_and_Horde_Spec.txt` (written under the working title Gravebound) is the original raw spec, the source of
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
- **Synergies** switch on at Lv 2 of every required class and are hinted (card line, banner), never
  secret. The newer classes' synergies are setter / finisher pairs: **one mark bonus per hit** (the
  highest), **half against the stage boss**, no extra tier for evolved pairs; every synergy damage
  bonus goes through `SynergyManager.hit_mult()` from `CombatResolver.damage_enemy()`.
- **Shadow Bolt** has a Nearest/Strongest aim toggle (T / pad Y).
- **Act II, the Ancient Eye** (owner decisions, GDD §15.0 "Act II: the Ancient Eye"): the faction is
  **the Ancient Eye** (never "the Drowned Choir"); it fights the necromancer **for the dead**. Its shared
  rules each have one path: **Claims** (`HordeDirector.claim_fallen()` → `EyeClaims`, `game.claims`: a
  summon dying near a claimer rises 15 s as a hostile Drowned Thrall; killed, its soul is Dread Rally
  charge), **Dread** (`DreadMeter`, `game.dread`: +5% damage taken per 25, applied once in
  `CombatResolver.damage_player()`; raised only through `game.dread.add()`), **unlocks** (`Unlocks.is_open()`
  / `offerable()`, `UnlockData`, Meta `[unlocks]`: Act II spells by its bosses, offered on every stage;
  its counter-passives by its achievements, Act II only through the card row's `act`). Act I runs never
  create any of it (`game.dread` / `game.claims` stay null): stages 1–3 must keep their same-seed
  summaries. Every female character is in the figure-redesign style; the finale (and Seraphine) grant
  new summon classes; each new spell comes with its playable character.
- **Act III, the Electronic Empire** (owner-approved proposal `docs/act3/PROPOSAL.md`, GDD §15.0 "Act III
  foundation (phase 1)"): a machine power that saw the Act II beacons and came; about 60% of its kinds shoot from
  range, and its three shared rules each have one path, all switched on by the STAGE key `empire` (`game.empire`,
  `EmpireRules`): **Line of Fire** (`EmpireShots`: every Empire shot stops on the first summon, Bone Wall segment
  or Orb Shield; barriers absorb; arcing shots ignore it; never through `ProjectileManager`), **Lock-On**
  (`LockOn.paint()`: 1.5 s painted lines, at most 3, a boss override; Signal Ghost through `paint_time()`) and
  **Steel has no soul** (`Enemy.leaves_corpse()` gates every corpse and raise; cyborgs rise as Grave Gunners
  through `HordeDirector.raise_corpse()` → `spawn_temporary()`). Act I and II runs never create any of it
  (`game.empire` stays null): stages 1–6 keep their same-seed summaries. Summons never get act-only rules.
- **Act IV, the Olympian Republic** (owner-answered proposal `docs/act4/PROPOSAL.md`, Acts IV–VI planned, built one
  act at a time; GDD §15.0 from "Act IV proposal (owner answers)" on): Greek gods commanding Roman legions, stages
  `ilion` / `olympus` / `underworld` (Hades is the act's final boss, the Pantheon Trial is stage 11). Its three shared
  rules each have one path, all switched on by the STAGE key `pantheon` (`game.pantheon`, `PantheonRules`): **Wrath
  of the Gods** (`DivineWrath`: waves / lightning / fissures, telegraphed, hitting both armies), **Phalanx** (locked
  shield fronts; the one facing test `PantheonRules.hit_from_front()`, applied once in
  `CombatResolver.damage_enemy()` from the hit's `origin`) and **Glory** (Heroes grow with every summon they kill).
  Act I–III runs never create any of it: stages 1–9 keep their same-seed summaries. A closing card after each act's
  epilogue part ties the acts together (`EpilogueData.CLOSINGS`).
- **Online co-op** (owner decisions Oct 2026, `docs/coop/DESIGN.md`, GDD §15.0 from "Online co-op: relay and
  lobby" on): 2 players, lobby codes through the Cloudflare relay (`server/relay/`, `CoopNet`), each with their own
  necromancer, army and build, in ONE deterministic simulation run on both machines (**lockstep**: only inputs travel,
  bundled ~3 ticks a frame for the free plan; a checksum every 60 ticks; a mismatch ends the run). Shared XP bar
  (×0.5), both pick on a level-up; downed / revived by the partner; enemies spawn ×2 (alive cap ×1.6) and advance on
  the nearest standing necromancer; boss HP ×1.7. One path each: `game.coop` (`CoopSession`, null in solo: solo
  stays bit-for-bit identical), the bound slot (`game.player` / `game.horde` / ... are the slot being stepped;
  owner-specific effects bind their owner's slot), one fixed gameplay view size in co-op (`Game.view_size()` drives
  spawns), level-ups / chests / pause as lockstep commands (never `get_tree().paused` for co-op gameplay), the visuals
  through `game.hud.coop_ui`. Same platform only (Web and native maths differ in the last bit). Any new gameplay
  code must read the necromancer through the bound slot and stay deterministic across machines.
- **The Bone Ring is the only formation** (owner decision Oct 2026, GDD §15.0 "Bone Ring is the only
  formation"; it replaced the four switchable stances): the army always rings the necromancer
  (blockers, flankers and ranged interleaved on the ring, priests and catapults inside) and its
  volleys fly outward. It only overrides numbers the horde AI already uses (`stance_data.gd`, read
  through `game.stance` by the horde director); the hard recall never changes and the flavour bonus
  stays off. There are no stance keys, stick flicks, stance bar, touch rose or Spearhead unlock.
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
- **Hyper mode** (`hyper_data.gd`; unlocked by slaying Seraphine once, any difficulty): a pre-run
  toggle stacking on the difficulty level through `difficulty_modifiers.gd`: the **growth** part of
  enemy HP / damage time scaling ×2 (the Reckoning too), stage boss HP ×1.5, Soul Ash +100% as its
  own line. A Hyper clear (victory) earns a per-stage, per-character gold badge. **Skins**
  (`skin_data.gd`) are **purely cosmetic**: never let one touch a stat.
- **Discovery:** evolution recipes are never hinted. The pause menu's Recipes view, the level-up
  recipe icon row and the main menu's **Codex** show an evolution only once it was obtained in some
  run (Meta `[recipes]`); other Codex entries (spells, summon classes, Covenant kinds, bosses) fill in
  as a run meets them (Meta `[codex]`) and are dark silhouettes until then. The Codex only reads the
  achievement counters; it never changes how anything is earned.
- **UI rules (menu modernization, owner decisions):** cut (chamfered) corners on every UI element;
  Jersey 10 for all text, only at 19 / 28 / 38 / 57 px, and Jacquard 24 only at 43 px (titles and
  banners), through the `UiTheme.Tier` type tiers; one-word buttons and few words; controls shown as
  `InputHints` chips (current bindings, last device), never hard-coded key names; colour carries
  meaning (gold = evolution / chest / victory / selection, crimson = danger / penalty / defeat,
  soul-teal = affordable / focused / new, violet base); UI motion is short, stops, runs on real time,
  is instant under `--autotest` and with Reduce motion, and never touches gameplay state or RNG;
  destructive actions ask first with Cancel focused (`ConfirmDialog`; the Ossuary's Refund all keeps
  its own crimson dialog with the Soul Ash icon), free and reversible ones (Lower Oath) act at once.

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
- `--stage=graveyard|crimson_march|sanctum|harbour|archive|spire|wastes|assembly|citadel|ilion|olympus|underworld` (default graveyard; stage locks are
  ignored)
- `--unlocks=all|none` (Act II's lockable spells / passives / classes in the card pool; forced items
  are open either way)
- `--boss=alaric|vael|seraphine` (puts that boss in the stage's slot, e.g. test Seraphine on the Graveyard)
- `--difficulty=initiate|necromancer|lich|deathlord` (GDD §8.4; default necromancer = today's game)
- `--modifiers=a,b` (GDD §8.5 run modifiers, e.g. `hardened_faith,scarcity`, or `all`)
- `--character=ID` (playable character, default `gravecaller`; locks bypassed, e.g. `bone_oracle`,
  `wither_witch`)
- `--hyper` (Hyper mode, lock bypassed) and `--skin=ID` (force a cosmetic skin, e.g. `dread_sovereign`)
- `--synergies=off` (no army synergy ever activates, old or new: A/B runs for synergy balance)
- `--volleys=on|off` (the bullet heaven pass, default on; `off` = none of the pass runs; the Bone Ring stays)
- `--spawn=kind@T[xN],...` (force-spawn any enemy kind at T game seconds on any stage, e.g.
  `sanctified_sentinel@120x3,high_confessor@180x2,cathedral_guardian@300` or `battle_sister@60x6`)
- `--pact`
- `--meta=none|mid|max`
- `--oath=0-5`
- `--speed=N` (default 8)
- `--meta-save`
- `--coop-bot` (a co-op run in one process, both slots bots; `--policy2=`, `--character2=`, `--classes2=`,
  `--spells2=`, `--coop-down=T`), `--perf` (per-tick timing), `--coop-net=host|join --relay=URL` (a networked lockstep
  run; the full gate is `tools/coop_lockstep_gate.py`), `--coop-net-test` (the transport test); Web builds read the
  autotest flags from `?necro_autotest=`

**"Done" means:**
- `--import` and the autotest runs you touched (at least default, `--mortal`, `--policy=army`) show
  **zero** `SCRIPT ERROR` / `ERROR:` / `WARNING:` lines;
- `stuck_units=0`;
- for balance-affecting changes, a multi-seed check against the targets below.

**Test lean** (owner request Oct 2026, GDD §15.0 "Parallel CI and lean testing"): while building, run only
the autotests for the area a change touches plus one default run; run the full "Done" set (every stage,
the same-seed gates) once per batch of changes, before `main` moves; multi-seed batches only for balance.

CI (`.github/workflows/ci.yml`) runs the import and, as thirteen **parallel** matrix jobs, the Graveyard
autotest with the naive and army policies, a Crimson March autotest, a Sanctum of Judgment autotest (army
policy) and one army autotest per Act II, Act IV and Act V stage; beside them, the Windows/Linux/Web exports (artifacts
`Necropathy-windows` / `-linux` / `-web`) and an exported-build smoke test; also the co-op jobs `coop-net` (relay
protocol + two-process transport test) and `coop-lockstep` (the two-process full-run determinism gate, ~10 min, not
waited on by the publish jobs) and, on `main` pushes, `deploy-relay` (the Worker, secrets `CLOUDFLARE_API_TOKEN` /
`CLOUDFLARE_ACCOUNT_ID`, at `wss://necropathy-relay.smoketsu.workers.dev`). The release and publish jobs
wait for the tests and exports. Pushing a `v*` tag publishes a GitHub Release with the three zips. **GitHub Pages is the game's web
home** (owner decision Oct 2026; itch.io publishing dropped, GDD §15.0 "GitHub Pages is the web home"):
`publish-pages-repo` (variable `PAGES_REPO` = `Smoketsu/NecropathyPlay` + secret `PAGES_TOKEN`) pushes the Web build
from `main` pushes, `v*` tags and manual runs of `main` to that public build-only repository, served at
<https://smoketsu.github.io/NecropathyPlay/>; `publish-pages` (variable `WEB_PAGES` = `true`, this repository's own
Pages) stays optional and off. Artifacts are kept 7 days (test logs 3): a full artifact store blocks every publish. Local web export: `mkdir -p build/web && touch build/.gdignore`, then
`godot --headless --export-release "Web" build/web/index.html` (templates `web_nothreads_*.zip`), then
**always** `python3 tools/patch_web_audio.py build/web/index.js` (shares sample buffers; without it phone tabs
run out of memory and reload mid-run; GDD §15.0 "Web audio buffer patch"; it also runs `tools/patch_web_gl.py`, which makes
deleted WebGL ids reusable: without it every polygon Godot redraws leaks memory and iPhones reload the page mid-fight,
GDD §15.0 "Web GL id leak patch"). Prefer textures over `draw_circle` / `draw_arc` / `draw_colored_polygon` in
anything redrawn every frame (each polygon costs GL objects on the Web).

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
  Shieldbearer, Banner Bearer and Halberdier (and later the Sister of the Scourge, below), a `Boss` base class, Marshal Vael, and ×1.25 Soul Ash;
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
  `scripts/player/dread_rally.gd`: a kill-charged soul meter; surge, 30% heal, raises the whole army
  (owner decision Oct 2026, `RALLY_RAISES_ARMY`), +40% damage and
  attack speed for 8 s through `compute_stats`, knockback); numbers in `player_ability_data.gd`,
  HUD in `hud_abilities.gd`, rebindable, used by every autotest bot.
- **army stances**, later reduced to **the Bone Ring as the only formation** (owner decision Oct 2026,
  GDD §15.0): `stance_data.gd`, `army_stance.gd` (`game.stance`), `stance_formations.gd` (the ring
  posts: radius from the army size, 60-150 px, two deep past that); the switching, HUD stance bar,
  banner, ground outline, pause tiles, touch rose, `--stance=` and the stance bot are gone, and a save
  that bought Spearhead Doctrine gets its 200 Soul Ash back (`MetaData.RETIRED_REFUNDS`).
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
- **Hyper mode and skins** (owner-approved): Hyper (`hyper_data.gd`, through
  `difficulty_modifiers.gd`; unlocked by Seraphine's first defeat, Meta `[hyper]`), a toggle on the
  pre-run screen (`prerun_hyper_skins.gd`, remembered in `[prerun] hyper`, kept by Restart, "+ Hyper"
  on the HUD and end screen, its own Soul Ash line), Hyper clears per stage and character
  (`[hyper_clears]`, gold `HyperBadge` on the stage select). Skins (`skin_data.gd`, cosmetic only):
  a default and a Hyper skin per character (Hyper skin = Sanctum cleared on Hyper with it) and four
  achievement skins (Dread Sovereign, Ivory Seer, Plague Doctor, Heretic Saint; lifetime counters
  `rot_kills`, `high_confessor_kills`, `seraphine_kills_full_army`); `SkinGlyphs` draws the skin's
  art, else the character sprite with the skin's palette tint, emblem and aura; the selector
  remembers a skin per character (`[skins]`). Skins are keyed by `RunConfig.character_key()`
  (= `character_id`, the one accessor) and read the character list from `CharacterData`; a skin
  without art on a character without art is that character's own glyph (`CharacterGlyphs`),
  tinted. `--hyper`, `--skin=`.
- **the content-wave integration** (the four parts above, merged together, GDD §15.0 "Content wave
  integration"): 24 actives for 6 slots; one `SpriteBank.draw()` `tint` parameter; one character
  list (`CharacterData`; `SkinData` only adds skins); the five later spells read their characters'
  innates (Ill Omen through `slow_enemy()`, Stonebone, Conductor, Creeping Rot through
  `rot_enemy()`; Restless × Restless Dead multiply in `spawn_temporary()`); Spirit Binding and
  Mournsong multiply on slows and chills, and every Rot goes through `rot_enemy()` (Mournsong
  included); the pre-run setup screen in two columns at 1280×720 (left: character, skin, Hyper;
  right: difficulty 2×2, modifiers 2×4, totals) with explicit cross-column focus links.
- **the menu modernization** (owner-approved, Oct 2026; nine parallel branches merged on
  `integration`, GDD §15.0 from "Ornamented UI kit" to "Menu modernization integration"; visual and
  UI only, gameplay unchanged; the autotest gains one `codex` summary line):
  - foundations: the **ornamented kit** (`tools/ui_kit.py`: dithered gradient fills, tiled edges,
    bone rosettes, the `ornate` / `header` / `ribbon` / `divider` kinds and the kit slider; crests
    drawn by `kit_style_box.gd`, placed by `UiArtData.CRESTS`); the **type tiers** (`UiTheme.Tier`:
    TITLE Jacquard 43, HERO / HEADER / NAME / BODY Jersey 57 / 38 / 28 / 19, LABEL; sizes in
    `UiArtData.TYPE_*`) with **Jersey 10 body text** (no smooth font left); **`UiMotion`**
    (`ui_motion.gd`, `ui_motion_data.gd`: open / close, staggered entrances, lift, squash,
    count-ups, the fade through black) with the UI sounds (`ui_back`, `panel_open` / `_close`,
    `purchase`, `denied`, `ui_tick` through `Sfx.play_ui()`) and a **Reduce motion** setting
    (`[feel] reduce_motion`); **`InputHints`** (`input_hints.gd`, `input_hint_data.gd`: key / pad
    chips from the current bindings and the last device, the bottom hint strip; developer text
    removed); the **menu diorama** (`menu_backdrop.gd`, `menu_backdrop_data.gd`, art rebuilt by
    `art_source/menu/make_menu_art.py`; moods for the stage select);
  - screens: the **title screen** (`main_menu.gd`: living logo `menu_logo.gd`, `SoulMarker` wisps,
    Play / Codex / Ossuary / Settings / Credits / Quit; numbers in `front_door_data.gd`, icons in
    `mask_icon_data.gd`), **stage select** vignette cards (`stage_vignette.gd`), the **pre-run
    setup** with the character as the hero (`prerun_hero.gd`), the **Ossuary** tiles and detail panel
    (`ossuary_tile.gd`, `ossuary_ui_data.gd`, pixel badges for Soul Ash, the trees and every upgrade),
    tabbed **Settings** (`settings_ui_data.gd`), the **Recipes** grid (`recipe_book_data.gd`); in a
    run (`in_run_ui_data.gd`, `ui_fx.gd`, `ui_shimmer.gd`, `level_pips.gd`, `run_build.gd`): the
    **level-up** cards, the **chest** reveal, the two-column **pause** screen, the **results card**
    (end screen, unlock plates) and the **HUD banner queue** (`hud_banners.gd`) and bars;
  - new screens: the **Codex** with achievements (`codex_screen.gd`, `codex_entries.gd`,
    `codex_feat_row.gd`, `codex_art.gd`, `codex_data.gd`; `CodexLog` as `game.codex` records what a
    run meets, Meta `[codex]` / `[codex_kills]`, GDD §10.1 Collection / Codex and Achievements),
    **Credits** with the Godot and OFL licences (`credits_screen.gd`, `credits_data.gd`), and the
    shared **confirm dialog** (`confirm_dialog.gd`, `confirm_data.gd`: main-menu Quit, pause Restart
    and Main Menu, Settings Reset keys; the Ossuary keeps its own Refund all dialog and Lower Oath
    acts at once);
  - the synthesized menu theme **"Grave Lullaby"** (`menu_theme_synth.gd`, score and mix in
    `menu_theme_data.gd`; rendered lazily, crossfaded with the run loop by `Sfx.play_music()`).
- **synergies for the newer classes** (owner-approved; GDD §6.3 and §15.0 "Synergies for the newer
  classes"): eight setter / finisher pairs (Flesh Rampart, Killing Field, Death from Above, The Wild
  Hunt, Cold Blood, Shatterfall, Requiem, Baying of the Damned) and the capstone The Charnel Menagerie
  (any 4 of the 7 newer classes, `distinct_of`), all in `SynergyData`. Two timed enemy marks
  (`Enemy.staggered_until` from the Abomination / Colossus stomp, `swooped_until` from the Gargoyle /
  Cathedral Horror dive), written only while a synergy reads them; ONE hit path,
  `SynergyManager.hit_mult()` called once from `CombatResolver.damage_enemy()` (source -> class through
  `SynergyData.SOURCE_CLASS`; one mark bonus per hit, the highest; half on the stage boss; the
  Menagerie its own category); behaviour hooks for catapult aim, Pack Hunt prey, rogue dash preference
  and reset, the Baying frenzy (`compute_stats()`), Requiem's `CombatResolver.extend_weaken()` and the
  Menagerie's `replenish_interval()`. HUD list fits 8 rows; pixel badges for all 13 synergies
  (`icons/syn_*`). Autotest `--synergies=off` and a `synergy bonus` line; the army / summon / evolve
  summaries are unchanged.
- the **Sister of the Scourge** (owner request, Oct 2026: a female Covenant soldier in the figure-redesign
  style; GDD §7.2, §15.0): kind `battle_sister`, data in `battle_sister_data.gd` (looked up by
  `EnemyDirector.enemy_def()` after `MarchEnemyData`), a `CovenantKit` (`BattleSisterKit`,
  `sanctum/sister_kit.gd`: a telegraphed 62 px lash that strikes the first two bodies in its line,
  summons or the necromancer, and a zeal surge when a soldier falls nearby, read from
  `CovenantRites.death_near()`), fallback glyph `SisterGlyphs`; on the Crimson March from 6:00 and the
  Sanctum from 7:45 (trickle + two squads each, real id in both timelines); Codex soldier entry;
  pixel art `enemies/battle_sister` (52 px) with a walk strip and bust bounce; autotest `battle
  sister` line, `--spawn=battle_sister@T`.

- the **Web build** (owner decision, GDD §15.0 "Web build after the art" and "Web build"): a no-threads
  Godot 4.3 `Web` export preset (no SharedArrayBuffer / COOP-COEP, any static host; the page sizes the canvas to the screen's safe area, `fitCanvas()` in `web/mobile_shell.html` with canvas_resize_policy 0, GDD §15.0 "Home Screen touch offset");
  the startup synthesis spread over frames on the Web (`StartupSynth`, the run loop as jobs in
  `RunLoopSynth`; 6 ms per frame, `SoundData.WEB_SYNTH_BUDGET_MS`; bit-identical, the desktop path
  unchanged), so the page no longer freezes for it; Quit hidden (`FrontDoorData.WEB_HIDDEN_ITEMS`); the
  fullscreen toggle follows the browser's real state and is not restored at startup; saves in IndexedDB
  (checked across a reload); the engine's copy of a sound's buffer on every play is patched out of the exported
  `index.js` (`tools/patch_web_audio.py`; it got phone tabs killed for memory mid-run); CI exports it (artifact `Necropathy-web`, release zip) and
  publishes it to GitHub Pages; the page starts the game from a **Play** button so the audio is created inside a
  gesture. **Never call `AudioServer.add_bus()`**: Godot 4.3's Web player inserts the bus before Master, which muted
  the whole Web build (GDD §15.0 "Web sound fix"); `Sfx._setup_buses()` uses `set_bus_count()`. **No shader may read the screen** (`hint_screen_texture`, `SCREEN_TEXTURE`, `BackBufferCopy`): the last stand's one did and crashed the owner's phone browser on a Reckoning death (GDD §15.0 "Web death crash: no screen-reading shaders"); use blend-mode rects instead. Tested in headless Chromium (title, a run, reload).
- **phones and tablets in the browser** (owner request "make it mobile friendly", GDD §15.0 "Mobile
  browser support"; native apps still deferred): `TouchSupport` (detection by a coarse pointer, the
  mobile UI scale `content_scale_factor` up to ×1.2 on short phone screens, `fit_to_screen()` on every
  screen's centre container so a screen taller than the visible area shrinks to fit, `pass_drags()` for
  the Codex lists, the portrait `RotateOverlay` that pauses a run); `InputHints.Device.TOUCH` (no chips;
  emulated mouse events are not decisive); `TouchControls` in a run (floating joystick on the `move_*`
  actions through `Input.action_press`, Grave Step / Dread Rally / aim / pause buttons that inject the
  existing actions as `InputEventAction`s: no second path for any rule;
  sizes in CSS px in `touch_data.gd`); the Ossuary buys on a second tap on touch; the **Effects**
  setting Full / Reduced (`effects_data.gd`, Reduced by default on phones, purely visual, autotest
  always Full); the page `web/mobile_shell.html` (no zoom / bounce, audio unlock on touchend, landscape
  lock in fullscreen); iPhone (GDD §15.0 "iPhone sound and fullscreen"): the shell asks for the
  "playback" audio session (the silent switch no longer mutes the game; silent `<audio>` loop before iOS 16.4),
  resumes "interrupted" contexts too and keeps the hardware sample rate, and Settings replaces the Fullscreen
  toggle with a line where the browser has no page fullscreen (`Settings.fullscreen_mode()`); saves (GDD §15.0
  "Save backup codes and the GitHub Pages build"): Settings → Save backs the progress up as a code and restores it
  (`SaveBackup`, `save_backup_data.gd`), the page asks for persistent storage, and the optional CI job
  `publish-pages-repo` (variable `PAGES_REPO` + secret `PAGES_TOKEN`) serves the build from a public build-only
  repository's GitHub Pages, whose saves iPhone Safari keeps (it forgets an embedded frame's). Tested with Playwright phone / tablet emulation (real taps, synthetic
  multi-touch) and a desktop viewport. Keep new screens inside 1280 × 600 layout px or call
  `TouchSupport.fit_to_screen()` on their centre container.

- the **bullet heaven pass** (owner request, Oct 2026, built to try out, then kept; GDD §15.0 "Bullet heaven pass"):
  `VolleyDirector` + `volley_data.gd` behind **Settings → Video → Volleys** (`Game.volleys_on`, default on;
  `--volleys=off` runs none of it; before the Bone Ring it reproduced the old game exactly): summon volleys from class Lv 3 (Lv 5 grows, each
  summon evolution a showpiece; attack-triggered through `SummonedUnit._step_cast()`, specials from their own
  moment), spell echoes from spell Lv 3, the Rally Barrage, denser fodder (spawn ×1.25, HP ×0.8 in
  `DifficultyModifiers`; kills keep full XP, owner decision); shots are packed-array data (cap 320 everywhere, 160 drawn on
  Reduced effects), every hit through `CombatResolver.damage_enemy()` with the firing class's source, at most
  2 boss hits a volley; autotest `volleys` line. **Kept** (owner decision Oct 2026: "volleys are great, makes the screen
  much more visually interesting"; GDD §15.0 "Volleys kept"); the Settings toggle stays.
  **Volley art** (GDD §15.0 "Volley art"): grey tint masks per shot look (`assets/sprites/volleys/`) and the
  `volley_hit` / `volley_flash` strips, tinted with the shot colour and drawn additively (bursts in a ring buffer
  in `VolleyDirector`, drawing only, nothing loaded headless); made with `tools/volley_art.py`.

- the **Act II foundation** (phase 1 of the owner-approved Act II, GDD §15.0 "Act II foundation (phase
  1)"): three registered stages (`harbour_stage.gd`, `archive_stage.gd`, `spire_stage.gd`: at first
  stubs behind "playable": false, "Coming soon"; act 2, Dread, Claims, the tide music; unlock chain from
  Seraphine; own boss ids with a placeholder `script`), act tabs on the stage select, the Ancient Eye's
  shared kinds (`EyeEnemyData`; per-stage tables `HarbourEnemyData` / `ArchiveEnemyData` /
  `SpireEnemyData`, looked up by `EnemyDirector.enemy_def()` / `eye_def()`), Eye kits and bosses loaded
  by name from `scripts/enemies/eye/`, Claims and the Drowned Thrall (`EyeClaims`, `EyeThrallKit`,
  `Enemy.wears`), Dread (`DreadMeter`, `dread_data.gd`, HUD meter, `DreadVignette`), unlocks
  (`UnlockData`, `Unlocks`, Meta `[unlocks]`, end-screen plates, Codex lock lines), the Codex's Ancient
  Eye tab, palette ramps `drowned` / `biolume` and the `eye/` sprite folder (`EyeGlyphs` fallbacks),
  "Below the Tide" (`SoundData.TIDE_SCORE`, score-driven `RunLoopSynth`), autotest `--stage=` /
  `--unlocks=` and the `dread` / `claims` lines. Gate passed: stages 1–3 same-seed summaries unchanged.

- **Act II phase 2** (owner: all three stages in parallel after the foundation; GDD §15.0 rows
  "Gullhaven Harbour (Act II phase 2)", "Act II: the Hollow Archive (Stage 5)", "Ul-Thalos, the Risen
  Spire" and the rows after it, "Fallen Seraph", "Act II integration (phase 2)"), merged on `integration`
  and playable: **Gullhaven Harbour** (`TideDirector`: rising water that slows all but the swimmers,
  surges every 4 min; `HarbourDirector`: bell buoys, smugglers' caches, the Harbourmaster; Deep Kin,
  Tide Caller, Netcaster; Abbot Merrow, `boss_merrow.gd`; Undertow / Maelstrom + Salt of the Deep;
  Brinewalker through `TerrainSlow`, the one ground-slow path; the Brine Widow), **the Hollow Archive**
  (`ArchiveDirector`: ink wells, the orrery, tomes, the Librarian; `RiftDirector`; Scribe, Ink Wraith,
  Pilgrim of the Spore, Gibbering Mass; the Archivist, `boss_archivist.gd`; Forbidden Verse / The Unwritten
  Word + Marginalia; Iron Mind; the Heretic Scribe), **Ul-Thalos** (`SinkingDirector`: the island
  sinks ring by ring; `SpireDirector`: dream pillars, guest squads; Siren of the Eye, Spawn of the Deep,
  Hierophant and Ascension; Vhal'Neth, `boss_vhalneth.gd`, arms and face, the Waking, the ending and the
  main-menu Epilogue for both acts; Call of the Drowned / Tidecaller's Host + Abyssal Pact; the Tide
  Widow), the summon classes **Spawn of the Deep** (Leviathan; unlocked by Vhal'Neth) and **Fallen
  Seraph** (Seraph of Ruin + Fallen Grace; unlocked by Seraphine, also retroactively from a save's
  stage record); the achievements Low Tide, Nothing Unwritten and The Dead God Serves; summon hooks
  `held_until` / `misdirect()` / `compel()`; per-stage autotest report lines. Integration balance in
  GDD §15.0 "Act II integration (phase 2)".

- **content wave 2** (owner-approved proposals, Oct 2026; five parallel branches merged on `integration`,
  GDD §15.0 "Content wave 2 (owner decisions)" and the rows after it): the **victory screen** (`VictoryResults`,
  `LastStand`, `VictoryCard`, `victory_data.gd`: a ~3 s last stand after the Reckoning, per-stage title and boss line,
  best time past 0:00, highlights, Next / Again / Menu; `--victory-preview`); **achievement rewards** (`UnlockData`
  reward types ultimate / title / skin, `TitleData`, `PreRunTitleRow`, `TitleFrame`, `RunRewards`; five new
  achievements Mass Grave, Untouchable, Full Ossuary, Deathlord's Due, Swift Judgment; universal skins Untouchable and
  Deathlord; `--rewards=on`); **more ultimates** (`UltimateData`, `UltimateSystem` as `game.ultimates`: Sovereign's
  Decree, Eclipse, Grave Tide beside Dread Rally on the shared meter; `PreRunUltimates` under the modifiers;
  `--ultimate=ID`; none beats Dread Rally, Eclipse is weakest on the Archive and waits for the owner's playtest); the
  **Bone Golem** (15th summon class, locked until Bone Legion: `GolemBehavior`, `GolemKit`, Ossuary Hunger, Bulwark;
  evolution Ossuary Titan + Grave Masonry; synergy **Bone Bastion** = Golem + any blocker, a damage-cut aura through
  `SynergyManager.bastion_reduction()` in `CombatResolver.damage_unit()`; no act-specific summon rules, owner rule);
  the **illustrated epilogue** (`EpilogueScreen`, `epilogue_data.gd`, 8 panels, plays once after the clear that opens
  it, Meta `[epilogue]`). Default runs stay bit-for-bit identical. Art: wave 2 review page for the owner
  (<https://claude.ai/artifact/6DzAFbmX7Wat8h6nbcatN7>).
- **parallel CI** (owner request, GDD §15.0 "Parallel CI and lean testing"): ~30 → ~4 min from a push to the live
  build.
- the **Act III foundation** (phase 1 of the owner-approved Act III, GDD §15.0 "Act III foundation (phase 1)" and
  the three rule rows after it; handoff and briefs in `docs/act3/`): three registered stub stages (`wastes_stage.gd`,
  `assembly_stage.gd`, `citadel_stage.gd`: "playable": false, act 3, `empire`, music `iron`, unlock chain from
  Vhal'Neth, own boss ids `kestrel` / `motherboard` / `deus_ex_machina` with placeholder scripts, `EmpireGround`
  floors), the Act III tab, `EmpireShots` (Line of Fire), `LockOn`, Steel has no soul and Grave Gunners, the Purge
  Protocol Reckoning (`EmpireRules`: kill-drones and orbital strikes), `EmpireEnemyData` (Scout Drone, Line Trooper,
  Spotter, Kill-Drone; per-stage tables `WastesEnemyData` / `AssemblyEnemyData` / `CitadelEnemyData`, looked up by
  `EnemyDirector.empire_def()`; row key `body` machine / cyborg), `EmpireKit` kits loaded by name from
  `scripts/enemies/empire/`, the Codex Empire tab, ramps `chrome` / `signal`, the `empire/` sprite folder
  (`EmpireGlyphs` fallbacks), "Iron Requiem" (`SoundData.IRON_SCORE`) and the lazy Empire sound pack, autotest
  `--stage=wastes|assembly|citadel` and the `line of fire` / `lock-on` / `steel` / `purge protocol` / `empire kinds` /
  `empire stage` lines (`EmpireReport`). Gate passed: stages 1–6 same-seed summaries unchanged.
- **Act III phase 2, live** (GDD §15.0 rows "The Scrap Wastes (Act III phase 2)" through "Act III goes live"; three
  parallel stage branches merged on `integration`): **the Scrap Wastes** (Signal Pylons, scrap storms, the Trojan Horse,
  Kestrel the Dead Pixel; Aegis Bot, Mortar Walker; Death Ray / Event Horizon + Conductive Marrow; the Lightning Abbess;
  Static in the Wastes → Lead-Lined Bones), **the Assembly Halls** (conveyors through `TerrainSlow`, fabricators, furnace
  channels, the Beta Build, the Motherboard; Arc Engineer, Juggernaut; Hollow Puppet / Puppet King + Strings of the Dead;
  the Marionette; the Grave Drone / Wraith Drone + Overclock; Cold Assembly → Signal Ghost), **the Iron Citadel** (shield
  gates, laser grids, citadel guns through `EmpireRules.strike()`, Sentry Turrets, Valkyrie 2.0, Deus Ex Machina with Varn
  in three phases; Valkyrie Duelist; Scrap Swarm / Deathless Swarm + Machine Soul; the Rust Prophet; the Iron Revenant /
  Deus Revenant + Recoil Frame; Nothing Is Deathless → title Breaker of Engines and the Act III epilogue "The Machines Go
  Dark", 4 panels). Art approved by the owner in six review rounds; Web performance below Ul-Thalos. The double-stepped
  Act II spells fixed (GDD §15.0 "Double-stepped Act II spells").

- the **mobile Web performance pass** (owner report: the page reloading at minute 7 on the Sanctum with Hellhounds,
  Low Power Mode; GDD §15.0 "Web GL id leak patch" and the rows after it, `docs/perf/MOBILE.md`): the Emscripten
  WebGL id leak patched (`tools/patch_web_gl.py`; retained JS heap 435 MB → 9 MB in the Hellhound run), shadows /
  glows / fire patches / shard fields / telegraphs as batched textures, off-screen shots skipped, the phone canvas
  capped at 2× (taps checked), adaptive draw tiers under ~24 fps, Web solo physics catch-up capped at 3 ticks a
  frame (co-op unchanged); visual only, same-seed gates identical; tools `mobile_web_perf.js`, `mobile_tap_check.js`,
  `--monitor` / `--draw-probe` / `--adaptive`. Owner's iPhone check: one full run, no reload, crisp, sound fine,
  cooler phone.

- the **Ossuary expansion** (owner request "more levels in each option, and more options", Oct 2026; proposal Claude Doc,
  `docs/ossuary/`, GDD §15.0 from "Ossuary expansion: owner decisions" on): Soul Ash restarts per act (stage 1 ×1, 2 ×1.25,
  3 ×1.5; Lich ×1.5, Deathlord ×2; `tools/ash_measure.py`, `docs/ossuary/ECONOMY.md`); levels 6-10 for 13 upgrades gated by
  difficulty clears (`[clears]`, `Meta.max_open_tier()`, SAVE_VERSION 2); ten new options and the Dominion tree (after
  Seraphine) with the Ossuary tab bar (Trees / Masteries / Relics / Offerings / Caskets); summon-class Masteries (`mastery_data.gd`,
  `[class_lv5]` / `[masteries]`, through `HordeDirector.compute_stats()`); Relics (`relic_data.gd`, `RelicEffects`, 1 -> 3
  slots, pre-run Rites strip) and expensive Grave Offerings (`offering_data.gd`); cosmetic recolours (`recolour_data.gd`,
  `Recolour`, `SpriteBank.draw()` `recolour`), won from **Recolour Caskets** (owner request "a bit of gambling", GDD §15.0
  "Recolour Caskets (owner request, Oct 2026)": the fifth tab, 350 Soul Ash a casket, one unowned prize each, rarity
  60 / 30 / 10 / 3 with a pity on the 10th, seeded per save, never gameplay RNG; `casket_data.gd`, `CasketLedger` as
  `Meta.caskets`, `[caskets]` / `[casket_skins]`; future casket-only skins are a `SkinData.CASKET_SKINS` row + art; nothing
  buys a recolour directly any more). All of it travels in the co-op loadout. `tools/ossuary_check.tscn` (CI),
  `tools/ossuary_balance.py`, `docs/ossuary/BALANCE.md`; the "too strong" gate (everything + Hyper + Oath 5 + Pact must
  fail a third) reached 31%, accepted by the owner. Prestige is noted for later.

- **online co-op** (owner request "add co-op, a lobby and code system", Oct 2026; `docs/coop/`): the relay and lobby
  (`coop-net`: Worker + `tools/coop_relay.py`, `CoopNet`, Co-op on the title screen, Host / Join with a letter pad,
  the lobby), two slots in one simulation (`coop-sim`: `CoopSession` / `CoopSlot`, `CoopData`, the co-op rules,
  `--coop-bot`, `--perf`; perf in `docs/coop/PERF.md`: volleys cheap, the doubled enemies the cost, so alive cap ×1.6),
  the visuals (`coop-hud`: partner plate, off-screen arrow, revive ring, `CoopUi`, co-op results) and the lockstep
  (`coop-lockstep`: `start_coop_run()`, the driver, bundled frames, checksums, partner drop → army bot, per-device
  saves, the full-run two-process gate; Web vs native desync, so mixed platforms are refused; Web vs Web passes).
  Solo same-seed summaries unchanged. Waits on the owner's real-phone test (input lag ~100-180 ms, late-game frame
  rate).
- the **Act IV foundation** (phase 1 of the Olympian Republic, GDD §15.0 "Act IV foundation (phase 1)" through "Act IV
  foundation review fixes"; three parallel branches, art / audio / code, merged on the lead's branch; phase 2 brief
  `docs/act4/BRIEF_PHASE2.md`, handoff `docs/act4/HANDOFF.md`): three stub stages (`ilion_stage.gd`, `olympus_stage.gd`,
  `underworld_stage.gd`: "playable": false, act 4, `pantheon`, their `wrath` kind, music `bronze`, unlock chain from Deus
  Ex Machina, boss ids `achilles` / `zeus` / `hades` with placeholder scripts, `PantheonGround` floors), the Act IV tab
  (compact tabs beyond three acts), `PantheonRules` with `DivineWrath`, `Phalanx` and `Glory`, the Twilight of the Gods
  Reckoning (`bronze_titan`), `PantheonEnemyData` (Shade of the Dead, Hoplite, Hero, Bronze Titan; per-stage tables
  `IlionEnemyData` / `OlympusEnemyData` / `UnderworldEnemyData`, `EnemyDirector.pantheon_def()`), kits by name from
  `scripts/enemies/pantheon/`, hit origins on `damage_enemy()`, the Codex Republic tab, ramps `bronze` / `marble` /
  `aegean` and the `pantheon/` sprites, "Hymn of Bronze" (`SoundData.BRONZE_SCORE`) and the lazy Pantheon sound pack,
  closing cards per act (`EpilogueData.CLOSINGS`; "The River Runs Dry" after Act III), autotest `--stage=ilion|olympus|
  underworld` and the `divine wrath` / `phalanx` / `glory` / `pantheon kinds` / `pantheon stage` lines (`PantheonReport`).
  Gate passed: stages 1–9 same-seed summaries unchanged.
- **Act IV phase 2** (GDD §15.0 rows from "The Shores of Ilion (Act IV phase 2)" to "Act IV integration (phase 2)";
  three parallel stage branches and the epilogue art merged on the lead's branch, one big test pass at the end, owner
  request): **the Shores of Ilion** (siege towers, Polyphemus, Achilles and his heel; Legionary / testudo, Wolf of
  Rome, Cyclops; Paris's Arrow / Arrow of Fate + Mortal Heel; the Doomed Prophetess; Heel Found → Bronze Breaker),
  **Mount Olympus** (the Pantheon Trial: Ares, Artemis, Poseidon, Zeus; Centaur Archer, Amazon, Gorgon; Stolen Thunder /
  Gigantomachy + Titan's Blood; the Oathbreaker; Twilight of the Gods → Grounded Bones; `DivineWrath.strike()` /
  `open_fissure()`, the one summon stun path `CombatResolver.stun_unit()`), **the Asphodel Underworld** (the Styx,
  Cerberus, Hades on the Claims path; River Styx / Lethe's Flood + Ferryman's Toll; the Ferrywoman; the Myrmidon Shades
  / Legion of Tartarus + Myrmidon Oath; Empty Throne), the Act IV epilogue "The Gods Are Silent" and the card "The Sun
  Still Rises". Stages 1–9 same-seed summaries unchanged.
- **Act V, the Shogunate of the Rising Sun** (owner: "use a similar plan to tackle act 5"; GDD §15.0 rows from "Act V
  foundation (phase 1)" to "Act V goes live"; `docs/act5/`): the foundation (`game.shogunate`, `ShogunateRules`: the
  Sun's Course `SunCourse` day / dusk / night with a darkness texture and lit stone lanterns, the Draw `DrawCuts`, From
  the Shadows `ShadowAmbush`; the shared kinds ashigaru, samurai, teppo gunner, ninja, onryo, oni; the Endless Night
  Reckoning; "The Setting Sun" and the Shogunate sounds) and three stages: **the Burning Province** (paddies, village
  fires, Shuten-doji, Kage and her clones revealed by light; Kunoichi, Kappa; Hundred Shadows / Thousand Shadows +
  Hidden Hand; the Grave Kunoichi; No Shadow Unlit → Paper Lanterns), **Castle Kurogane** (the General of the Left,
  Shogun Kurogane whose army is his health bar, six regiments and the iai duel; Hatamoto, Kiba-musha; Banner of the
  Dead / Hundred Banners + Warlord's Seal; the Ronin Revenant; Regiments Broken → Unbending), **the Road to the Sun**
  (the Kirin, Amaterasu crossing the sky through `SunCourse.set_override()`; Kitsune and fox-fire illusions, Sohei;
  Black Sun / Eclipse of Heaven + Stolen Dawn; the Shrine Maiden of Night; the Bound Oni / Oni Lord + Oni's Resolve;
  The Sun Goes Out → the epilogue part and "The Pit Keeps Count"). Stages 1–12 same-seed summaries unchanged.

**Next, in priority order:**
1. **Playtest feedback** from the owner and friends (actively playtesting); it outranks everything below.
   Act II is new: its feel, difficulty (the Archive's boss fight is the sharpest spike) and the
   placeholder Soul Ash multipliers wait for the owner's runs.
2. **Small fixes:** none open. (Menu modernization wave 1 closed the last one: menu key hints now
   follow rebinds and the last device used, `InputHints` chips, GDD §15.0 "Input hints". Archers
   now hold their ground: user decision, GDD §15.0.)
   **Menu modernization: done (Oct 2026)** (see the Done list above); the menu diorama ships to
   `main` only after the owner has seen its recorded video.
3. **Art pass: done (Oct 2026)** (GDD §15.0 "Art pass (true pixel art)" and the rows after it). Every unit,
   character, skin, boss, structure, pickup, projectile, icon, world marker and overlay (`MarkerArtData`, GDD §15.0
   "Placeholder art batch"), obstacle (both orientations), zone floor, decal, effect
   strip, walk cycle (54 units), the UI kit and the NECROPATHY logo are pixel art at 1 art px = 1 screen px through the
   sharp-pixel shader; fonts Jersey 10 (all UI text, descriptions included) + Jacquard 24 (titles, banners), sized
   by the `UiTheme.Tier` type tiers (GDD §15.0 "Type tiers"). Tools: `tools/gen_image.py` (API
   generation, cost ledger `docs/art/generation_ledger.csv`), `prepare_sprite.py`, `art_check.py`, `make_tile.py`,
   `walk_cycle.py`, `ui_kit.py`, `skin_cap.py`, `pixelate_source.py`, `mesh_props.py` (see-through harbour props drawn on the grid). Boss attack poses are in (`boss_pose_data.gd`). **Figure redesign** (owner
   request, GDD §15.0 "Figure redesign of the female characters"): the Wither Witch, the Soulbinder, their Hyper skins and
   Seraphine (all four sprites), the Banshee and the Keening Lady have exaggerated hourglass figures (fully clothed) and a procedural bust bounce in their walk
   / glide strips (`walk_cycle.py` rig key `bust`); Seraphine, her Avatar, the Banshee and the Keening Lady have glide
   strips. Small detailed figures go through `pixelate_source.py` first. Every bust rig also has a 24-frame **idle
   breathing strip** `<key>_idle.png` (`walk_cycle.py idle`, `IdleData`, GDD §15.0 "Idle breathing bounce") that plays
   while the unit stands, on game time, through the same `SpriteBank.draw()` path. Possible later polish: attack poses for regular units, arm swing, more effect hooks.
4. **Phones: done for the browser (Oct 2026)** (see the Done list; GDD §15.0 "Mobile browser
   support"). Left: measure it on real phones (iOS Safari audio unlock and frame rate first, on the
   GitHub Pages build); native Android / iOS apps stay deferred.
5. **Content wave 2 art review** (owner): the marks on the wave 2 review page; then any redo.
6. **Act III, the Electronic Empire: live (Oct 2026).** The three stages are playable (GDD §15.0 "Act III goes
   live"); the owner balances by hand from playtests (their notes outrank the bots). Open: the naive survival rate,
   the placeholder Soul Ash multipliers, a real-iPhone check; CI has no Act III job yet. Handoff: `docs/act3/HANDOFF.md`.
6b. **Act IV, the Olympian Republic: live (Oct 25, 2026).** The three stages are playable (GDD §15.0 "Act IV goes
   live"), with one CI army job each. Shipped after the art review (eight rounds) and three bot playtest passes at meta
   none (`docs/act4/playtest/`; the Underworld got damage ×1.5, Centaur Archers and the new Shade Archer). Open: the
   owner's own playtest notes (Soul Ash now ×1 / ×1.25 / ×1.5, the per-act rule), the Web performance check
   on Olympus late game. Handoff: `docs/act4/HANDOFF.md`.
6c. **Act V, the Shogunate of the Rising Sun: live (Oct 26, 2026).** The three stages are playable (GDD §15.0 "Act V
   goes live"), one CI army job each. Built with the Act IV plan (`docs/act5/`: proposal copy, foundation and phase 2
   briefs, three parallel agents each, an integration agent for the merge); art review four rounds
   (`docs/act5/ART_REDO_R*.md`); three bot playtest passes at meta none (`docs/act5/playtest/`: Kurogane's cavalry
   softened, the Road to the Sun's damage back to ×1.5). Soul Ash ×1 / ×1.25 / ×1.5 (the per-act rule); the Bound Oni
   has its Ossuary mastery. Open: the owner's own playtest notes, the spell-only build on Kurogane, a phone check of
   the night darkness and the Shogun fight.
7. **Phase 4 polish:** accessibility, profiling on real hardware, and the **final balance pass**.
   The owner's Oct 2026 playtest balance pass is in (GDD §15.0 "Balance pass (Oct 2026 playtest)": Dread Rally raises the army, spells ×1.2, boss HP Alaric −35% / Vael −40% / Seraphine −30%, later level-up items weigh 0.5, Frost Wraith / Bone Hound / Banshee base damage raised; the earlier +5% global multiplier was removed); further value tweaks wait for this pass (naive-bot
   death rates above target on both stages and spell-only builds lacking single-target damage are
   known and accepted until then).

**Pace:** the owner lifted the one-agent limit (Oct 2026): independent features may run as parallel
agents in worktrees, merged on `integration`. Keep test batches proportionate (see **Test lean** above: sanity checks
while building, the full set once per batch, multi-seed screens only for balance), and at most 4 Godot
processes on the 4-core machine.
