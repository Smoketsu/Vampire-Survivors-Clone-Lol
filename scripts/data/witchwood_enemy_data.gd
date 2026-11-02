## WitchwoodEnemyData — immutable design data for the Court kinds that belong
## to the Witchwood (Stage 20) (Act VII; GDD §15.0 "Act VII foundation (phase
## 1)" and "The Witchwood (Act VII phase 2)"; owner-approved proposal
## docs/act7/PROPOSAL.md "Stage 20: The Witchwood"):
##   bog_mother     — the BOG MOTHER, the stage miniboss (female): a vast drowned
##                    witch who drags summons into the fen (BogMotherKit).
##   isolde_sister  — one of ISOLDE'S THREE SISTERS (her phase 2; BossIsolde
##                    spawns them, IsoldeSisterKit): all three must fall within
##                    10 s of each other or the fallen rise again.
##   hex_stone      — a HEX STONE, a structure (the Witchwood's director raises
##                    them in every zone, HexStoneKit): it powers the covens'
##                    circles; broken, it leaves dead ground where no coven casts.
## The new shared kinds of the stage (the Crimson Witch, the Bloated Thrall) are
## rows in CourtEnemyData (its "Act VII: the Witchwood" block), as the brief
## asks, so every Act VII stage fields them. Each kind here stays usable on any
## stage (--spawn=kind@T). EnemyDirector.court_def() looks these rows up after
## CourtEnemyData. Rows have every key of a CourtEnemyData.ENEMIES row (same
## meaning; "kit" ids load scripts/enemies/court/<kit>_kit.gd, unique across the
## Eye, Empire, Pantheon, Shogunate, Inferno and Court folders). Kit numbers are
## row keys documented on each row.
## The GDD gives no numbers: everything is TUNING (not in GDD) unless marked as
## the owner-approved proposal.
class_name WitchwoodEnemyData
extends RefCounted

## Kind id of the miniboss.
const BOG_MOTHER: String = "bog_mother"
## Kind id of Isolde's sisters.
const SISTER: String = "isolde_sister"
## Kind id of the hex stone.
const HEX_STONE: String = "hex_stone"
## Damage tag of the Bog Mother's drowning (a summon dragged to her).
const DROWN_SOURCE: String = "bog_drown"
## Damage tag of the Bog Mother's mire slam.
const MIRE_SOURCE: String = "bog_mire"

## Kind id -> design row.
const ENEMIES := {
	# Miniboss (female): THE BOG MOTHER. Owner-approved proposal: "a vast drowned
	# witch who drags summons into the fen". A CourtKit (BogMotherKit):
	#   * HER BOG — black fen water of bog_radius px around her wherever she
	#     wades: it slows the necromancer, the summons and the living foes in it
	#     (TerrainSlow, the one ground-slow path, through FenWater.wade(), the
	#     same as the Fen's pools).
	#   * THE DRAG — every drag_every s, when summons stand within drag_reach px,
	#     up to drag_count of the nearest are marked (a ring under each,
	#     drag_telegraph s); then weed-ropes seize those still within reach and
	#     DRAG them into her bog through THE ONE PULL PATH (BogMotherKit.pull():
	#     held by SummonedUnit.compel(), moved at drag_speed px/s, at most
	#     drag_hold s). One dragged to her side is DROWNED: drown_damage.
	#   * THE MIRE SLAM — a summon or the necromancer within slam_trigger px:
	#     a telegraphed circle of slam_radius px (slam_windup s), then a blow of
	#     black water on everyone in it.
	#   * The forced march — beyond advance_range px she strides
	#     advance_speed_mult faster.
	# On death: reward_xp in reward_crystals, the miniboss chest (ChestManager).
	"bog_mother": {
		"display_name": "The Bog Mother",
		"max_hp": 2000.0,  # TUNING (not in GDD) before the time / stage scaling (the Gatekeeper 2300); first pass 2400 (she stood 8 min, healing in the pools)
		"move_speed": 36.0,  # TUNING (not in GDD) px/s; she wades
		"damage": 10.0,  # TUNING (not in GDD) a claw in reach, before the time scaling
		"attack_interval": 1.5,  # TUNING (not in GDD) s
		"attack_range": 14.0,  # TUNING (not in GDD) px
		"radius": 24.0,  # TUNING (not in GDD) px; vast
		"armor": 0.15,  # TUNING (not in GDD)
		"xp": 0,  # Her reward is the burst below.
		"behavior": "melee",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.85,  # TUNING (not in GDD) 0..1
		"mass": 12.0,  # TUNING (not in GDD)
		"slow_resist": 0.5,  # TUNING (not in GDD) like a boss
		"faction": CourtEnemyData.FACTION,
		"kit": "bog_mother",
		"miniboss": true,  # The stage miniboss (Enemy.is_miniboss: the chest, the bosses' exemptions).
		"feeds": 0.25,  # Owner-approved: not a vampire (a witch): 25%
		"bog_radius": 110.0,  # TUNING (not in GDD) px of her black water
		"bog_slow_player": 0.3,  # TUNING (not in GDD) share of the necromancer's speed lost in it
		"bog_slow_summon": 0.35,  # TUNING (not in GDD) share of a summon's speed lost in it
		"bog_slow_enemy": 0.25,  # TUNING (not in GDD) share of a living foe's speed lost in it
		"drag_every": 9.0,  # TUNING (not in GDD) s
		"drag_reach": 230.0,  # TUNING (not in GDD) px
		"drag_count": 2,  # TUNING (not in GDD) summons per drag; first pass 3
		"drag_telegraph": 0.9,  # TUNING (not in GDD) s the marks glow
		"drag_speed": 150.0,  # TUNING (not in GDD) px/s
		"drag_hold": 2.5,  # TUNING (not in GDD) s a rope holds at most
		"drown_damage": 14.0,  # TUNING (not in GDD) before the time scaling; first pass 22
		"slam_every": 6.0,  # TUNING (not in GDD) s
		"slam_trigger": 30.0,  # TUNING (not in GDD) px edge to edge
		"slam_windup": 0.9,  # TUNING (not in GDD) s
		"slam_radius": 70.0,  # TUNING (not in GDD) px
		"slam_damage_player": 11.0,  # TUNING (not in GDD) before the time scaling
		"slam_damage_summon": 12.0,  # TUNING (not in GDD) before the time scaling
		"slam_push": 30.0,  # TUNING (not in GDD) px summons are thrown
		"advance_range": 380.0,  # TUNING (not in GDD) px
		"advance_speed_mult": 1.8,  # TUNING (not in GDD)
		"reward_xp": 300,  # TUNING (not in GDD) as the Gatekeeper
		"reward_crystals": 14,  # TUNING (not in GDD)
	},
	# Isolde's sister (BossIsolde spawns three in her phase 2; female, her
	# image in her own three colours, IsoldeData.SISTER_TINTS). A ranged witch:
	# hex bolts (the shared shot), and every circle_every s a hex circle under
	# the nearest summon of the ring (WitchHexes.cast_circle(), the witches'
	# one circle path). Her HP is set by Isolde (a third of the bar between her
	# phase 2 and 3); max_hp below is only the fallback of a forced spawn.
	"isolde_sister": {
		"display_name": "Sister of the Red Moon",
		"max_hp": 900.0,  # TUNING (not in GDD) fallback; Isolde sets each sister's life
		"move_speed": 52.0,  # TUNING (not in GDD) px/s
		"damage": 6.0,  # TUNING (not in GDD) a hex bolt, before the time scaling
		"attack_interval": 1.8,  # TUNING (not in GDD) s
		"attack_range": 150.0,  # TUNING (not in GDD) px
		"radius": 14.0,  # TUNING (not in GDD) px
		"armor": 0.1,  # TUNING (not in GDD)
		"xp": 0,  # Isolde's burst pays for the fight.
		"behavior": "ranged",
		"projectile_speed": 240.0,  # TUNING (not in GDD) px/s
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.9,  # TUNING (not in GDD) 0..1, as the boss
		"mass": 6.0,  # TUNING (not in GDD)
		"slow_resist": 0.5,  # TUNING (not in GDD) like a boss
		"faction": CourtEnemyData.FACTION,
		"kit": "isolde_sister",
		"feeds": 0.25,  # Owner-approved: not a vampire (a witch): 25%
		"circle_every": 9.0,  # TUNING (not in GDD) s
		"circle_radius": 62.0,  # TUNING (not in GDD) px
		"circle_windup": 1.2,  # TUNING (not in GDD) s
		"circle_time": 4.0,  # TUNING (not in GDD) s
		"circle_heal": 0.04,  # TUNING (not in GDD) share of max HP per s for the Court inside
		"circle_drain": 5.0,  # TUNING (not in GDD) per s per summon, before the time scaling
		"circle_reach": 220.0,  # TUNING (not in GDD) px from her
	},
	# Structure: a HEX STONE (the Witchwood's director raises them, three a
	# zone). Owner-approved proposal: "standing stones that power the covens'
	# circles; destroy one and its zone's covens cannot cast". While it stands,
	# a coven near it (WitchHexData.STONES power_range) may cast without the
	# Blood Moon; broken, it leaves dead ground (dead_range) where no coven casts
	# (WitchHexes; HexStoneKit). Immovable; the army breaks it like any structure.
	"hex_stone": {
		"display_name": "Hex Stone",
		"max_hp": 320.0,  # TUNING (not in GDD) before the time / stage scaling (a coffin 260)
		"move_speed": 0.0,
		"damage": 0.0,
		"attack_interval": 1.0,
		"attack_range": 0.0,
		"radius": 13.0,  # TUNING (not in GDD) px
		"armor": 0.15,  # TUNING (not in GDD) stone
		"xp": 8,  # TUNING (not in GDD)
		"behavior": "structure",
		"projectile_speed": 0.0,
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.75,  # TUNING (not in GDD) worth breaking
		"mass": 60.0,  # Immovable.
		"is_structure": true,
		"faction": CourtEnemyData.FACTION,
		"kit": "hex_stone",
	},
}
