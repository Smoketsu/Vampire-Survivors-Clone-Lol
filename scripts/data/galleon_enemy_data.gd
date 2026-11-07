## GalleonEnemyData — the kinds of the Treasure Galleon only (Act X, the Black
## Tide; GDD §15.0 "The Treasure Galleon (Act X phase 2)"); rows as
## CorsairEnemyData's (same keys, kits in scripts/enemies/corsair/).
## EnemyDirector.corsair_def() looks them up after CorsairEnemyData.
##   old_hollow_eye — OLD HOLLOW-EYE, the stage's miniboss (a creature): the
##                    kraken itself, a swimmer like the Kraken Arm but boss-
##                    sized: it circles the hull submerged (SeaStrikes), its
##                    tentacle strikes grab a summon each (the shared
##                    "tentacle" strike with a larger circle), and it raises
##                    Kraken Arms beside it ("arm_every" s, at most
##                    "arms_max"); hittable only while surfaced. It registers
##                    as the HUD's miniboss (OldHollowEyeKit).
##   cursed_coin    — Admiral Marrec's GOLD FEVER: a cursed coin (a 1 HP
##                    structure: any hit clears it) that keeps a barrier on
##                    the crew within "aura" px (Enemy.holy_shield, the one
##                    shield path) and cuts the Admiral's damage taken while
##                    she stands near it (CursedCoinKit, BossMarrec).
## Optional keys of these rows (absent = off):
##   reward_xp / reward_crystals — a miniboss's XP burst.
##   arm_every / arms_max — Old Hollow-Eye's kraken arms (s between two, most alive).
##   aura / shield / life / pulse — the coin's barrier reach (px), barrier HP
##                    (x the enemies' HP scaling), lifetime (s), refresh (s).
## Every number is TUNING (not in GDD) unless marked as the owner-approved proposal.
class_name GalleonEnemyData
extends RefCounted

## Kind id of Old Hollow-Eye (the miniboss).
const HOLLOW_EYE: String = "old_hollow_eye"
## Kind id of Marrec's cursed coin (Gold Fever).
const COIN: String = "cursed_coin"

## The stage's own kinds, keyed by kind id.
const ENEMIES := {
	# Old Hollow-Eye (see the header): the miniboss of the Treasure Galleon.
	# Brief: "the kraken's arm (tentacles in the rail band, every tentacle
	# grabs: SeaStrikes with a boss-sized tentacle)".
	"old_hollow_eye": {
		"display_name": "Old Hollow-Eye",  # Owner-approved proposal
		"max_hp": 1500.0,  # TUNING (not in GDD) a miniboss hittable only while surfaced (the Warbeast 2,100)
		"move_speed": 30.0,  # TUNING (not in GDD) px/s (SeaStrikes moves it)
		"damage": 0.0,  # TUNING (not in GDD) its strikes deal the damage
		"attack_interval": 1.0,  # TUNING (not in GDD) s
		"attack_range": 0.0,  # TUNING (not in GDD) px
		"radius": 26.0,  # TUNING (not in GDD) px (the sprite is drawn larger)
		"armor": 0.15,  # TUNING (not in GDD)
		"xp": 0,  # TUNING (not in GDD) its XP is the burst below
		"behavior": "structure",
		"projectile_speed": 0.0,  # TUNING (not in GDD) px/s (0 = none)
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 1.0,  # TUNING (not in GDD) 0..1: kill it while it is up
		"mass": 80.0,  # TUNING (not in GDD)
		"faction": CorsairEnemyData.FACTION,
		"kit": "old_hollow_eye",
		"is_structure": true,  # A swimmer like the Kraken Arm (never shoved, never drowned)
		"miniboss": true,  # The miniboss flag (Enemy.is_miniboss: the HUD bar, the chest, boss multipliers)
		"water": true,  # A swimmer (SeaStrikes)
		"strike": {"type": "tentacle", "radius": 46.0, "strike_every": 4.0, "reach": 420.0, "telegraph": 1.2, "surface_time": 3.5,  # Brief: a boss-sized tentacle; TUNING (not in GDD) the rest
			"first_strike": 2.0, "dmg_summon": 10.0, "dmg_player": 8.0, "dmg_enemy": 20.0},  # TUNING (not in GDD)
		"arm_every": 11.0,  # TUNING (not in GDD) s between two kraken arms it raises
		"arms_max": 3,  # TUNING (not in GDD) kraken arms alive at once (its own and the timeline's)
		"reward_xp": 300,  # TUNING (not in GDD) as the Warbeast's burst
		"reward_crystals": 14,  # TUNING (not in GDD)
	},  # Old Hollow-Eye.
	# Marrec's cursed coin (Gold Fever; owner-approved proposal: "cursed coins
	# that become short barriers round her marines; area damage clears them").
	# A 1 HP structure: any hit clears it, so an area spell clears a whole
	# scatter at once. No XP, no drop.
	"cursed_coin": {
		"display_name": "Cursed Coin",  # Owner-approved proposal
		"max_hp": 1.0,  # TUNING (not in GDD) any hit clears it
		"move_speed": 0.0,  # TUNING (not in GDD) px/s
		"damage": 0.0,  # TUNING (not in GDD)
		"attack_interval": 1.0,  # TUNING (not in GDD) s
		"attack_range": 0.0,  # TUNING (not in GDD) px
		"radius": 6.0,  # TUNING (not in GDD) px
		"armor": 0.0,  # TUNING (not in GDD)
		"xp": 0,  # TUNING (not in GDD)
		"behavior": "structure",
		"projectile_speed": 0.0,  # TUNING (not in GDD) px/s (0 = none)
		"undead_damage_mult": 1.0,
		"heal_amount": 0.0,
		"heal_interval": 0.0,
		"heal_radius": 0.0,
		"target_priority": 0.7,  # TUNING (not in GDD) 0..1
		"mass": 60.0,  # TUNING (not in GDD)
		"faction": CorsairEnemyData.FACTION,
		"kit": "cursed_coin",
		"is_structure": true,
		"aura": 80.0,  # TUNING (not in GDD) px: the crew within this of a coin keep a barrier
		"shield": 18.0,  # TUNING (not in GDD) barrier HP x the enemies' HP scaling
		"life": 14.0,  # TUNING (not in GDD) s before an unbroken coin fades
		"pulse": 1.0,  # TUNING (not in GDD) s between two barrier refreshes
	},  # The Cursed Coin.
}
