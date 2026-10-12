# Gravebound — Godot 4.3 prototype

**Gravebound** is a dark-fantasy bullet-heaven / horde-survival roguelite in the
vein of *Vampire Survivors*, with one twist: **the army is your weapon**. You play
a necromancer hunted by the Crimson Covenant, a fanatical holy order. You only
move. Your shadow spells fire automatically, and an **autonomous undead horde**
of Skeleton Warriors, Skeletal Archers, Undead Mages and the two priest orders,
Grave Menders and Crypt Warders (plus Corpse Abominations, Grave Rogues, Crypt
Gargoyles and Frost Wraiths), follows, fights, heals, shields, holds the line
and regroups without any commands from you. Late in a run your summons can
evolve into Death Knights, Liches, Profane Bishops, Shadow Reapers and
Cathedral Horrors.

This repository has a playable **prototype** of the three campaign stages,
*The Desecrated Graveyard*, *The Crimson March* (unlocked by slaying Sir
Alaric) and *The Sanctum of Judgment* (unlocked by slaying Marshal Vael),
built in Godot 4.3. Every visual is drawn in code, and there are no external
assets or addons.

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
3. Press **F5** (or the ▶ Play button). Choose **Play** on the main menu, then
   a stage.

The project uses the GL Compatibility renderer, so it runs on almost any GPU.

### Controls

| Action | Keyboard / mouse | Controller |
|---|---|---|
| Move | WASD or arrow keys | Left stick / D-pad |
| Menu / card navigation and confirm | Mouse, arrow keys, Enter / Space | D-pad or left stick, **A** |
| Stage select (after **Play**) | Left / right between stages, Enter marches, Esc goes back | D-pad / stick, **A**, **B** |
| Pick a level-up card | Click, or keys **1 / 2 / 3** | Focus + **A** |
| Level-up: Reroll all cards (2 per run) | **R**, or the Reroll button | **X**, or focus the button + **A** |
| Level-up: Banish a card (2 per run) | **B**, then pick the card (**B** / **Esc** cancels) | **LB**, then pick the card (**LB** / **B** cancels) |
| Level-up: Skip (unlimited, heals 8% HP) | **N**, or the Skip button | **RB**, or focus the button + **A** |
| Shadow Bolt aim: Nearest / Strongest | **T** | **Y** |
| Grave Step (dash) | **Shift** | **RB** |
| Dread Rally (ultimate, when its soul meter is full) | **Space** | **LB** |
| Army stance: Escort / Onslaught / Spearhead / Bone Ring | **1 / 2 / 3 / 4** (rebindable) | **Right-stick flick** up / right / down / left |
| Pause (Resume / Recipes / Settings / Restart / Main Menu) | **Esc** (Esc again resumes) | **Start** (**B** or Start resumes) |
| Recipes (evolutions you have discovered) | **Recipes** in the pause menu; arrows move through the list, Esc / Back closes | Focus + **A**; D-pad / stick move; **B** closes |
| Debug overlay (FPS, counts, unit FSM states) | **F3** | — |
| Ossuary (Soul Ash upgrades) | **The Ossuary** in the main menu; arrows move, Enter buys; Esc closes | D-pad / stick move, **A** buys, **B** closes |
| Settings (volume, shake, damage numbers, fullscreen, keys) | **Settings** in the main or pause menu; Esc / Back closes | Focus + **A**; **B** closes |
| Rebind a key (in Settings) | Select a binding, then press the new key | **B** cancels |

You don't aim or cast anything yourself. Spells, summons, targeting, healing and
replacing fallen units all happen automatically (GDD §4, §21). The only two
buttons you press in a fight are the dash and the ultimate (below).

### Grave Step and Dread Rally (dash and ultimate)

- **Grave Step** (Shift / RB) is a 110 px shadow step over 0.15 s in the
  direction you move (or the way you last moved when standing still), with
  0.2 s of invulnerability. It passes through enemies but not obstacles: the
  step stops short of a gravestone or wall and always ends on free ground. It
  has a 5 s cooldown and is available from the first run; the Ossuary sells a
  second charge (**Twin Shadow**) and a shorter cooldown (**Restless Shade**,
  5 → 3.5 s). The army follows as it does when you walk. A violet shadow
  trail marks the step.
- **Dread Rally** (Space / LB) has no cooldown: its **soul meter fills from
  kills** (1 point per kill, 8 per elite or Crimson March structure, 60 for
  the stage boss; 240 to fill, about 60-90 s of mid-game fighting). It stays
  full until you use it, and kills made during a rally do not charge it.
  Casting it calls the army: every summon outside its formation band
  returns to you and the whole army moves +120% faster for 1.5 s, every
  summon heals 30% of its max HP, and for 8 s the army deals **+40% damage**
  with **+40% attack speed**. Enemies within 120 px are knocked back (heavier
  ones less, bosses barely).
- Both live in the HUD's bottom centre, either side of the ability bar: the
  Grave Step icon with one pip per charge (it darkens and counts down while
  no charge is ready) and the Dread Rally icon with its meter (a pulsing
  border and READY when full, the buff time while it runs). The key names
  follow your rebinds. Everything runs on game time, so pauses, level-ups and
  chests freeze the cooldown, the meter and the buff, and the Space / A that
  confirms a card or closes a chest never casts the rally.

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
  for Move up / down / left / right, Shadow Bolt aim, Grave Step, Dread Rally,
  Pause and the four army stances. Arrow keys and
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

### Army stances

You don't control units one by one, but you choose how the whole army fights.
A stance only changes numbers the horde AI already uses (where each unit's
formation post is, how far units chase, how hard they pull back to their
post); every unit keeps its own AI. The hard recall (650 px, the teleport
back) never changes.

| Key | Stance | Shape | Chase distance |
|---|---|---|---|
| **1** | **Escort** (default) | The usual formation: blockers on an arc facing the threat, the rest in their bands around you | 220 px |
| **2** | **Onslaught** | Loose: fighters surge at the nearest enemy groups, priests trail between you and the fight. Exposes you | 440 px (formation pull cut to a third) |
| **3** | **Spearhead** | A wedge pointed where you move (or last moved): blockers at the tip, Rogues on the flanks, ranged and priests close around you. The rear is open | 150 px |
| **4** | **Bone Ring** | A closed circle 60-90 px out with the blockers spaced evenly, ranged and priests inside. Safest, fewest kills | 110 px |

- **Escort, Onslaught and Bone Ring** are available from the first run.
  **Spearhead** is bought in the Ossuary (*Spearhead Doctrine*, Necromancy,
  200 Soul Ash). Before that, its key only shows "Locked: unlock Spearhead in
  the Ossuary" (once per run).
- Keys **1-4** (rebindable in Settings) or a **right-stick flick** (up /
  right / down / left; release the stick before the next flick). After a
  change, the next one is possible after **1.5 s** of game time. Stance keys
  do nothing while a menu or the level-up panel is open.
- The **stance bar** beside the army list shows the four stances with their
  keys: the active one lit (a thin bar shows the switch lockout), the others
  dimmed, a locked one dark with a padlock. A change shows a one-word banner
  under the necromancer, plays a command horn and draws a faint outline of the
  new shape on the ground for 1 s. The pause menu lists what each stance does.
- The stance resets to **Escort** at the start of every run (and on Restart).
- No stance gives a stat bonus yet. Flavour bonuses (Onslaught +10% army
  attack speed, Spearhead +30% push on the tip, Bone Ring -10% army damage
  taken) exist in `scripts/data/stance_data.gd` but are switched off
  (`BONUSES_ENABLED`).

### Summon classes

All classes run the same shared AI (formation band, target scoring, leash and
recall, replacement queue). The GDD's single Undead Priest is **split into two
classes**, the Grave Mender and the Crypt Warder (user request; they can later
merge into the Profane Bishop, see *Evolutions & Synergies*). The four later
classes add one special action each (`scripts/horde/behaviors/`). Every class
number is in `scripts/data/unit_data.gd`.

| Class | Population (Lv 1 → 5) | Replaced every | Role | Special |
|---|---|---|---|---|
| Skeleton Warrior | 2 → 8 | 5 s | Frontline blocker | Physically blocks enemies (they move at 60%); shield bash. Evolves into the **Death Knight** |
| Skeletal Archer | 1 → 5 | 8 s | Ranged DPS | Holds its ground and fires; pierce at Lv 4. Evolves into the **Gravebow** |
| Undead Mage | 1 → 3 | 12 s | AoE caster | Explosions on the best cluster. Evolves into the **Lich** |
| Grave Mender | 1 → 2 | 15 s | Healer | Heals allies and you (the old priest heal, §31) |
| Crypt Warder | 1 → 2 | 15 s | Warder | Wards you when you are threatened; instant barriers on threatened allies |
| Profane Bishop | 3 (merge only) | 12 s | Support | Never offered on a card: created when Menders and Warders merge. Heals, wards, barriers and a heal / burn aura |
| **Corpse Abomination** | 1 → 3 | 20 s | Tank | A wider, heavier blocker (enemies touching it move at 45%). **Stomp**: a telegraphed bone-green ring, then damage and knockback to everything around it, with a shockwave and screen shake. Evolves into the **Bone Colossus** |
| **Grave Rogue** | 1 → 4 | 9 s | Assassin | Hunts Chaplains, archers and the back of the crowd. **Dash Strike**: a telegraphed violet lane, then a dash through it that hits every enemy in the lane and makes them bleed; it never ends inside an obstacle and runs back to formation |
| **Crypt Gargoyle** | 1 → 3 | 12 s | Skirmisher | Claws. **Swoop**: takes off (airborne: flies over obstacles and bodies, can't be hit, drawn above its shadow), dives onto a cluster for AoE damage, lands on a free spot |
| **Frost Wraith** | 1 → 3 | 14 s | Ice caster | Frost bolts **chill** (slow, frost film). **Deep Freeze**: a telegraphed circle, then every enemy inside is frozen (Stasis rules: Sir Alaric only briefly, Reckoning enemies immune) |

- **Global capacity bonuses** (Grave Dominion, Legion of Bone) give every GDD
  class the full bonus, and the Mender and Warder each count as a class; the
  merged Bishop gets it once. Low-population later classes take only part of
  it (Abomination 40%, Frost Wraith 50%, Rogue and Gargoyle 60%, rounded
  down).
- **Synergies and achievements**: The Unholy Host and Dread Sovereign need the
  GDD's four roles (Warriors, Archers, Mages and either priest order, or the
  Bishop); the later classes are never required. March of the Deathless
  counts any 3 classes.
- **Evolutions only touch their own classes**: Death Knight (Warriors), Lich
  (Mages), Profane Bishop (Menders + Warders), Gravebow (Archers), Bone
  Colossus (Abominations), Shadow Reaper (Rogues), Cathedral Horror
  (Gargoyles) and Winter Revenant (Frost Wraiths). Forbidden Knowledge and
  Dark Benediction boost only Mages and the support classes. (The
  Gravebow's curse is the one exception that helps everyone: a cursed foe
  takes more damage from every undead source.)
- **Interactions**: an enemy touching several blockers (Warriors, Death
  Knights, Abominations) gets the strongest slow, never a product of them.
  Shieldwall barriers stay on Warriors (and Death Knights); Warder and Bishop
  ally barriers can land on any threatened ally, Abominations included. A
  Gargoyle in flight is out of reach of enemies and allies alike: it can't be
  hit, healed or given a barrier until it lands.

### Evolutions & Synergies

- **Evolutions** (GDD §6.1): once a spell reaches **Lv 5**, its paired
  passive is **also at Lv 5** (owner rule: every evolution, spell or summon,
  needs its paired passive maxed) **and the run has reached 8:00 elapsed** (12:00
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

- **Summon evolutions** (user request; GDD §4.2 / §6.1 name one per class).
  They use the spell evolutions' delivery: once the recipe holds **and** the
  run has reached 8:00 elapsed, the next treasure chest grants it first (the
  40 s evolution pity applies too). An evolved class keeps its slot, level and
  capacity; its existing units **transform in place** (a light column and
  rings, full heal) and its card, HUD row, slot icon and name change.

| Summon class | + Requirement | = Evolution |
|---|---|---|
| Skeleton Warrior Lv 5 | Dark Command **Lv 5** | **Death Knight**: bigger armoured silhouette, ×1.5 HP, ×1.35 damage; each swing **cleaves** 50% to foes within 32 px; **life drain** 12% of melee damage; a heavier wall (block mass 5, bash ×2 every 1.5 s, foes in contact slowed to 45%) |
| Undead Mage Lv 5 | Forbidden Knowledge **Lv 5** (+8–40% mage damage, +5–25% splash) | **Lich**: floating crowned wisp, ×1.4 HP, ×1.2 damage; **raise the dead**: every 5th foe a Lich kills rises as a skeleton for 12 s (max 6 at once) |
| Grave Rogue Lv 5 | Bound Souls **Lv 5** | **Shadow Reaper**: hooded scythe assassin, ×1.35 HP, ×1.25 damage; **Dash Strike cooldown halved**; each dash **chains** to the nearest enemy it has not struck yet (same lane rules: a clear lane that reaches it, an end inside the leash, never inside an obstacle; 0.1 s lane flash); **bleeds stack** up to 3 per Reaper on one enemy (each stack ticks on its own; at the cap the oldest stack is refreshed); a **kill during a dash resets** the cooldown to 0.9 s (at most once per chain) |
| Crypt Gargoyle Lv 5 | Unholy Resilience **Lv 5** | **Cathedral Horror**: huge cracked-marble gargoyle, ×1.4 HP, ×1.25 damage; **swoop radius +30%**; the dive **stuns** every enemy it hits for 0.6 s (the Deep Freeze hold: the boss 25%, elites 60%, Reckoning enemies and structures immune; stars over the enemy); after landing it **turns to stone** for 2 s: it stands still and does not attack, **takes no damage** and still body-blocks (a recall ends it at once) |
| Grave Mender Lv 5 **and** Crypt Warder Lv 5 | Dark Benediction **Lv 5** (+8–40% heals, wards and barriers) | **Profane Bishop** (a **merge**): both orders become one class that heals, wards you **and** shields allies, plus an aura every 3 s that heals everything near it and burns foes. Capacity becomes 3 + your global capacity bonuses (counted once, not twice); existing Menders and Warders convert in place up to that cap, the rest dissolve into them, and **one active slot is freed** |
| Frost Wraith Lv 5 | Soul Recycling **Lv 5** (faster replacement) | **Winter Revenant**: a taller crowned ice wraith, ×1.25 HP, ×1.25 damage, Deep Freeze radius **+35%**; **shatter**: a foe that dies while Deep-Frozen bursts for 22% of its max HP to foes within 56 px and chills them (bosses and structures never shatter; a shatter never sets off another shatter, and at most 12 resolve per tick); **death nova**: a Revenant that falls deals 3× its frost-bolt damage within 84 px and freezes the survivors for 1.2 s (boss / elite multipliers apply), and Soul Recycling brings it back quickly |
| Skeletal Archer Lv 5 | Unholy Precision **Lv 5** (minion crits 5–25%) | **Gravebow** (GDD "Gravebow Company"): a tall hooded archer with a huge bone longbow, ×1.4 HP, ×1.25 damage; arrows **pierce 2** foes; every **4th volley splits** into a fan of 3 arrows; every hit **curses** the foe for 4 s: it takes **+15% damage from every undead source** (all summons and your spells; only the Soul Nova is exempt), shown as a violet film and rune. Still holds its ground |
| Corpse Abomination Lv 5 | Bone Plating **Lv 5** (flat damage off every hit on a minion) | **Bone Colossus**: armoured in fused bone, ×1.6 HP, a bigger body (19 px) and blocking ring (23 px, mass 11), **Stomp radius +40%**; **taunt**: foes within 110 px pick it as their target before you or any other summon (target choice only: they still advance; bosses, Reckoning enemies and structures ignore it); when it falls it bursts into **bone shrapnel** (2× its stomp damage to foes within 90 px, with knockback) |

  The numbers live in `scripts/data/summon_evolution_data.gd`; the runtime is
  `HordeDirector.evolutions` (`scripts/horde/summon_evolutions.gd`). Summon
  cards and the paired passives' cards show the path ("Evolves into Death
  Knights at Lv 5 with Dark Command Lv 5 ...") and "Evolution ready" once it
  holds. Stage-event temporary summons (graves, crypt) always keep the base kit.
- **Recipe book** (owner decision: evolutions are meant to be *discovered*).
  The pause menu's **Recipes** view lists every evolution recipe, but shows
  only the ones you have **obtained in some run**: the evolution's icon and
  name, its kind, and the recipe ("Shadow Bolt Lv 5 + Soul Conduit Lv 5 ->
  Void Barrage"; both priest orders for the Profane Bishop). Every other
  recipe is a locked dark "?" tile with no names or ingredients, and a
  count ("3 / 10 discovered") shows how many exist. There are no other new
  hints (no card lines, no HUD signal). Discoveries are saved at once in
  the save file's `[recipes]` section. The list is built from
  `EvolutionData` + `SummonEvolutionData` (`scripts/core/evolution_recipes.gd`),
  so new recipes appear automatically; texts in `recipe_book_data.gd`.
- **Later horde passives** (GDD §34 names; effects are the prototype's,
  GDD §15.0). Like every army passive they are a dead card while you own no
  summon class; their NEW cards share one weight
  (`NEW_PASSIVE_POOL_WEIGHT` = 2). Each card already names the summon
  evolution it will unlock (those evolutions are not built yet), and Soul
  Recycling's card names the Frost Wraith's:

| Passive | Effect (Lv 1 → 5) | Will evolve (with the class at Lv 5) |
|---|---|---|
| Bone Plating | Minions ignore 2 → 6 damage of every hit (after the other reductions, before barriers; a hit keeps at least 25%; holy-ground ticks are exempt) | Abominations → **Bone Colossi** |
| Unholy Precision | Minion attacks and specials crit 5% → 25% of the time for double damage (not the Rogue's bleed ticks, not your spells) | Archers → **Gravebows** |
| Unholy Resilience | Minions take 8% → 35% less **area and holy** damage: Hammerfall, Vael's cleave, Halberdier sweeps, Judgment, Purifier fire, holy ground (consecration, ward generators, boss and Inquisitor zones), Holy Retribution bolts, the Sanctum's Sentinel sweeps, Guardian slams and beams and Radiant Inquisitor bolts | Gargoyles → **Cathedral Horrors** |
| Bound Souls | Minion move speed +6% → +30%; leash (engagement radius and soft recall) +10% → +50%; the return trip after a recall takes 10% → 50% less time | Rogues → **Shadow Reapers** |
| Soul Recycling (existing) | Faster replacement | Frost Wraiths → **Winter Revenants** |

  Their hooks are on the single paths: `CombatResolver` (crits, Resilience,
  Plating; the crit rolls use their own seeded RNG, so runs stay
  deterministic) and `HordeDirector.compute_stats()` (Bound Souls). Source
  lists and numbers are in `passive_data.gd`; card lines in
  `scripts/horde/minion_passives.gd`.
- **Army synergies** (GDD §6.3) turn on automatically while every required
  summon class is at **Lv 2+**. A banner announces each one, and the active
  ones are listed above the army panel:
  **Shieldwall of the Damned** (Warriors + Warders: warriors get barriers),
  **Volley of the Fallen** (Archers + Mages: mage hits mark foes, archers deal
  +35% to marked foes), **March of the Deathless** (any 3 classes: +15% move
  speed and regeneration), **The Unholy Host** (Warriors, Archers, Mages and
  either priest order: +15% attack speed, −15% damage taken, aura on every
  summon). The Profane Bishop counts as both priest orders, so merging keeps
  both synergies.
- **Level-up cards** are weighted: upgrades to items you own (2.5), and items
  on an evolution path, come up more often. New cards: Orb Shield and Shadow
  Blast weigh 1 each and the four newer spells share one weight
  (`NEW_SPELL_POOL_WEIGHT` = 2, split between the ones you don't own); the
  GDD summon roles weigh 1.5 (`WEIGHT_NEW_CORE_SUMMON`: Archer, Mage, and the
  one Priest role whose two orders, Mender and Warder, get 0.75 each); the
  four later classes share one weight (`NEW_SUMMON_POOL_WEIGHT` = 1.5; the
  Bishop is never offered and merged classes don't count); the four later
  horde passives share `NEW_PASSIVE_POOL_WEIGHT` = 2 the same way. So the larger
  roster doesn't crowd passives, upgrades and the core classes out of the
  hands (Shadow Bolt is always yours); once your 6
  active slots are full, no new summon or spell is offered at all. A hand is never made only of useless
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
| **Corpse Explosion** | Every enemy that dies (to your horde, spells or anything) leaves a corpse for 8 s. The spell detonates the corpses near you with the most foes around them. | 22 dmg, 1 corpse, radius 50, every 2.4 s → 34 dmg, 3 corpses, radius 70, every 2.0 s |
| **Plague Cloud** | A lingering cloud settles on the most packed foes (avoiding spots already covered), ticks damage every 0.5 s and inflicts **Rot**: for 1.5 s the foe takes extra damage from **every** source (bosses get half). | 2 dmg/tick, radius 55, 3 s, every 3.8 s, Rot +8% → 3 dmg/tick, radius 70, 4.5 s, every 3.4 s, Rot +18% |

Rot is a field on the enemy (`rot_until`, `rot_amp`) that
`CombatResolver.damage_enemy` applies to every hit; the extra damage is the
`rot_bonus_dmg` stat. Shade Stride and Vampiric Rite are read by the
necromancer's movement and regeneration; Necrotic Expanse and Lingering
Malediction are two more categories in `AbilityManager.apply_spell_mods()`
(radius keys; `AbilityData.DURATION_KEYS`, which include Shadow Blast's slow).

With the summon roster: Rot amplifies **every** hit that goes through
`CombatResolver.damage_enemy`, so summon attacks and specials (Frost Wraith
bolts, Lich blasts, Rogue dashes and bleeds, Abomination stomps, Gargoyle
swoops, the Bishop aura, Death Knight cleaves) all deal the Rot bonus.
Corpse Explosion gets a corpse from every kill, whoever made it (a Lich kill
leaves a corpse *and* may raise a skeleton). Soul Rapture's spare lifesteal
mends the summon with the biggest wound **not covered by its barrier**
(Shieldwall or a Warder / Bishop barrier counts as HP) and skips flying
Gargoyles and summons still rising.

### Stages

**Play** opens the stage select: one card per stage with its chapter, name,
a short description and a small emblem, plus either its lock requirement or
your best time, boss kills and Soul Ash bonus there. Every stage runs the same
structure (a 20:00 countdown, its boss with 3:00 left, the Reckoning at 0:00).

| Stage | Unlock | Boss | Soul Ash |
|---|---|---|---|
| Chapter I, **The Desecrated Graveyard** | always open | Sir Alaric, the Gravebreaker | ×1.0 |
| Chapter II, **The Crimson March** | slay Sir Alaric once (GDD §9.3) | Marshal Vael, the Crimson Bulwark | ×1.25 |
| Chapter III, **The Sanctum of Judgment** | slay Marshal Vael once (GDD §9.3) | Grand Inquisitor Seraphine, Voice of the Dawn | ×1.5 |

### Difficulty & run modifiers

Choosing a stage opens the **pre-run setup** screen (GDD §10.2): pick one of
the four GDD §8.4 **difficulty levels** and toggle any of the eight §8.5
**run modifiers**. Every card lists its exact effect and Soul Ash reward, and
the screen shows the **total Soul Ash multiplier** of the stack and the
combined enemy multipliers (plus a note when a Profane Oath tier is active).
It works with keyboard, mouse and controller (arrows / D-pad move, Enter / A
selects or toggles, Esc / B goes back to the stage select). Your last choice
is remembered (saved in `user://save.cfg`), **Restart** keeps it, and
**Standard** resets to Necromancer with no modifiers. All four levels are open
from the start. The HUD's Modifiers area (top right) and the end screen show
the difficulty and the active modifiers.

| Difficulty (`difficulty_data.gd`) | Foes | Soul Ash |
|---|---|---|
| **Initiate** ("easier scaling") | HP ×0.9 and damage ×0.8, and both grow 25% slower over time (×0.70 HP and ×0.66 damage by 0:00); boss HP ×0.8 | ×0.8 |
| **Necromancer** (standard) | today's game, every value ×1 | ×1 |
| **Lich** ("increased HP / aggression") | HP and damage ×1.05, growing faster over time (×1.28 HP and ×1.20 damage by 0:00); move speed ×1.05; boss HP ×1.15 | ×1.25 |
| **Deathlord** ("hardest, with more elites") | HP and damage ×1.05, growing 40% faster (×1.42 HP and ×1.35 damage by 0:00); move speed ×1.06; 0.8% of trickle soldiers are promoted to elites (elite HP and size, but plain XP and no elite chest or power-up chance); boss HP ×1.3 | ×1.5 |

The levels mostly bite later in the run: an army that falls behind in the
first minutes never recovers, so a harsh opening would make Deathlord a coin
flip instead of a hard mode. Spawn rate and XP stay ×1 on every level (the
data has both keys): more soldiers, or elites with elite XP, meant more XP
and builds complete a minute early, which made the hard levels easier.

| Run modifier (`run_modifier_data.gd`) | Effect | Soul Ash |
|---|---|---|
| **Endless Crusade** | +30% enemy spawn rate and soft cap (GDD) | +20% |
| **Hardened Faith** | +25% enemy HP (GDD; the boss gets a fifth of it) | +20% |
| **Divine Fury** | +20% enemy damage (GDD) | +20% |
| **Purge the Unholy** | ×2.5 Purifiers in every wave segment, and they join from 3:00 | +15% |
| **Scarcity** | Grave Feast drops are 60% rarer and heal half as much | +10% |
| **Frail Master** | the necromancer starts with 30% less max HP | +15% |
| **Vengeful Dead** | summons deal +20% damage but have −30% HP | +10% |
| **Holy Retribution** | a slain elite bursts into 8 radiant bolts (orbs can intercept them) | +15% |

**How it all combines** (`DifficultyModifiers`, the one difficulty path):
the difficulty level is its own multiplier; the run modifiers, the Profane
Pact and the Profane Oath are one opt-in category whose bonuses **add**. So
enemy HP = time scaling × stage × level HP × (1 + Pact + Oath + modifiers),
and the same for damage and spawns. Soul Ash: every source pays its own line
on the run subtotal, and the lines add: Ash Harvest, Pact, Oath, the stage
bonus, **Difficulty** (−20% on Initiate up to +50% on Deathlord) and **Run
modifiers** (the sum of the active modifiers' rewards, +125% with all eight).
The setup screen's total is level ×ash + modifier rewards (Deathlord with
every modifier: ×2.75).

### Stage 1: The Desecrated Graveyard (Stage & Boss)

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

### Stage 2: The Crimson March

The army marches on the Covenant's headquarters (GDD §8.2). The clock stays
in charge: the march passes through **four battle zones** on fixed times, and
at each change a banner names the zone, a fog of war sweeps the field and the
terrain around you is rebuilt as the next zone (an old road always stays
open). The zone is shown under the timer.

| Zone (from) | Ground and obstacles | Timeline beats (GDD §8.2) |
|---|---|---|
| I, the Burned Road (0:00) | ash, burned houses, charred trees, cart wrecks | patrols; a supply cart at 2:30 |
| II, the Fortified Checkpoint (4:00) | forest, barricades, stakes | a watchtower and a shield line at 4:00; Templar ambush (an arc of three) at 6:00; a cart at 6:40 |
| III, the Siege Camp (9:00) | tents, crates, siege engines | two siege outposts at 9:00; Banner Bearers; a cart at 10:30; heavy infantry at 12:00; a cart at 13:20 |
| IV, the Fortress Approach (15:00) | cobbles, fortress walls, tower bases, rubble | two Holy Ward Generators at 15:00; cathedral defenders at 16:00; fortress assault at 16:30; **Marshal Vael at 17:00** |

- **Objectives.** *Outposts* (a watchtower, two siege outposts) send a melee
  squad every 12-14 s while you are nearby, until destroyed (like the normal
  spawning, they hold back while the field is at its density cap); they pay
  an XP burst.
  *Holy Ward Generators* each keep a
  holy zone up (it burns and slows undead, stings you and blocks summon
  replacement) until destroyed; each drops XP and a chest. *Supply carts* roll
  past you with an escort and escape after 30 s; destroying one drops XP and a
  power-up. *The battlefield dead* (heaps of fallen soldiers) work like the
  Graveyard's empowered graves.
- **New Covenant soldiers** (each with its own silhouette):
  - **Covenant Shieldbearer** (tall tower shield): takes 60% less damage from
    projectiles (Shadow Bolt, Void Barrage, Bone Spear / Ossuary Lance,
    arrows, mage and Lich blasts, Frost Wraith bolts, the support classes'
    bolts). Melee summons, bashes, Shadow Blast, orbs, Corpse Explosion,
    Plague Cloud and Soul Siphon hit it normally.
  - **Banner Bearer** (tall swallow-tailed banner): buffs Covenant soldiers
    within 110 px (+15% damage and speed, −10% damage taken; buffed soldiers
    show a gold chevron). Your summons prioritise it.
  - **Crimson Halberdier** (long halberd): slow and armoured; a hit on a
    summon also cleaves two neighbours.
- **Marshal Vael, the Crimson Bulwark** (35,200 HP with the stage bonus):
  - **Radiant Cleave**: a gold sector telegraph, then a flaming sweep; each
    summon caught in it soaks part of your damage.
  - **Crusader's Command**: rally banners mark a shield line that forms
    behind you.
  - **Holy Standard**: a marked spot, then a destructible standard whose
    aura buffs the Covenant and Vael for 15 s. Kill it or pull him away.
  - **Shieldwall**: he raises a gold-rimmed shield for 4 s and walks slower;
    spells and projectiles deal only 50%; close-range blows reach around it
    for full damage: Warriors, bashes, Death Knights (strike, bash, cleave),
    Lich-risen skeletons, Abominations (fists, stomp), Rogues (stab, dash,
    bleed), Gargoyles (claws, swoop) and the Profane Bishop's aura
    (`MarchEnemyData.MELEE_SOURCES`).
  - **Last Stand** below 30% HP: faster swings and specials, and a
    Crusader's Command at once.

  He strides faster while far from you (he has no charge). Killing him drops
  a large XP burst, a chest and a power-up.
- **Structures and your kit**: outposts, Holy Ward Generators, supply carts
  and the Holy Standard are ordinary targets for summons and spells (Rot,
  bleeds, chills and knockback-free hits apply). They are immune to the
  Frost Wraith's Deep Freeze (the Stasis power-up still holds them), leave no
  corpse for Corpse Explosion, never rise as Lich skeletons, and Soul Siphon
  tethers them only when no soldier is in range.
- **Harder than the Graveyard**: from Zone II (4:00) enemies have ×1.1 HP and
  ×1.05 damage on top of the usual time scaling (Marshal Vael always), tougher
  kinds arrive earlier, and Soul Ash is ×1.25 (its own end-screen line). The
  first two minutes are recruit patrols only, like the Graveyard's opening:
  every build starts with Shadow Bolt and two warriors, and a harder opening
  snowballed into starved runs.

### Stage 3: The Sanctum of Judgment

The final assault on the Covenant's cathedral (GDD §8.3). Like the March, the
clock is in charge: **four battle zones** on fixed times, each announced with
a gold banner and a sweep of dusty light that rebuilds the terrain around you
(`MarchDirector` runs the zones; the zone and the floor's corruption are shown
under the timer). The GDD's 22:00 timeline is compressed into the 20:00
countdown with the boss at 17:00 like the other stages.

| Zone (from) | Ground and obstacles | Timeline beats (GDD §8.3) |
|---|---|---|
| I, the Outer Courtyards (0:00) | pale flagstones; saints' statues, fountains, benches | outer defenders; **sanctified chamber 1 at 3:00** |
| II, the Sanctified Halls (4:00) | gold mosaic and carpet runners; rows of pillars, pews | Sanctified Sentinels from 4:00; **Cathedral Guardian + chamber 2 at 5:30**; Radiant Inquisitors from 6:00 |
| III, the Cloisters (8:30) | stone walks and turf; cloister arches, garden beds, cypresses | High Confessor ambush at 8:30; **three sacred altars at 10:30** |
| IV, the Final Sanctuary (13:00) | marble and stained-glass light; giant statues, columns, reliquaries | Sun Paladins at 13:00; the final sanctuary opens at 15:30; **Grand Inquisitor Seraphine at 17:00** |

- **Sanctified chambers** (GDD "ward crystals"): a 220 px circle of holy
  ground near you with two **ward crystals**. Until both fall, every summon
  inside takes light holy damage each second (Unholy Resilience applies) and
  undead attacks on foes standing inside deal **25% less**. Shattering both
  cleanses it: the circle turns into a purple rot stain and the penalty ends.
- **The Cathedral Guardian** (5:30) is a plain miniboss (it shields nothing)
  with its own bar under the boss bar; it drops a **treasure chest**.
- **Sacred altars** (10:30, optional): three altars rise 300-400 px away, each
  guarded by a High Confessor. Every altar destroyed takes **6% max HP** off
  every Covenant soldier spawned afterwards (up to −18%) and weakens
  Seraphine's retinue (`Game.altars_destroyed`). Skipping them only costs the
  bonus.
- **Corruption**: every cleansed chamber and fallen altar corrupts the
  Sanctum; the whole floor darkens toward purple (HUD: *Corruption N%*).
  Each cleansed chamber pays +10 Soul Ash and each altar +8 (a *Stage
  objectives* line, before the stage bonus).
- **Dawn's Wrath**: the Sanctum's Reckoning. Same escalation, but a gold dawn
  light floods the field and Sun Paladins march with the Inquisitors.
- **The crypts beneath**: open crypts work like the Graveyard's empowered graves.
- **Hardest stage**: from Zone II (4:00) enemies have ×1.2 HP and ×1.1 damage
  (the boss always), and Soul Ash is ×1.5. The opening minute is recruits only.
- **New enemies and the boss**: the Sanctified Sentinel, High Confessor, Sun
  Paladin, Radiant Inquisitor, the Cathedral Guardian's kit and Grand
  Inquisitor Seraphine are named through the stage's kind aliases
  (`SanctumStage.KINDS` / `BOSS_ID`), so the timeline does not change when
  they arrive.

### Stage 3 Covenant kinds (the Sanctum of Judgment)

Five new Covenant kinds (GDD §7.2, §8.3; `SanctumEnemyData`), each with its
own silhouette and a `CovenantKit` for its specials. Any stage can spawn
them; the autotest's `--spawn=` puts them in any run.

- **Sanctified Sentinel** (squat pale-stone construct, gold eye slit):
  slow and armoured; it **ignores the first 6 damage of every hit** (after
  armour; a hit keeps at least 25%, so many weak hits still chip it: mages,
  spears and big single hits are the answer). When its target is close it
  shows a gold cone for 1 s, then **sweeps**: undead in the cone are hurt and
  shoved back, and so are you if you stand in it. Constructs are never
  healed, shielded or raised by Covenant priests.
- **Radiant Inquisitor** (elite caster: ivory robe, gold sunburst halo):
  advances shooting radiant bolts, lays **holy zones** on your path, and casts
  a **suppression sigil**: a 1 s gold warning circle (160 px) on your undead
  frontline, then for 4 s no replacement spawns inside it and summons that die
  inside it are **not replaced until it ends** (the rest of the army keeps
  replacing normally; afterwards replacement resumes as usual).
- **High Confessor** (elite priest: gold mitre, crook): heals the most wounded
  ally within 120 px, puts **holy shields** (an absorb, ivory-gold bubble) on
  up to 3 allies (bosses and elites first), and every 12 s **raises one fallen
  soldier** that died within 140 px of it, where it fell, after a **gold pillar
  of 1.5 s**: kill the Confessor during the pillar to cancel it. At most 3
  revives per Confessor; never elites, structures, constructs, bosses or the
  Reckoning; a raised soldier comes back at 60% HP, drops no XP and is never
  raised again. Your summons treat it as a top-priority healer.
- **Sun Paladin** (elite: gold shield with a sun emblem): an armoured Templar
  with the same telegraphed charge, whose **sun aura** gives other Covenant
  soldiers within 110 px **20% damage resistance** (a gold shield pip; one
  ward per soldier, Paladins do not stack; a Soul Nova ignores it).
- **Cathedral Guardian** (miniboss, owner decision: a plain one): a giant
  stone construct with **its own health bar** under the timer. It advances
  slowly (striding faster when left behind), punches, and alternates two
  telegraphed specials: a **ground slam** (gold circle on your spot; summons
  inside soak part of your damage and are thrown out) and a **sweeping beam**
  (a gold sector, then a radiant beam sweeps across it, hitting everything
  once). It shrugs off knockback, Deep Freeze / stuns and Stasis like a boss,
  is never recycled, and drops an XP burst and a **treasure chest** when it
  falls.

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
  | Stage objectives (Sanctum: cleansed chambers, destroyed altars) | 10 per chamber, 8 per altar | 2 + 3 = 44 |
  | **Stage bonus** (Crimson March / Sanctum) | +25% / +50% on the sum | |

  A strong run earns about **450** at no upgrades (about 550-610 with mid / max
  upgrades, Ash Harvest included): two or three mid-tier upgrades. A death at
  9-11 min still keeps about 100-150. The Reckoning pays only about 8% of a
  good run. Buying everything costs **9,835** (8,965 before the two Grave
  Step upgrades and the Spearhead stance unlock), about 22 good runs (17–28 including weaker runs and Ash
  Harvest), plus 375 for the optional Profane Oath (10,210 in all). The Profane Pact and Oath rewards add their own bonus
  lines on top (below).
- **The Ossuary** (main menu) holds the four GDD §9.2 trees. Each upgrade
  raises one stat per tier, costs rise per tier, and some need a prerequisite
  in the same tree:

  | Tree | Upgrades (per tier, tiers, cost of tier 1 → last) |
  |---|---|
  | Necromancy | Necrotic Marrow minion HP +6% (5, 40→230) · Sharpened Bones minion damage +5% (5, 40→230) · Grave Call replacement time −6% (3, 60→200) · Risen Vanguard +1 Warrior capacity (2, 130→280; needs Marrow II) · Legion of Bone +1 capacity for every class (1, 500; needs Vanguard II) · Spearhead Doctrine unlocks the Spearhead army stance (1, 200) |
  | Shadowcraft | Umbral Potency spell damage +5% (5, 40→230) · Quickened Rites spell cooldowns −3% (4, 60→250) · Widening Dark Shadow Blast / pulse radius +6% (3, 70→230; needs Potency I) · Shadow Mastery spell damage +10% (1, 450; needs Rites III) · Restless Shade Grave Step cooldown −10% (3, 60→190; 5 s → 3.5 s) |
  | Survival | Grave-Hardened Flesh max HP +10 (5, 40→230) · Bone Mail damage taken −3% (4, 60→250) · Fleet Shade move speed +4% (3, 50→175) · Undying Will one revival per run at 50% HP with a knock-back burst (1, 550; needs Bone Mail II) · Twin Shadow +1 Grave Step charge (1, 300; needs Fleet Shade I) |
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
  Warriors, also as Death Knights, land 1,000 killing blows), *Heretic's Bane*
  (500 Chaplains slain), *Dread Sovereign* (slay Sir Alaric while commanding
  Warriors, Archers, Mages and a priest order: Menders, Warders or Bishops),
  *Dawn Extinguished* (slay the Sanctum's boss, Grand Inquisitor Seraphine;
  counted from the Sanctum's stage record).
  Their unlocks (Bone Golem, a Profane Bishop unlock, a skin, the campaign
  epilogue) don't exist yet (the Profane Bishop is available from the start),
  so each pays a one-time Soul Ash bounty (100 / 100 / 150 / 200) for now. Capacity upgrades that
  apply to "every class" (Legion of Bone, Grave Dominion) count the Mender
  and the Warder as two classes and the merged Bishop as one.
- **Save file.** `user://save.cfg` (ConfigFile, separate from `settings.cfg`)
  stores `save_version`, Soul Ash, every tier, lifetime stats and achievements.
  It is written on every run end, purchase and refund (via a temp file and a
  rename). A missing file starts a fresh profile. An unreadable file is kept as
  `save.cfg.corrupt` and the game starts fresh. Every value is type-checked and
  clamped, unknown keys are ignored, and tiers whose prerequisite is missing
  are refunded. The autotest never reads or writes it (unless `--meta-save`).
  The active Profane Oath tier is saved as `[oath] active`. Per-stage records
  (runs, victories, best time, boss kills) are saved under `[stages]`; they
  drive the stage unlocks. An older save without that section is migrated:
  its lifetime stats become the Graveyard record, so a past Alaric kill
  unlocks the Crimson March. The last pre-run choice is saved as
  `[prerun] difficulty` / `modifiers` (a comma-separated id list); an older
  save without it starts on Necromancer with no modifiers, and unknown ids
  are dropped. Discovered evolution recipes are saved under `[recipes]`
  (`<evolution id> = true`), written as soon as an evolution is obtained; an
  older save without the section starts with nothing discovered.

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
  makes about **4-7 chests per run** on the Graveyard (combined balance pass:
  median 5 for the army bot, 7 for the summon bot, 2-3 for naive runs; the
  Crimson March adds its ward-generator and Vael chests: army median 7). Chests never despawn (at most 3 on the
  ground), and none drop from Reckoning enemies or after 0:00. Walking over
  one pauses the run and shows a short code-drawn reveal. Before **15:00
  elapsed** a chest grants **1** upgrade; from then on **1, 3 or 5**
  (weights 85 / 12 / 3), drawn from the normal level-up pool with the usual
  card weights, listed with their old → new levels. **A chest only upgrades what you already own**
  (survivor convention): it never puts a new spell, summon class or passive into an empty slot, so your slots stay your
  own level-up choices. **Every ready evolution comes first: evolutions are delivered only
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
  area shows the Pact level, the Oath tier and their combined effect. The
  difficulty levels and run modifiers go through the same path (the run
  modifiers join the Pact and Oath category; see *Difficulty & run
  modifiers*).

---

### Camera zoom

The Settings menu has a **Zoom** option: Close (1.25×), **Normal (1.0×, default)** and Far (0.8×).
Zooming in never changes gameplay (enemy spawns use the Normal view or wider). A green ring on the
ground marks the necromancer.

### Sprite art (in progress)

Units can use real sprite art instead of their code-drawn shapes. `SpriteBank` draws
`assets/sprites/<category>/<id>.png` whenever that file exists and otherwise falls back to the
glyph, so art arrives one piece at a time without breaking anything. The style is **pixel art**,
set by the approved necromancer sprite. Sprites are generated in ChatGPT from the prompt pack in
`docs/art/ART_BIBLE.md` and processed with `python3 tools/prepare_sprite.py <image> <key>`, which
keeps the original in `art_source/` (ignored by Godot), crops it and stores it at 3x its on-screen
height from `scripts/data/sprite_data.gd`. Done so far: the necromancer, every summon and evolution, every enemy soldier (Stage 1, Stage 2 and the Reckoning's Inquisitor), both bosses (Sir Alaric, Marshal Vael) and the five Crimson March structures. Still to do: the pickups.

Effects (explosions, bursts) can be **short animations**: a ChatGPT sprite sheet or a GIF, converted
with `python3 tools/prepare_sprite.py --anim <sheet or GIF> <id>` into a strip of square 128 px
frames at `assets/sprites/effects/<id>.png`. An effect given an animation id plays it once, scaled
to its radius (timing and fill in `scripts/data/anim_data.gd`), and keeps its drawn shape when the
file is missing. Shadow Blast (the test), the Dread Rally burst (`dread_rally`) and the Grave Step
departure puff (`grave_step_trail`) are wired so far.

## What is implemented (vs. the GDD)

| Area | Status in this prototype |
|---|---|
| Necromancer | Movement (keyboard and stick), HP with a slow natural regeneration (0.5 HP/s), i-frames, pickup radius, hit flash. Can receive Mender heals and Warder wards. |
| **Shared summon AI** (§25–§31, §36) | **One** data-driven `SummonedUnit` script runs every class (Warrior, Archer, Mage, Mender, Warder, Profane Bishop, the evolved Death Knight and Lich, and the four later classes). It has the full FSM from §25, soft formation bands around the player (§26), and normalised target scoring (§27). Targets are held for at least 1 s; ranged units redirect when a target is already doomed (overkill reservation); healers use the §31 heal formula. Support and evolution kits (ally barrier, aura, cleave, life drain) are data-driven hooks into `SummonAbilities`; the four later classes plug one special action each into the AI through a `SummonBehavior` (see *Summon classes*). |
| Leash and recall (§24) | Engagement radius 220 px, soft recall at 320 px, hard spectral recall at 650 px (Bound Souls widens the first two by up to 50% and halves the return trip). |
| Replenishment (§24) | Each summon ability refills its own queue one unit at a time (Warrior 5 s, Archer 8 s, Mage 12 s, Mender and Warder 15 s, Profane Bishop 12 s; Abomination 20 s, Rogue 9 s, Gargoyle 12 s, Frost Wraith 14 s). A capacity increase spawns the new units immediately. A failed spawn retries without using up the timer. |
| **Warrior blocking** | Warriors are physical blockers. Enemies can't pass through them; overlaps are resolved through the spatial hash, weighted by mass. An enemy touching a warrior is *engaged*: it moves at 60% speed and attacks that warrior. Warriors also shield-bash on a cooldown (damage plus knockback). Sir Alaric's Divine Charge loses distance for every undead body it hits, so a thick enough wall stops it. |
| **Priest orders** (user request: the GDD's Priest split in two) | **Grave Mender** (round teal robe, green halo): heals allies and the necromancer with the §31 formula, a critically hurt necromancer first (the old priest heal, unchanged). **Crypt Warder** (heater-shaped blue robe, ward sigil): whenever you are under threat (hit in the last 1.5 s, or any enemy within 90 px) it casts an instant damage-absorbing **ward** on you, as long as no ward is active and its own ward cooldown is ready (the old priest ward, same numbers); it also casts an instant **barrier** (12 HP, +25–80% by level) on the most threatened ally in reach every 3 s: an ally hit in the last 2 s, or a warrior fighting in melee, whose barrier is below half. Barriers don't stack with Shieldwall's (the stronger one wins). Both orders fire weak bolts when idle. Each has its own card, cap (1-2 by level), 15 s replenishment and HUD row; the ward shows as a ring on the necromancer and in the HUD. |
| Staggered AI and performance (§25, §38) | Unit and enemy decisions run at 5 Hz spread over 12 ticks. Formation updates at 4 Hz, threat checks at 5 Hz, enemy separation at 10 Hz. A uniform-grid spatial hash handles all neighbour and target queries. Projectiles, enemies, summons, XP crystals and effects are all pooled. |
| Spells (§8) | Shadow Bolt (starting spell, homing, multi-shot, pierce; the player can switch its aim between *Nearest* and *Strongest*, i.e. highest current HP, with ties going to the nearest; extra bolts go to the next-ranked targets; shown on the HUD above the ability bar). Shadow Orb Shield (orbiting damage; intercepts a limited number of projectiles, then recharges). Shadow Blast (area damage plus slow). Plus Bone Spear, Soul Siphon, Corpse Explosion and Plague Cloud (see *The newer spells*). Each has 5 levels. |
| Passives (§34) | Grave Dominion (capacity), Necrotic Vigor (minion HP), Dark Command (minion damage and attack speed; at Lv 5 it evolves Warriors), Soul Recycling (faster replacement), plus the evolution passives Soul Conduit, Warding Ritual, Abyssal Focus, Shade Stride, Vampiric Rite, Necrotic Expanse, Lingering Malediction, Forbidden Knowledge (mage damage and splash) and Dark Benediction (heals, wards and barriers), and the later horde passives Bone Plating (flat damage off every hit on a minion), Unholy Precision (minion crits), Unholy Resilience (less area / holy damage to minions) and Bound Souls (minion speed, leash and return). Every evolution needs its paired passive at Lv 5. Bonus stacking follows §34. |
| Evolutions & synergies (§6) | Void Barrage, Eclipse Ward, Abyssal Detonation, Ossuary Lance, Soul Rapture, Grave Eruption and Pestilence; the summon evolutions Death Knight, Lich, Profane Bishop (a merge of the two priest orders), Shadow Reaper and Cathedral Horror; four army synergies; weighted level-up cards with Reroll, Banish and Skip. See *Evolutions & Synergies* above. |
| Enemies (§10, §35) | Covenant Recruit, Crimson Footman (armoured), Zealous Archer (ranged), Chaplain (heals other enemies), Purifier (hunts undead, ×2 damage to summons), elite variants, and the Reckoning's *Inquisitor of the End*. Survivor convention: **every enemy always advances on the player**. Archers shoot and Chaplains heal while walking in (archers slow briefly after each shot); nobody kites or holds at range. Undead have no dodge AI and act as body blockers, so enemy arrows hit the first summon in their path. **Templar Knights** (heavy charging melee) join at 13:00. |
| Waves and stage events (§11) | The data-driven 20-minute Graveyard timeline at the GDD's real times (Sir Alaric at 17:00), then the Reckoning. It includes empowered graves, Desecration, Templar Knights and the Crypt Defender, and the arena has solid obstacles. See *Stage & Boss* above. |
| Boss (§11) | Sir Alaric with all five telegraphed attacks (Hammerfall, Divine Charge, Consecrated Ground, Call to Arms, Judgment of the Dead), plus a *Wrath* phase at 50% HP. |
| Stages (§8, §9.3, §10.2) | A stage registry with three stages, a stage select (locks, best time, boss kills) and the GDD §9.3 unlocks (slay Sir Alaric once to open the Crimson March, Marshal Vael once to open the Sanctum). See *Stages* above. |
| Stage 2 (§8.2, §7.4, §7.5) | The Crimson March: four battle zones on the clock with their own ground and obstacles, outposts, Holy Ward Generators, supply carts, three new Covenant soldiers (Shieldbearer, Banner Bearer, Halberdier) and Marshal Vael with Radiant Cleave, Crusader's Command, Holy Standard, Shieldwall and Last Stand. See *Stage 2* above. |
| Stage 3 (§8.3, §7.4) | The Sanctum of Judgment: four battle zones on the clock (courtyards, golden halls, cloisters, final sanctuary), two sanctified chambers with ward crystals, the Cathedral Guardian miniboss (chest), three optional sacred altars (−6% soldier HP each), floor corruption, Dawn's Wrath, the boss slot for Grand Inquisitor Seraphine. See *Stage 3* above. |
| Meta-progression (§9.2, §9.4) | Soul Ash earned every run (kept on death), the Ossuary shop with the four trees (18 upgrades plus the Spearhead stance unlock, prerequisites, respec) plus the opt-in Profane Oath, 4 tracked achievements, and a versioned save in `user://save.cfg`. See *Meta-progression (Soul Ash)* above. |
| Power-ups, chests, difficulty (§6.1, §8.5) | Six power-up drops with pity timer and despawn, treasure chests that deliver evolutions (the "special elite reward"), the Profane Pact passive and the Profane Oath meta upgrade. See *Power-ups & Profane Pact* above. |
| Difficulty levels and run modifiers (§8.4, §8.5, §10.2) | The four GDD difficulty levels and all eight GDD run modifiers, chosen on a pre-run setup screen that shows the total Soul Ash multiplier, remembered in the save and shown on the HUD and end screen. See *Difficulty & run modifiers* above. |
| Audio, feel and settings (§12, §38) | Synthesized sound effects and music with voice limits, screen shake, hit-stop, damage numbers and particles. The settings menu has volumes, toggles, fullscreen and key rebinding, saved to `user://settings.cfg`. See *Audio, Feel & Settings* above. |
| UI (§16) | Main menu, HUD, level-up cards (they grow to fit their text), pause menu (with a **Recipes** view of the discovered evolution recipes), end screens and the F3 debug overlay; all are fully usable with a controller (`ui_accept` / `ui_cancel` include pad A / B, and each screen focuses a button when it opens). The HUD shows: XP bar; HP, orb shields and the Warder ward; countdown, objective, event banner and boss HP; kills; army per class with replacement progress (compact rows, at most one per active slot); ability slots with levels (an evolved class shows its evolution's icon and name). |
| Art (§16, §17) | Placeholder shapes drawn in code. Undead use blue, violet, green and bone; the Covenant uses crimson, ivory, silver and gold. **Every unit and enemy type has its own silhouette** (for example, warriors are squares with shields, archers are triangles, mages are diamonds, Menders are round with a halo, Warders are downward heater shapes under a floating ward sigil, Bishops wear a tall mitre over a bell robe, Death Knights have horned helms, spiked pauldrons and a greatsword, Liches float as crowned wisps, the Lich's risen dead are bare ribcages, abominations are huge stitched blobs, rogues are hooded chevrons with daggers, gargoyles have bat wings, frost wraiths are legless ice ghosts, Shadow Reapers are smoke-trailing hooded scythe assassins, Cathedral Horrors are huge marble gargoyles on a broken plinth). Hit flashes, death pops and an evolution glow are included. |

### Where the numbers come from

All tunable numbers are in `scripts/data/`. Each value is tagged in a comment:

- Values from the spec are marked `# GDD §N`.
- Invented values are marked `# TUNING (not in GDD)`.

**From the spec:**

- Unit table (§23): HP, damage, attack interval, preferred range, speed, level-1
  count and radius for all four classes.
- Priest heal of 8 HP per 2 s cast (§23), now the Grave Mender's.
- Replacement timers 5 / 8 / 12 / 15 s (§24); the Mender and Warder keep the priest's 15 s.
- Spawn distance 35–80 px (§24).
- Leash distances 220 / 320 / 650 px (§24).
- AI rates of 5 / 4 / 5 Hz (§25).
- Formation bands 35–85, 85–155 and 60–125 px (§26).
- Warrior and priest steering weights (§26), used by all three support classes.
- 1 s target commitment and "critical below 35% HP" (§27).
- Warrior intercept radius of 80 px (§28).
- Archer kite distance of 45 px (§29), now 0: archers hold their ground (user decision, GDD §15.0).
- Heal score weights 0.6 / 0.2 / 0.2 (§31).
- Warrior level progression 2 → 3 → 5 → 6 → 8, with its % bonuses (§34).
- 6 active and 6 passive ability slots (§6), 5 levels per skill, and 3 cards per level-up.

**Invented** (the spec is silent on these): all enemy and boss stats, spell
values, passive values, archer/mage/Mender/Warder level progressions (aimed at
the §42 sandbox army of 5 archers, 3 mages and 2 priests), archer and mage
steering weights, target-score weights, the XP curve, player stats, the
warrior blocking/bash and Warder ward / barrier values, the Profane Bishop and
the summon-evolution numbers, the Reckoning scaling, and everything about the
Abomination, Rogue, Gargoyle and Frost Wraith.

---

## Architecture

```
scenes/main.tscn            Minimal entry scene (one Node + main.gd)
scripts/
  core/
    game_state.gd           Autoload: CLI options (autotest), session prefs, last run summary
    settings.gd             Autoload: persistent settings (volumes, toggles, key rebinds) in user://settings.cfg
    meta_progress.gd        Autoload "Meta": Soul Ash, upgrade tiers, lifetime stats, achievements,
                            discovered evolution recipes,
                            purchase / refund, run award, versioned save in user://save.cfg
    meta_modifiers.gd       The ONE path meta upgrades take into a run (game.meta, read by stat code)
    difficulty_modifiers.gd The ONE path the difficulty level, run modifiers, Profane Pact + Oath take
                            into a run (game.difficulty); defines how they combine
    arena.gd                Solid obstacles (circles/rects) and the collision push-out used by all units
    main.gd                 Switches menu <-> run (a run is a fresh Game node every time, built from a RunConfig)
    run_config.gd           Pre-run choices handed from the menu into Game (stage, difficulty, run modifiers)
    game.gd                 One run: builds world + managers in code, fixed-order simulation step,
                            level-up / pause / end-of-run flow; `stage_def` = the run's stage
    spatial_hash.gd         Uniform grid for radius queries (enemies and allies, rebuilt per tick)
    combat_resolver.gd      All damage / healing / kills / XP drops / stats go through here
    effect.gd, effect_manager.gd   Pooled cosmetic effects and boss telegraphs
    glyphs.gd               All placeholder shapes (world entities AND UI icons share this code)
    sprite_bank.gd          Optional sprite art (assets/sprites/), falls back to the glyphs
    ground.gd               Procedural graveyard floor, redrawn only when the camera changes cell
    march_ground.gd         Crimson March floor: the road and each battle zone's look (extends Ground)
    march_glyphs.gd         Crimson March shapes: new soldiers, structures, Marshal Vael, obstacles, corpse piles
    sanctum_ground.gd       Sanctum floor: each battle zone's look, corruption tint (extends Ground)
    sanctum_terrain_glyphs.gd  Sanctum shapes: ward crystals, sacred altars, the four zones' obstacles
    sanctum_glyphs.gd       Sanctum of Judgment Covenant shapes (Sentinel, Radiant Inquisitor, High Confessor,
                            Sun Paladin, Cathedral Guardian) and their overlays (holy shield, sun ward,
                            revival pillar, suppression sigil, Guardian beam)
    evolution_recipes.gd    Read-only list of every evolution recipe (spell + summon data), for the
                            Recipes view, the Meta [recipes] section and the autotest
    autotest.gd             Headless self-test driver
    stance_bot.gd           The autotest's army-stance driver (--stance, or its switching rule)
  player/necromancer.gd
  player/grave_step.gd      Grave Step dash: charges, obstacle-clamped step, i-frames, shadow trail
  player/dread_rally.gd     Dread Rally ultimate: kill-charged soul meter, surge, heal, army buff, knockback
  horde/
    horde_director.gd       Army registry, pools, caps, effective stats, replenishment queues,
                            formation anchors, threat evaluation, staggered 5 Hz AI ticks
    synergy_manager.gd      Army synergy activation and effects
    summoned_unit.gd        The ONE shared FSM/steering/targeting AI for all summon classes
    summon_abilities.gd     Data-driven kits the shared AI hooks into: Warder / Bishop ally
                            barrier, Bishop aura pulse, Death Knight cleave + life drain
    summon_evolutions.gd    Summon evolutions: eligibility, stat overlay, in-place transform,
                            Mender + Warder merge, Lich raise-the-dead, card hints
    winter_revenant.gd      Winter Revenant kit: shatter (kill hook) and death nova (summon_died)
    suppression_field.gd    Holy suppression zones (HordeDirector.add_suppression(): blocked replacement
                            spawns, held deaths, optional minion damage cut)
    minion_passives.gd      Card lines and the autotest line of the later horde passives
                            (their effects live in CombatResolver / compute_stats)
    army_stance.gd          The run's army stance (game.stance): lockout, keys / right-stick
                            flicks, Ossuary unlock, the numbers the director reads, summary stats
    stance_formations.gd    Formation posts of Onslaught, Spearhead and Bone Ring (Escort is the
                            director's own layout)
    behaviors/              Class special actions plugged into that AI (one SummonBehavior per unit):
      summon_behavior.gd      Base class: think / physics / attack / score / draw hooks, recall-safe
      summon_behaviors.gd     Registry (behavior id -> class) and the level-up card lines
      abomination_behavior.gd Stomp (telegraphed ring, AoE damage + knockback)
      special_evolutions.gd   Shadow Reaper / Cathedral Horror card lines and autotest line
                              (their mechanics live in the Rogue / Gargoyle behaviours)
      rogue_behavior.gd       Dash Strike (telegraphed lane, dash, bleed, return to formation)
      gargoyle_behavior.gd    Swoop (airborne flight over obstacles, dive AoE, safe landing)
      frost_wraith_behavior.gd Frost bolts (chill) and Deep Freeze (the Stasis freeze path)
    gravebow_kit.gd         Gravebow volleys (pierce, split fan, cursed arrows), card lines, autotest line
    colossus_kit.gd         Bone Colossus taunt list (4 Hz, generation-checked) and shrapnel burst
  enemies/
    enemy.gd                Data-driven Covenant soldier (melee / purifier / ranged / healer / banner /
                            structure / cart), auras, cleaves, damage-taken hook, warrior-blocking resolution
    boss.gd                 Shared base of the stage bosses (extends Enemy; EnemyDirector.boss)
    boss_alaric.gd          Sir Alaric (extends Boss): five telegraphed attacks + Wrath phase
    boss_vael.gd            Marshal Vael (extends Boss): Cleave, Command, Holy Standard, Shieldwall, Last Stand
    stage_director.gd       Empowered graves, Desecration, Crypt Defender, holy ground (incl. ward-generator zones)
    march_director.gd       Crimson March: battle zones, outposts, ward generators, supply carts, timed structures
                            (also the Sanctum's battle zones)
    sanctum_director.gd     Sanctum: sanctified chambers, Cathedral Guardian, sacred altars, corruption, Dawn's Wrath light
    enemy_director.gd       The stage's wave timeline, events, boss, Reckoning, pooling, recycling,
                            the miniboss slot (HUD bar)
    sanctum/                The Sanctum of Judgment's Covenant kits (one CovenantKit per enemy, like
                            the summon behaviours):
      covenant_kit.gd         Base class: reset / think / physics / killed / danger / draw hooks
      covenant_kits.gd        Registry (kit id -> class)
      covenant_rites.gd       Recent-deaths ring buffer, High Confessor revivals (gold pillars), danger hints
      sentinel_kit.gd         Sanctified Sentinel: telegraphed frontal sweep with knockback
      inquisitor_kit.gd       Radiant Inquisitor: holy zones and the suppression sigil
      confessor_kit.gd        High Confessor: holy shields and revival (heals use the shared healer AI)
      paladin_kit.gd          Sun Paladin: sun ward aura (the charge is the shared Templar rush)
      guardian_kit.gd         Cathedral Guardian miniboss: ground slams, sweeping beam, XP burst
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
  fx/stance_outline.gd      Faint ground outline of the army's shape after a stance change
  ui/                       hud, level_up_panel, pause_menu, end_screen, main_menu,
                            debug_overlay, hud_bar, icon_glyph, ui_theme, settings_menu,
                            progression_glyphs (evolution/synergy icons), summon_glyphs
                            (Warder, Bishop, Death Knight, Lich, risen skeleton,
                            Abomination, Rogue, Gargoyle, Frost Wraith shapes and
                            their icons, evolution glow, enemy chill tint),
                            reaper_horror_glyphs (Shadow Reaper, Cathedral Horror,
                            enemy stun stars, stone-form shell),
                            gravebow_colossus_glyphs (Gravebow, Bone Colossus, their icons,
                            the curse tint),
                            ossuary_menu (Soul Ash shop), meta_glyphs (Soul Ash / tree / upgrade icons),
                            chest_panel (chest reveal), powerup_glyphs (power-up, chest, Pact / Oath icons),
                            stage_select (stage cards, locks, best times), pre_run_setup (difficulty level,
                            run modifiers, total Soul Ash multiplier), recipes_panel (pause menu
                            Recipes view: discovered evolution recipes, locked "?" placeholders),
                            hud_abilities (Grave Step charges and Dread Rally meter), ability_glyphs
                            (their icons), stance_bar (HUD stance icons + banner),
                            stance_glyphs (stance icons, padlock, ground outline shapes)
  data/                     DESIGNER-TUNABLE DATA (no logic):
    stage_registry.gd       The stages in campaign order (id -> STAGE dictionary; every key documented)
    stages/graveyard_stage.gd      Stage 1: segments, events, Reckoning flavour, graves, desecration,
                                   Crypt Defender, obstacle layout, boss arrival
    stages/crimson_march_stage.gd  Stage 2: segments, events, zones (ground + layout), march config,
                                   stage multipliers, boss arrival
    stages/sanctum_stage.gd        Stage 3: kind aliases (integration stand-ins), segments, events,
                                   zones, chamber / altar / corruption rules, Dawn's Wrath, boss arrival
    sanctum_objective_data.gd      Sanctum structures: ward crystal, sacred altar
    unit_data.gd            Summon classes (and their specials), level tables, AI weights, leash/rates
    enemy_data.gd           Graveyard enemy roster, Sir Alaric, Reckoning enemy, elites
    march_enemy_data.gd     Crimson March soldiers and structures, Marshal Vael
    sanctum_enemy_data.gd   Sanctum of Judgment kinds (Sentinel, Radiant Inquisitor, High Confessor,
                            Sun Paladin, Cathedral Guardian) and their kit numbers
    wave_data.gd            Shared run rules: countdown, enemy time scaling, caps, spawn ring
    ability_data.gd         Spell level tables
    passive_data.gd         Passive level tables
    evolution_data.gd       Evolution recipes and stats
    recipe_book_data.gd     Texts of the pause menu's Recipes view (discovered evolutions)
    summon_evolution_data.gd Summon evolution recipes (Death Knight, Lich, Profane Bishop,
                            Winter Revenant, Shadow Reaper, Cathedral Horror, Gravebow,
                            Bone Colossus) and stats
    synergy_data.gd         Army synergy requirements and effects
    level_up_data.gd        Card weights, reroll/banish/skip counts, fallback cards
    arena_data.gd           Structural obstacle limits (cell size, margins; layouts live in the stage files)
    sound_data.gd           Sound recipes, voice limits, priorities
    player_data.gd          Player stats, XP curve, slot counts
    player_ability_data.gd  Grave Step and Dread Rally numbers (and the bots' use of them)
    meta_data.gd            Soul Ash formula, upgrade trees / tiers / costs, achievements, autotest profiles
    powerup_data.gd         Power-up types, weights, durations, drop chances, pity, cap, lifetime
    chest_data.gd           Chest drop chances, pity, contents (1 / 3 / 5) weights, reveal timing
    pact_data.gd            Profane Pact levels and Profane Oath per-tier values
    difficulty_data.gd      GDD §8.4 difficulty levels (Initiate, Necromancer, Lich, Deathlord)
    run_modifier_data.gd    GDD §8.5 run modifiers: effects and Soul Ash rewards
    stance_data.gd          Army stances: leash / recall / pull overrides, shapes, lockout,
                            switched-off flavour bonuses, the autotest stance bot's thresholds
    palette.gd              Colour language
```

**Simulation order.** Each physics tick (60 Hz), `Game` runs these steps in order:

1. Rebuild the enemy and ally spatial hashes.
2. Player, then the army stance's bookkeeping (move direction, per-stance stats).
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
counter. A unit, enemy, projectile or healer that holds a reference checks the
generation, so it never acts on a recycled node.

**Overkill reservation.** Ranged damage that is already in flight is recorded on
the target (`Enemy.incoming_damage`). Archers, mages and Shadow Bolt pass over
targets that are already expected to die. Menders and Bishops do the same with
`incoming_heal`, so two healers don't both heal the same full-HP ally.

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
| `--policy=NAME` | Level-up card policy: `naive` (default; takes every new summon class, then new spells, then new passives), `army` (a summoner build that levels summons and army passives first, both priest orders included; it maxes Dark Command, so it usually gets the Death Knight too), `evolve` (a spell build that chases the three spell evolutions), `summon` (a summoner build that chases the three summon evolutions: Warriors + Dark Command, Mages + Forbidden Knowledge, Menders + Warders + Dark Benediction) or `pact` (the naive build that takes every Profane Pact card at once, to measure the Pact). Every other policy ranks the Pact below every card, fallbacks included, so balance runs never take it. |
| `--meta=PROFILE` | Simulated Soul Ash purchases, applied in memory only: `none` (default, so balance runs stay comparable), `mid` (about half of every tree) or `max` (everything). |
| `--meta-save` | Test flag: lets the autotest read and write `user://save.cfg` (by default it never touches it). Every run's summary has a `recipe book` line (evolutions discovered so far, in memory only without this flag) and builds the Recipes view rows once, headless. |
| `--oath=N` | Active Profane Oath tier 0-5 (default 0). No `--meta` profile includes the Oath, so `--meta=max` balance runs stay comparable. |
| `--classes=a,b` | Forces summon classes (`abomination`, `rogue`, `gargoyle`, `frost_wraith`, or any offerable class id; the merge-only `bishop` is ignored): each is raised to Lv 1 at the start (while active slots allow) and every policy upgrades it first, so its special gets exercised. |
| `--pact` | Any policy also takes every Profane Pact card at once (`--policy=army --pact` is a strong build with the Pact; it gives up Warding Ritual for the Pact's slot, not the Void Barrage passive). |
| `--spells=a,b,...` | Any policy first takes these spells (ids from `AbilityData.SPELL_ORDER`, e.g. `bone_spear,soul_siphon,corpse_explosion,plague_cloud`) and their evolution passives, which also get ×8 card weight in hands and chests so they are offered reliably (a test-only hook; without `--spells` the draw is unchanged), never banishes them, and stops taking other new actives (or passives) once the free slots are down to the forced spells (or passives) still missing plus one spare, because chests can fill slots too (a hand with nothing else is rerolled or skipped). The `army`, `evolve` and `summon` bots never take a new item that is not on their build list (they reroll or skip), so the newer spells and the later summon classes do not change those baselines (`--classes` / `--spells` items are exempt); the `summon` and `army` bots also keep active slots free for the core classes they still lack (summon: Warriors, Mages, Menders, Warders; army: those plus Archers). Use it to exercise a spell and reach its evolution. |
| `--passives=a,b,...` | Any policy first takes these passives (ids from `PassiveData.ORDER` except the Pact, e.g. `unholy_precision,unholy_resilience`) exactly like the `--spells` items (score, ×8 card weight, slot reservation, never banished), so a passive's effect can be exercised. |
| `--stage=ID` | Stage to play: `graveyard` (default), `crimson_march` or `sanctum`. Stage locks are ignored. |
| `--difficulty=ID` | Difficulty level (GDD §8.4): `initiate`, `necromancer` (default, today's game), `lich` or `deathlord` (names work too, any case). |
| `--stance=ID` | Army stance for the whole run: `escort`, `onslaught`, `spearhead` or `bone_ring` (forcing ignores the Spearhead unlock). Without it, `army`, `summon` and `evolve` switch stances by a simple rule (Bone Ring when the necromancer is in danger or the boss is within 260 px; Onslaught when at most 6 enemies are within 220 px and a Crimson March structure or a Sanctum crystal / altar is within 420 px or at most 10 enemies are within 480 px; Spearhead, when owned, toward a chest or power-up within 300 px; else Escort; `StanceBot`), while `naive` and `pact` keep Escort so their baselines do not move. |
| `--spawn=k@T[xN],...` | Test hook: force-spawns N (default 1) enemies of kind `k` at T game seconds, in an arc on the spawn ring, on any stage (any kind id of `EnemyData`, `MarchEnemyData` or `SanctumEnemyData`), e.g. `--spawn=sanctified_sentinel@120x3,high_confessor@180x2,cathedral_guardian@300`. When a Sanctum kind spawned, the summary adds `sanctum ...` lines (spawned / killed per kind; Sentinel sweeps and flat armour absorbed; Inquisitor zones and suppressions with the horde's suppression counters; Confessor heals, shields, revives and cancelled revives; Paladin ward pulses and damage prevented; Guardian slams, beams, kills, time to kill and chests). |
| `--modifiers=a,b` | Run modifiers (GDD §8.5): any of `endless_crusade`, `hardened_faith`, `divine_fury`, `purge_the_unholy`, `scarcity`, `frail_master`, `vengeful_dead`, `holy_retribution`, or `all`. The summary adds a `difficulty` line (level, modifiers and every effective multiplier, the Soul Ash parts) and a `difficulty results` line (the difficulty and modifier Soul Ash lines, trickle elites promoted, Holy Retribution bursts and their damage, the starting max HP). |

Setting the environment variable `GRAVEBOUND_AUTOTEST=1` is the same as `--autotest`.

On the Crimson March the autopilot also walks toward outposts, ward generators
and supply carts when nothing presses it, and the summary adds four lines:
`crimson march` (zones entered and the final zone; outposts, generators,
carts and Holy Standards placed / destroyed / escaped; outpost reinforcements;
ward zones), `march enemies` (aura buff pulses, halberd cleave hits, damage
resisted by tower shields and by Vael, kills of the new kinds), `marshal vael`
(Last Stand, cleave hits on summons and how often they soaked his blow for
you, Crusader's Command soldiers) and `march events` (a timed log). The
`boss attacks` line lists the stage boss's own specials. In the Sanctum
(the zones also print the `crimson march` line) the `army`, `summon` and
`evolve` autopilots walk toward live ward crystals and sacred altars when
calm, and the summary adds `sanctum` (chambers cleansed and when, crystals
destroyed, altars destroyed and when, corruption, the soldier HP cut, the
Guardian's death time, chamber burns, objective Soul Ash, structures caught in
an obstacle (must stay 0), minion damage the chambers prevented) and `sanctum
events` (a timed log). Every run ends with
a `stage:` line (stage, Soul Ash stage bonus, stages unlocked by the run).

The summary covers: result, time, kills, level, army per class, boss
spawn/kill, all cards picked, and per-source damage (`dmg_warrior`, `dmg_bolt`,
`dmg_bash`, …). It also reports damage taken by summons, split by attacker
(`summon_dmg_from_*`) and damage taken by the player, split by attacker
(`player_dmg_from_*`); damage to the boss by source (`bossdmg_*`); Shadow Bolt
damage per aim mode (the autotest uses Nearest, then switches to Strongest when
the boss spawns); a **necro spells** line (for each newer spell: level, total
damage and the evolved part, boss damage, and counters such as volleys,
lifesteal healed, corpse bursts and chains, clouds, Death Novas and the Rot
bonus damage); a **horde passives** line (each later horde passive's level,
damage prevented by Bone Plating and by Unholy Resilience, split area /
holy, Unholy Precision crits and their extra damage, Bound Souls soft and
hard recalls; the stats are `plating_dmg_prevented`,
`resilience_dmg_prevented[_area|_holy]`, `minion_crits`,
`minion_crit_bonus_dmg`, `summon_soft_recalls`); heals, wards and orb intercepts; peak entity counts;
pool node counts; and the average and worst simulation-step cost. The
**evolution** lines list every evolution by type (spell / summon) with its
time, the summon-evolution counters (Lich raises and raises lost at the cap,
Menders / Warders converted and dissolved by the merge, Bishop aura pulses),
and the damage / heals / shields of every summon source
(`dmg_<tag>`, `heal_by_<tag>`, `shield_by_<tag>`; tags are the class or
evolution id plus `bash`, `death_knight_bash`, `death_knight_cleave` and
`lich_risen`) and the same summed per class. The **special evolutions** line
counts the Shadow Reaper's chained dashes, cooldown resets, bleed stacks added
and the most stacks on one enemy (`reaper_chain_dashes`, `reaper_cd_resets`,
`reaper_bleed_stacks_added`, `reaper_max_bleed_stacks`) and the Cathedral
Horror's stuns (and on the boss), stunned-enemy seconds, stone forms, stone
seconds and damage the stone prevented (`horror_stuns`, `horror_boss_stuns`,
`enemy_stunned_seconds`, `horror_stone_forms`, `horror_stone_seconds`,
`horror_stone_dmg_prevented`). The ward line reports wards on
the necromancer (and per minute with 2+ Warders / Bishops alive), heal casts,
ally barriers and the barrier damage absorbed. A **gravebow / bone colossus**
line reports Gravebow volleys, split volleys and their extra arrows, pierce
hits (`gravebow_pierce_hits`) and damage, curses applied / refreshed and the
curse bonus damage (`curse_bonus_dmg`), and the Colossus's damage, stomps,
taunted enemies (`colossus_taunts`) and shrapnel bursts, hits and damage. These numbers
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
300 px when nothing presses it. One **class** line per later summon class
lists its level, alive / capacity, deaths, damage by source (attack and
special) and its special counters: `abom_stomps` / `abom_stomp_hits`,
`rogue_dashes` / `rogue_dash_hits` (plus `dmg_rogue_bleed`),
`gargoyle_swoops` / `gargoyle_swoop_hits`, and `frost_deep_freezes`,
`frost_freezes` (enemies frozen), `frost_boss_freezes`,
`frost_frozen_seconds` and `frost_chills`. A **winter revenant** line counts the
Winter Revenant's shatters (and those skipped by the per-tick cap), shatter
hits and damage, death novas, nova hits, nova freezes and nova damage
(`wr_*` stats, `dmg_winter_revenant_shatter` / `_nova`). The stuck check also counts a
special still running after 4 s (a dashing or airborne unit) and any dash or
landing that ends inside an obstacle; specials cancelled by a recall are
reported too. The **army stance** line says how the stance was driven
(forced, bot switching or the Escort baseline) and lists, per stance, the
seconds held, times entered, kills, army damage taken, hard recalls and the
unit spread (largest and mean distance from the necromancer), plus the
number of switches.

Every policy also uses the **dash and the ultimate**: Grave Step when 3+
enemies touch a 45 px circle around the necromancer, when he was hit in the
last 0.6 s while in danger, or to leave a boss / stage telegraph, toward the
safest of 12 directions (clear length, enemies and danger at the landing
point, the flee direction); Dread Rally once the meter is full and he is in
danger, the stage boss is alive, or the army is badly hurt (average HP under
60% or under 70% of its capacity alive). The **grave step** line reports
dashes and why the bot took them (`bot_dash_crowd` / `_hit` / `_telegraph`),
`dash_hits_avoided` (hits ignored during the dash i-frames), blocked and
shortened steps and the average length; the **dread rally** line reports
rallies, every meter fill time, `rally_knockbacks`, summons called back
(`rally_recalled`), `rally_heal`, the minion damage dealt under the buff
(`rally_minion_dmg`) with the share its +40% damage added, and the buff
uptime.

### Continuous integration and builds

`.github/workflows/ci.yml` runs on every push and pull request:

1. **test:** imports the project with Godot 4.3 headless and runs the full 20-minute autotest with the naive and
   army policies on the Graveyard, then once on the Crimson March (`--stage=crimson_march`) and once in the
   Sanctum (`--stage=sanctum --policy=army`) (`--quit-after 15000`, at most 10 wall-clock minutes per run,
   40 minutes for the job).
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

- **Balance is checked only against the autotest bots.** The v0.3 pass, before
  the priest split and the newer content (`--mortal`; after the
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
  Alaric only about 1 run in 4. The combined pass below supersedes these
  numbers.
- **Combined balance pass** (all content together, `--mortal`, meta none
  unless noted; 16 seeds for army / naive and 8 for summon and meta max on
  each stage; details and the baseline in GDD §15.0). The **army** bot never
  dies before 0:00 and always kills the boss on both stages: Graveyard lowest
  HP 101-116, Sir Alaric in about 111 s, build complete at about 16:18
  (16:00-17:18); Crimson March lowest HP 70-112, Marshal Vael in about
  139 s, build complete at about 16:11 (15:15-17:00). 26 of 32 (Graveyard)
  and 24 of 32 (march) evolutions land at 10-14 min, with 5-7 / 5-10 chests
  and about 456 / 559 Soul Ash. The **summon** bot kills the boss in 8/8 and
  7/8 runs (one march run starved and died at 19:16); Liches deal about 30%
  of its damage (at most 38% in one run). At **meta max** every bot kills
  both bosses and the Reckoning still ends every run, 23-43 s past 0:00.
- **Naive builds are still below their targets** (dies 20-40%, kills the
  boss 25-50%): on the Graveyard the naive bot dies before 0:00 in 8 of 16
  runs and kills Sir Alaric in 3 of 16; on the Crimson March it dies in 11
  of 16 and never kills Marshal Vael (baseline: 4 of 8 / 0 of 8 and 3 of 8 /
  0 of 8). With 15 actives for 6 slots it spreads over many level-1 items,
  and builds without a priest or a damage core starve (levels 21-56 at
  20:00 instead of about 66). Corpse
  Explosion / Grave Eruption, Plague Cloud and the mages carry most naive
  runs that do well: area spells feed on the packed crowds weak armies let
  build up.
- A Rogue's bleeds stop if that rogue dies. Bone Spear needed an aim assist:
  pure movement aim missed almost everything while kiting.
- Two stages so far (the Sanctum of Judgment is next), both 20-minute runs
  (the GDD's lower bound). On the **Crimson March** the terrain changes at
  each battle zone rather than scrolling (the clock drives the march).
- Arrows and spells fly over obstacles (no line-of-sight checks).
- Eclipse Ward usually arrives late (15:00-19:00) and only in builds that
  take Orb Shield. No evolution is granted before 8:00 elapsed.
- Since every evolution needs its passive at Lv 5, builds that level the
  paired passive late evolve late: the army bot's Void Barrage now comes in
  2 of 4 seeds at 16:30-17:10 (before: 4 of 4 at 12:45-14:00); the spell
  bot's Abyssal Detonation and Eclipse Ward land at 8:43-13:00 (GDD §15.0).
  Not retuned yet (final balance pass).
- No ultimate, dash, mid-run saves or skins yet. The difficulty levels and
  run modifiers have first-pass numbers checked only with the autotest bots
  (see GDD §15.0), and no difficulty is locked. Army bot, `--mortal`:
  Initiate (4 seeds) lowest HP 106-114 vs 37-109 on Necromancer; Deathlord
  (6 seeds) always reaches 0:00 but kills Sir Alaric only 1 time in 6, with
  one run surviving on 1 HP. The Soul Ash
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
autotest stats; give the horde a feel pass (formation spacing,
warrior wall shape) with a human player.

**Phase 2 – Graveyard vertical slice (mostly done):** playtest with humans;
retune Void Barrage and the boss; the summon evolutions the later horde
passives point to (Cathedral Horror, Shadow Reaper, Winter Revenant; the
Gravebow and Bone Colossus are in); saves; density and minion-HP-bar settings (§38).

**Phase 3 – Campaign:** the Crimson March and Marshal Vael are in (a human
playtest and balance pass are next); the Sanctum of Judgment and Grand
Inquisitor Seraphine, the remaining enemies (Radiant Inquisitor, Sanctified
Sentinel, High Confessor), Soul Ash balance against the full-length stage, the
real achievement unlocks, skins (the pre-run setup screen can take a skin
choice next to the difficulty and modifiers).

**Phase 4 – Polish:** real art and animation, audio, accessibility, full
controller UX, profiling on target hardware (§40 stress scenarios), balance.
