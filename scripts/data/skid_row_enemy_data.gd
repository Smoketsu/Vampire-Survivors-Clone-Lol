## SkidRowEnemyData — immutable design data for the City kinds that join on
## Skid Row (Stage 22) (Act VIII, the Last Line; GDD §15.0 "Act VIII foundation
## (phase 1)" and "Skid Row (Act VIII phase 2)"; owner-approved proposal
## docs/act8/PROPOSAL.md "Stage 22: Skid Row"). Skid Row adds no roster kind
## (it stops at SWAT, brief); its own kinds are its miniboss and its boss's
## board:
##   armoured_limo — BIG SAL'S ARMOURED LIMO (the miniboss's first form): a
##                   VEHICLE (Convoy: the drive, the run-over, the wreck) with
##                   an armoured front (Armour) whose crew sprays gang-gunner
##                   pistols out of both side windows while it drives; Big Sal
##                   rides inside (one body). It holds the HUD's miniboss bar.
##   big_sal       — BIG SAL (male), the enforcer who climbs out of the limo's
##                   wreck for a short melee finish: the stage MINIBOSS (the
##                   miniboss chest, the XP burst).
##   bounty_board  — DON MARROW'S BOUNTY BOARD (a structure, a priority
##                   target): while it stands, the gangs come twice as thick.
## EnemyDirector.city_def() looks these rows up after CityEnemyData. Rows have
## every key of a CityEnemyData.ENEMIES row (same meaning; "kit" ids load
## scripts/enemies/city/<kit>_kit.gd, unique across the Eye, Empire, Pantheon,
## Shogunate, Inferno, Court and City folders; "tier", "armour_front",
## "vehicle", "super" and "civilian" switch the shared rules on for the kind).
## The GDD gives no numbers: everything is TUNING (not in GDD).
class_name SkidRowEnemyData
extends RefCounted

## Kind id of Big Sal's Armoured Limo.
const LIMO: String = "armoured_limo"
## Kind id of Big Sal on foot (the miniboss).
const BIG_SAL: String = "big_sal"
## Kind id of Don Marrow's bounty board.
const BOUNTY_BOARD: String = "bounty_board"
## Damage tag of the limo crew's pistol sprays (a ranged City source: Kevlar
## Bones; CityEnemyData.RANGED_SOURCES).
const LIMO_SPRAY_SOURCE: String = "limo_spray"
## Damage tag of Big Sal's sledgehammer swing.
const SAL_SWING_SOURCE: String = "big_sal_swing"

## Kind id -> design row.
const ENEMIES := {
	# The miniboss's first form: BIG SAL'S ARMOURED LIMO (owner-approved
	# proposal: "an enforcer who rams the ring while his crew shoots from the
	# windows"). A VEHICLE (Convoy: it drives the street lanes, runs over what
	# is in its body box, rams wrecks, leaves a burning wreck) with an ARMOURED
	# FRONT (armour_front: a hit inside its front arc is cut). Its CREW fires
	# out of both side windows while it drives: every crew_every s, for each
	# side with a target (a summon or a necromancer) within crew_range px of
	# that side, a spray of crew_spray bullets (crew_spread rad) out of that
	# side's window, tagged limo_spray. Big Sal rides inside (one body); the
	# limo holds the HUD's miniboss bar; when it dies its wreck burns and Big
	# Sal climbs out (SkidRowDirector).
	"armoured_limo": {
		"display_name": "Big Sal's Armoured Limo",
		"max_hp": 1200.0,  # TUNING (not in GDD) a miniboss's body (Blitz 1300; the tank 700); first pass 1500 (the seed-2 army bot took 5:30 to wreck it)
		"move_speed": 120.0,  # TUNING (not in GDD) px/s; heavy for a car (the squad car 150)
		"damage": 0.0,  # Unused: run_damage and the crew.
		"attack_interval": 1.0,
		"attack_range": 0.0,
		"radius": 20.0,  # TUNING (not in GDD) px (targeting body; the run-over box is half_length x half_width; within MAX_BODY_RADIUS 36)
		"armor": 0.25,  # TUNING (not in GDD) armoured doors
		"xp": 30,  # TUNING (not in GDD)
		"behavior": "melee",  # Unused: its kit drives it.
		"projectile_speed": 300.0,  # TUNING (not in GDD) px/s, the crew's pistols
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.85,  # TUNING (not in GDD) 0..1; the miniboss
		"mass": 60.0,  # TUNING (not in GDD) an armoured car
		"slow_resist": 0.6,  # TUNING (not in GDD) like a miniboss
		"faction": CityEnemyData.FACTION,
		"kit": "armoured_limo",
		"tier": "gangs",  # The gangs' enforcer (the report and the Codex list him there).
		"vehicle": true,  # Owner-approved proposal: "rams the ring" (Armour, Convoy)
		"armour_front": 0.5,  # TUNING (not in GDD) the armoured grille and windscreen cut half of a hit from the front
		"half_length": 36.0,  # TUNING (not in GDD) px (~80 px sprite); the wreck is clamped to WRECK_HALF_MAX
		"half_width": 15.0,  # TUNING (not in GDD) px
		"run_damage": 7.0,  # TUNING (not in GDD) before the time scaling (the squad car 5, the tank 9)
		"ram_damage": 0.05,  # TUNING (not in GDD) share of its max HP a wreck ram costs it (CONVOY's 0.15 for every other vehicle): its plated grille. Without it the seed-7 and seed-1 limos rammed themselves to death on wrecks in ~35 s without firing a shot
		"crew_every": 1.6,  # TUNING (not in GDD) s between two volleys from the windows
		"crew_range": 210.0,  # TUNING (not in GDD) px from its side a target must be
		"crew_spray": 4,  # TUNING (not in GDD) bullets a side (the gang gunner's 4)
		"crew_spread": 0.45,  # TUNING (not in GDD) rad each side (poor aim, many bullets)
		"crew_damage": 1.4,  # TUNING (not in GDD) per bullet, before the time scaling (the gang gunner's 1.4)
	},  # Big Sal's Armoured Limo.
	# The stage MINIBOSS: BIG SAL (male), the enforcer who climbs out of the
	# wreck for "a short melee finish". A huge man in a pinstripe suit with a
	# sledgehammer. Every swing_every s, with a summon or the necromancer within
	# swing_reach px, he winds up swing_windup s (a telegraphed arc of
	# swing_half_angle rad each side) and swings: every summon and necromancer
	# in the arc takes swing_damage and is knocked swing_push px back. Beyond
	# advance_range px he strides advance_speed_mult faster. Killed, he drops an
	# XP burst (reward_xp in reward_crystals) and the miniboss chest.
	"big_sal": {
		"display_name": "Big Sal",
		"max_hp": 760.0,  # TUNING (not in GDD) a short finish (Old Greymane 1500)
		"move_speed": 56.0,  # TUNING (not in GDD) px/s
		"damage": 9.0,  # TUNING (not in GDD) a jab of the hammer's head in reach
		"attack_interval": 1.2,  # TUNING (not in GDD) s
		"attack_range": 10.0,  # TUNING (not in GDD) px
		"radius": 15.0,  # TUNING (not in GDD) px (as an elite x1.3 = 19.5, within MAX_BODY_RADIUS 36)
		"armor": 0.15,  # TUNING (not in GDD) a heavy coat
		"xp": 0,  # His XP is the burst.
		"behavior": "melee",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.9,  # TUNING (not in GDD) 0..1; the enforcer first
		"mass": 8.0,  # TUNING (not in GDD)
		"slow_resist": 0.6,  # TUNING (not in GDD) like a boss
		"always_elite": true,  # Counts as an elite for Soul Nova, Dread Rally and Soul Ash
		"miniboss": true,  # The miniboss flag (Enemy.is_miniboss: the HUD bar, the chest, boss multipliers).
		"faction": CityEnemyData.FACTION,
		"kit": "big_sal",
		"tier": "gangs",  # The gangs' enforcer.
		"swing_every": 4.5,  # TUNING (not in GDD) s
		"swing_reach": 58.0,  # TUNING (not in GDD) px from his edge
		"swing_windup": 0.6,  # TUNING (not in GDD) s
		"swing_half_angle": 1.0,  # TUNING (not in GDD) rad each side (~57 degrees)
		"swing_damage": 12.0,  # TUNING (not in GDD) before the time scaling
		"swing_push": 40.0,  # TUNING (not in GDD) px the summons are knocked back
		"advance_range": 380.0,  # TUNING (not in GDD) px
		"advance_speed_mult": 1.6,  # TUNING (not in GDD)
		"reward_xp": 220,  # TUNING (not in GDD) as Old Greymane
		"reward_crystals": 10,  # TUNING (not in GDD)
	},  # Big Sal.
	# Structure: DON MARROW'S BOUNTY BOARD (owner-approved proposal: "he puts a
	# price on the necromancer's head: gang spawns double while his bounty board
	# is up; break the board to end it"). A billboard of wanted posters on legs,
	# raised by BossDonMarrow; a priority target (summons go for it first) that
	# is never recycled. While it stands SkidRowDirector.bounty_active() is
	# true. Its HP before the time / stage scaling.
	"bounty_board": {
		"display_name": "Bounty Board",
		"max_hp": 320.0,  # TUNING (not in GDD) a ring breaks it in a few seconds (the sleeping coffin 140)
		"move_speed": 0.0,
		"damage": 0.0,
		"attack_interval": 1.0,
		"attack_range": 0.0,
		"radius": 18.0,  # TUNING (not in GDD) px
		"armor": 0.0,
		"xp": 10,  # TUNING (not in GDD)
		"behavior": "structure",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 1.0,  # Owner-approved proposal: a priority target ("break the board")
		"mass": 60.0,  # Immovable.
		"is_structure": true,
		"faction": CityEnemyData.FACTION,
		"kit": "bounty_board",
		"tier": "gangs",  # The gangs' price on your head.
	},  # The bounty board.
}
