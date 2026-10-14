# NECROPATHY: Game Design Document

| | |
|---|---|
| **Document** | Formal Game Design Document (GDD) |
| **Source version** | Spec v0.2, October 2026 (Part I: GDD v0.1; Part II: Autonomous Horde Technical Design v0.2) |
| **Status** | Pre-production / prototype |
| **Genre** | Dark fantasy, single-player action roguelite / bullet heaven / horde survival |
| **Platform** | PC first (Steam) |
| **Preferred engine** | Godot 4 (alternative: Unity) |

> **Source of record.** This document reorganizes and formalizes the raw design spec kept alongside it at
> [`docs/Gravebound_Complete_Game_Design_and_Horde_Spec.txt`](./Gravebound_Complete_Game_Design_and_Horde_Spec.txt).
> That plain-text file remains the **source of record**. If this GDD and the raw spec disagree, the raw spec wins
> and this document should be corrected. Nothing here adds design decisions; gaps are listed in
> [Open Questions](#15-open-questions) instead of being filled in.

> **Tuning disclaimer (from source).** All figures are **prototype tuning targets, not tested balance values.**

---

## Pitch

**Necropathy** is a top-down dark-fantasy horde-survival roguelite in which you play a necromancer hunted by the
Crimson Covenant, a fanatical holy order bent on eradicating necromancy. You start alone and fragile, armed with a
single shadow spell, and over a 20–30 minute run you raise an autonomous undead army of skeleton warriors, archers,
mages and priests that fights, heals and regroups on its own while you only steer the necromancer and pick upgrades.
Across a three-stage campaign the power dynamic flips: defend your graveyard, march on the crusaders' compound, then
storm its sanctum and destroy their leader. **Begin as the hunted. Raise the fallen. Become the army. Extinguish the
crusade.**

---

## Table of Contents

1. [Vision and Pillars](#1-vision-and-pillars)
2. [Core Loop](#2-core-loop)
3. [Player Necromancer and Controls](#3-player-necromancer-and-controls)
4. [Undead Horde](#4-undead-horde)
   - [4.1 Scope and Boundaries](#41-scope-and-boundaries)
   - [4.2 Summon Classes](#42-summon-classes)
   - [4.3 Army Capacity and Composition](#43-army-capacity-and-composition)
   - [4.4 Summon Lifecycle and Spawning](#44-summon-lifecycle-and-spawning)
   - [4.5 Replenishment](#45-replenishment)
   - [4.6 Leash and Recall](#46-leash-and-recall)
   - [4.7 Finite State Machine](#47-finite-state-machine)
   - [4.8 Soft Formation and Steering](#48-soft-formation-and-steering)
   - [4.9 Target Acquisition and Scoring](#49-target-acquisition-and-scoring)
   - [4.10 Class Behaviors and Heal Formula](#410-class-behaviors-and-heal-formula)
   - [4.11 Shared Army Coordination and Overkill Reservation](#411-shared-army-coordination-and-overkill-reservation)
   - [4.12 Summon Skill Progression](#412-summon-skill-progression)
   - [4.13 Illustrative Balance Sandbox](#413-illustrative-balance-sandbox)
   - [4.14 Horde Performance Strategy](#414-horde-performance-strategy)
5. [Spells and Abilities](#5-spells-and-abilities)
6. [Passives, Evolutions and Synergies](#6-passives-evolutions-and-synergies)
7. [Enemies and Bosses](#7-enemies-and-bosses)
8. [Stages and Wave Timelines](#8-stages-and-wave-timelines)
9. [Progression](#9-progression)
10. [UI and HUD](#10-ui-and-hud)
11. [Art Direction and Color Language](#11-art-direction-and-color-language)
12. [Audio](#12-audio)
13. [Technical Architecture and Performance Budgets](#13-technical-architecture-and-performance-budgets)
14. [Development Roadmap](#14-development-roadmap)
15. [Open Questions](#15-open-questions)

---

## 1. Vision and Pillars

### 1.1 High Concept

| Attribute | Value |
|---|---|
| Title | NECROPATHY |
| Genre | Dark fantasy, single-player action roguelite / bullet heaven / horde survival |
| Perspective | Top-down 2D or 2.5D |
| Platform | PC first (Steam) |
| Run length | 20–30 minutes per level |
| Inspirations | Vampire Survivors, Brotato, Army of Ruin, Warcraft III undead faction |

The player is a necromancer fighting an advancing fanatical holy order, the **Crimson Covenant**. The Covenant is
aesthetically inspired by the Scarlet Crusade from World of Warcraft but is designed as an **original faction**. The
player begins alone and hunted, gaining shadow spells and an increasingly powerful autonomous undead army. The
campaign reverses the power dynamic: defend a graveyard, besiege the crusaders' compound, then invade the interior and
defeat their leader.

**Core fantasy:** *Begin as the hunted. Raise the fallen. Become the army. Extinguish the crusade.*

### 1.2 Campaign at a Glance

| # | Stage | Role in the arc |
|---|---|---|
| 1 | The Desecrated Graveyard | Defend against the Covenant invasion |
| 2 | The Crimson March | Advance with the undead against the outer compound |
| 3 | The Sanctum of Judgment | Invade the compound for the final boss |

Full details: [Stages and Wave Timelines](#8-stages-and-wave-timelines).

### 1.3 Design Pillars

1. **The Army Is Your Weapon.** Warriors, archers, mages and priests play distinct frontline, ranged, area-damage and
   support roles. Summons are *the* feature, not merely cosmetic projectiles.
2. **Unholy Power versus Divine Zeal.** The enemy uses holy magic, military formations, healing, protective wards and
   specialized undead hunters.
3. **Build Diversity.** Mass skeletons, elite undead, destructive shadow magic, sustain/defensive builds and hybrids
   should all be viable.
4. **Escalating Spectacle.** The game evolves visibly from a fragile caster into an army leader amid large-scale
   magical conflict.

### 1.4 Key Design Decisions to Preserve

These are locked decisions from the source spec (section 43):

- Autonomous horde, **not** manual RTS commands.
- Four main classes: warrior, archer, mage, priest.
- Shadow Bolt, Shadow Orb Shield and Shadow Blast remain core standalone spells.
- Enemy forces consist of crimson holy paladins, priests and infantry.
- Progression runs through graveyard defense, compound assault and compound-interior final boss.
- The pre-run menu chooses level, difficulty, modifiers and skins.
- Readability and performant mass combat take precedence over simulation.
- Pure summoner, pure shadow and hybrid strategies should each be viable.

---

## 2. Core Loop

### 2.1 Run Loop

1. Choose level, skin, difficulty and modifiers at the main menu.
2. Begin the run with a **single starting skill**.
3. Move to survive as enemies approach continuously.
4. Equipped shadow spells cast automatically and summons deploy automatically.
5. Enemies drop **XP crystals** and sometimes other resources.
6. Level up and choose **one of three randomized upgrades**.
7. New enemies, elites, events and environmental threats arrive **by time**.
8. Build synergies, evolve abilities and replenish fallen summons.
9. Defeat the final stage boss to unlock the next chapter, currency and cosmetics.
10. Spend earned **Soul Ash** on permanent upgrades, then replay.

### 2.2 Player Agency

The player **only** moves the necromancer and selects run upgrades. Combat, spells, summons, targeting and healing are
all automatic. No manual unit selection, unit positioning or aiming is required. The horde must feel coordinated
rather than perfectly omniscient, and be predictable enough that **player positioning matters**.

---

## 3. Player Necromancer and Controls

### 3.1 Controls

| Input | Action |
|---|---|
| WASD | Move |
| Mouse | Menu navigation |
| Shift | Optional unlocked dash |
| Space | Optional ultimate |
| Esc | Pause / settings |
| Tab | Expand army information |
| Controller left stick | Move |
| Controller A / Cross | Confirm |

### 3.2 Player Statistics

| Stat | Governs |
|---|---|
| Max Health | Player survivability |
| Movement Speed | Movement across battlefield |
| Armor | Physical damage mitigation |
| Shadow Resistance | Hostile magic damage mitigation |
| Spell Power | Shadow ability damage |
| Minion Damage | Summon damage |
| Minion Health | Summon survivability |
| Summon Capacity | Max active undead |
| Cooldown Reduction | Ability intervals |
| Area of Effect | Spell radii |
| Duration | Temporary effect duration |
| Pickup Radius | Experience collection distance |
| Luck | Reward probability |

Base values for these stats are not specified in the source (see [Open Questions](#15-open-questions)).

### 3.3 Ability Slots

| Slot type | Count | Notes |
|---|---|---|
| Active abilities | 6 | Automatic summons and spells |
| Passive abilities | 6 | See [Passives](#6-passives-evolutions-and-synergies) |
| Ultimate | 1 (optional) | Bound to Space |

- If active slots fill up, level-up offers switch to existing skills and passives.
- Skills have **five normal levels**.
- Evolution requires a **matching passive** and a **special elite reward**.

### 3.4 Character Skins

Skins are cosmetic and carry no default mechanical bonuses. See [Art Direction](#114-character-skins).

*Prototype (see 15.0, "Playable characters"):* playable **characters** are separate from skins: each starts with its
own spell and has an innate passive and stat modifiers. Four of the skin names below became characters.

---

## 4. Undead Horde

### 4.1 Scope and Boundaries

Every undead unit spawns, follows, targets, attacks, heals, retreats and regroups **without manual commands**.

**Excluded from current scope:** RTS selection, unit click-to-move, manual focus fire, unit inventories, persistent
named companions, tactical pause orders.

### 4.2 Summon Classes

| Class | Role | Behavior summary | Upgrade paths | Evolution |
|---|---|---|---|---|
| **Skeleton Warrior** | Frontline | Basic rusted-sword melee attacker; engages enemies threatening the player. Moderate HP, modest damage, limited body-block effect. | Extra population, more HP/damage, shields and armor, cleave | **Dreadguard Legion**: armored skeleton fighters with retaliatory strikes and cleaving attacks |
| **Skeletal Archer** | Ranged sustained DPS | Keeps distance, fires physical arrows, fragile. | Increased count, faster attack, piercing arrows, cursed arrows | **Gravebow Company**: splitting/piercing arrows and curses |
| **Undead Mage** | Magical AoE | Targets clustered enemies with shadow projectiles or explosions. | More mages, damage, splash, Soulburn, larger AoE | **Lich Conclave**: chain explosions and shadow storms |
| **Undead Priest** | Healing and support | Corrupted former cleric; heals allied undead, occasionally shields the player, casts minor unholy offense when no healing is needed. | More priests, healing amount, radius, defense buffs | **Profane Bishop**: area healing aura and unholy damage pulse |

**Possible future summons** (not in current scope):

| Summon | Role |
|---|---|
| Bone Golem | Tank |
| Banshee | Debuffer |
| Death Knight | Elite melee / buff commander |
| Corpse Abomination | Durable monster |

#### Base Unit Data (initial prototype only)

| Stat | Warrior | Archer | Mage | Priest |
|---|---|---|---|---|
| HP | 60 | 30 | 35 | 40 |
| Attack damage | 10 | 8 | 14 | 3 |
| Attack interval | 1.2 s | 1.6 s | 2.5 s | 2.0 s |
| Preferred range | 22 px | 170 px | 145 px | 150 px |
| Movement speed | 85 | 95 | 82 | 90 |
| Level 1 count | 2 | 1 | 1 | 1 |
| Unit radius | 10 px | 9 px | 10 px | 10 px |
| Replacement interval | 5 s | 8 s | 12 s | 15 s |

- **Priest offense** is used only when no heal is needed.
- **Priest healing example** (balance sandbox): **8 HP per cast at a 2.0 s interval**, subject to tuning and skill level.
- **Coordinate baseline:** ~**32 px per world tile**.

### 4.3 Army Capacity and Composition

```
Army cap = sum of equipped summon abilities' class caps + global bonuses
```

| Benchmark | Count |
|---|---|
| Level-one composition with all four summon abilities | 5 total summons (2 + 1 + 1 + 1) |
| Target common late-game composition | 20–40 undead |
| Illustrative late-game composition ([4.13](#413-illustrative-balance-sandbox)) | 18 summons |

### 4.4 Summon Lifecycle and Spawning

```
SPAWN -> ORIENT -> TARGET -> ENGAGE/REPOSITION -> REPEAT -> DIE/DESPAWN
```

**A summon is created when:**
- the skill is learned;
- capacity increases;
- a timer replaces a casualty;
- a temporary summon effect activates.

**Spawn location rules:**
- Ground point ~**35–80 px** from the player.
- Navigable, not inside solid world geometry.
- Preferably not inside hazards or an enemy collider.
- **Failed spawns retry** rather than consuming capacity or cooldown.

**On death:**
1. Stop AI and attacks.
2. Deregister from targetable sets.
3. Release target and anchor reservations.
4. Play death FX.
5. Return the unit to the pool.
6. Queue a replacement.

Corpses are **cosmetic and non-collidable**.

### 4.5 Replenishment

Each parent summon ability controls **its own replacement queue** and refills **sequentially, one unit per interval**.

| Class | Replacement interval |
|---|---|
| Warrior | 5 s |
| Archer | 8 s |
| Mage | 12 s |
| Priest | 15 s |

*Example:* if an ability can hold 5 warriors and only 3 survive, the missing 2 spawn one at a time, one per interval.
The timer resets to 0 while the ability is at capacity, and only resets after a **successful** spawn (see the
replenishment pseudocode in [13.6](#136-behavior-pseudocode)).

### 4.6 Leash and Recall

| Threshold | Distance from player | Behavior |
|---|---|---|
| Engagement zone | ~220 px | Normal combat area |
| Soft recall | 320 px | Unit enters `RETURNING` |
| Hard recall | 650 px | Spectral fade / teleport for stranded units |

Hard recall should be **rare**. Long pursuits must always resolve via return or recall.

### 4.7 Finite State Machine

**States:** `SPAWNING`, `FOLLOWING`, `ACQUIRING`, `ENGAGING`, `REPOSITIONING`, `CASTING`, `RETREATING`, `RETURNING`,
`DEAD`.

| From | To | Condition |
|---|---|---|
| SPAWNING | FOLLOWING | Emergence finishes |
| FOLLOWING | ACQUIRING | A viable enemy is found |
| ACQUIRING | ENGAGING | Target chosen |
| ACQUIRING | FOLLOWING | No target chosen |
| ENGAGING | CASTING / attack | In valid range and ready |
| ENGAGING | REPOSITIONING | Line of sight or range inadequate |
| ENGAGING | RETURNING | Target pursuit exceeds leash |
| ENGAGING | ACQUIRING | Target dies |
| REPOSITIONING | ENGAGING | Firing position achieved |
| RETURNING | FOLLOWING | Re-enters army region |
| Any alive state | DEAD | Zero HP |

**Per-update priority order** (from the unit pseudocode): dead check, then hard recall, then soft recall, then
continue an in-progress cast, then act on a valid target (attack or reposition), otherwise acquire a target
(`ENGAGING`) or fall back to `FOLLOWING`.

#### Suggested Update Rates

| System | Rate |
|---|---|
| Movement physics | 60 Hz |
| General AI decisions | 5 Hz |
| Target checks | 3–5 Hz |
| Formation anchors | 4 Hz |
| Player threat checks | 5 Hz |

AI work is **staggered among unit groups** to avoid synchronized spikes.

### 4.8 Soft Formation and Steering

Formation uses **non-rigid circles around the player, weighted toward threats**. Bands are *preferences*; role-based
behavior overrides anchors when warranted.

| Band | Radius from player | Occupants |
|---|---|---|
| Inner defense band | 35–85 px | Warriors |
| Midline | 85–155 px | Archers and mages |
| Support band | 60–125 px | Priests |

- Assign **player-relative angular slots** spread across rings.
- Add slight **stable random offsets** to avoid perfect geometry.
- **Threat direction** biases warriors toward approaching enemies; support units avoid dangerous crowd densities.

#### Steering

The steering vector combines formation attraction, target pursuit, ally separation, obstacle avoidance and threat
avoidance, **weighted and clamped**. Example weights (tuneable data values, not strict physics constants):

| Weight | Warrior | Priest |
|---|---|---|
| Pursuit | 1.0 | 0.0 while healing |
| Formation | 0.35 | 0.7 |
| Ally separation | 0.8 | 0.8 |
| Obstacle avoidance | 1.2 | 1.2 |
| Threat avoidance | 0.1 | 1.0 |

#### Collision Matrix

| Pair | Physical collision | Notes |
|---|---|---|
| Player ↔ friendly undead | **No** | Friendly units must never physically trap the player |
| Friendly ↔ friendly | **No** hard collision | Steering separation only |
| Friendly ↔ enemy | **No** blocking (initial prototype) | Enemies can still hit summons via attacks and overlapping hit detection |
| Units ↔ solid world | **Yes** | |
| Corpses | **No** | Cosmetic only |

#### Navigation

- **Open arenas** use steering.
- **Indoor halls** may use navigation for major routes, local avoidance for small obstacles, and recall if pathing
  fails.
- **Never** recalculate full paths every physics frame.

### 4.9 Target Acquisition and Scoring

Each unit queries the shared **SpatialIndex** for living, targetable candidate enemies within its acquisition range.
Ranged attacks may require line of sight.

**Target score** (all constituent measures normalized):

```
score = distance_value * Wd
      + threat_to_player * Wt
      + role_priority   * Wr
      + tactical_value  * Wv
      - overkill_penalty
```

#### Class Target Preferences (highest priority first)

| Class | Priority order |
|---|---|
| Warrior | 1. Enemies attacking the player  2. Close-range intruders  3. Accessible ranged casters  4. Nearest available enemy. *Don't chase distant targets while the necromancer is surrounded.* |
| Archer | 1. Exposed chaplains / healers  2. Enemy archers / casters  3. Near-death finishable enemies  4. Unblocked nearby targets |
| Mage | 1. Largest valuable AoE cluster  2. Groups with support/elite targets  3. Groups closing on the player  4. Isolated units when needed. Scores potential impact positions, generally based on enemy centers and nearby units. |
| Priest | 1. Critically injured necromancer, **only if** the priest skill explicitly allows player healing  2. Allies below **35% HP**  3. Allies with large missing normalized HP  4. Large damaged clusters, if AoE heal is unlocked  5. Minor offense when nothing needs healing |

#### Target Commitment

- Hold a reasonable target for **≥ 1 s**.
- Switch **instantly** on target death or invalidity.
- Switch **early** only for a significantly greater threat.
- Acceptance criterion: units must not oscillate rapidly between targets.

### 4.10 Class Behaviors and Heal Formula

#### Warrior

Acquire close threat → approach within ~**22 px** → melee swing → hit lands on animation impact → cooldown → repeat.
Intercept enemies within ~**80 px** of the player; don't stray excessively.
*Dreadguard Legion evolution:* armor, cleave, reactive strikes, larger silhouette.

#### Archer

Choose ranged-priority target → move into ~**170 px** preferred range → check line of sight → fire arrow → cooldown.
If a threatening enemy is within ~**45 px**, kite/retreat if space permits; otherwise keep firing.
*Gravebow Company evolution:* piercing, cursed arrows, volleys, longer acquisition.

#### Mage

Collect nearby enemy candidates → score circular explosion opportunities based on counts, clustered high-value units
and proximity to the player → cast at best position → projectile/impact → splash and optional **Soulburn** → cooldown.
*Lich Conclave evolution:* larger blasts, chains, curses, periodic shadow-storm AoE.

#### Priest

Collect damaged nearby allies → heal the target with highest weighted urgency → approach range → cast → apply
**capped** heal → cooldown → seek next.

**Proposed normalized healing score:**

```
heal_priority = 0.6 * (missing health fraction)
              + 0.2 * (normalized missing raw HP)
              + 0.2 * (tactical role priority)
```

- Warriors may get a small role bonus.
- **Never heal full-HP allies.**
- If player healing is enabled, a critical necromancer has **top priority**.
- *Profane Bishop evolution:* group heal aura, defensive blessing and damage pulse.

### 4.11 Shared Army Coordination and Overkill Reservation

The **HordeDirector** holds:
- the living unit registry;
- class caps;
- anchor ownership;
- a local player-threat summary;
- summon queues;
- buffs;
- rough pending ranged-damage reservations.

**Overkill reservation:** the HordeDirector tracks rough committed ranged damage per target and **redirects new shots
when the target is already expected to die**. This is approximate by design, not exact. It feeds the
`overkill_penalty` term of the target score.

#### Threat Categories

| Category |
|---|
| Immediate melee |
| Ranged cluster |
| Holy support |
| Elite / boss |
| Environmental hazards |

During player danger, raise warrior defense priority while archers/mages keep providing damage and priests keep
healing. Once threats disappear, return to formation band preferences.

#### Boss Engagement Rules

| Class | Behavior against bosses |
|---|---|
| Warriors | Engage but respect leash |
| Archers | Prioritize the boss unless an urgent support target appears |
| Mages | Target boss + adds for useful splash |
| Priests | Sustain allied units |

Bosses may suppress or kill squads with **clear telegraphs** but must **never permanently disable summon abilities**.

### 4.12 Summon Skill Progression

Example: **Skeleton Warrior, Levels 1–5**

| Level | Change | Warriors at this level (cumulative) |
|---|---|---|
| L1 | 2 skeleton warriors | 2 |
| L2 | +1 warrior, +10% damage | 3 |
| L3 | +2 warriors, +15% HP | 5 |
| L4 | +1 warrior, +20% attack speed | 6 |
| L5 | +2 warriors, +20% HP | **8** (before global capacity bonuses) |

**Upgrade application rules:**
- Current summons **recalculate effective attributes** upon upgrades.
- **Health percentage is preserved** on max-HP increase unless healing explicitly occurs.
- **Recommended stacking:** add like-category bonus percentages, then multiply separate categories. The formula must be
  consistent and **player-visible**.

Level tables for Archer, Mage and Priest are not yet defined (see [Open Questions](#15-open-questions)).

### 4.13 Illustrative Balance Sandbox

Illustrative late-game composition: **8 warriors + 5 archers + 3 mages + 2 priests = 18 summons.**
Example bonuses: **+50% power** and **+30% attack speed**.

```
Approximate theoretical DPS = sum(count * damage / interval)
                            * (1 + power_bonus)
                            * (1 + speed_bonus)

Priest baseline healing     = priest_count * 8 / 2.0
                            * (1 + healing_bonus)
                            * (1 + cast_speed_bonus)
```

| Class | Count | Damage / interval (source) | Per-unit DPS *(derived)* | Group DPS *(derived)* |
|---|---|---|---|---|
| Warrior | 8 | 10 / 1.2 | 8.33 | 66.67 |
| Archer | 5 | 8 / 1.6 | 5.00 | 25.00 |
| Mage | 3 | 14 / 2.5 | 5.60 | 16.80 |
| Priest | 2 | 3 / 2 | 1.50 | 3.00 |
| **Sum (unbuffed)** | **18** | | | **≈ 111.5** |
| **With +50% power, +30% attack speed** | | | | **≈ 217.4** |

*Derived* columns are arithmetic applied to the source formula for reference; they are not additional design
targets. Priest baseline healing for 2 priests with no bonuses is 2 × 8 / 2.0 = **8 HP/s** (derived). The source notes
these idealized outputs **ignore** hit rate, armor, animation, targets, splash, overheal, deaths, healing downtime and
replenishment. (Priests also only attack when no heal is needed, so their DPS term is an upper bound.)

### 4.14 Horde Performance Strategy

Summary; full budgets in [13.4](#134-performance-budgets-and-optimization).

- Shared **spatial hash / 2D spatial partitioning** for ally, enemy and AoE queries; no full enemy scans per unit.
- **Pool** summons, enemies, projectiles, combat text, effects and corpses; reset all mutable state, references,
  timers, effects and signal connections on reuse.
- **Stagger** target/strategy decisions (see [update rates](#suggested-update-rates)); physics motion stays responsive.
- **Lightweight direct steering**; pathfind only on target/path changes.
- **Approximate** overkill reservation instead of exact damage prediction.
- Do not broadcast movement every frame globally.

---

## 5. Spells and Abilities

### 5.1 Core Shadow Spells

| Spell | Behavior | Upgrade paths | Evolution (with passive) |
|---|---|---|---|
| **Shadow Bolt** | Automatically fires at a nearby enemy at intervals. | Damage, extra projectiles, speed and pierce, damage-over-time curse | **Void Barrage** (+ Soul Conduit): rapid piercing bolts that split on impact |
| **Shadow Orb Shield** | Protective orbs orbit the necromancer, damage approaching enemies and intercept a limited number of hostile projectiles. Interception is **charge- or cooldown-limited** to avoid invulnerability. | Orb count, orbit speed, radius, damage, interception | **Eclipse Ward** (+ Warding Ritual): rotating barrier and periodic damage pulses |
| **Shadow Blast** | Automatically creates an AoE explosion around the player. | Damage, radius, cooldown, slow | **Abyssal Detonation** (+ Abyssal Focus): double-hit blast and short enemy pull |

Numeric spell stats and per-level tables are not yet specified (see [Open Questions](#15-open-questions)).

### 5.2 Spell–Horde Interactions

| Spell | Current interaction | Future synergy direction |
|---|---|---|
| Shadow Bolt | Can preferentially hit enemies threatening warriors | Curse marks can increase minion damage |
| Shadow Orb Shield | Protects the player from threats slipping through the frontline | Upgrades may grant nearby minions defense |
| Shadow Blast | Slows/clusters nearby foes, creating intercept opportunities | Can buff minion move speed or reduce replacement timers |

### 5.3 Candidate Additional Spells

| Spell | Concept |
|---|---|
| Grasp of the Damned | Hands from the ground slow/root enemies |
| Soul Siphon | Nearby damage and **capped** lifesteal |
| Death Nova | Wave dealing bonus damage to cursed enemies |
| Grave Eruption | Bone spikes create damaging ground zones |

*Prototype (see 15.0, "Four more necromancer spells"):* Soul Siphon is a spell; Grave Eruption is the evolution of
Corpse Explosion and Death Nova is the burst that ends each Pestilence cloud (Plague Cloud's evolution). Bone Spear,
Corpse Explosion and Plague Cloud are the prototype's own additions. Grasp of the Damned is not implemented.

*Prototype (see 15.0, "Five more spells"):* five owner-approved spells take the game to 12: **Death Mark**,
**Bone Wall**, **Soul Chains**, **Wither** and **Raise Dead**, evolving into Doom Brand, Charnel Bastion, Chains of
the Damned, Necrotic Blight and Legion of Bones.

### 5.4 Summon Abilities

The four summon abilities (Skeleton Warrior, Skeletal Archer, Undead Mage, Undead Priest) occupy **active** slots like
spells. Their behavior is specified in [Undead Horde](#4-undead-horde).

### 5.5 Movement and Ultimate Abilities

| Ability | Input | Status |
|---|---|---|
| Dash | Shift | Optional, unlocked |
| Ultimate | Space | Optional, 1 slot; cooldown shown on HUD |

No specific ultimate or dash behavior is defined in the source. (Resolved in 15.0: **Grave Step** is the dash and
**Dread Rally**, charged by kills rather than a cooldown, is the ultimate.)

---

## 6. Passives, Evolutions and Synergies

### 6.1 Evolution Recipes

Evolution requires the base skill, its **matching passive**, and a **special elite reward**.

| Base ability | + Passive | = Evolution |
|---|---|---|
| Skeleton Warrior | Bone Plating | Dreadguard Legion |
| Skeletal Archer | Unholy Precision | Gravebow Company |
| Undead Mage | Forbidden Knowledge | Lich Conclave |
| Undead Priest | Dark Benediction | Profane Bishop |
| Shadow Bolt | Soul Conduit | Void Barrage |
| Shadow Orb Shield | Warding Ritual | Eclipse Ward |
| Shadow Blast | Abyssal Focus | Abyssal Detonation |

### 6.2 Global Horde Passives

| Passive | Effect |
|---|---|
| Grave Dominion | Capacity |
| Necrotic Vigor | Max minion health |
| Dark Command | Minion attack damage / speed |
| Soul Recycling | Faster replacement |
| Unholy Resilience | Armor / AoE resistance |
| Bound Souls | Speed and leash/recall improvements |

### 6.3 Army Synergies

| Synergy | Requirement | Effect |
|---|---|---|
| Shieldwall of the Damned | Warriors + Priests | Priest barriers on frontline |
| Volley of the Fallen | Archers + Mages | Mage marks cause archer bonus damage |
| March of the Deathless | 3 different summons | Move speed + regeneration |
| The Unholy Host | All 4 main summons | Army-wide attack speed / resilience aura and visual effect on summon |

### 6.4 Stacking Rules

Add like-category bonus percentages, then multiply separate categories. The resulting formula must be consistent and
visible to the player (the level-up panel shows actual stat deltas; see [10.4](#104-level-up-panel)).

---

## 7. Enemies and Bosses

### 7.1 Faction: The Crimson Covenant

A fanatical, original religious-military order dedicated to eradicating necromancy. Scarlet Crusade-inspired
aesthetic: **crimson and ivory tabards, polished silver armor, cloaks and religious insignia**. Their magic appears
**radiant gold/white**, contrasting the player's **purple/green** necromancy.

### 7.2 Roster

| Enemy | Role | Description | Horde interaction rules |
|---|---|---|---|
| Covenant Recruit | Basic infantry | Weak basic infantry, mass waves | — |
| Crimson Footman | Armored melee | Moderate damage resistance | — |
| Zealous Archer | Ranged | Ranged projectiles | Preferred archer target (enemy archers/casters) |
| Covenant Chaplain | Healer | Heals enemy allies | Heals other enemies; increases ranged-unit target preference |
| Purifier | Anti-undead | Bonus damage versus undead summons | Prioritizes undead, deals minion bonus damage; relatively vulnerable to ranged focus |
| Templar Knight | Heavy melee | Heavy charging melee; knockback / disruption | Charges and disrupts melee army, threatening the player through gaps |
| Radiant Inquisitor | Elite caster | Creates holy damage zones | Produces holy hazards; at later difficulty may briefly suppress replacement locally, with telegraphed visuals |
| Banner Bearer | Buffer | Buffs nearby Covenant soldiers | Buffs nearby soldiers; elevated target priority |
| Sanctified Sentinel | Construct | High-armor construct with sweeps | — |
| High Confessor | Elite priest | Healing, shielding and limited revival | — |

Numeric enemy stats (HP, damage, speed, XP value) are not yet specified (see [Open Questions](#15-open-questions)).

### 7.3 Faction Tactics

- Infantry protect archers and priests in advancing formations.
- Holy healers demand target prioritization.
- Purifiers attack the horde to exploit its reliance on summons.
- Banners buff formations until destroyed.
- Holy suppression / consecration zones apply **localized, temporary** pressure.
- Boss suppression must allow normal replacement afterward.

### 7.4 Stage Hazards and Objectives Owned by the Enemy

| Entity | Stage | Function |
|---|---|---|
| Consecrated graves | 1 | Priests attempt to consecrate selected graves; failure to interrupt creates hazardous anti-undead spaces |
| Outposts | 2 | Spawn reinforcements until destroyed |
| Holy Ward Generators | 2 | Damage/weaken summons in areas |
| Supply carts | 2 | Optional destruction rewards |
| Ward crystals | 3 | Sanctified chambers punish undead until crystals are destroyed |
| Sacred altars | 3 | Optional/required objectives; destroying them weakens later enemies |
| Cathedral Guardians | 3 | Construct minibosses controlling route access |

### 7.5 Bosses

#### Sir Alaric, the Gravebreaker (Stage 1, at 20:00)

Heavy holy paladin with a two-handed hammer.

| Ability | Effect |
|---|---|
| Consecrated Ground | Persistent radiant zones |
| Hammerfall | Telegraphed overhead smash |
| Divine Charge | Fast linear rush |
| Call to Arms | Reinforcement infantry |
| Judgment of the Dead | Marked AoE that damages allied summons |

**Win:** defeat Alaric. *Story:* the necromancer learns the origin of the crusade and attacks.

#### Marshal Vael, the Crimson Bulwark (Stage 2, at 24:00)

Shield and flaming holy sword.

| Ability | Effect |
|---|---|
| Shieldwall | High frontal damage resistance |
| Crusader's Command | Infantry formation waves |
| Radiant Cleave | Sweeping melee |
| Holy Standard | Buff zone |
| Last Stand | Attack speed boost below **30% HP** |

**Win:** defeat Vael and breach the fortress gates.

#### Grand Inquisitor Seraphine, Voice of the Dawn (Stage 3 final boss, at 22:00)

| Phase | Trigger | Name | Behaviors |
|---|---|---|---|
| 1 | Start | Divine Judgment | Radiant projectiles, delayed holy circles, templars, teleportation |
| 2 | **60% HP** | Avatar of the Dawn | Relic transformation, rotating holy beams, barrages, temporary undead suppression, constructs, safe-zone navigation |
| 3 | **20% HP** | The Last Light | Faster attacks, more hazards, no boss healing support, collapsing arena, final army confrontation |

**Win:** defeat Seraphine and shatter the radiant relic.
*Ending:* the compound falls; other religious orders mobilize, setting up a sequel.

#### Minibosses

| Miniboss | Stage | Notes |
|---|---|---|
| Cathedral Guardians | 3 | Construct minibosses controlling route access (Guardian miniboss at 07:00) |

---

## 8. Stages and Wave Timelines

All stages: run length target **20–30 minutes**. Stage selection is progression-locked initially.

### 8.1 Stage 1: The Desecrated Graveyard

| Attribute | Value |
|---|---|
| Theme | Defense and survival |
| Art | Moonlit cemetery, crypts, broken tombs, dead trees, fog and spectral blue-green lights; red torches and banners advance over time |
| Story | Covenant forces discover the necromancer's burial grounds and attack |
| Boss | Sir Alaric, the Gravebreaker |

**Mechanics**
- **Empowered graves** near the player add temporary reinforcements or improve summon replenishment.
- **Desecration events:** priests attempt to consecrate selected graves; failure to interrupt creates hazardous
  anti-undead spaces.
- **Crypt Defender event:** briefly awaken ancient guardian units.

| Time | Event |
|---|---|
| 00:00 | Recruits |
| 03:00 | Archers and footmen |
| 05:00 | Chaplain elite |
| 08:00 | Purifiers |
| 10:00 | Grave consecration event |
| 13:00 | Templar Knights |
| 15:00 | Major assault |
| 18:00 | Final preparation wave |
| 20:00 | Sir Alaric boss |

### 8.2 Stage 2: The Crimson March

| Attribute | Value |
|---|---|
| Theme | Counteroffensive and siege |
| Art | Roads, devastated settlements, forests, camps, barricades and distant fortress towers |
| Story | The necromancer's army marches toward Covenant headquarters |
| Boss | Marshal Vael, the Crimson Bulwark |

**Mechanics**
- Guided progression through **interconnected battle zones**; outposts spawn reinforcements until destroyed.
- **Holy Ward Generators** damage/weaken summons in areas.
- Destroy enemy **supply carts** for optional rewards.

| Time | Event |
|---|---|
| 00:00 | Patrols |
| 04:00 | Fortified checkpoint |
| 06:00 | Templar ambush |
| 09:00 | Siege outpost |
| 12:00 | Heavy infantry |
| 15:00 | Ward generator |
| 18:00 | Cathedral defenders mobilize |
| 20:00 | Fortress assault |
| 24:00 | Marshal Vael boss |

### 8.3 Stage 3: The Sanctum of Judgment

| Attribute | Value |
|---|---|
| Theme | Final assault |
| Art | Cathedral halls, cloisters, sacred courtyards, stained glass, giant statues, golden mosaics; progressively corrupted as holy wards fall |
| Story | Invade the fortress interior and defeat the Covenant's supreme leader |
| Boss | Grand Inquisitor Seraphine, Voice of the Dawn |

**Mechanics**
- **Sanctified chambers** punish undead until their ward crystals are destroyed.
- **Sacred altars** are optional/required objectives that weaken later enemies.
- **Cathedral Guardians** are construct minibosses controlling route access.

| Time | Event |
|---|---|
| 00:00 | Outer defenders |
| 04:00 | Sanctified chamber |
| 07:00 | Guardian miniboss |
| 10:00 | High Confessor ambush |
| 13:00 | Altar destruction |
| 16:00 | Elite paladins |
| 19:00 | Final sanctuary opens |
| 22:00 | Final boss |

### 8.4 Difficulty Levels

| Difficulty | Effect |
|---|---|
| Initiate | Easier scaling |
| Necromancer | Standard |
| Lich | Increased HP / aggression |
| Deathlord | Hardest, with more elites |

*Prototype (see 15.0, "Difficulty levels"):* numbers in `scripts/data/difficulty_data.gd`; Necromancer is the
standard game.

### 8.5 Optional Run Modifiers

| Modifier | Effect |
|---|---|
| Endless Crusade | +30% enemy spawn rate |
| Hardened Faith | +25% enemy health |
| Divine Fury | +20% enemy damage |
| Purge the Unholy | More Purifiers |
| Scarcity | Reduced healing drops |
| Frail Master | Reduced player starting HP |
| Vengeful Dead | Minion damage up, minion HP down |
| Holy Retribution | Elites emit radiant attacks on death |

Modifier stacking must **show the total reward multiplier**, not hide it.

*Prototype (see 15.0, "Run modifiers"):* all eight are implemented (`scripts/data/run_modifier_data.gd`), chosen on the
pre-run setup screen ([10.2](#102-pre-run-configuration)) together with the difficulty.

---

## 9. Progression

### 9.1 In-Run Progression

```
XP crystals -> level-ups -> three randomized choices
```

- Choices draw from: active abilities, passives, upgrades, or situational boosts.
- **Limited** rerolls, skips and banishes.
- Six active slots, six passive slots, one optional ultimate; once active slots are full, offers shift to existing
  skills and passives.
- Skills have **five normal levels**; evolution requires the matching passive plus a **special elite reward**
  ([6.1](#61-evolution-recipes)).

### 9.2 Persistent Currency: Soul Ash

Earned after battles and spent on permanent upgrades:

| Upgrade tree | Improves |
|---|---|
| Necromancy | Minion cap, health and damage |
| Shadowcraft | Spell damage, cooldown reduction, AoE |
| Survival | Health, armor and movement |
| Fortune | Pickup radius, reward luck and rerolls |

### 9.3 Campaign Unlocks

Defeating a stage's final boss unlocks the next chapter, currency and cosmetics. Graveyard → Crimson March → Sanctum.

### 9.4 Example Achievement Unlocks

| Achievement | Unlock |
|---|---|
| 1,000 Warrior kills | Bone Golem |
| Clear a stage without Shadow Bolt | Alternative starting ability |
| Defeat 500 priests | Priest evolution-related unlock |
| Clear Graveyard on Lich difficulty | The Bone Oracle skin |
| Defeat the final boss with all 4 summons | The Dread Sovereign skin |

---

## 10. UI and HUD

### 10.1 Main Menu

**Visual:** the necromancer in an atmospheric candlelit crypt, with attendants and a live skin preview.

| Menu button |
|---|
| Play |
| Character Customization |
| Upgrades |
| Collection / Codex (**resolved**: the **Codex** screen, see 15.0 "Codex and achievements screen") |
| Achievements (**resolved**: the Codex's Achievements tab, same screen) |
| Settings |
| Exit |

*Prototype (see 15.0, "Menu diorama", "Front door screens", "Title screen", "Codex and achievements screen",
"Credits screen" and "Confirm dialogs"):* the main menu is a living title screen over an animated pixel-art
graveyard at night (the diorama stands in for the candlelit crypt) with six one-word buttons: **Play** (stage
select, then the pre-run setup, which holds Character Customization: the character, its skins, the difficulty,
the run modifiers and Hyper), **Codex** (Collection / Codex and Achievements in one screen), **Ossuary** (the
Upgrades), **Settings**, **Credits** (an extra screen with the font and engine licences) and **Quit** (Exit; asks
first).

### 10.2 Pre-Run Configuration

- Select stage: Graveyard, Crimson March or Sanctum (progression-locked initially).
- Select character skin, difficulty ([8.4](#84-difficulty-levels)) and modifiers ([8.5](#85-optional-run-modifiers)).
- Show the total reward multiplier from stacked modifiers.

*Prototype (see 15.0, "Pre-run setup screen", "Playable characters", "Hyper mode", "Skins", "Pre-run setup layout",
"Stage select vignettes" and "Pre-run setup: the character is the hero"):*
stage select, then one setup screen for the playable character (one per spell, each with its starting spell, an
innate passive and stat modifiers; unlocked by reaching Lv 5 with that spell in any run), its skin, the difficulty,
the run modifiers and the Hyper toggle; the choice is remembered in the save.

### 10.3 In-Run HUD Layout

| Screen region | Contents |
|---|---|
| Top left | Player HP, shields, level |
| Top center | Timer, objective/event indicator, boss HP when applicable |
| Top right | Pause, modifiers, kill count |
| Bottom center | Equipped active/passive icons, levels, ultimate cooldown |
| Bottom left | Army total, class counts and summon capacity |
| Top or bottom edge | XP bar |

**Tab** expands army information.

### 10.4 Level-Up Panel

Combat **pauses**. Three large cards, each showing:
- icon;
- name;
- old/new level;
- description;
- **actual stat delta**;
- evolution readiness.

*Prototype (see 15.0, "Card text: one sentence", "Recipe icon row" and "Level-up panel presentation"):* each card
shows its key chip and kind tag, the icon, the name, level pips (old and new level), a one-sentence description, the
stat deltas and, only once discovered, the recipe as icons (evolution readiness is not hinted on cards: evolutions are
discovered and delivered by chests).

### 10.5 Readability and Visual Options

- Clear AoE telegraphs.
- Adjustable: screen shake, damage numerals, particles, ally transparency.
- Exposed toggles (performance/readability): damage-number density, corpses, particles, unit alpha, screen shake,
  minion HP bars.
- All classes must be readable at normal gameplay zoom.

*Prototype (see 15.0, "Accessibility / remapping", "Settings tabs" and "Reduce motion setting"):* Settings has
screen shake and damage-number toggles, two camera zooms and a **Reduce motion** toggle that makes every UI motion
instant.

---

## 11. Art Direction and Color Language

### 11.1 Style

Stylized gothic dark fantasy, either **polished pixel art** or **painted 2D**. Perspective: top-down 2D or 2.5D.

### 11.2 Color Language

| Subject | Palette |
|---|---|
| Necromancer | Purple / green / black / bone |
| Undead | Gray steel / cold blue / green |
| Covenant | Crimson / ivory / silver / gold |
| Friendly undead effects (combat) | Blue, violet, green |
| Enemy holy effects (combat) | Gold, ivory, crimson |
| Covenant magic | Radiant gold / white |
| Player necromancy | Purple / green |

Stage palettes: see the *Art* row of each stage in [Stages](#8-stages-and-wave-timelines).

### 11.3 Animation States

| Entity | States |
|---|---|
| Necromancer | idle, walk, cast, hit, death |
| Undead | rise, walk, attack, hit, collapse, special ability |
| Enemies | walk, attack, cast, hurt, death |
| Bosses | intro, tells, special attacks, transformations, defeat |

Evolved units may change silhouette (e.g., Dreadguard Legion has a larger silhouette).

### 11.4 Character Skins

Cosmetic; no default mechanical bonuses.

| Skin | Look | Unlock (if specified) |
|---|---|---|
| The Gravecaller | Hood, skull staff | — |
| The Plague Scholar | Decaying alchemical robes, green magic | — |
| The Dread Sovereign | Black armor, royal cloak | Final boss with all 4 summons |
| The Bone Oracle | Skull mask and spectral ornaments | Graveyard on Lich |
| The Fallen Confessor | Corrupted Covenant-style clerical robes | — |

---

## 12. Audio

| Element | Direction |
|---|---|
| Music / ambience | Ominous choirs, dark orchestration, low percussion and ambient drones |
| Holy sounds | Bright and metallic |
| Necromancy sounds | Low and unsettling |
| Mixing | **Aggressive audio voice limits** required with large crowds; cap audio voices |

*Prototype (see 15.0, "Audio voice limits", "UI sounds", "Menu theme ("Grave Lullaby")" and "Music crossfades"):*
every sound and both music tracks are synthesized in-engine (no audio files): a 12 s ambient loop for runs and the
51.2 s menu theme, crossfaded on real time.

---

## 13. Technical Architecture and Performance Budgets

### 13.1 Platform

- Preferred engine: **Godot 4**; alternative: Unity.
- Target: PC first (Steam).

### 13.2 Systems and Responsibilities

Top-level systems named in the source: PlayerController, PlayerStats, AbilityManager, HordeDirector, EnemyDirector,
CombatResolver, SpatialIndex, ProjectileManager, ProgressionManager, RunConfigurationManager, UIManager, SaveSystem.

| Component | Responsibility |
|---|---|
| Player / AbilityManager | Current skills and effective stat modifiers |
| HordeDirector | Population limits, replenishment scheduling, formation anchor assignment, threat context, registered summons, buffs and target reservations |
| SummonedUnit | Its own movement, target choice, attack/heal, animation and HP |
| SpatialIndex | Shared nearby-enemy/ally lookup |
| CombatResolver | Hits, armor, death, status effects and healing |
| ProjectileManager | Projectiles, pooling and impacts |
| EnemyDirector | Enemy waves, enemy density and event escalation |

### 13.3 Proposed Godot 4 Scene / Class Tree

```
Game (Node2D)
  Player (CharacterBody2D)
    PlayerController
    PlayerStats
    AbilityManager
    HealthComponent
  HordeDirector
  EnemyDirector
  CombatResolver
  SpatialIndex
  ProjectileManager
  EffectManager
  UnitContainer
  EnemyContainer
  UIManager

SummonedUnit (CharacterBody2D or optimized equivalent)
  MovementController
  BehaviorController
  TargetSelector
  CombatController
  HealthComponent
  StatusEffectController
  VisualController
```

Share unit logic in a base scene/script and parameterize per-class behavior with data resources. **Avoid four
independent, unrelated AI implementations.**

#### Data Definitions

**`SummonDefinition`** (Godot Resource)

| Field |
|---|
| `unit_id` |
| `display_name` |
| `unit_scene` |
| `max_health` |
| `base_damage` |
| `move_speed` |
| `attack_interval` |
| `attack_range` |
| `acquisition_range` |
| `preferred_follow_radius` |
| `soft_recall_distance` |
| `hard_recall_distance` |
| `target_profile` |
| `attack_profile` |
| `ability_definitions` |
| `animation_profile` |
| `visual_effect_profile` |

**`SummonAbilityDefinition`** (Godot Resource)

| Field |
|---|
| `ability_id` |
| `associated_unit_id` |
| `current_level` |
| `population_by_level` |
| `replenishment_interval` |
| `evolution_requirements` |
| `evolution_id` |

> Implementation note (from source): keep **immutable design data** in a Resource, and per-run `current_level`,
> timers and live instances in **separate runtime state**.

#### Events / Signals

| Signal |
|---|
| `summon_created` |
| `summon_died` |
| `summon_count_changed` |
| `summon_cap_changed` |
| `target_acquired` |
| `damage_applied` |
| `healing_applied` |
| `ability_cast` |
| `unit_evolved` |
| `army_buff_changed` |

Don't broadcast movement every frame globally.

### 13.4 Performance Budgets and Optimization

| Source section | Display | Friendly units | Enemies | Projectiles | Hardware |
|---|---|---|---|---|---|
| Technical Platform (Part I §18) | 1080p / 60 FPS | 20–40 | 150–300 | Many, pooled | Modest gaming PC |
| Optimization (Part II §38) | 1080p / 60 FPS | 40 | 250 | Hundreds | Real target-class hardware, measured |

Neither target is guaranteed without profiling.

**Essential techniques**
- Grid-based spatial hash or other 2D spatial partitioning for nearby allied, enemy and AoE queries; avoid full enemy
  scans per unit.
- Object pooling for common enemies, summons, projectiles, combat text, effects and corpses. Reset all mutable state,
  references, timers, effects and signal connections.
- Stagger target/strategy decisions; physics motion stays responsive.
- Simplified crowd collision (see [collision matrix](#collision-matrix)).
- Lightweight direct steering; pathfind only on target/path changes.
- Batched/simple effects, capped audio voices, limited simultaneous projectiles.
- Visual density settings; expose damage-number density, corpses, particles, unit alpha, screen shake and minion HP
  bar toggles.

### 13.5 Test Plan

**Functional tests**
- Buy Warrior → exactly two spawn.
- No spawn beyond population cap.
- Kill one → count reduces and replacement occurs after cooldown.
- Move player → units follow and recover from long-distance pursuit.
- Warrior prioritizes the enemy threatening the player.
- Archer prefers range and attempts to kite within ~45 px.
- Mage picks a useful enemy cluster.
- Priest heals a wounded unit and never wastes full-health heals.
- Unit death deregisters targets and the pool resets correctly.
- All four classes act differently while functioning as a whole.
- Boss AoEs meaningfully hurt the army without locking it out forever.

**Stress scenarios**

| Scenario | Allies | Enemies |
|---|---|---|
| S1 | 10 | 50 |
| S2 | 20 | 100 |
| S3 | 40 | 200 |
| S4 | 60 | 300 |

Measure: mean/worst FPS and frametime, AI cost, physics, projectile cost, allocations, nav requests and memory.

**Acceptance criteria**
- Friendly units cannot physically trap the player.
- Units don't oscillate rapidly between targets.
- Long pursuits always resolve via return or recall.
- Summons replenish, cooperate and remain useful against bosses.
- All classes readable at normal gameplay zoom.
- Stable measured performance at agreed entity counts.

### 13.6 Behavior Pseudocode

Reproduced from the source as reference logic.

```text
HORDE DIRECTOR:
function update_horde(delta):
    update_summon_replenishment(delta)
    if formation_update_due: calculate_formation_anchors()
    if threat_update_due: evaluate_player_threats()
    for unit in scheduled_behavior_units:
        if unit.is_alive: unit.update_behavior()
    update_army_wide_effects(delta)

UNIT:
function update_behavior():
    if health <= 0:
        enter_state(DEAD)
        return
    if distance_to_player > hard_recall:
        perform_safe_recall()
        return
    if distance_to_player > soft_recall:
        enter_state(RETURNING)
        return
    if state == CASTING:
        continue_cast()
        return
    if has_valid_target():
        if can_attack_target(): perform_attack_if_ready()
        else: reposition_for_attack()
        return
    target = acquire_best_target()
    if target != null: enter_state(ENGAGING)
    else: enter_state(FOLLOWING)

TARGET SELECTOR:
function acquire_best_target():
    candidates = spatial_index.get_nearby_enemies(position, acquisition_range)
    best = null
    best_score = -infinity
    for enemy in candidates:
        if not is_valid_target(enemy): continue
        score = evaluate_target(enemy, target_profile)
        if score > best_score:
            best = enemy
            best_score = score
    return best

REPLENISHMENT:
function update_summon_ability(delta):
    if active_count >= current_capacity:
        replenish_timer = 0
        return
    replenish_timer += delta
    if replenish_timer >= replenish_interval:
        if try_spawn_summon(): replenish_timer = 0

PRIEST TARGETING:
function choose_healing_target():
    allies = spatial_index.get_nearby_allies(position, healing_range)
    best = null
    score_best = 0
    for ally in allies:
        if ally.health >= ally.max_health: continue
        score = calculate_healing_priority(ally)
        if score > score_best:
            score_best = score
            best = ally
    return best
```

---

## 14. Development Roadmap

### 14.1 Production Phases

| Phase | Name | Scope |
|---|---|---|
| 1 | Prototype | Necromancer, movement, Skeleton Warrior, Shadow Bolt, two enemies, XP, level-ups and a five-minute spawner |
| 2 | Graveyard vertical slice | All 4 summons, 3 spells, initial passives, evolutions, six enemies, elite, Gravebreaker, menus and saves |
| 3 | Campaign | March, Sanctum, remaining enemies and bosses, events, permanent progression, modifiers, skins |
| 4 | Polish | Art, audio, QA, accessibility, controller support, optimization and balance |

### 14.2 Minimum Viable Product

| MVP item | Quantity |
|---|---|
| Necromancer | 1 |
| Graveyard stage | 1 |
| Summon abilities | 4 |
| Shadow abilities | 3 |
| Enemies | 7 |
| Boss | 1 |
| Upgrades | Basic |
| Difficulty | 1 |
| Menus | Yes |
| Level-up UI | Yes |
| Victory / defeat states | Yes |

### 14.3 Autonomous Horde Milestones

| Milestone | Scope | Success criterion |
|---|---|---|
| A. Basic army | Shared SummonedUnit, HordeDirector, warrior follow/target, melee, death, replenishment | 10 soldiers act autonomously |
| B. Class roles | Archer, mage, priest; ranged/AoE/healing; class targeting | Four-class army functions for a five-minute simulation |
| C. Coordination | Bands, threats, ally separation, priority scoring, leash | Recognizable formation and automatic threat response |
| D. Optimization | Spatial hash, pooling, staggered AI, projectiles, profiler | Target performance with late-game crowds |
| E. Progression | Five skill levels, passives, evolutions, synergies, bosses, summon HUD | Win the graveyard with a summoner-first build |

### 14.4 Next Recommended Work

1. Implement the Godot 4 prototype architecture with scenes and scripts.
2. Start with a movable player, 10 autonomous skeleton warriors, enemy targets, summon replenishment, a live debug
   overlay and a 5-minute wave director.
3. Add archers, mages, priests, then special Crimson Covenant enemies.
4. Only after the AI feels good, construct the Graveyard vertical slice.

### 14.5 Design Risks

| Risk | Mitigation |
|---|---|
| Army overcrowding | Collision rules, separation steering, opacity options |
| Too-passive combat | Telegraphed hazards, positioning-sensitive threats |
| Excessive anti-undead suppression | Localized, telegraphed counterplay |
| Mandatory builds | Test pure summoner, pure magic and hybrid clears |
| Overscope | Polish the graveyard vertical slice before later content |

### 14.6 Success Criteria

Unique and recognizable summon roles; meaningful level-up choices; engaging holy enemy counters; distinctive stages;
viable build types; readable large battles; strong replay value.

---

## 15. Open Questions

Items where the source is ambiguous, contradictory, or silent on something a designer or implementer will need.
Decisions made since the source was written are recorded in 15.0; everything below 15.0 is still open unless marked
**Resolved**.

### 15.0 Resolved Decisions

| # | Topic | Decision |
|---|---|---|
| 1 | Run end / time cap | The stage timer **counts down**. The stage boss appears before the timer ends. When the timer reaches 0:00 the run counts as survived and **"Reckoning" enemies** begin spawning: extremely powerful Covenant units that escalate over time. Only an absurdly overpowered build can kill them; normally they end the run. Dying after 0:00 shows the victory/results screen, and dying before 0:00 is a defeat. |
| 11 | Priest player healing/shielding | Priests **can heal the player** (same heal formula) and **can shield the player** with a short damage-absorb barrier. No special upgrade is required. |
| 12 | Warrior body-blocking | Warriors **physically block enemies**. Enemies cannot overlap warriors (overlap is resolved through the spatial hash, not physics bodies). Enemies in contact with a warrior are *engaged*: slowed and drawn to attack it. Warriors also have a short-cooldown shield bash that knocks back and damages enemies on contact. Other summon classes do not block. |
| 46 | Presentation / engine | **Top-down 2D in Godot 4.** |
| — | Power curve | A strong summoner build should make the player **nigh unkillable** before 0:00, as in other survivor games. Weak or careless builds can still die. Only the Reckoning is meant to end strong runs. |
| — | Summons vs. boss attacks | Undead **do not dodge** telegraphed attacks. They act as body blockers that absorb hits, including projectiles, for the necromancer. |
| — | Enemy movement | Covenant enemies **always advance toward the player**, following survivor-genre convention. Ranged enemies and Chaplains do not kite or hold at range; they attack or heal while advancing. |
| — | Shadow Bolt targeting | By default Shadow Bolt targets the **nearest** enemy. The player can toggle a **Strongest** aim mode that targets the highest-HP enemy in range. |
| 48 | Audio voice limits | No more than **24** sound-effect voices play at once. Each sound also has its own voice cap (1–4), a minimum re-trigger interval and a priority. When a sound is at its cap, its oldest voice is reused. When the global pool is full, a sound only replaces a voice of equal or lower priority. Positional sounds get quieter with distance from the camera and are culled beyond 900 px. Audio is synthesized in code at startup, so there are no audio assets. |
| 49 | Accessibility / remapping (prototype scope) | Settings include Master / Music / SFX volume, screen-shake, damage-number and fullscreen toggles, and keyboard rebinding of the **primary** key for movement, Shadow Bolt aim and pause. Arrow keys and controller bindings are fixed, and binding a key that is already in use swaps the two keys. The menu works with a controller. (Later: Grave Step, Dread Rally and the four army stances are rebindable too, the Controls tab shows each action's fixed pad binding beside its key, and a Reduce motion toggle exists; see "Settings tabs" and "Reduce motion setting".) |
| 50 | Save scope (settings) | For now only the settings are saved, in `user://settings.cfg` (ConfigFile). They are written when the Settings menu closes and loaded at startup. |
| — | Hit-stop and screen shake | Screen shake is trauma-based and stays small: it is largest on boss impacts and boss kills, and medium when the player takes damage. Brief hit-stop (40–130 ms, with time slowed to ×0.05) happens on Hammerfall impacts, boss kills and elite kills. It never happens during the autotest or while the game is paused. Damage numbers merge per enemy and are capped at 40 on screen. |
| 9, 26, 31, … | Missing numbers | Placeholder values marked `TUNING` in the prototype's data files are acceptable. Balance will be tuned against the playable prototype. |
| 27 | Evolution condition | An evolution becomes available when the base spell is at **level 5**, its paired passive is at **level 5** (it was **level 1+** until the owner rule "every evolution requires its paired passive at Lv 5", see the row near the end of this table), and the run has reached **8:00 elapsed** (12:00 left on the timer, the Purifier beat). The time gate was added in the balance pass: without it a spell rush evolved Shadow Bolt at 1:48-5:35. Raising the passive level alone would not help, because a rush maxes Soul Conduit by about 3-4 min. The "special elite reward" is not used for now; the condition is the single function `AbilityManager.ready_evolutions()`, with its numbers in `EvolutionData` (`BASE_LEVEL_REQUIRED`, `PASSIVE_LEVEL_REQUIRED`, `MIN_ELAPSED`), so a later delivery method (for example chests) can reuse it. While the condition holds, every level-up includes the evolution as a highlighted card. It replaces the base spell in the same slot, and the passive is kept. The paired passives have standalone effects: Soul Conduit gives +% spell damage, Warding Ritual gives −% damage taken, and Abyssal Focus gives −% spell cooldowns. |
| 29 | Synergy activation | Synergies switch on **automatically** while every required summon class is owned at skill **level 2+**. March of the Deathless needs any 3 classes at level 2+. Units do not need to be alive. Activation is announced with a banner and the active synergies are listed on the HUD. Magnitudes are `TUNING`. |
| 7, 8 | Rerolls, banishes, skips; maxed-out offers | Each run has **2 rerolls** and **2 banishes**. A reroll redraws the whole hand. A banish removes an item from the run and redraws that card. **Skips are unlimited** and heal 8% of max HP. Cards are drawn **weighted** toward upgrades of owned items and evolution paths, and a hand is never made only of dead cards. Once the real upgrades run out, fallback cards fill the hand: heal, +10 max HP, or instantly raise every fallen summon. Fortune-tree meta upgrades add charges on top (Fate's Thread +1 reroll per tier, Banishing Rite +1 banish per tier; see the Soul Ash rows below). |
| — | Sir Alaric phases | The GDD gives Alaric no phases. The prototype uses one threshold: at **50% HP** he enters *Wrath*. Specials come about 30% faster, Consecrated Ground and Judgment of the Dead place one or two more zones/marks, and Call to Arms is cast immediately. |
| — | Boss attacks vs. body-blocking | **Hammerfall:** each summon inside the circle absorbs 20% of the necromancer's damage, up to 80%. **Divine Charge:** each undead body hit uses up part of the remaining charge distance (warriors use up more), so enough bodies stop it short. **Judgment of the Dead** damages summons only. **Consecrated Ground** zones burn and slow undead, and sting the necromancer while he stands in them. |
| 14 | Temporary summons | Empowered-grave reinforcements and Crypt Defender guardians run the shared summon AI. They do **not** count toward class caps or HUD counts, are never replaced, and crumble when their duration ends. |
| 36 | Holy ground / suppression | Consecrated ground (from Alaric or from a desecrated grave) is a visible zone, telegraphed before it activates. It damages and slows undead inside, lightly damages the necromancer, and **blocks summon replacement inside it** (localized suppression). Replacement resumes as soon as the zone fades. |
| — | Graveyard stage events | *(6-minute prototype; superseded by "Graveyard stage events (20-minute run)" below.)* Untimed §11 mechanics are placed on the compressed timeline. Empowered graves appear from 0:30, then every 40 s; the necromancer claims one by walking onto it, for either reinforcements or an instant refill of every missing summon. Desecration happens at 2:30 (as in the timeline) and again at 4:15: Chaplains walk to the marked graves and channel for 12 s, and killing them interrupts it. The Crypt Defender event is at 4:00. |
| 33 | Templar Knight | Implemented as **heavy charging melee**. After a telegraphed lane it rushes forward, shoving summons aside. A warrior in the lane body-blocks the rush. |
| — | Arena obstacles | Sparse, solid gravestones, dead trees and crypt walls, using circle and rectangle collision without a physics engine. Units slide around them. Projectiles and line of sight ignore obstacles in the prototype. |
| 1 | Run length and Graveyard timeline | The countdown is **20:00** (the GDD's lower bound), replacing the 6:00 prototype. The [8.1](#81-stage-1-the-desecrated-graveyard) beats keep their real times: recruits 0:00, archers and footmen 3:00, Chaplain elite 5:00, Purifiers 8:00, grave consecration 10:00, Templar Knights 13:00, major assault 15:00. **Sir Alaric arrives at 17:00 (3:00 left)** instead of 20:00. The final preparation wave therefore moves from 18:00 to 16:00, so it still precedes him, and two **Call to Arms** formation waves at 18:00 and 19:00 reinforce him during the fight. Smaller waves fill the gaps between beats (every 35-60 s), and the first one comes at 0:12. The trickle ramps in steps, with a peak at each beat and a short lull after most of them; the boss fight has a thinner trickle. The Reckoning is unchanged and starts at 0:00. |
| — | Graveyard stage events (20-minute run) | Empowered graves rise from 0:45, then every 75 s until 19:10. A reinforce grave raises 3 warriors plus 1 per 5 minutes elapsed, for 25 s. Desecrations happen at 10:00 (GDD) and 14:00. The Crypt Defender appears at 16:30 and wakes 6 guardians for 60 s, so they meet Sir Alaric. A saved grave drops 60 XP. |
| — | Enemy time scaling | Enemy HP and damage scale with elapsed minutes m: HP × (1 + 0.10 m + 0.013 m²) and damage × (1 + 0.03 m + 0.005 m²). That is ×1.8 / ×3.3 / ×5.4 / ×8.2 HP and ×1.3 / ×1.8 / ×2.6 / ×3.6 damage at 5 / 10 / 15 / 20 min. The early game stays gentle, and the 13:00-17:00 peak can overwhelm weak builds but not a focused one. Sir Alaric has 42 000 HP (not time-scaled; 46 000 before the balance pass, lowered to make up for the Void Barrage nerf) and drops 400 XP. |
| — | XP curve and in-run pacing | XP to the next level = 17 + Σ growth, where growth is +3 per level for L2-18, +4 for L19-35 and +6 from L36 (piecewise linear). Enemy XP values are unchanged. Measured with the autotest bots at zero meta upgrades: first level-up at about 0:21-0:25; levels about 4-5 / 11 / 18 / 35 / 52 at 1 / 3 / 5 / 10 / 15 min, and 65 at 20 min. A focused build (6 actives and 6 passives at Lv 5 plus its evolution, 59 picks) completes at about 17:00-18:00. Weaker builds that fall behind the density earn less XP and often die at the 16:00-19:00 peak. A stray-crystal fix keeps XP collectable in long runs: at the 250-crystal cap a drop merges only into a crystal within 60 px, otherwise the crystal farthest from the player moves to the drop point. |
| — | Autotest for the 20-minute run | `--timeout` defaults to 1500 game s and `--speed` to 8; results are identical at speed 4 and 8. `[metric]` lines are printed every 60 s and include XP collected. The summary adds the level pacing and the time the build was complete. CI uses `--quit-after 15000` and a 600 s wall limit per run. |
| 39 | Soul Ash earn rate | Soul Ash is earned at the end of **every** run and **kept on death** (survivor convention). Per run: **7.5 per minute** survived on the countdown (max 150 on the 20:00 stage), **0.03 per kill**, **4 per elite**, **75 for Sir Alaric**, and **2.5 per second** survived into the Reckoning (capped at 180 s), each part floored; the Fortune upgrade Ash Harvest then adds +5% per tier. A strong 20-minute run (about 3,000 kills, 15 elites, boss slain, 30 s of Reckoning) earns about **450**. All numbers are `TUNING`. |
| 39 | Soul Ash upgrade trees and costs | Four trees as in 9.2, 18 upgrades. Each upgrade raises one stat by a fixed amount per tier. Five-tier upgrades cost 40 / 80 / 125 / 175 / 230, and other upgrades rise in similar steps. Capstones cost 450–550 and need a prerequisite in the same tree. **Necromancy:** minion HP +6%/tier, minion damage +5%/tier, replacement time −6%/tier, +1 Warrior capacity/tier (2 tiers), +1 capacity for every class (capstone). **Shadowcraft:** spell damage +5%/tier, spell cooldowns −3%/tier, spell area (Shadow Blast and pulse radius) +6%/tier, +10% spell damage (capstone). **Survival:** max HP +10/tier, damage taken −3%/tier (armor), move speed +4%/tier, one revival per run (capstone). **Fortune:** pickup radius +10%/tier, XP gain +4%/tier, Soul Ash +5%/tier, +1 reroll/tier, +1 banish/tier. Buying everything costs **8,965**, about 20 good runs (9,165 since the Spearhead army-stance unlock, 200, joined Necromancy; see "Army stances"). **Refund all** returns 100% of spent ash after a confirmation. |
| — | Meta modifiers in a run | Purchases apply at run start through one `MetaModifiers` object that the existing stat code reads. Each meta stat is its **own stacking category** (6.4): it multiplies the skill-level, passive and synergy bonuses. With no purchases every value is 0 and the game plays exactly as before. |
| 13 | Capacity from meta upgrades | A meta capacity bonus goes to the class the upgrade names (Risen Vanguard: Skeleton Warriors, which also means more starting summons) or to **every** owned class (Legion of Bone), like Grave Dominion. |
| — | Revival (Undying Will) | Once per run, lethal damage instead leaves the necromancer at **50% max HP** with 2.5 s of invulnerability and a knock-back burst. Dying after the revival is spent ends the run normally (the victory / defeat rule still depends on 0:00). |
| 40 | Achievement wording | Implemented: *Bone Legion* = 1,000 killing blows by Skeleton Warriors (strike or shield bash) over all runs; *Heretic's Bane* = 500 Covenant **Chaplains** slain; *Dread Sovereign* = Sir Alaric slain while all 4 summon classes are owned. Their GDD unlocks (Bone Golem, priest evolution unlock, Dread Sovereign skin) are not in the prototype yet, so each pays a one-time Soul Ash bounty (100 / 100 / 150) for now. The Shadow Bolt and Lich-difficulty achievements need systems that don't exist yet. The Codex's Achievements tab (see "Codex and achievements screen") shows each achievement's reward as its Soul Ash bounty plus, for *Bone Legion*, the Ivory Seer skin it already unlocks (read from `SkinData`); nothing else changed. |
| 50 | Save scope (meta) | Meta-progression is saved to `user://save.cfg` (ConfigFile), separate from `settings.cfg`. It holds `save_version`, Soul Ash, the tier of every upgrade, lifetime stats (runs, victories, best time, best Reckoning time, total kills, boss kills, achievement counters, ash earned) and achievement unlocks. It is written on every run end, purchase and refund, never during the autotest (unless the `--meta-save` test flag is given). Loading is migration-safe: a missing file starts fresh, an unreadable file is kept as `save.cfg.corrupt` and the game starts fresh, values are type-checked and clamped, unknown keys are ignored, and tiers whose prerequisite is missing are refunded. There are no mid-run saves. |
| — | Necromancer regeneration | The necromancer regenerates **0.3 HP/s** (18 HP per minute; `PlayerData.HP_REGEN`, `TUNING`). Without it, a build that never drew a Priest had no healing at all and always died of chip damage at 6-8 min. It now dies at the later peaks instead, while bursts still kill. |
| 11 | Priest ward timing | A priest's ward on the necromancer is **not** suppressed while he or an ally is critical. The ward is instant and has its own cooldown, so it never delays a heal. Before the balance pass, a critical summon (common in the boss fight) stopped every ward exactly when the necromancer needed one. |
| — | Balance pass (meta none / mid / max) | Measured with the autotest bots (`--mortal`; 16 seeds for naive / army at none and max, 8 for the rest). **Fresh save:** the summoner build never dies before 0:00 (lowest HP 98/120) and always kills Sir Alaric; the naive build dies before 0:00 in about 30% of runs (9-11 min without a Priest, otherwise at the 19:00 peak) and kills him in about 25%; the spell build is in between. **Meta mid:** no bot died before 0:00 and every bot killed him. **Meta max:** nothing dies before 0:00, the summoner build kills him in 70-115 s (at least 16 of his attacks), and the Reckoning still ends every run, 15-55 s past 0:00 (6-24 s at no upgrades). Void Barrage was nerfed (damage 30 → 24, cooldown 0.5 → 0.6 s, pierce 3 → 2, shard damage 50% → 40%), which cut its damage share from about 83% to about 62% in the spell build and from 43% to 31% in the summoner build. Build complete: 16:30-20:00 at no upgrades, 15:40-17:10 at max (the max XP and pickup bonuses add about 3-4 levels by 20:00). Soul Ash is unchanged: about 450 per good run at no upgrades, 100-150 for a death at 9-11 min, and the Reckoning is about 8% of a good run. |
| — | Power-up drops | Six data-driven drops (`PowerupData`, numbers `TUNING`): **Soul Magnet** (every XP crystal flies to the player), **Grave Feast** (heals 30% max HP), **Hyper** (10 s: spells ×2 damage, cooldowns halved), **Stasis** (5 s: every enemy frozen, no movement / attacks / heals / projectile spawns; Sir Alaric frozen for the first half; Reckoning enemies immune; a frozen attacker's telegraphs, Alaric's marks and his arming zones pause with it, and frozen Desecration Chaplains do not channel), **Dark Frenzy** (12 s: summons ×1.5 damage and ×1.5 attack speed, a separate stacking category in the horde's effective stats) and **Soul Nova** (rarest; kills every regular enemy on screen, elites lose 50% of current HP, the boss 5% of max HP, Reckoning immune; routed through the combat resolver so kills drop XP and count). Drop chance 0.2% per regular kill, 20% per elite, guaranteed from Sir Alaric; weighted type draw (3 / 3 / 2 / 1.5 / 2 / 0.5); a pity timer drops one on the next kill after 120 s without a drop (about 17 per run); at most 3 on the ground; each despawns after 30 s (blinking for the last 7 s); none from Reckoning enemies or after 0:00. Collected by walking over them (12 px from the body edge, a fixed radius, not the XP pickup radius). **Re-collecting a running buff refreshes its duration to full; buffs never stack.** Drop rolls use their own seeded RNG. |
| 27 | Treasure chests and evolution delivery | Chests are the GDD's "special elite reward": elites drop one at 10%, Sir Alaric always, and a pity timer drops one from the next kill after 360 s without a chest, or after 40 s while an evolution is ready (none from Reckoning enemies or after 0:00; they never despawn, at most 3 on the ground); about 4-7 per run. Opening one pauses the run with a short reveal and grants 1 upgrade before 15:00 elapsed, then 1 / 3 / 5 upgrades (weights 85 / 12 / 3), from the normal weighted level-up pool. **Every ready evolution is granted first, and evolutions are delivered only by chests**, no longer as level-up cards (this supersedes the "highlighted card" delivery in the Evolution condition row above; the eligibility condition itself is unchanged). Chests never grant the Profane Pact; with nothing left to upgrade a chest heals (Dark Restoration). |
| — | Profane Pact (in-run difficulty) | A 5-level passive item offered on level-up cards (0.4× card weight) that takes a passive slot and can be banished, like Vampire Survivors' Curse. Per level: enemy spawn rate (trickle rate and soft cap) +5%, enemy HP +5%, enemy damage +3%; rewards XP +8%, Soul Ash +12%, power-up drop chance +15% (`TUNING`). The card shows every penalty and reward as old → new; the HUD Modifiers area shows the level and the combined effect. |
| 39 | Profane Oath (meta difficulty) | A standalone 5-tier Ossuary entry ("Oath", outside the four trees), cheap on purpose (25 / 50 / 75 / 100 / 125) since it is a risk / reward choice. Each active tier from the first second: enemy spawn +6%, HP +5%, damage +4%; XP +5%, Soul Ash +10%, drop chance +10% (`TUNING`). The player can lower the **active** tier (to off) at once and with no refund (free and reversible, so no confirmation since the menu modernization; see "Ossuary redesign"); owned tiers can be raised again for free; Refund all returns everything. Shown on the HUD and as its own bonus line on the end screen. The autotest `--meta` profiles never include it (`--oath=N` sets it). |
| — | Pact + Oath stacking | One difficulty path (`DifficultyModifiers`). The Pact and Oath bonuses of a key are one category and **add**; the sum applies once as (1 + bonus) and multiplies the time scaling, meta upgrades and every other category. Enemy HP / damage go through the existing time-scaling multipliers (the Reckoning included); Sir Alaric's HP gets only 20% of the HP bonus (his HP is not time-scaled, and the full bonus made him a wall). XP is its own category next to Grave Tithe. Soul Ash pays a Pact and an Oath bonus line on the run subtotal (each floored, alongside Ash Harvest). |
| — | Power pacing with chests (post-merge retune) | Merged on top of the balance pass, the first chest numbers (35% elite chance, 150 s pity, 1 / 3 / 5 from the start) gave about 12 chests and 17 extra upgrades per run: builds completed at about 13:50 instead of 17:20, and the naive bot died in only 1 of 8 runs. Retuned (`TUNING`): elite chance 10%, pity 360 s, a 40 s pity while an evolution is ready (evolutions come only from chests), 1-upgrade chests before 15:00 and 85 / 12 / 3 afterwards; power-ups 0.2% per kill with a 120 s pity. Measured (`--mortal`, 16 seeds at meta none): army build complete 16:07 (15:44-16:26), Void Barrage 12:29-14:38, 0 deaths, lowest HP 92+, Sir Alaric 16/16; naive 7/16 deaths, 7/16 boss kills; meta max builds complete at about 15:20-15:30 and the Reckoning still ends every run. The Profane Pact was a trap (Lv 5: +50% spawns of +50% HP and a 63,000 HP Sir Alaric; the army bot never killed him): it is now +5% spawn / +5% HP / +3% damage per level with +12% Soul Ash, and Sir Alaric gets 20% of the HP bonus. An army build that takes it at once kills him in 5 of 8 runs, never dies (lowest HP 26-94) and earns about 745 Soul Ash instead of about 455. Profane Oath V (unchanged) is a hard mode: the army bot never dies but kills him in 2 of 8 runs. Stasis now also pauses a frozen attacker's telegraphs, Sir Alaric's marks and arming zones, and Desecration channelling. |
| 11, 15 | Priest split: Grave Mender and Crypt Warder | User request: the Undead Priest is **two summon classes**, each with its own card, cap, replenishment queue and HUD row. The **Grave Mender** keeps the priest's §23 numbers, its level table (count 1/1/2/2/2, heal +25%/+50%, HP +20%; Lv 5 now casts 25% faster instead of the ward bonus) and the §31 heal formula on allies and the necromancer, unchanged. The **Crypt Warder** (HP 45, otherwise the priest's numbers and 15 s replenishment) casts the old priest ward on the threatened necromancer (15 HP, 4 s, 6 s cooldown, same trigger) and an instant **ally barrier** (12 HP, 3 s cooldown) on the most threatened ally in reach (hit in the last 2 s, or a blocker fighting in melee) whose barrier is below half; its table is count 1/1/2/2/2, ward and barrier +25/+25/+50/+80%, HP +20% at Lv 4. Barriers share the Shieldwall barrier slot (the stronger wins, no stacking). Both cast weak bolts when idle. Synergies: **Shieldwall** needs Warriors + **Warders** (the barrier class; the refresh needs a living Warder or Bishop); **The Unholy Host**'s "4 main summons" are Warriors, Archers, Mages and **either** priest order; March of the Deathless counts each class separately. *Dread Sovereign* needs Warriors, Archers, Mages and a priest order. Capacity bonuses for "every class" (Grave Dominion, Legion of Bone) count the Mender and Warder as two classes. All numbers `TUNING`. |
| 27, 28 | Summon evolutions and their passives | User request. Three summon evolutions use the spell evolutions' delivery (`ready_evolutions()` lists them, the next treasure chest grants them, the 8:00 `MIN_ELAPSED` gate and the 40 s evolution pity apply; never on level-up cards). Recipes: **Death Knight** (the GDD's Dreadguard Legion) = Skeleton Warrior Lv 5 + Dark Command **Lv 5**; **Lich** (Lich Conclave) = Undead Mage Lv 5 + Forbidden Knowledge **Lv 5**; **Profane Bishop** (GDD §4.2) = Grave Mender Lv 5 + Crypt Warder Lv 5 + Dark Benediction **Lv 5** (it was **owned** until the owner's Lv 5 rule, see the row near the end of this table). A *transform* evolution keeps the class id, slot, level and capacity, overlays its stats (own stacking category) and transforms every unit in place (glow, full heal); the HUD row, slot icon and name become the evolution's. Death Knight: ×1.5 HP, ×1.35 damage, radius 12, block radius 15 / mass 5, foes in contact slowed to 45% (its "dread": a slow, not a fear, so enemies still always advance), bash ×2 every 1.5 s with more knockback, cleave 50% of each hit to foes within 32 px, life drain 12% of melee damage. Lich: ×1.4 HP, ×1.35 damage, ×1.25 splash, 15% faster casts, and **raise the dead**: every 5th Lich kill (a deterministic accumulator, no RNG) rises as a base-kit skeleton for 12 s (×0.6 HP, ×0.8 damage, at most 6 at once). The *merge* evolution sets both priest orders to level 0 and locks them (never offered again), which **frees one active slot**, and creates the Profane Bishop at level 5 with **capacity 3 + global bonuses** (counted once instead of twice); living Menders and Warders convert in place up to that cap, the rest dissolve (not counted as deaths) and any shortfall spawns at once. The Bishop (HP 70, radius 12, 12 s replenishment) heals like a Mender (12 HP), wards the necromancer (20 HP, 5 s cooldown) and shields allies (16 HP, 2.5 s) like a Warder, and pulses an aura every 3 s (90 px) that heals allies and the necromancer 4 HP and deals 12 damage to foes; it counts as both priest orders for synergies and achievements. Standalone effects of the new 5-level passives (open question 28): **Forbidden Knowledge** +8–40% mage damage and +5–25% mage splash; **Dark Benediction** +8–40% heals, wards, barriers and aura heals of Menders, Warders and Bishops; each is a dead card while none of its classes is owned, and both are on the evolution-path card weight (as are Dark Command for Warriors and the base classes once their passive is owned). Stage-event temporary summons always keep the base kit. Bone Plating and Unholy Precision were not implemented then (they are now, see "Later horde passives" near the end of this table). Measured first pass (autotest `--policy=summon`, seed 1337): Bishop 11:16, Death Knight 11:55, Lich 12:36; the Lich's 1.5× damage made it 36% of all damage and was trimmed to 1.35×. 4-seed sanity check against main (`--mortal`, seeds 1-4): army 0 deaths before 0:00, lowest HP 92-110 (main 92-114), Sir Alaric 4/4, build complete 15:58-16:40 (main 15:55-16:14), Death Knight 10:26-11:16; naive 2/4 deaths and 2/4 boss kills (main 3/4 and 1/4). A combined balance pass is still due. All numbers `TUNING`. |
| — | Autotest summon policy | `--policy=summon` is a summoner build that chases the three summon evolutions (Warriors, Mages, Menders, Warders, then Archers; Dark Command and Forbidden Knowledge to Lv 5, Dark Benediction; Shadow Blast fills the slot the merge frees). `--policy=army` now takes both priest orders and, since it maxes Dark Command, usually evolves the Death Knight. The summary lists evolutions by type with their times, the Lich raises, merge conversions and aura pulses, and the damage / heals / shields of every summon source and class. |
| — | Four more summon classes | The roster grows by four classes (user request; on top of the GDD's Warrior, Archer and Mage and the split priest's Mender and Warder, plus the merge-only Bishop): **Corpse Abomination** (the §4.2 "possible future summon"; tank / blocker, 1 → 3), **Grave Rogue** (dash-strike assassin, 1 → 4), **Crypt Gargoyle** (melee + flying swoop, 1 → 3) and **Frost Wraith** (ice caster, 1 → 3). Each is a normal summon skill: a level-up card, 5 levels with a population table, its own replacement timer (20 / 9 / 12 / 14 s), a HUD row and a formation band (Abomination and Gargoyle join the warriors' threat-facing arc at 45-95 / 50-110 px, the Rogue sits at 70-130 px, the Frost Wraith on the outer midline at 95-160 px). All of them run the **one shared SummonedUnit AI**; each class's special action is a `SummonBehavior` (new files in `scripts/horde/behaviors/`) plugged in through one dispatch object per unit. All numbers are `TUNING` in `UnitData` (base stats, a `special` dictionary per class and `special_bonus` / `special_area` / `special_haste` / `special_duration` level keys); special damage scales with every minion-damage bonus (skill level, Dark Command, meta, Dark Frenzy), special cooldowns do not scale with attack speed. |
| — | Target preferences of the new classes (§4.9) | Abomination: the warrior "guard" weights (threats to the player first, no chasing while he is surrounded). Rogue ("assassin"): role priority first (Chaplains, archers, consecrators) plus a bonus for enemies far from the player, i.e. the back of the crowd. Gargoyle ("skirmisher"): threats near the player, plus a cluster bonus while its swoop is ready. Frost Wraith ("frost"): enemies closing on the player, unchilled ones first so the slow spreads; it never wastes a shot on a doomed target (overkill weight 2). |
| 12 | Corpse Abomination blocking and Stomp | The Abomination is a physical blocker like a warrior, with a wider block radius (20 px vs 12) and more mass (8 vs 3; Sir Alaric, 12, still shoves it, and it stops Templar rushes). Enemies touching it move at 45% speed. Stomp: when 2+ enemies (or an elite / the boss) stand inside 85% of its 64 px ring and the 6 s cooldown is ready, it plants its feet, a bone-green ring is telegraphed for 0.6 s, then every enemy in the ring takes 22 damage and is knocked back (260 px/s divided by mass), with a shockwave, dust burst and a small screen shake. |
| — | Grave Rogue Dash Strike | Modelled on the Templar charge: with the 4.5 s cooldown ready and its target 45-130 px away, the rogue measures the lane with the arena (an obstacle between it and the target cancels the dash; the end must stay inside the soft leash), shows a violet lane for 0.3 s, then dashes through at 560 px/s: every enemy touching the 24 px lane takes 24 damage once and **bleeds** (3 damage every 0.5 s for 3 s; refreshed, not stacked). The dash always ends on a free point (never inside an obstacle), then the rogue drops its target and returns to its formation slot. Bleeds are ticked by the rogue that caused them and stop if it dies (prototype simplicity). |
| — | Crypt Gargoyle Swoop and airborne rules | With the 7 s cooldown ready and its target 50-230 px away, inside the 220 px engagement zone and in a cluster of 3+ (or an elite / the boss), the gargoyle takes off (0.25 s), flies straight at the target at 330 px/s (at most 1.4 s), dives for 30 damage in 50 px with a small knockback, and settles (0.25 s) onto the nearest free point. While **airborne** it ignores obstacles, is not in the ally grid (enemies can neither target nor be blocked by it, boss marks and holy zones skip it) and cannot be damaged; it is drawn lifted above a ground shadow. Leash and recall always win: a soft or hard recall changes its FSM state, which cancels the swoop and lands it at once. |
| — | Frost Wraith chill and Deep Freeze | Frost bolts (8 damage, 160 px) **chill**: -35% move speed for 1.8 s, shown as a frost film on the enemy. **Deep Freeze** (9 s cooldown): on a target in bolt range standing in a cluster of 3+, or an elite / the boss, or next to a necromancer who is in danger, a cold-blue circle is telegraphed for 0.45 s, then every enemy within 52 px is frozen for 1.6 s. It reuses the **Stasis freeze path** (`Enemy.freeze_timer` makes EnemyDirector hold the enemy exactly like Stasis: no movement, attacks, heals, arrows or channelling, its telegraphs pause, the frost shell is drawn). Sir Alaric is frozen for 20% of the duration (Stasis: 50%), elites for 60%, Reckoning enemies are immune. |
| 13 | Global capacity bonuses for elite classes | Grave Dominion (+1 to +5 per class) and the Legion of Bone meta upgrade would double or triple a low-population class. Each new class takes only a share of global capacity bonuses (`capacity_bonus_mult`, rounded down): Abomination 40% (+2 at Grave Dominion V, none from Legion of Bone), Frost Wraith 50% (+2), Rogue and Gargoyle 60% (+3). The GDD classes keep the full bonus, with the Mender and Warder each counting as a class (and the merged Bishop once; see the priest split row). |
| 7, 8 | Card pool with many summon classes | New summon classes share one draw weight (`LevelUpData.NEW_SUMMON_POOL_WEIGHT` = 3): each unowned, unbanished, offerable class gets min(1, 3 / their number). With the original four GDD classes this was exactly the old weight of 1; with the Mender, Warder and the four later classes (8 offerable classes, 7 unowned at the start besides the Warriors) a hand still shows about as many new summons as before instead of being crowded with them. The Mender and Warder share the pool like any class; the evolution-only Profane Bishop and merged-away Menders / Warders are never offered and do not count toward the split. The 6 active slots stay the real constraint: once they are full, no new summon or spell card is drawn at all (never a dead card), so taking a new class always means giving up a slot for a spell or another class. |
| 29, 40 | "All 4 classes" with a larger roster | The Unholy Host synergy and the Dread Sovereign achievement keep meaning the GDD's four summon **roles**: Warriors, Archers, Mages and **either** priest order (Mender or Warder; the Profane Bishop counts as both). `UnitData.CORE_CLASSES` holds that list in `SynergyManager.classes_met()` format and `MetaData.DREAD_SOVEREIGN_CLASSES` is it; the later classes are never required. March of the Deathless (any 3 classes at Lv 2+) counts every class, new ones included (the Bishop once). |
| — | Autotest for the new classes | `--classes=a,b` raises those classes to Lv 1 at the start (while active slots allow) and every policy upgrades them first. The summary prints one line per new class (level, alive / capacity, deaths, damage by source, stomps / dashes / swoops / Deep Freezes, enemies frozen, frozen-enemy-seconds, chills) and the stuck check also counts a special still running after 4 s (airborne or dashing) and any dash or landing that ends inside an obstacle. |
| — | First measurements of the new classes (before the combined balance pass) | With `--policy=army --classes=X` (seed 1337, the forced class replaces one of the army bot's usual classes) the new classes deal damage in the range of the core classes in the same runs (mage 79-113k, archer 62-80k, warrior 53-70k): **Rogue** 80k (dash 50k, stab 25k, bleed 5.5k; ~1,500 dashes, 70 deaths: it dives and dies a lot), **Gargoyle** 69k (swoop 38k, ~500 swoops hitting ~2 enemies each), **Abomination** 52k (stomp 35k, ~490 stomps, 6 deaths: a tank), **Frost Wraith** 23k plus crowd control (~460 Deep Freezes, ~1,300 enemies frozen, ~790 frozen-enemy-seconds, ~1,800 chills). No special ever ran overtime, was cancelled or ended inside an obstacle; stuck_units stayed 0. Sanity check vs main (`--mortal`): the army bot is unchanged (4 seeds: 0 deaths, lowest HP 100-114 vs 92-114, Sir Alaric 4/4, build complete 15:57-16:18 vs 15:55-16:14, Soul Ash 436-455 vs 453-460); the **naive bot got safer** (8 seeds: 1 death vs 4, Sir Alaric 6/8 vs 3/8), because it now often fills its slots with sturdier summon classes. Left for the combined balance pass, as briefed. |
| — | Priest split + summon evolutions merged with the four later classes | The two features were built in parallel and merged; interaction decisions: (1) **Evolutions stay on their own classes.** Death Knight, Lich and Profane Bishop list their bases explicitly, and Forbidden Knowledge / Dark Benediction list theirs (`PassiveData` `classes`), so nothing applies to the Abomination, Rogue, Gargoyle or Frost Wraith (the Frost Wraith is an "ice mage" in flavour only; Forbidden Knowledge does not boost it). The later classes have no evolution yet. (2) **Several blockers on one enemy:** an enemy touching Warriors, Death Knights and Abominations in the same tick is slowed by the **strongest** of their contact slows (lowest `engaged_speed_mult`; Death Knight and Abomination are both 45%), never a product, and the result no longer depends on the order the spatial hash returns blockers in. (3) **Shieldwall stays on Warriors** (Death Knights included: same class); Abominations have their own HP pool and get no Shieldwall barrier. Warder / Bishop **ally barriers** pick any threatened ally, Abominations included (a blocker fighting in melee counts as threatened, like a warrior). (4) **Airborne Gargoyles** are outside the ally grid, so Warder / Bishop barriers, Mender heals and the Bishop aura skip them while they fly; they cannot be hit then anyway, and are eligible again as soon as they land. (5) **Determinism:** the Lich's raise-the-dead is an accumulator and the Deep Freeze is a timer on the enemy, so neither uses RNG; the later classes' specials only use the seeded global RNG (first cooldown). (6) The merge converts Menders / Warders in place into Bishops, which have no `SummonBehavior`, so no special state is carried across. (7) **HUD:** only owned classes have a visible army row and each takes an active slot, so at most 6 rows show; the army panel uses compact rows (22 px icons, 2 px gaps) so 6 rows fit its box. (8) `--classes` ignores the merge-only `bishop`. Post-merge check (`--mortal --policy=army`, seeds 1-4): 0 deaths before 0:00, lowest HP 97 / 111 / 71 / 110, Sir Alaric 4/4, build complete 16:14-16:40, Death Knight 9:41-11:24, Void Barrage 12:41-13:25, Soul Ash 433-467; `--policy=summon` (seed 1337) gets Profane Bishop 9:58, Death Knight 11:28, Lich 12:52; `--policy=army --classes=abomination,rogue,gargoyle,frost_wraith` completes with no special overtime, cancelled or ending inside an obstacle; stuck_units 0 everywhere. The default naive run (seed 1337) filled its slots with Warriors, Mender, Warder, Abomination and Frost Wraith and never got a second spell or Mages, so it did little damage to Sir Alaric: naive results now depend on the larger card mix and belong to the combined balance pass. |
| — | Four more necromancer spells | User request ("more weapons"). Four spells fill gaps in the kit (Shadow Bolt = single-target homing, Orb Shield = orbit/defence, Shadow Blast = AoE around you), each with 5 levels (`TUNING`), card deltas and code-drawn visuals and sounds. **Bone Spear**: straight piercing spears thrown the way you are **walking** (the last direction is kept while standing), with an **aim assist**: the volley flies at the nearest enemy within ±0.6 rad of that direction, else at the nearest enemy (pure movement aim dealt almost nothing while kiting: 3.9k damage in a whole run); it throws only while an enemy is within 420 px; Lv 1 18 dmg, 1 spear, pierce 2, 1.3 s, 360 px → Lv 5 31 dmg, 3 spears, pierce 4, 0.9 s, 440 px. **Soul Siphon** (5.3): tethers on the **strongest** enemies in range (highest HP; enemies already expected to die are skipped, like the overkill reservation) drain on a pulse and heal `lifesteal` of the damage, **capped per second** by a leaky budget; Lv 1 7 dmg / 0.5 s, 1 tether, 170 px, 25%, cap 1 HP/s → Lv 5 14 dmg / 0.45 s, 3 tethers, 210 px, 35%, cap 2 HP/s. **Corpse Explosion**: every enemy that dies, **to any killer**, leaves a corpse for 8 s; the spell detonates the corpses within range that have the most live enemies around them (corpses with nobody near are kept); Lv 1 24 dmg, 1 corpse, radius 50, 2.2 s → Lv 5 40 dmg, 3 corpses, radius 70, 1.6 s. **Plague Cloud**: a lingering cloud on the most packed enemies within range (avoiding spots already covered) ticks every 0.5 s and inflicts **Rot**; Lv 1 3 dmg/tick, radius 55, 3.5 s, every 3.4 s, Rot +8% → Lv 5 4 dmg/tick, radius 70, 5 s, every 3 s, Rot +18% (cut twice: a cloud always sits on the densest pack, and the first passes dealt 2-3x Shadow Blast's damage, up to 37% of a naive run's total). A spell that finds nothing to do retries after 0.25 s without spending its cooldown. Measured (first pass, `--mortal` 4 seeds vs the base commit; the combined balance pass is still due): army 0 deaths, lowest HP 106-111 (base 92-114), Sir Alaric 4/4, build complete 15:53-16:18 (base 15:55-16:14); naive 2/4 deaths and 2/4 boss kills (base 3/4 and 1/4). Each spell forced alone (`--spells`, seed 1337) evolves at 8:00-8:04, and all four forced together evolve at 8:19-11:08. Grave Eruption is the strongest of the four evolutions (about 400 dmg/s once evolved, close to Void Barrage in a spell rush). All damage goes through `CombatResolver`; their stats come through `AbilityManager.spell_stats()`, so Soul Conduit, Abyssal Focus, meta Shadowcraft and Hyper apply, and they keep hitting enemies frozen by Stasis. Grasp of the Damned (5.3) is not implemented. |
| 30 | Rot status | The prototype's one "curse" status: **Rot** (from Plague Cloud / Pestilence) makes an enemy take **+X% damage from every source** (horde, spells, everything) for 1.5 s after its last plague tick; the stronger Rot wins, bosses get half. It is a field on the enemy applied once in `CombatResolver.damage_enemy`, and Pestilence's Death Nova deals bonus damage to rotting enemies (5.3 "bonus damage to cursed enemies"). Shadow Bolt curses, cursed arrows and Soulburn stay open. |
| 27, 28 | Evolutions of the newer spells | Same rules as the first three (base spell Lv 5, paired passive Lv 1+, 8:00 elapsed, delivered only by treasure chests through `ready_evolutions()` / `chest_rewards()`). Each paired passive has a standalone 5-level effect (`TUNING`): **Bone Spear + Shade Stride** (+3-15% move speed, its own category) = **Ossuary Lance** (34 dmg, 3 lances ahead **and 2 behind**, pierce 8, knockback, 0.8 s). **Soul Siphon + Vampiric Rite** (+0.2-1.0 HP/s on top of the natural 0.3) = **Soul Rapture** (5 tethers, 16 dmg / 0.4 s, 40% lifesteal capped at 3 HP/s; a tethered enemy that dies bursts for 2x drain in 70 px; lifesteal you cannot use at full HP heals the most wounded summon). **Corpse Explosion + Necrotic Expanse** (+5-25% spell area: every radius stat, its own category next to meta Widening Dark) = **Grave Eruption** (5.3: 36 dmg, 3 corpses, radius 90, 1.3 s; each burst leaves a 3 s bone-spike field dealing 15% per 0.5 s and slowing 35%; an enemy an eruption kills erupts at once, up to 3 chained bursts per cast). **Plague Cloud + Lingering Malediction** (+10-50% spell durations: cloud duration, spike fields and Shadow Blast's slow) = **Pestilence** (6 dmg/tick, radius 95, 7 s, every 2.6 s, Rot +25%; clouds creep 35 px/s after the nearest enemy and end in a **Death Nova** of 3x tick damage over 1.5x the radius, doubled against rotting enemies). |
| — | Autotest `--spells` | `--spells=a,b,...` makes any policy take those spells and their evolution passives first (never banished; they also get x8 card weight through a test-only hook, since otherwise a forced spell could go unoffered for most of a run) and stop taking other new actives (or passives) once the free slots are down to the forced items still missing plus one spare, since chests can fill slots too (a hand with nothing else is rerolled or skipped), so each spell can be exercised and evolved. The summary adds a "necro spells" line (level, damage and the evolved part, boss damage, spell counters, Rot bonus damage). With 11 actives in the pool the army bot began spending slots on off-list spells (one seed lost its Mage and Shadow Blast and failed to kill Sir Alaric), so the **army and evolve bots never take a new item that is not on their build list**; they reroll or skip and stay comparable baselines (extended to the summon bot when the branches were merged, see the merge row below). The naive bot and `--spells` exercise the new content. |
| — | Newer spells merged with the priest split, summon evolutions and later classes | The spell branch and the two summon branches were built in parallel and merged; decisions: (1) **Rot** lives in `CombatResolver.damage_enemy`, the one damage path, so every source gets the bonus, summons included (Frost Wraith bolts, Lich blasts, Rogue dashes and bleeds, stomps, swoops, the Bishop aura, Death Knight cleaves). (2) **Corpse Explosion** records a corpse in `CombatResolver._kill_enemy` for every kill whoever made it; a Lich kill also feeds the Lich raise (the raise hook runs first), so one enemy can both rise and leave a corpse. (3) **Soul Rapture's spare lifesteal** picks the summon whose wound is largest **after its barrier** (Shieldwall / Warder / Bishop barriers count as HP), and skips summons still rising and airborne Gargoyles (which are also outside the ally grid while flying). (4) **Card pool with 15 active ids** (7 spells, 8 offerable summon classes) for 6 active slots: no extra rule was added. New spells keep weight 1 each and new summon classes share 3, so at the start new spells carry 6 of the 9 new-active weight; Shadow Bolt can never be lost. Naive survey after the merge (`--mortal`, seeds 1-4 and the default 1337): every run owned 2-4 spells (Shadow Bolt plus 1-3 others), 1 of 5 died before 0:00 (seed 1 at 11:29), Sir Alaric died in 2 of 5. The weakest run (seed 4: Shadow Bolt + Blast with Warriors, Mender, Warder and Frost Wraith) survived but did little damage: a careless support-heavy build, as intended for the naive bot. (5) **Focused bots**: the build-list rule (never take a NEW item off the list; reroll or skip) now covers `army`, `evolve` **and** `summon` (`Autotest._build_list()`), so the later classes and the newer spells only enter those builds through chests; `--classes` and `--spells` items are exempt and come first. The army list stays its intended summoner build (Warriors, Archers, Mages, Menders, Warders). The summon bot also **keeps active slots for its evolution bases** (Warriors, Mages, Menders, Warders; a merged-away class counts as owned), like the `--spells` slot reservation: with seven spells a chest once handed it Soul Siphon and an early Shadow Blast filled the last slot, so the Warder and the Profane Bishop never came. (6) `Arena.free_point()` adds `ArenaData.FREE_POINT_MARGIN` (0.5 px) to every push-out: in 32-bit floats a sub-pixel push far from the origin could round away, which once left a Rogue's dash ending inside an obstacle (a stuck unit in the `--classes` run). Post-merge verification (zero errors / warnings and stuck_units 0 in every run): default and `--mortal` (seed 1337) build complete 16:23, Sir Alaric slain, lowest HP 106; army 16:54, Death Knight 8:36, Void Barrage 13:50, lowest HP 111; summon gets Death Knight 9:52, Lich 10:33, Profane Bishop 13:33; evolve gets Void Barrage 8:03, Abyssal Detonation 8:42, Eclipse Ward 11:57; `--spells` with all four newer spells evolves Soul Rapture 9:43, Ossuary Lance 10:27, Grave Eruption 11:15, Pestilence 11:45; army `--classes` with the four later classes completes at 15:34. Army `--mortal` seeds 1-4: 0 deaths before 0:00, lowest HP 71 / 112 / 111 / 101, Sir Alaric 4/4, build complete 15:57-16:57, Death Knight 8:01-12:40, Void Barrage 11:11-13:57. |
| — | Multi-stage framework | Every stage-specific number lives in one stage file (`scripts/data/stages/graveyard_stage.gd`, `crimson_march_stage.gd`) behind `StageRegistry`: wave segments, timeline events, the boss and its arrival time, the Reckoning flavour, empowered graves / desecration / Crypt Defender data, the obstacle layout, the ground look, stage HP / damage multipliers and the Soul Ash multiplier. `WaveData` and `ArenaData` keep only the shared run rules (20:00 countdown, enemy time scaling, caps, spawn ring, structural obstacle limits). A `RunConfig` (stage today; the hook for a later pre-run difficulty / modifier step) goes from the menu through `Main` into `Game`; Restart reuses it. Bosses share a `Boss` base class (`EnemyDirector.boss`). The refactor changed nothing in the Graveyard: same-seed autotest runs (default, `--mortal`, `--policy=army`) are identical line for line to the pre-refactor build. |
| 3 | Stage select and unlocks (§9.3, §10.2) | **Play** opens a stage select (keyboard / mouse / controller) with one card per stage: chapter, name, short description, a code-drawn emblem, and either the lock requirement or the stage's best time, boss kills and Soul Ash bonus. The Crimson March unlocks after Sir Alaric is slain **once** in any run (GDD §9.3 "defeating a stage's final boss unlocks the next chapter"). The save gains a `[stages]` section with per-stage runs, victories, best time and boss kills; a save without it (older build) is migrated additively: its lifetime stats become the Graveyard record, so an earlier Alaric kill unlocks the march. Locked stages stay focusable so their requirement can be read. The autotest's `--stage=` ignores locks. |
| 3 | Stage 2 zone progression vs the fixed timeline | **The clock is authoritative.** The Crimson March runs the same 20:00 countdown (boss with 3:00 left, Reckoning at 0:00). Its "interconnected battle zones" are four zones on fixed times: I The Burned Road (0:00), II The Fortified Checkpoint (4:00), III The Siege Camp (9:00), IV The Fortress Approach (15:00). At each change the HUD announces the zone, a fog of war sweeps the field and the terrain around the necromancer is rebuilt as the next zone (its own ground look and obstacle layout, with a clear circle around him; an old road along the march axis always stays open). Outposts, ward generators and supply carts are timeline events placed near him, so geography can never soft-lock a run and Marshal Vael always arrives at 17:00. |
| 33 | Crimson March timeline and roster | GDD §8.2 beats at real times up to 15:00; the 18:00 and 20:00 beats move to 16:00 and 16:30 and Marshal Vael to 17:00, like the Graveyard's compression. Mapping: *Patrols* = recruit / footman squads; *Fortified checkpoint* = a Checkpoint Watchtower outpost plus a shieldbearer line; *Templar ambush* = a Templar ring; *Siege outpost* = two Siege Outposts; *Heavy infantry* = Crimson Halberdiers with Covenant Shieldbearers; *Ward generator* = two Holy Ward Generators; *Cathedral defenders* = Chaplains, Banner Bearers, Templars and heavy infantry; *Fortress assault* = a large ring wave. Supply carts roll past at 2:30, 6:40, 10:30 and 13:20. The Graveyard's empowered graves return as "the battlefield dead" (same schedule and rewards). |
| — | New Covenant enemies (Stage 2) | Data-driven in `MarchEnemyData`, each with its own silhouette and counterplay, all body-blocked by warriors and frozen by Stasis like any enemy. **Covenant Shieldbearer** (heavy infantry, tower shield): takes 60% less damage from projectiles (Shadow Bolt, Void Barrage, skeletal arrows, mage bolts); warriors, bashes, Shadow Blast and orbs hit it normally. **Banner Bearer** (GDD §7.2 buffer, elevated target priority): advances like a Chaplain and buffs every Covenant soldier within 110 px (damage +15%, speed +15%, damage taken −10%); summons focus it. **Crimson Halberdier** (heavy infantry): slow and armoured, its halberd hit on a summon also cleaves up to 2 neighbours for 40% (punishes packed ranks; kite it or heal the line). Structures are pooled enemies too (`is_structure`): never recycled, no target picking, a Soul Nova treats them like elites. All numbers `TUNING`. |
| — | Crimson March objectives (§7.4) | **Outposts** (a Checkpoint Watchtower at 4:00, two Siege Outposts at 9:00) send a squad every 12-14 s while the necromancer is within 760 px, until destroyed; destroying one pays an XP burst. **Holy Ward Generators** (two at 15:00, 160-210 px away) each sustain a holy zone (105 px: burns and slows undead, stings the necromancer, blocks summon replacement) that collapses when the generator falls; each drops an XP burst and a chest. **Supply carts** roll past the necromancer (a straight path 90 px off his position) with an escort and escape after 30 s; destroying one pays an XP burst and a power-up (Grave Feast, Soul Magnet, Hyper, Dark Frenzy in turn, no RNG). |
| — | Marshal Vael (§7.5) | 32,000 HP (×1.1 stage HP = 35,200; his Shieldwall, Holy Standard and Last Stand make him tougher than Sir Alaric in practice), arrives at 17:00, always drops a chest, a power-up and a 450 XP burst. **Radiant Cleave**: a telegraphed gold sector (120 px, ~115°, 1 s); summons inside take the blow and each soaks 15% of the necromancer's damage (up to 75%), the undead body-block rule. **Crusader's Command**: rally banners, then a shield line of footmen, shieldbearers and archers forms on the far side of the necromancer (a telegraphed pincer). **Holy Standard**: a marked spot, then a destructible standard whose aura buffs the Covenant and Vael for 15 s (kill it or pull Vael away). **Shieldwall** (frontal resistance): a 4 s stance with a gold-rimmed raised shield and a slower walk in which every source except close-range blades (warriors, bashes) deals 50%: spells and projectiles come from the necromancer's side, blades reach around the shield. **Last Stand** below 30% HP: melee 40% faster, specials sooner with 20% shorter windups, a Crusader's Command at once. With no gap-closer (Alaric has Divine Charge), he strides at 1.8× speed while more than 220 px from the necromancer (still slower than him). Stasis freezes him for half its duration and pauses his telegraphs and marks. |
| — | Crimson March balance (first pass) | Stage step-up: enemy HP ×1.1 and damage ×1.05 on top of the shared time scaling, tougher kinds earlier (Shieldbearers from 4:00, Templars at 6:00, Banner Bearers from 9:00, Halberdiers from 12:00), objectives that push back. Measured with the autotest bots (`--stage=crimson_march --mortal`, meta none, **4 seeds** per policy, a combined balance pass follows): **army** never dies before 0:00 (lowest HP 76-102), kills Marshal Vael in 3 of 4 runs (in 132-187 s; the fourth left him at 2,900 / 35,200), completes its build at 15:29-16:00, evolves Void Barrage at 11:15-12:18, opens 4-8 chests and earns 455-561 Soul Ash (stage bonus included). **Naive** dies before 0:00 in 1 of 4 (at 7:11), kills Vael in 1 of 4, earns about 375-550 when it survives. First level-up at 0:23-0:27. The first tuning passes (Vael 46,000 HP, cleave 30 on summons, larger 16:00 / 16:30 waves, no forced march) let the army collapse at 16-17 min and never kill him; the fixes were the forced march, a weaker Radiant Cleave on summons, smaller pre-boss waves, lower XP on the new kinds and structures, and chests from ward generators only. |
| 39 | Stage Soul Ash bonus | A run on the Crimson March earns ×1.25 Soul Ash: a separate end-screen line ("The Crimson March bonus (x1.25)") worth 25% of the run's subtotal, next to Ash Harvest and the Pact / Oath lines. The Graveyard's multiplier is 1.0 (no line). |
| — | Stage 2 merged with the new summons and spells | The multi-stage branch was built from the pre-summon base and merged last. Decisions: (1) **Shared vs stage data.** `ArenaData.FREE_POINT_MARGIN` stays in `ArenaData` (a structural collision rule for every stage); the run length, evolution time gate and its card hints still read the shared `WaveData.RUN_DURATION` / `EvolutionData.MIN_ELAPSED`, and empowered graves / the battlefield dead still raise temporary summons through `HordeDirector.spawn_temporary` (stage data via `game.stage_def`). (2) **Melee sources for Vael's Shieldwall** (`MarchEnemyData.MELEE_SOURCES`): Warrior strikes and bashes (temporary and Lich-risen skeletons too), the Death Knight's strike, bash and cleave, the Abomination's fists and stomp, the Rogue's stab, dash and bleed, the Gargoyle's claws and swoop, and the Profane Bishop's aura (a pulse around the Bishop reaches behind the shield; it now has its own `bishop_aura` damage tag, separate from the Bishop's bolts). Everything else, the new spells included, is blocked from the front. (3) **Projectile sources for the Shieldbearer's tower shield** (`PROJECTILE_SOURCES`): Shadow Bolt, Void Barrage bolts and shards, Bone Spear and Ossuary Lance, arrows, mage and Lich blasts, Frost Wraith bolts and the Mender / Warder / Bishop bolts. Corpse Explosion, Grave Eruption, Plague Cloud, Pestilence, Soul Siphon / Rapture, Shadow Blast and Orb Shield are not projectiles. (4) **Rot** is applied after the enemy-side modifiers (tower shield, aura buffs, Shieldwall) in `CombatResolver.damage_enemy`. (5) **Structures** (outposts, ward generators, carts, the Holy Standard) stay normal targets for summons and spells, but are immune to the Frost Wraith's Deep Freeze (a frozen building would stop its own timers; the Stasis power-up still holds them) and the Wraith never spends a Deep Freeze on one; they leave no corpse for Corpse Explosion and never rise as Lich skeletons; Soul Siphon tethers them only when no soldier is in range (by HP they would always be the "strongest"). (6) Dread Sovereign is earned by slaying either stage boss with the four GDD roles. (7) **Card pool, revised**: the first post-merge Crimson March check had the army bot collapse (seed 1337: no Mages or priest order offered, about 770 kills in 20 min). With one shared pool over all eight summon classes each GDD class drew at 0.375 next to seven spells at 1.0. Now only the four later classes share `NEW_SUMMON_POOL_WEIGHT` (lowered to 1.5, UnitData `shared_card_pool`); Archer, Mage, Mender and Warder keep the full weight 1 of a new spell (4 + 1.5 new-summon weight against 6 new-spell weight at the start). This supersedes the 3.0 single pool of the "Card pool with many summon classes" row. (8) **Army bot slot reservation**: like the summon bot, the army bot keeps active slots for the core classes it lacks (Warriors, Archers, Mages, Menders, Warders: with Shadow Bolt they fill all six slots), so it no longer takes Shadow Blast early and then misses its Mages. Chests still ignore the policy and can grant it a spell. Post-merge verification (zero errors / warnings, stuck_units 0 in every run). **Graveyard** (seed 1337): army, summon and evolve kill Sir Alaric (summon: Profane Bishop 10:51, Lich 11:46, Death Knight 13:49; evolve: Void Barrage 8:00, Eclipse Ward 9:13); the naive default run did not kill him and its `--mortal` twin died before 0:00. Army `--mortal` seeds 1-4: 0 deaths, lowest HP 82 / 37 / 109 / 106 (seed 2 dipped at 9-10 min), Sir Alaric 4/4, build complete 16:03-17:05. **Crimson March** (seed 1337): naive default, army, summon (Death Knight 9:56, Lich 11:05, Bishop 11:44), army `--classes` with the four later classes and `--spells` with the four newer spells (all four evolve 8:01-10:14) all kill Marshal Vael; the naive `--mortal` run died. Army `--mortal` seeds 1-4: 0 deaths, lowest HP 88 / 102 / 59 / 67, Marshal Vael 2/4 (the pre-merge Stage 2 branch: 3/4, lowest HP 76-102). Seed 4 never got Mages: a chest granted Plague Cloud into the slot. The Crimson March is harder for the army bot with both priest orders and seven spells in the pool; left for the combined balance pass. |
| 27, 7 | Treasure chests upgrade only what you own | Survivor-genre convention, decided in the combined balance pass: a chest grants ready evolutions first, then upgrades of spells, summon classes and passives the player already **owns** (drawn with the normal card weights), and Dark Restoration when nothing owned can rise. It never puts a new item into an empty active or passive slot (`ChestData.GRANTS_NEW_ITEMS` = false; `AbilityManager._owned_only()`). With 7 spells and 8 summon classes in the pool, chests had started deciding builds: one put Plague Cloud into the slot an army build had kept for Mages (Crimson March seed 4: no Mages, Marshal Vael survived), and others rescued builds by granting a class the hands never offered. This supersedes "drawn from the normal weighted level-up pool" in the treasure chest row above; slots are now only filled by level-up choices. |
| — | Combined balance pass | The priest split, the summon evolutions, the four later classes, the four newer spells and Stage 2 had been tuned separately. Measured with the autotest bots (`--mortal`, meta none unless noted; 8-seed screens, confirmed with 16 seeds for army / naive and 8 for summon and meta max on each stage). Changes (all `TUNING`): (1) **Chests upgrade only owned items** (row above). (2) **Card weights.** The GDD summon roles get `LevelUpData.WEIGHT_NEW_CORE_SUMMON` 1.5 as new cards, the Mender and Warder half of it each (one Priest role split in two, UnitData `new_card_weight_mult` 0.5), and the four newer spells share `NEW_SPELL_POOL_WEIGHT` 2.0 like the later classes share 1.5 (AbilityData `shared_card_pool`; Orb Shield and Shadow Blast keep 1.0). Owned upgrades stay 2.5. With owned-only chests a Graveyard army run never saw a Mage or Warder card in 24 level-ups and collapsed (level 22 at 20:00). This supersedes the new-card weights of the two "Card pool" rows above. (3) **Crimson March opening.** The stage multipliers (×1.1 HP, ×1.05 damage) apply to regular enemies from Zone II, 4:00 (`enemy_mult_from`; Marshal Vael always gets them), and the first two patrols and the 1:00 trickle are recruits only. From 0:00, ×1.1 lifted a 14 HP recruit above the starting Shadow Bolt's 15 damage, halving early kills: 6 of 8 army runs had about 30 foes alive at 1:00 instead of 15 and 4 never recovered. (4) **Outposts** stop at the segment's soft cap like the trickle (`EnemyDirector.soft_cap()`; they used to fill the field to 170) and send melee squads only (an outpost a weak army cannot raze sent about 180 archers per run). The 6:00 Templar ambush is an arc of 2 Templars + 1 elite + 8 footmen (was a ring of 4 + 1 + 6). (5) **Necromancer regeneration** 0.3 → 0.5 HP/s: with fewer priests in careless builds, they died of 200-300 HP of chip damage at 6-10 min. (6) **Outliers, by per-source damage:** Corpse Explosion Lv 1-5 deals 22/26/26/30/34 every 2.4/2.4/2.2/2.2/2.0 s (was 24-40 every 2.2-1.6 s; about 165k unevolved in naive runs, mage about 90k); Grave Eruption 26 damage, 2 corpses, every 1.6 s, chain 2 (was 36 / 3 / 1.3 s / 3; 145-306k with the four spells forced, 2-3x the other three evolutions); Plague Cloud 2/2/2/3/3 per tick, 3-4.5 s, every 3.8-3.4 s, Rot unchanged (was 3-4 per tick, 3.5-5 s, every 3.4-3.0 s; 150-230k unevolved at Lv 4 in naive Crimson March runs); Lich ×1.2 damage, no extra splash and no faster casts (was ×1.35, ×1.25 splash, ×0.85 attack interval); Frost Wraith bolts 12 damage (was 8; about 18k per run at Lv 5, the other later classes 73-120k). **Results, baseline → final** (deaths before 0:00 / boss kills / lowest HP of survivors / build complete / Soul Ash, medians): Graveyard army 0/8, 8/8, 37-112, 16:28, 455 → 0/16, 16/16, 101-116, 16:18 (16:00-17:18), 456; first evolution 12:52 → 11:29, 26 of 32 evolutions at 10-14 min, 5 chests (5-7). Crimson March army 0/8, **2/8**, 31-102, 4 of 8 builds complete, 384 → 0/16, **16/16** (Vael in about 139 s), 70-112, 16:11 (15:15-17:00), 559; 24 of 32 evolutions at 10-14 min, 7 chests (5-10). Summon: Graveyard 0/8, 7/8 → 0/8, 8/8 (lowest HP 100-116, build 18:31); Crimson March 1/8, 5/8 → 1/8, 7/8 (81-115, 7 of 8 builds at about 17:20). Meta max: every bot kills both bosses, lowest HP 128-164, builds at about 15:15-15:30, and the Reckoning still ends every run 23-43 s past 0:00 (baseline 23-53 s). Naive: Graveyard 4/8 deaths, 0/8 kills → 8/16 (7:05-19:03), 3/16; Crimson March 3/8, 0/8 → 11/16 (6:34-19:04), 0/16. Top sources (share of all damage, max in one run): army Void Barrage 30% (43%), mages 19%, archers 17%; Crimson March army Void Barrage 24%, mages 23%; summon build Lich 33% on the Graveyard (max 38%, baseline 29% / 45%) and 28% on the Crimson March (max 31%). Strong builds kill everything that spawns, so their shares mostly show which source lands the kill first: cutting the Lich's damage alone did not move its share; its splash and cast rate did. Forced items (`--classes` with the four later classes, `--spells` with the four newer spells, 2 seeds per stage): Abomination 43-93k, Rogue 56-77k, Gargoyle 68-116k, Frost Wraith 21-27k plus about 300-430 Deep Freezes; Grave Eruption 91-200k, Ossuary Lance 82-102k, Soul Rapture 53-134k, Pestilence 88-142k (evolved parts). No special ran overtime or ended inside an obstacle; stuck_units 0 in every run. **Open:** naive builds remain below target (dies 20-40%, kills the boss 25-50%), most on the Crimson March; see the README known limitations. |
| 37 | Difficulty levels (§8.4) | User request. The four GDD levels are data in `DifficultyData` (all numbers `TUNING`); the chosen level is `RunConfig.difficulty_id`. **Necromancer** is the standard game (every value ×1, so a Necromancer run with no run modifiers is bit-identical to the game before difficulty levels: same-seed autotest summaries match on both stages). Each level sets: enemy HP and damage ×, the **growth** of the time scaling ×(`hp_scaling` / `damage_scaling`: HP = 1 + s × (0.10 m + 0.013 m²)), trickle spawn rate / soft cap ×, enemy move speed × (not the boss), a trickle-elite chance, boss HP ×, Soul Ash × and XP ×. **Initiate** ("easier scaling"): HP ×0.9, damage ×0.8, growth ×0.75 (×0.70 HP and ×0.66 damage by 0:00), boss ×0.8, Soul Ash ×0.8. **Lich** ("increased HP / aggression"): HP / damage ×1.05, growth ×1.25 / ×1.2 (×1.28 / ×1.20 by 0:00), move speed ×1.05, boss ×1.15, Soul Ash ×1.25. **Deathlord** ("hardest, with more elites"): HP / damage ×1.05, growth ×1.4 (×1.42 / ×1.35 by 0:00), move speed ×1.06, 0.8% of trickle soldiers promoted to elites, boss ×1.3, Soul Ash ×1.5. Spawn rate and XP stay ×1 on every level. Tuning notes: (1) the difficulty is put in the **growth**, not the opening: a harsh start (HP ×1.3, spawns ×1.2, speed ×1.12) made the army bot collapse in the first minutes on 2 of 3 seeds, and a collapsed army never recovers; (2) **more spawns and XP bonuses made the hard levels easier**: the extra kills' XP completed builds about a minute early (15:10-15:40 instead of 16-17 min); (3) **promoted elites are a threat, not a loot source**: elite HP and size, but the base soldier's XP and no elite chest / power-up chance (`Enemy.is_promoted`; with elite loot Deathlord runs got 8-10 chests). The trickle-elite roll uses the gameplay RNG only when the chance is above 0. |
| 38 | Run modifiers (§8.5) | User request. All eight GDD modifiers are data in `RunModifierData` and stack freely (`RunConfig.modifiers`). **Endless Crusade** +30% spawn rate and soft cap (GDD), **Hardened Faith** +25% enemy HP (GDD; the boss gets `PactData.BOSS_HP_SHARE` = a fifth of it, like the Pact), **Divine Fury** +20% enemy damage (GDD); `TUNING`: **Purge the Unholy** = the Purifier share of every trickle segment ×2.5 and Purifiers (weight 0.08) in segments without them from 3:00; **Scarcity** = Grave Feast drops 60% rarer (weight ×0.4) and healing half as much; **Frail Master** = starting max HP ×0.7 (after Soul Ash upgrades; +max HP cards add on top); **Vengeful Dead** = summon damage +20% and max HP −30% (their own stacking category in `HordeDirector.compute_stats`); **Holy Retribution** = a slain elite (not the boss or a structure) bursts into a ring of 8 radiant bolts (9 damage × the enemy damage scaling, 150 px/s, 300 px reach; Covenant projectiles: Orb Shield intercepts them, they hit the necromancer or the first summon; the ring is aimed at the player, no RNG). Soul Ash rewards (`TUNING`): Crusade, Faith and Fury +20% each, Purge, Frail and Retribution +15%, Scarcity and Vengeful +10%; +125% with all eight. Modifiers give no XP bonus. |
| 37, 38 | How difficulty, run modifiers, Pact and Oath combine | One path, `DifficultyModifiers` (GDD §6.4 "add like-category bonuses, multiply separate categories"): the **difficulty level is its own category** and multiplies once; the **opt-in modifiers** (the §8.5 run modifiers, the Profane Pact and the Profane Oath) are **one category** whose bonuses of a key **add**. Enemy HP = time scaling (growth × level) × stage × level HP × (1 + Pact + Oath + run modifiers), likewise for damage and the spawn rate; the boss gets level boss HP × (1 + 20% of the opt-in HP bonus). XP: level × (1 + Pact + Oath XP reward), next to Grave Tithe. **Soul Ash**: every source pays its own floored line on the run subtotal and the lines add (Ash Harvest, Pact, Oath, stage bonus, **Difficulty** = (level ×ash − 1) × subtotal, negative on Initiate, and one **Run modifiers** line = the summed rewards). The setup screen's "total Soul Ash reward" is level ×ash + the modifiers' rewards (e.g. Deathlord with every modifier ×2.75); a note names an active Oath tier, which adds on top. |
| 37, 38 | Pre-run setup screen (§10.2) | After the stage select, **Prepare the Ritual** shows the four difficulty cards (one selected; each lists the GDD effect and every number that differs from the standard level) and the eight run-modifier cards (effect, Soul Ash reward, ON / off), the stacked total Soul Ash multiplier and the combined enemy multipliers (at the start and by 0:00), with Back, Standard (Necromancer, no modifiers) and Begin. Keyboard, mouse and controller navigable with explicit focus neighbours; Esc / B returns to the stage card. The last confirmed choice is remembered in the Meta save (`[prerun] difficulty` and `modifiers`, a comma-separated id list; additive: an older save without the section gets Necromancer and no modifiers, unknown ids and wrong types are dropped), and Restart keeps it (`RunConfig.duplicate_config`). **All levels are open from the start**: the GDD implies no difficulty unlock (§9.4 only names an achievement for clearing the Graveyard on Lich). The HUD Modifiers area shows the difficulty, the run modifiers (short names) and their Soul Ash multiplier above the Pact / Oath lines; the end screen lists the difficulty and the run modifiers in the run column and their two Soul Ash lines. Autotest: `--difficulty=ID` and `--modifiers=a,b` (or `all`); the summary adds a `difficulty` line (every effective multiplier and the Soul Ash parts) and a `difficulty results` line. (The screen's presentation was rebuilt since: see "Pre-run setup layout" and "Pre-run setup: the character is the hero"; the numbers moved to tooltips.) |
| 43 | Naming collisions (difficulty names) | The GDD names are kept (Initiate, Necromancer, Lich, Deathlord). The UI always says "Difficulty: Lich" (HUD, end screen, setup screen header), so the level never reads as the player character or the Lich summon evolution. |
| — | Difficulty and run modifier measurements (first pass) | Autotest bots, Graveyard, `--policy=army --mortal`, meta none. **Necromancer** with no modifiers reproduces integration 0a7470b exactly (same-seed summaries identical apart from wall-clock lines, default and army `--mortal`, both stages); seeds 1-4: 0 deaths, lowest HP 82 / 37 / 109 / 106, Sir Alaric 4/4, builds complete 16:03-17:05, Soul Ash 440-466. **Initiate** seeds 1-4: 0 deaths, lowest HP 106-114, Alaric 4/4 (killed at 18:29-19:00), builds 16:15-16:47, Soul Ash 368-393. **Lich** seeds 1-2: 0 deaths, lowest HP 101-107, Alaric 2/2 (about 30 s later than on Necromancer), Soul Ash 546-557. **Deathlord** seeds 1-6: all reach 0:00 (lowest HP 63 / 109 / 88 / 95 / 103 / 1: seed 6 drew no ranged class early and limped through on 1 HP), Sir Alaric slain in 1 of 6 (the others leave him at 5,500-54,200 of 54,600 HP), builds 15:57-19:13, 19-38 trickle elites, Soul Ash 690-828. Run modifiers, one at a time (seed 1337; Necromancer reference: lowest HP 111, Alaric slain, 459 ash): Endless Crusade 109 HP (5,760 kills, build at 15:12: the extra kills' XP), Hardened Faith 19 HP (the army fell behind early, 757 kills, Alaric barely scratched), Divine Fury 104, Purge the Unholy 108 (920 Purifiers slain instead of 435), Scarcity 113, Frail Master 75 (84 max HP), Vengeful Dead 110, Holy Retribution 111 (15 bursts, 164 damage to summons, none to the necromancer); every run reached 0:00 and all but Hardened Faith killed Alaric. All eight stacked: 66 HP, Alaric slain, Soul Ash 1,125 (subtotal 500 + 625); all eight on Deathlord on the Crimson March (invulnerable bot) and stacked with the default bot ran clean. Zero script errors / warnings and `stuck_units=0` in every run. |
| — | Skeletal Archer stance | User decision: archers **hold their ground and fire**. The GDD §29 45 px step-back (kiting) is removed (`kite_distance` 0) and their threat-avoidance steering is cut to the Warriors' level (`w_threat` 0.6 → 0.1). Like every summon they still follow the formation and leash rules. |
| — | Art style and pipeline | User decision: **pixel art** (ART_BIBLE Style B), set by the approved necromancer sprite. Sprites are generated in ChatGPT from `docs/art/ART_BIBLE.md` (top-down three-quarter view, facing right, transparent background, the §11 colour language), processed by `tools/prepare_sprite.py`, and drawn by `SpriteBank` when present, falling back to the code-drawn glyphs. One still image per unit; motion, flashes, facing and shadows are done in code. |
| — | Army spacing and depth sorting for sprite art | User decision after the first rendered screenshots: the summon and enemy containers are **depth-sorted** (lower on screen draws in front; purely visual), and every formation band and the ally separation distance are widened **×1.3** (`UnitData.FORMATION_SPREAD`, `SEPARATION_SPREAD`) so 44-88 px sprites stop merging into one blob. Body-blocking radii are unchanged. |
| — | Evolution icon marker | User decision: evolution icons (spell and summon evolutions, Shadow Mastery) are marked by a **gold border on the icon box** instead of a gold ring, so sprite art keeps the whole box. |
| — | Effect animations | User decision: visual effects may be **short sprite-sheet animations** (ChatGPT sheets or GIFs, 6-10 frames, pixel art) rather than still images. `tools/prepare_sprite.py --anim` converts them to strips of square 128 px frames in `assets/sprites/effects/`; `Effect` plays the strip once, scaled to the effect's radius (`AnimData` timing and fill), and falls back to the drawn shape without the file. Purely visual. Shadow Blast is the first (test) hook; the others are wired as their art arrives. |
| — | Camera zoom and player marker | User decision: the fixed 1.5× camera zoom (chosen for the small code-drawn shapes) is replaced by a **Zoom setting** (Close 1.25 / **Normal 1.0**, default / Far 0.8; `ViewData`). Gameplay distances (spawn ring, on-screen checks) use the visible area at 1.0 or wider, so Close plays like Normal and the autotest always uses 1.0. Moving from 1.5 to 1.0 widens the spawn ring (enemies arrive a little later), left for the final balance pass. A soft green **ground ring** marks the necromancer so the player is easy to find among similar summons. |
| 28 | Later horde passives | User request. The four remaining GDD §6.2 / §34 passives exist as 5-level horde passives (`PassiveData`, all `TUNING`), dead cards while no summon class is owned; their NEW cards share `LevelUpData.NEW_PASSIVE_POOL_WEIGHT` = 2 (like the later classes and spells) so they do not crowd early hands. **Bone Plating**: every hit on a minion loses 2/3/4/5/6 damage, after the Unholy Host and Unholy Resilience and before barriers; a hit keeps at least 25% of its damage (`PLATING_MIN_FRACTION`, so weak early swings still land), and holy-ground ticks are exempt (a field, not a hit). **Unholy Precision**: minion attacks crit 5/10/15/20/25% of the time for ×2 damage (`CRIT_DAMAGE_MULT`): basic attacks of every class, evolution and Lich-raised skeleton, bashes, Death Knight cleaves, the Bishop's aura, stomps, dashes and swoops, but not the Rogue's bleed ticks nor the necromancer's spells (the source lists are data in `PassiveData`). The rolls use their own `RandomNumberGenerator` in `CombatResolver`, seeded from the autotest seed like the chest and power-up rolls, so the gameplay RNG stream is untouched and runs stay deterministic per seed. **Unholy Resilience**: minions take 8/15/21/28/35% less **area and holy** damage; the classification is data (`PassiveData.AREA_HOLY_SOURCES`): area = Sir Alaric's Hammerfall, Marshal Vael's cleave, Halberdier sweeps; holy = Judgment, Purifier holy fire, holy ground (grave consecration, Holy Ward Generators, boss zones), Holy Retribution bolts. Charges (Templar, Sir Alaric) are body hits, not areas. **Bound Souls**: minion move speed +6/12/18/24/30% (its own category), engagement leash and soft recall +10/20/30/40/50% (220 / 320 px; the 650 px hard recall is unchanged) and the return trip after a recall takes 10-50% less time (RETURNING speed divided by 1 − value), all through `HordeDirector.compute_stats()` into per-unit fields. Each passive's card already names the summon evolution it will unlock (not built yet): Bone Plating → Abominations become **Bone Colossi**, Unholy Precision → Archers become **Gravebows**, Unholy Resilience → Gargoyles become **Cathedral Horrors**, Bound Souls → Rogues become **Shadow Reapers**, and Soul Recycling → Frost Wraiths become **Winter Revenants** (this replaces the GDD §6.1 pairing of Bone Plating with the Warriors' Dreadguard Legion: the Death Knight already uses Dark Command). Autotest: a `horde passives` summary line (levels, damage prevented by Plating and Resilience split area / holy, crits and their extra damage, soft and hard recalls), `--passives=a,b` forces passives like `--spells`; the army and summon bots list them below their baseline passives and take one NEW only once Grave Dominion is owned (an early Unholy Precision once filled the last slot before Grave Dominion and that army starved). Checks with forced passives (`--passives`, seed 1337): Graveyard army run Plating 24k damage prevented, Resilience 4.8k (almost all holy), 318 crits; a run with the four later classes, 3,562 crits worth 51k extra damage. |
| 27 | Every evolution requires its paired passive at Lv 5 | Owner rule. All ten evolutions need the paired passive at its **max level (5)**: the seven spell evolutions (`EvolutionData.PASSIVE_LEVEL_REQUIRED` 1 → 5) and the Profane Bishop (`SummonEvolutionData` `passive_level` 1 → 5; the Death Knight and Lich already needed Lv 5). Delivery is unchanged (the next treasure chest, from 8:00 elapsed, the 40 s evolution pity while one waits), and every card text says so ("Evolves into Void Barrage at Lv 5 with Soul Conduit Lv 5", "... once this is Lv 5"). The evolve, summon and `--spells` bots already level their paired passives, so they keep evolving. 4-seed screen against the previous main (`--mortal`, seeds 1-4, meta none, Graveyard): **evolve** Void Barrage 8:02-8:04 (was 8:02-8:06), Abyssal Detonation 8:43-12:39 (was 8:43-11:15), Eclipse Ward 9:45-12:59 in 4/4 (was 8:45-10:04 in 3/4), Death Knight 14:27-15:19 (was 13:42-15:25); 0 deaths, lowest HP 74-93 (was 67-111), Sir Alaric 3/4 (was 4/4). **army** (with the later passives available) Death Knight 9:51-14:55 (was 9:49-13:41), Void Barrage only 2/4 and late, 16:33 and 17:09 (was 4/4 at 12:45-13:56: its Soul Conduit is a low priority and now has to reach Lv 5), 0 deaths, lowest HP 65-114 (was 110-114), Sir Alaric 4/4, build complete 16:01-16:29 (was 15:58-16:55). `--spells=bone_spear,soul_siphon,corpse_explosion,plague_cloud` still evolves all four (10:04-12:06). No retuning (deferred to the final balance pass). |
| — | Evolution recipe book | Owner decision: evolutions are **meant to be discovered**. There are no new hints on level-up cards or the HUD (the existing card text stays as it was); the only reference is a **Recipes** view in the pause menu that lists the combinations the player has **obtained in any run**. A discovered entry shows the evolution's icon, name and kind and its recipe (base Lv 5, both bases for a merge such as the Profane Bishop, + paired passive Lv 5 -> evolution). Every undiscovered recipe is a locked placeholder (a dark tile of three empty sockets since "Recipes book grid", no names or ingredients) and a count ("3 / 10 discovered") shows that more exist. Discoveries are recorded when an evolution is granted and saved at once in the Meta save's `[recipes]` section (an older save starts with none; the autotest keeps them in memory unless `--meta-save`). The list is built from `EvolutionData` + `SummonEvolutionData` (`EvolutionRecipes`), so new recipes appear automatically. Purely informational: eligibility and delivery are unchanged. |
| 27, 28 | Winter Revenant (Frost Wraith evolution) | Owner-approved. **Frost Wraith Lv 5 + Soul Recycling Lv 5** = **Winter Revenant** ("transform", same chest delivery and 8:00 gate as the other summon evolutions; `SummonEvolutionData`, all `TUNING`). Overlay: ×1.25 HP, ×1.25 damage, radius 12, and **Deep Freeze radius +35%** through a new `special_mult` overlay on the class special (applied in `SummonEvolutions.modify_stats()`, the one summon-stat path). **Shatter** (`WinterRevenant.on_enemy_killed()`, fed by the CombatResolver kill hook): an enemy that dies while Deep-Frozen (`freeze_timer > 0`; a Stasis power-up freeze does not count; bosses and structures never shatter) deals 22% of **its own max HP** to every enemy within 56 px (source `winter_revenant_shatter`) and chills the survivors (0.4 slow, 2 s). **Chain guard:** a shatter never triggers another shatter: kills by shatter damage, and any kill made while a shatter is resolving (on-kill effects inside it), do not shatter; at most 12 shatters resolve per physics tick (the rest are skipped and counted). **Death nova** (`HordeDirector.summon_died`): a Winter Revenant that dies (not a temporary summon, not a dissolved unit) deals 3× its frost-bolt damage within 84 px (source `winter_revenant_nova`) and Deep-Freezes the survivors for 1.2 s through `CombatResolver.freeze_enemy()` (class boss / elite multipliers; Reckoning enemies immune); enemies it kills while already frozen shatter. Bolt damage stays tagged `frost_wraith`. Shatter and nova do not crit (Unholy Precision lists only the basic tags and named specials). Effects: drawn frost rings with the `frost_shatter` / `frost_nova` animation hooks (`AnimData`); sprite key `summons/winter_revenant` (56 px) with a drawn fallback glyph. Measured (`--classes=frost_wraith --passives=soul_recycling`, `--policy=summon` seed 1): first numbers (shatter 30% max HP, nova ×4) made the class 15% of all damage in the Graveyard but 29% on the Crimson March (shatters alone 16%), so they were trimmed to 22% / ×3. After the trim: Graveyard evolved at 8:01, 666 shatters ~22k + 4 novas ~1.5k on ~41k bolt damage (class 13% of all damage); `--policy=army` seed 2 class 10%; Crimson March evolved at 8:51, 452 shatters ~106k + 72 novas ~78k (class 38%: dense formations, higher enemy HP and frequent Revenant deaths; a candidate for the final balance pass). |
| — | Shadow Reaper (Rogue evolution) | Owner-approved. **Grave Rogue Lv 5 + Bound Souls Lv 5**, delivered by a treasure chest from 8:00 like every evolution (mode "transform": units change in place). It **upgrades the Dash Strike** rather than replacing it (`SummonEvolutionData` "special_mult" / "special_set" overlays on the class-special numbers, read by `RogueBehavior`): ×1.35 HP, ×1.25 damage, **dash cooldown ×0.5**; each dash **chains** once: when it ends, the nearest enemy not struck by this chain that passes the normal dash checks (dash_min..dash_length away, an obstacle-free lane that reaches it, a lane end inside the soft leash, the target inside the engagement leash; at most 6 lane checks) is dashed at after a 0.1 s lane flash, and every lane ends on a free point. **Bleeds stack** up to 3 per Reaper on one enemy: each dash hit adds a stack with its own timer and duration (each ticks `bleed_damage`), and at the cap the stack with the fewest ticks left is refreshed. A **kill by a dash hit resets** the cooldown to 0.9 s when the chain ends, at most once per chain (never to 0, so kills cannot loop). Forced summon-bot run (Graveyard, seed 1337): evolved at 8:00, 1,253 chained dashes, 749 resets, max 3 stacks; Reapers dealt about 35% of all damage (0.6 s reset floor: 38%, so it was raised to 0.9 s). |
| — | Cathedral Horror (Gargoyle evolution) | Owner-approved. **Crypt Gargoyle Lv 5 + Unholy Resilience Lv 5**, same delivery. It **upgrades the Swoop** (`GargoyleBehavior`): ×1.4 HP, ×1.25 damage, **swoop radius ×1.3**; the dive **stuns** every enemy it hits for 0.6 s through the new `CombatResolver.stun_enemy()`, which uses the Deep Freeze hold (`Enemy.stun_timer`; EnemyDirector skips AI, attacks and movement exactly as for a freeze; stars instead of the frost shell): the boss gets 25%, elites 60%, Reckoning enemies and structures are immune. After landing it **turns to stone for 2 s**: it stands still and does not attack, **takes no damage** (`SummonedUnit.stone_form`, checked first in `damage_unit()`; the hits are counted as prevented) and, being on the ground, **still body-blocks** like any gargoyle; it is drawn tinted grey under a cracked stone shell, and a recall ends it at once. Forced summon-bot run (Graveyard, seed 1337): evolved at 8:01, 1,051 stuns (44 on Sir Alaric), 454 stone forms, 6.1k damage prevented; Horrors dealt about 21% of all damage. |
| 27 | Gravebow (Archer evolution) | Owner-approved name and pairing (GDD §4.2 / §6.1 "Gravebow Company"; the owner chose the singular **Gravebow**, plural Gravebows). Recipe: Skeletal Archer Lv 5 + **Unholy Precision Lv 5**, delivered like every summon evolution (next treasure chest from 8:00). A *transform* evolution (`SummonEvolutionData`, all `TUNING`): ×1.4 HP, ×1.25 damage, radius 10, arrows **pierce 2** (Lv 5 archers pierce 1); every **4th volley** of a unit (a per-unit counter, deterministic) **splits** into a 3-arrow fan of 0.5 rad (the middle arrow homes as usual; the side arrows fly straight and reserve no damage); every arrow hit **curses** the foe for 4 s. **Curse**: a status timed on game time like Rot (`Enemy.curse_until` / `curse_amp`), applied and resolved only in `CombatResolver` (`curse_enemy()`, `damage_enemy()`); a cursed foe takes **+15% damage from every undead source**. Decision: "undead sources" means **all damage to the Covenant**, the summons *and* the necromancer's spells (every hit on a soldier is undead), except the **Soul Nova**, which deals an exact share of max HP and already ignores enemy-side modifiers (`SummonEvolutionData.CURSE_EXEMPT_SOURCES`). Curses refresh (the stronger amp is kept) and do not stack; the bonus is applied after Rot. Cursed foes show a violet film and rune. Gravebow arrows count as projectiles for tower shields and as archer arrows for Volley of the Fallen. The Gravebow keeps the archer stance (holds its ground). The new card / HUD icon has the gold evolution border; sprite key `summons/gravebow` (52 px). Measured (`--classes=archer --passives=unholy_precision --policy=summon`, seed 1337): evolved 8:55; Gravebow 58k damage (17% of all damage; Liches 124k), curse bonus 15k; Crimson March forced run (Gravebow at 8:02): 171k of 679k (25%; Liches 133k), curse bonus 49k. |
| 27 | Bone Colossus (Abomination evolution) | Owner-approved name and pairing (plural **Bone Colossi**). Recipe: Corpse Abomination Lv 5 + **Bone Plating Lv 5**, chest delivery from 8:00. A *transform* evolution (all `TUNING`): ×1.6 HP; a bigger body (radius 16 → 19) and blocking ring (block radius 20 → 23, mass 8 → 11; the boss, mass 12, still shoves it); **Stomp radius ×1.4** (an overlay on the class special: `special_mult` / `special_set` in `SummonEvolutionData`, applied by `SummonEvolutions.modify_stats()` after the special's suffix scaling). Body and ring grow together on purpose: an enemy held at the ring is `block_radius - radius` px from the body and must reach that far to strike, so the gap stays the Abomination's 4 px (a 26 px ring on a 16 px body was tried and made it unreachable for every melee soldier: no Colossus ever died). `UnitData.MAX_BLOCK_RADIUS` (the padding of every enemy / boss query for summon bodies) is raised **16 → 19** to match; every such query filters by exact distance afterwards, so existing results are unchanged; `HordeDirector.block_query_radius` is also raised on the transformation. **Taunt**: a regular enemy whose centre is within **110 px** of a living Colossus targets it before the necromancer or any other summon (`Enemy._pick_target()` asks `ColossusKit.taunt_target()`; the taunter list is rebuilt at 4 Hz as generation-checked entries). It changes the target choice only: melee soldiers walk at their target as always, ranged ones keep advancing on the player and shoot the Colossus, so enemies still always advance; an enemy already held by a blocker keeps fighting it; **bosses, Reckoning enemies and structures ignore the taunt** (the Reckoning must still end the run). **Bone shrapnel**: when a Colossus is killed (`CombatResolver.damage_unit()`), every enemy within 90 px takes 2× its stomp damage (source `colossus_shrapnel`, a minion special for Unholy Precision crits and a melee source for Vael's Shieldwall) and is knocked back. Sprite key `summons/bone_colossus` (100 px). Measured (`--classes=abomination --passives=bone_plating --policy=summon`, seed 1337): evolved 8:00; ~3,800 taunt redirects, 2 deaths and 2 shrapnel bursts in the run (Colossi rarely die). |
| 10 | Grave Step (the dash) | Owner-approved. **Shift** (gamepad **RB**): a **110 px** shadow step over **0.15 s** in the movement direction (the last one when standing still), **0.2 s of invulnerability** from its start, **5 s cooldown**, charges recharge one at a time. **Available from the first run** (owner decision: no unlock). It passes through enemies and summons (the necromancer never collides with bodies) but **not obstacles**: the step is measured with `Arena.clear_length()` (8 px samples with the player's radius) and ends on `Arena.free_point()`, so it stops short of a gravestone, tree or wall and never ends inside one (a step shorter than 12 px is refused and keeps its charge); the arena has no outer bounds. The army simply follows as when he walks. Visuals: fading violet afterimages along the path and a departure puff (`EffectManager.ring`, anim id `grave_step_trail`). Code `scripts/player/grave_step.gd`, numbers `PlayerAbilityData` (`TUNING`). |
| 10 | Dread Rally (the ultimate) | Owner-approved. **Space** (gamepad **LB**). No cooldown: a **soul meter filled by kills** (owner decision): 1 point per kill, 8 per elite or Crimson March structure, 60 for the stage boss; **240 points** fill it. Measured kill rates between 6:00 and 12:00 (Graveyard, seed 1, `--mortal`): army bot ~205 / min, naive ~165 / min, i.e. a full meter in ~70-90 s mid-game (the first fill takes ~140 s, late-game fills ~40-60 s). The meter persists, caps at full, and kills during the rally's buff do not charge it. Casting it: every summon outside its formation band drops its target and **returns** to the necromancer and the army moves **+120% faster for 1.5 s** (a surge, no teleport); every summon **heals 30% of max HP** (`CombatResolver.heal_unit`); for **8 s** the army gets **+40% damage and +40% attack speed** (`HordeDirector.compute_stats`, its own timed category like Dark Frenzy); enemies within **120 px** are knocked back (460 px/s ÷ mass, so bosses resist, structures never move); a dark burst (`EffectManager.ring`, anim id `dread_rally`), an abyss vortex and a big screen shake. Code `scripts/player/dread_rally.gd`. |
| 10, 39 | Grave Step Ossuary upgrades | Two upgrades through `MetaModifiers` (stats `dash_charges`, `dash_cooldown`): **Twin Shadow** (Survival, +1 charge, 1 tier, 300 Soul Ash, needs Fleet Shade I) and **Restless Shade** (Shadowcraft, the tree of cooldowns: −10% cooldown per tier, 3 tiers, 60 / 120 / 190, so 5 → 3.5 s). Priced like Grave Call (a comparable 3-tier upgrade) and between Fate's Thread and the 450-550 capstones. Buying everything now costs 9,635 (was 8,965), about 21 good runs. The `--meta=mid` profile includes Restless Shade II and Twin Shadow; `max` both in full. |
| 10, 49 | Dash / ultimate input | New input actions `dash` (Shift, pad RB = button 10) and `ultimate` (Space, pad LB = button 9), both **rebindable** in Settings like the other gameplay keys (primary keyboard key). They are read in `Game._unhandled_input()` only while the run is PLAYING, so the Space / A that confirms a level-up card or closes a chest never fires the rally (those panels handle the event and the run is paused). The level-up panel's own LB / RB (banish, skip) only act while it is open. Cooldowns, the meter and the buff run on game time (pause, level-ups and hit-stop freeze them). HUD: bottom centre, flanking the ability bar: the Grave Step icon with one pip per charge and a recharge sweep, the Dread Rally icon with its meter, a pulsing READY border and the buff time (`hud_abilities.gd`); key names follow rebinds. |
| 10 | Autotest use and first measurements | Every bot dashes when 3+ enemies touch a 45 px circle, when hit in the last 0.6 s while in danger, or to leave a boss / stage telegraph, toward the best of 12 directions (clear length, enemies and danger at the landing point, flee direction), and rallies when the meter is full and the player is in danger, the boss is alive or the army is hurt (average HP < 60% or < 70% of capacity alive). Graveyard `--mortal` seeds 1-4 vs the same seeds before: **army** 0 deaths (was 0), lowest HP 112 / 115 / 112 / 104 (was 114 / 112 / 65 / 112), Sir Alaric 4/4 (4/4), Reckoning ends every run 12-19 s past 0:00 (9-28 s); **naive** 3/4 still die before 0:00, later (11:17, 10:41, 15:57 vs 9:51, 9:17, 14:40), seed 4 lowest HP 112 (was 25), Sir Alaric 0/4 (0/4). Safer, not trivial; no numbers changed. Runs stay deterministic per seed. |
| — | Army stances | Owner decision (approved proposal). The player picks one of **four stances** for the whole undead army; a stance only **overrides numbers the horde AI already uses** (formation post shape, chase / engagement distance, soft recall, formation pull), so no unit gets new behaviour code. **1 Escort** (default) is exactly the earlier formation (frontliners on a threat-facing arc, the rest in their bands; chase 220 px, soft recall 320 px), so balance and the bot baselines do not move. **2 Onslaught**: loose, fighters spread toward the nearest enemy groups (enemies grouped by angular sector within 440 px), priests trail the frontline between the necromancer and the fighting; chase 440 px, soft recall 540 px, formation pull cut to a third; exposes the necromancer. **3 Spearhead**: a wedge pointed along the necromancer's last movement direction, blockers ("front" classes) on a V at the tip, melee skirmishers (Rogues) on the flanks, ranged and priests in a small band around the necromancer; chase 150 px; the rear is open. **4 Bone Ring**: a closed circle 60–90 px out with the blockers (and Rogues) spaced evenly all round, ranged and priests inside; chase 110 px; safest, fewest kills. The **hard recall (650 px) never changes**. Posts are resolved with the arena's free-point push-out like the Escort anchors; specials read the stance-adjusted leash. **No stat bonuses at first**: the flavour bonuses (Onslaught +10% army attack speed, Spearhead +30% push on the tip, Bone Ring −10% army damage taken) exist as data behind `StanceData.BONUSES_ENABLED = false`, already wired through `compute_stats` / `CombatResolver`, for a later balance pass. **Unlocks:** Escort, Onslaught and Bone Ring are available from the first run; **Spearhead is bought in the Ossuary** (Necromancy, *Spearhead Doctrine*, 1 tier, 200 Soul Ash, through `MetaModifiers.unlocks()`; the autotest `--meta=mid\|max` profiles own it); a locked stance's key only shows "Locked: unlock Spearhead in the Ossuary" once per run. **Controls:** keys **1–4** (rebindable), controller **right-stick flicks** up / right / down / left (deadzone 0.6, re-armed under 0.25, one flick = one switch); a **1.5 s** game-time lockout between changes; game input only while playing (the level-up panel's 1–3 keys work only while it pauses the run). **Feedback:** a four-icon stance bar beside the army list (active lit, locked dimmed with a padlock; `icons/stance_<id>.png` art plugs in), a one-word banner, a synthesized command sound and a faint 1 s ground outline of the shape; the pause menu lists one line per stance (four compact stance tiles since the menu modernization, see "Pause screen layout"). The stance **resets to Escort every run** (and on Restart). **Autotest:** `--stance=ID` forces one stance for the run (ignoring the lock); otherwise army / summon / evolve switch by a simple rule (Bone Ring when in danger or the boss is close, Onslaught when few enemies are near and a structure is in reach or the screen is nearly clear, Spearhead toward a chest / drop when owned, else Escort) and naive / pact keep Escort, their long-standing baseline; the summary's "army stance" line reports time, kills, army damage taken, hard recalls and unit spread per stance plus the switch count. All numbers `TUNING` in `scripts/data/stance_data.gd`. |
| 3, 4 | Stage 3 structure and timeline (§8.3) | Owner-approved proposal. **The Sanctum of Judgment** is Chapter III, third in campaign order, **unlocked by slaying Marshal Vael once** (same `[stages]` record and lock as the Crimson March), Soul Ash **×1.5** (its own end-screen line). The clock is authoritative as on the March (open question 3): four zones on fixed elapsed times, run by `MarchDirector` (the Sanctum's `march` config has zones only, with a gold banner "THE SANCTUM OPENS - ZONE N" and a dusty-gold light sweep): **I The Outer Courtyards** 0:00-4:00 (pale flagstones; saints' statues, fountains, benches), **II The Sanctified Halls** 4:00-8:30 (gold mosaic, carpet runners; rows of pillars, pews: an `aligned` layout puts each obstacle at its cell's centre), **III The Cloisters** 8:30-13:00 (stone walks and turf; cloister arches, garden beds, cypresses), **IV The Final Sanctuary** 13:00-20:00 (marble with stained-glass light; giant statues, columns, reliquaries). The GDD's 22:00 timeline is compressed into the 20:00 countdown with the boss at **17:00** like the other stages: outer defenders 0:00; sanctified chamber 1 at 3:00 (GDD 4:00); Sanctified Sentinels from 4:00; the **Cathedral Guardian** and chamber 2 at 5:30 (GDD 7:00); Radiant Inquisitors from 6:00; the **High Confessor ambush** at 8:30 (GDD 10:00); **three sacred altars** at 10:30 (GDD 13:00); **Sun Paladins** (elite paladins) at 13:00 (GDD 16:00); the **final sanctuary** wave at 15:30 (GDD 19:00); **Grand Inquisitor Seraphine** at 17:00 (GDD 22:00); the Reckoning at 20:00. Normal waves use the existing roster scaled as the hardest stage: ×1.2 HP and ×1.1 damage from 4:00 (the boss always), the first minute recruits only (the March's lesson). The crypts beneath the cathedral work like the empowered graves. The new kinds are named through stage-local aliases (`SanctumStage.KINDS`: sentinel, confessor, paladin, radiant, guardian; StageRegistry `kind_aliases`, resolved by `EnemyDirector.resolve_kind()`) and the boss slot is Seraphine's own arrival (`SeraphineData.ARRIVAL`); see "Stage 3 integration". Floors and obstacles are drawn in code (ivory, gold, pale stone; `SanctumGround`, `SanctumTerrainGlyphs`); the art bible lists the zone tiles, the ward crystal and the sacred altar. |
| — | Sanctified chambers (§7.4 "ward crystals") | Owner-approved. A chamber is a **220 px** (radius) circle of holy ground centred 250-320 px from the necromancer with **two ward crystals** (structures, `SanctumObjectiveData`, the Holy Ward Generator pattern: pooled enemies, never recycled, top target priority) 110-115 px from its centre. Until both crystals fall, each summon inside takes **3 holy damage per second** (source `holy_zone`, so Unholy Resilience applies; ticked once per second) and **undead minion attacks on a foe standing inside deal 25% less** (one path: `CombatResolver.damage_enemy()` asks `SanctumDirector.minion_damage_mult()` for minion sources; implemented on the target's position because projectiles and specials do not carry their shooter, which for melee is the same rule). Unlike a ward generator's zone it does not sting the necromancer or block summon replacement. Destroying both **cleanses** the chamber: the circle turns into a purple rot stain, the penalty ends, corruption rises and the chamber pays +10 Soul Ash; every crystal pays a small XP burst. Live objectives ask `Arena.keep_clear()`, so a later zone change never rebuilds an obstacle on top of them. |
| — | Cathedral Guardian slot (§7.4, §7.5 minibosses) | Owner decision: the Guardian is a **plain miniboss** (it does **not** shield the crystals). At 5:30 one Guardian walks in from the spawn ring (never recycled), shows on a **generic miniboss bar** under the timer (`EnemyDirector.set_miniboss()`, HUD), and drops a **treasure chest** when it dies (forced; not after 0:00) plus an XP burst. The Guardian itself (HP, kit, XP burst) is the roster's Cathedral Guardian ("Cathedral Guardian (miniboss)"); its chest comes from `ChestManager`'s miniboss rule, its bar from its kit's `set_miniboss()` (see "Stage 3 integration"). |
| 4 | Sacred altars: optional (§7.4, §8.3) | Resolves open question 4. The altars are **optional**: at 10:30 three altars rise 300-400 px from the necromancer (spread evenly, 170 px apart, out of obstacles), each guarded by a High Confessor and two footmen. **Each altar destroyed cuts 6% max HP off every Covenant soldier spawned afterwards** (additive: −18% for all three; the Reckoning's soldiers included, the boss not), through one factor in the enemy-stat path (`EnemyDirector.step()` multiplies `hp_mult` by `SanctumDirector.objective_hp_mult()`), pays +8 Soul Ash and an XP burst, raises corruption and counts in `Game.altars_destroyed` (Seraphine starts with 3 healers minus that number). Nothing waits on them: skipping them costs only the bonus, so Stage 3 can never soft-lock. |
| — | Sanctum corruption | GDD §8.3 "progressively corrupted as holy wards fall": a per-run corruption value 0..1 (+0.25 per cleansed chamber, +1/6 per destroyed altar) eases at 0.5 per second and blends every floor colour toward a necromantic purple (up to 65%); the HUD zone line shows *Corruption N%*. Cosmetic, plus the Soul Ash parts above (the stat `objective_ash`, a "Stage objectives" part of the subtotal, so the stage bonus multiplies it). |
| 1 | Dawn's Wrath (the Sanctum's Reckoning) | Same Reckoning mechanics (waves every 10 s, ×1.6 HP and ×1.25 damage compounding), restyled: the banner "DAWN'S WRATH", a gold dawn light pooled around the necromancer with turning light shafts, and **Sun Paladins** marching with each wave's Inquisitors (a stage `companions` list: 1 + floor(wave / 2) per wave, scaled like the Inquisitors; the `paladin` alias, i.e. the roster's Sun Paladin). |
| — | Dawn Extinguished (achievement) | Owner-approved: **slay the Sanctum's stage boss** (Grand Inquisitor Seraphine) once. Counted from the Sanctum's stage record (`boss_kills`), so it works for whatever boss the stage names and needs no new lifetime counter (achievement rows may name a `stage`; `Meta.achievement_progress()`). Its unlock, the campaign epilogue, does not exist yet, so it pays a one-time **200** Soul Ash bounty like the other achievements. |
| — | Sanctum autotest | `--stage=sanctum` (locks ignored). The army, summon and evolve bots walk toward live ward crystals and sacred altars when calm (naive / pact keep their baseline); the stance bot treats them like March structures. The summary adds a `sanctum` line (chambers cleansed and when, crystals destroyed, altars destroyed and when, corruption, the soldier HP cut applied, the Guardian's death time, chamber burns, objective Soul Ash, structures caught in an obstacle, minion damage the chambers prevented) and a `sanctum events` log. CI runs `--stage=sanctum --policy=army`. |
| — | Sanctum first measurements (before the roster and boss merged) | Autotest bots, `--stage=sanctum`, meta none, measured while the aliases still pointed at existing kinds (halberdier, chaplain, templar, purifier) and Marshal Vael held the boss slot; superseded by "Stage 3 integration". **Army** `--mortal` seeds 1337 / 1 / 2: 0 deaths, lowest HP 96 / 98 / 98, builds complete 15:35-15:49, the boss slain 2 of 3 (the third left at 13,800 / 38,400); chambers cleansed 2 / 2 / 1, altars destroyed 2 / 3 / 1, the Guardian slain at 6:11-6:49, 6 chests (seed 1337), Soul Ash 714 (×1.5 and 36 objective ash included). **Summon** (seed 1337): both chambers, 1 altar, Guardian at 6:41, boss slain, lowest HP 99. **Naive** (seed 1337): never seeks the objectives (its baseline), the Guardian dies at 13:45; the invulnerable run completes, the `--mortal` run dies at 16:20. No structure was ever inside an obstacle; zero script errors / warnings and `stuck_units=0` in every run. The Graveyard and the Crimson March default runs are identical to before (same-seed summaries, wall-clock lines aside). |
| 31, 32, 33 | Sanctum of Judgment Covenant roster | Five new kinds for Stage 3 (`SanctumEnemyData`, looked up after `EnemyData` and `MarchEnemyData`, so **any stage** can spawn them through the normal spawn path): the **Sanctified Sentinel**, **Radiant Inquisitor**, **High Confessor**, **Sun Paladin** (the GDD's "Elite paladins") and the **Cathedral Guardian** miniboss. Their specials are `CovenantKit`s (one per enemy, pooled with it, like the summon behaviours). "Elite" (open question 32) is both: a modifier on any soldier (×3 HP, as before) and, for the Inquisitor, Confessor, Paladin and Guardian, part of the kind (`always_elite`: their numbers are final, they always count as elites for loot, Dread Rally, Soul Nova, freeze / stun times and Soul Ash, and a spawner's elite flag never multiplies them again). **Constructs** (Sentinel, Guardian) are never healed by Chaplains or Confessors, shielded or raised. All numbers `TUNING` unless owner-approved below. |
| — | Sanctified Sentinel | Owner-approved. A slow (34 px/s) stone construct, 120 HP, 15% armour, that **ignores the first 6 damage of every hit**: a flat cut after percentage armour in `CombatResolver.damage_enemy()`, keeping at least **25%** of the hit so weak hits still chip it (Soul Nova exempt). When its target is within 60 px it shows a gold cone (74 px, ±60°) for **1 s**, then sweeps: undead inside take 14 damage (time-scaled) and are shoved 46 px back, the necromancer takes 12 if he is inside. Undead do not dodge it. |
| 36 | Radiant Inquisitor and suppression | Owner-approved. A mid-game elite caster (150 HP, 25 XP; the Reckoning's Inquisitor of the End is unchanged): it advances shooting radiant bolts, lays a holy zone on the necromancer's path every 8 s (52 px, the usual holy ground: burns and slows undead, stings him, blocks replacement inside) and every 14 s casts **suppression**: a **1 s telegraphed 160 px circle** on the nearest summon with at least 3 summons around it; once armed, for **4 s** no replacement spawns inside it and a summon that dies inside it is **not replaced until it ends** (its class timer pauses while every missing unit of that class is held; other deaths are replaced as usual), then replacement resumes normally. One path for every suppression, `HordeDirector.add_suppression(pos, radius, duration, damage_mult, telegraph, source)` (`SuppressionField`): `damage_mult` scales minion attacks on enemies standing inside (1 for the Inquisitor). Grand Inquisitor Seraphine's own suppression (5 s / 220 px / half undead damage) uses the same call with her numbers (her own row). |
| 35 | High Confessor revival | Owner-approved. An elite priest (170 HP, 30 XP) that walks at the necromancer like a Chaplain: it heals the most wounded ally within **120 px** (6 HP every 3 s, growing with the enemy HP scaling), puts **holy shields** (an absorb of 15 × HP scaling for 6 s) on **up to 3** allies within 120 px every 10 s (boss and minibosses first, then elites, then the nearest; never another Confessor, so a pack of priests cannot shield itself). A first forced-spawn test with 10 HP / 2.5 s and 25-point shields every 8 s let a few Confessors keep an elite pack alive against a 3-minute army, and every **12 s** raises **one** fallen ordinary soldier that died within **140 px** of it in the last 20 s, **where it fell**, after a **gold pillar of 1.5 s**; killing the Confessor during the pillar **cancels** it. **At most 3 revives per Confessor.** Never elites, structures, constructs, bosses, minibosses, stage objectives, the Reckoning's units or a soldier already raised once. A raised soldier has 60% HP and drops no XP (no farming). The death record is a 32-entry ring buffer (kind, position, time; no instance ids). Summons score it like a Chaplain (target priority 1.0, a Rogue "backline" target). An external owner can point any healer at a chosen ally with `Enemy.set_heal_override(ally, reach)`, and the normal ally search already includes bosses within 120 px. |
| — | Sun Paladin | Owner-approved. An armoured Templar Knight in gold (260 HP, 35% armour) with the same telegraphed charge, whose **sun aura** gives every other Covenant soldier within **110 px** (bosses and minibosses included, structures and the Reckoning excepted) **20% damage resistance**, lingering 0.6 s after it leaves. One ward per soldier: overlapping Paladins keep the strongest value and never stack; it applies in `CombatResolver.damage_enemy()` (Soul Nova exempt) on top of other categories (Banner Bearer buffs multiply). |
| — | Cathedral Guardian (miniboss) | Owner decision: a **plain miniboss**, spawned once by its stage (Stage 3 at 5:30). A giant construct (2,200 HP × the time scaling, about ×1.9 at 5:30; 20% armour) with **its own HUD health bar** (under the timer; under the boss bar when both live). It walks at the necromancer slowly (30 px/s, ×2 beyond 260 px so it never gets left behind), punches, and alternates two telegraphed specials with 4 s between them: a **ground slam** (every 10 s at most: a 72 px gold circle on his spot for 1.3 s; summons inside take 14 and are thrown out, each soaking 15% of his 26 damage, up to 60%) and a **sweeping beam** (every 14 s at most: a gold ±0.75 rad sector for 1.2 s, then a 340 px beam sweeps across it in 1.5 s, hitting everything once: 22 to him, 9 to summons; with slams every 6 s, 18 beam damage every 11 s and 2.2 s between specials it ground a whole Crimson March army down). Spawned alone at 5:30 the army bot kills it in about 60 s (Graveyard) / 80 s (Crimson March), the summon bot in about 160 s on the March, without losing a unit; the naive bot cannot kill it before 10:00. Boss-like crowd-control resistance: knockback is ignored, Deep Freeze and the Cathedral Horror's stun use the caller's boss multiplier, Stasis holds it only for the boss share; never recycled. On death: 160 XP in 10 crystals and a **guaranteed treasure chest** (ChestManager, like the boss). |
| — | Autotest `--spawn` | Test hook: `--spawn=kind@T[xN],...` force-spawns N enemies of any kind (Graveyard, Crimson March or Sanctum data) at T game seconds in an arc on the spawn ring, on any stage. When a Sanctum kind spawned, the summary adds `sanctum ...` lines (per-kind spawns and kills, Sentinel sweeps and flat armour absorbed, Inquisitor zones / suppressions with the held deaths and paused replacement, Confessor heals / shields / revives / cancelled revives, Paladin ward damage prevented, Guardian slams / beams / time to kill / chests). The autopilot dodges the kits' telegraphs. Runs without these kinds are unchanged. |
| 34, 36 | Grand Inquisitor Seraphine (§7.5) | Owner-approved kit (`BossSeraphine`, numbers in `SeraphineData`, all `TUNING`). Boss id `seraphine`; like every stage boss she arrives at **17:00** (3:00 left) with a banner and the boss bar, and the Reckoning still begins at 0:00. 40,000 HP before the stage HP multiplier (~1.25× Marshal Vael's 32,000; her transformation, teleports, healers and channels lengthen the fight: measured with the army bot, seeds 1–4, she dies after 120 / 92 / 173 / 127 s on the Graveyard and 139 / – / 121 / 88 s on the Crimson March, ×1.1 HP, where seed 2 ends at 169 HP; 48,000 took 154–191 s). She **never kites** (walks at the necromancer between specials; every special holds her or brings her closer) and **telegraphs every big hit**; undead do not dodge her hazards, only the necromancer can. **Phase 1, Divine Judgment (100–60%)**: radiant fans (gold sector 0.6 s, 7 bolts), **delayed holy circles** (3, blast after **1.2 s**), Templar squads (rally banners 1.3 s), and a **teleport** after a **1 s glow** with a marked landing spot, only when ≥ 170 px away, landing 110–160 px from the necromancer on his side of her (never farther), on a free point. **Her healers (q34):** up to three attendants arrive with her, **count = 3 − altars destroyed** on the stage (`game.altars_destroyed`, 0 when absent, min 0); while one lives within 170 px she **regenerates 30 HP/s per attendant** (through `CombatResolver.heal_enemy`); in the Last Light they **flee** (no more healing). **Phase 2, Avatar of the Dawn (60–20%)**: the relic transformation (**1 s, invulnerable**, larger and brighter), **two rotating holy beams** (1.2 s warning rays with sweep arrows, then a 4.2 s sweep, 320 px long, damage pulses every 0.25 s on the necromancer and on summons), barrages (3 rings of 12 bolts), constructs (2, rally marks), **undead suppression (q36, Seraphine part): a 1.5 s telegraphed 220 px ring around the necromancer; summons inside deal half damage and are not replaced for 5 s** (cast through the horde's one suppression path, `HordeDirector.add_suppression()`, which also times and draws it), and every **25 s the Judgment nova**: a 640 px area around her glows for **2.5 s** while **2–3 safe circles** (62 px) are marked, the first always 80–140 px from the necromancer (reachable in time) and on her side of him (shelter keeps the fight close); the necromancer and summons outside them take heavy holy damage. **Phase 3, The Last Light (< 20%)**: gaps ×0.6, windups ×0.85, +2 circles, faster beams, fans back, novas every 20 s with 2 safe circles; the **arena collapses**: holy fire closes in from the rim of a **600 px circle around her, shrinking to 300 px over 40 s** (damage outside every 0.5 s), and a **final guard** wave (5 Templars and 3 Sun Paladins) forms on the circle. **Victory:** the radiant relic shatters, the normal boss reward fires, and the **ending text** plays as the stage banner: *"The Sanctum falls. Across the realm, other holy orders begin to mobilize."* Her bolts, circles, beams, nova and fire count for Unholy Resilience; beam pulses and the fire are fields (no Bone Plating). The autotest option `--boss=ID` (alaric / vael / seraphine) puts a boss in any stage's slot for testing. |
| — | Stage 3 integration | The Sanctum stage, its Covenant roster and Seraphine merged. `SanctumStage.KINDS` maps the aliases to the real kinds (sentinel → `sanctified_sentinel`, confessor → `high_confessor`, paladin → `sun_paladin`, radiant → `radiant_inquisitor`, guardian → `cathedral_guardian`) and the boss slot is `SeraphineData.ARRIVAL`; `BOSS_ID` and the Guardian's old ×14 HP multiplier are gone. `EnemyDirector.enemy_def()` resolves a stage alias, then looks in `EnemyData`, `SanctumObjectiveData.STRUCTURES`, `MarchEnemyData` and `SanctumEnemyData` (`is_known_kind()` checks the same tables). **One miniboss system**: the Guardian's kit registers it with `EnemyDirector.set_miniboss(e)` (`miniboss_alive()` returns the Enemy), the HUD shows **one** red miniboss bar under the timer named by its display name (under the boss bar if both live), `ChestManager`'s miniboss rule drops its only chest and `GuardianKit` pays its only XP burst; `SanctumDirector` just spawns and tracks it (objective text, kill time). `CombatResolver.damage_enemy()` applies, in order, the sanctified-chamber penalty (`sanctum_chamber_dmg_prevented`), suppression (`suppression_dmg_prevented`), the enemy-side modifiers, the Sun Paladin ward (`paladin_ward_dmg_prevented`), flat armour (`flat_armor_absorbed_<kind>`) and holy shields (`holy_shield_absorbed`). **Seraphine:** her suppression goes through `HordeDirector.add_suppression(pos, 220, 5, 0.5, her 1.5 s telegraph, "seraphine")`, so the `SuppressionField` times and draws it once (her hazards no longer draw a second ring); her attendants are High Confessors and her constructs Sanctified Sentinels at their own HP (multipliers 1.0, were ×6 Chaplains / ×3 footmen), her Last Light guard is 5 Templars and 3 Sun Paladins (were 5 footmen); she reads `Game.altars_destroyed` directly; her attendants heal her through **one** path, her `attend_regen` pulse (the Confessor's `set_heal_override()` hook is not used: its per-cast heal would have replaced her tuned 30 HP/s per attendant; as Confessors they keep their ordinary kit). Dawn's Wrath's companions are Sun Paladins. |
| — | Stage 3 integration balance | With the real kinds the stage (tuned on lighter kinds before the merge) was far too hard: army bot `--mortal`, seeds 1-8, **6 of 8 died before 0:00** (6:44-16:39), Seraphine **0 of 8** killed, the Guardian killed once (6:31); armies collapsed between 5:30 and 7:30 (sanctified-chamber burns of whole armies camped on a crystal, Guardian beams / slams crossing the whole army, Sentinels piling up, and ~60-70 trickle elites a run: Radiant suppressions up to 659 a run, Confessor revivals up to 69, 21 chests and 1,818 Soul Ash in the one strong run). A few principled changes, all Sanctum numbers: (1) the sanctified chamber burns **1.5** HP/s (was 3: "light" holy damage); (2) the elite kinds (Radiant Inquisitor, High Confessor, Sun Paladin) come **only in the scripted waves**, never in the trickle, and Sentinels trickle at a quarter of the first weights (all weights had been tuned on the lighter kinds that held the slots: purifier, chaplain, templar, halberdier); (3) `ENEMY_HP_MULT` **1.1** (was 1.2, now the March's) and the stage multipliers start at **Zone III, 8:30** (was 4:00), because the Zone II kinds carry the step up; Zone I uses the March's opening rates and weights; (4) the Cathedral Guardian: **1,400** HP (was 2,200), slam 18 / 8 and beam 15 / 5 to the necromancer / summons (were 26 / 14 and 22 / 9: its beam crosses the whole army); the Sentinel's sweep does **10** to summons (was 14); (5) Seraphine: **30,000** HP before the stage multiplier (33,000 in the Sanctum; was 40,000, tuned on the Graveyard), Judgment nova 22 and holy circles 16 to the necromancer (were 28 / 20). After, seeds 1-8: **7 of 8 alive at 0:00** (seed 5 dies at 9:58 with a starved 13-16 capacity army; it survived before the merge), lowest HP 96 / 87 / 46 / 79 / – / 86 / 62 / 93, **Seraphine slain in 7 of 8** (74-152 s after arrival; Avatar after 34-61 s, Last Light after 55-122 s), the Guardian slain in 7 of 8 at 6:01-7:22, chambers cleansed 1-2 of 2, altars 1-3 of 3 (so 0-2 attendants), Radiant suppressions 13-17 and Seraphine's 0-2 a run, Confessor revivals 5-10 (0-2 cancelled), corruption 0.67-1.00, builds complete 14:15-15:27, 7-11 chests, ~900 Soul Ash (×1.5 included); Dawn's Wrath ends every run 7-34 s past 0:00 (meta max: 45 s, lowest HP 151). Naive `--mortal` seeds 1-8 die in every run (6:06, 7:03, then 9:08-19:34; 6 of 8 after 8:00; accepted, final balance pass). Builds still complete ~1-2 min earlier than on the other stages and Soul Ash is ~1.5× the March's: left for the final balance pass. Graveyard and Crimson March runs are same-seed identical to before. |
| — | Five more spells | Owner-approved: five spells take the game from 7 to **12 spells** (21 actives with the 9 offerable classes at the time; 24 with the 12 offerable classes after the content-wave integration; still 6 active slots). Same `NecroSpellBook` dispatch and `AbilityManager.spell_stats()` path (Soul Conduit, Abyssal Focus, Necrotic Expanse, Lingering Malediction, meta Shadowcraft and Hyper apply); per-level rows in `AbilityData`, fixed rules in `GraveSpellData`, all `TUNING`. Their NEW cards join the shared newer-spell card pool (`NEW_SPELL_POOL_WEIGHT` unchanged, so early hands hold no more new-spell weight), their three new passives the shared later-passive pool. **Death Mark**: every 2.4 → 1.8 s brands the 1 → 2 **strongest** foes in range (Shadow Bolt "Strongest" rule; doomed foes skipped, unbranded first, structures last); a brand deals 4 → 7 damage every 0.5 s for 5 → 6 s. **Bone Wall**: every 7 → 6 s a line of 5 → 9 bone-spike segments (9 px, 16 px apart) rises 70-80 px ahead, across the walking direction (aimed at the nearest foe within ±0.8 rad, else the nearest foe within 300 px), for 3.5 → 4.5 s; foes pressing on it take 4 → 8 every 0.5 s. **Soul Chains**: every 1.6 → 1.3 s a bolt strikes the nearest foe (those attacking undead first) and arcs 2 → 4 times to the nearest unstruck foe within 110-130 px, losing 20 → 18% per jump; 18 → 31 damage; 25 → 35% slow for 0.6 → 0.8 s. **Wither**: a 80 → 105 px aura pulsing every 1 → 0.8 s for 5 → 11 damage and cutting armour and flat armour by 25 → 50% while inside (bosses half). **Raise Dead**: every 9 → 7 s, 2 → 4 skeletons (50 → 70% of a Skeleton Warrior's HP, 60 → 100% damage, 7 → 9 s, at most 8 alive) claw up beside the foes nearest you. |
| — | Death Mark (owner change) | The owner removed the damage-taken amplification of the original idea: the brand is a **plain damage-over-time** that must kill early foes on its own (a Lv 1 brand deals 40 over 5 s; a recruit has 14 HP, a footman 36), so Death Mark works as a starting spell. A branded foe that dies **to anything** raises a temporary **Risen** (the Lich raise path, `HordeDirector.spawn_temporary()`: warrior kit drawn as "risen", 8 s, 50% HP, 60% damage, outside the army cap, its own cap `risen_cap` 2 → 4; structures have no body). Raising and detonations are queued and released on the next step, never inside the kill. |
| — | Soul Chains (owner change) | The owner changed Soul Chains from tethers to a **lightning bolt that arcs** from foe to foe (falloff per jump, a brief slow), drawn as jagged violet-soul arcs (deterministic jags from a cast counter, no RNG). The whole chain is chosen before damage lands, so a kill mid-chain never breaks it. |
| — | Bone Wall blocking | Enemies are held by a **push-out** pass, not physics: after the obstacles are resolved each tick (`NecroSpellBook.after_physics()`, called by `Game`), every enemy body overlapping a segment is moved out of it. Enemy AI is untouched, so foes keep advancing: they press on the wall, slide along it and walk around its ends (never turned away, never kiting). The wall blocks **enemies only** (the necromancer and his undead walk through it, so it can never trap them), a segment is never placed inside an obstacle (`Arena.is_blocked()`), and bosses, minibosses, Reckoning enemies and structures / carts are not held (a wall must not stall the boss fight, the run's end or a cart's path); they still take spike damage. |
| — | Later spell evolutions and passives | Owner rule kept: base Lv 5 + paired passive **Lv 5** + 8:00 + a treasure chest; all appear in the Recipes view automatically, and no passive pairs with two evolutions. **Doom Brand** (Death Mark + **Grim Ledger**, new: +5 → 25% damage to elites, minibosses and bosses from every source but the Soul Nova, one category in `CombatResolver.damage_enemy()`): 3 brands per cast, 9 per tick for 6 s every 1.6 s, Risen cap 5, and a branded death detonates for 4× the tick damage within 60 px. **Charnel Bastion** (Bone Wall + **Grave Dominion**, which had no recipe): a ring of segments at most 18 px apart, 95 px around you, 10 per tick, 4.5 s every 6 s, bursting into 30 shrapnel damage (once per foe within 40 px of a segment) when it falls. **Chains of the Damned** (Soul Chains + **Spirit Binding**, new: +8 → 40% duration of every slow, chill, Deep Freeze and stun, applied where those statuses are applied: `CombatResolver.slow_enemy()` / `chill_enemy()` / `freeze_enemy()` / `stun_enemy()`): 38 damage, up to 8 jumps (−12% each), every 1.1 s, 45% slow for 1 s, and every foe struck after the first gets a 150 px/s pull toward the first. **Necrotic Blight** (Wither + **Necrotic Vigor**, which had no recipe): a 130 px aura, 13 every 0.7 s, −60% armour, healing you 0.6 HP per foe inside each pulse, capped at 3 HP/s. **Legion of Bones** (Raise Dead + **Restless Dead**, new: +10 → 50% life and +8 → 40% damage of **every** temporary summon, one path in `HordeDirector.spawn_temporary()`: Death Mark Risen, raised skeletons, Lich raises and the stage reinforcements): 6 skeletons (80% HP, 110% damage, 10 s, at most 12) every 7 s, each bursting for 32 within 60 px when it crumbles or falls. |
| — | Wither armour shred | The shred is a timed field on the enemy (`Enemy.wither_until` / `wither_shred`, like Rot) refreshed by every pulse (pulse interval + 0.4 s); `CombatResolver.damage_enemy()` multiplies the enemy's percentage armour and its flat armour by (1 − shred) (stat `wither_shred_bonus_dmg`). It is not a damage-taken bonus: an unarmoured foe gains nothing. First pass (radius 60 → 85) dealt 2.4k damage in ten minutes of a forced run, because a kiting necromancer rarely lets foes that close; widened to 80 → 105. |
| — | Five more spells: measured | Seed 1337, `--policy=evolve`. `--spells=death_mark,bone_wall,soul_chains`: Graveyard evolutions Chains of the Damned 12:14, Doom Brand 16:00, Charnel Bastion 16:12; damage Soul Chains 91k (28% of all), Death Mark 74k (22%), Bone Wall 72k (22%) beside Shadow Bolt / Void Barrage 79k (24%); Crimson March Doom Brand 8:33, Charnel Bastion 11:31, Chains 14:04, Death Mark 193k (30%) beside Void Barrage 187k (29%). `--spells=wither,raise_dead`: Graveyard Necrotic Blight 8:01, Legion of Bones 8:43, Wither 64k (13%), Raise Dead 41k (8%) beside Void Barrage 283k (57%) (a pre-widening run of the same config, whose draw went differently, had Raise Dead 105k / 25% and Wither 91k / 21%); Crimson March Blight 8:45, Legion 9:38, Wither 100k (15%), Raise Dead 72k (11%). Sanctum (`death_mark,bone_wall,wither`): Bastion 8:00, Doom Brand 14:48, Blight 14:49. For comparison, the four older newer spells forced on the Graveyard dealt Corpse Explosion 133k, Bone Spear 113k, Plague Cloud 90k: no new spell is above the strongest older one. Every run `stuck_units=0` and free of errors; default, `--mortal`, `--policy=army` (lowest HP 111, Alaric killed) and `--policy=evolve` unchanged in behaviour (the new cards only change the draw order). |
| — | Three more summon classes | Owner-approved; offerable classes 9 → 12. Each is an ordinary class (card, 5 levels, population, cap, replacement, HUD row) on the one shared summon AI with one `SummonBehavior` (`scripts/horde/behaviors/`), all numbers `TUNING` in `UnitData`; NEW cards share `NEW_SUMMON_POOL_WEIGHT` with the other later classes. **Bone Hounds** (`bone_hound`, behaviour `pack`): cheap, fast pack beasts, 40 HP, 7.5 damage every 1.0 s, **122 px/s** (the fastest summon), population **3 / 4 / 5 / 7 / 9** (the largest of any class), replaced every 6 s, 60% of global capacity bonuses. Melee, `w_threat` 0: they never kite. **Pack Hunt**: before choosing a target each hound counts what its packmates bite and prefers that prey (focus bonus), archers / casters / priests / banner bearers (backline bonus) and, slightly, the edge of the crowd; each other hound biting the same foe (within 30 px of its edge) adds **+15%** to a bite, at most 3 (**+45%**). **Banshee** (`banshee`, behaviour `dirge`): a floating spectral support caster (40 HP, 7-damage shriek bolts every 1.8 s, 150 px). **Decision: it is not airborne.** It is drawn floating above a shadow and, like every summon, passes through enemies, but enemies **can target and hit it** (a permanently untargetable caster would be free value); it keeps out of the crowd with `w_threat` 0.9. **Dirge** every 6 s: when its target stands in a crowd (3+), is an elite / miniboss / the boss, or is on an endangered necromancer, a pale circle is telegraphed for 0.6 s, then every foe within 72 px is **weakened for 4 s**: slowed 30% and its hits deal **25% less** (bosses and minibosses half of both; Reckoning enemies and structures immune). This is the **one debuff path**, `CombatResolver.weaken_enemy()` (fields `Enemy.weaken_until` / `weaken_cut`, timed on game time like the curse), read by `Enemy.hit_mult()`, so it cuts every hit an enemy strikes itself (soldier swings, arrows, Templar rushes, Sanctum kit hits, Vael's cleave, Seraphine's fans and barrages) but not scripted boss / stage hazards (Hammerfall, holy circles, beams, holy ground). Slows never make an enemy flee (they only lower its speed; the strongest slow wins). **Corpse Catapult** (`corpse_catapult`, behaviour `barrage`): slow siege artillery (90 HP, 60 px/s) in a new formation band **"back"** (an arc behind the necromancer, opposite the threat; the army stances post it with the priests), holding its ground like the Archers. **Bone Barrage**: after a 0.5 s windup it lobs a boulder (22 damage, 235 px reach, 50 px splash) at its target's position led by 70% of its velocity × the flight time (distance / 300 px/s, 0.55-1.1 s); the landing spot is telegraphed on the ground for the whole flight; every enemy in the splash (structures included) takes the damage and a small knockback. Target scoring "siege": the densest pack (the mages' cluster value over its splash) and +1.5 for a structure (outposts, ward generators, supply carts, ward crystals, altars), +0.7 for an elite, a miniboss or the boss; 380 px acquisition (at 300 it saw structures only when the necromancer stood next to them). Boulders, fire patches and shard fields are pooled in one `HordeHazards` node (generation-guarded, capped, no RNG). Populations 1 → 3 for both; 40% of global capacity bonuses. |
| 27, 28 | Hellhound, Keening Lady, Ossuary Engine and their passives | Owner-approved; same chest delivery, 8:00 gate and Lv 5 + paired passive Lv 5 rule as every summon evolution ("transform", `SummonEvolutionData`, overlays through `special_set`; the Recipes view lists them automatically). Three NEW 5-level passives (`PassiveData`, shared NEW-card pool like the later horde passives): **Blood Scent** — the *fast* classes, defined in data as base move speed ≥ `FAST_SUMMON_SPEED` = 95 px/s (Bone Hounds, Rogues, Gargoyles and Archers), move +5→25% and attack +6→30% faster (own categories in `HordeDirector.compute_stats()`); **Mournsong** — every **weakening** effect on enemies lasts +10→50% longer, through one helper `CombatResolver.debuff_time()` used by `slow_enemy()`, `chill_enemy()`, `curse_enemy()`, `weaken_enemy()` and Plague Cloud Rot; holds (Deep Freeze, dive stun) are not weakening effects; **Siegecraft** — summon damage (strike sources plus `MINION_DOT_SOURCES`: bleeds, burns, fire and shard ticks) to **structures, elites and minibosses** +10→50% in `CombatResolver.damage_enemy()`; **not the stage boss** (a boss-damage passive would distort every boss fight). **Hellhound** (Bone Hounds + Blood Scent): ×1.3 HP, ×1.2 damage; burning bites (60% of the bite again over 3 s, one burn per hound per foe, refreshed, ticked by the hound and stopped with it like the Rogue bleed); a short **fire trail** (a 14 px patch every 0.3 s and 26 px while running, burning 1.6 s for 30% of the bite every 0.5 s); the pack **splits** into two halves (think-slot parity), each focusing its own prey and steered off the other half's. **Keening Lady** (Banshee + Mournsong): ×1.3 HP, ×1.25 damage; the Dirge repeats in **3 expanding waves** 0.35 s apart (radius ×1, ×1.3, ×1.6) and every wave **silences** what it reaches for the Dirge duration: `CombatResolver.heal_enemy(e, amount, healer)` fails for a silenced healer (Chaplains and High Confessors through `Enemy._try_heal()`), and a silenced attendant does not count for Seraphine's regeneration. **Ossuary Engine** (Corpse Catapult + Siegecraft): ×1.35 HP, **three boulders per volley** (one on the aim point, two 52 px to its sides across the line of fire) at ×0.75 damage each and ×1.2 attack interval; each leaves **burning bone shards** for 3 s (30 px, 10% of the boulder damage every 0.5 s). Sprite keys `summons/bone_hound` (32 px), `hellhound` (40), `banshee` (48), `keening_lady` (56), `corpse_catapult` (56), `ossuary_engine` (72), drawn fallbacks in `WarbandGlyphs`. Autotest: `--classes` / `--passives` take them; one class line each (bites, pack bites and bonus, burns, trail; Dirges, foes weakened, debuff enemy-seconds, waves, silences, heals silenced; volleys, boulders, hits, structure damage, shard fields) and a `class passives` line. The army / summon / evolve bots keep their build lists (none of the later classes is on them), so their baselines are unchanged; the naive bot takes them like any new class. Measured (`--policy=summon --classes=bone_hound,banshee,corpse_catapult --passives=blood_scent,mournsong,siegecraft`): Graveyard seed 1: Hellhound 8:01, Ossuary Engine 8:41, Keening Lady 9:46 (catapults 185k = 52% of the army's damage, hounds 74k = 21% with 11k pack bonus, banshees 8k plus 20k enemy-seconds of Dirge and 2,000 foes silenced); seed 2: 8:46 / 9:38 / 11:33; Crimson March seed 2: Keening Lady 8:12, Hellhound 10:33, Ossuary Engine 10:56; Sanctum seed 1: Keening Lady 12:27 (this trio-only test build has no frontline and no priests, and on the Sanctum it collapses once the Sanctified Sentinels arrive). Mixed armies: Crimson March `--classes=abomination,corpse_catapult` catapults 33% of the army's damage (Abominations 24%, Death Knights 25%) and 76% of all structure damage, every outpost and ward generator destroyed; Graveyard `gargoyle,bone_hound,corpse_catapult`: hounds 20%, Cathedral Horrors 20%, catapults 38% (before the last Ossuary Engine trim). The comparable baseline (`abomination,rogue,gargoyle`) has Shadow Reapers at 48%. Changed during the tests: hounds 26 HP / 5.5 damage / 0.8 s with backline / edge pulls 0.5 / 0.3 (200+ deaths a run, bites eaten by the Sentinels' flat armour) became 40 / 7.5 / 1.0 s with 0.35 / 0.1; catapult acquisition 300 to 380 px; Ossuary Engine boulders x1.0 to x0.75 and shards 0.15 to 0.10. Known, for the final balance pass: in trio-only runs the catapults deal 52-73% (the rest of that army is weak) and the hounds die about 200 times a run (cheap, replaced every 6 s). Synergies for the new classes were skipped. |
| — | Playable characters | Owner-approved: **one playable character per spell**, twelve necromancers chosen on the pre-run setup screen (a character section above the difficulty row; [10.2](#102-pre-run-configuration)). Each starts the run with **its own spell at Lv 1** (instead of Shadow Bolt), has **one innate passive** and a few stat modifiers (`CharacterData`, all innate numbers and the art colours `TUNING` unless the owner gave them). Roster: **The Gravecaller** (Shadow Bolt; no innate; baseline), **The Umbral Warden** (Orb Shield; *Eclipsed Guard*: orbs destroy every enemy arrow / bolt they touch, charged or not, no charge spent; +15 max HP, −5% move speed), **The Voidcaller** (Shadow Blast; *Echoing Dark*: each blast, Abyssal Detonation included, leaves a ring that bursts again **1 s** later for **40%** of its damage, source `echo`; −10 max HP), **The Bone Oracle** (Bone Spear; *Ossuary Ward*: a Bone Spear / Ossuary Lance kill grows an orbiting bone shard, **max 3**, at most one per **3 s**; a shard absorbs one whole hit on the necromancer and gives the normal 0.5 s hit i-frames, never spent during i-frames; +10 max HP), **The Fallen Confessor** (Soul Siphon; *Stolen Grace*: every heal the necromancer receives through `CombatResolver.heal_player()` also heals his nearest wounded summons for **half** the HP healed, nearest first with the rest spilling over, up to **3** summons within **240 px**; natural regeneration is not a heal; +5% move speed), **The Carrion Lord** (Corpse Explosion; *Grave Harvest*: every summon that dies leaves a corpse in Corpse Explosion's ring buffer, detonated like an enemy's; expired temporary summons leave none; baseline), **The Plague Scholar** (Plague Cloud; *Contagion*: an enemy that dies while Rotting passes its full Rot to the nearest other enemy within **160 px** for **3 s**, through the one Rot path `CombatResolver.rot_enemy()`, so it chains; −10 max HP, +10% spell area), and five characters for the coming spells (below). The GDD [11.4](#114-character-skins) skin names Gravecaller, Plague Scholar, Bone Oracle and Fallen Confessor are now these characters; skins stay cosmetic ([3.4](#34-character-skins)). |
| — | Characters: innates only, the Gravecaller is the default | Owner decisions: characters have **innate passives only**, no exclusive passive cards (the level-up pool is the same for everyone). **The Gravecaller is the default** (fresh saves, the autotest) with **no innate and baseline stats**, and with him the game plays **bit-for-bit like before characters** (same-seed autotest summaries identical; checked on the default and `--policy=army` runs, seed 1). One path, like the Soul Ash upgrades: `RunConfig.character_id` → `CharacterModifiers` (`game.character`: the starting spell for `AbilityManager.setup()`, max HP / move speed applied once after `MetaModifiers.apply_to_player()` and before the Frail Master modifier, spell area as one more category in `apply_spell_mods()`, the innate numbers) → `CharacterInnates` (`game.innates`: hooks in `ProjectileManager`, `AbilityManager._cast_blast()`, `CombatResolver.damage_enemy()` / `damage_player()` / `heal_player()`, `HordeDirector.on_unit_died()` and `spawn_temporary()`; each returns at once unless the run's character owns that innate). |
| — | Character unlock rule | Owner rule: a character unlocks **the first time the player reaches Lv 5 with its starting spell in any run** (with any character, on any stage and difficulty; a level from a treasure chest counts, since every spell level goes through `AbilityManager.apply_offer()`). The Gravecaller is open from the start. The Meta save keeps the **best level of every spell** (`[characters] <spell id> = level`), written as soon as a level is new (like a recipe discovery, so quitting mid-run keeps it), and a character's lock is derived from it (`Meta.is_character_unlocked()`). The end screen shows a **NEW CHARACTER UNLOCKED** line for each character a run opened (a gold *New character: ...* plate on the results card since the menu modernization, see "Results card (end screen)"). The picker shows locked characters with a padlock and their condition; they cannot be chosen. The last chosen character is remembered as `[prerun] character` with the difficulty and modifiers (a remembered character that is locked or missing falls back to the Gravecaller), and **Restart** keeps it. The recipe book is unchanged. |
| — | Characters of the five coming spells | The Doomsayer (Death Mark; *Ill Omen*: branded enemies also slowed **15%**), the Barrow Warden (Bone Wall; *Stonebone*: walls last **50%** longer; +10 max HP), the Soulbinder (Soul Chains; *Conductor*: arcs jump to **one** extra enemy), the Wither Witch (Wither; *Creeping Rot*: the aura applies Rot, **10%** lingering **1 s**; −5 max HP) and the Grave Herald (Raise Dead; *Restless*: temporary summons from any source last **25%** longer) start with spells not in the game yet. They are **hidden from the picker** and **refused by `--character=`** (an error naming the missing spell; the Gravecaller plays) until their spell exists (`CharacterModifiers.is_available()`: the starting spell is in `AbilityData.SPELLS`), so merging the spells is all it takes. Their innates are data plus hooks the spell code reads: `game.character.innate_value("death_mark_slow")` (a slow fraction to apply with the brand's duration), `"bone_wall_duration"` (× (1 + value) on the wall's lifetime), `"soul_chains_extra_jumps"` (+ that many jumps), `"wither_rot"` / `"wither_rot_linger"` (call `game.combat.rot_enemy(e, rot, game.elapsed + linger)` on each aura tick); each is 0 for every other character. *Restless* already works: `HordeDirector.spawn_temporary()` multiplies every temporary summon's duration by (1 + `temp_summon_duration`). **Now playable:** the five spells merged in the content wave, so all five characters are in the picker and `--character=` accepts them; their hooks are wired as described here (see "Content wave integration"). |
| — | Character art | Each character has a sprite key `player/<id>` (56 px, prompts in the [Art Bible](art/ART_BIBLE.md)); the Gravecaller keeps `player/necromancer`. Until a character's art exists, the necromancer's sprite is drawn tinted with the character's spell-school colour over a soft aura of that colour (`CharacterGlyphs`), in the run and on the picker portraits (with the starting spell's icon as a badge). |
| — | Character first measurements | Graveyard, `--policy=army --mortal`, meta none, seeds 1-4 (the bot swaps each character's spell and its evolution passive into Shadow Bolt's and Soul Conduit's build priority). **Gravecaller**: 0 deaths, lowest HP 105-110, Alaric 4/4. **Umbral Warden**: 1 death (seed 4, 17:01: an XP-starvation spiral, level 15 at 17:00, the army never built up; Orb Shield kills little early), otherwise lowest HP 108-129, Alaric 3/4, 140-340 projectiles destroyed per run. **Voidcaller**: 0 deaths, lowest HP 83-103 (the lowest, −10 HP), Alaric 4/4, 370-440 echo bursts for 18-45k damage. **Bone Oracle**: 0 deaths, lowest HP 125-130 (52-76 hits absorbed by shards: chip damage almost never lands), Alaric 3/4. **Fallen Confessor**: 0 deaths, lowest HP 94-113, Alaric 3/4 (seed 3 starved: level 20 at 15:00), grace healing small (2-131 HP: the bot is rarely hurt). **Carrion Lord**: 0 deaths, lowest HP 104-112, Alaric 4/4, 30-67 summon corpses (6-17 detonated). **Plague Scholar**: 0 deaths, lowest HP 99-104, Alaric 4/4, ~2,600-2,900 Contagion spreads and 35-53k Rot bonus damage. No character dominates or is hopeless with this bot; the Bone Oracle is the safest and the two weak-killing starters (Orb Shield, Soul Siphon) are the most likely to starve. Numbers left as specified; to be revisited in the final balance pass. |
| — | Hyper mode | Owner-approved. An opt-in **Hyper** toggle on the pre-run setup screen, beside the difficulty and the run modifiers (`HyperData`, all numbers `TUNING`). **Unlock:** the first time Grand Inquisitor Seraphine is slain, on any difficulty (Meta `[hyper] unlocked`; the end screen of that run shows a gold *Hyper mode unlocked* plate on the results card; a save that already holds her kill in the Sanctum record is unlocked on load); until then the card shows the condition and cannot be switched on. **Effect**, through `DifficultyModifiers` (the one difficulty path), applied once and stacking with the level: the **growth** part of the enemy HP and damage time scaling ×2 on top of the level's `hp_scaling` / `damage_scaling` (the starting values are unchanged; the Reckoning is built from the same scaling, so it grows too), the stage boss's HP ×1.5 on top of the level's boss HP, and **Soul Ash +100%** of the run subtotal as its own end-screen line ("Hyper (+100%)", next to the difficulty line; the setup screen's total adds 1.00). At 0:00 vs the standard game: **Necromancer + Hyper** HP ×1.88 and damage ×1.72 (×15.4 / ×6.2 the starting values instead of ×8.2 / ×3.6), boss ×1.5; **Deathlord + Hyper** HP ×2.71 and damage ×2.41, boss ×1.95. Remembered as `[prerun] hyper`, kept by Restart, turned off by Standard; the HUD shows "Difficulty: Lich + Hyper" and the end screen names it. A **Hyper clear** = a victory (the run reached the Reckoning) with Hyper on; it is recorded per stage **and per character** (`[hyper_clears] <stage>-<character>`, the character from `RunConfig.character_id`, `gravecaller` when there is none) and gives the stage a gold **HYPER CLEARED** badge on the stage select (with the number of characters when more than one). Autotest `--hyper` (bypasses the lock); every summary has a `hyper` line. The in-run *Hyper* power-up keeps its name. |
| 42 | Skins | Owner-approved: skins are **purely cosmetic**, never a stat (resolves open question 42). `SkinData` covers the twelve playable characters (read from `CharacterData` since the content-wave integration; Gravecaller, Umbral Warden, Voidcaller, Bone Oracle, Carrion Lord, Fallen Confessor, Plague Scholar, Doomsayer, Barrow Warden, Soulbinder, Wither Witch, Grave Herald; `CharacterData` owns the characters) and gives each a **default** look and a **Hyper skin**, unlocked by **clearing the Sanctum of Judgment on Hyper** with that character: Eclipsed Gravecaller, Sunless Warden, Starless Voidcaller, Gilded Oracle, Crowned Carrion Lord, Fallen Seraph, Blighted Scholar, Final-Hour Doomsayer, Gilded Barrow King, Radiant Soulbinder, Thorn-Crowned Witch, Golden Herald (owner-named: Eclipsed Gravecaller, Gilded Oracle, Blighted Scholar, Fallen Seraph; the rest follow the same "<epithet> <title>" pattern). Four **achievement skins**: Gravecaller → **The Dread Sovereign** (black armour, royal cloak; slay Seraphine while commanding Warriors, Archers, Mages and a priest order: the *Dread Sovereign* achievement's role check, lifetime counter `seraphine_kills_full_army`), Bone Oracle → **The Ivory Seer** (the *Bone Legion* achievement), Plague Scholar → **The Plague Doctor** (5,000 enemies slain while Rotting, lifetime `rot_kills`), Fallen Confessor → **The Heretic Saint** (50 High Confessors slain, lifetime `high_confessor_kills`). Unlocks are **derived** from those counters, the achievements and the Hyper clears (never stored separately); the end screen announces new ones (a gold *New skin: ...* plate on the results card); the autotest writes nothing without `--meta-save`. **Rendering:** a skin is the sprite key `player/<character>_<skin>`; while that PNG is missing, `SkinGlyphs` draws the character's sprite (or glyph) with the skin's **palette** (a tint, an accent emblem: crown, halo, cracked halo, gold sun corona or plague mask, a faint accent aura ring, the glyph's eye / orb glow), so every skin shows before its art (ART_BIBLE: 16 skin rows and the Hyper badge icon). **Selector:** a row of cards on the setup screen (per selected character: preview, name, the condition and progress while locked; keyboard, mouse and controller), remembered per character (`[skins] <character> = <skin id>`). Autotest `--skin=ID` forces one (ignores the unlock and the character, for screenshots); every summary has a `skins` line. The GDD §9.4 / §11.4 skins (Gravecaller, Plague Scholar, Bone Oracle, Fallen Confessor) are now playable characters, so their looks are the characters' defaults; the "Graveyard on Lich" Bone Oracle unlock is left to the character system. |
| — | Hyper measurements | Autotest, Graveyard, `--hyper --policy=army --mortal`, meta none, seeds 1-8 (**Necromancer + Hyper**): **8 of 8 reach 0:00** (lowest HP before 0:00 27 / 98 / 26 / 11 / 105 / 69 / 59 / 61), **Sir Alaric slain 0 of 8** (63,000 HP; left at 9,400-62,200: the army holds until about 14:00-16:00 and then collapses to 4-33 summons under the doubled growth, so the boss is fought by spells and remnants), builds complete in 4 of 8 (16:53-19:11), and **the Reckoning ends every run 6-18 s past 0:00** (35 s on the standard game, seed 1337). Soul Ash 574-756 (the Hyper line pays +287-378). **Deathlord + Hyper**, seeds 1-4: **0 of 4 reach 0:00** (deaths at 12:01 / 14:27 / 16:41 / 13:44, lowest HP 9-17 just before; Soul Ash 452-517 with ×2.5 on the subtotal): the stacked apex is beyond the army bot, so it is left as the hardest challenge a human can attempt rather than tuned down. Accepted as the owner's numbers (target: a strong build usually reaches 0:00 and the Reckoning ends every run); the boss's ×1.5 is not the limit (without it only one of the eight would have killed him). With Hyper off, default, `--mortal` and `--policy=army` Graveyard runs are same-seed identical to before (wall-clock and audio lines aside, and the new `hyper` / `skins` summary lines). Zero script errors / warnings and `stuck_units=0` in every run. |
| — | Content wave integration | The five later spells, the three later summon classes, the twelve playable characters and Hyper mode / skins, built in parallel, merged together. **Counts:** 12 spells and 12 offerable summon classes, **24 actives for the 6 active slots**; their new cards share the existing newer-spell / newer-class / later-passive pool weights, so early hands carry no more new-item weight. The `army`, `evolve` and `summon` bots still never take the new or later items unless forced (`--spells=`, `--classes=`, `--passives=`), so their baselines only move through the changed draw order. **Stacking:** Spirit Binding (slows, chills, freezes, stuns: `cc_mult()`) and Mournsong (weakening effects: `debuff_time()`) are separate categories and **multiply** on slows and chills (`CombatResolver.slow_enemy()` / `chill_enemy()`: duration × (1 + cc) × (1 + debuff)); freezes and stuns take only Spirit Binding, the Dirge, curses and Rot only Mournsong. Every Rot (Plague Cloud, Contagion, Creeping Rot) goes through **one** path, `CombatResolver.rot_enemy()`, which applies Mournsong (it lengthens what is left of the Rot). The Restless Dead passive and the Grave Herald's Restless innate are separate categories in `HordeDirector.spawn_temporary()` and **multiply**: lifetime × (1 + temp_duration) × (1 + temp_summon_duration) (Restless Dead Lv 5 + Restless: ×1.875). Grim Ledger (every source vs elites, minibosses, bosses) and Siegecraft (summon damage vs structures, elites, minibosses) are separate categories in `damage_enemy()`. **The five later characters' innates are wired** into their spells exactly as specified ("Characters of the five coming spells"): Ill Omen in `DeathMark._brand()` (the brand's slow goes through `slow_enemy()`, so Spirit Binding and Mournsong lengthen it; stat `ill_omen_slows`), Stonebone in `BoneWall._cast()` (walls and Charnel Bastion rings; `stonebone_extra_seconds`), Conductor in `SoulChains._cast()` (`conductor_extra_jumps`), Creeping Rot in `Wither._pulse()` (applied before the pulse's damage, so the pulse already gains from it; `creeping_rot_applied`), Restless in `spawn_temporary()` (Raise Dead spawns through it; `restless_extra_seconds`); the autotest `character` line reports each. **One character list:** `SkinData` reads `CharacterData` (ids, order, names, base sprite keys; its mirrored copy is gone) and `RunConfig.character_key()` returns `character_id` (the one accessor skins and Hyper clears use). **One tint:** `SpriteBank.draw(ci, key, o, flash, tint)` (both branches had added the same optional parameter). **Skin fallback:** a skin without its own art on a character without art draws **that character's** look (`CharacterGlyphs.draw_player()`: the school-tinted necromancer, or its glyph variant) multiplied by the skin's palette tint, with the skin's emblem and aura, never the Gravecaller's silhouette; the Gravecaller keeps `SkinGlyphs`' recoloured glyph when no art exists at all. |
| 37, 38 | Pre-run setup layout | The setup screen now holds the character picker, the skins, the difficulty, the run modifiers, Hyper and the totals, which no longer fit stacked in 720 px. **Two columns under a one-line title** (fits 1280 × 720 with no scrolling): the **left** column is *who plays* (character tiles 6 × 2 at 62 px, the detail panel under them, then one compact card per skin of the chosen character and the Hyper card), the **right** column *how hard* (the four difficulty cards as a 2 × 2 grid, the eight run modifiers as a 2 × 4 grid, then the total Soul Ash line, its breakdown and the foe line), with Back / Standard / Begin across the bottom. A difficulty card shows its Soul Ash (and XP) multiplier on its name line, which fixes the old bottom "Soul Ash" line that spilled past the card's edge. Keyboard / pad: explicit focus links inside each column (rows up / down by column position), a row's end crosses to the other column's row nearest in height, the left column's last card leads down to Back and the right column's to Standard / Begin, and the bottom buttons lead back up; the links are rebuilt when the skin cards change with the character. (Layout superseded by "Pre-run setup: the character is the hero"; the content is unchanged.) |
| — | Content wave measurements | On the merged build, meta none, `--mortal`, army bot. **All twelve characters**, Graveyard seeds 1-4 (lowest HP before 0:00 / Alaric slain): Gravecaller 98-112, 4/4; Umbral Warden 1 death (seed 4, 17:01, the same XP-starvation spiral as before the merge), 108-128, 2/4; Voidcaller 99-103, 4/4; Bone Oracle 130 (every hit absorbed by a shard), 4/4; Fallen Confessor 107-113, 4/4; Carrion Lord 107-112, 4/4; Plague Scholar 98-102, 3/4; **Doomsayer** 109-112, 4/4 (937-1,414 brands slowed by Ill Omen); **Barrow Warden** 19-115, 2/4 (Stonebone 372-420 extra wall seconds; Bone Wall kills little early, so the first level-up comes at 0:40 instead of 0:28 and seed 4 starves: level 19 at 10:00, no evolution); **Soulbinder** 106-112, 4/4 (420-487 extra jumps from Conductor); **Wither Witch** 78-108, 4/4 (4,100-5,200 Creeping Rot applications, 21-24k Rot bonus damage); **Grave Herald** 104-110, 4/4 (565-647 temporary summons, 1,400-1,950 extra seconds from Restless). No character dominates; the Barrow Warden joins the Umbral Warden as the weak-killing starters most likely to starve. Numbers left as the owner specified them, for the final balance pass. **Three stages, 8 seeds, Gravecaller:** Graveyard 0 deaths before 0:00, lowest HP 98-114, Alaric 8/8; Crimson March 0 deaths, 85-112, Vael 7/8; Sanctum 0 deaths, 13-107 (seed 7 at 13 HP, seed 3 at 46), Seraphine 7/8 (seed 7 left her at 475 HP). **Hyper**, Graveyard seeds 1-4: 4/4 reach 0:00, lowest HP 46 / 87 / 81 / 68, Alaric 0/4 (13-35k of 63k left), matching the pre-merge Hyper measurements. Forced runs (seed 1337): Death Mark, Bone Wall and Soul Chains all evolve (`--policy=evolve --spells=death_mark,bone_wall,soul_chains`), so do Wither and Raise Dead, and Hellhound, Keening Lady and Ossuary Engine (`--policy=summon --classes=bone_hound,banshee,corpse_catapult --passives=blood_scent,mournsong,siegecraft`); `--character=soulbinder --classes=bone_hound --spells=soul_chains --hyper --skin=soulbinder_hyper` runs clean. Every run free of errors and warnings, `stuck_units=0`, no special or Grave Step ending in an obstacle. A `--meta-save` round trip in a renamed scratch project keeps a character unlock (`[characters] bone_spear=5`), the Hyper unlock (`[hyper] unlocked`), a Hyper clear (`[hyper_clears] sanctum-bone_oracle`, which unlocks the Gilded Oracle skin) and the skin counters together across runs. |
| — | Web build after the art | Owner decision (Oct 2026): once the Phase 2 art is complete, the next step is a **browser build for desktop** (keyboard / controller), not phones yet. Plan: a Godot 4.3 Web export preset **without threads** (no SharedArrayBuffer / COOP-COEP headers needed, any static host), the startup sound synthesis (`sfx.gd`, WorkerThreadPool) checked for a load pause and spread over frames behind a loading screen if needed, the Quit button hidden on the web, saves in browser storage (`user://` → IndexedDB, per browser), and a CI job that exports the web build and publishes it (GitHub Pages or itch.io) so playtesters get a link. Known web difference: the master-bus hard limiter is not applied in Godot's web sample playback. **Phones** (touch joystick and buttons, a mobile UI scale, landscape lock, a performance setting) and native Android / iOS apps are deferred until the browser build has been measured. |
| — | Art pass (true pixel art) | Owner decision (Oct 2026), proposal "Gravebound: Art Pass Proposal" accepted: the ChatGPT placeholders are replaced by **true pixel art made at its real size**, for clarity at the small in-game sizes. **Grid:** 1 art px = 2 screen px at 1280×720 (necromancer 28 art px tall, shown at 56), drawn sharp (nearest filtering) at whole-number scales; sizes in art px: fodder 20-22, soldiers and summons 22-26, necromancer 28, heavies 30-36, structures 36-50, minibosses and bosses 60-78. **Zoom:** Normal ×1 and Close ×1.5, **Far dropped**. **Locked palette** of about 32 colours in ramps; the processing tool (`prepare_sprite.py` grid mode) snaps every asset to it, draws the outline (1 art px, the darkest shade of the unit's own hue, never pure black) and a 1 px light rim on the top-left, and aligns the feet; an automatic **check sheet** shows each asset at in-game size on all three stage floors, in greyscale and as a silhouette. **Faction colours:** violet is reserved for the player (necromancer and the 12 characters); the undead army is bone ivory, cold grey and teal-green soul fire with one accent per class; the **Undead Mage and Lich move to a deeper arcane / frost blue** and the **Frost Wraith and Winter Revenant get their own pale icy shade** so the two stay distinct; the Covenant is crimson, ivory and warm steel, gold for elites, Sanctum kinds and bosses; floors are dark, low-saturation, narrow-value. Glow only on the player, spells, telegraphs, elites and bosses. **All 31 finished sprites are redone.** **Animation:** engine motion for every unit (tier 0: step bob, lean, turn squash, attack lunge and recoil, hit squash, summon rise, death dissolve; visual only), then 4-frame walk cycles for the characters and summon classes first; soldier walks, action poses and boss poses after. **Obstacles** come in fixed size variants (each collision shape matches its variant, within today's size ranges), several sizes per kind for variety; long walls from caps and a middle. **Font:** an open-licence pixel font for titles and numbers, picked by the owner from sample renders. **Order:** foundations (sharp scaling, palette, tools, engine motion) → anchors approved in-game (necromancer, Skeleton Warrior, Covenant Recruit, a Graveyard tile, a gravestone, one icon) → units by screen time → environments → icons, pickups, projectiles, UI kit → motion frames and effects → the web build. |
| — | Pixel fonts | Owner choice (option 13 of the sample sheets): **Jacquard 24** (Google Fonts, SIL OFL) for the game title and zone / event banners, drawn at whole multiples of its 43 px em; **Pixelify Sans Bold** (SIL OFL) for the HUD, numbers, headings, labels, buttons and card names. Long card descriptions keep a clean body font unless the owner asks otherwise (the owner later asked for Jersey 10 everywhere, see "Body font: Jersey 10"). Both live in `assets/fonts/` with their licence texts and are imported with anti-aliasing, hinting and subpixel positioning off. Wired in with the UI kit (art pass phase 5). |
| — | Grid-art drawing and zoom | Art pass foundation. `SpriteBank` treats a PNG no taller than its `SpriteData.HEIGHTS` entry as **grid art**: true pixel art stored at art resolution (storage contract: height exactly `HEIGHTS[K] / 2`; `SpriteData.ART_SCALE` = 2). It is drawn at exactly 2 screen px per art px (3 at Close), **sharp**: the texture is wrapped in a nearest-filtered `CanvasTexture`, which overrides the node's filter for that draw only, so every caller (units, bosses, structures, player, character / skin glyphs, HUD / card icons, Grave Step trail) gets it while legacy art, text and code-drawn shapes stay smooth. The rect sits on whole art pixels from the node origin; at a whole-number scale with nearest filtering a moving sprite steps whole pixels without shimmer, so the global `snap_2d_transforms_to_pixel` / `snap_2d_vertices_to_pixel` settings stay off (they would step every shape and HP bar and risk 1 px player jitter with the smoothed camera). Icon mode uses the largest whole-number scale that fits the box. Taller PNGs (the 31 legacy 3× placeholders) keep the old smooth scaling until replaced. **Zoom:** Normal ×1 (default) and Close ×1.5 only, Far dropped; a saved Far loads as Normal; gameplay distances unchanged (autotest summaries identical). |
| — | Art tools and palette | Art pass foundations (Oct 2026). **Palette:** `tools/palette.json` is the single source of truth: 40 colours (37 for sprites, 3 floors) in dark-to-light ramps whose first colour is the outline ink: violet (player only), bone (undead bone and Covenant ivory), cold grey, teal soul, moss (Archer), arcane blue (Mage, Lich), icy cyan (Frost Wraith, Winter Revenant), warm steel, crimson, brown, gold (with holy white), skin, flame, and the Graveyard / March / Sanctum floors (`#161A1C`, `#221C17`, `#312E2B`); a material keeps at most 3 shades, unit mid-tones sit at OKLab L 0.45-0.80. 40 rather than the proposal's ~32 so that the 14 faction materials keep 3-shade ramps. **`prepare_sprite.py` grid mode** (the default; `--legacy` keeps the old smooth copy, `--anim` is unchanged) rebuilds a sprite at exactly `HEIGHTS / 2` art px, opaque or transparent pixels only: a material-first downscale (linework suppressed, majority material per cell, bright accents kept), per-material levels over its ramp, the folder's faction ramps (violet only under `player/`, with per-key exceptions keeping arcane and ice apart), ramp pruning and speck cleanup, the ramp-ink outline, the top-left rim, feet on the last row, the body centred; `--frames 4` writes `<key>_walk.png` (4 equal frames, frame 1 idle). **`art_check.py`** renders a check sheet with the game itself (a scene in `tools/art_check/`, ignored by Godot, run in a scratch copy): the sprite on the 9 stage floors beside the necromancer, a Skeleton Warrior and a Covenant Recruit at ×1 and ×1.5, a 4-10× zoom, greyscale and silhouette, and the rule checks (height, alpha, palette, feet, main-shape lightness +0.15 over every floor, violet off-player, glow, specks). Measured: detailed AI illustrations keep their masses but lose faces and trims at 20-28 px; chunky sources drawn near the grid come back about 95% pixel-identical, so the prompts ask for a figure "N pixels tall" in big blocks with flat palette colours and a thick outline, and small details (eyes) are best touched up by hand on the small PNG. The art bible also removes violet from the other summon descriptions (player-only rule). The Sanctum's code floors (L 0.34-0.40) are lighter than the palette's stone and come down in the floors pass. |
| — | Engine motion (tier 0) | Art-pass foundation (Oct 2026), visual only. Every unit (the necromancer and characters, all summon classes and evolutions incl. temporary Risen, every Covenant kind and elite, the miniboss and the three bosses at reduced amplitude) gets procedural motion: a **step bob** matched to its measured speed, a **lean** (≈5°) into the movement, a **turn squash** on facing flips, an **attack lunge and recoil** at the existing strike / shot / cast / special moments, a **hit squash** with the white flash, a **summon rise** (0.3 s, grave dust) and a **death dissolve** (0.4 s collapse into bone dust or holy ash, pooled; bosses keep their own death). **Structures** only squash on hits. Frozen, stunned, stone-form and airborne units hold still. A unit draws in three layers (ground effects on its node, body and overlays on two child `UnitLayer`s); only the body moves, by a scale and shear about its feet, so shadows, HP bars, auras and telegraphs stay put and nothing redraws per frame. `MotionDirector` runs it once per rendered frame on game time (hit-stop and pause included) for on-screen units. It never writes gameplay state or uses RNG: same-seed autotest summaries are byte-identical. Numbers in `motion_data.gd`. |
| — | Art pass grid: 1 art px = 1 screen px | Owner decision after in-game comparisons (Oct 2026), **overriding the 2× grid** of "Art pass (true pixel art)" and "Grid-art drawing and zoom": at 28 art px the necromancer lost its skull pauldrons, hands and staff skull, while at 56 art px it read clearly, and the AI image tools naturally draw figures about 60-95 px tall, so far less is thrown away. **`SpriteData.ART_SCALE` = 1**: a grid-art PNG is exactly `HEIGHTS[K]` art px tall (necromancer 56) and drawn 1:1; every art-px size in the art bible doubles. **Sharp-pixel filter:** the 1280×720 layout is stretched to the window (×1.5 in a 1080p window) and Close zoom doubles it, so an art pixel often covers a fractional number of screen px; nearest filtering drew uneven pixels and linear blurred. Grid textures are now LINEAR-filtered `CanvasTexture`s drawn through `sharp_pixel.gdshader` (`SpriteBank.apply_sharp()` puts one shared `ShaderMaterial` on any CanvasItem that draws grid art): crisp pixels whose edges blend over **0.5 screen px** (`SpriteData.SHARP_EDGE_SOFTNESS`, the owner's pick "C2" from 1080p renders at 0, 0.25, 0.5 and 1); minified textures (legacy 3× placeholders, small icons) fall back to plain linear and untextured shapes are unaffected, so nothing else changes; it also smooths the shear of the engine motion. Icons draw grid art at the largest whole scale that fits, or scaled down when even 1× is too big. **Zoom: Normal ×1 and Close ×2** (was ×1.5). Visual only: same-seed autotest summaries identical. |
| — | Environment art hookup | Floors and obstacles take art piecemeal like the units; the code floors and glyphs stay the fallback whenever a PNG is missing (`EnvironmentArt`, data in `environment_art_data.gd`). **Floors:** `tiles/<zone>.png` (128×128 seamless; `graveyard`, `march_<style>`, `sanctum_<style>`) is drawn as one repeating rect on the world tile grid, 1 art px = 1 layout px, through the sharp-pixel shader, on the same redraws as before (fewer draw calls than the code floor). Up to two variants (`<zone>_2`, `_3`) each cover 20% of cells, chosen from the floor's stable cell hash. `tiles/march_road.png` (140 px tall; `_<style>` override per zone) draws along y = 0. The Sanctum corruption fades the tiles toward the code floor's purple with one translucent overlay at the same blend strength. Flat code decorations stay on top; the Graveyard's solid-looking tombstone, stone cross and dead tree are skipped on the tile floor because they never collide ("nothing looks solid unless it collides"). **Obstacles:** each kind has 2-3 fixed size variants (`sizes` in the stage files, inside the old ranges; the collision is exactly the variant; one RNG draw per cell as before, centres on whole px; deterministic per seed), drawn from `obstacles/<kind>_s\|_m\|_l[_v].png` with the sprite's bottom edge on the bottom of the collision shape and a code drop shadow, else from its code glyph at that size. The gravestone has two sizes, r 11 / 15, matching the owner's `gravestone_s` / `gravestone_l` anchors. Long walls are whole fixed-length sprites, one per length (no cap-and-middle assembly); a vertical rect needs its own `_v` sprite or keeps its glyph. Balance unchanged (army `--mortal`, 4 seeds: 0 deaths, min HP 104-112, Alaric 4/4). |
| — | Pickup and projectile art | Art pass (Oct 2026), visual only. Flat sprites (`SpriteData.FLAT_SIZES`: projectiles, the Orb Shield orb and now the pickups) count as grid art when their longest side is no more than their entry, and `SpriteBank.draw_flat()` then draws them 1:1 through the sharp-pixel shader (projectiles rotate along their flight; unrotated pickups sit on whole px). The **XP crystal** has three sprites by value, on the code's thresholds and colour language (1-2 teal, 3-7 arcane blue, 8+ violet: XP is the player's reward), over the same faint glow. **Power-ups** are round medallions (a dark disc in the accent rim, the icon inside) drawn over the code's pulsing ring, keeping the GDD §11.2 rule that a drop never reads as a crystal or an enemy. The **world chest** is a bone-and-iron chest with a violet lock over the code's gold pulse; the ChestPanel's opening reveal stays code-drawn. Thin projectiles (arrows, Bone Spear) keep a 1 art px light shaft between outline rows so they read at 4-6 px tall. |
| — | Icon art | Art pass (Oct 2026), visual only. All 77 badge icons (`assets/sprites/icons/`, 32×32 grid art; spells, evolutions, passives, summon classes and evolutions, stances, power-ups, the Profane Pact, Grave Step and Dread Rally) share one badge: a 32×32 frame with the Shadow Bolt anchor's **cut corners** (owner decision: cut corners on every UI element, matching the UI kit's chamfered frames; a brief square version was reverted at the owner's request), a 1 px border and an ink-violet face, with the symbol centred in a 26 px box. The 9 base summon classes (warrior, archer, mage, mender, warder, rogue, gargoyle, frost wraith, abomination) have badges too, so every hotbar slot and army-list row shows a badge rather than the old code box. The border is **violet** for ordinary icons and **gold** for every evolution (the art bible's "gold-trimmed frame"), so an evolved slot reads at a glance in the HUD and on the cards. Grid icons fill their box through the sharp-pixel shader and skip the code backdrop (unchanged path). The **Hyper badge** is a bare 16×16 gold sun, which `HyperBadge` draws 1:1 (largest whole scale) at its 16-18 px sizes instead of the code shape. |
| — | Skin art sizing | Art pass (Oct 2026), cosmetic only. Every skin keeps its character's body height (head to feet); a crown, halo, corona or taller staff above the head grows the sprite's art height (its `SpriteData.HEIGHTS` entry), never the body. Skins were generated with the character's own sprite attached so the pose and silhouette stay the same; the Hyper skins carry the gilded / eclipsed theme mainly in gold trim and a gold corona or crown (thin corona rays merge into a rim at 56 px). The Grave Step afterimage uses the worn skin's sprite (else the character's, else the necromancer's). |
| — | Effect animations (art pass) | Art pass (Oct 2026), visual only. Effects are **smooth by design**: strips of square frames scaled to the gameplay radius with plain linear filtering (not the sharp-pixel shader; one strip plays from ~40 px to ~1500 px), in pixel-art style with palette colours. 28 strips in `assets/sprites/effects/`, 128 px frames or 192 / 256 / 512 px via `prepare_sprite.py --anim --frame-px`; huge thin rings (Seraphine's nova, Soul Nova) are built from one 1024 px ring image. `EffectManager.ring()` / `pop()` / `spawn_ring()` / `abyss()` / `impact()` take an optional anim id and the drawn shape stays the fallback; every such `AnimData` duration equals its code duration, so effect lifetimes and same-seed autotest summaries do not depend on the art. `EffectManager.ring_under()` hides the inner rings under the Abyssal burst and Soul Nova while their art exists, keeping the effect alive for its full time. Art-only effects with no drawn shape (`bolt_impact` on Shadow Bolt / Void Bolt / Void Shard hits, `level_up` following the necromancer, `evolution` when a chest grants one) play through `EffectManager.burst()` into `AnimBursts`, one batched ring-buffer node outside the Effect pool: nothing without the art, no effect-count change, no RNG. The Doom Brand sigil is violet (Death Mark is the player's colour). |
| — | Zone floor tiles (art pass) | The eight March and Sanctum zone floors (`tiles/march_*`, `tiles/sanctum_*`, 128×128, seamless) and the March road strips (`tiles/march_road`, the paved `tiles/march_road_fortress`, 192×140, the dirt road's edges fading into transparency) are built from AI sources by `tools/make_tile.py`. Organic floors are made seamless with cut paths; floors with regular joints (flagstones, mosaic, cloister walks, marble slabs, paving) use a joint pattern that repeats by construction, filled from the AI texture. Each zone has up to two variants whose edges equal the base tile's (none for the Fortress Approach and the Final Sanctuary). Floors stay dark and quiet: mean OKLab L 0.24-0.29, with seven new floor-only shades in `palette.json` (grass, ochre, slate, ash, dirt, moss, marble), so every unit keeps its +0.15 contrast. No purple is baked in (the Sanctum corruption overlay adds it). Purely visual; the code decorations stay on top until the decals pass. |
| — | Floor decals (art pass) | On a zone's tile floor each hashed code decoration becomes a flat pixel-art decal (`decals/<zone>_<name>.png`, 1 art px = 1 layout px, sharp-pixel shader, no outline or shadow, nothing solid-looking) at the same hashed point, with variants picked by the same cell hash. It is dropped where the tile already shows it (cobbles, mud, turf, tesserae, veins, cracks, slabs, trampled dirt, rubble, March II grass), or stays code-drawn when it is a soft translucent effect (Graveyard fog, Fortress tower shadows, stained-glass light). Standing stakes, crates and banner posts are drawn fallen or smashed flat. The Sanctified Halls carpet runner is a seamless 128×36 strip. The Sanctum corruption overlay is drawn last on the tile floor, so it covers the decals like the tiles. No tile PNG means the code floor and decorations exactly as before; a missing decal PNG means that decoration's code drawing. Data in `decal_data.gd`; sources and the rebuild script in `art_source/decals/`. Purely visual: autotest summaries unchanged. |
| — | Title: Necropathy | Owner decision (Oct 2026): the game's true title is **Necropathy** (working title: Gravebound). Renamed everywhere players and builds see it: the main-menu title, `config/name`, the export products and executables (`Necropathy.exe`, `Necropathy.x86_64`), the CI artifacts and release zips (`Necropathy-windows.zip`, `-linux.zip`), the autotest summary header and the docs. Godot names the `user://` folder after the project, so `SaveMigration` (run first thing from `GameState._ready()`, never in the autotest) copies `save.cfg` and `settings.cfg` from the old `app_userdata/Gravebound` folder on the first launch whose own folder has neither; the old folder stays as a backup, so playtesters keep their Soul Ash, unlocks, records and settings. `NECROPATHY_AUTOTEST=1` replaces `GRAVEBOUND_AUTOTEST=1` (both accepted). The original raw spec keeps its file name (`docs/Gravebound_Complete_Game_Design_and_Horde_Spec.txt`, the source of record); the GitHub repository name is unchanged. |
| — | UI kit and title logo (art pass) | Pixel-art NECROPATHY wordmark (`assets/ui/logo.png`, 246×90 art px drawn at ×2; image-AI source converted to the grid, skull hand-fixed; the plain label stays the fallback) on the main menu; the app icon is the logo's O (`config/icon`). A 9-slice UI kit drawn by `tools/ui_kit.py` from the palette (margins in `ui_art_data.gd`; fills keep the UI's own dark colours) (ornamented in the menu modernization: dithered gradient fills, tiled edges, bone rosettes, the ornate / header / ribbon / divider kinds and the kit slider; see "Ornamented UI kit"), served by `UiTheme.style(kind, accent, state)` with unchanged content margins and the flat look as the fallback; accents violet / gold (evolution, chest, victory, selected) / crimson (run modifiers, the Oath) / soul / dim; a 3 px soul-teal focus ring outside the focused control; HUD slot sockets and bar frames; the sharp-pixel material on framed controls. **Cut (chamfered) corners on every UI element** (owner decision, Oct 2026): kit frames, icon badges and the flat `UiTheme.box()` fallback (`corner_detail = 1`, a straight cut instead of a rounded arc). A reskin: every layout, focus link and controller path unchanged. |
| — | Walk cycles | Art pass (Oct 2026), visual only. 8-frame walk strips `assets/sprites/<key>_walk.png` (frames the still's exact size, frame 0 = the still) cut procedurally from the approved stills by `tools/walk_cycle.py` (a hip-line rig: legs sheared and shortened row by row, the upper body rigid with a 1 px dip; weapons and shields move with the body; every pixel comes from the approved still, so no style drift). An AI walk-sheet pilot redrew the characters (lost faces, changed helmets) and was rejected. The frame follows the engine-motion step phase (`WalkData`: walking above 14 px/s, standing below 8 px/s, the stretch bob cut to 35%); standing units show the still. Deterministic, no RNG; no measurable frame-time cost. 49 units: the 12 characters and 16 skins, 12 summons (warrior, archer, mage, mender, warder, rogue, risen, bone hound, Death Knight, Gravebow, Shadow Reaper, Hellhound) and 9 Covenant soldiers; floating, flying, giant, siege and boss units keep the still with engine motion. Robes swing 1 px at the hem (subtle by design); no arm swing yet. |
| — | Boss attack poses | Art pass (Oct 2026), visual only. The three stage bosses show attack poses: Sir Alaric (hammer raised overhead in every windup, a shoulder charge, the slam's crouch in recovery), Marshal Vael (flaming sword raised in every windup, the Shieldwall crouch, the cleave's follow-through) and Seraphine (the relic staff raised in every cast, normal and Avatar). The boss scripts already report a pose number from their attack phase (0 walk, 1 windup / cast, 2 special stance, 3 strike); `BossPoseData` maps it to a sprite (`bosses/<boss>_<pose>.png`) and `SpriteBank.draw_pose()` draws it with its bottom edge on the still's bottom edge (feet never jump), under the still's shadow, else the still. Poses change no timing, hitbox or telegraph: same-seed autotest summaries are unchanged. 8 sprites, generated with each boss's still attached so they stay on model. |
| — | Releases: version and notes | v0.5.0 (Oct 2026) is the first release as Necropathy. The version lives in `project.godot` (`application/config/version`, shown on the main menu as "v0.5.0" in place of the old "Prototype build" line) and in the Windows file version fields of `export_presets.cfg`. Each tag has hand-written player-facing notes in `docs/release_notes/<tag>.md` (images in `docs/media/<tag>/`, linked by raw GitHub URL at the tag); CI makes the release "Necropathy <tag>" with those notes as its body, GitHub's generated changelog below them. Gameplay unaffected. v0.6.0 (Oct 2026, owner: "call this 6") ships the menu modernization, the Codex, Credits, confirm dialogs, the menu theme and the +5% player damage; the v0.5.0 tag was pushed as `v,0.5.0` (a typo), so its release kept the generated changelog only and the v0.6.0 notes link the v0.5.0 notes for players who missed them. |
| — | Card text: one sentence | Owner request (Oct 2026): level-up card descriptions are one short sentence (about 6-14 words) in the game's voice, saying what the thing does, with no numbers (the stat lines carry them) and no lore padding: every spell, summon class, passive, spell evolution, summon evolution and the Profane Pact. No description spells out an evolution recipe (the "At Lv 5, with X at Lv 5, a treasure chest evolves it into Y" sentences are gone from every passive), in line with the recipe book's discover-it rule. Summon classes have their own sentence (`UnitData` "description", shown on new and upgrade cards like a spell's), replacing the generated "Raise X to fight for you..." / "Strengthen your X." text; the respawn interval moved to a stat line on the new card. Text only: same-seed autotest summaries are unchanged. |
| — | Pixel fonts wired (font pass) | Pixelify Sans Bold renders cleanly only at 11, 23, 24 and 27+ px (glyph check over 9-48 px; at 12-22 px "2" fills into "8", "C" into "O"), so its glyphs are always drawn from its 11 or 23 px pixel size and scaled to each label's size through the sharp-pixel shader: every glyph is correct at any window size and layouts are unchanged. Jacquard 24 only at its 43 px em, for event, zone, stance and evolution banners (wrapping at 680 px; the stance word in title case; HUD banners no longer wrap since "HUD banner queue"). Long descriptions kept Godot's default font until "Body font: Jersey 10". Fonts imported mono, unhinted, oversampling 1. Settings key rows tightened so Back fits at 720 px. |
| — | Recipe icon row | Owner decision (Oct 2026), **replacing** the "Evolution recipe book" note that the existing card text stays: level-up cards no longer spell out evolutions. A spell, passive or summon card shows `[base] + [passive] = [evolution]` icons (the Bishop: Menders + Warders + Dark Benediction) **only once that recipe is discovered** (Meta `[recipes]`); otherwise it shows nothing about evolutions, so recipes are truly discovered. The Recipes pause view is unchanged (`recipe_icon_row.gd`). |
| — | Pixel font: Jersey 10 (owner pick, replaces Pixelify Sans) | The owner compared 9 pixel fonts after Pixelify's "2" read as "8" and "5" as "S" in-game. **Jersey 10** (SIL OFL 1.1, © 2023 The Soft Type Project Authors; 75-unit grid, pixel em 18.67 px, 10 px caps) is drawn everywhere Pixelify was: HUD, numbers, headings, labels, buttons, card names, the recipe row's signs and the in-world damage numbers. It is drawn from one exact 19 px raster at 19 / 28 / 38 / 57 px (1, 1.5, 2 or 3 layout px per font pixel) through the sharp-pixel shader, never minified; UI sizes map to the same cap height (×1.31), and the font's empty line space is trimmed 2 px top and bottom. Every screen checked to fit at 1280×720. Jacquard 24 banners unchanged; Pixelify Sans removed. (Later: long descriptions moved to Jersey 10 too and Jacquard also sets screen titles, see "Type tiers" and "Body font: Jersey 10".) This supersedes the Pixelify half of "Pixel fonts" and "Pixel fonts wired". |
| — | Ornamented UI kit | Menu modernization (Oct 2026), visual only. Owner: "I like the ornaments, we don't want it to look plain and unappealing." The 9-slice kit (`tools/ui_kit.py`, still procedural from the palette, 1 texel = 1 layout px, cut corners on every element) gets: an **ordered-dither (4×4 Bayer) vertical gradient** in every fill (lighter top tinted toward the accent, darker bottom; inverted on pressed buttons / cards; sockets shadowed at the top), kept in the top / bottom 9-slice margins (`UiArtData.SLICE_V`) so it keeps its pixel size; edges and centres are **tiled, not stretched** (`AXIS_STRETCH_MODE_TILE`), with every ornament and its outline one texel clear of the tiled band (the generator raises otherwise); crisper bevels and button glints; panels get a bone rosette with a gem in each cut corner, cards a double frame (dark channel, inner rail) with rosettes and serif bone brackets; a thicker, ink-outlined focus ring. Ornaments are material masks shaded by one top-left light after mirroring, so every corner is lit correctly. **New kinds** in violet / gold / crimson: `ornate` (hero panel: bone inlay, dark channel, bone filigree corners with a gem rosette, knuckled arm, thorn and spiral curl, and a **skull keystone** with bone wings rising 9 px over the top edge), `header` (title band, pointed end caps, gem-diamond finials), `ribbon` (banner backing for the Jacquard banners: stitched cloth band, swallow-tail tails behind its lower half), `divider` (rule with a central skull between gem studs), and the **kit slider** (recessed track, violet fill, bone-and-gem grabber: soul-teal when hovered / focused, dim when disabled) as the Theme default for every HSlider, replacing Godot's white round knob. Crests that must not stretch (keystone, finials, divider skull) are separate PNGs drawn at their own size by the new `KitStyleBox` (`scripts/ui/kit_style_box.gd`; placement in `UiArtData.CRESTS`). API for screens: `UiTheme.ornate_panel(accent)`, `header_band(text, accent, size)`, `ribbon(accent)`, `divider(accent)`, `style("ornate" / "header" / "ribbon" / "divider" / "track" / "fill", accent)`, `has_kit_slider()`. Content margins of the older kinds are unchanged (no layout moved); the new kinds' margins are in `UiArtData.CONTENT`. The sharp-pixel shader's linear fallback is now decided per axis (identical for uniformly scaled sprites), so tiled 9-slice seams do not blur the 1-texel rings. |
| — | Type tiers (menu modernization) | Every screen sizes text by role, not by number: `UiTheme.Tier` = **TITLE** (Jacquard 24 at its 43 px em: screen titles and banners, in title case because blackletter capitals read poorly), **HERO** (Jersey 10 at 57 px: big numbers), **HEADER** (Jersey 38: section headers, the HUD timer, the Ossuary balance, the end-screen Soul Ash headline), **NAME** (Jersey 28: item / card / upgrade / stage names and buttons; the theme's Button default), **BODY** (Jersey 19: descriptions, stats and secondary lines; the theme default) and **LABEL** (Jersey 19, upper case, +2 px letter spacing, a whole font pixel so it stays on the grid: small section labels such as "Difficulty", "Army stance", card kind tags). Sizes live in `UiArtData.TYPE_*`; helpers `UiTheme.tier_label()`, `set_tier()`, `tier_px()`, `para()` (wrapped BODY) and `title()`. Dense rows keep BODY where NAME would not fit (Settings key buttons and toggles, pre-run modifier names, Ossuary upgrade lines). Every screen migrated; checked at 1280×720 and 1920×1080. |
| — | Body font: Jersey 10 (owner: "Jersey, let's keep it cohesive") | Long descriptions (level-up cards, stage cards, difficulty, run modifier, Hyper and character details, the Ossuary description and dialogs, pause stance help, recipes) are Jersey 10 at the BODY tier (19 px, sharp); Godot's smooth fallback font is no longer used anywhere in the UI. Jersey body text is wider (~7.4 px per character) and taller (~21 px lines) than the old 11-13 px smooth font, so the screens keep one or two lines on a card's face and move the rest into its tooltip: a difficulty card shows one line (the per-level numbers are its tooltip), a run modifier is one line (name, reward, state) with the focused one's effect in a line under the grid, and a character's flavour title is its tile tooltip. The wave-2 screens were laid out for it (see "Stage select vignettes", "Pre-run setup: the character is the hero", "Ossuary redesign"). |
| — | Input hints (menu modernization; closes "menu key hints should reflect rebinds") | `InputHints` (`scripts/ui/input_hints.gd`, data in `input_hint_data.gd`) draws key / pad-button **chips** from the CURRENT bindings (`Settings.key_name()` for rebindable actions, else the InputMap) and the **last device used**: a tiny always-processing node under the tree root watches input (keys / mouse clicks / mouse moves ≥ 6 px = keyboard; pad buttons / sticks past 0.5 = pad) and every chip redraws when the device changes or a key is rebound. Keyboard chips are bone keycaps with the key name (Esc, Enter, Shift, "WASD" for movement); pad chips are Xbox-style: A / B / X / Y as coloured octagons (green / red / blue / yellow, cut corners, never round), LB / RB / Start / LS / RS as grey chips, stick flicks and the D-pad with a drawn arrow. Chip frames are pixel images at 1 texel = 1 layout px through the sharp-pixel shader. A reusable **hint strip** (`InputHints.strip()` / `bottom_strip()`) replaces hard-coded strings: main menu (Select), pause (Move, Step, Rally, Bolt aim, Resume, plus a chip on each stance tile), level-up (1 / 2 / 3 chips on the cards and in the strip, keyboard only; A on the pad; chips inside Reroll / Banish / Skip; a Cancel chip on the banish prompt), chest Claim, the results card's Restart / Main Menu, Settings (Select or Rebind / Back), the stage select, pre-run setup, Ossuary, Recipes, Codex and Credits (hint strip or button chips), the HUD's Shadow Bolt aim line, and the HUD Grave Step / Dread Rally key labels (RB / LB on a pad). Purely visual: never touches gameplay; headless runs see no input, so the hints stay on keyboard. |
| — | Developer text removed | The main-menu controls manual, the HUD's permanent "Esc: Pause  T / Y: Bolt aim  F3: Debug" line and the pause menu's "F3: Debug" are gone (F3 still works); the HUD's difficulty / modifiers box shows only when the run differs from the standard one (another difficulty, a run modifier, Hyper, the Pact or the Oath), without the "Modifiers: none" filler. Buttons trimmed to one word where they were sentences (Play, Ossuary, Standard, Begin; Standard's details in its tooltip). Screen titles in title case for Jacquard (Paused, Settings, Recipes, Level 12, Treasure Chest, Victory / Defeat / Time's Up, The Ossuary, Choose Your Battlefield, Prepare the Ritual). |
| — | UI motion layer | One shared motion vocabulary for every screen (`UiMotion`, numbers in `ui_motion_data.gd`, all `# TUNING (not in GDD)`): a screen opens with a ~0.18 s fade while its panel rises 6 px and grows from 0.96, and closes with a 0.1 s fade (then freed / hidden; a closing screen stops taking input at once so a second Esc reaches the screen under it); cards, rows and tiles enter staggered (0.055 s apart, fade + 12 px rise + grow with a slight overshoot; chest rewards rise in one by one, 0.2 s apart, after the chest bursts open); a hovered or focused card / tile (auto: buttons at least 56 px tall and at most 420 px wide, or opted in with `liftable()`) lifts 3 px and brightens its frame; every button squashes slightly while held (at most 4 px per side) and springs back; numbers can count up with a rising tick (the end screen's Soul Ash); the menu to run switch, back to the menu and Restart fade through black (0.2 s out, 0.06 s hold, 0.3 s in). Short motion that stops, never busy. It is purely visual: real (unscaled) time through its own driver (hit-stop and the autotest's time scale never touch it), runs while the tree is paused, never touches Engine.time_scale or the seeded RNG, and is instant under `--autotest` (same-seed summaries unchanged). |
| — | Reduce motion setting | A **Reduce motion** toggle in Settings (saved in `user://settings.cfg`, `[feel] reduce_motion`, default off) makes every UI motion instant (open / close, entrances, lift, squash, count-ups, the fade through black); the chest is shown already open (no rattle, burst or turning rays), and the level-up pillars, evolution bursts, sheens, pulsing pips and the HP damage trail are off. Sounds are unchanged. It sits in the Video tab of Settings (see "Settings tabs"). |
| — | UI sounds | Synthesized like the rest (`sound_data.gd`): `ui_back` (ui_confirm's two notes mirrored downward; Back / Cancel / Close buttons or meta `ui_back`, and Esc / pad B pressed while the focus is inside a screen opened by `UiMotion.open()`, seen on the root window's input before any screen handles it; screens where Esc means something else set meta `ui_cancel_silent`: level-up, chest), `panel_open` / `panel_close` (soft short airy whooshes, -23 / -25 dB; the level-up and chest panels keep their own sounds instead), `purchase` (Ossuary buy: a dry knock then a rising C-G-C bone-chime), `denied` (a dull low thud: Ossuary locked / can't afford / maxed, locked characters, skins and Hyper), `ui_tick` (count-up tick, pitch rising with the count). `Sfx.play_ui()` plays such a sound in place of the generic confirm click of the same press. The menu music came last (see "Menu theme"). |
| — | Menu diorama | The main menu's flat code backdrop (grey disc moon, blob tombstones, orange dots) is replaced by an animated pixel-art graveyard at night behind every out-of-run screen (owner: "That's fun, but I'll need to see it in action first"; a 20 s 1080p video went to the owner before it ships to `main`). `MenuBackdrop` (`scripts/ui/menu_backdrop.gd`, numbers in `scripts/data/menu_backdrop_data.gd`) draws layered parallax at 1 art px = 1 layout px through the sharp-pixel shader: a banded sky with a pixel moon and stepped halo, twinkling stars, drifting clouds, the odd bat flock and a rare shooting star; far hills with the Covenant's cathedral (its torches flicker) and a ruined tower; a mid graveyard made of the game's own obstacle art plus a mausoleum, an iron fence, soul lanterns and candles; the near ground on the Graveyard tile with its decals; three drifting fog banks; soul wisps rising from the graves; and small troupes of undead (rarely the necromancer with his army) shuffling past on their walk strips, at most two at once, one per lane. A slow camera drift (±9 px, 46 s) moves each depth by its parallax factor; plain layers are drawn once and only animated layers redraw each frame (Web-friendly: no full-screen shaders). Coordinates are offsets from the screen centre with the 720 px frame pinned to the bottom, so wider and taller windows reveal more scene. Purely cosmetic: real time, a private RNG (the star field has a fixed seed), no gameplay state; the autotest still skips the menu. |
| — | Menu sub-screens over the diorama | When any sub-screen opens over the main menu (stage select, pre-run, Ossuary, settings, and any later one added as a child of the menu), the menu's own content (logo, Soul Ash plaque, buttons, version, hint strip) fades to alpha 0 (it stays "visible", so the sub-screen's `close()` can still return focus to its button), the diorama dims (`MenuBackdrop.set_dim()`), and the sub-screen's own full-screen scrim is lowered to at most 0.4 alpha so the dimmed graveyard shows around its panel; closing the last one restores all three. This fixes the logo flames poking out above the stage-select panel. |
| — | Menu diorama hooks | For later screens: `MenuBackdrop.set_dim(on)`, `set_band(center_x, width, alpha)` (the dark band behind the menu column) and `set_mood(id)` fading the colours to another `MenuBackdropData.MOODS` entry (`graveyard` night, `crimson_march` dusk, `sanctum` dawn; the stage select follows the focused stage, see "Stage select vignettes"). A `MenuBackdrop` works behind any full-rect Control. Its art (`assets/sprites/menu/`) is rebuilt by `art_source/menu/make_menu_art.py`: procedural pixel art in palette colours plus two AI sources (cathedral, mausoleum) converted at their native grid; tintable masks (halo, glow, clouds, fog) use stepped alpha, never smooth gradients (art bible "Menu diorama"). |
| — | Front door screens | Menu modernization, wave 2 (owner: one-word buttons, fewer words, ornaments, the diorama, cut corners, Jersey 10 everywhere, "go the extra mile"). The **main menu**, **stage select** and **pre-run setup** are rebuilt over the menu diorama; every number and short caption is in `scripts/data/front_door_data.gd` (`# TUNING (not in GDD)`), small pixel icons are character masks in `scripts/data/mask_icon_data.gd` drawn by `MaskIcon` at whole-number scales through the sharp-pixel shader (padlock, hourglass, tomb, skull, crowned skull, trophy, candle, lich, deathlord, rune pips, ember). All motion runs on real time, keeps a private RNG, and stops under the autotest and with Reduce motion (`UiMotion.enabled()`); gameplay and same-seed autotest summaries are unchanged. |
| — | Title screen | A composed centre column over the diorama, its dark band fitted to it (`set_band`): the **living logo** (`MenuLogo`: the logo PNG is split once into letters and its five soul flames; the flames become an 8-frame loop in which each art row shifts sideways by whole art px, more toward the tip, along a wave that climbs it, so the fire sways as true pixel art at ×2; a stepped soul glow breathes behind each flame and small embers rise from the tips), the tagline (BODY), skull dividers, a **narrow column of one-word buttons** (Play, Codex, Ossuary, Settings, Credits, Quit; up / down wrap) with a pair of flickering **soul wisps** flanking the focused one and sliding to the next (`SoulMarker`, the diorama's wisp art; mouse hover moves the focus), a gold **Soul Ash plaque** (the balance rolls up on open) and the **lifetime stats** as pixel icons with numbers (runs, best time, bosses slain, achievements; names in tooltips, no pipe separators). The version sits small in the bottom-right corner, the hint strip at the bottom. Everything the menu owns lives under one content node, so the version and the hint strip now hide with the rest when an overlay opens (they showed under the stage-select panel before); focus returns to the last menu button when the last overlay closes. The Soul Ash icon goes through one class (`SoulAshIcon`): the pixel badge `assets/sprites/icons/soul_ash.png` as soon as it exists, else the code glyph. **Codex** and **Credits** call `CodexScreen.open_over(menu)` / `CreditsScreen.open_over(menu)` and **Quit** calls `ConfirmDialog.ask(menu, "Quit?", ..., "Quit", quit, true)`; the menu loads those three scripts by path at runtime (`ResourceLoader.exists` + `load`; they were built in parallel and the hook stayed), so a missing screen plays `denied` and Quit without the dialog quits at once. |
| — | Stage select vignettes | Three tall **vignette cards** (300×424 px at the 1280×720 layout). Each is topped by a small composed pixel scene (`StageVignette`, data `FrontDoorData.VIGNETTES`): the stage's own floor tile, a few of its obstacles, structures and decals, a handful of undead on the left and the **stage boss in an attack pose** facing them (Sir Alaric's windup, Marshal Vael's windup, Seraphine's cast), each unit on a drop shadow, 1 art px = 1 layout px, stepped edge shading, ambient motes (soul wisps, embers, holy light), dimmed until focused. Under it the chapter (LABEL), the name (NAME) and **one line** (`STAGE_LINES`; the GDD description is the tooltip), then a footer: best time and boss kills (pixel icons), the Soul Ash bonus and a gold **Hyper** badge once the stage was cleared on Hyper. A **locked** stage shows the same scene as a dark silhouette under a pixel padlock and a one-liner naming the boss to slay ("Slay Sir Alaric", built from the stage registry's unlock); its card is no longer a disabled button: pressing it plays `denied` and shakes the card. **Focusing a card turns the diorama to that stage's mood** (`set_mood`: night, dusk, dawn); closing the select returns it to night. While the pre-run setup is open over it the select's cards and hint strip fade out (its scrim stays), so the diorama shows around the setup. Back is a small centred button; the hint strip shows Move / March / Back. |
| — | Pre-run setup: the character is the hero | Supersedes the layout of "Pre-run setup layout" (the content is unchanged). Two columns under the one-line title (TITLE + a LABEL "Chapter · stage"), over a low scrim (0.3) so the diorama shows around them; fits 1280×720 with room for a hint strip. **Left: the hero panel** (`PreRunHero`, an ornate panel): the character being looked at (focused / hovered tile, else the chosen one) stands at **3×**, walking in place on its walk cycle on a pedestal of the chosen stage's floor with a soft glow in its school colour, wearing the skin it would wear (a focused skin tile previews that skin); a locked character stands still as a silhouette under the padlock. Under it: the name (gold when chosen), the starting spell with its icon and the stat line, the innate (LABEL name + one or two BODY lines; "Locked" + the unlock condition for a locked one), a divider, then **the skin tiles** (small portraits) and the **Hyper tile** (badge, "Hyper", On / Off / Locked, a small clear badge) with ONE detail line naming the focused tile. **Right: the setup panel**: the twelve **character tiles in one row** (60 px; the detail panel is gone, the hero replaces it; name and flavour title are tooltips), the four **difficulty cards as icon cards in one row** (pixel icon, name, one line from `LEVEL_LINES`, Soul Ash multiplier; the GDD line and every differing number are the tooltip), the eight **run modifiers as compact toggle tiles** 4×2 (rune pip lit crimson when on, name, reward; the focused one's effect is the line under the grid), and ONE gold **"Soul Ash ×N" plaque** that rolls to each new total with ticks (the breakdown, the combined enemy numbers and the Profane Oath note are its tooltip; an active Oath adds a small crimson "+ Oath N" on the plaque). Back and Standard sit under the panel and **Begin** is the strong gold primary button at its right. Focus: the left column is one row (skins, Hyper), the right column four rows (characters, difficulty, two modifier rows); row ends cross to the other column's row nearest in height, the last rows lead down to the bottom buttons; links are rebuilt when the skin tiles change. Remembered `[prerun]` choices, Restart and Standard are unchanged. Multipliers use the × sign (Jersey 10 has it). |
| — | In-run screens: colour and art | Menu modernization, wave 2 (owner bar: "polished / finished", art first, short motion that stops, ornament on the frame, colour carries meaning, fewer words). Every number is in `in_run_ui_data.gd` (`# TUNING (not in GDD)`). Colour meaning on the in-run screens: **gold** = evolution, chest, victory; **crimson** = danger, Covenant / boss events, defeat; **soul-teal** = new or focused (the level a card grants, the active stance); violet is the base. Effect strips play inside the UI through `UiFx` (the same `assets/sprites/effects/` art as the world, at a whole-number scale through the sharp-pixel shader, on real time); a gold sheen (`UiShimmer`) marks evolution cards and rewards. All of it is cosmetic: it reads the run, never changes it, draws no gameplay RNG and is instant (or absent) under `--autotest` and with Reduce motion. |
| — | Level-up panel presentation | Two columns of violet light (the `level_up` strip at x2) rise beside the card row each time the panel opens; the cards rise in one after another and lift on hover / focus. A card shows, top to bottom: its number key chip and kind tag (a soul-teal **NEW** for a new item), the 64 px icon (the 32 px badge at x2), the name, **level pips** (`LevelPips`: owned levels violet, the level this card grants soul-teal and gently pulsing, levels to come dark), a skull divider, the one-sentence description, the stat deltas and, at the bottom, the recipe icon row only once discovered (unchanged owner rule). Evolution cards are gold (frame, divider, name, "Lv N -> Evolved"), with the `evolution` vortex collapsing into the icon as the card enters and a gold sheen every 2.6 s. Skip reads "Skip +8% HP"; the status line is "Evolution ready" / "Pick a card to banish". Fix: the card row no longer holds the old and new cards together during rerolls (old cards are detached at once), which had left the whole panel drawn off-centre for the rest of a run. |
| — | Treasure chest reveal | The code-drawn chest is replaced in the panel by the real `pickups/chest.png` at x3 in a gold ornate panel: it rattles for 0.32 s, bursts open (the `chest_open` strip), its lid (the top 12 art rows) lifts 4 art px on a band of light, and slowly turning gold rays and a stepped glow sit behind it, all clipped to the chest stage so nothing reaches the title or the "3 UPGRADES" label above (fixes the subtitle overlapping the rays). The rewards then rise one by one (0.2 s apart) as **centred** fixed-width rows: icon, name, the level change and the level pips; an evolution reward is a gold row with its own `evolution` burst and sheen. The Claim button is gold. Confirm first skips the reveal, then claims; with Reduce motion the chest is shown open at once. The world chest and the "chest" icon keep `PowerupGlyphs.draw_chest` as their fallback. |
| — | Pause screen layout | Two columns. Left, a framed run summary rebuilt on every open (read-only): stage name and time left (the Reckoning time in crimson past 0:00), the character, the difficulty and modifiers in crimson only when the run is not the standard one, the build as icon rows with level pips (spells, passives) and the army as class icons with unit counts, then the four army stances as compact tiles (stance icon, name, a 2-3 word tagline, the key / pad chip; the active one framed soul-teal, a locked one dim with a padlock; the full StanceData description is the tile's tooltip; replaces the four description paragraphs). Right, an ornate violet panel with "Paused" and Resume / Recipes / Settings / Restart / Main Menu. Under both, one hint strip: Move, Step, Rally, Bolt aim, Resume. Restart and Main Menu go through `_on_restart()` / `_on_main_menu()`, which ask first through the shared confirm dialog (see "Confirm dialogs"). |
| — | Results card (end screen) | The 13-line stats label is replaced by a results card: an ornate panel, **gold on a victory, crimson on a defeat**, with "Victory" / "Defeat" (TITLE tier) on a ribbon plate and one line of flavour; the character portrait (its sprite or worn skin at up to x3, the largest whole-number scale that fits, on the stage's floor tile in a recessed frame) with the character, stage and difficulty (crimson when not standard); 2 x 2 stat tiles (time survived with "+m:ss past 0:00" or "m:ss left", enemies slain, level, the stage boss "Slain" / "Alive" / "Never came"); the build and the army as icons (read from the run: `EndScreen.game` is set by Game, read-only); the Soul Ash as a HERO number that counts up with ticks while each bonus line ticks in, and the new balance; every unlock (new character, stage, skin, Hyper mode, Hyper clear, achievements) as a small gold plate under the columns. Restart carries R / pad X, Main Menu Esc / pad B (new keys on this screen; Enter / A still press the focused button). It fits 1280x720 even with every bonus line and six unlock plates. |
| — | HUD banner queue | Every in-run banner now shows in ONE slot (`HudBanners`) under the top-centre block (timer, zone, objective, boss bars), one at a time from a short queue (at most 3 waiting; a queued banner cuts the current one short after 1.4 s on screen), on a ribbon plate whose accent carries meaning: **gold** for evolutions and synergies (announcement titles containing EVOLUTION / SYNERGY), **crimson** for Covenant and boss events (`EnemyDirector.show_banner`), **violet** otherwise (zones, revives, and event banners that are good news: CALM_EVENT_WORDS such as "destroyed", "shatters", "crumbles"). A banner is a small kicker (the announcement title), a **one-line** Jacquard headline (a headline wider than 640 px splits at its first colon, the rest joining the sub-line, then steps down to Jersey 38, then 28, then trims) and an optional one-line sub-line; it fades and rises in (0.25 s) and out (0.35 s). Timing stays in game time (event banners until their `banner_until`, announcements 3.5 s), so a banner raised under a panel waits, and the whole slot (and the stance banner) is **hidden whenever the run is not PLAYING**: nothing shows through the level-up, chest, pause or end screens any more. Replaces the wrapping event banner and the separate announcement box. |
| — | HUD bars and ability keys | The XP bar is inset (6 px from the sides, 4 px from the top, 15 px tall) inside its kit frame so its numbers no longer touch the top edge; the HP bar is 240 x 20 with quarter notches and a pale damage trail that waits 0.35 s and drains (real time; off when motion is off). The Grave Step / Dread Rally keys are InputHints chips above the icons, and Dread Rally's READY now sits under its icon instead of over it. The stance bar's keys are chips too: the keyboard key, or on a pad the right stick with its flick arrow (redrawn when the device or a binding changes). The stance word banner fades and rises and hides under panels. |
| — | Ossuary redesign (menu modernization) | Owner: "go the extra mile", "less wordy". The Ossuary (`ossuary_menu.gd`, tiles in `ossuary_tile.gd`, numbers and words in `ossuary_ui_data.gd`) is now: a title row ("The Ossuary" and the Soul Ash badge with the balance); four tree columns under kit header bands carrying each tree's pixel emblem and name in its colour; one **tile** per upgrade with only its 32 px badge icon, its name, its tier pips and its next cost (the 16 px Soul Ash symbol and a number), the frame colour giving the state (soul teal affordable, violet too expensive, gold maxed, dim with a darkened icon and a padlock locked); and **one ornate detail panel** that follows the focused / hovered tile: the icon at x2, name and pips, the one-line effect, the current → next value with a code-drawn pixel arrow (`PixelMarks`; Jersey 10 has no "→"), the cost or the missing prerequisite ("Needs Necrotic Marrow II") or "Maxed", and a Buy chip (InputHints) when it can be bought; the panel turns gold for a maxed upgrade and crimson for the Oath. The three-colour, three-line button text, the ASCII "->" deltas, the status line and the ASCII achievements line are gone (achievements move to their own screen). A purchase plays `purchase` with a soul-glow flash and a burst of pixel sparks on the tile (private cosmetic RNG, real time) while the balance counts down and the spent amount floats away; a locked / too expensive / maxed press plays `denied`, shakes the tile and blinks the cost red (all instant / skipped with Reduce motion and under the autotest). Bottom right: the **Profane Oath** tile (crimson once owned; its pips show the active tiers bright and owned-but-lowered tiers dark; pressing a lowered Oath raises it again for free), **Lower Oath** (now immediate: lowering is free and reversible, so its confirmation is gone; crimson while a tier is active), **Refund all** (still asks first, in the Ossuary's own small crimson ornate dialog showing the Soul Ash it returns beside the Soul Ash icon, Cancel focused; it keeps this dialog instead of the shared ConfirmDialog for that icon; `_on_refund_pressed()` asks, `refund_all()` refunds) and Back (with its Esc / B chip). Neither button ever looks disabled: with nothing to lower / refund a press answers `denied`. Focus: a grid inside the trees, down from any tree to the Oath tile, up from it back to the tree last visited. Fits 1280×720 (tiles 282×56, six Necromancy rows). Visual only: costs, tiers and saving are unchanged. |
| — | Ossuary and Soul Ash icon art | The Soul Ash currency, the four Ossuary tree emblems and the 19 Ossuary upgrades that were still code-drawn (`MetaGlyphs`) got pixel-art badges in the icon style (32×32, cut corners, violet ring; `assets/sprites/icons/`, art bible "Icons"), so `MetaGlyphs` is now only the fallback. Upgrade symbols use their tree's colour (Necromancy soul teal and bone, Shadowcraft violet, Survival cold blue, Fortune gold with teal crystals); the Profane Oath is the one crimson Ossuary icon (like the Pact). Soul Ash also has a bare 16×16 symbol (`icons/soul_ash_small`, like the Hyper badge) for inline costs. API: `IconGlyph.new("soul_ash", Vector2(32, 32))` (badge) and `IconGlyph.new("soul_ash_small", Vector2(16, 16))` (inline). 31 generated images, about $0.47. |
| — | Settings tabs (menu modernization) | Settings (`settings_menu.gd`, data in `settings_ui_data.gd`) is three tabs over one ornate panel of fixed size: **Audio** (Master / Music / Effects on the kit slider), **Video** (Fullscreen, Zoom Normal / Close, Screen shake, Damage numbers, **Reduce motion**) and **Controls**: the twelve rebindable actions in three groups (Move: Up / Down / Left / Right; Actions: Bolt aim / Grave Step / Dread Rally / Pause; Stances: Escort / Onslaught / Spearhead / Bone Ring), each row showing its keyboard key as a key chip on a rebind button (short names: "Esc", not "Escape") next to its **controller binding as a read-only pad chip** (the pad layout is fixed), and **Reset keys** (`_on_reset_keys()`, which the shared confirm dialog wraps). Tabs switch by focusing / clicking a tab or with **Q / E** (keyboard) and **LB / RB** (pad) from anywhere; those two chips flank the tab row. No prose: the old "Arrow keys and the pad stay bound" note is replaced by the pad column, and a bottom hint strip shows Select (Rebind on Controls) / Back for the device in use. Toggle rows keep the normal frame when on (the kit toggle icon shows the state). Fits 1280×720. Options, defaults and the save file are unchanged. |
| — | Recipes book grid (menu modernization) | The pause menu's Recipes view (`recipes_panel.gd`, layout in `recipe_book_data.gd`) is a 5-column grid of tiles in an ornate panel under a "7 / 23 discovered" count (HEADER number, LABEL word), replacing 23 identical "??? / Undiscovered..." rows: a discovered recipe is a gold-framed tile with its recipe as icons (`RecipeIconRow`: base + passive = evolution; both priest orders for the Profane Bishop); an undiscovered one is a dark tile with three empty sockets joined by dim "+" / "=" marks and a dim "?", identical for every locked recipe (owner rule: no names, no icons, not even the ingredient count). Under the grid the focused / hovered tile's detail: name, kind tag and ingredients with their levels for a discovered recipe, just "Undiscovered" otherwise. Arrows / D-pad move on the grid (down from the last row to Back, which carries its Esc / B chip). `RecipesPanel.build_list()` still builds the tiles headless for the autotest (one child per recipe, same summary line). |
| — | Codex and achievements screen | Owner-approved ("All 3"). GDD §10.1's **Collection / Codex** and **Achievements** buttons are one screen, **Codex** in the main menu (`CodexScreen.open_over(parent)`), an ornate violet panel with four tabs (Q / E, LB / RB): **Achievements**, **Spells**, **Summons**, **Covenant**. **Achievements** lists every `MetaData` achievement and every *feat* (the lifetime-counter skin unlocks The Plague Doctor, The Heretic Saint and the Dread Sovereign skin, the Hyper unlock and the twelve Hyper skins) as a card: a 32 px badge at x2 (four new gold cut-corner badges `icons/ach_*`; feats show the skin), name, one-line goal, a kit progress bar with "progress / goal" and the reward (the skin it unlocks, Hyper mode, the Soul Ash bounty); earned cards are gold with an "Earned" stamp. It only **reads** the existing counters (`Meta.achievement_progress()`, lifetime stats, `is_skin_unlocked()`): how anything is earned is unchanged. The codex pages are a tile grid per section (spells / evolutions; summon classes / evolutions; soldiers, structures, champions = the Reckoning Inquisitor and the Cathedral Guardian, bosses on big tiles) and a detail panel: the art at the largest **whole** scale (badges up to x6, sprites up to x5; a giant shrinks to fit), name, tag, one-sentence description (the Covenant's live in `CodexData.DESCRIPTIONS`), base stats and a lifetime record ("Slain: N", "Best level reached: N"). Entries are **discovered by playing** (below); unmet ones are flat dark **silhouettes** with a 1 px violet rim named "Unknown" (`flat_silhouette.gdshader`), spells a dim ghost of their badge. **Evolutions follow the recipe rule**: they read the `[recipes]` book, and until obtained they are a "?" socket with no name, shape, description or recipe (never a hint); once obtained the detail shows the recipe. Explicit focus grid (Up from the top row reaches the tabs; the boss row lines up by position), Esc / B closes. |
| — | Codex discovery and its save section | `CodexLog` (`game.codex`, built first in `Game._ready`) records what a run **meets**: a spell learned (the starting spell and every spell card, `AbilityManager`), a summon class raised (`HordeDirector.set_class_level`, so the starting Warriors count), a Covenant kind slain (`CombatResolver._kill_enemy`: soldiers, structures, the Reckoning Inquisitor, the Cathedral Guardian; ids the codex does not list are ignored), the stage boss faced (`EnemyDirector.boss_spawned`). A first sight in a run is one set insert and a forward to `Meta.codex_record()`; later sights are one Dictionary lookup. It writes only its own Dictionaries and the Meta codex: no RNG, no gameplay state, so runs stay deterministic (same-seed summaries unchanged apart from the new line). Saved as `[codex] <category> = "<id>,<id>,..."` (categories `spell`, `summon`, `enemy`, `boss`; comma-separated like `[prerun] modifiers`), written once at the end of the frame of a first sight (a deferred save; survives quitting mid-run) and never under the autotest unless `--meta-save`; lifetime kills per Covenant kind are added from the run's `kill_<kind>` stats at each run's end as `[codex_kills] <kind> = count`. Additive: older saves have neither section and start with nothing met; unknown ids and wrong types are dropped. Autotest: a `codex` summary line (entries met this run per category, new to the save, the save's codex totals and the recipe book's evolutions). |
| — | Credits screen | Owner-approved. **Credits** in the main menu (`CreditsScreen.open_over(parent)`): an ornate panel with two pages (Q / E, LB / RB). **Credits**: a slow roll that rests 1.6 s, then drifts up at 24 px/s on real time by fractional pixels (Up / Down, the wheel or a drag take over; still with Reduce motion): the NECROPATHY logo, "A game by **Smoketsu**" (the studio name in `export_presets.cfg`), "Made with **Godot Engine**", the fonts **Jersey 10** and **Jacquard 24** (Copyright 2023 The Soft Type Project Authors, SIL Open Font License 1.1), music and sound "synthesized in-engine", a generic thank-you to the playtesters (no names: nothing invented), "Thanks for playing". **Licences**: everything Godot asks a game to ship, `Engine.get_license_text()` (MIT), the third-party components of `Engine.get_copyright_info()` with their licence texts (`Engine.get_license_info()`), and the OFL 1.1 text with both fonts' copyright lines, read from `assets/fonts/OFL-*.txt`; both export presets now include `assets/fonts/*.txt` so the files ship. Built on first view (about 65,000 characters). Texts in `CreditsData`. |
| — | Confirm dialogs | Owner-approved. One shared modal, `ConfirmDialog.ask(host, title, body, confirm_label, on_confirm, danger = true)`: a backdrop, an ornate panel (**crimson** when `danger`, else violet), a Jacquard title, one short consequence line, a skull divider, **Cancel** (focused by default, so an accidental A / Enter never confirms) and the confirm word (crimson when `danger`); the focus cannot leave the two buttons; Esc / B / pause cancel (`ui_back` sound), the opener's focus comes back on close; works over the paused run; UiMotion open / close; a second ask on the same host returns the open dialog. Wired as one-line wraps of the old handlers: main menu **Quit**, pause **Restart** and **Main Menu** ("no Soul Ash is earned": an abandoned run is never awarded) and Settings **Reset keys** (violet, not a danger action). The Ossuary keeps its own crimson **Refund all** dialog (it shows the Soul Ash icon with the amount), and **Lower Oath** acts at once with no confirmation (free and reversible); see "Ossuary redesign". Texts in `ConfirmData` (the main menu's Quit passes its own line). |
| — | Menu theme ("Grave Lullaby") | Owner: "Definitely need our own menu theme." The main menu and every screen opened from it (stage select, pre-run setup, Ossuary, settings, Codex, Credits) play their own music, synthesized in-engine like every other sound (no audio files, no new tools), in the §12 palette ("ominous choirs, dark orchestration, low percussion and ambient drones"). It is a 51.2 s seamless loop in D minor at 75 BPM: 16 bars of 4/4 in an A / B form. A (bars 1-8, Dm Bb F C \| Dm Bb Gm A, i–VI–III–VII then i–VI–iv–V) puts a music-box motif over an "ooh" choir pad and a soft pedal organ, with a lute-like harp from bar 5. B (bars 9-16, Gm Dm/F Bb F \| Gm Eb Asus4–A A, iv–i–VI–III–iv–bII–V) has a sung "aah" lead over flowing harp arpeggios; it peaks on the Neapolitan E-flat (bar 14), resolves a D→C# suspension over the dominant and pulls back to the top through a timpani roll. A deep church bell (minor-third tierce) tolls each 4-bar phrase, soft timpani tuned to D / A mark the phrase starts and cadences, and a wind and candle-crackle bed and a low D drone run throughout, in a dark cathedral reverb. The motif (bars 1-4, A4 D5 F5 E5 \| D5 C5 Bb4 \| A4 C5 F5 E5 \| E5 D5 C5, rhythm "q q q. e \| q. e h") is the game's signature phrase, reusable later (e.g. a victory stinger). Score and mix: `scripts/data/menu_theme_data.gd`; renderer: `MenuThemeSynth`; playback: `Sfx.play_music()`. |
| — | Menu theme synthesis and cost | `MenuThemeSynth` renders the score into one 22.05 kHz mono 16-bit loop (2.3 MB). It uses three rates so each layer costs only the samples it needs: the music box's short high partials and the crackle at 22.05 kHz; the lead, harp, drone and wind at 11.025 kHz; the pad, organ, bell, timpani, music-box body and echoes and the reverb at 5.5 kHz. A 4-tap half-band filter upsamples between them. The voices are wavetables shaped per note by vowel formants (so the vowel stays put across pitches), with a quiet second singer whose detune drifts slowly (an ensemble, not a steady tremolo). The music box, bell and timpani are decaying partials from a recursive oscillator; the harp is a Karplus-Strong string tuned by an all-pass. The reverb is mono Freeverb-style: 4 combs and 2 all-passes. The loop is seamless: note tails wrap to the top, continuous oscillators are snapped to whole cycles per loop, the wind's noise is indexed by the wrapped sample, the reverb and wind are primed with the loop's last seconds, and the mean is removed. It is normalised to -1.1 dBFS. It has its own seeded RNG and never touches the gameplay RNG. The work is a fixed list of small jobs, so rendering can be chunked with bit-identical results. It renders lazily, the first time the menu asks for it (the autotest never does): on a worker thread on desktop (about 1.5 s of compute on the 4-core dev VM), in 4 ms per-frame steps on the Web build (only while the menu is shown). The theme fades in when ready. |
| — | Music crossfades | `Sfx` has two music players on the Music bus (the Music slider sets both). `Main` calls `Sfx.play_music(&"menu")` when the menu is shown and `Sfx.play_music(&"run")` when a run starts (as Play's fade through black begins). The asked track starts from its top and fades in: the run loop over 2.5 s, the menu theme over 2 s. The other track fades out (the menu theme over 1.2 s, the run loop over 1 s) and stops. Fades use real time, so the autotest's time scale and hit-stop never affect them. The in-run loop no longer plays on the menu. Loudness is matched: the menu theme player is at -9.5 dB (loop -15.2 LUFS at full scale) against the run loop's -8 dB (-16.5 LUFS), so both sit near -24.6 LUFS in game. |
| — | Menu modernization integration | The nine menu-modernization branches (UI kit, type and hints, motion and sounds, diorama; then the front door, in-run, archive and new screens; then the menu theme) were merged on `integration`. Where two touched the same screen: `main_menu.gd` is the front-door version (Play, Codex, Ossuary, Settings, Credits, Quit; the Codex, Credits and confirm-dialog hooks load those scripts by path); the pause menu is the in-run version, its Restart and Main Menu wrapped by `ConfirmDialog.ask`; the shared dialog also asks before main-menu Quit and Settings Reset keys, while the Ossuary keeps its own crimson Refund all dialog (with the Soul Ash icon) and Lower Oath acts at once. Visual and UI only: no gameplay number changed, and the autotest's one new summary line is `codex`. |
| — | Player damage +5% (playtest) | Owner request (Oct 2026, playtesting: "the player is feeling a bit weak"): every player and summon damage source deals 5% more. One constant, `PlayerData.ALL_DAMAGE_MULT = 1.05`, applied once at the top of `CombatResolver.damage_enemy()` (the single path all spells, evolutions, summon attacks / specials / hazards, damage over time and the Soul Nova take), before crits, Siegecraft and the enemy-side modifiers; level-up card numbers still show base values. An owner-requested exception to deferring value tweaks to the final balance pass. 16 seeds, `--mortal`: army 0 deaths before 0:00 both ways, Alaric 16/16, min HP 110 → 108, first evolution 11:24 → 10:23, build complete 16:49 → 16:43; naive deaths before 0:00 9 → 7 of 16; Soul Ash unchanged (469 → 462 army). **Superseded** by "Balance pass (Oct 2026 playtest)": the global multiplier was removed (owner: take it out, raise boss-fight power through the changes below instead). |
| — | Balance pass (Oct 2026 playtest) | Owner playtest: "failing to kill Vael after several attempts and good runs", with army builds and 1-2 spells, keeping the enemy density. Measured first on ~600 seeded autotests across the three stages, four bots and three Ossuary profiles (16 seeds per confirming config, cloud sessions in parallel): before the pass a strong army needed 2:00 for Sir Alaric, 2:23 for Marshal Vael (15/16 kills, often the whole window) and 1:40 for Seraphine; a mixed build left Vael at ~98% HP. The pass: Dread Rally raises the whole army (row below); spells ×1.2 (`AbilityData.SPELL_DAMAGE_MULT`, in `AbilityManager.apply_spell_mods()`, so the cards show it); boss HP per boss (Alaric 42,000 → 27,300 −35%, Vael 32,000 → 19,200 −40% = 21,120 on the March, Seraphine 30,000 → 21,000 −30% = 23,100 in the Sanctum, so the three fights last alike: −40% on Seraphine dropped her to ~1:00); the +5% global multiplier removed. Result (16 seeds, `--mortal`, fresh save): army bot Alaric 16/16 in 1:29, Vael 16/16 in 1:33, Seraphine 15/16 in 1:17, 0 deaths; evolve bot 16/16 everywhere in 1:23-1:49; pacing (build complete ~15-17 min, evolutions 10-12 min), Soul Ash and the Reckoning (16-19 s past 0:00) unchanged. Early deaths of weak builds on a fresh save on the March / Sanctum (naive bot 11-15 of 16) are accepted (owner): with mid Ossuary upgrades they fall to ~1 in 8. |
| — | Dread Rally raises the army | Owner decision: "the ultimate should res your whole army". On cast, every missing unit of every owned class is queued for an immediate spawn through `HordeDirector.raise_all_missing()` (the Call of the Grave path), rising beside the necromancer at full HP with the rally buff (`PlayerAbilityData.RALLY_RAISES_ARMY`); stat `rally_raised`. |
| — | Level-up weight of later items | Owner decision ("I rarely ever see the newer additions"): every later spell, summon class and passive (`shared_card_pool`) weighs `LevelUpData.WEIGHT_NEW_LATER` = 0.5 as a NEW card, replacing three fixed pools (spells 2.0, classes 1.5, passives 2.0 split between every unowned later item) that had fallen to ~0.2 each (~2% of hands). Measured opening hands: each later item ~4% of hands (was ~2%), 74% of hands hold one (was 48%), about a third to a half of NEW cards are later items. Side effect: a build that takes only the original five classes (the army bot) gets fewer upgrades, so on the March it fields a slightly smaller army (Vael 11/16 instead of 16/16); a player who takes later items does not pay this. Autotest line `level-up offers`. Supersedes the pool weights in "Card pool with many summon classes" and "Combined balance pass". |
| — | Later summons that hit too softly | Owner: "increase the usefulness of the new summons". Each later class forced into the army bot's build on the March (8 seeds): damage per unit vs a core unit Gargoyle 183%, Corpse Catapult 179%, Abomination 178%, Rogue 141%, Frost Wraith 55%, Bone Hound 43% (pack ~half a core class), Banshee 23% (support). Base damage: Frost Wraith 12 → 18 (now 84%), Bone Hound 7.5 → 12 (71%, a 12-hound pack above a core class), Banshee 7 → 14 (41%, plus the Dirge); their evolutions multiply the base. Vael with each forced: Frost Wraith 6 → 7/8, Bone Hound 6 → 7/8, Banshee 6 → 8/8 (level at 17:00 53 → 61). |
| — | Figure redesign of the female characters | Owner request (Oct 2026): "make the female characters hotter", with "big titties and big hips" and "jiggle physics", then "go even bigger on the breasts, they should be eye popping". Applies to the female characters and the one female boss: the **Wither Witch** and the **Soulbinder** (and their Hyper skins, Thorn-Crowned Witch and Radiant Soulbinder) and **Grand Inquisitor Seraphine** (still, cast pose, Avatar of the Dawn, Avatar cast). All eight sprites redrawn (`gen_image.py` with the old sprite as reference, then the new still as reference for each variant; ~$0.53) with an exaggerated hourglass figure: a very large bust, a cinched waist, wide hips, fitted low-necked outfits with a high slit; **fully clothed**, same identity, colours, props and pose; the Wither Witch now stands tall instead of crooked. Seraphine is converted with `--no-levels` after `tools/skin_cap.py` (her skin highlights had snapped to ivory; ART_BIBLE "Converting skin"). **Jiggle:** a procedural **bust bounce** in `tools/walk_cycle.py` (rig key `bust`, `BUST_BOUNCE`, `_bounce()`): the bust box warps each walk frame like a damped spring (lag, overshoot, rebound, settle), up to 2 px on the characters and 3 px on Seraphine; pixels are moved only, never recoloured; the Witch's box stops short of her near arm. Seraphine and her Avatar gain **glide strips** (`bosses/seraphine_walk`, `seraphine_avatar_walk`: robe sway, bob, bounce), which `SpriteBank.draw()` already plays for any unit with a strip; cast poses keep their stills. Visual only: no gameplay, RNG or save change, so same-seed autotest summaries are unchanged. **Follow-up (owner: "implement all that stuff"):** the female summons **Banshee** and **Keening Lady** get the same figure (silver-blue hair kept off the chest, a slate gown, so the bust reads at 48 / 56 px; converted through `tools/pixelate_source.py` and `prepare_sprite.py --ink-l`, ART_BIBLE "Converting small figures") and glide strips with a 2 px bounce (`summons/banshee_walk`, `keening_lady_walk`); their class icons (faces) are unchanged. |

### 15.1 Core Rules and Run Structure

1. **Resolved (see 15.0).** **Run end after the boss / time cap.** Run length is "20–30 minutes," with bosses at 20:00, 24:00 and 22:00, and the
   only stated win condition is defeating the boss. Is there a hard time limit, enrage, or endless continuation if the
   boss isn't killed? *Matters for pacing, difficulty scaling and the EnemyDirector after the timeline ends.*
2. **Starting skill.** Runs begin with "a single starting skill," and an achievement for clearing without Shadow Bolt
   implies Shadow Bolt is the default, but this is never stated, and the "alternative starting ability" is undefined.
   *Needed for the first prototype loop.*
3. **Resolved (see 15.0).** **Stage 2 progression model.** Stage 2 has "guided progression through interconnected battle zones" yet also a
   fixed time-based wave timeline. How do zone progression and the clock interact (e.g., does the boss appear at 24:00
   regardless of zone)? *Fundamental to level layout and EnemyDirector design.*
4. **Resolved (see 15.0, "Sacred altars: optional").** **Altars: optional or required?** Stage 3 sacred altars are described as "optional/required." Which ones, and what
   happens if they're skipped? *Determines whether Stage 3 can soft-lock or be bypassed.*
5. **"Other resources" and healing drops.** Enemies "sometimes" drop other resources, and the Scarcity modifier
   reduces "healing drops," but no drop types, rates or values are defined. *Needed for the loot table and sustain
   balance.*
6. **XP curve.** No XP values per enemy or XP-to-level curve are given. *Required for any playable progression.*
7. **Rerolls, skips, banishes.** "Limited," but counts and how meta upgrades (Fortune tree) increase them are
   unspecified.
8. **"Situational boosts."** Listed as a level-up choice type but never defined; also unclear what is offered once all
   slots and levels are maxed.

### 15.2 Player

9. **Base player stats.** None of the 13 player stats has a base value (HP, speed, armor, pickup radius, etc.).
10. **Resolved (see 15.0, "Grave Step", "Dread Rally").** The dash is Grave Step, available from the first run
    (Ossuary upgrades add a charge and cut its cooldown); the ultimate is Dread Rally, charged by kills.
    **Dash and ultimate.** Both are "optional," the dash is "unlocked," but neither the unlock method nor any ultimate
    ability, cooldown or effect is defined. *The HUD already reserves space for an ultimate cooldown.*
11. **Resolved (see 15.0).** **Priest player healing/shielding.** Part I says priests "occasionally shield the player"; Part II says priests heal
    the necromancer only "if their skill explicitly allows player healing." Which upgrade enables player healing, and
    is shielding a separate behavior? *Directly affects priest AI and sustain balance.*

### 15.3 Horde

12. **Resolved (see 15.0).** **Body-blocking contradiction.** The Warrior has a "limited body-block effect," but the collision matrix specifies
    no friendly↔enemy blocking collision for the initial prototype. Is body-block deferred, faked via steering, or
    dropped? *Core to the Warrior's frontline identity.*
13. **Capacity distribution.** Army cap = sum of class caps + global bonuses. When a global bonus (Summon Capacity
    stat, Grave Dominion, Necromancy meta tree) adds +1 capacity, which class receives the extra unit? *Required for
    the HordeDirector's population logic.*
14. **Temporary summons and the cap.** Do temporary reinforcements (empowered graves, Crypt Defender guardians) count
    toward army cap and HUD counts? Do they use the same AI?
15. **Resolved (see 15.0).** **Level tables for Archer, Mage, Priest.** Only the Skeleton Warrior L1–L5 table exists. *`population_by_level`
    cannot be authored for the other three.* (The prototype's tables are `TUNING`; the Priest's became the Grave Mender
    and Crypt Warder tables in the priest split.)
16. **Per-level bonus stacking within one skill.** Do Warrior L3 (+15% HP) and L5 (+20% HP) add to +35% under the
    "add like-category" rule? Which bonuses form a "category"?
17. **Target-score weights.** Wd, Wt, Wr, Wv, the overkill_penalty magnitude and the normalization ranges are not
    given for any class. *Needed to implement `evaluate_target`.*
18. **Acquisition and healing ranges.** `acquisition_range` and `healing_range` are referenced in data definitions and
    pseudocode but no values are given (only "preferred range"). Gravebow is said to get "longer acquisition."
19. **Heal-score inputs.** "Normalized missing raw HP" (normalized against what?), "tactical role priority" values, and
    the Warrior "small role bonus" are unquantified. Do heals and priest attacks share the 2.0 s interval? What is the
    heal cap?
20. **Undefined FSM edges.** `RETREATING` (presumably archer kiting) has no entry/exit transitions; `CASTING` exit and
    `SPAWNING` emergence duration are not defined; "re-entering army region" (RETURNING → FOLLOWING) has no defined
    radius. Does ENGAGING → RETURNING use the ~220 px engagement zone or the 320 px soft recall?
21. **Hard recall behavior.** "Spectral fade/teleport": which, and to where (anchor slot, near player)?
22. **Formation band overlap.** The priest support band (60–125 px) overlaps both the warrior inner band (35–85 px)
    and the midline (85–155 px). Intentional? Warriors also intercept within ~80 px, while the engagement zone is
    ~220 px; the relationship between these radii should be confirmed.
23. **"Significantly greater threat."** The threshold for early target switching is not quantified.
24. **Movement speed units.** Unit movement speeds (85/95/82/90) have no stated unit; px/s is assumed but not stated.
25. **Steering weights for Archer and Mage.** Example weights exist only for Warrior and Priest.

### 15.4 Spells, Passives and Evolutions

26. **Spell numbers.** No damage, cooldown, radius, projectile count or per-level tables exist for Shadow Bolt, Shadow
    Orb Shield or Shadow Blast. Orb Shield interception is "charge- *or* cooldown-limited": which?
27. **Resolved (see 15.0, "Evolution condition", "Treasure chests and evolution delivery" and "Every evolution
    requires its paired passive at Lv 5").** The base skill and the paired passive must both be Lv 5, the run must
    have reached 8:00, and a treasure chest is the "special elite reward" that delivers it.
    **Evolution requirements.** What is the "special elite reward"? Must the base skill be L5 and/or the passive at a
    given level? *Drives elite design and the level-up panel's "evolution readiness."*
28. **Resolved for the implemented passives (see 15.0, "Later horde passives").** Soul Conduit, Warding Ritual,
    Abyssal Focus, Forbidden Knowledge, Dark Benediction, Bone Plating, Unholy Precision, Unholy Resilience and
    Bound Souls all have standalone effects and numbers; the summon evolutions Bone Plating and Unholy Precision
    pair with (Bone Colossus, Gravebow) are still to be built.
    **Passive effects.** The seven evolution passives (Bone Plating, Unholy Precision, Forbidden Knowledge, Dark
    Benediction, Soul Conduit, Warding Ritual, Abyssal Focus) have no defined standalone effect, and none of the six
    global passives has a number. There are 13 named passives for 6 slots.
29. **Synergies.** Activation rules (automatic on owning the summons? at any level?) and magnitudes for all four
    synergies are undefined.
30. **Partly resolved (see 15.0, "Rot status").** **Curse / Soulburn statuses.** Cursed arrows, Shadow Bolt DoT curse, curse marks, Mage marks, Soulburn and Death
    Nova's "cursed enemies" bonus imply shared status effects with no definitions. Is "curse" one unified status?

### 15.5 Enemies and Bosses

31. **Enemy stats.** No HP, damage, speed, armor, XP value or spawn-rate numbers for any of the 10 roster entries or
    the 3 bosses (including boss HP for phase thresholds).
32. **Partly resolved (see 15.0, "Sanctum of Judgment Covenant roster").** **Elite definition.** "Elite" is used for the Chaplain at 05:00 ("Chaplain elite"), the Radiant Inquisitor, the
    High Confessor and generic "elites." Is "elite" a unit type or a modifier applied to any unit? *Matters for
    Deathlord, Holy Retribution and evolution rewards.*
33. **Partly resolved for Stage 2 (see 15.0, "Crimson March roster"); Stage 3's "Elite paladins" are the Sun Paladin (see 15.0, "Sanctum of Judgment Covenant roster").** **Enemy roster vs. timelines.** Timeline entries such as "Patrols," "Heavy infantry," "Cathedral defenders,"
    "Outer defenders" and "Elite paladins" do not map to named roster units. Is the Templar Knight the "paladin"?
34. **Resolved (see 15.0, "Grand Inquisitor Seraphine").** **Seraphine's healing support.** Phase 3 has "no boss healing support," implying healers support her in Phases 1–2,
    which isn't specified.
35. **Resolved (see 15.0, "High Confessor revival").** **High Confessor "limited revival".** Limits and rules are unspecified.
36. **Resolved (see 15.0, "Radiant Inquisitor and suppression" and "Grand Inquisitor Seraphine").** **Suppression rules.** Radiant Inquisitors may "briefly suppress replacement locally" and Seraphine applies
    "temporary undead suppression." Durations, radii and telegraph requirements are not quantified.

### 15.6 Run Configuration and Meta Progression

37. **Resolved (see 15.0).** **Difficulty numbers.** "Easier scaling," "increased HP/aggression," "more elites": no multipliers are defined.
38. **Resolved (see 15.0).** **Modifier numbers and rewards.** Purge the Unholy, Scarcity, Frail Master and Vengeful Dead have no magnitudes,
    and no modifier has a reward multiplier, although the UI must show the stacked total.
39. **Resolved (see 15.0).** **Soul Ash economy.** Earn rates, upgrade costs, tiers and per-tier values for the four trees are unspecified.
40. **Partly resolved (see 15.0, "Achievement wording" and "Codex and achievements screen").** The wording is
    implemented and the Codex shows every achievement with its progress and reward; the GDD unlocks (Bone Golem, the
    priest evolution unlock) still pay a Soul Ash bounty instead.
    **Achievement wording.** "1,000 Warrior kills": kills *by* Skeleton Warriors, or of some enemy? "Defeat 500
    priests": Covenant Chaplains, High Confessors, or both? What is the "priest evolution-related unlock"?
41. **Bone Golem scope.** The Bone Golem is listed as a "possible future summon" yet is an achievement unlock. Is it in
    launch scope?
42. **Resolved (see 15.0, "Skins").** **Skin bonuses.** Skins have "no *default* mechanical bonuses," which suggests optional bonuses could exist (e.g.,
    in a mode). Confirm skins are purely cosmetic. Unlock conditions exist for only 2 of 5 skins.
43. **Resolved (see 15.0).** **Naming collisions.** "Necromancer" (difficulty and player character) and "Lich" (difficulty and Lich Conclave)
    may confuse players in UI and achievements.

### 15.7 Technical, Art and Scope

44. **Performance target mismatch.** Part I targets 20–40 allies / 150–300 enemies; Part II targets 40 allies / 250
    enemies; the stress tests go up to 60 allies / 300 enemies, and acceptance refers to "agreed entity counts" that
    are never agreed. Which numbers are the budget?
45. **Unplaced systems.** ProgressionManager, RunConfigurationManager and SaveSystem are listed as systems but absent
    from the proposed scene tree (which adds EffectManager, UnitContainer and EnemyContainer). Autoloads vs. scene
    nodes is undecided.
46. **Resolved (see 15.0).** **Undecided presentation.** Top-down 2D *or* 2.5D; pixel art *or* painted 2D; Godot 4 *or* Unity. *These drive
    asset pipeline, collision shapes and the ~32 px tile baseline.*
47. **MVP enemy count.** Phase 1 has two enemies, Phase 2 "six enemies, elite," and the MVP "seven enemies." Is the MVP
    seven = six + one elite, and which seven roster units?
48. **Audio voice limits.** "Aggressive" limits are required but no voice counts are specified.
49. **Partly resolved (see 15.0, "Accessibility / remapping", "Input hints" and "Reduce motion setting").** Keyboard
    remapping (with on-screen hints that follow it and the device in use) and a Reduce motion toggle exist;
    colour-blind support is still open.
    **Accessibility scope.** Listed under Phase 4 Polish, but beyond the visual toggles, no requirements (remapping,
    colorblind support for the purple/green vs. gold/crimson language, etc.) are defined.
50. **Resolved (see 15.0).** **Save system scope.** "Saves" are in Phase 2, but what persists (Soul Ash, unlocks, settings, mid-run saves) is
    not specified.
