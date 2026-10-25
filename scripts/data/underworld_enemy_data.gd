## UnderworldEnemyData — immutable design data for the Olympian Republic kinds that
## join on the Asphodel Underworld (Stage 12) (Act IV; GDD §15.0 "Act IV foundation (phase 1)"
## and "The Asphodel Underworld (Act IV phase 2)"): the Underworld's own soldier,
## Cerberus and his three heads, and Hades' Lord of the Dead guard.
## Each kind stays in play on the stages after it, and any stage can spawn it
## (--spawn=kind@T). EnemyDirector.pantheon_def() looks these rows up after
## PantheonEnemyData. Rows have every key of a PantheonEnemyData.ENEMIES row
## (same meaning; "kit" ids load scripts/enemies/pantheon/<kit>_kit.gd, unique
## across the Eye, Empire and Pantheon folders; "bronze", "phalanx", "hero",
## "fodder" switch the shared rules on for the kind), plus:
##   wears / wear_tint — the sprite key the kind borrows and its multiply tint
##                       (ShadeHopliteKit sets Enemy.wears from them: the
##                       Underworld's dead hoplites wear the Hoplite's art, pale
##                       as ghosts; own decision, no new art).
##   head_* and the attack keys — Cerberus only: his three heads (CERBERUS_HEAD)
##                       and their attacks (CerberusKit).
## The kinds:
##   shade_hoplite   — Shade Hoplite: soldier; the dead of a thousand wars still
##                     in their ranks. PHALANX (they lock shields like the living)
##                     but not bronze (a ghost's shield draws no lightning).
##   cerberus        — Cerberus: the miniboss, the three-headed hound of the gates.
##                     His body cannot be struck (untargetable): his three heads
##                     (cerberus_head) ride on it and each must be killed on its
##                     own; the last one falling kills him (the chest, the XP).
##   cerberus_head   — one of his heads: a structure riding on the body, with its
##                     own HP; CerberusKit runs the attack of each living head.
##   tartarus_warden — Hades' guard of the dead (Lord of the Dead): a dark
##                     hoplite of Tartarus raised around him in a ring; PHALANX.
## The GDD gives no numbers: everything is TUNING (not in GDD) unless marked as
## the owner-approved proposal.
class_name UnderworldEnemyData
extends RefCounted

## Kind id of the Underworld's dead hoplite (soldier).
const SHADE_HOPLITE: String = "shade_hoplite"
## Kind id of the miniboss (CerberusKit).
const CERBERUS: String = "cerberus"
## Kind id of one of Cerberus's heads (CerberusHeadKit).
const CERBERUS_HEAD: String = "cerberus_head"
## Kind id of Hades' ring guard (Lord of the Dead).
const WARDEN: String = "tartarus_warden"

## Pale ghost tint (multiply, RGBA 0..1) of the Underworld's dead (the Hoplite
## art they borrow; marble and Aegean, never the undead's bone and teal).
const SHADE_TINT := Color(0.72, 0.80, 0.90, 0.86)  # TUNING (not in GDD)
## Darker, colder tint (multiply, RGBA 0..1) of Hades' Tartarus guard.
const WARDEN_TINT := Color(0.50, 0.56, 0.74, 0.94)  # TUNING (not in GDD)

## Kind id -> design row.
const ENEMIES := {
	# Soldier: a hoplite of the dead, still in the ranks it died in: pale, the
	# Hoplite's art tinted as a ghost. Locks shields like the living.
	"shade_hoplite": {
		"display_name": "Shade Hoplite",
		"max_hp": 30.0,  # TUNING (not in GDD) a soldier (Hoplite 34): a ghost's body is thinner
		"move_speed": 46.0,  # TUNING (not in GDD) px/s; a little quicker than the living
		"damage": 4.0,  # TUNING (not in GDD) a spear thrust, before the time scaling
		"attack_interval": 1.3,  # TUNING (not in GDD) s
		"attack_range": 12.0,  # TUNING (not in GDD) px; the spear
		"radius": 10.0,  # TUNING (not in GDD) px
		"armor": 0.1,  # TUNING (not in GDD) a ghost's bronze
		"xp": 2,  # TUNING (not in GDD)
		"behavior": "melee",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.4,  # TUNING (not in GDD) 0..1
		"mass": 1.2,  # TUNING (not in GDD)
		"faction": PantheonEnemyData.FACTION,
		"kit": "shade_hoplite",
		"phalanx": true,  # Locks shields (Phalanx).
		"wears": "pantheon/hoplite",  # Own decision: the Hoplite's art, pale (no new art).
		"wear_tint": SHADE_TINT,
	},
	# Miniboss: the three-headed hound of the gates (owner-approved proposal:
	# "three heads, three attacks, and each head must be killed on its own").
	# A huge black hound with a mane of Hades' fire.
	"cerberus": {
		"display_name": "Cerberus",
		"max_hp": 300.0,  # Placeholder: the body cannot be struck; its HP mirrors the heads' sum (CerberusKit)
		"move_speed": 50.0,  # TUNING (not in GDD) px/s
		"damage": 10.0,  # TUNING (not in GDD) a paw swipe in melee, before the time scaling
		"attack_interval": 1.4,  # TUNING (not in GDD) s
		"attack_range": 14.0,  # TUNING (not in GDD) px
		"radius": 26.0,  # TUNING (not in GDD) px; a big body
		"armor": 0.0,  # The heads carry the armour.
		"xp": 0,  # Its reward is CerberusKit's XP burst.
		"behavior": "melee",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.0,  # Untargetable: summons fight the heads.
		"mass": 12.0,  # TUNING (not in GDD) shoves warriors aside, like Valkyrie 2.0
		"slow_resist": 0.5,  # TUNING (not in GDD) like every miniboss
		"faction": PantheonEnemyData.FACTION,
		"kit": "cerberus",
		"always_elite": true,  # Counts as an elite for Soul Nova, Dread Rally and Soul Ash.
		"miniboss": true,
		"reward_xp": 200,  # TUNING (not in GDD) XP burst on death (Valkyrie 2.0 180)
		"reward_crystals": 10,  # TUNING (not in GDD) crystals it is split into
		"reward_ash": 14,  # TUNING (not in GDD) Soul Ash bounty (objective_ash; Valkyrie 2.0 12)
		"advance_range": 300.0,  # TUNING (not in GDD) px; farther than this he lopes faster
		"advance_speed_mult": 2.0,  # TUNING (not in GDD) speed factor while left behind
		# The three heads (CerberusHeadKit rides each on the body; CerberusKit runs
		# their attacks one at a time, never a dead head's).
		"head_hp": 520.0,  # TUNING (not in GDD) each head's max HP, x the time scaling and the stage HP multiplier (1,560 in all)
		"head_offsets": [Vector2(-2, -19), Vector2(15, -42), Vector2(30, -14)],  # TUNING (not in GDD) px from the body's centre facing right (mirrored facing left), on the pantheon/cerberus sprite's three heads: head 0 the back one (fire), 1 the high middle one (pounce), 2 the front one (howl)
		"attack_gap": 2.4,  # TUNING (not in GDD) s between the end of one head's attack and the next
		"first_attack": 2.0,  # TUNING (not in GDD) s after he arrives
		"recover_time": 0.5,  # TUNING (not in GDD) s he stands after an attack
		# Head 0: FIRE BREATH, a cone of Hades' fire in front of him.
		"breath_range": 130.0,  # TUNING (not in GDD) px cone length
		"breath_half_arc": 0.5,  # TUNING (not in GDD) rad each side
		"breath_telegraph": 0.8,  # TUNING (not in GDD) s
		"breath_time": 1.4,  # TUNING (not in GDD) s of fire
		"breath_tick": 0.35,  # TUNING (not in GDD) s between two burns of a body inside
		"breath_damage_player": 4.0,  # TUNING (not in GDD) per tick, before the time scaling
		"breath_damage_summon": 4.0,  # TUNING (not in GDD) per tick, before the time scaling
		# Head 1: the POUNCE, a leap that bites down on the necromancer's spot.
		"pounce_range_min": 90.0,  # TUNING (not in GDD) px
		"pounce_range_max": 320.0,  # TUNING (not in GDD) px
		"pounce_telegraph": 0.9,  # TUNING (not in GDD) s the landing circle shows
		"pounce_time": 0.45,  # TUNING (not in GDD) s in the air
		"pounce_radius": 56.0,  # TUNING (not in GDD) px landing bite
		"pounce_damage_player": 16.0,  # TUNING (not in GDD) before the time scaling
		"pounce_damage_summon": 14.0,  # TUNING (not in GDD) before the time scaling
		# Head 2: the HOWL, the dread of the gates: shades rise, summons falter.
		"howl_telegraph": 0.7,  # TUNING (not in GDD) s
		"howl_shades": 6,  # TUNING (not in GDD) Shades of the Dead per howl (never over the hard cap)
		"howl_rise_radius": 90.0,  # TUNING (not in GDD) px around him they rise
		"howl_slow": 0.3,  # TUNING (not in GDD) fraction of speed the summons within howl_reach lose
		"howl_reach": 140.0,  # TUNING (not in GDD) px
		"howl_slow_time": 1.5,  # TUNING (not in GDD) s
	},
	# One of Cerberus's heads: a structure that rides on the body (CerberusHeadKit).
	"cerberus_head": {
		"display_name": "Head of Cerberus",
		"max_hp": 520.0,  # Placeholder: CerberusKit sets it from the body's head_hp
		"move_speed": 0.0,
		"damage": 0.0,
		"attack_interval": 1.0,
		"attack_range": 0.0,
		"radius": 11.0,  # TUNING (not in GDD) px; the head's hit body
		"armor": 0.15,  # TUNING (not in GDD) thick hide
		"xp": 0,
		"behavior": "melee",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 1.0,  # TUNING (not in GDD) the army goes for the heads
		"mass": 50.0,  # Never shoved.
		"faction": PantheonEnemyData.FACTION,
		"kit": "cerberus_head",
		"is_structure": true,  # Rides on the body; no corpse, no knockback.
	},
	# Hades' guard (Lord of the Dead): a hoplite of Tartarus, risen around him in
	# a ring; the Hoplite's art, dark and cold.
	"tartarus_warden": {
		"display_name": "Tartarus Warden",
		"max_hp": 70.0,  # TUNING (not in GDD) x the time scaling: sturdier than a soldier (the ring must take work to break)
		"move_speed": 40.0,  # TUNING (not in GDD) px/s
		"damage": 6.0,  # TUNING (not in GDD) before the time scaling
		"attack_interval": 1.3,  # TUNING (not in GDD) s
		"attack_range": 12.0,  # TUNING (not in GDD) px
		"radius": 10.0,  # TUNING (not in GDD) px
		"armor": 0.2,  # TUNING (not in GDD)
		"xp": 1,  # TUNING (not in GDD) few: the ring is the boss's
		"behavior": "melee",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.7,  # TUNING (not in GDD) break the ring
		"mass": 2.0,  # TUNING (not in GDD)
		"faction": PantheonEnemyData.FACTION,
		"kit": "tartarus_warden",
		"phalanx": true,  # His ring locks shields.
		"wears": "pantheon/hoplite",  # Own decision: the Hoplite's art, dark (no new art).
		"wear_tint": WARDEN_TINT,
	},
}
