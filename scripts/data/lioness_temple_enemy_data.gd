## LionessTempleEnemyData — the kinds of the Temple of the Lioness (stage 2 of
## the act; temporary Act XII, the Necropolis Dynasty; GDD §15.0 "The Temple of
## the Lioness (Dynasty phase 2)", "The Lion Warden (Dynasty phase 2)" and
## "Sekhmet, the Lioness of Retribution (Dynasty phase 2)"). The stage's own
## kinds (the Bastet Hunter and the Ushabti Statue are shared rows in
## DynastyEnemyData, so any stage may use them):
##   woken_colossus — a WOKEN COLOSSUS: a great statue stepping out of a long
##                    statue row (the Awakening Statues); it wears the Sand
##                    Colossus's art but is a regular heavy elite, never a
##                    miniboss (WokenColossusKit: the ground slam).
##   lion_warden    — THE LION WARDEN, the stage's miniboss (male): a huge
##                    stone lion-headed warrior holding the one doorway of the
##                    sealed hall (LionWardenKit, LionessTempleDirector).
##   wine_jar       — a RED-WINE JAR, a structure: Sekhmet sets down three in
##                    the Feast (WineJarKit, BossSekhmet).
## EnemyDirector.dynasty_def() looks these rows up after DynastyEnemyData.
## Rows have every key of a DynastyEnemyData.ENEMIES row (same meaning; "kit"
## ids load scripts/enemies/dynasty/<kit>_kit.gd, unique across every kit
## folder; "group", "rebirth", "fire_taken", "embalms", "holds_names" and
## "storm_silenced" switch the shared rules on for the kind), plus:
##   wears        — the woken colossus: the sprite key it is drawn with (Enemy
##                  .wears; visual only).
##   slam         — {every, windup (s), radius (px), damage (summons),
##                  damage_player, push (px)}: a telegraphed circle slam.
##   roar         — the Warden's: {first, every, windup (s), length, width,
##                  slack (px), damage, damage_player, wakes (statue rows)}.
##   walk_speed   — the Warden's speed once the seal falls (px/s).
##   reward_xp / reward_crystals — the miniboss's XP burst.
## The GDD gives no numbers: everything is TUNING (not in GDD) unless marked as
## the owner-approved proposal. Tuned for the act's FINAL slot VII.
class_name LionessTempleEnemyData
extends RefCounted

## Kind id of the Woken Colossus.
const WOKEN_COLOSSUS: String = "woken_colossus"
## Kind id of the Lion Warden (the miniboss).
const LION_WARDEN: String = "lion_warden"
## Kind id of Sekhmet's red-wine jar (a structure row).
const WINE_JAR: String = "wine_jar"
## Sprite the Woken Colossus wears (the Sand Colossus's art, the Dynasty pass).
const COLOSSUS_SPRITE: String = "dynasty/sand_colossus"
## Sprite the wine jar is drawn with (the Canopic Jar's art, tinted wine red).
const WINE_JAR_SPRITE: String = "dynasty/canopic_jar"
## Damage tag of the Woken Colossus's slam.
const COLOSSUS_SLAM_SOURCE: String = "woken_colossus_slam"
## Damage tag of the Lion Warden's slam.
const WARDEN_SLAM_SOURCE: String = "lion_warden_slam"
## Damage tag of the Lion Warden's roar.
const WARDEN_ROAR_SOURCE: String = "lion_warden_roar"
## Damage tag of the Bastet Hunter's ambush (her row is DynastyEnemyData's).
const BASTET_SOURCE: String = "bastet_ambush"

## Kind id -> design row.
const ENEMIES := {
	# The WOKEN COLOSSUS (see the header): stone, slow and heavy; burst it and
	# stay at range (the proposal's counter for the Sand Colossus).
	"woken_colossus": {
		"display_name": "Woken Colossus",
		"max_hp": 420.0,  # TUNING (not in GDD) a heavy elite (no elite multiplier: always_elite)
		"move_speed": 30.0,  # TUNING (not in GDD) px/s; stone
		"damage": 10.0,  # TUNING (not in GDD) a stone fist, before the time scaling
		"attack_interval": 1.6,  # TUNING (not in GDD) s
		"attack_range": 10.0,  # TUNING (not in GDD) px
		"radius": 18.0,  # TUNING (not in GDD) px (an 84 px statue)
		"armor": 0.15,  # TUNING (not in GDD)
		"flat_armor": 3.0,  # TUNING (not in GDD) sandstone (the Ushabti's 5 is the proposal's; the colossus is bigger, not harder)
		"xp": 14,  # TUNING (not in GDD)
		"behavior": "melee",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.7,  # TUNING (not in GDD) 0..1
		"mass": 30.0,  # TUNING (not in GDD) heavy stone
		"slow_resist": 0.5,  # TUNING (not in GDD)
		"always_elite": true,  # An elite by design (Soul Nova, Dread Rally, Soul Ash), never a miniboss
		"faction": DynastyEnemyData.FACTION,
		"kit": "woken_colossus",
		"group": "stone",
		"wears": COLOSSUS_SPRITE,
		"slam": {
			"every": 7.0,  # TUNING (not in GDD) s
			"windup": 1.0,  # TUNING (not in GDD) s of the raised fists
			"radius": 64.0,  # TUNING (not in GDD) px
			"damage": 12.0,  # TUNING (not in GDD) to each summon, before the time scaling
			"damage_player": 9.0,  # TUNING (not in GDD) before the time scaling
			"push": 20.0,  # TUNING (not in GDD) px
		},
	},  # The Woken Colossus.
	# THE LION WARDEN (male; proposal: "a huge statue-warrior that stands in a
	# doorway and must be killed to pass"): the stage's miniboss.
	"lion_warden": {
		"display_name": "Lion Warden",
		"max_hp": 1300.0,  # TUNING (not in GDD) a miniboss in a doorway (the Warbeast 2,100, Mammoth 2,200 walk at you; first passes 2,300, 1,800 and 1,500 outlived his seal)
		"move_speed": 0.0,  # He holds his doorway (LionWardenKit sets walk_speed once released)
		"damage": 12.0,  # TUNING (not in GDD) his slab shield in reach, before the time scaling
		"attack_interval": 1.4,  # TUNING (not in GDD) s
		"attack_range": 16.0,  # TUNING (not in GDD) px
		"radius": 24.0,  # TUNING (not in GDD) px (an 80 px statue-warrior)
		"armor": 0.2,  # TUNING (not in GDD) stone
		"flat_armor": 2.0,  # TUNING (not in GDD) stone (first pass 4, the Warbeast's plates: too slow to kill in a doorway)
		"xp": 0,  # His XP is the burst.
		"behavior": "melee",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.95,  # TUNING (not in GDD) 0..1: kill him to pass
		"mass": 80.0,  # TUNING (not in GDD) immovable stone
		"slow_resist": 1.0,  # TUNING (not in GDD) stone in a doorway
		"always_elite": true,  # Counts as an elite for Soul Nova, Dread Rally and Soul Ash
		"miniboss": true,  # The miniboss flag (Enemy.is_miniboss: the HUD bar, the chest, boss multipliers).
		"faction": DynastyEnemyData.FACTION,
		"kit": "lion_warden",
		"group": "stone",
		"walk_speed": 34.0,  # TUNING (not in GDD) px/s once the seal falls by itself
		"slam": {
			"every": 5.5,  # TUNING (not in GDD) s
			"windup": 1.0,  # TUNING (not in GDD) s of the raised slab
			"radius": 92.0,  # TUNING (not in GDD) px
			"damage": 14.0,  # TUNING (not in GDD) to each summon, before the time scaling
			"damage_player": 11.0,  # TUNING (not in GDD) before the time scaling
			"push": 26.0,  # TUNING (not in GDD) px
		},
		"roar": {
			"first": 4.0,  # TUNING (not in GDD) s after he arrives
			"every": 10.0,  # TUNING (not in GDD) s
			"windup": 1.1,  # TUNING (not in GDD) s the lane shows
			"length": 460.0,  # TUNING (not in GDD) px (across the sealed hall)
			"width": 40.0,  # TUNING (not in GDD) px
			"slack": 120.0,  # TUNING (not in GDD) px beyond the length the necromancer may stand and still be roared at
			"damage": 10.0,  # TUNING (not in GDD) to each summon, before the time scaling
			"damage_player": 10.0,  # TUNING (not in GDD) before the time scaling
			"wakes": 1,  # TUNING (not in GDD) statue rows each roar wakes
		},
		"reward_xp": 300,  # TUNING (not in GDD) a miniboss (the Warbeast 260)
		"reward_crystals": 14,  # TUNING (not in GDD)
	},  # The Lion Warden.
	# A RED-WINE JAR (proposal: "three red-wine jars (structures) fill the
	# arena; break all three while she drinks from each"): Sekhmet's Feast.
	"wine_jar": {
		"display_name": "Wine Jar",
		"max_hp": 150.0,  # Replaced at spawn by SekhmetData jar_hp_share x her max HP (BossSekhmet._set_jars())
		"move_speed": 0.0,
		"damage": 0.0,
		"attack_interval": 1.0,
		"attack_range": 0.0,
		"radius": 12.0,  # TUNING (not in GDD) px (the 30 px jar art)
		"armor": 0.0,
		"xp": 4,  # TUNING (not in GDD)
		"behavior": "structure",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 1.0,  # TUNING (not in GDD) 0..1: break them first
		"mass": 60.0,  # Immovable.
		"is_structure": true,
		"faction": DynastyEnemyData.FACTION,
		"kit": "wine_jar",
		"group": "stone",
	},  # The red-wine jar.
}
