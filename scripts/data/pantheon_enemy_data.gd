## PantheonEnemyData — immutable design data for the kinds the OLYMPIAN
## REPUBLIC fields on every Act IV stage (GDD §15.0 "Act IV foundation (phase
## 1)"; owner-approved proposal docs/act4/PROPOSAL.md "Act IV: The Olympian
## Republic"). Greek gods command Roman discipline: bronze hoplites in shield
## walls, demigod heroes leading them, the pale dead fleeing the Underworld. The
## shared kinds of phase 1:
##   shade_of_dead — Shade of the Dead: fodder; pale, fast, weak ghosts in
##                   swarms. FODDER (Poseidon's waves drown it).
##   hoplite       — Hoplite: soldier; spear and round shield. PHALANX (three or
##                   more shoulder to shoulder lock shields) and BRONZE (Zeus's
##                   lightning chains to it).
##   hero          — Hero: elite; a strong melee demigod. HERO (Glory: every
##                   summon it kills makes it stronger) and BRONZE. Named
##                   variants (Ajax, Hector, Atalanta) as display names.
##   bronze_titan  — Bronze Titan: the Twilight of the Gods' Reckoning kind
##                   (stages name it as their RECKONING "kind"): a slow, huge
##                   bronze colossus stepping out of the ground. BRONZE.
## Each stage's own kinds live in its own file (IlionEnemyData,
## OlympusEnemyData, UnderworldEnemyData; empty until phase 2);
## EnemyDirector.enemy_def() looks them up through pantheon_def(), this file
## first, after the Electronic Empire's tables.
##
## Rows have every key of an EnemyData.ENEMIES row (same meaning) plus the
## optional Pantheon keys (absent = off):
##   faction  — "pantheon" (the Codex's Olympian Republic tab, the reports).
##   kit      — a CovenantKit id; a Pantheon kit lives in
##              scripts/enemies/pantheon/<kit>_kit.gd (CovenantKits loads it by
##              name, after the Eye's and the Empire's folders, so kit ids must
##              be unique across the three folders). Every Pantheon kind has
##              one (a PantheonKit): it carries the facing the Phalanx reads.
##   bronze   — true: bronze-clad; a Wrath of the Gods lightning strike chains
##              to it (DivineWrath, PantheonRulesData.WRATH lightning).
##   phalanx  — true: can lock shields with its neighbours (Phalanx,
##              PantheonRulesData.PHALANX).
##   hero     — true: carries Glory (Glory, PantheonRulesData.GLORY): a stack
##              per summon it kills, paid out when it dies.
##   fodder   — true: fodder; Poseidon's wave drowns it outright.
##   names    — hero only: display names handed out in turn (named variants).
##   floating — true: drawn hovering, never carried by the ground (TerrainSlow).
##   rises    — true: steps out of the ground when it spawns (the Titans).
## The facing (the way the shield points) is the kit's, not a row key.
## The GDD gives no numbers: everything is TUNING (not in GDD).
class_name PantheonEnemyData
extends RefCounted

## Faction id of the Olympian Republic's kinds (row "faction").
const FACTION: String = "pantheon"
## Kind id of the shared fodder (DivineWrath's fissures spit it).
const SHADE: String = "shade_of_dead"
## Kind id of the shared shield soldier.
const HOPLITE: String = "hoplite"
## Kind id of the shared Glory elite.
const HERO: String = "hero"
## Kind id of the Twilight of the Gods' Reckoning kind (stages' RECKONING "kind").
const BRONZE_TITAN: String = "bronze_titan"

## The Olympian Republic's shared kinds, keyed by kind id.
const ENEMIES := {
	# Fodder: a pale, wispy ghost of a Greek dead soul fleeing the Underworld.
	# Weak and fast, in swarms; glides.
	"shade_of_dead": {
		"display_name": "Shade of the Dead",
		"max_hp": 9.0,  # TUNING (not in GDD) frail fodder (Recruit 14, Scout Drone 10)
		"move_speed": 86.0,  # TUNING (not in GDD) px/s; fast (Recruit 58)
		"damage": 2.0,  # TUNING (not in GDD) a cold touch, before the time scaling
		"attack_interval": 1.0,  # TUNING (not in GDD) s
		"attack_range": 4.0,  # TUNING (not in GDD) px, melee
		"radius": 7.0,  # TUNING (not in GDD) px
		"armor": 0.0,  # TUNING (not in GDD)
		"xp": 1,  # TUNING (not in GDD)
		"behavior": "melee",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.2,  # TUNING (not in GDD) 0..1, fodder
		"mass": 0.5,  # TUNING (not in GDD) light: warriors hold it easily
		"faction": FACTION,
		"kit": "shade",
		"fodder": true,  # Poseidon's waves drown it.
		"floating": true,  # Glides, drawn hovering.
	},
	# Soldier: bronze Corinthian helmet with a crest, a big round bronze shield
	# held forward, a spear. Locks shields with its neighbours (the Phalanx).
	"hoplite": {
		"display_name": "Hoplite",
		"max_hp": 34.0,  # TUNING (not in GDD) a soldier (Footman 36)
		"move_speed": 42.0,  # TUNING (not in GDD) px/s; a steady march
		"damage": 4.5,  # TUNING (not in GDD) a spear thrust, before the time scaling
		"attack_interval": 1.3,  # TUNING (not in GDD) s
		"attack_range": 12.0,  # TUNING (not in GDD) px; the spear outreaches a sword
		"radius": 10.0,  # TUNING (not in GDD) px
		"armor": 0.2,  # TUNING (not in GDD) bronze
		"xp": 2,  # TUNING (not in GDD)
		"behavior": "melee",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.4,  # TUNING (not in GDD) 0..1
		"mass": 1.4,  # TUNING (not in GDD) a braced shield wall is hard to shove
		"faction": FACTION,
		"kit": "hoplite",
		"phalanx": true,  # Locks shields (Phalanx).
		"bronze": true,  # Draws Zeus's lightning.
	},
	# Elite: a demigod champion in bronze and gold, an Aegean-blue cloak, a
	# plumed helmet. Gains Glory from every summon it kills.
	"hero": {
		"display_name": "Hero",
		"max_hp": 280.0,  # TUNING (not in GDD) an elite (Spotter 110, Siren 120): a demigod
		"move_speed": 54.0,  # TUNING (not in GDD) px/s
		"damage": 12.0,  # TUNING (not in GDD) per blow, before the time scaling and Glory
		"attack_interval": 1.1,  # TUNING (not in GDD) s
		"attack_range": 10.0,  # TUNING (not in GDD) px
		"radius": 12.0,  # TUNING (not in GDD) px (Glory grows it)
		"armor": 0.25,  # TUNING (not in GDD)
		"xp": 18,  # TUNING (not in GDD) an elite's XP
		"behavior": "melee",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.9,  # TUNING (not in GDD) 0..1; kill it early (Glory)
		"mass": 2.2,  # TUNING (not in GDD)
		"faction": FACTION,
		"kit": "hero",
		"always_elite": true,  # Owner-approved proposal: tier Elite
		"hero": true,  # Carries Glory.
		"bronze": true,  # Draws Zeus's lightning.
		"names": ["Ajax", "Hector", "Atalanta"],  # Owner-approved proposal: the named variants
	},
	# The Twilight of the Gods' Titan (Reckoning kind): a huge walking bronze
	# colossus of marble and bronze with glowing eyes, stepping out of the ground.
	"bronze_titan": {
		"display_name": "Bronze Titan",
		"max_hp": 520.0,  # TUNING (not in GDD) before the Reckoning's own growth (Kill-Drone 60, a heavy)
		"move_speed": 34.0,  # TUNING (not in GDD) px/s; slow
		"damage": 20.0,  # TUNING (not in GDD) per blow, before the Reckoning's growth
		"attack_interval": 1.6,  # TUNING (not in GDD) s
		"attack_range": 14.0,  # TUNING (not in GDD) px
		"radius": 22.0,  # TUNING (not in GDD) px; huge
		"armor": 0.3,  # TUNING (not in GDD)
		"xp": 4,  # TUNING (not in GDD)
		"behavior": "melee",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.5,  # TUNING (not in GDD)
		"mass": 6.0,  # TUNING (not in GDD) a colossus: blockers barely slow it
		"faction": FACTION,
		"kit": "titan",
		"bronze": true,  # Draws Zeus's lightning.
		"rises": true,  # Steps out of the ground.
	},
}
