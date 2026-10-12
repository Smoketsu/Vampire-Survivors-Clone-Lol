## GraveSpellData — immutable rule constants of the five later necromancer
## spells (owner-approved, GDD §15.0 "Five more spells"): Death Mark, Bone
## Wall, Soul Chains, Wither and Raise Dead. Their per-level stat rows live
## in AbilityData.SPELLS and their evolution rows in EvolutionData, like
## every spell; this file holds only the fixed rules each spell node reads
## (tick rates, caps, geometry, the temporary summons they raise). Logic is
## in scripts/abilities/spells/ (DeathMark, BoneWall, SoulChains, Wither,
## RaiseDead). All numbers are TUNING (not in GDD). Data only.
class_name GraveSpellData
extends RefCounted

# --- Death Mark / Doom Brand (DeathMark) --------------------------------------------

## Seconds between brand damage ticks.
const DEATH_MARK_TICK: float = 0.5  # TUNING (not in GDD)
## Most brands burning at once (a cast skips new brands beyond it).
const DEATH_MARK_MAX: int = 24  # TUNING (not in GDD)
## Summon class a Death Mark Risen rises as (base kit, drawn as "risen").
const DEATH_MARK_RISEN_CLASS: String = "warrior"  # TUNING (not in GDD)
## Seconds a Death Mark Risen lasts before it crumbles (Restless Dead
## lengthens it, HordeDirector.spawn_temporary()).
const DEATH_MARK_RISEN_LIFE: float = 8.0  # TUNING (not in GDD)
## Multiplier (0..1) on that class's current max HP for a Risen.
const DEATH_MARK_RISEN_HP: float = 0.5  # TUNING (not in GDD)
## Multiplier (0..1) on that class's current damage for a Risen.
const DEATH_MARK_RISEN_DAMAGE: float = 0.6  # TUNING (not in GDD)
## Rank penalty (DeathMark candidate score units, lower = branded first)
## that puts an enemy already branded behind every unbranded one (a recast
## on it only refreshes the brand).
const DEATH_MARK_BRANDED_PENALTY: float = 1.0e9  # TUNING (not in GDD)

# --- Bone Wall / Charnel Bastion (BoneWall) -----------------------------------------

## Seconds between spike damage ticks on enemies pressing on a wall.
const BONE_WALL_TICK: float = 0.5  # TUNING (not in GDD)
## Radius (px) of one bone-spike segment (its blocking circle).
const BONE_WALL_SEGMENT_RADIUS: float = 9.0  # TUNING (not in GDD)
## Distance (px) between neighbouring segment centres of a straight wall:
## a 16 px step leaves no gap between two 9 px circles, so the smallest
## enemy (9 px radius) cannot slip between them.
const BONE_WALL_SPACING: float = 16.0  # TUNING (not in GDD)
## Largest distance (px) between neighbouring Charnel Bastion ring segments
## (the ring gets as many segments as it needs to stay under it).
const BASTION_SPACING: float = 18.0  # TUNING (not in GDD)
## Extra reach (px) beyond touching in which an enemy counts as pressing on
## a segment (spike damage).
const BONE_WALL_TOUCH_MARGIN: float = 5.0  # TUNING (not in GDD)
## A wall is only raised while an enemy is within this many px of the
## necromancer (else the spell retries every AbilityData.SPELL_RETRY s).
const BONE_WALL_TRIGGER_RANGE: float = 300.0  # TUNING (not in GDD)
## Aim assist half-angle (radians) around the walking direction: the wall
## faces the nearest enemy inside this cone, else the nearest enemy.
const BONE_WALL_AIM_CONE: float = 0.8  # TUNING (not in GDD)
## Most segments standing at once (the oldest wall crumbles beyond it).
const BONE_WALL_MAX_SEGMENTS: int = 90  # TUNING (not in GDD)
## Charnel Bastion shrapnel burst radius (px) around each expiring segment.
const BASTION_SHRAPNEL_RADIUS: float = 40.0  # TUNING (not in GDD)
## Extra query reach (px) of the push-out pass: the enemy grid is built at
## the start of the tick, before this tick's movement (a few px at most).
const BONE_WALL_GRID_SLACK: float = 8.0  # TUNING (not in GDD)
## Seconds a wall takes to rise / crumble (drawing only).
const BONE_WALL_RISE_TIME: float = 0.2  # TUNING (not in GDD)

# --- Soul Chains / Chains of the Damned (SoulChains) --------------------------------

## Seconds a drawn lightning arc stays visible (cosmetic only).
const CHAINS_ARC_TIME: float = 0.25  # TUNING (not in GDD)
## Most arcs drawn at once (cosmetic; older ones are dropped).
const CHAINS_ARC_MAX: int = 48  # TUNING (not in GDD)
## Radius (px) of the strike flash ring at each struck enemy (cosmetic; the
## "soul_lightning" animation plays there when its art exists).
const CHAINS_FLASH_RADIUS: float = 14.0  # TUNING (not in GDD)

# --- Wither / Necrotic Blight (Wither) ----------------------------------------------

## Seconds the armour shred lingers on an enemy after a pulse, on top of the
## pulse interval (refreshed every pulse while it stays inside).
const WITHER_LINGER: float = 0.4  # TUNING (not in GDD)
## Fraction (0..1) of the shred that applies to bosses (like
## AbilityData.ROT_BOSS_MULT for Rot).
const WITHER_BOSS_MULT: float = 0.5  # TUNING (not in GDD)
## Seconds of heal_cap the Necrotic Blight heal budget can bank.
const BLIGHT_BUDGET_SECONDS: float = 1.0  # TUNING (not in GDD)

# --- Raise Dead / Legion of Bones (RaiseDead) ---------------------------------------

## Summon class a raised skeleton rises as (base kit, drawn as "risen").
const RAISE_DEAD_CLASS: String = "warrior"  # TUNING (not in GDD)
## Most Raise Dead skeletons alive at once; a cast skips the rest.
const RAISE_DEAD_MAX: int = 8  # TUNING (not in GDD)
## Most Legion of Bones skeletons alive at once.
const RAISE_DEAD_MAX_EVOLVED: int = 12  # TUNING (not in GDD)
## Gap (px) between the chosen enemy's body and the skeleton's, on the
## necromancer's side of the enemy.
const RAISE_DEAD_OFFSET: float = 4.0  # TUNING (not in GDD)
## Angle (radians) between skeletons raised beside the same enemy (when a
## cast has more skeletons than enemies in range).
const RAISE_DEAD_FAN: float = 0.9  # TUNING (not in GDD)
