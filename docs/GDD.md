# GRAVEBOUND: Game Design Document

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

**Gravebound** is a top-down dark-fantasy horde-survival roguelite in which you play a necromancer hunted by the
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
| Title | GRAVEBOUND |
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
| Collection / Codex |
| Achievements |
| Settings |
| Exit |

### 10.2 Pre-Run Configuration

- Select stage: Graveyard, Crimson March or Sanctum (progression-locked initially).
- Select character skin, difficulty ([8.4](#84-difficulty-levels)) and modifiers ([8.5](#85-optional-run-modifiers)).
- Show the total reward multiplier from stacked modifiers.

*Prototype (see 15.0, "Pre-run setup screen"):* stage select, then a setup screen for the difficulty and the run
modifiers (no skins yet); the choice is remembered in the save.

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

### 10.5 Readability and Visual Options

- Clear AoE telegraphs.
- Adjustable: screen shake, damage numerals, particles, ally transparency.
- Exposed toggles (performance/readability): damage-number density, corpses, particles, unit alpha, screen shake,
  minion HP bars.
- All classes must be readable at normal gameplay zoom.

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
| 49 | Accessibility / remapping (prototype scope) | Settings include Master / Music / SFX volume, screen-shake, damage-number and fullscreen toggles, and keyboard rebinding of the **primary** key for movement, Shadow Bolt aim and pause. Arrow keys and controller bindings are fixed, and binding a key that is already in use swaps the two keys. The menu works with a controller. |
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
| 39 | Soul Ash upgrade trees and costs | Four trees as in 9.2, 18 upgrades. Each upgrade raises one stat by a fixed amount per tier. Five-tier upgrades cost 40 / 80 / 125 / 175 / 230, and other upgrades rise in similar steps. Capstones cost 450–550 and need a prerequisite in the same tree. **Necromancy:** minion HP +6%/tier, minion damage +5%/tier, replacement time −6%/tier, +1 Warrior capacity/tier (2 tiers), +1 capacity for every class (capstone). **Shadowcraft:** spell damage +5%/tier, spell cooldowns −3%/tier, spell area (Shadow Blast and pulse radius) +6%/tier, +10% spell damage (capstone). **Survival:** max HP +10/tier, damage taken −3%/tier (armor), move speed +4%/tier, one revival per run (capstone). **Fortune:** pickup radius +10%/tier, XP gain +4%/tier, Soul Ash +5%/tier, +1 reroll/tier, +1 banish/tier. Buying everything costs **8,965**, about 20 good runs. **Refund all** returns 100% of spent ash after a confirmation. |
| — | Meta modifiers in a run | Purchases apply at run start through one `MetaModifiers` object that the existing stat code reads. Each meta stat is its **own stacking category** (6.4): it multiplies the skill-level, passive and synergy bonuses. With no purchases every value is 0 and the game plays exactly as before. |
| 13 | Capacity from meta upgrades | A meta capacity bonus goes to the class the upgrade names (Risen Vanguard: Skeleton Warriors, which also means more starting summons) or to **every** owned class (Legion of Bone), like Grave Dominion. |
| — | Revival (Undying Will) | Once per run, lethal damage instead leaves the necromancer at **50% max HP** with 2.5 s of invulnerability and a knock-back burst. Dying after the revival is spent ends the run normally (the victory / defeat rule still depends on 0:00). |
| 40 | Achievement wording | Implemented: *Bone Legion* = 1,000 killing blows by Skeleton Warriors (strike or shield bash) over all runs; *Heretic's Bane* = 500 Covenant **Chaplains** slain; *Dread Sovereign* = Sir Alaric slain while all 4 summon classes are owned. Their GDD unlocks (Bone Golem, priest evolution unlock, Dread Sovereign skin) are not in the prototype yet, so each pays a one-time Soul Ash bounty (100 / 100 / 150) for now. The Shadow Bolt and Lich-difficulty achievements need systems that don't exist yet. |
| 50 | Save scope (meta) | Meta-progression is saved to `user://save.cfg` (ConfigFile), separate from `settings.cfg`. It holds `save_version`, Soul Ash, the tier of every upgrade, lifetime stats (runs, victories, best time, best Reckoning time, total kills, boss kills, achievement counters, ash earned) and achievement unlocks. It is written on every run end, purchase and refund, never during the autotest (unless the `--meta-save` test flag is given). Loading is migration-safe: a missing file starts fresh, an unreadable file is kept as `save.cfg.corrupt` and the game starts fresh, values are type-checked and clamped, unknown keys are ignored, and tiers whose prerequisite is missing are refunded. There are no mid-run saves. |
| — | Necromancer regeneration | The necromancer regenerates **0.3 HP/s** (18 HP per minute; `PlayerData.HP_REGEN`, `TUNING`). Without it, a build that never drew a Priest had no healing at all and always died of chip damage at 6-8 min. It now dies at the later peaks instead, while bursts still kill. |
| 11 | Priest ward timing | A priest's ward on the necromancer is **not** suppressed while he or an ally is critical. The ward is instant and has its own cooldown, so it never delays a heal. Before the balance pass, a critical summon (common in the boss fight) stopped every ward exactly when the necromancer needed one. |
| — | Balance pass (meta none / mid / max) | Measured with the autotest bots (`--mortal`; 16 seeds for naive / army at none and max, 8 for the rest). **Fresh save:** the summoner build never dies before 0:00 (lowest HP 98/120) and always kills Sir Alaric; the naive build dies before 0:00 in about 30% of runs (9-11 min without a Priest, otherwise at the 19:00 peak) and kills him in about 25%; the spell build is in between. **Meta mid:** no bot died before 0:00 and every bot killed him. **Meta max:** nothing dies before 0:00, the summoner build kills him in 70-115 s (at least 16 of his attacks), and the Reckoning still ends every run, 15-55 s past 0:00 (6-24 s at no upgrades). Void Barrage was nerfed (damage 30 → 24, cooldown 0.5 → 0.6 s, pierce 3 → 2, shard damage 50% → 40%), which cut its damage share from about 83% to about 62% in the spell build and from 43% to 31% in the summoner build. Build complete: 16:30-20:00 at no upgrades, 15:40-17:10 at max (the max XP and pickup bonuses add about 3-4 levels by 20:00). Soul Ash is unchanged: about 450 per good run at no upgrades, 100-150 for a death at 9-11 min, and the Reckoning is about 8% of a good run. |
| — | Power-up drops | Six data-driven drops (`PowerupData`, numbers `TUNING`): **Soul Magnet** (every XP crystal flies to the player), **Grave Feast** (heals 30% max HP), **Hyper** (10 s: spells ×2 damage, cooldowns halved), **Stasis** (5 s: every enemy frozen, no movement / attacks / heals / projectile spawns; Sir Alaric frozen for the first half; Reckoning enemies immune; a frozen attacker's telegraphs, Alaric's marks and his arming zones pause with it, and frozen Desecration Chaplains do not channel), **Dark Frenzy** (12 s: summons ×1.5 damage and ×1.5 attack speed, a separate stacking category in the horde's effective stats) and **Soul Nova** (rarest; kills every regular enemy on screen, elites lose 50% of current HP, the boss 5% of max HP, Reckoning immune; routed through the combat resolver so kills drop XP and count). Drop chance 0.2% per regular kill, 20% per elite, guaranteed from Sir Alaric; weighted type draw (3 / 3 / 2 / 1.5 / 2 / 0.5); a pity timer drops one on the next kill after 120 s without a drop (about 17 per run); at most 3 on the ground; each despawns after 30 s (blinking for the last 7 s); none from Reckoning enemies or after 0:00. Collected by walking over them (12 px from the body edge, a fixed radius, not the XP pickup radius). **Re-collecting a running buff refreshes its duration to full; buffs never stack.** Drop rolls use their own seeded RNG. |
| 27 | Treasure chests and evolution delivery | Chests are the GDD's "special elite reward": elites drop one at 10%, Sir Alaric always, and a pity timer drops one from the next kill after 360 s without a chest, or after 40 s while an evolution is ready (none from Reckoning enemies or after 0:00; they never despawn, at most 3 on the ground); about 4-7 per run. Opening one pauses the run with a short reveal and grants 1 upgrade before 15:00 elapsed, then 1 / 3 / 5 upgrades (weights 85 / 12 / 3), from the normal weighted level-up pool. **Every ready evolution is granted first, and evolutions are delivered only by chests**, no longer as level-up cards (this supersedes the "highlighted card" delivery in the Evolution condition row above; the eligibility condition itself is unchanged). Chests never grant the Profane Pact; with nothing left to upgrade a chest heals (Dark Restoration). |
| — | Profane Pact (in-run difficulty) | A 5-level passive item offered on level-up cards (0.4× card weight) that takes a passive slot and can be banished, like Vampire Survivors' Curse. Per level: enemy spawn rate (trickle rate and soft cap) +5%, enemy HP +5%, enemy damage +3%; rewards XP +8%, Soul Ash +12%, power-up drop chance +15% (`TUNING`). The card shows every penalty and reward as old → new; the HUD Modifiers area shows the level and the combined effect. |
| 39 | Profane Oath (meta difficulty) | A standalone 5-tier Ossuary entry ("Oath", outside the four trees), cheap on purpose (25 / 50 / 75 / 100 / 125) since it is a risk / reward choice. Each active tier from the first second: enemy spawn +6%, HP +5%, damage +4%; XP +5%, Soul Ash +10%, drop chance +10% (`TUNING`). The player can lower the **active** tier (to off) with a confirmation and no refund; owned tiers can be raised again for free; Refund all returns everything. Shown on the HUD and as its own bonus line on the end screen. The autotest `--meta` profiles never include it (`--oath=N` sets it). |
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
| 37, 38 | Pre-run setup screen (§10.2) | After the stage select, **Prepare the Ritual** shows the four difficulty cards (one selected; each lists the GDD effect and every number that differs from the standard level) and the eight run-modifier cards (effect, Soul Ash reward, ON / off), the stacked total Soul Ash multiplier and the combined enemy multipliers (at the start and by 0:00), with Back, Standard (Necromancer, no modifiers) and Begin. Keyboard, mouse and controller navigable with explicit focus neighbours; Esc / B returns to the stage card. The last confirmed choice is remembered in the Meta save (`[prerun] difficulty` and `modifiers`, a comma-separated id list; additive: an older save without the section gets Necromancer and no modifiers, unknown ids and wrong types are dropped), and Restart keeps it (`RunConfig.duplicate_config`). **All levels are open from the start**: the GDD implies no difficulty unlock (§9.4 only names an achievement for clearing the Graveyard on Lich). The HUD Modifiers area shows the difficulty, the run modifiers (short names) and their Soul Ash multiplier above the Pact / Oath lines; the end screen lists the difficulty and the run modifiers in the run column and their two Soul Ash lines. Autotest: `--difficulty=ID` and `--modifiers=a,b` (or `all`); the summary adds a `difficulty` line (every effective multiplier and the Soul Ash parts) and a `difficulty results` line. |
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
| 10 | Grave Step (the dash) | Owner-approved. **Shift** (gamepad **RB**): a **110 px** shadow step over **0.15 s** in the movement direction (the last one when standing still), **0.2 s of invulnerability** from its start, **5 s cooldown**, charges recharge one at a time. **Available from the first run** (owner decision: no unlock). It passes through enemies and summons (the necromancer never collides with bodies) but **not obstacles**: the step is measured with `Arena.clear_length()` (8 px samples with the player's radius) and ends on `Arena.free_point()`, so it stops short of a gravestone, tree or wall and never ends inside one (a step shorter than 12 px is refused and keeps its charge); the arena has no outer bounds. The army simply follows as when he walks. Visuals: fading violet afterimages along the path and a departure puff (`EffectManager.ring`, anim id `grave_step_trail`). Code `scripts/player/grave_step.gd`, numbers `PlayerAbilityData` (`TUNING`). |
| 10 | Dread Rally (the ultimate) | Owner-approved. **Space** (gamepad **LB**). No cooldown: a **soul meter filled by kills** (owner decision): 1 point per kill, 8 per elite or Crimson March structure, 60 for the stage boss; **240 points** fill it. Measured kill rates between 6:00 and 12:00 (Graveyard, seed 1, `--mortal`): army bot ~205 / min, naive ~165 / min, i.e. a full meter in ~70-90 s mid-game (the first fill takes ~140 s, late-game fills ~40-60 s). The meter persists, caps at full, and kills during the rally's buff do not charge it. Casting it: every summon outside its formation band drops its target and **returns** to the necromancer and the army moves **+120% faster for 1.5 s** (a surge, no teleport); every summon **heals 30% of max HP** (`CombatResolver.heal_unit`); for **8 s** the army gets **+40% damage and +40% attack speed** (`HordeDirector.compute_stats`, its own timed category like Dark Frenzy); enemies within **120 px** are knocked back (460 px/s ÷ mass, so bosses resist, structures never move); a dark burst (`EffectManager.ring`, anim id `dread_rally`), an abyss vortex and a big screen shake. Code `scripts/player/dread_rally.gd`. |
| 10, 39 | Grave Step Ossuary upgrades | Two upgrades through `MetaModifiers` (stats `dash_charges`, `dash_cooldown`): **Twin Shadow** (Survival, +1 charge, 1 tier, 300 Soul Ash, needs Fleet Shade I) and **Restless Shade** (Shadowcraft, the tree of cooldowns: −10% cooldown per tier, 3 tiers, 60 / 120 / 190, so 5 → 3.5 s). Priced like Grave Call (a comparable 3-tier upgrade) and between Fate's Thread and the 450-550 capstones. Buying everything now costs 9,635 (was 8,965), about 21 good runs. The `--meta=mid` profile includes Restless Shade II and Twin Shadow; `max` both in full. |
| 10, 49 | Dash / ultimate input | New input actions `dash` (Shift, pad RB = button 10) and `ultimate` (Space, pad LB = button 9), both **rebindable** in Settings like the other gameplay keys (primary keyboard key). They are read in `Game._unhandled_input()` only while the run is PLAYING, so the Space / A that confirms a level-up card or closes a chest never fires the rally (those panels handle the event and the run is paused). The level-up panel's own LB / RB (banish, skip) only act while it is open. Cooldowns, the meter and the buff run on game time (pause, level-ups and hit-stop freeze them). HUD: bottom centre, flanking the ability bar: the Grave Step icon with one pip per charge and a recharge sweep, the Dread Rally icon with its meter, a pulsing READY border and the buff time (`hud_abilities.gd`); key names follow rebinds. |
| 10 | Autotest use and first measurements | Every bot dashes when 3+ enemies touch a 45 px circle, when hit in the last 0.6 s while in danger, or to leave a boss / stage telegraph, toward the best of 12 directions (clear length, enemies and danger at the landing point, flee direction), and rallies when the meter is full and the player is in danger, the boss is alive or the army is hurt (average HP < 60% or < 70% of capacity alive). Graveyard `--mortal` seeds 1-4 vs the same seeds before: **army** 0 deaths (was 0), lowest HP 112 / 115 / 112 / 104 (was 114 / 112 / 65 / 112), Sir Alaric 4/4 (4/4), Reckoning ends every run 12-19 s past 0:00 (9-28 s); **naive** 3/4 still die before 0:00, later (11:17, 10:41, 15:57 vs 9:51, 9:17, 14:40), seed 4 lowest HP 112 (was 25), Sir Alaric 0/4 (0/4). Safer, not trivial; no numbers changed. Runs stay deterministic per seed. |

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
4. **Altars: optional or required?** Stage 3 sacred altars are described as "optional/required." Which ones, and what
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
32. **Elite definition.** "Elite" is used for the Chaplain at 05:00 ("Chaplain elite"), the Radiant Inquisitor, the
    High Confessor and generic "elites." Is "elite" a unit type or a modifier applied to any unit? *Matters for
    Deathlord, Holy Retribution and evolution rewards.*
33. **Partly resolved for Stage 2 (see 15.0, "Crimson March roster").** **Enemy roster vs. timelines.** Timeline entries such as "Patrols," "Heavy infantry," "Cathedral defenders,"
    "Outer defenders" and "Elite paladins" do not map to named roster units. Is the Templar Knight the "paladin"?
34. **Seraphine's healing support.** Phase 3 has "no boss healing support," implying healers support her in Phases 1–2,
    which isn't specified.
35. **High Confessor "limited revival".** Limits and rules are unspecified.
36. **Suppression rules.** Radiant Inquisitors may "briefly suppress replacement locally" and Seraphine applies
    "temporary undead suppression." Durations, radii and telegraph requirements are not quantified.

### 15.6 Run Configuration and Meta Progression

37. **Resolved (see 15.0).** **Difficulty numbers.** "Easier scaling," "increased HP/aggression," "more elites": no multipliers are defined.
38. **Resolved (see 15.0).** **Modifier numbers and rewards.** Purge the Unholy, Scarcity, Frail Master and Vengeful Dead have no magnitudes,
    and no modifier has a reward multiplier, although the UI must show the stacked total.
39. **Resolved (see 15.0).** **Soul Ash economy.** Earn rates, upgrade costs, tiers and per-tier values for the four trees are unspecified.
40. **Achievement wording.** "1,000 Warrior kills": kills *by* Skeleton Warriors, or of some enemy? "Defeat 500
    priests": Covenant Chaplains, High Confessors, or both? What is the "priest evolution-related unlock"?
41. **Bone Golem scope.** The Bone Golem is listed as a "possible future summon" yet is an achievement unlock. Is it in
    launch scope?
42. **Skin bonuses.** Skins have "no *default* mechanical bonuses," which suggests optional bonuses could exist (e.g.,
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
49. **Accessibility scope.** Listed under Phase 4 Polish, but beyond the visual toggles, no requirements (remapping,
    colorblind support for the purple/green vs. gold/crimson language, etc.) are defined.
50. **Resolved (see 15.0).** **Save system scope.** "Saves" are in Phase 2, but what persists (Soul Ash, unlocks, settings, mid-run saves) is
    not specified.
