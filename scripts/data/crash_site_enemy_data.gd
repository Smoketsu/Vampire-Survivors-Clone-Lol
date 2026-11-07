## CrashSiteEnemyData — immutable design data for the Concord kinds that join on
## the Crash Site (Stage 25) (Act IX, the Concord of Stars; GDD §15.0 "Act IX
## foundation (phase 1)" and "The Crash Site (Act IX phase 2)"; owner-approved
## proposal docs/act9/PROPOSAL.md "Stage 25: The Crash Site" with the owner's
## phase 2 answers of Nov 3, 2026). The stage's own rows (the shared Brood
## soldiers it adds, the Burrower and the Acid Spitter, live in
## ConcordEnemyData so any stage may use them):
##   brood_egg       — an INFESTATION EGG (a 1-hit structure row): it sits
##                     where a Concord enemy fell (CrashSiteDirector, the one
##                     egg path) for hatch_time s; any hit clears it (spells,
##                     summons and volleys alike: its HP is EGG_HP, so every hit
##                     that reaches it does); otherwise a broodling hatches.
##                     It never attacks or moves, heals on no turf and gives no
##                     XP, drop or corpse, and a cleared egg is not a kill
##                     (CombatResolver clears it through
##                     CrashSiteDirector.clear_egg() before the kill path).
##   brood_matriarch — the stage MINIBOSS: a winged queen-guard (an insect
##                     creature, female by name, drawn as an insect in the
##                     Brood's green-black chitin, as the queen-guard of the
##                     approved act9_boss.png; not in the figure style) and a
##                     FLIER who spits EGG SACS over the ring: they arc over it
##                     with a landing telegraph and land as Infestation eggs
##                     (the same egg path).
## EnemyDirector.concord_def() looks these rows up after ConcordEnemyData.
## Rows have every key of a ConcordEnemyData.ENEMIES row (same meaning; "kit"
## ids load scripts/enemies/concord/<kit>_kit.gd, unique across the Eye,
## Empire, Pantheon, Shogunate, Inferno, Court, City and Concord folders;
## "race", "beam", "abducts", "cloak" and "heals_on_turf" switch the shared
## rules on for the kind). The GDD gives no numbers: everything is TUNING (not
## in GDD) unless marked as the owner-approved proposal or the owner's answers.
class_name CrashSiteEnemyData
extends RefCounted

## Kind id of the Infestation egg (a structure row; CrashSiteDirector lays it).
const EGG: String = "brood_egg"
## Kind id of the stage miniboss.
const MATRIARCH: String = "brood_matriarch"
## Max HP an egg is set to at activation, whatever the HP scalings (so every
## hit that reaches it clears it: brief, "a 1 HP structure row").
const EGG_HP: float = 0.01  # TUNING (not in GDD) brief: every hit that reaches it clears it

## Kind id -> design row.
const ENEMIES := {
	# THE INFESTATION EGG (owner answer, Nov 3, 2026: "when a Concord enemy dies
	# on the Crash Site, an egg sits where it fell for 6 s; any spell or summon
	# hit on that spot clears it; otherwise a broodling hatches"). A pulsing
	# green-black egg in a smear of resin. BroodEggKit counts it down and hatches
	# it; CrashSiteDirector lays it (the one egg path) and counts it.
	"brood_egg": {
		"display_name": "Brood Egg",
		"max_hp": 1.0,  # Brief: a 1 HP structure row (set to EGG_HP at activation, whatever the scalings).
		"move_speed": 0.0,
		"damage": 0.0,  # It never attacks.
		"attack_interval": 1.0,
		"attack_range": 0.0,
		"radius": 6.0,  # TUNING (not in GDD) px (~14 px sprite)
		"armor": 0.0,
		"xp": 0,  # Brief: no XP.
		"behavior": "structure",  # It never moves.
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.45,  # TUNING (not in GDD) 0..1; worth a blow before it hatches
		"mass": 60.0,  # Immovable.
		"is_structure": true,  # No corpse, no knockback; a summon blocking it takes the whole correction.
		"faction": ConcordEnemyData.FACTION,
		"kit": "brood_egg",
		"race": "brood",  # Owner: the Brood lead Stage 25
		"heals_on_turf": false,  # Brief: heals on no turf
		"hatch_time": 6.0,  # Owner answer (Nov 3, 2026): "an egg sits where it fell for 6 s"
		"hatch_kind": "broodling",  # Owner answer: "otherwise a broodling hatches" (ConcordEnemyData.BROODLING)
	},  # The Infestation egg.
	# THE BROOD MATRIARCH, the stage miniboss (owner-approved proposal: "a winged
	# queen-guard who spits egg sacs over the ring"). An insect creature in the
	# Brood's green-black chitin with acid-green eyes, long cream claws and
	# membranous wings (female by name; drawn as an insect, not in the figure
	# style). A FLIER (Night Wings: no summon body-blocks her; a grounded melee
	# blow deals flight_melee_taken of itself: she swoops low to claw). She
	# comes in with the shared melee AI and claws in reach; every sac_every s
	# she stops for sac_windup s and spits `sacs` EGG SACS that arc over the
	# Bone Ring (sac_flight s, a landing telegraph) to points sac_min..sac_max
	# px from the necromancer (fixed angles turned by her think slot and her
	# volley count, no RNG) and land as Infestation eggs
	# (CrashSiteDirector.lay_egg(), the one egg path; tag "sac"). Killed, she
	# drops an XP burst (reward_xp in reward_crystals) and the miniboss chest.
	# BroodMatriarchKit.
	"brood_matriarch": {
		"display_name": "Brood Matriarch",
		"max_hp": 1300.0,  # TUNING (not in GDD) a miniboss (Big Sal 760, Old Greymane 1500)
		"move_speed": 58.0,  # TUNING (not in GDD) px/s
		"damage": 8.0,  # TUNING (not in GDD) her claws in reach, before the time scaling
		"attack_interval": 1.2,  # TUNING (not in GDD) s
		"attack_range": 10.0,  # TUNING (not in GDD) px
		"radius": 18.0,  # TUNING (not in GDD) px (~60 px sprite)
		"armor": 0.2,  # TUNING (not in GDD) chitin
		"xp": 0,  # Her XP is the burst.
		"behavior": "melee",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.9,  # TUNING (not in GDD) 0..1; the miniboss first
		"mass": 8.0,  # TUNING (not in GDD)
		"slow_resist": 0.6,  # TUNING (not in GDD) like a boss
		"always_elite": true,  # Counts as an elite for Soul Nova, Dread Rally and Soul Ash.
		"miniboss": true,  # The miniboss flag (Enemy.is_miniboss: the HUD bar, the chest, boss multipliers).
		"faction": ConcordEnemyData.FACTION,
		"kit": "brood_matriarch",
		"race": "brood",  # Owner: the Brood lead Stage 25
		"flies": true,  # Owner-approved proposal: "a winged queen-guard" (Night Wings)
		"phases": true,  # A flier crosses obstacles.
		"floating": true,  # Over the ground (the terrain slows and fires spare her).
		"flight_melee_taken": 0.5,  # TUNING (not in GDD) she swoops low to claw: grounded melee blows land at half
		"sac_every": 6.5,  # TUNING (not in GDD) s between two volleys of sacs
		"sac_windup": 0.7,  # TUNING (not in GDD) s she rears before she spits
		"sacs": 3,  # TUNING (not in GDD) sacs a volley
		"sac_flight": 1.1,  # TUNING (not in GDD) s in the air (the landing telegraph shows as long)
		"sac_min": 50.0,  # TUNING (not in GDD) px from the necromancer (inside the ring)
		"sac_max": 130.0,  # TUNING (not in GDD) px (the ring is 60-150 px)
		"sac_radius": 12.0,  # TUNING (not in GDD) px of the landing telegraph
		"reward_xp": 220,  # TUNING (not in GDD) as Big Sal and Old Greymane
		"reward_crystals": 10,  # TUNING (not in GDD)
	},  # The Brood Matriarch.
}
