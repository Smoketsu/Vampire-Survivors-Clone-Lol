## ProvingMoonEnemyData — immutable design data for the Concord kinds that join on
## the Proving Moon (Stage 26) (Act IX, the Concord of Stars; GDD §15.0 "The
## Proving Moon (Act IX phase 2)" and "The Warbeast (Act IX)"; owner-approved
## proposal docs/act9/PROPOSAL.md "Stage 26: The Proving Moon"):
##   warbeast — THE WARBEAST, the stage's miniboss: the Vrask's armoured
##              hunting animal (a creature: a six-legged reptilian hound the size
##              of a horse, teal hide under dark gunmetal armour plates; never
##              the necromancer's violet and bone). It walks at its target and
##              bites in reach (the shared melee); every pounce_every s it
##              crouches (a telegraphed landing circle) and POUNCES: it leaps
##              onto the spot, over the Bone Ring, and everything in the circle
##              is bitten and thrown out (WarbeastKit). Under the moon's low
##              gravity (ConcordRules.gravity(), 2.0) its pounce reaches twice
##              as far and its throw goes twice as far. Its ARMOUR PLATES are
##              the existing flat_armor path (own decision: flat armour, not a
##              lumen shield; Wither shreds it), plus a little percentage armour.
## EnemyDirector.concord_def() looks these rows up after ConcordEnemyData.
## Rows have every key of a ConcordEnemyData.ENEMIES row (same meaning; "kit"
## ids load scripts/enemies/concord/<kit>_kit.gd, unique across the Eye,
## Empire, Pantheon, Shogunate, Inferno, Court, City and Concord folders;
## "race", "beam", "abducts", "cloak" and "heals_on_turf" switch the shared
## rules on for the kind). The Warbeast's own keys (WarbeastKit):
##   pounce_every   — s between two pounces (after one lands).
##   pounce_first   — s after it arrives before the first.
##   pounce_min     — px (edge to edge) nearer than which it bites instead.
##   pounce_reach   — px (centre to the landing point) it pounces from, x the
##                    low gravity (ConcordRules.gravity(): twice as far on the
##                    moon).
##   pounce_windup  — s it crouches with its landing circle shown.
##   pounce_time    — s of the leap.
##   pounce_height  — px its body rises at the top of the leap (drawing).
##   pounce_radius  — px of the landing circle.
##   pounce_damage_player / pounce_damage_summon — the landing's bite before the
##                    time scaling.
##   pounce_push    — px the summons in the circle are thrown out, x the low
##                    gravity.
##   reward_xp / reward_crystals — its XP burst (the crystals it scatters).
## The GDD gives no numbers: everything is TUNING (not in GDD).
class_name ProvingMoonEnemyData
extends RefCounted

## Kind id of the Warbeast (the miniboss).
const WARBEAST: String = "warbeast"
## Damage tag of the Warbeast's pounce (its landing).
const POUNCE_SOURCE: String = "warbeast_pounce"
## Sprite key of the Warbeast (assets/sprites/concord/warbeast.png; its walk
## strip warbeast_walk.png).
const WARBEAST_SPRITE: String = "concord/warbeast"

## Kind id -> design row.
const ENEMIES := {
	# The Warbeast (see the header): the miniboss of the Proving Moon.
	"warbeast": {
		"display_name": "Warbeast",
		"max_hp": 2100.0,  # TUNING (not in GDD) a miniboss (Mammoth 2,200, Old Greymane 2,200)
		"move_speed": 62.0,  # TUNING (not in GDD) px/s; a hunting animal
		"damage": 9.0,  # TUNING (not in GDD) a bite in reach, before the time scaling
		"attack_interval": 1.1,  # TUNING (not in GDD) s
		"attack_range": 12.0,  # TUNING (not in GDD) px
		"radius": 22.0,  # TUNING (not in GDD) px (x 1.35 as an elite = 29.7; a ~64 px sprite)
		"armor": 0.15,  # TUNING (not in GDD) its hide
		"flat_armor": 4.0,  # TUNING (not in GDD) own decision: its armour plates are flat armour (Mammoth 4)
		"xp": 0,  # Its XP is the burst.
		"behavior": "melee",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.9,  # TUNING (not in GDD) 0..1
		"mass": 40.0,  # TUNING (not in GDD) heavy
		"slow_resist": 0.6,  # TUNING (not in GDD) like a miniboss
		"always_elite": true,  # Counts as an elite for Soul Nova, Dread Rally and Soul Ash
		"miniboss": true,  # The miniboss flag (Enemy.is_miniboss: the HUD bar, the chest, boss multipliers).
		"faction": ConcordEnemyData.FACTION,
		"kit": "warbeast",
		"race": "vrask",  # The Vrask's hunting animal (owner: the Vrask lead the Proving Moon)
		"pounce_every": 6.5,  # TUNING (not in GDD) s
		"pounce_first": 3.0,  # TUNING (not in GDD) s
		"pounce_min": 40.0,  # TUNING (not in GDD) px edge to edge
		"pounce_reach": 150.0,  # TUNING (not in GDD) px, x the low gravity (300 on the moon)
		"pounce_windup": 0.9,  # TUNING (not in GDD) s
		"pounce_time": 0.45,  # TUNING (not in GDD) s
		"pounce_height": 26.0,  # TUNING (not in GDD) px (drawing)
		"pounce_radius": 46.0,  # TUNING (not in GDD) px
		"pounce_damage_player": 9.0,  # TUNING (not in GDD) before the time scaling
		"pounce_damage_summon": 10.0,  # TUNING (not in GDD) before the time scaling
		"pounce_push": 18.0,  # TUNING (not in GDD) px, x the low gravity (36 on the moon)
		"reward_xp": 260,  # TUNING (not in GDD) a miniboss (Mammoth 260)
		"reward_crystals": 12,  # TUNING (not in GDD)
	},  # The Warbeast (the Proving Moon).
}
