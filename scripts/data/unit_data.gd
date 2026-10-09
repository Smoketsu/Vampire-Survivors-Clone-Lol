## UnitData — immutable design data for the four undead summon classes and the
## horde AI tuning knobs (GDD Part II §23–§34). The shared SummonedUnit script
## reads one row of UNITS per class; nothing class-specific lives in code.
##
## Per GDD §37 note: this file holds IMMUTABLE design data only. Per-run state
## (current level, timers, live instances) lives in HordeDirector.
##
## Numbers taken from the GDD are tagged "GDD §x"; invented ones are tagged
## "TUNING (not in GDD)". Distances are in pixels (GDD: ~32 px per world tile),
## times in seconds, speeds in px/s.
class_name UnitData
extends RefCounted

## Display / iteration order of summon classes (HUD rows, card pool).
const CLASS_ORDER := ["warrior", "archer", "mage", "priest"]

## Base stats per summon class at skill level 1, before any bonus.
## Field reference (same keys in every row):
##   display_name / plural   — UI strings.
##   max_hp                  — hit points.
##   damage                  — damage per attack (priest: offensive bolt only).
##   attack_interval         — seconds between attacks / heal casts.
##   attack_range            — preferred attack range in px. For melee it is
##                             measured edge-to-edge, for ranged centre-to-edge.
##   move_speed              — px/s.
##   radius                  — body radius in px.
##   acquisition_range       — px; how far the unit looks for targets.
##   replenish_interval      — s; per-ability sequential replacement timer.
##   band_min / band_max     — px; soft formation band around the necromancer.
##   w_pursuit / w_formation / w_separation / w_threat — steering weights.
##   attack_profile          — which attack branch the shared AI runs:
##                             "melee" | "arrow" | "aoe" | "heal".
##   target_profile          — which TARGET_WEIGHTS row scores enemies.
##   windup                  — s; cast / swing time before the hit lands.
##   projectile_speed        — px/s (0 for melee).
##   splash_radius           — px; mage explosion radius (0 = none).
##   heal_amount             — HP restored per priest cast (0 = no heals).
##   kite_distance           — px; archers retreat from threats this close.
##   heal_role_priority      — 0..1 "tactical role priority" a priest assigns
##                             to healing this class (GDD §31).
## Optional keys (read with a default of 0 when absent):
##   block_radius            — px; >0 makes the unit a physical blocker that
##                             enemies cannot overlap (warriors only).
##   block_mass              — blocker "mass" vs Enemy mass: share of an
##                             overlap correction is mass-weighted, so heavy
##                             warriors barely move and the boss shoves them.
##   engaged_speed_mult      — speed multiplier for enemies touching this
##                             blocker (they are "engaged").
##   bash_damage             — shield-bash damage on contact.
##   bash_cooldown           — s between shield bashes.
##   bash_knockback          — px/s impulse of the bash (divided by enemy mass).
##   shield_amount           — HP absorbed by a priest's ward on the player.
##   shield_duration         — s the ward lasts.
##   shield_cooldown         — s between wards from the same priest.
const UNITS := {
	"warrior": {
		"display_name": "Skeleton Warrior",  # GDD §7
		"plural": "Warriors",
		"max_hp": 60.0,  # GDD §23
		"damage": 10.0,  # GDD §23
		"attack_interval": 1.2,  # GDD §23
		"attack_range": 22.0,  # GDD §23 / §28
		"move_speed": 85.0,  # GDD §23
		"radius": 10.0,  # GDD §23
		"acquisition_range": 150.0,  # TUNING (not in GDD)
		"replenish_interval": 5.0,  # GDD §24
		"band_min": 35.0,  # GDD §26 inner defense band
		"band_max": 85.0,  # GDD §26
		"w_pursuit": 1.0,  # GDD §26
		"w_formation": 0.35,  # GDD §26
		"w_separation": 0.8,  # GDD §26
		"w_threat": 0.1,  # GDD §26
		"attack_profile": "melee",
		"target_profile": "guard",
		"windup": 0.2,  # TUNING (not in GDD)
		"projectile_speed": 0.0,
		"splash_radius": 0.0,
		"heal_amount": 0.0,
		"kite_distance": 0.0,
		"heal_role_priority": 1.0,  # GDD §31 "Warriors may get a small role bonus"
		"block_radius": 12.0,  # TUNING (not in GDD) user brief: warriors physically block
		"block_mass": 3.0,  # TUNING (not in GDD)
		"engaged_speed_mult": 0.6,  # TUNING (not in GDD) user brief: ~60% speed
		"bash_damage": 5.0,  # TUNING (not in GDD)
		"bash_cooldown": 2.0,  # TUNING (not in GDD)
		"bash_knockback": 160.0,  # TUNING (not in GDD)
	},
	"archer": {
		"display_name": "Skeletal Archer",  # GDD §7
		"plural": "Archers",
		"max_hp": 30.0,  # GDD §23
		"damage": 8.0,  # GDD §23
		"attack_interval": 1.6,  # GDD §23
		"attack_range": 170.0,  # GDD §23 / §29
		"move_speed": 95.0,  # GDD §23
		"radius": 9.0,  # GDD §23
		"acquisition_range": 260.0,  # TUNING (not in GDD)
		"replenish_interval": 8.0,  # GDD §24
		"band_min": 85.0,  # GDD §26 midline band
		"band_max": 155.0,  # GDD §26
		"w_pursuit": 0.6,  # TUNING (not in GDD)
		"w_formation": 0.5,  # TUNING (not in GDD)
		"w_separation": 0.8,  # TUNING (not in GDD)
		"w_threat": 0.6,  # TUNING (not in GDD)
		"attack_profile": "arrow",
		"target_profile": "ranged",
		"windup": 0.15,  # TUNING (not in GDD)
		"projectile_speed": 420.0,  # TUNING (not in GDD)
		"splash_radius": 0.0,
		"heal_amount": 0.0,
		"kite_distance": 45.0,  # GDD §29
		"heal_role_priority": 0.5,  # TUNING (not in GDD)
	},
	"mage": {
		"display_name": "Undead Mage",  # GDD §7
		"plural": "Mages",
		"max_hp": 35.0,  # GDD §23
		"damage": 14.0,  # GDD §23
		"attack_interval": 2.5,  # GDD §23
		"attack_range": 145.0,  # GDD §23
		"move_speed": 82.0,  # GDD §23
		"radius": 10.0,  # GDD §23
		"acquisition_range": 240.0,  # TUNING (not in GDD)
		"replenish_interval": 12.0,  # GDD §24
		"band_min": 85.0,  # GDD §26 midline band
		"band_max": 155.0,  # GDD §26
		"w_pursuit": 0.5,  # TUNING (not in GDD)
		"w_formation": 0.6,  # TUNING (not in GDD)
		"w_separation": 0.8,  # TUNING (not in GDD)
		"w_threat": 0.7,  # TUNING (not in GDD)
		"attack_profile": "aoe",
		"target_profile": "cluster",
		"windup": 0.35,  # TUNING (not in GDD)
		"projectile_speed": 260.0,  # TUNING (not in GDD)
		"splash_radius": 40.0,  # TUNING (not in GDD)
		"heal_amount": 0.0,
		"kite_distance": 0.0,
		"heal_role_priority": 0.5,  # TUNING (not in GDD)
	},
	"priest": {
		"display_name": "Undead Priest",  # GDD §7
		"plural": "Priests",
		"max_hp": 40.0,  # GDD §23
		"damage": 3.0,  # GDD §23 (minor offense when nothing needs healing)
		"attack_interval": 2.0,  # GDD §23
		"attack_range": 150.0,  # GDD §23
		"move_speed": 90.0,  # GDD §23
		"radius": 10.0,  # GDD §23
		"acquisition_range": 200.0,  # TUNING (not in GDD)
		"replenish_interval": 15.0,  # GDD §24
		"band_min": 60.0,  # GDD §26 support band
		"band_max": 125.0,  # GDD §26
		"w_pursuit": 0.0,  # GDD §26 (0 while healing)
		"w_formation": 0.7,  # GDD §26
		"w_separation": 0.8,  # GDD §26
		"w_threat": 1.0,  # GDD §26
		"attack_profile": "heal",
		"target_profile": "support",
		"windup": 0.3,  # TUNING (not in GDD)
		"projectile_speed": 300.0,  # TUNING (not in GDD)
		"splash_radius": 0.0,
		"heal_amount": 8.0,  # GDD §23 (8 HP per cast at 2.0 s)
		"kite_distance": 0.0,
		"heal_role_priority": 0.5,  # TUNING (not in GDD)
		"shield_amount": 15.0,  # TUNING (not in GDD) user brief: priest ward on player
		"shield_duration": 4.0,  # TUNING (not in GDD)
		"shield_cooldown": 6.0,  # TUNING (not in GDD)
	},
}

## Summon-ability progression, one entry per skill level (index 0 = level 1).
## Values are CUMULATIVE totals for that level, not per-level increments.
##   count           — population cap granted by this ability level.
##   hp_bonus        — +% max HP from skill levels (0.15 = +15%).
##   damage_bonus    — +% damage from skill levels.
##   speed_bonus     — +% attack speed from skill levels.
##   splash_bonus    — +% splash radius (mage).
##   heal_bonus      — +% heal per cast (priest).
##   pierce          — extra enemies an arrow passes through (archer).
##   shield_bonus    — +% ward strength on the necromancer (priest).
const LEVELS := {
	# GDD §34 example Skeleton Warrior L1–L5 (2, +1 +10% dmg, +2 +15% HP,
	# +1 +20% attack speed, +2 +20% HP = 8 total).
	"warrior": [
		{"count": 2, "hp_bonus": 0.0, "damage_bonus": 0.0, "speed_bonus": 0.0},
		{"count": 3, "hp_bonus": 0.0, "damage_bonus": 0.10, "speed_bonus": 0.0},
		{"count": 5, "hp_bonus": 0.15, "damage_bonus": 0.10, "speed_bonus": 0.0},
		{"count": 6, "hp_bonus": 0.15, "damage_bonus": 0.10, "speed_bonus": 0.20},
		{"count": 8, "hp_bonus": 0.35, "damage_bonus": 0.10, "speed_bonus": 0.20},
	],
	# L1 count 1 is GDD §23; the rest is TUNING (not in GDD), aimed at the
	# §42 sandbox composition of 5 archers.
	"archer": [
		{"count": 1, "damage_bonus": 0.0, "speed_bonus": 0.0, "pierce": 0},
		{"count": 2, "damage_bonus": 0.0, "speed_bonus": 0.0, "pierce": 0},
		{"count": 3, "damage_bonus": 0.15, "speed_bonus": 0.0, "pierce": 0},
		{"count": 4, "damage_bonus": 0.15, "speed_bonus": 0.0, "pierce": 1},
		{"count": 5, "damage_bonus": 0.15, "speed_bonus": 0.20, "pierce": 1},
	],
	# L1 count 1 is GDD §23; the rest is TUNING (not in GDD), aimed at the
	# §42 sandbox composition of 3 mages.
	"mage": [
		{"count": 1, "damage_bonus": 0.0, "splash_bonus": 0.0},
		{"count": 2, "damage_bonus": 0.0, "splash_bonus": 0.0},
		{"count": 2, "damage_bonus": 0.0, "splash_bonus": 0.30},
		{"count": 3, "damage_bonus": 0.0, "splash_bonus": 0.30},
		{"count": 3, "damage_bonus": 0.30, "splash_bonus": 0.50},
	],
	# L1 count 1 is GDD §23; the rest is TUNING (not in GDD), aimed at the
	# §42 sandbox composition of 2 priests.
	"priest": [
		{"count": 1, "heal_bonus": 0.0, "hp_bonus": 0.0, "shield_bonus": 0.0},
		{"count": 1, "heal_bonus": 0.25, "hp_bonus": 0.0, "shield_bonus": 0.0},
		{"count": 2, "heal_bonus": 0.25, "hp_bonus": 0.0, "shield_bonus": 0.0},
		{"count": 2, "heal_bonus": 0.50, "hp_bonus": 0.20, "shield_bonus": 0.0},
		{"count": 2, "heal_bonus": 0.50, "hp_bonus": 0.20, "shield_bonus": 0.60},
	],
}

## Target-scoring weights per target_profile (GDD §27):
## score = distance*Wd + threat_to_player*Wt + role_priority*Wr
##       + tactical*Wv (+ cluster*Wc for mages) - overkill*Wo
## All constituent measures are normalised to 0..1 before weighting.
const TARGET_WEIGHTS := {
	# Warriors: enemies attacking the player / close intruders first.
	"guard": {"distance": 1.0, "threat": 1.4, "role": 0.3, "tactical": 0.4, "cluster": 0.0, "overkill": 0.5},  # TUNING (not in GDD)
	# Archers: exposed healers / casters, finishable enemies.
	"ranged": {"distance": 0.4, "threat": 0.6, "role": 1.2, "tactical": 0.6, "cluster": 0.0, "overkill": 2.0},  # TUNING (not in GDD)
	# Mages: biggest valuable cluster near the player.
	"cluster": {"distance": 0.3, "threat": 0.6, "role": 0.6, "tactical": 0.0, "cluster": 1.5, "overkill": 1.0},  # TUNING (not in GDD)
	# Priest offensive fallback: nearest threat.
	"support": {"distance": 1.0, "threat": 0.8, "role": 0.2, "tactical": 0.0, "cluster": 0.0, "overkill": 2.0},  # TUNING (not in GDD)
}

# --- Leash / lifecycle (GDD §24) ---------------------------------------------

## Engagement zone radius around the player (px).
const ENGAGE_RADIUS: float = 220.0  # GDD §24
## Beyond this distance from the player a unit drops its target and RETURNs.
const SOFT_RECALL: float = 320.0  # GDD §24
## Beyond this distance a unit is spectrally teleported back (should be rare).
const HARD_RECALL: float = 650.0  # GDD §24
## Minimum spawn distance from the player (px).
const SPAWN_MIN: float = 35.0  # GDD §24
## Maximum spawn distance from the player (px).
const SPAWN_MAX: float = 80.0  # GDD §24
## Spawn-point attempts per frame before giving up (timer is NOT consumed).
const SPAWN_RETRIES: int = 6  # TUNING (not in GDD)
## Duration of the "rise from the grave" emergence animation (s).
const SPAWN_DURATION: float = 0.5  # TUNING (not in GDD)
## RETURNING -> FOLLOWING once within band_max + this margin of the player.
const RETURN_ARRIVE_MARGIN: float = 30.0  # TUNING (not in GDD)

# --- Update rates (GDD §25) -----------------------------------------------------

## AI decisions run every Nth physics tick: 60 Hz / 12 = 5 Hz, and units are
## spread round-robin over the 12 slots so work never spikes on one frame.
const AI_TICK_DIVISOR: int = 12  # GDD §25 (5 Hz)
## Formation anchors recomputed every Nth physics tick: 60 / 15 = 4 Hz.
const FORMATION_TICK_DIVISOR: int = 15  # GDD §25 (4 Hz)
## Player threat evaluation every Nth physics tick: 60 / 12 = 5 Hz.
const THREAT_TICK_DIVISOR: int = 12  # GDD §25 (5 Hz)

# --- Targeting (GDD §27–§31) -------------------------------------------------

## Minimum time (s) a unit keeps a valid target before reconsidering.
const TARGET_COMMIT_TIME: float = 1.0  # GDD §27
## Score margin a new target must beat the current one by to cause an early
## switch ("significantly greater threat").
const SWITCH_MARGIN: float = 0.35  # TUNING (not in GDD)
## Distance (px) used to normalise "threat to player" (0 at this distance).
const THREAT_NORM_DISTANCE: float = 200.0  # TUNING (not in GDD)
## Warriors intercept enemies within this distance of the player when the
## player is in danger, ignoring farther targets.
const WARRIOR_INTERCEPT_RADIUS: float = 80.0  # GDD §28
## Mages evaluate at most this many candidate impact points per decision.
const MAGE_MAX_CANDIDATES: int = 16  # TUNING (not in GDD)
## Enemy count inside a splash that counts as a "full" cluster (score 1.0).
const MAGE_CLUSTER_NORM: float = 6.0  # TUNING (not in GDD)
## Extra edge tolerance (px) for a melee swing to still connect after windup.
const MELEE_TOLERANCE: float = 10.0  # TUNING (not in GDD)
## How long (s) an archer kites before firing again.
const KITE_DURATION: float = 0.5  # TUNING (not in GDD)
## Cooldown (s) between kites so archers "otherwise keep firing" (GDD §29).
const KITE_COOLDOWN: float = 1.2  # TUNING (not in GDD)

## Priest heal score weights (GDD §31):
## 0.6*missing_fraction + 0.2*normalised_missing_raw + 0.2*role_priority.
const HEAL_W_MISSING_FRACTION: float = 0.6  # GDD §31
## Weight of normalised raw missing HP.
const HEAL_W_MISSING_RAW: float = 0.2  # GDD §31
## Weight of tactical role priority.
const HEAL_W_ROLE: float = 0.2  # GDD §31
## Raw missing HP that normalises to 1.0.
const HEAL_MISSING_RAW_NORM: float = 60.0  # TUNING (not in GDD)
## Allies under this HP fraction are "critical" (GDD §27: below 35% HP).
const HEAL_CRITICAL_FRACTION: float = 0.35  # GDD §27
## Extra score for critical allies so they always win over chip damage.
const HEAL_CRITICAL_BONUS: float = 0.5  # TUNING (not in GDD)
## Tactical role priority of the necromancer as a heal target (priests may
## always heal the player, per the user brief overriding GDD §27's "if skill
## allows").
const PLAYER_HEAL_ROLE: float = 1.0  # TUNING (not in GDD)
## Extra score when the necromancer is critical (< HEAL_CRITICAL_FRACTION) so
## a critical necromancer has top priority (GDD §31).
const PLAYER_CRITICAL_BONUS: float = 1.0  # TUNING (not in GDD)
## Priests consider a ward when the player was hit within this many seconds
## (or is flagged "in danger").
const SHIELD_TRIGGER_WINDOW: float = 1.5  # TUNING (not in GDD)
## Max radius (px) of any blocker, used to size enemy-vs-blocker queries.
const MAX_BLOCK_RADIUS: float = 16.0  # TUNING (not in GDD)

# --- Coordination / steering ----------------------------------------------------

## Radius (px) around the player scanned for threats.
const THREAT_RADIUS: float = 160.0  # TUNING (not in GDD)
## Radius (px) in which enemies count as "immediate melee" danger.
const DANGER_RADIUS: float = 80.0  # TUNING (not in GDD)
## Enemies inside DANGER_RADIUS that flag the player as "in danger".
const DANGER_COUNT: int = 4  # TUNING (not in GDD)
## Player HP fraction under which the player is always "in danger".
const DANGER_HP_FRACTION: float = 0.35  # TUNING (not in GDD)
## Max random angular offset (radians) per unit slot (non-rigid formation).
const FORMATION_JITTER_ANGLE: float = 0.35  # TUNING (not in GDD)
## Speed multiplier while FOLLOWING but far (> CATCHUP_DISTANCE) from anchor.
const CATCHUP_SPEED_MULT: float = 1.35  # TUNING (not in GDD)
## Distance (px) from anchor at which catch-up speed kicks in.
const CATCHUP_DISTANCE: float = 60.0  # TUNING (not in GDD)
## Speed multiplier while RETURNING to the army.
const RETURN_SPEED_MULT: float = 1.5  # TUNING (not in GDD)
## Steering acceleration as a multiple of move speed per second.
const STEER_ACCEL: float = 8.0  # TUNING (not in GDD)
## Extra spacing (px) kept between allies on top of their radii.
const SEPARATION_PADDING: float = 4.0  # TUNING (not in GDD)
## Radius (px) scanned for threats to avoid (priests / archers / mages).
const THREAT_AVOID_RADIUS: float = 55.0  # TUNING (not in GDD)
