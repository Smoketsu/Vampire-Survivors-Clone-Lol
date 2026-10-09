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

### 5.4 Summon Abilities

The four summon abilities (Skeleton Warrior, Skeletal Archer, Undead Mage, Undead Priest) occupy **active** slots like
spells. Their behavior is specified in [Undead Horde](#4-undead-horde).

### 5.5 Movement and Ultimate Abilities

| Ability | Input | Status |
|---|---|---|
| Dash | Shift | Optional, unlocked |
| Ultimate | Space | Optional, 1 slot; cooldown shown on HUD |

No specific ultimate or dash behavior is defined in the source.

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
| 27 | Evolution condition | An evolution becomes available when the base spell is at **level 5** and its paired passive is at **level 1+**. The "special elite reward" is not used for now. While the condition holds, every level-up includes the evolution as a highlighted card. It replaces the base spell in the same slot, and the passive is kept. The paired passives have standalone effects: Soul Conduit gives +% spell damage, Warding Ritual gives −% damage taken, and Abyssal Focus gives −% spell cooldowns. |
| 29 | Synergy activation | Synergies switch on **automatically** while every required summon class is owned at skill **level 2+**. March of the Deathless needs any 3 classes at level 2+. Units do not need to be alive. Activation is announced with a banner and the active synergies are listed on the HUD. Magnitudes are `TUNING`. |
| 7, 8 | Rerolls, banishes, skips; maxed-out offers | Each run has **2 rerolls** and **2 banishes**. A reroll redraws the whole hand. A banish removes an item from the run and redraws that card. **Skips are unlimited** and heal 8% of max HP. Cards are drawn **weighted** toward upgrades of owned items and evolution paths, and a hand is never made only of dead cards. Once the real upgrades run out, fallback cards fill the hand: heal, +10 max HP, or instantly raise every fallen summon. Fortune-tree meta upgrades are not in yet. |
| — | Sir Alaric phases | The GDD gives Alaric no phases. The prototype uses one threshold: at **50% HP** he enters *Wrath*. Specials come about 30% faster, Consecrated Ground and Judgment of the Dead place one or two more zones/marks, and Call to Arms is cast immediately. |
| — | Boss attacks vs. body-blocking | **Hammerfall:** each summon inside the circle absorbs 20% of the necromancer's damage, up to 80%. **Divine Charge:** each undead body hit uses up part of the remaining charge distance (warriors use up more), so enough bodies stop it short. **Judgment of the Dead** damages summons only. **Consecrated Ground** zones burn and slow undead, and sting the necromancer while he stands in them. |
| 14 | Temporary summons | Empowered-grave reinforcements and Crypt Defender guardians run the shared summon AI. They do **not** count toward class caps or HUD counts, are never replaced, and crumble when their duration ends. |
| 36 | Holy ground / suppression | Consecrated ground (from Alaric or from a desecrated grave) is a visible zone, telegraphed before it activates. It damages and slows undead inside, lightly damages the necromancer, and **blocks summon replacement inside it** (localized suppression). Replacement resumes as soon as the zone fades. |
| — | Graveyard stage events | Untimed §11 mechanics are placed on the compressed timeline. Empowered graves appear from 0:30, then every 40 s; the necromancer claims one by walking onto it, for either reinforcements or an instant refill of every missing summon. Desecration happens at 2:30 (as in the timeline) and again at 4:15: Chaplains walk to the marked graves and channel for 12 s, and killing them interrupts it. The Crypt Defender event is at 4:00. |
| 33 | Templar Knight | Implemented as **heavy charging melee**. After a telegraphed lane it rushes forward, shoving summons aside. A warrior in the lane body-blocks the rush. |
| — | Arena obstacles | Sparse, solid gravestones, dead trees and crypt walls, using circle and rectangle collision without a physics engine. Units slide around them. Projectiles and line of sight ignore obstacles in the prototype. |

### 15.1 Core Rules and Run Structure

1. **Resolved (see 15.0).** **Run end after the boss / time cap.** Run length is "20–30 minutes," with bosses at 20:00, 24:00 and 22:00, and the
   only stated win condition is defeating the boss. Is there a hard time limit, enrage, or endless continuation if the
   boss isn't killed? *Matters for pacing, difficulty scaling and the EnemyDirector after the timeline ends.*
2. **Starting skill.** Runs begin with "a single starting skill," and an achievement for clearing without Shadow Bolt
   implies Shadow Bolt is the default, but this is never stated, and the "alternative starting ability" is undefined.
   *Needed for the first prototype loop.*
3. **Stage 2 progression model.** Stage 2 has "guided progression through interconnected battle zones" yet also a
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
10. **Dash and ultimate.** Both are "optional," the dash is "unlocked," but neither the unlock method nor any ultimate
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
15. **Level tables for Archer, Mage, Priest.** Only the Skeleton Warrior L1–L5 table exists. *`population_by_level`
    cannot be authored for the other three.*
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
27. **Evolution requirements.** What is the "special elite reward"? Must the base skill be L5 and/or the passive at a
    given level? *Drives elite design and the level-up panel's "evolution readiness."*
28. **Passive effects.** The seven evolution passives (Bone Plating, Unholy Precision, Forbidden Knowledge, Dark
    Benediction, Soul Conduit, Warding Ritual, Abyssal Focus) have no defined standalone effect, and none of the six
    global passives has a number. There are 13 named passives for 6 slots.
29. **Synergies.** Activation rules (automatic on owning the summons? at any level?) and magnitudes for all four
    synergies are undefined.
30. **Curse / Soulburn statuses.** Cursed arrows, Shadow Bolt DoT curse, curse marks, Mage marks, Soulburn and Death
    Nova's "cursed enemies" bonus imply shared status effects with no definitions. Is "curse" one unified status?

### 15.5 Enemies and Bosses

31. **Enemy stats.** No HP, damage, speed, armor, XP value or spawn-rate numbers for any of the 10 roster entries or
    the 3 bosses (including boss HP for phase thresholds).
32. **Elite definition.** "Elite" is used for the Chaplain at 05:00 ("Chaplain elite"), the Radiant Inquisitor, the
    High Confessor and generic "elites." Is "elite" a unit type or a modifier applied to any unit? *Matters for
    Deathlord, Holy Retribution and evolution rewards.*
33. **Enemy roster vs. timelines.** Timeline entries such as "Patrols," "Heavy infantry," "Cathedral defenders,"
    "Outer defenders" and "Elite paladins" do not map to named roster units. Is the Templar Knight the "paladin"?
34. **Seraphine's healing support.** Phase 3 has "no boss healing support," implying healers support her in Phases 1–2,
    which isn't specified.
35. **High Confessor "limited revival".** Limits and rules are unspecified.
36. **Suppression rules.** Radiant Inquisitors may "briefly suppress replacement locally" and Seraphine applies
    "temporary undead suppression." Durations, radii and telegraph requirements are not quantified.

### 15.6 Run Configuration and Meta Progression

37. **Difficulty numbers.** "Easier scaling," "increased HP/aggression," "more elites": no multipliers are defined.
38. **Modifier numbers and rewards.** Purge the Unholy, Scarcity, Frail Master and Vengeful Dead have no magnitudes,
    and no modifier has a reward multiplier, although the UI must show the stacked total.
39. **Soul Ash economy.** Earn rates, upgrade costs, tiers and per-tier values for the four trees are unspecified.
40. **Achievement wording.** "1,000 Warrior kills": kills *by* Skeleton Warriors, or of some enemy? "Defeat 500
    priests": Covenant Chaplains, High Confessors, or both? What is the "priest evolution-related unlock"?
41. **Bone Golem scope.** The Bone Golem is listed as a "possible future summon" yet is an achievement unlock. Is it in
    launch scope?
42. **Skin bonuses.** Skins have "no *default* mechanical bonuses," which suggests optional bonuses could exist (e.g.,
    in a mode). Confirm skins are purely cosmetic. Unlock conditions exist for only 2 of 5 skins.
43. **Naming collisions.** "Necromancer" (difficulty and player character) and "Lich" (difficulty and Lich Conclave)
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
50. **Save system scope.** "Saves" are in Phase 2, but what persists (Soul Ash, unlocks, settings, mid-run saves) is
    not specified.
