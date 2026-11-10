## GreenwoodEnemyData — the kinds of THE GREENWOOD (temporary Act XV stage 43,
## the Turning Year's first stage; GDD §15.0 "The Greenwood (Act XV phase 2)";
## owner-approved proposal docs/proposals/LAST_SIX_ACTS.md section XV, "Stage 43:
## The Greenwood"):
##   huntsman       — THE HUNTSMAN OF THE WILD HUNT (male), the stage miniboss:
##                    "who leads three riders in a sweeping line" (HuntsmanKit,
##                    a WildChargeKit: he brings three Riders of the Wild Hunt
##                    and leads them abreast in his sweeps).
##   antler_thicket — one thorn of the Stag King's ANTLER CROWN: a structure
##                    the boss grows in a ring round himself (AntlerThicketKit:
##                    it keeps its place on the ring as he walks; while one
##                    stands he cannot be hurt; fire burns it, BossStagKing
##                    .crown_burn() through Thickets' rings).
## EnemyDirector.wild_def() looks these rows up after WildEnemyData. Rows have
## every key of a WildEnemyData.ENEMIES row (same meaning; "kit" ids load
## scripts/enemies/wild/<kit>_kit.gd, unique across every kit folder). Tuned for
## the act's FINAL slot XV; every value is TUNING (not in GDD) unless marked as
## the owner-approved proposal.
class_name GreenwoodEnemyData
extends RefCounted

## Kind id of the Huntsman of the Wild Hunt (the miniboss).
const HUNTSMAN: String = "huntsman"
## Kind id of one thorn of the Antler Crown.
const ANTLER_THICKET: String = "antler_thicket"

## Kind id -> design row.
const ENEMIES := {
	# THE HUNTSMAN OF THE WILD HUNT, the stage miniboss (male): a horned hunter
	# on a great antlered mount, a horn at his belt. He brings `riders` Riders
	# of the Wild Hunt (row rider_kind) and, every charge_every s, blows his horn
	# and LEADS THEM IN A SWEEPING LINE: they blink to his flanks rider_spacing
	# px apart, the line shows charge_windup s, then all of them sweep
	# charge_len px through the necromancer (WildChargeKit; each trample once a
	# sweep). Killed, he drops an XP burst (reward_xp in reward_crystals) and
	# the miniboss chest; his riders ride on alone.
	"huntsman": {
		"display_name": "The Huntsman of the Wild Hunt",
		"max_hp": 1300.0,  # TUNING (not in GDD) a miniboss (Mother Clubtail 1000 x the Titans' 2.2; slot XV is the hardest)
		"move_speed": 58.0,  # TUNING (not in GDD) px/s
		"damage": 12.0,  # TUNING (not in GDD) a spear in reach, before the time scaling
		"attack_interval": 1.3,  # TUNING (not in GDD) s
		"attack_range": 12.0,  # TUNING (not in GDD) px
		"radius": 20.0,  # TUNING (not in GDD) px (~80 x 68 px sprite)
		"armor": 0.2,  # TUNING (not in GDD)
		"xp": 0,  # His XP is the burst.
		"behavior": "melee",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.9,  # TUNING (not in GDD) 0..1; the miniboss first
		"mass": 12.0,  # TUNING (not in GDD) the ring does not shove him
		"slow_resist": 0.6,  # TUNING (not in GDD) like a boss
		"always_elite": true,  # Counts as an elite for Soul Nova, Dread Rally and Soul Ash.
		"miniboss": true,  # The miniboss flag (Enemy.is_miniboss: the HUD bar, the chest, boss multipliers).
		"no_bloom": true,  # A miniboss: never heals on living ground.
		"reward_xp": 260,  # TUNING (not in GDD) a little over Mother Clubtail's 240
		"reward_crystals": 10,  # TUNING (not in GDD)
		"faction": WildEnemyData.FACTION,
		"kit": "huntsman",
		"group": "hunt",
		"riders": 3,  # Owner-approved proposal: "who leads three riders in a sweeping line"
		"rider_kind": WildEnemyData.WILD_RIDER,  # Owner-approved proposal
		"rider_spacing": 46.0,  # TUNING (not in GDD) px between two places in his line
		"charge_first": 4.0,  # TUNING (not in GDD) s after he arrives
		"charge_every": 9.0,  # TUNING (not in GDD) s between two sweeps
		"charge_trigger": 420.0,  # TUNING (not in GDD) px to the necromancer for a sweep to start
		"charge_windup": 1.4,  # TUNING (not in GDD) s the line shows (his horn)
		"charge_speed": 360.0,  # TUNING (not in GDD) px/s
		"charge_len": 560.0,  # Owner-approved proposal: "a sweeping line"; TUNING (not in GDD) px
		"charge_damage": 9.0,  # TUNING (not in GDD) to each summon he crosses, before the time scaling
		"charge_player": 10.0,  # TUNING (not in GDD) to the necromancer, before the time scaling
		"charge_stun": 0.5,  # TUNING (not in GDD) s
		"charge_knock": 30.0,  # TUNING (not in GDD) px
	},  # The Huntsman of the Wild Hunt.
	# One thorn of THE ANTLER CROWN (the Stag King's ring; owner-approved
	# proposal: "his antlers grow a thicket ring around him that must be burned
	# through before he can be hurt"). A structure that keeps its place on the
	# ring round him (AntlerThicketKit); broken by damage, or burned by any fire
	# source near it (Thickets.burn_at() -> BossStagKing.crown_burn()). No XP,
	# no corpse.
	"antler_thicket": {
		"display_name": "Antler Thicket",
		"max_hp": 160.0,  # TUNING (not in GDD) per thorn (x the time and stage scaling; the crown's eight)
		"move_speed": 0.0,
		"damage": 0.0,  # It never attacks.
		"attack_interval": 1.0,
		"attack_range": 0.0,
		"radius": 12.0,  # TUNING (not in GDD) px
		"armor": 0.1,  # TUNING (not in GDD) bark
		"xp": 0,  # The crown is in the way, not a prize.
		"behavior": "structure",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.95,  # TUNING (not in GDD) 0..1: the army breaks the crown first
		"mass": 60.0,  # Immovable.
		"is_structure": true,  # No corpse, no knockback.
		"no_bloom": true,  # The crown never heals: it must be broken.
		"faction": WildEnemyData.FACTION,
		"kit": "antler_thicket",
		"group": "growth",
	},  # One thorn of the Antler Crown.
}
