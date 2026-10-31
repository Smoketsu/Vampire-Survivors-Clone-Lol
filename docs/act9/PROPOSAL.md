# Necropathy: Act IX Proposal (The Concord of Stars)

Owner-approved, with the owner's answers. This copies the Act IX part of the Claude Docs proposal "Necropathy: Acts IV–IX
Proposal" (https://claude.ai/artifact/R4bwVB2JHPiDELgtfCTGBg) into the repo, with the owner's answers that bear on it. The
campaign rules every act keeps are in `docs/act4/PROPOSAL.md`; Act VI's decisions are in `docs/act6/PROPOSAL.md`.

**Build (Oct 31, 2026).** The owner: "Finish implementing all the rest of the planned content. Then we can talk about the
order of it again, so don't worry about epilogue stuff of each act until we nailed down what we're doing with the order."
- **No epilogue part and no closing card** for this act yet.
- The act keeps its current number and stage numbers until the act order is settled (Claude Doc "Necropathy: A New Act
  Order", https://claude.ai/artifact/B76vzD659dz2dAyy5P4bqh).
- Soul Ash follows the per-act rule: ×1, ×1.25, ×1.5.
- Concept art (a lineup, a boss and a stage image) is made first and approved by the owner before the sprites.
- Every prompt names the figure's sex. The mixed lineup holds: male soldiers, and the female kinds in the figure-redesign
  style.

## The owner's answers for Act IX (Oct 31, 2026)
- **The races: one coalition.** The Harvesters, the Brood, the Vrask and the Luminous fight together.
  - The Brood lead Stage 25, the Vrask Stage 26 and the Harvesters Stage 27.
  - The Luminous are mixed into every stage.
- **The third shared rule is Terraforming**, replacing Adaptation. Alien ground spreads across the arena over the run and
  heals Concord units standing on it. The necromancer's spells burn it back.
- The act's three shared rules are therefore **Beams, Abduction and Terraforming**.
- **A plain finale.** The Harvester fights as written; story twists wait for the act-order talk.

## Act IX: The Concord of Stars (draft, still cooking)
The harvest has stopped. Long ago, something out in the dark seeded life on this world, the way a farmer plants a field, and every few thousand years it comes back to reap the dead. This time there is nothing to reap: the necromancer has taken every soul. The Concord (a union of alien races under the Harvesters who rule it) arrives to find out why. The look is hull white and gunmetal, plasma green and laser magenta, against starfield black; each race adds one accent colour of its own. Recommended as a draft: the races, the rules and the bosses below are a starting set, and the ideas bank at the end of this section has the alternatives.

### The races
| Race | What they are | Their weapons | Leads |
|---|---|---|---|
| The Harvesters | Tall grey beings who rule the Concord and farm worlds for their dead | Tractor beams, probes, psionics | Stage 27 |
| The Brood | An insect swarm the Harvesters use to clear a world | Claws, acid, burrowing, numbers | Stage 25 |
| The Vrask | Reptilian hunters who serve for trophies | Cloaks, plasma casters, glaives | Stage 26 |
| The Luminous | Beings of living light, the Concord's priests | Beams, prisms, shields | Mixed into every stage |

### Shared rules
1. Beams (your idea, as the headline). Concord weapons are continuous beams, not bullets: a thin aiming line for 1 s, then a beam that holds and sweeps for about 1.5 s, cutting through every body on its line. Unlike Act III's shots, the ring cannot block them, so the army has to get out of the line. The necromancer's answer: Orb Shields and Warder barriers reflect a beam back along its line, into whoever fired it. At most 6 beams at once. One path, ConcordBeams, never through ProjectileManager.
2. Abduction. Saucers hover over the ring and lift a summon (or a corpse) in a tractor beam. The summon is held for 8 s; shoot the saucer down in time and it drops back, otherwise it is gone until the next replenish. It is the act's anti-army rule, answered by Archers, Gargoyles, Mages and spells. One path through the existing summon hook held_until, capped at 3 summons held at once.
3. Adaptation (the bold option). The Concord learns: once a minute, the damage source that killed the most Concord units (a spell or a summon class) becomes resisted by every new arrival for the next minute, −30%, shown on the HUD as "ADAPTED: Shadow Bolt". It pushes the player to build wide and switch targets. One stat in CombatResolver.damage_enemy(). If it feels unfair in playtests, the fallback is Gravity Wells (from the ideas bank).

### Roster
| Kind | Race | Tier | What it does | How you beat it |
|---|---|---|---|---|
| Broodling | Brood | Fodder | Fast swarms of 12 | Anything |
| Burrower | Brood | Soldier | Tunnels in and bursts up inside the ring (a dirt mound 1 s ahead) | Blockers inside the ring |
| Acid Spitter | Brood | Ranged | Lobs acid that leaves a burning puddle; arcing, so it ignores the ring | Kill it on approach |
| Grey Drone | Harvester | Fodder | Small greys with probes, in squads | Anything |
| Saucer | Harvester | Elite, flying | Abduction | Gargoyles, Archers, spells |
| Grey Overseer | Harvester | Support | A psionic pulse that stuns summons for 1 s; shields greys near it | Priority target |
| Vrask Hunter | Vrask | Elite | Cloaked (a shimmer while it moves); a three-dot plasma caster lock, then a shot | Area damage reveals it |
| Lumen Sentinel | Luminous | Ranged | Sweeping beams; a shield that soaks the first hits | Reflect its beams; Wither |
| Prism | Luminous | Support (figure style, the Star-Seer) | Splits any beam that passes through it into three | Kill it before the beams line up |
Reckoning, the Final Harvest: at 0:00 the mothership opens its eye over the arena: its main beam sweeps the whole map, saucers fill the sky, and the abduction cap is gone.

### Stage 25: The Crash Site
A Harvester scout ship lies broken in the ruins of the capital, and the Brood is hatching from it.


Zones: the Crater, the Hatchery, the Wreck, the Glass Spire.

Infestation: the Brood lays eggs in corpses. A corpse left for 6 s becomes an egg that hatches Broodlings, so the necromancer raises fast or loses the dead to the swarm (the same race for corpses as Act II's Claims, on the Brood's side).

Miniboss, the Brood Matriarch, a winged queen-guard who spits egg sacs over the ring.

Boss, the Hive Mother: a vast queen grown into the crater. The Brood (egg waves and burrowers from every side), the Burrow (she dives under the arena and erupts beneath the ring on a telegraph), the Flight (she tears loose and takes to the air, raining acid).

### Stage 26: The Proving Moon
The Vrask take the necromancer to their hunting ground on the moon, to see what he is worth.


Zones: the Landing, the Craters, the Trophy Hall, the Duelling Ring.

Low gravity: knockback goes twice as far for everyone, both armies, and leaps are longer (one value in the stage data, read by the existing knockback code).

Miniboss, the Warbeast, the Vrask's armoured hunting animal.

Boss, Vrask'Tal, the Hunt-Lord: the Stalk (cloaked, picking summons off the ring's edge; each kill hangs a skull on his belt), the Duel (he drops his cloak and fights the necromancer with a glaive, leaping over the ring), the Last Trophy (he arms the bomb on his wrist: a 20 s countdown he tries to finish standing next to the necromancer).

### Stage 27: The Ark of the Concord (the finale)
The mothership in orbit over the dead world: the Concord's capital and its harvest vault.


Zones: the Hangar, the Specimen Vaults (break the tanks to free captured beasts that attack everyone), the Reactor, the Bridge of Stars.

Miniboss, the Luminous Archon, a being of pure light whose every attack is a beam to reflect.

Boss, the Harvester: the oldest of its kind, the one who planted the world.


The Council: it fights with the Concord's powers in turn: the Brood's swarms, the Vrask's cloak, the Luminous beams.

The Reaping: it opens a tractor beam over the whole ring, and every summon starts rising. Four beam emitters around the arena must be destroyed before the army is gone.

The Gardener: it reveals its true form, a vast being of light and rings, and turns the world below into its weapon.

When it falls, the stars go dark too.

### Rewards
| Boss | Spell (paired passive) | Its character |
|---|---|---|
| Hive Mother | Bone Beetles: slain enemies burst into bone beetles that bite the next enemy → Hive of Bone (+ Chitin) | The Broodbound, a woman who wed the swarm (figure style) |
| Vrask'Tal | Soul Caster: a shoulder cannon that locks three targets with three red dots and fires → Apex Predator (+ Trophy Rack) | The Blooded, the one human who survived the Hunt (figure style) |
| The Harvester | Tractor Beam: lifts the strongest enemy into the air and slams it down → Abduction (+ Starseed) | The Starborn, a Harvester who deserted (figure style) |


Finale summon class: the Ghost Saucer, a flying ranged summon that fires short beams and lifts small enemies (evolution Black Mothership).

Counter-passives (Act IX only): Mirror Bones (reflected beams deal more and summons take less beam damage), Anchored (abductions last half as long and break when the saucer takes damage).

Achievements: Nothing Hatched (no egg hatches on the Crash Site), The Hunter Hunted (beat Vrask'Tal before the countdown ends), The Last Harvest (beat the Harvester; opens the Act IX epilogue).

### Ideas bank for Act IX
Pick, swap or combine; each idea fits the one-path rule.


Other rules: Gravity Wells (black-hole mines that pull both armies together, so the ring bunches up and area damage shines), Terraforming (alien ground spreads across the arena over the run and heals Concord units on it; the necromancer's spells burn it back), Phase Shields (shields that only one damage colour can break, shown on the shield), Time Slip (a Luminous power that rewinds one enemy 3 s, HP included, unless it is killed outright).

Other races: the Silicates (living crystal, slow and armoured, shatter into shards), the Parasites (worms that ride enemies and jump to a summon when their host dies; close to Act VI's charm, so only if Temptation changes), the Void Whales (vast space beasts as stage hazards that swallow a strip of the arena).

Other structures: one race per stage with no coalition (a cleaner art plan, three palettes); or an invasion act set on Earth (the Crash Site, a captured city, the mothership), keeping the moon for an Act X or a bonus stage.

Other twists for the finale: the Harvester is the one who made the first necromancer; or the Concord offers the necromancer a place among it, and the last phase is the Concord's other races turning on the Harvester beside you.


