## BattleSisterData — immutable design data for the Sister of the Scourge
## (kind id "battle_sister"; owner request, Oct 2026: a female Covenant
## soldier in the figure-redesign style, GDD §15.0 "Sister of the Scourge"),
## a fast melee zealot of the Crimson Covenant with a three-tailed scourge.
## She marches on the Crimson March from 6:00 and in the Sanctum of Judgment
## from 7:45 (their stage timelines name her by her real id), and any stage
## can spawn her (--spawn=battle_sister@T). EnemyDirector.enemy_def() looks
## her up after EnemyData, the Sanctum structures and MarchEnemyData, before
## SanctumEnemyData; the Codex reads her row like any Covenant kind's.
##
## The row has every key of an EnemyData.ENEMIES row (same meaning) plus
## "kit": "sister" (BattleSisterKit, a CovenantKit, reads the lash_* and
## zeal_* keys below). She is an ordinary soldier (not always_elite): a
## spawner's elite flag makes her an elite like any other kind.
## The GDD gives no numbers: everything is TUNING (not in GDD).
class_name BattleSisterData
extends RefCounted

## Kind id of the Sister of the Scourge (Enemy.kind, stats, Codex, --spawn=).
const ID: String = "battle_sister"

## Her design row, keyed by ID (looked up through ENEMIES like the other
## enemy tables).
const ENEMIES := {
	# A quick zealot who closes in at a run and lashes from just outside
	# sword reach. Counterplay: a front line in the way only shares the lash
	# (two targets at most), focus fire (she is light), Shade Stride / Grave
	# Step out of the telegraphed line. She always advances on the player.
	"battle_sister": {
		"display_name": "Sister of the Scourge",
		"max_hp": 44.0,  # TUNING (not in GDD) between a Shieldbearer (52) and a Footman (36)
		"move_speed": 66.0,  # TUNING (not in GDD) px/s; quick (Recruit 58, Purifier 66, necromancer 110)
		"damage": 4.0,  # TUNING (not in GDD) her scourge-handle blow in contact (the lash is her real attack)
		"attack_interval": 1.3,  # TUNING (not in GDD) s between contact blows
		"attack_range": 4.0,  # TUNING (not in GDD) px edge to edge (contact)
		"radius": 11.0,  # TUNING (not in GDD) px body radius
		"armor": 0.1,  # TUNING (not in GDD) 10% of damage ignored (corset and pauldron)
		"xp": 4,  # TUNING (not in GDD) a Halberdier's XP
		"behavior": "melee",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.5,  # TUNING (not in GDD) 0..1; a damage dealer the archers should shoot early
		"mass": 1.2,  # TUNING (not in GDD) light: warriors hold her
		"kit": "sister",
		# Lash (BattleSisterKit): when her target is within reach, she stops,
		# a crimson lash line flickers toward it for lash_telegraph s, then
		# the scourge cracks along the line: the first lash_targets bodies in
		# it (summons and the necromancer, nearest first) are struck.
		"lash_first": 1.0,  # TUNING (not in GDD) s after spawning before the first lash
		"lash_cooldown": 2.4,  # TUNING (not in GDD) s between lashes (counts down while she walks)
		"lash_reach": 62.0,  # TUNING (not in GDD) px from her centre to the lash tip (a sword is ~15)
		"lash_trigger": 56.0,  # TUNING (not in GDD) px from her centre to the target's edge to start a lash
		"lash_width": 14.0,  # TUNING (not in GDD) px; a body within half of it (plus its radius) of the line is struck
		"lash_telegraph": 0.35,  # TUNING (not in GDD) s the line flickers before the crack
		"lash_recover": 0.25,  # TUNING (not in GDD) s she stands after the crack
		"lash_targets": 2,  # TUNING (not in GDD) bodies one crack can strike
		"lash_damage_player": 7.0,  # TUNING (not in GDD) before time scaling
		"lash_damage_summon": 8.0,  # TUNING (not in GDD) before time scaling
		# Zeal: when a fellow soldier falls within zeal_radius px (the deaths
		# CovenantRites records), she surges for zeal_duration s: faster feet
		# and a faster lash cooldown. Not again within zeal_cooldown s.
		"zeal_radius": 110.0,  # TUNING (not in GDD) px
		"zeal_duration": 2.5,  # TUNING (not in GDD) s
		"zeal_cooldown": 6.0,  # TUNING (not in GDD) s from the start of one surge to the next
		"zeal_speed_mult": 1.3,  # TUNING (not in GDD) move speed x while surging
		"zeal_lash_rate": 1.6,  # TUNING (not in GDD) lash cooldown runs this many times faster while surging
	},
}
