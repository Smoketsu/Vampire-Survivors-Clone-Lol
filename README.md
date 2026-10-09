# Gravebound — Godot 4.3 prototype

**Gravebound** is a dark-fantasy bullet-heaven / horde-survival roguelite in the
vein of *Vampire Survivors*, with one twist: **the army is your weapon**. You play
a necromancer hunted by the Crimson Covenant, a fanatical holy order. You only
move. Your shadow spells fire automatically, and an **autonomous undead horde**
of Skeleton Warriors, Skeletal Archers, Undead Mages and Undead Priests follows,
fights, heals, holds the line and regroups without any commands from you.

This repository has a playable **prototype** of the first stage, *The Desecrated
Graveyard*, built in Godot 4.3. Every visual is drawn in code, and there are no
external assets or addons.

Design documents:
- [`docs/Gravebound_Complete_Game_Design_and_Horde_Spec.txt`](docs/Gravebound_Complete_Game_Design_and_Horde_Spec.txt):
  the raw spec and **source of record**. It contains the GDD (Part I) and the
  horde AI technical spec with its numbers (Part II).
- [`docs/GDD.md`](docs/GDD.md): a formatted version of the same spec.

Code comments cite the spec as `GDD §N`.

---

## How to play

1. Download **Godot 4.3** (the standard build, not .NET) from
   <https://godotengine.org/download/archive/4.3-stable/>.
2. Start Godot and choose **Import**, then select this folder's `project.godot`.
3. Press **F5** (or the ▶ Play button). Choose **Play** on the main menu.

The project uses the GL Compatibility renderer, so it runs on almost any GPU.

### Controls

| Action | Keyboard / mouse | Controller |
|---|---|---|
| Move | WASD or arrow keys | Left stick / D-pad |
| Menu / card navigation and confirm | Mouse, arrow keys, Enter / Space | D-pad or left stick, **A** |
| Pick a level-up card | Click, or keys **1 / 2 / 3** | Focus + **A** |
| Shadow Bolt aim: Nearest / Strongest | **T** | **Y** |
| Pause (Resume / Restart / Main Menu) | **Esc** (Esc again resumes) | **Start** (**B** or Start resumes) |
| Debug overlay (FPS, counts, unit FSM states) | **F3** | — |

You don't aim or cast anything yourself. Spells, summons, targeting, healing and
replacing fallen units all happen automatically (GDD §4, §21).

### How a run works

- A **6:00 countdown** runs at the top of the screen.
- You start with **Shadow Bolt** and **2 Skeleton Warriors**. Covenant soldiers
  close in, and each one drops an **XP crystal** when it dies. Walk near a
  crystal and it flies to you.
- Each **level-up pauses the game** and offers **3 cards**: new or upgraded
  summon classes, spells, or passives. Every card shows the level change
  (`Lv 2 -> Lv 3`) and the exact stat changes (for example `Max HP 66 -> 76`).
- The waves follow the Graveyard timeline. Archers and footmen arrive, then a
  Chaplain elite, Purifiers, a consecration pincer, a footman phalanx, a major
  assault and a final wave.
- **Sir Alaric, the Gravebreaker** arrives with **1:00 left**. He telegraphs two
  attacks:
  - **Hammerfall**: a gold warning circle appears, then the smash lands there.
  - **Divine Charge**: a gold warning lane appears, then he dashes along it.

  Killing him drops a large burst of XP crystals, but it does not end the run.
- When the timer reaches **0:00** you have survived. **THE RECKONING** begins:
  waves of *Inquisitors of the End* arrive every 10 s, each wave larger and
  tougher than the last. Normally they will kill you.
- How the run ends:
  - Dying **after 0:00** shows **VICTORY – Run Complete**, with how long you
    lasted past zero.
  - Dying **before 0:00** shows **DEFEAT**.

---

## What is implemented (vs. the GDD)

| Area | Status in this prototype |
|---|---|
| Necromancer | Movement (keyboard and stick), HP, i-frames, pickup radius, hit flash. Can receive priest heals and wards. |
| **Shared summon AI** (§25–§31, §36) | **One** data-driven `SummonedUnit` script runs all four classes. It has the full FSM from §25, soft formation bands around the player (§26), and normalised target scoring (§27). Targets are held for at least 1 s; ranged units redirect when a target is already doomed (overkill reservation); priests use the §31 heal formula. |
| Leash and recall (§24) | Engagement radius 220 px, soft recall at 320 px, hard spectral recall at 650 px. |
| Replenishment (§24) | Each summon ability refills its own queue one unit at a time (Warrior 5 s, Archer 8 s, Mage 12 s, Priest 15 s). A capacity increase spawns the new units immediately. A failed spawn retries without using up the timer. |
| **Warrior blocking** | Warriors are physical blockers. Enemies can't pass through them; overlaps are resolved through the spatial hash, weighted by mass. An enemy touching a warrior is *engaged*: it moves at 60% speed and attacks that warrior. Warriors also shield-bash on a cooldown (damage plus knockback). Sir Alaric's charge goes straight through the wall. |
| **Priests** | Heal allies and the necromancer with the §31 formula; a critically hurt necromancer comes first. Whenever you are under threat (hit in the last 1.5 s, or any enemy within 90 px), a priest also casts an instant damage-absorbing **ward** on you, as long as no ward is active, its own ward cooldown is ready, and nobody is critical. The ward has its own cooldown, so it never replaces a heal. It shows as a ring on the necromancer and in the HUD, and the autotest reports ward counts and wards per minute. |
| Staggered AI and performance (§25, §38) | Unit and enemy decisions run at 5 Hz spread over 12 ticks. Formation updates at 4 Hz, threat checks at 5 Hz, enemy separation at 10 Hz. A uniform-grid spatial hash handles all neighbour and target queries. Projectiles, enemies, summons, XP crystals and effects are all pooled. |
| Spells (§8) | Shadow Bolt (starting spell, homing, multi-shot, pierce; the player can switch its aim between *Nearest* and *Strongest*, i.e. highest current HP, with ties going to the nearest; extra bolts go to the next-ranked targets; shown on the HUD above the ability bar). Shadow Orb Shield (orbiting damage; intercepts a limited number of projectiles, then recharges). Shadow Blast (area damage plus slow). Each has 5 levels. |
| Passives (§34) | Grave Dominion (capacity), Necrotic Vigor (minion HP), Dark Command (minion damage and attack speed), Soul Recycling (faster replacement). Bonus stacking follows §34. |
| Enemies (§10, §35) | Covenant Recruit, Crimson Footman (armoured), Zealous Archer (ranged), Chaplain (heals other enemies), Purifier (hunts undead, ×2 damage to summons), elite variants, and the Reckoning's *Inquisitor of the End*. Survivor convention: **every enemy always advances on the player**. Archers shoot and Chaplains heal while walking in (archers slow briefly after each shot); nobody kites or holds at range. Undead have no dodge AI and act as body blockers, so enemy arrows hit the first summon in their path. |
| Waves (§11) | The data-driven Graveyard timeline, compressed 4× to 5 minutes, then the boss and the Reckoning. |
| Boss (§11) | Placeholder Sir Alaric with telegraphed Hammerfall and Divine Charge. |
| UI (§16) | Main menu, HUD, level-up cards (they grow to fit their text), pause menu, end screens and the F3 debug overlay; all are fully usable with a controller (`ui_accept` / `ui_cancel` include pad A / B, and each screen focuses a button when it opens). The HUD shows: XP bar; HP, orb shields and priest ward; countdown, objective, event banner and boss HP; kills; army per class with replacement progress; ability slots with levels. |
| Art (§16, §17) | Placeholder shapes drawn in code. Undead use blue, violet, green and bone; the Covenant uses crimson, ivory, silver and gold. **Every unit and enemy type has its own silhouette** (for example, warriors are squares with shields, archers are triangles, mages are diamonds, priests are round with a halo). Hit flashes and death pops are included. |

### Where the numbers come from

All tunable numbers are in `scripts/data/`. Each value is tagged in a comment:

- Values from the spec are marked `# GDD §N`.
- Invented values are marked `# TUNING (not in GDD)`.

**From the spec:**

- Unit table (§23): HP, damage, attack interval, preferred range, speed, level-1
  count and radius for all four classes.
- Priest heal of 8 HP per 2 s cast (§23).
- Replacement timers 5 / 8 / 12 / 15 s (§24).
- Spawn distance 35–80 px (§24).
- Leash distances 220 / 320 / 650 px (§24).
- AI rates of 5 / 4 / 5 Hz (§25).
- Formation bands 35–85, 85–155 and 60–125 px (§26).
- Warrior and priest steering weights (§26).
- 1 s target commitment and "critical below 35% HP" (§27).
- Warrior intercept radius of 80 px (§28).
- Archer kite distance of 45 px (§29).
- Heal score weights 0.6 / 0.2 / 0.2 (§31).
- Warrior level progression 2 → 3 → 5 → 6 → 8, with its % bonuses (§34).
- 6 active and 6 passive ability slots (§6), 5 levels per skill, and 3 cards per level-up.

**Invented** (the spec is silent on these): all enemy and boss stats, spell
values, passive values, archer/mage/priest level progressions (aimed at the §42
sandbox army of 5 archers, 3 mages and 2 priests), archer and mage steering
weights, target-score weights, the XP curve, player stats, the warrior
blocking/bash and priest ward values, and the Reckoning scaling.

---

## Architecture

```
scenes/main.tscn            Minimal entry scene (one Node + main.gd)
scripts/
  core/
    game_state.gd           The only autoload: CLI options (autotest), session prefs, last run summary
    main.gd                 Switches menu <-> run (a run is a fresh Game node every time)
    game.gd                 One run: builds world + managers in code, fixed-order simulation step,
                            level-up / pause / end-of-run flow
    spatial_hash.gd         Uniform grid for radius queries (enemies and allies, rebuilt per tick)
    combat_resolver.gd      All damage / healing / kills / XP drops / stats go through here
    effect.gd, effect_manager.gd   Pooled cosmetic effects and boss telegraphs
    glyphs.gd               All placeholder shapes (world entities AND UI icons share this code)
    ground.gd               Procedural graveyard floor, redrawn only when the camera changes cell
    autotest.gd             Headless self-test driver
  player/necromancer.gd
  horde/
    horde_director.gd       Army registry, pools, caps, effective stats, replenishment queues,
                            formation anchors, threat evaluation, staggered 5 Hz AI ticks
    summoned_unit.gd        The ONE shared FSM/steering/targeting AI for all summon classes
  enemies/
    enemy.gd                Data-driven Covenant soldier (melee / purifier / ranged / healer),
                            plus warrior-blocking resolution
    boss_alaric.gd          Sir Alaric (extends Enemy): Hammerfall + Divine Charge
    enemy_director.gd       Wave timeline, events, boss, Reckoning, pooling, recycling
  abilities/
    ability_manager.gd      Spell casting, passive values, level-up card generation + deltas
    orb_shield.gd           Shadow Orb Shield
    projectile.gd, projectile_manager.gd   Pooled projectiles + overkill reservations
  pickups/xp_crystal.gd, xp_manager.gd     Pooled XP crystals with magnet
  ui/                       hud, level_up_panel, pause_menu, end_screen, main_menu,
                            debug_overlay, hud_bar, icon_glyph, ui_theme
  data/                     DESIGNER-TUNABLE DATA (no logic):
    unit_data.gd            Summon classes, level tables, AI weights, leash/rates
    enemy_data.gd           Enemy roster, boss, Reckoning enemy, elites
    wave_data.gd            Countdown, segments, events, Reckoning escalation
    ability_data.gd         Spell level tables
    passive_data.gd         Passive level tables
    player_data.gd          Player stats, XP curve, slot counts
    palette.gd              Colour language
```

**Simulation order.** Each physics tick (60 Hz), `Game` runs these steps in order:

1. Rebuild the enemy and ally spatial hashes.
2. Player.
3. Spells.
4. Horde: replenishment, formation (4 Hz), threat (5 Hz), then each unit's
   `think()` on its stagger slot and `physics_step()` every tick.
5. Enemies: trickle and events, `think()`, separation, movement, warrior blocking.
6. Projectiles.
7. XP pickups.
8. Effects.

The whole step is timed and the cost is shown in the F3 overlay.

**Pooling and stale references.** All pooled entities have a `generation`
counter. A unit, enemy, projectile or priest that holds a reference checks the
generation, so it never acts on a recycled node.

**Overkill reservation.** Ranged damage that is already in flight is recorded on
the target (`Enemy.incoming_damage`). Archers, mages and Shadow Bolt pass over
targets that are already expected to die. Priests do the same with
`incoming_heal`, so two priests don't both heal the same full-HP ally.

**Data vs runtime.** As §37 asks, design data is immutable and lives in
`data/`. Per-run levels, timers and live instances belong to the
directors and managers.

---

## Headless verification / autotest

```bash
# Parse/import check
godot --headless --import

# Full automated run: skips the menu, picks cards automatically, fast-forwards
# (time_scale 4 with physics ticks scaled to match), plays through the countdown,
# the boss and the Reckoning, then prints a summary and quits
# (exit code 0 = run completed).
godot --headless --fixed-fps 60 --quit-after 40000 -- --autotest
```

Options (after `--`):

| Option | Effect |
|---|---|
| `--autotest` | Run the automated playthrough. |
| `--mortal` | The player can die before 0:00 (a balance check). By default the autotest player cannot die until 20 s into the Reckoning, so the whole timeline gets exercised. |
| `--speed=N` | Time scale (default 4). |
| `--seed=N` | RNG seed (default 1337). |
| `--timeout=N` | Give up after N game seconds (default 480). |
| `--policy=NAME` | Level-up card policy: `naive` (default; takes every new summon class, then new spells, then new passives) or `army` (a summoner build that levels summons and army passives first). |

Setting the environment variable `GRAVEBOUND_AUTOTEST=1` is the same as `--autotest`.

The summary covers: result, time, kills, level, army per class, boss
spawn/kill, all cards picked, and per-source damage (`dmg_warrior`, `dmg_bolt`,
`dmg_bash`, …). It also reports damage taken by summons, split by attacker
(`summon_dmg_from_*`) and damage taken by the player, split by attacker
(`player_dmg_from_*`); damage to the boss by source (`bossdmg_*`); Shadow Bolt
damage per aim mode (the autotest uses Nearest, then switches to Strongest when
the boss spawns); heals, wards and orb intercepts; peak entity counts;
pool node counts; and the average and worst simulation-step cost. These numbers
are the starting point for tuning. Every 30 s it also prints `[metric]` lines
(army size and capacity per class, damage taken by attacker, enemies alive by
kind), and at the end `boss_hp_at_0` and `min_hp_before_0` (the lowest player
HP before 0:00). Multi-seed tuning scripts parse these lines.

---

## Known limitations

- **Balance is first-pass.** All `TUNING` values are guesses. In the autotest,
  the army holds until about 3:00, then gets worn down by footmen, Covenant
  arrows and Purifiers. With the autopilot's build, Sir Alaric usually survives
  until the Reckoning. The autopilot is a simple "flee and collect XP" script,
  not a skilled player.
- Only the Graveyard stage, and only a 6-minute version of it (the GDD runs are
  20–30 minutes).
- The arena is open, with no solid obstacles, so line-of-sight checks and
  obstacle avoidance are not used (the steering has no obstacle term).
- There are no evolutions, army synergies, ultimate, dash, rerolls, meta
  progression (Soul Ash), saves, settings, skins, difficulties or modifiers yet.
  The HUD shows "Modifiers: none".
- Sir Alaric only has Hammerfall and Divine Charge. Consecrated Ground, Call to
  Arms and Judgment of the Dead are not in.
- Desecration events, empowered graves and Crypt Defender are not in. The
  consecration and Templar timeline beats use stand-in waves.
- No audio, damage numbers or accessibility toggles (§38).
- Performance was measured headless: about 2.8 ms of simulation per tick with
  40 summons and 150 enemies. Rendering cost on real hardware has not been
  profiled yet.

## Next steps (grouped by GDD §19 phases)

**Phase 1 – Prototype (mostly done):** tune the TUNING values using the
autotest stats; give the horde a feel pass (formation spacing, kite timing,
warrior wall shape) with a human player.

**Phase 2 – Graveyard vertical slice:**
- Evolutions and their passives: Bone Plating, Unholy Precision, Forbidden
  Knowledge, Dark Benediction, Soul Conduit, Warding Ritual, Abyssal Focus.
- Army synergies (§9).
- Unholy Resilience and Bound Souls passives.
- A sixth enemy type (Templar Knight) and the Banner Bearer.
- Sir Alaric's other attacks.
- The desecration / grave mechanics.
- Saves.
- Settings for density, screen shake and minion HP bars (§38).
- Audio with voice limits.

**Phase 3 – Campaign:** Crimson March and Sanctum stages, Marshal Vael and
Grand Inquisitor Seraphine, remaining enemies, Soul Ash meta progression,
difficulties and modifiers, skins.

**Phase 4 – Polish:** real art and animation, audio, accessibility, full
controller UX, profiling on target hardware (§40 stress scenarios), balance.
