## LibertyHeightsEnemyData — immutable design data for the City kinds that join on
## Liberty Heights (Stage 24) (Act VIII, the Last Line; GDD §15.0 "Act VIII foundation (phase
## 1)" and "Liberty Heights (Act VIII phase 2)"; owner-approved proposal
## docs/act8/PROPOSAL.md). The stage's three new Supers (Atlas, Aurora,
## Nightjar) are rows of the shared CityEnemyData (any stage may use them);
## this table holds what only Liberty Heights fields:
##   conscript — army tier fodder (male): young Guardsmen in olive with
##               bayoneted rifles held as spears, in crowds. The stage starts
##               at the army (the escalation's "army" at 0:00, the proposal's
##               "starts at 4 stars") and its timeline spawns only its tiers'
##               kinds (the brief), so the army brings its own fodder beside
##               the rifle squads and the tanks (own decision).
## EnemyDirector.city_def() looks these rows up after CityEnemyData. Rows have
## every key of a CityEnemyData.ENEMIES row (same meaning; "kit" ids load
## scripts/enemies/city/<kit>_kit.gd, unique across the Eye, Empire, Pantheon,
## Shogunate, Inferno, Court and City folders; "tier", "armour_front",
## "vehicle", "super" and "civilian" switch the shared rules on for the kind).
## The GDD gives no numbers: everything is TUNING (not in GDD).
class_name LibertyHeightsEnemyData
extends RefCounted

## Kind id of the army's fodder on Liberty Heights.
const CONSCRIPT: String = "conscript"

## Kind id -> design row.
const ENEMIES := {
	# Army, fodder (male): bayonets in crowds; the shared melee blow.
	"conscript": {
		"display_name": "Conscript",
		"max_hp": 22.0,  # TUNING (not in GDD) fodder a step above the street thug (16)
		"move_speed": 50.0,  # TUNING (not in GDD) px/s
		"damage": 3.5,  # TUNING (not in GDD) a bayonet thrust, before the time scaling
		"attack_interval": 1.0,  # TUNING (not in GDD) s
		"attack_range": 8.0,  # TUNING (not in GDD) px (the bayonet's reach)
		"radius": 9.0,  # TUNING (not in GDD) px
		"armor": 0.05,  # TUNING (not in GDD) a helmet
		"xp": 1,  # TUNING (not in GDD)
		"behavior": "melee",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.2,  # TUNING (not in GDD) 0..1, fodder
		"mass": 1.0,  # TUNING (not in GDD)
		"faction": CityEnemyData.FACTION,
		"kit": "conscript",
		"tier": "army",  # The army's fodder
		"fodder": true,
	},  # The conscript.
}
