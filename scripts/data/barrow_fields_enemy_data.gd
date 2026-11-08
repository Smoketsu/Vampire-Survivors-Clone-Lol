## BarrowFieldsEnemyData — immutable design data for the Norse kinds that join
## on the Barrow Fields (Stage 16 in the final order; the Hall of the Slain,
## temporarily Act XI, final slot VI; GDD §15.0 "The Barrow Fields (the Hall of
## the Slain phase 2)"; the act's section "Stage 16: The Barrow Fields" of
## docs/proposals/LAST_SIX_ACTS.md and docs/norse/BRIEF_PHASE2.md "Agent A").
## EnemyDirector.norse_def() looks these rows up after NorseEnemyData. Rows have
## every key of a NorseEnemyData.ENEMIES row (same meaning; "kit" ids load
## scripts/enemies/norse/<kit>_kit.gd, unique across every kit folder;
## "warrior" puts a kind under Berserkergang; "douses" makes it put out the
## Long Winter's braziers). The stage's own kinds:
##   draugr_female — the barrow-dead women (the proposal: "Draugr (male and
##                   female)"): the shared draugr's numbers and kit, her own
##                   sprite (norse/draugr_female).
##   open_barrow   — THE OPEN BARROWS (the brief: "mounds that crack open on a
##                   2 s telegraph and let draugr out until the mound is
##                   broken"): a structure (OpenBarrowKit) placed by
##                   BarrowFieldsDirector and by Hrimgar's Grave.
##   barrow_wight  — the miniboss, THE BARROW-WIGHT (the brief: "a draugr
##                   chieftain whose howl stuns the ring for 1 s"):
##                   BarrowWightKit.
##   hrimgar_barrow — Hrimgar's own barrow (BossHrimgar: he sinks into it when
##                   he falls; breaking it while he is down ends him for good).
## The GDD gives no numbers: everything is TUNING (not in GDD) unless marked as
## the owner-approved proposal or the brief.
class_name BarrowFieldsEnemyData
extends RefCounted

## Kind id of an open barrow (BarrowFieldsDirector, BossHrimgar).
const OPEN_BARROW: String = "open_barrow"
## Kind id of the miniboss.
const WIGHT: String = "barrow_wight"
## Kind id of the female draugr.
const DRAUGR_FEMALE: String = "draugr_female"
## Kind id of Hrimgar's barrow.
const HRIMGAR_BARROW: String = "hrimgar_barrow"
## Damage tag of the Barrow-Wight's howl (a stun, no damage; the stats).
const HOWL_SOURCE: String = "wight_howl"

## Kind id -> design row.
const ENEMIES := {
	# --- Act XI (temporary): the Barrow Fields ---
	# The barrow-dead woman (owner-approved proposal: "Draugr (male and
	# female) | Soldier | Barrow-dead in rusted mail; armour 3; a cold touch
	# that slows a summon"). The shared draugr's numbers (NorseEnemyData
	# "draugr"), her own sprite norse/draugr_female (a plain walk, no bust rig:
	# owner's art round 2). DraugrKit (the cold touch is NorseRules
	# .on_unit_struck(), read from the row's chill_slow / chill_time).
	"draugr_female": {
		"display_name": "Draugr",
		"max_hp": 40.0,  # As the draugr (NorseEnemyData)
		"move_speed": 44.0,  # TUNING (not in GDD) px/s; a hair lighter than the male draugr's 42
		"damage": 4.5,  # As the draugr, before the time scaling
		"attack_interval": 1.3,  # As the draugr (s)
		"attack_range": 8.0,  # As the draugr (px)
		"radius": 9.0,  # As the draugr (px)
		"armor": 0.0,
		"flat_armor": 3.0,  # Owner-approved proposal: "armour 3"
		"xp": 3,  # As the draugr
		"behavior": "melee",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.45,  # As the draugr (0..1)
		"mass": 1.3,  # As the draugr
		"faction": NorseEnemyData.FACTION,
		"kit": "draugr",
		"group": "wilds",
		"chill_slow": 0.35,  # As the draugr: share of the struck summon's speed lost
		"chill_time": 2.0,  # As the draugr (s)
	},  # The female draugr.
	# THE OPEN BARROW (the brief: "mounds that crack open on a 2 s telegraph and
	# let draugr out until the mound is broken"). A burial mound on the snow:
	# for crack_time s it CRACKS (a ring of frost shows, the closed sprite
	# shakes; it can already be struck), then it stands OPEN (ice-blue glow)
	# and lets a draugr out every release_every s (alternating male and female)
	# at its mouth, while fewer than release_max of its own walk and the field
	# is under the hard cap, until it is broken. It never moves or attacks;
	# broken, it pays its xp. OpenBarrowKit.
	"open_barrow": {
		"display_name": "Open Barrow",
		"max_hp": 220.0,  # TUNING (not in GDD) a few seconds of the ring's blows (a landing pod 150)
		"move_speed": 0.0,
		"damage": 0.0,  # It never attacks.
		"attack_interval": 1.0,
		"attack_range": 0.0,
		"radius": 20.0,  # TUNING (not in GDD) px (the 48 x 38 barrow sprite)
		"armor": 0.15,  # TUNING (not in GDD) stone and frozen earth
		"xp": 10,  # TUNING (not in GDD)
		"behavior": "structure",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.7,  # TUNING (not in GDD) 0..1; break the barrows
		"mass": 60.0,  # Immovable.
		"is_structure": true,  # No corpse, no knockback.
		"faction": NorseEnemyData.FACTION,
		"kit": "open_barrow",
		"group": "wilds",  # The barrow-dead's mound (the report lists it with the draugr).
		"crack_time": 2.0,  # Brief: "crack open on a 2 s telegraph"
		"release_every": 5.0,  # TUNING (not in GDD) s between two draugr let out
		"release_max": 3,  # TUNING (not in GDD) its own draugr walking at once
		"release_kinds": ["draugr", "draugr_female"],  # Owner-approved proposal: "Draugr (male and female)", in turn
		"release_dist": 26.0,  # TUNING (not in GDD) px from its centre a draugr climbs out
	},  # The open barrow.
	# THE BARROW-WIGHT, the stage miniboss (the brief: "a draugr chieftain whose
	# howl stuns the ring for 1 s"). A towering male draugr chieftain in a
	# rusted crown and a torn mail coat, a notched sword, ice-blue eyes. He walks
	# in with the shared melee AI and cuts in reach; every howl_every s he
	# throws back his head for howl_windup s (a frost ring grows: the telegraph)
	# and HOWLS: every summon within howl_radius px is stunned howl_stun s
	# (CombatResolver.stun_unit(), THE one summon stun path) and the necromancer
	# in reach is slowed howl_slow for howl_slow_time s (TerrainSlow, a world
	# cold). Each howl also cracks open howl_barrows barrows near the ring.
	# Already dead: no warrior of the hall (never berserk). Killed, he drops an
	# XP burst and the miniboss chest. BarrowWightKit.
	"barrow_wight": {
		"display_name": "Barrow-Wight",
		"max_hp": 1500.0,  # TUNING (not in GDD) a miniboss (the Brood Matriarch 1300, Old Greymane 1500)
		"move_speed": 46.0,  # TUNING (not in GDD) px/s; slow and dreadful
		"damage": 10.0,  # TUNING (not in GDD) his notched sword in reach, before the time scaling
		"attack_interval": 1.3,  # TUNING (not in GDD) s
		"attack_range": 12.0,  # TUNING (not in GDD) px
		"radius": 18.0,  # TUNING (not in GDD) px (~56 px sprite)
		"armor": 0.0,
		"flat_armor": 5.0,  # TUNING (not in GDD) the draugr's armour 3, a chieftain's mail
		"xp": 0,  # His XP is the burst.
		"behavior": "melee",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.9,  # TUNING (not in GDD) 0..1; the miniboss first
		"mass": 10.0,  # TUNING (not in GDD)
		"slow_resist": 0.6,  # TUNING (not in GDD) like a boss
		"always_elite": true,  # Counts as an elite for Soul Nova, Dread Rally and Soul Ash.
		"miniboss": true,  # The miniboss flag (the HUD bar, the chest, boss multipliers).
		"faction": NorseEnemyData.FACTION,
		"kit": "barrow_wight",
		"group": "wilds",
		"chill_slow": 0.35,  # TUNING (not in GDD) his blow chills as a draugr's (NorseRules.on_unit_struck())
		"chill_time": 2.0,  # TUNING (not in GDD) s
		"howl_every": 9.0,  # TUNING (not in GDD) s between two howls
		"howl_windup": 1.0,  # TUNING (not in GDD) s he throws back his head (the telegraph ring grows)
		"howl_radius": 170.0,  # TUNING (not in GDD) px (the Bone Ring is 60-150 px from the necromancer)
		"howl_stun": 1.0,  # Brief: "stuns the ring for 1 s"
		"howl_slow": 0.3,  # TUNING (not in GDD) the necromancer's slow in reach
		"howl_slow_time": 1.5,  # TUNING (not in GDD) s
		"howl_barrows": 1,  # TUNING (not in GDD) barrows his howl cracks open near the ring
		"reward_xp": 220,  # TUNING (not in GDD) as the Brood Matriarch
		"reward_crystals": 10,  # TUNING (not in GDD)
	},  # The Barrow-Wight.
	# HRIMGAR'S BARROW (the brief: "each time he falls he sinks into his barrow
	# and returns stronger 20 s later, unless the necromancer breaks the barrow
	# while he is down"). The great mound he sinks into where he fell (sprite
	# norse/boss_barrow; broken: norse/boss_barrow_broken). It stands only while
	# he is down; breaking it ends him for good (BossHrimgar.barrow_broken()).
	# Draugr climb out of it while it stands (release_every / release_max, as an
	# open barrow's). HrimgarBarrowKit.
	"hrimgar_barrow": {
		"display_name": "Hrimgar's Barrow",
		"max_hp": 1300.0,  # TUNING (not in GDD) x the stage HP multiplier: the army's 20 s of work, not a free win
		"move_speed": 0.0,
		"damage": 0.0,
		"attack_interval": 1.0,
		"attack_range": 0.0,
		"radius": 26.0,  # TUNING (not in GDD) px (the 64 x 56 barrow sprite)
		"armor": 0.2,  # TUNING (not in GDD)
		"xp": 0,  # Its fall is his.
		"behavior": "structure",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 1.0,  # TUNING (not in GDD) 0..1; the army goes for it first
		"mass": 60.0,  # Immovable.
		"is_structure": true,
		"faction": NorseEnemyData.FACTION,
		"kit": "hrimgar_barrow",
		"group": "wilds",
		"release_every": 3.5,  # TUNING (not in GDD) s between two draugr climbing out
		"release_max": 4,  # TUNING (not in GDD) its own draugr at once
		"release_kinds": ["draugr", "draugr_female"],  # Owner-approved proposal (male and female)
		"release_dist": 32.0,  # TUNING (not in GDD) px
	},  # Hrimgar's barrow.
}
