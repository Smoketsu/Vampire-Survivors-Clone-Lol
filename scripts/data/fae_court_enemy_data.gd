## FaeCourtEnemyData — the kinds of THE FAE COURT (temporary Act XV stage 44, the
## Turning Year's second stage; GDD §15.0 "The Fae Court (Act XV phase 2)";
## owner-approved proposal docs/proposals/LAST_SIX_ACTS.md section XV, "Stage 44:
## The Fae Court"):
##   winter_prince   — THE WINTER PRINCE (male), the stage miniboss: "the Summer
##                     Queen's rival, who brings one minute of winter into her
##                     summer" (WinterPrinceKit: frost armour, a sword in reach
##                     and fans of frost bolts that chill summons; the minute of
##                     winter itself is FaeCourtDirector's, through
##                     SeasonCycle.set_override()).
##   masked_courtier — one face of the Summer Queen's MASQUE: a fae courtier
##                     wearing her face (MaskedCourtierKit: drawn as her until a
##                     hit unmasks it; masked, it throws her petal bolts;
##                     unmasked, it fights with a thorn rapier).
## EnemyDirector.wild_def() looks these rows up after WildEnemyData. Rows have
## every key of a WildEnemyData.ENEMIES row (same meaning; "kit" ids load
## scripts/enemies/wild/<kit>_kit.gd, unique across every kit folder). Tuned for
## the act's FINAL slot XV; every value is TUNING (not in GDD) unless marked as
## the owner-approved proposal.
class_name FaeCourtEnemyData
extends RefCounted

## Kind id of the Winter Prince (the miniboss).
const WINTER_PRINCE: String = "winter_prince"
## Kind id of one masked face of the Masque.
const MASKED_COURTIER: String = "masked_courtier"

## Kind id -> design row.
const ENEMIES := {
	# THE WINTER PRINCE, the stage miniboss (male): frost armour, a cloak of
	# snow, an icicle sword. He walks at the necromancer and strikes in reach;
	# every volley_every s he throws volley_bolts frost bolts in a fan
	# (volley_spread degrees wide) at the nearest necromancer (the plain hostile
	# shot, ProjectileManager.fire_hostile(): volley_damage x the time scaling,
	# chilling the summon each strikes chill_slow for chill_time s through
	# CombatResolver.chill_unit()). His coming starts ONE MINUTE OF WINTER
	# (winter_time s; FaeCourtDirector). Killed, he drops an XP burst
	# (reward_xp in reward_crystals) and the miniboss chest; the winter keeps
	# its minute.
	"winter_prince": {
		"display_name": "The Winter Prince",
		"max_hp": 1150.0,  # TUNING (not in GDD) a miniboss (the Huntsman 1,100; he is alone, without riders)
		"move_speed": 56.0,  # TUNING (not in GDD) px/s
		"damage": 10.0,  # TUNING (not in GDD) an icicle sword in reach, before the time scaling
		"attack_interval": 1.2,  # TUNING (not in GDD) s
		"attack_range": 12.0,  # TUNING (not in GDD) px
		"radius": 18.0,  # TUNING (not in GDD) px (~40 x 56 px sprite)
		"armor": 0.25,  # TUNING (not in GDD) frost armour
		"xp": 0,  # His XP is the burst.
		"behavior": "melee",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.9,  # TUNING (not in GDD) 0..1; the miniboss first
		"mass": 10.0,  # TUNING (not in GDD) the ring does not shove him
		"slow_resist": 0.6,  # TUNING (not in GDD) like a boss (the snow he brings barely slows him)
		"always_elite": true,  # Counts as an elite for Soul Nova, Dread Rally and Soul Ash.
		"miniboss": true,  # The miniboss flag (Enemy.is_miniboss: the HUD bar, the chest, boss multipliers).
		"no_bloom": true,  # A miniboss: never heals on living ground.
		"reward_xp": 260,  # TUNING (not in GDD) as the Huntsman
		"reward_crystals": 10,  # TUNING (not in GDD)
		"faction": WildEnemyData.FACTION,
		"kit": "winter_prince",
		"group": "fae",
		"winter_time": 60.0,  # Owner-approved proposal: "who brings one minute of winter into her summer"
		"volley_first": 3.0,  # TUNING (not in GDD) s after he arrives
		"volley_every": 5.5,  # TUNING (not in GDD) s between two fans
		"volley_range": 360.0,  # TUNING (not in GDD) px to the necromancer for a fan
		"volley_bolts": 5,  # TUNING (not in GDD) bolts in a fan
		"volley_spread": 50.0,  # TUNING (not in GDD) degrees, the fan's width (first pass 40)
		"volley_speed": 290.0,  # TUNING (not in GDD) px/s
		"volley_damage": 2.5,  # TUNING (not in GDD) per bolt, before the time scaling (first pass 4: 120-165 on the necromancer in his minute, seeds 7 and 11)
		"chill_slow": 0.35,  # TUNING (not in GDD) 0..1 the chill on a summon a bolt strikes (the Winter Fae's frost)
		"chill_time": 2.5,  # TUNING (not in GDD) s
	},  # The Winter Prince.
	# One face of THE MASQUE (owner-approved proposal: "she and her court change
	# faces, and only hits reveal which is real"): a fae courtier in a gown of
	# roses wearing the Summer Queen's face. While MASKED it is drawn exactly as
	# she is (her `_mask` art) and throws one of her petal bolts every bolt_every
	# s at the nearest necromancer (bolt_damage x the time scaling); the first
	# hit it takes UNMASKS it (it is drawn as itself) and it fights on with a
	# thorn rapier. It never heals on living ground (a glamour, not a growing
	# thing).
	"masked_courtier": {
		"display_name": "Masked Courtier",
		"max_hp": 90.0,  # TUNING (not in GDD) a soldier (x the time and stage scaling)
		"move_speed": 60.0,  # TUNING (not in GDD) px/s
		"damage": 7.0,  # TUNING (not in GDD) a thorn rapier, before the time scaling
		"attack_interval": 1.1,  # TUNING (not in GDD) s
		"attack_range": 8.0,  # TUNING (not in GDD) px
		"radius": 11.0,  # TUNING (not in GDD) px
		"armor": 0.1,  # TUNING (not in GDD)
		"xp": 6,  # TUNING (not in GDD)
		"behavior": "melee",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.7,  # TUNING (not in GDD) 0..1
		"mass": 1.4,  # TUNING (not in GDD)
		"no_bloom": true,  # A glamour: never heals on living ground.
		"faction": WildEnemyData.FACTION,
		"kit": "masked_courtier",
		"group": "fae",
		"bolt_first": 1.0,  # TUNING (not in GDD) s after it comes on
		"bolt_every": 2.8,  # TUNING (not in GDD) s between two petal bolts while masked
		"bolt_range": 340.0,  # TUNING (not in GDD) px to the necromancer for a bolt
		"bolt_speed": 260.0,  # TUNING (not in GDD) px/s
		"bolt_damage": 3.5,  # TUNING (not in GDD) before the time scaling
	},  # One masked face of the Masque.
}
