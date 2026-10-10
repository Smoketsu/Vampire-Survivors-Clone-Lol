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

### Option A: download a ready-made build (no Godot needed)

- **Releases:** on GitHub, open **Releases** and download `Gravebound-windows.zip` (or `-linux.zip`), unzip it, and run
  `Gravebound.exe`. Windows SmartScreen may warn that the app is unrecognized because it is unsigned. Click
  **More info → Run anyway**.
- **Latest commit:** open **Actions → CI**, click the newest green run, and download the `Gravebound-windows`
  artifact at the bottom of the page. You must be signed in to GitHub.

### Option B: run from source in Godot

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
| Level-up: Reroll all cards (2 per run) | **R**, or the Reroll button | **X**, or focus the button + **A** |
| Level-up: Banish a card (2 per run) | **B**, then pick the card (**B** / **Esc** cancels) | **LB**, then pick the card (**LB** / **B** cancels) |
| Level-up: Skip (unlimited, heals 8% HP) | **N**, or the Skip button | **RB**, or focus the button + **A** |
| Shadow Bolt aim: Nearest / Strongest | **T** | **Y** |
| Pause (Resume / Restart / Main Menu) | **Esc** (Esc again resumes) | **Start** (**B** or Start resumes) |
| Debug overlay (FPS, counts, unit FSM states) | **F3** | — |
| Ossuary (Soul Ash upgrades) | **The Ossuary** in the main menu; arrows move, Enter buys; Esc closes | D-pad / stick move, **A** buys, **B** closes |
| Settings (volume, shake, damage numbers, fullscreen, keys) | **Settings** in the main or pause menu; Esc / Back closes | Focus + **A**; **B** closes |
| Rebind a key (in Settings) | Select a binding, then press the new key | **B** cancels |

You don't aim or cast anything yourself. Spells, summons, targeting, healing and
replacing fallen units all happen automatically (GDD §4, §21).

### Audio, Feel & Settings

- **Audio, with no audio files.** `Synth` builds every sound effect and a 12 s
  dark D-minor ambient loop (drone, choir pad, heartbeat) as 16-bit PCM
  `AudioStreamWAV`s on worker threads at startup. The main thread is blocked
  for under 1 ms; all sounds are ready in about 0.15–0.3 s and the music in
  about 0.3–0.5 s. Recipes and voice limits live in `scripts/data/sound_data.gd`.
  The `Sfx` autoload creates the **Master / Music / SFX** buses and plays
  sounds from a pool of 24 voices. Each sound also has its own voice cap,
  cooldown and priority, so 150 enemies dying at once play only a few voices.
  In headless runs everything runs except actually starting the players.
- **Feel (`Juice` autoload).** Trauma-based screen shake (bigger for boss
  impacts and player damage), plus a short hit-stop on Hammerfall impacts,
  boss kills and elite kills. Hit-stop is off under `--autotest` and while
  the game is paused. Also: death pops, XP sparkles, a red hurt vignette, and
  floating damage numbers. Particles and numbers are drawn by one node from
  fixed ring buffers, and hits on the same enemy merge into one number.
  `Juice` gets most events from the run's existing signals and stats.
  Gameplay code only calls it in a few one-line hooks.
- **Settings (`Settings` autoload, `SettingsMenu`).** Volume sliders, screen
  shake, damage numbers, fullscreen, and keyboard rebinding of the primary key
  for Move up / down / left / right, Shadow Bolt aim and Pause. Arrow keys and
  controller bindings stay fixed, and binding a key that is already in use
  swaps the two keys. Everything works with a controller. Settings are saved
  to `user://settings.cfg` when the menu closes and loaded at startup.

### How a run works

- A **20:00 countdown** runs at the top of the screen.
- You start with **Shadow Bolt** and **2 Skeleton Warriors**. Covenant soldiers
  close in, and each one drops an **XP crystal** when it dies. Walk near a
  crystal and it flies to you.
- Each **level-up pauses the game** and offers **3 cards**: new or upgraded
  summon classes, spells, or passives. Every card shows the level change
  (`Lv 2 -> Lv 3`) and the exact stat changes (for example `Max HP 66 -> 76`).
- The waves follow the GDD Graveyard timeline at its real times: recruits from
  0:00, archers and footmen at 3:00, a Chaplain elite at 5:00, Purifiers at
  8:00, a grave consecration at 10:00, Templar Knights at 13:00, the major
  assault at 15:00 and the final preparation wave at 16:00. Smaller waves fill
  the gaps, density ramps up in steps with short lulls after the big beats,
  and enemies get tougher over time.
- **Level-ups slow down over the run.** The first comes after about 20-25 s
  and a focused build has every slot maxed (plus its evolution) at about
  16:00 (level-ups plus about 5 treasure-chest upgrades); a scattered build
  is still filling in its last levels at 20:00.
- **Sir Alaric, the Gravebreaker** arrives with **3:00 left** (17:00). He
  telegraphs two attacks:
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

### Evolutions & Synergies

- **Evolutions** (GDD §6.1): once a spell reaches **Lv 5**, you own its
  paired passive (any level) **and the run has reached 8:00 elapsed** (12:00
  left on the timer), the **next treasure chest** grants its evolution first
  (the GDD's "special elite reward"); while an evolution waits, a chest drops
  within about 40 s. Evolutions never appear on level-up cards, and the
  spell / passive card hints say so ("from a treasure chest, timer 12:00 or
  less"). The evolution replaces the spell in its slot. The whole eligibility
  check is `AbilityManager.ready_evolutions()` with its numbers in
  `EvolutionData` (`BASE_LEVEL_REQUIRED`, `PASSIVE_LEVEL_REQUIRED`,
  `MIN_ELAPSED`).

| Spell | + Passive (its standalone effect) | = Evolution |
|---|---|---|
| Shadow Bolt | Soul Conduit (+10–50% spell damage) | **Void Barrage**: 4 rapid piercing void bolts that split into 3 shards on impact |
| Shadow Orb Shield | Warding Ritual (−5–25% damage taken) | **Eclipse Ward**: 6-orb rotating eclipse barrier with periodic damage pulses that push foes back |
| Shadow Blast | Abyssal Focus (−5–25% spell cooldowns) | **Abyssal Detonation**: a blast that pulls foes inward, then a second detonation |
| Bone Spear | Shade Stride (+3–15% move speed) | **Ossuary Lance**: great barbed lances thrown ahead of you *and* behind, pierce 8, knock foes back |
| Soul Siphon | Vampiric Rite (+0.2–1.0 HP/s regeneration) | **Soul Rapture**: 5 braided soul tethers; a tethered foe bursts when it dies; spare lifesteal heals your most wounded summon |
| Corpse Explosion | Necrotic Expanse (+5–25% spell area) | **Grave Eruption**: bigger bursts that leave bone-spike fields (damage + slow); foes an eruption kills erupt in turn |
| Plague Cloud | Lingering Malediction (+10–50% spell durations) | **Pestilence**: black clouds that creep after foes, Rot +25%, and end in a Death Nova (double damage to rotting foes) |

- **Army synergies** (GDD §6.3) turn on automatically while every required
  summon class is at **Lv 2+**. A banner announces each one, and the active
  ones are listed above the army panel:
  **Shieldwall of the Damned** (Warriors + Priests: warriors get barriers),
  **Volley of the Fallen** (Archers + Mages: mage hits mark foes, archers deal
  +35% to marked foes), **March of the Deathless** (any 3 classes: +15% move
  speed and regeneration), **The Unholy Host** (all 4: +15% attack speed,
  −15% damage taken, aura on every summon).
- **Level-up cards** are weighted: upgrades to items you own, and items on an
  evolution path, come up more often. A hand is never made only of useless
  cards, and fallback cards (heal, +max HP, raise every fallen summon) fill
  any empty slots once everything is maxed. Use **Reroll** (2 per run),
  **Banish** (2 per run; removes that item from the run) and **Skip**
  (unlimited; small heal) as needed.
- Numbers are in `scripts/data/evolution_data.gd`, `synergy_data.gd`,
  `level_up_data.gd` and `passive_data.gd`. The autotest opens every chest
  it reaches. Its summary reports the evolutions obtained (with times),
  the active synergies, and the rerolls, banishes and skips used.
  `--policy=evolve` runs a spell build that chases the evolutions.

### The newer spells

Four more necromancer spells (code in `scripts/abilities/spells/`, numbers in
`AbilityData` / `EvolutionData` / `PassiveData`, all `TUNING`). Each has 5
levels; the card lists every stat as old → new. Soul Conduit, Abyssal Focus,
the meta Shadowcraft upgrades and the Hyper power-up apply to them like to
the first three spells, and they keep hitting enemies frozen by Stasis.

| Spell | What it does | Lv 1 → Lv 5 |
|---|---|---|
| **Bone Spear** | Straight piercing bone spears thrown the way you are **walking**, aim-assisted: the volley flies at the nearest enemy within ±34° of your walking direction (standing still keeps the last one), or at the nearest enemy when none is ahead. Throws only while an enemy is within 420 px. | 18 dmg, 1 spear, pierce 2, every 1.3 s, 360 px → 31 dmg, 3 spears, pierce 4, every 0.9 s, 440 px |
| **Soul Siphon** (GDD §5.3) | Tethers hold the **strongest** foes in range (highest HP; foes already doomed are skipped) and drain them on a pulse; part of the damage heals you, **capped per second**. | 7 dmg / 0.5 s, 1 tether, 170 px, 25% lifesteal, cap 1 HP/s → 14 dmg / 0.45 s, 3 tethers, 210 px, 35%, cap 2 HP/s |
| **Corpse Explosion** | Every enemy that dies (to your horde, spells or anything) leaves a corpse for 8 s. The spell detonates the corpses near you with the most foes around them. | 24 dmg, 1 corpse, radius 50, every 2.2 s → 40 dmg, 3 corpses, radius 70, every 1.6 s |
| **Plague Cloud** | A lingering cloud settles on the most packed foes (avoiding spots already covered), ticks damage every 0.5 s and inflicts **Rot**: for 1.5 s the foe takes extra damage from **every** source (bosses get half). | 3 dmg/tick, radius 55, 3.5 s, every 3.4 s, Rot +8% → 4 dmg/tick, radius 70, 5 s, every 3 s, Rot +18% |

Rot is a field on the enemy (`rot_until`, `rot_amp`) that
`CombatResolver.damage_enemy` applies to every hit; the extra damage is the
`rot_bonus_dmg` stat. Shade Stride and Vampiric Rite are read by the
necromancer's movement and regeneration; Necrotic Expanse and Lingering
Malediction are two more categories in `AbilityManager.apply_spell_mods()`
(radius keys; `AbilityData.DURATION_KEYS`, which include Shadow Blast's slow).

### Stage & Boss

- **Obstacles.** Gravestones, dead trees and crypt walls are solid for the
  player, summons and enemies. Each one is a simple circle or rectangle, so no
  physics engine is used. Units walk around obstacles, and nothing ever spawns
  or is recalled inside one. Arrows and spells still fly over them.
- **Stage events** (`WaveData.EVENTS`, on the GDD §11 timeline at real times):
  - **Empowered graves** glow near you from 0:45, then every 75 s. Walk onto
    one to raise temporary warriors (3 early, one more every 5 minutes), or
    to bring back every fallen summon at once.
  - **Desecration** at 10:00 (as in the GDD) and 14:00. Chaplains march to
    the marked graves and start channelling. Kill a Chaplain to save its
    grave (you get XP). Otherwise the grave becomes **holy ground**: a gold
    zone that burns and slows undead, stings you, and blocks summon
    replacement inside it.
  - **Templar Knights** arrive at 13:00. They telegraph a short charge lane,
    then rush along it and shove summons aside. A warrior in the lane stops
    the rush.
  - **Crypt Defender** at 16:30. Walk to the crypt to wake 6 strong guardians
    for 60 s, in time for Sir Alaric.
  - **Call to Arms** waves at 18:00 and 19:00 reinforce Alaric on top of his
    own Call to Arms.
- **Sir Alaric** (42 000 HP, arrives with 3:00 left) uses all five GDD
  abilities. Each one is telegraphed:
  - **Hammerfall**: a gold circle. Each summon inside soaks 20% of the hit
    on you.
  - **Divine Charge**: a gold lane. Every undead body he hits absorbs part
    of the charge, and enough bodies stop it.
  - **Consecrated Ground**: arming gold circles that become holy zones for
    10 s.
  - **Call to Arms**: crimson rally banners mark where infantry will arrive.
  - **Judgment of the Dead**: ivory sigils on your summon clusters. Summons
    inside take heavy damage; you are not hurt.

  At **50% HP** he enters **Wrath**: his specials come faster, he places more
  zones and marks, and he casts Call to Arms immediately.
- **Temporary summons** from graves and the crypt don't count toward your
  caps or the HUD counts, and they crumble when their time runs out.
- **Autotest.** The summary also reports boss attacks per type, stage events
  fired, obstacle collisions resolved and `stuck_units`. A unit counts as
  stuck if it is trying to reach its target or anchor but has not moved more
  than 10 px in 10 s; this should stay at 0.

### Meta-progression (Soul Ash)

- **Soul Ash** is earned at the end of **every** run and kept even if you die
  (survivor convention). The end screen shows the breakdown and the new total;
  the main menu shows the balance and a lifetime line (runs, best time, boss
  kills, achievements). Formula (all `TUNING`, in `scripts/data/meta_data.gd`):

  | Part | Rate | Good 20:00 run |
  |---|---|---|
  | Time survived on the countdown | 7.5 per minute | 20 min = 150 |
  | Enemies slain | 0.03 each (1 per ~33) | 3,000 = 90 |
  | Elites slain | 4 each | 15 = 60 |
  | Sir Alaric slain | 75 | 75 |
  | Seconds survived into the Reckoning | 2.5 per second (capped at 180 s) | 30 s = 75 |
  | **Ash Harvest** (Fortune) | +5% per tier on the sum | |

  A strong run earns about **450** at no upgrades (about 550-610 with mid / max
  upgrades, Ash Harvest included): two or three mid-tier upgrades. A death at
  9-11 min still keeps about 100-150. The Reckoning pays only about 8% of a
  good run. Buying everything costs **8,965**, about 17-20 good runs (15–25
  including weaker runs and Ash Harvest), plus 375 for the optional Profane
  Oath (9,340 in all). The Profane Pact and Oath rewards add their own bonus
  lines on top (below).
- **The Ossuary** (main menu) holds the four GDD §9.2 trees. Each upgrade
  raises one stat per tier, costs rise per tier, and some need a prerequisite
  in the same tree:

  | Tree | Upgrades (per tier, tiers, cost of tier 1 → last) |
  |---|---|
  | Necromancy | Necrotic Marrow minion HP +6% (5, 40→230) · Sharpened Bones minion damage +5% (5, 40→230) · Grave Call replacement time −6% (3, 60→200) · Risen Vanguard +1 Warrior capacity (2, 130→280; needs Marrow II) · Legion of Bone +1 capacity for every class (1, 500; needs Vanguard II) |
  | Shadowcraft | Umbral Potency spell damage +5% (5, 40→230) · Quickened Rites spell cooldowns −3% (4, 60→250) · Widening Dark Shadow Blast / pulse radius +6% (3, 70→230; needs Potency I) · Shadow Mastery spell damage +10% (1, 450; needs Rites III) |
  | Survival | Grave-Hardened Flesh max HP +10 (5, 40→230) · Bone Mail damage taken −3% (4, 60→250) · Fleet Shade move speed +4% (3, 50→175) · Undying Will one revival per run at 50% HP with a knock-back burst (1, 550; needs Bone Mail II) |
  | Fortune | Soul Magnet pickup radius +10% (4, 30→155) · Grave Tithe XP gain +4% (3, 60→200) · Ash Harvest Soul Ash +5% (3, 80→270) · Fate's Thread +1 reroll (2, 120→250) · Banishing Rite +1 banish (2, 150→310; needs Thread I) |
  | Oath (standalone) | **Profane Oath**: opt-in difficulty (5, 25→125). See *Power-ups & Profane Pact* below |

  Every button shows the tier pips, the effect delta (`Minion HP +6% -> +12%`)
  and whether it is affordable, too expensive, locked or maxed. **Refund all**
  (respec) returns every spent Soul Ash after a confirmation. The screen is
  fully usable with keyboard or controller.
- **One modifier path.** At run start `Meta.run_modifiers()` turns the
  purchased tiers into a `MetaModifiers` object (`game.meta`). The existing
  stat code reads it in a few places (horde `compute_stats` / `capacity` /
  `replenish_interval`, `apply_spell_mods`, `damage_player`, `add_xp`, the
  reroll / banish counts, and the player's run-start stats). Each meta stat is
  its own stacking category (GDD §6.4), and with no purchases every value is 0.
- **Achievements** (GDD §9.4, tracked over all runs): *Bone Legion* (Skeleton
  Warriors land 1,000 killing blows), *Heretic's Bane* (500 Chaplains slain),
  *Dread Sovereign* (slay Sir Alaric while owning all 4 summon classes). Their
  GDD unlocks (Bone Golem, a priest evolution unlock, a skin) don't exist yet,
  so each pays a one-time Soul Ash bounty (100 / 100 / 150) for now.
- **Save file.** `user://save.cfg` (ConfigFile, separate from `settings.cfg`)
  stores `save_version`, Soul Ash, every tier, lifetime stats and achievements.
  It is written on every run end, purchase and refund (via a temp file and a
  rename). A missing file starts a fresh profile. An unreadable file is kept as
  `save.cfg.corrupt` and the game starts fresh. Every value is type-checked and
  clamped, unknown keys are ignored, and tiers whose prerequisite is missing
  are refunded. The autotest never reads or writes it (unless `--meta-save`).
  The active Profane Oath tier is saved as `[oath] active`.

### Power-ups & Profane Pact

- **Power-up drops** (`scripts/data/powerup_data.gd`, all `TUNING`). Killed
  enemies sometimes drop a power-up: a dark round token with a pulsing ring
  and its own icon, so it never reads as an XP crystal.

  | Power-up | Weight | Effect |
  |---|---|---|
  | **Soul Magnet** (violet horseshoe) | 3 | Every XP crystal on the stage flies to you. |
  | **Grave Feast** (haunch on a bone) | 3 | Restores 30% of max HP. |
  | **Hyper** (violet lightning) | 2 | 10 s: your spells deal ×2 damage and their cooldowns are halved. Violet screen tint. |
  | **Stasis** (cold-blue hourglass) | 1.5 | 5 s: every enemy is frozen (no movement, attacks, heals or arrows; frost shell). Sir Alaric is frozen for the first half only, Reckoning enemies are immune. A frozen attacker's telegraphs (and Alaric's marks and arming zones) pause with it, and frozen Desecration Chaplains stop channelling. Cold-blue screen tint. |
  | **Dark Frenzy** (green skull, crossed bones) | 2 | 12 s: summons deal ×1.5 damage and attack ×1.5 as fast (through the horde's effective stats). |
  | **Soul Nova** (white-violet starburst) | 0.5 (rarest) | Screen clear: every regular enemy on screen dies, elites lose 50% of their current HP, Sir Alaric takes 5% of his max HP; Reckoning enemies are immune. The kills go through `CombatResolver`, so they drop XP and count for stats, Soul Ash and achievements. Big flash, shake and sound. |

  Drop rules: **0.2%** per regular kill, **20%** per elite kill, and Sir
  Alaric always drops one. A **pity timer** guarantees a drop on the next
  kill after 120 s without one (about 17 drops per run). At most **3** lie on the ground (a roll at
  the cap is lost), each despawns after **30 s** and blinks for its last
  7 s. Nothing drops from Reckoning enemies or after 0:00. You pick one up by
  **walking over it** (within 12 px of your body: a fixed radius on purpose,
  so it is a routing choice and the Soul Magnet meta upgrade doesn't vacuum
  power-ups). Each has its own pickup sound and a screen flash. Running
  buffs are listed under your HP with the time left. **Collecting a buff
  that is already running refreshes its duration to full; it never stacks.**
  Drop rolls use their own seeded RNG, so autotest runs stay deterministic.
- **Treasure chests** (`scripts/data/chest_data.gd`, all `TUNING`). A gold-
  banded crimson reliquary. Elites drop one **10%** of the time, Sir Alaric
  always, and a pity timer drops one from the next kill after **360 s**
  without a chest, or after only **40 s** while an evolution is ready. That
  makes about **4-7 chests per run** (median 5 for the army bot, 4 naive, 7
  for the spell build). Chests never despawn (at most 3 on the
  ground), and none drop from Reckoning enemies or after 0:00. Walking over
  one pauses the run and shows a short code-drawn reveal. Before **15:00
  elapsed** a chest grants **1** upgrade; from then on **1, 3 or 5**
  (weights 85 / 12 / 3), drawn from the normal level-up pool with the usual
  card weights, listed with their old → new levels. **Every ready evolution comes first: evolutions are delivered only
  by chests.** A chest never grants the Profane Pact, and when nothing can be
  upgraded it heals (Dark Restoration). Confirm (Enter / Space / click / pad
  A) skips the reveal, then closes it.
- **Profane Pact** (in-run difficulty passive, `scripts/data/pact_data.gd`).
  Offered on level-up cards (crimson **PACT** tag, a modest 0.4× card
  weight), it takes a passive slot, has 5 levels and can be banished. Per
  level: enemies **+5% spawn rate** (trickle rate and soft cap), **+5%
  HP**, **+3% damage**; rewards **+8% XP**, **+12% Soul Ash**, **+15%
  power-up drop chance**. Sir Alaric gets only 20% of the HP bonus (42,000
  → 44,100 at Lv 5). The card lists every penalty and reward as old → new.
  Measured with an army build that takes it at once (`--policy=army --pact`,
  `--mortal`, 8 seeds): no deaths, lowest HP 26-94 (vs 92-114 without it),
  Sir Alaric killed in 5 of 8 runs (the others left him at 200-7,100 HP),
  Soul Ash about 745 instead of about 455.
- **Profane Oath** (Ossuary, standalone "Oath" entry between Refund all and
  Back; 5 tiers costing 25 / 50 / 75 / 100 / 125). Each **active** tier
  applies from the first second: enemies +6% spawn rate, +5% HP, +4%
  damage; rewards +5% XP, +10% Soul Ash, +10% drop chance. **Lower Oath**
  (with a confirmation) lowers the active tier by one, down to off, with no
  refund; owned tiers can be raised again for free. Refund all returns
  everything.
- **One difficulty path, additive.** `DifficultyModifiers` (`game.difficulty`)
  adds the Pact and Oath bonuses of each key (one stacking category) and
  hands out the multipliers: `EnemyDirector` multiplies its `hp_mult` /
  `damage_mult` and the trickle rate / soft cap (Sir Alaric's HP by 20% of
  the HP bonus),
  `Game.add_xp` the XP, `PowerupManager` the drop chance, and
  `Meta.compute_ash` pays a **Profane Pact** and a **Profane Oath** bonus
  line on the run's subtotal (shown on the end screen). The HUD's Modifiers
  area shows the Pact level, the Oath tier and their combined effect.

---

## What is implemented (vs. the GDD)

| Area | Status in this prototype |
|---|---|
| Necromancer | Movement (keyboard and stick), HP with a slow natural regeneration (0.3 HP/s), i-frames, pickup radius, hit flash. Can receive priest heals and wards. |
| **Shared summon AI** (§25–§31, §36) | **One** data-driven `SummonedUnit` script runs all four classes. It has the full FSM from §25, soft formation bands around the player (§26), and normalised target scoring (§27). Targets are held for at least 1 s; ranged units redirect when a target is already doomed (overkill reservation); priests use the §31 heal formula. |
| Leash and recall (§24) | Engagement radius 220 px, soft recall at 320 px, hard spectral recall at 650 px. |
| Replenishment (§24) | Each summon ability refills its own queue one unit at a time (Warrior 5 s, Archer 8 s, Mage 12 s, Priest 15 s). A capacity increase spawns the new units immediately. A failed spawn retries without using up the timer. |
| **Warrior blocking** | Warriors are physical blockers. Enemies can't pass through them; overlaps are resolved through the spatial hash, weighted by mass. An enemy touching a warrior is *engaged*: it moves at 60% speed and attacks that warrior. Warriors also shield-bash on a cooldown (damage plus knockback). Sir Alaric's Divine Charge loses distance for every undead body it hits, so a thick enough wall stops it. |
| **Priests** | Heal allies and the necromancer with the §31 formula; a critically hurt necromancer comes first. Whenever you are under threat (hit in the last 1.5 s, or any enemy within 90 px), a priest also casts an instant damage-absorbing **ward** on you, as long as no ward is active and its own ward cooldown is ready (even while someone is critical: the ward is instant, so it never delays or replaces a heal). It shows as a ring on the necromancer and in the HUD, and the autotest reports ward counts and wards per minute. |
| Staggered AI and performance (§25, §38) | Unit and enemy decisions run at 5 Hz spread over 12 ticks. Formation updates at 4 Hz, threat checks at 5 Hz, enemy separation at 10 Hz. A uniform-grid spatial hash handles all neighbour and target queries. Projectiles, enemies, summons, XP crystals and effects are all pooled. |
| Spells (§8) | Shadow Bolt (starting spell, homing, multi-shot, pierce; the player can switch its aim between *Nearest* and *Strongest*, i.e. highest current HP, with ties going to the nearest; extra bolts go to the next-ranked targets; shown on the HUD above the ability bar). Shadow Orb Shield (orbiting damage; intercepts a limited number of projectiles, then recharges). Shadow Blast (area damage plus slow). Plus Bone Spear, Soul Siphon, Corpse Explosion and Plague Cloud (see *The newer spells*). Each has 5 levels. |
| Passives (§34) | Grave Dominion (capacity), Necrotic Vigor (minion HP), Dark Command (minion damage and attack speed), Soul Recycling (faster replacement), plus the evolution passives Soul Conduit, Warding Ritual, Abyssal Focus, Shade Stride, Vampiric Rite, Necrotic Expanse and Lingering Malediction. Bonus stacking follows §34. |
| Evolutions & synergies (§6) | Void Barrage, Eclipse Ward, Abyssal Detonation, Ossuary Lance, Soul Rapture, Grave Eruption and Pestilence; four army synergies; weighted level-up cards with Reroll, Banish and Skip. See *Evolutions & Synergies* above. |
| Enemies (§10, §35) | Covenant Recruit, Crimson Footman (armoured), Zealous Archer (ranged), Chaplain (heals other enemies), Purifier (hunts undead, ×2 damage to summons), elite variants, and the Reckoning's *Inquisitor of the End*. Survivor convention: **every enemy always advances on the player**. Archers shoot and Chaplains heal while walking in (archers slow briefly after each shot); nobody kites or holds at range. Undead have no dodge AI and act as body blockers, so enemy arrows hit the first summon in their path. **Templar Knights** (heavy charging melee) join at 13:00. |
| Waves and stage events (§11) | The data-driven 20-minute Graveyard timeline at the GDD's real times (Sir Alaric at 17:00), then the Reckoning. It includes empowered graves, Desecration, Templar Knights and the Crypt Defender, and the arena has solid obstacles. See *Stage & Boss* above. |
| Boss (§11) | Sir Alaric with all five telegraphed attacks (Hammerfall, Divine Charge, Consecrated Ground, Call to Arms, Judgment of the Dead), plus a *Wrath* phase at 50% HP. |
| Meta-progression (§9.2, §9.4) | Soul Ash earned every run (kept on death), the Ossuary shop with the four trees (18 upgrades, prerequisites, respec) plus the opt-in Profane Oath, 3 tracked achievements, and a versioned save in `user://save.cfg`. See *Meta-progression (Soul Ash)* above. |
| Power-ups, chests, difficulty (§6.1, §8.5) | Six power-up drops with pity timer and despawn, treasure chests that deliver evolutions (the "special elite reward"), the Profane Pact passive and the Profane Oath meta upgrade. See *Power-ups & Profane Pact* above. |
| Audio, feel and settings (§12, §38) | Synthesized sound effects and music with voice limits, screen shake, hit-stop, damage numbers and particles. The settings menu has volumes, toggles, fullscreen and key rebinding, saved to `user://settings.cfg`. See *Audio, Feel & Settings* above. |
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
    game_state.gd           Autoload: CLI options (autotest), session prefs, last run summary
    settings.gd             Autoload: persistent settings (volumes, toggles, key rebinds) in user://settings.cfg
    meta_progress.gd        Autoload "Meta": Soul Ash, upgrade tiers, lifetime stats, achievements,
                            purchase / refund, run award, versioned save in user://save.cfg
    meta_modifiers.gd       The ONE path meta upgrades take into a run (game.meta, read by stat code)
    difficulty_modifiers.gd The ONE path the Profane Pact + Oath take into a run (game.difficulty)
    arena.gd                Solid obstacles (circles/rects) and the collision push-out used by all units
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
    synergy_manager.gd      Army synergy activation and effects
    summoned_unit.gd        The ONE shared FSM/steering/targeting AI for all summon classes
  enemies/
    enemy.gd                Data-driven Covenant soldier (melee / purifier / ranged / healer),
                            plus warrior-blocking resolution
    boss_alaric.gd          Sir Alaric (extends Enemy): five telegraphed attacks + Wrath phase
    stage_director.gd       Graveyard events: empowered graves, Desecration, Crypt Defender, holy ground
    enemy_director.gd       Wave timeline, events, boss, Reckoning, pooling, recycling
  abilities/
    ability_manager.gd      Spell casting, passive values, level-up card generation + deltas
    orb_shield.gd           Shadow Orb Shield
    projectile.gd, projectile_manager.gd   Pooled projectiles + overkill reservations
    spells/                 The four newer spells, behind ONE dispatch in ability_manager.gd:
      necro_spell_book.gd   Creates / ticks the spell nodes, kill hook, passive card lines, autotest line
      necro_spell.gd        Base class (shared area-damage / target helpers)
      bone_spear.gd         Bone Spear / Ossuary Lance (pooled spears)
      soul_siphon.gd        Soul Siphon / Soul Rapture (tethers, capped lifesteal)
      corpse_explosion.gd   Corpse Explosion / Grave Eruption (corpse ring buffer, spike fields)
      plague_cloud.gd       Plague Cloud / Pestilence (clouds, Rot, Death Nova)
      spell_glyphs.gd       Their icons (spells, evolutions, passives) and world visuals
  pickups/xp_crystal.gd, xp_manager.gd     Pooled XP crystals with magnet
  pickups/powerup.gd, powerup_manager.gd   Pooled power-up drops, drop rules, timed buffs, Soul Nova
  pickups/chest.gd, chest_manager.gd       Pooled treasure chests and their drop rules
  audio/sfx.gd              Autoload: audio buses, pooled voices with per-sound and global voice limits
  audio/synth.gd            Procedural sound and music synthesis (no audio files)
  fx/juice.gd               Autoload: screen shake, hit-stop, hooks for particles and damage numbers
  fx/fx_layer.gd            One node that draws all particles and damage numbers from fixed buffers
  ui/                       hud, level_up_panel, pause_menu, end_screen, main_menu,
                            debug_overlay, hud_bar, icon_glyph, ui_theme, settings_menu,
                            progression_glyphs (evolution/synergy icons),
                            ossuary_menu (Soul Ash shop), meta_glyphs (Soul Ash / tree / upgrade icons),
                            chest_panel (chest reveal), powerup_glyphs (power-up, chest, Pact / Oath icons)
  data/                     DESIGNER-TUNABLE DATA (no logic):
    unit_data.gd            Summon classes, level tables, AI weights, leash/rates
    enemy_data.gd           Enemy roster, boss, Reckoning enemy, elites
    wave_data.gd            Countdown, segments, events, Reckoning escalation
    ability_data.gd         Spell level tables
    passive_data.gd         Passive level tables
    evolution_data.gd       Evolution recipes and stats
    synergy_data.gd         Army synergy requirements and effects
    level_up_data.gd        Card weights, reroll/banish/skip counts, fallback cards
    arena_data.gd           Obstacle layout
    sound_data.gd           Sound recipes, voice limits, priorities
    player_data.gd          Player stats, XP curve, slot counts
    meta_data.gd            Soul Ash formula, upgrade trees / tiers / costs, achievements, autotest profiles
    powerup_data.gd         Power-up types, weights, durations, drop chances, pity, cap, lifetime
    chest_data.gd           Chest drop chances, pity, contents (1 / 3 / 5) weights, reveal timing
    pact_data.gd            Profane Pact levels and Profane Oath per-tier values
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
8. Power-up drops and buffs, then treasure chests.
9. Effects.

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
# (time_scale 8 with physics ticks scaled to match), plays through the 20:00
# countdown, the boss and the Reckoning (about 1220-1260 game seconds), then
# prints a summary and quits (exit code 0 = run completed). One run takes about
# 1.5-2 minutes of wall time; 15000 frames at speed 8 allow 2000 game seconds.
godot --headless --fixed-fps 60 --quit-after 15000 -- --autotest
```

Runs are deterministic for a given seed: the same seed gives the same run at
`--speed=4` and `--speed=8`, alone or under load. The simulation is CPU-bound
under `--fixed-fps`, so speed 8 takes about the same wall time as 4 and only
needs half the frames. Speed 16 produces audio errors, so don't use it. Each
run is single-threaded, so multi-seed batches run in parallel, e.g. four at a
time on four cores.

Options (after `--`):

| Option | Effect |
|---|---|
| `--autotest` | Run the automated playthrough. |
| `--mortal` | The player can die before 0:00 (a balance check). By default the autotest player cannot die until 20 s into the Reckoning, so the whole timeline gets exercised. |
| `--speed=N` | Time scale (default 8; results are identical at 4 and 8). |
| `--seed=N` | RNG seed (default 1337). |
| `--timeout=N` | Give up after N game seconds (default 1500: the 20:00 countdown plus the Reckoning). |
| `--policy=NAME` | Level-up card policy: `naive` (default; takes every new summon class, then new spells, then new passives), `army` (a summoner build that levels summons and army passives first), `evolve` (a spell build that chases the three evolutions) or `pact` (the naive build that takes every Profane Pact card at once, to measure the Pact). Every other policy ranks the Pact below every card, fallbacks included, so balance runs never take it. |
| `--meta=PROFILE` | Simulated Soul Ash purchases, applied in memory only: `none` (default, so balance runs stay comparable), `mid` (about half of every tree) or `max` (everything). |
| `--meta-save` | Test flag: lets the autotest read and write `user://save.cfg` (by default it never touches it). |
| `--oath=N` | Active Profane Oath tier 0-5 (default 0). No `--meta` profile includes the Oath, so `--meta=max` balance runs stay comparable. |
| `--pact` | Any policy also takes every Profane Pact card at once (`--policy=army --pact` is a strong build with the Pact; it gives up Warding Ritual for the Pact's slot, not the Void Barrage passive). |
| `--spells=a,b,...` | Any policy first takes these spells (ids from `AbilityData.SPELL_ORDER`, e.g. `bone_spear,soul_siphon,corpse_explosion,plague_cloud`) and their evolution passives, which also get ×8 card weight in hands and chests so they are offered reliably (a test-only hook; without `--spells` the draw is unchanged), never banishes them, and stops taking other new actives (or passives) once the free slots are down to the forced spells (or passives) still missing plus one spare, because chests can fill slots too (a hand with nothing else is rerolled or skipped). The `army` and `evolve` bots never take a new item that is not on their build list (they reroll or skip), so the newer spells do not change those baselines. Use it to exercise a spell and reach its evolution. |

Setting the environment variable `GRAVEBOUND_AUTOTEST=1` is the same as `--autotest`.

The summary covers: result, time, kills, level, army per class, boss
spawn/kill, all cards picked, and per-source damage (`dmg_warrior`, `dmg_bolt`,
`dmg_bash`, …). It also reports damage taken by summons, split by attacker
(`summon_dmg_from_*`) and damage taken by the player, split by attacker
(`player_dmg_from_*`); damage to the boss by source (`bossdmg_*`); Shadow Bolt
damage per aim mode (the autotest uses Nearest, then switches to Strongest when
the boss spawns); a **necro spells** line (for each newer spell: level, total
damage and the evolved part, boss damage, and counters such as volleys,
lifesteal healed, corpse bursts and chains, clouds, Death Novas and the Rot
bonus damage); heals, wards and orb intercepts; peak entity counts;
pool node counts; and the average and worst simulation-step cost. These numbers
are the starting point for tuning. Every 60 s it also prints `[metric]` lines
(army size and capacity per class, level, damage taken by attacker, enemies
alive by kind, XP collected so far as `xp=`), and at the end `boss_hp_at_0`
and `min_hp_before_0` (the lowest player HP before 0:00). Multi-seed tuning
scripts parse these lines. The summary also has a **level pacing** line (the
level at 1:00, 3:00, 5:00, 10:00, 15:00, 17:00 and 20:00, and when levels 2,
5, 10, ... 60 were reached) and **build complete** (the first level-up whose
hand held only fallback cards: every slot maxed and every available evolution
taken). The last lines
list the active meta upgrades and the run's Soul Ash award with its breakdown
(time, kills, elites, boss, Reckoning, Ash Harvest bonus, Pact and Oath
bonuses, achievement bounty). Before them come the **power-up** lines (drops
spawned / collected / expired per type, lost at the cap, pity drops, buff
uptime, Soul Nova kills), the **chest** lines (spawned, opened by size,
items granted, every chest's contents with its time) and the **Profane
Pact** line (taken or not, the time of each level, the Oath tier, and the
extra XP and Soul Ash from the Pact and the Oath). The autopilot walks to a
chest within 450 px unless enemies press it hard, and to a power-up within
300 px when nothing presses it.

### Continuous integration and builds

`.github/workflows/ci.yml` runs on every push and pull request:

1. **test:** imports the project with Godot 4.3 headless and runs the full 20-minute autotest with the naive and
   army policies (`--quit-after 15000`, at most 10 wall-clock minutes per run, 20 minutes for the job).
   It fails on any `SCRIPT ERROR`, `ERROR:` or `WARNING:` line, or if a run doesn't complete.
2. **export:** builds single-file Windows and Linux executables using `export_presets.cfg` (game data is embedded in
   the executable), runs the autotest again on the exported Linux build, and uploads both as workflow artifacts.

To publish a downloadable release, push a version tag. The export job then creates a GitHub Release with both zips
attached:

```bash
git tag v0.2.0 && git push origin v0.2.0
```

To export locally, install the 4.3 export templates (**Editor → Manage Export Templates**), then use
**Project → Export**, or run `godot --headless --export-release "Windows Desktop" build/windows/Gravebound.exe`.

---

## Known limitations

- **Balance is checked only against the autotest bots** (`--mortal`; after the
  power-up / chest merge: 16 seeds for naive / army at meta none, 8 for evolve
  at none, army / naive at max and the Pact build). At **meta none** the
  summoner build (`--policy=army`) never dies before 0:00 (lowest HP 92/120),
  always kills Sir Alaric (in 96-140 s), completes its build at about 16:07
  (15:44-16:26; chests included), evolves Void Barrage at 12:29-14:38 and lasts
  6-17 s into the Reckoning. The naive build dies before 0:00 in about 40% of
  runs (mostly at 8-13 min) and kills him in about 45%. The spell build
  (`--policy=evolve`) evolves at 8:00-8:13 (the time gate), never died and
  always killed him. At **meta max** nothing dies before 0:00, builds complete
  at about 15:20-15:30, every bot kills him, and the Reckoning still ends
  every run, 25-53 s past 0:00. Void Barrage is still
  the strongest single source: about 30-45% of all damage in army / naive
  builds, about 60-70% in the spell build. A first-time naive player kills
  Alaric only about 1 run in 4.
- The four newer spells (Bone Spear, Soul Siphon, Corpse Explosion, Plague
  Cloud) and their evolutions have first-pass numbers, checked only against
  single bot runs (`--spells=...`) and a 4-seed naive / army comparison.
  The army and evolve bots never pick them on purpose, and a combined
  balance pass is still due. Plague Cloud and Grave Eruption were the
  strongest and were cut; Grave Eruption is still the strongest of the four
  evolutions (about 400 dmg/s, close to Void Barrage in a spell rush).
  Bone Spear needed an aim assist: pure movement aim missed almost
  everything while kiting.
- Only the Graveyard stage (a 20-minute run, the GDD's lower bound).
- Arrows and spells fly over obstacles (no line-of-sight checks).
- Eclipse Ward usually arrives late (15:00-19:00) and only in builds that
  take Orb Shield. No evolution is granted before 8:00 elapsed.
- No ultimate, dash, mid-run saves, skins or GDD difficulty levels yet; the
  only modifiers are the opt-in Profane Pact and Profane Oath. The Soul Ash
  numbers are first-pass and the achievement unlocks only pay Soul Ash until
  their GDD rewards exist.
- Power-up, chest and Pact / Oath numbers are tuned only against the bots.
  The Profane Oath at tier V is a true hard mode: the army bot never dies
  but kills Sir Alaric in only about 1 run in 4 (8 seeds).
- Menu hint text still shows the default keys (Esc, T) after you rebind them.
- Nobody has played it on real hardware yet. Audio, visuals and performance
  have only been verified headless (simulation step about 0.9–1.3 ms on
  average over a 20-minute run, with up to 180 enemies and ~45 summons). Rendering cost has not been profiled.

## Next steps (grouped by GDD §19 phases)

**Phase 1 – Prototype (mostly done):** tune the TUNING values using the
autotest stats; give the horde a feel pass (formation spacing, kite timing,
warrior wall shape) with a human player.

**Phase 2 – Graveyard vertical slice (mostly done):** playtest with humans;
retune Void Barrage and the boss; the remaining passives (Bone Plating, Unholy
Precision, Forbidden Knowledge, Dark Benediction, Unholy Resilience, Bound
Souls); the Banner Bearer; saves; density and minion-HP-bar settings (§38).

**Phase 3 – Campaign:** Crimson March and Sanctum stages, Marshal Vael and
Grand Inquisitor Seraphine, remaining enemies, Soul Ash balance against the
full-length stage, the real achievement unlocks, difficulties and modifiers,
skins.

**Phase 4 – Polish:** real art and animation, audio, accessibility, full
controller UX, profiling on target hardware (§40 stress scenarios), balance.
