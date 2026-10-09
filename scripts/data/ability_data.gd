## AbilityData — immutable design data for the three shadow spells (GDD §8):
## Shadow Bolt (starting spell), Shadow Orb Shield and Shadow Blast. Each spell
## has five levels (GDD §6). Each level row holds the ABSOLUTE stats at that
## level, so designers read a level without summing increments, and level-up
## cards can show exact "old -> new" values by diffing two rows.
##
## The GDD lists which stats each spell upgrades but no values, so all numbers
## are TUNING (not in GDD).
class_name AbilityData
extends RefCounted

## Spell the run starts with (GDD §3 "Begin run with a single starting skill").
const STARTING_SPELL: String = "shadow_bolt"

## Display / card order of spells.
const SPELL_ORDER := ["shadow_bolt", "orb_shield", "shadow_blast"]

## Spell definitions.
##   display_name — UI name.
##   icon         — IconGlyph kind.
##   description  — short card text (GDD §8 wording).
##   labels       — stat key -> UI label, in display order. Only these keys
##                  are listed on cards.
##   levels       — 5 rows of absolute stats.
##
## Shadow Bolt stat keys:
##   damage (per bolt), cooldown (s), count (bolts per cast), pierce (extra
##   enemies passed through), speed (px/s), range (px search radius).
## Orb Shield stat keys:
##   orbs (count), damage (per touch), orbit_radius (px), orbit_speed (rad/s),
##   hit_cooldown (s between touches on the same enemy), recharge (s before a
##   spent orb can intercept another projectile; GDD §8 "charge-limited").
## Shadow Blast stat keys:
##   damage, radius (px), cooldown (s), slow (fraction of speed removed),
##   slow_duration (s).
const SPELLS := {
	"shadow_bolt": {
		"display_name": "Shadow Bolt",
		"icon": "shadow_bolt",
		"description": "Automatically fires shadow bolts at nearby enemies.",
		"labels": {"damage": "Damage", "count": "Bolts", "cooldown": "Cooldown (s)", "pierce": "Pierce", "speed": "Speed"},
		"levels": [
			{"damage": 15.0, "cooldown": 1.0, "count": 1, "pierce": 0, "speed": 380.0, "range": 380.0},  # TUNING (not in GDD)
			{"damage": 20.0, "cooldown": 1.0, "count": 1, "pierce": 0, "speed": 380.0, "range": 380.0},  # TUNING (not in GDD)
			{"damage": 20.0, "cooldown": 1.0, "count": 2, "pierce": 0, "speed": 380.0, "range": 380.0},  # TUNING (not in GDD)
			{"damage": 20.0, "cooldown": 0.9, "count": 2, "pierce": 1, "speed": 440.0, "range": 400.0},  # TUNING (not in GDD)
			{"damage": 26.0, "cooldown": 0.8, "count": 3, "pierce": 1, "speed": 440.0, "range": 420.0},  # TUNING (not in GDD)
		],
	},
	"orb_shield": {
		"display_name": "Shadow Orb Shield",
		"icon": "orb_shield",
		"description": "Orbs circle you, damaging enemies and intercepting a limited number of projectiles.",
		"labels": {"orbs": "Orbs", "damage": "Damage", "orbit_radius": "Orbit radius", "orbit_speed": "Orbit speed", "recharge": "Intercept recharge (s)"},
		"levels": [
			{"orbs": 2, "damage": 8.0, "orbit_radius": 52.0, "orbit_speed": 2.6, "hit_cooldown": 0.5, "recharge": 5.0},  # TUNING (not in GDD)
			{"orbs": 3, "damage": 8.0, "orbit_radius": 52.0, "orbit_speed": 2.6, "hit_cooldown": 0.5, "recharge": 5.0},  # TUNING (not in GDD)
			{"orbs": 3, "damage": 12.0, "orbit_radius": 60.0, "orbit_speed": 2.6, "hit_cooldown": 0.5, "recharge": 5.0},  # TUNING (not in GDD)
			{"orbs": 4, "damage": 12.0, "orbit_radius": 60.0, "orbit_speed": 2.6, "hit_cooldown": 0.5, "recharge": 3.5},  # TUNING (not in GDD)
			{"orbs": 5, "damage": 16.0, "orbit_radius": 64.0, "orbit_speed": 3.4, "hit_cooldown": 0.5, "recharge": 3.5},  # TUNING (not in GDD)
		],
	},
	"shadow_blast": {
		"display_name": "Shadow Blast",
		"icon": "shadow_blast",
		"description": "Periodically detonates shadow around you, damaging and slowing nearby foes.",
		"labels": {"damage": "Damage", "radius": "Radius", "cooldown": "Cooldown (s)", "slow": "Slow", "slow_duration": "Slow duration (s)"},
		"levels": [
			{"damage": 22.0, "radius": 80.0, "cooldown": 4.0, "slow": 0.3, "slow_duration": 1.0},  # TUNING (not in GDD)
			{"damage": 30.0, "radius": 80.0, "cooldown": 4.0, "slow": 0.3, "slow_duration": 1.0},  # TUNING (not in GDD)
			{"damage": 30.0, "radius": 105.0, "cooldown": 4.0, "slow": 0.3, "slow_duration": 1.0},  # TUNING (not in GDD)
			{"damage": 30.0, "radius": 105.0, "cooldown": 3.0, "slow": 0.45, "slow_duration": 1.0},  # TUNING (not in GDD)
			{"damage": 42.0, "radius": 125.0, "cooldown": 3.0, "slow": 0.45, "slow_duration": 1.5},  # TUNING (not in GDD)
		],
	},
}

## Shadow Bolt: score bonus (px-equivalent) for enemies currently attacking a
## summon, so bolts "preferentially hit enemies threatening warriors" (GDD §33).
const BOLT_PROTECT_BONUS: float = 80.0  # TUNING (not in GDD)
## Shadow Bolt homing turn rate (radians/s) toward its target.
const BOLT_HOMING: float = 5.0  # TUNING (not in GDD)
## Radius (px) of a single orb's body / hit circle.
const ORB_RADIUS: float = 7.0  # TUNING (not in GDD)
