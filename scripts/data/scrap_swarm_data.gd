## ScrapSwarmData — immutable rule constants of the Scrap Swarm spell, its
## evolution Deathless Swarm and its paired passive Machine Soul (Act III, the
## Iron Citadel; GDD §15.0 "Scrap Swarm, Machine Soul and the Rust Prophet";
## owner-approved proposal: "A cloud of bone-and-scrap drones orbits outside the
## Bone Ring (about 40 px past its outer edge, so the orbit widens as the army
## grows; owner: inside the ring it would do nothing) and shoots enemies before
## they reach your army"; unlocked by defeating Deus Ex Machina). Its per-level
## stat rows live in AbilityData.SPELLS and its evolution row in EvolutionData,
## like every spell; this file holds only the fixed rules the spell node
## (ScrapSwarm) reads, the Rust Prophet's scrap-bolt numbers
## (CharacterInnates) and Machine Soul's id and key. Data only.
class_name ScrapSwarmData
extends RefCounted

## Spell id (AbilityData.SPELLS, UnlockData).
const ID: String = "scrap_swarm"
## Damage-source tag of the drones' bolts (base spell).
const SOURCE: String = "scrap_swarm"
## Damage-source tag of the evolved drones' bolts (Deathless Swarm).
const EVOLVED_SOURCE: String = "deathless_swarm"
## Px from the Bone Ring's post radius (HordeDirector.ring_radius) to its
## outer edge: the posts' radial wobble plus a body.
const RING_EDGE: float = 18.0  # TUNING (not in GDD) StanceData.RING_DEPTH 6 + a body of about 12
## Px past the ring's outer edge the drones orbit (owner-approved proposal: "about 40 px").
const RING_GAP: float = 40.0  # Owner-approved proposal
## A drone only shoots foes at least this many px OUTSIDE its orbit radius
## minus this (they have not reached the army yet): owner-approved proposal
## "shoots enemies before they reach your army".
const INSIDE_SLACK: float = 30.0  # TUNING (not in GDD) px
## Bolt flight speed (px/s).
const BOLT_SPEED: float = 520.0  # TUNING (not in GDD)
## Drones on the orbit at most (a Deathless Swarm with every kill drone).
const MAX_DRONES: int = 12  # TUNING (not in GDD)
## Seconds an extra Deathless Swarm drone (one per kill) flies (owner-approved
## proposal: "each kill adds one for 10 s").
const KILL_DRONE_LIFE: float = 10.0  # Owner-approved proposal
## Px the orbit radius may change per second (the swarm eases out as the ring
## widens, and back in).
const ORBIT_EASE: float = 60.0  # TUNING (not in GDD)
## Px of a drone's body (drawing and its sprite's scale).
const DRONE_RADIUS: float = 5.0  # TUNING (not in GDD)

# --- Machine Soul (the paired passive) ---
## Passive id of Machine Soul (PassiveData, UnlockData).
const MACHINE_SOUL: String = "machine_soul"
## Its level-row key: the share (0..1) of every enemy's armour (percentage and
## flat) each of your hits pierces (CombatResolver.damage_enemy(), the stronger
## of it and the Wither shred applies).
const MACHINE_SOUL_KEY: String = "armor_pierce"

# --- The Rust Prophet's innate: Scrap Prophecy (CharacterInnates) ---
## Damage-source tag of a temporary Risen's scrap bolt.
const PROPHET_SOURCE: String = "scrap_bolt"
## Px a Risen looks for a foe to fire its scrap bolt at.
const PROPHET_RANGE: float = 240.0  # TUNING (not in GDD)
## Bolt flight speed (px/s) of a Risen's scrap bolt.
const PROPHET_BOLT_SPEED: float = 480.0  # TUNING (not in GDD)
