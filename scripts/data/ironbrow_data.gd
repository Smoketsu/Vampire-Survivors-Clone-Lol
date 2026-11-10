## IronbrowData — immutable design data for OLD IRONBROW, THE HORNED TITAN, the
## boss of the Great Plain (temporary Act XIV, the Age of Titans, final slot
## XIV; GDD §15.0 "Old Ironbrow, the Horned Titan (Act XIV phase 2)";
## owner-approved proposal docs/proposals/NEW_ACTS_AND_ORDER.md Part 2, "Stage
## B: The Great Plain": "Boss: Old Ironbrow, the Horned Titan (male
## ceratopsian). The Herd: he leads a stampede himself; the front runs behind
## him. The Charge: straight-line charges at the necromancer. Missing into a
## rock stuns him for 3 s. The Break: he snaps one horn on a rock; the shards
## fly as 3 short lines, then he charges with the stump."). BossIronbrow
## (scripts/enemies/primeval/boss_ironbrow.gd, loaded by name for the boss id
## "ironbrow") reads it. A giant ceratopsian (art `primeval/ironbrow`, 112x80;
## `primeval/ironbrow_broken` after the Break; a beast: no figure style). His
## fight:
##   * THE CHARGE (all fight): every charge_every s, once the necromancer is
##     within charge_trigger px, he lowers his horns for charge_windup s (a
##     line shows the charge) and CHARGES at the necromancer: charge_speed
##     px/s up to charge_len px; every grounded summon and necromancer he
##     crosses is hit once (HornchargerKit.gore(), the one charge hit): a
##     summon takes charge_damage_summon (x the time scaling x Thick Marrow)
##     and is stunned charge_stun s and thrown charge_knock px aside; the
##     necromancer takes charge_damage. A charge that runs into a rock stops
##     there and STUNS HIM rock_stun s (the owner-approved 3 s).
##   * THE HERD (every herd_every-th charge): he leads a stampede: his herd
##     (herd_size beasts of herd_kinds, brought herd_back px behind him when he
##     has none near, at most herd_cap herd beasts alive) stampedes the
##     charge's way through the one stampede start (Herds.launch()), so the
##     front runs behind him; that charge's windup is the stampede's dust line
##     (Herds "lead").
##   * THE BREAK (below break_hp, once): he turns on the nearest rock within
##     break_search px (none near: he stamps where he stands) and charges it;
##     the horn SNAPS: `shards` short lines shard_len px long fly from the
##     rock toward the necromancer, shard_spread degrees apart, shown for
##     shard_warn s; every summon and necromancer within shard_width px of a
##     line then takes shard_damage_summon / shard_damage. From then on he
##     CHARGES WITH THE STUMP: x stump_speed faster, every stump_every s.
## Beaten: a short ending text (no epilogue part until the reorder pass).
## Killing him drops a big XP burst and the boss chest; slaying him unlocks
## Stampede, Calcified Hide and so the Herd-Warden (UnlockData, boss
## "ironbrow"). The GDD gives no numbers: everything is TUNING (not in GDD)
## unless marked as the owner-approved proposal.
class_name IronbrowData
extends RefCounted

## Special ids in report order (the autotest "boss attacks" line, boss_atk_<id>).
const SPECIALS := ["charge", "herd", "break"]

## Sprite key of his art (assets/sprites/primeval/ironbrow.png, 112x80, walk
## strip; pose 1 `ironbrow_broken`, the still after the Break).
const SPRITE: String = "primeval/ironbrow"
## Damage tag of his charge (stats, the death line).
const CHARGE_SOURCE: String = "ironbrow_charge"
## Damage tag of the Break's horn shards (stats, the death line).
const SHARD_SOURCE: String = "ironbrow_shard"
## Seconds the ending line (the arrival's defeat_banner) stays on the HUD banner.
const ENDING_BANNER_TIME: float = 10.0  # TUNING (not in GDD)
## The short ending text shown when he falls (HUD announce: title, line, text).
const ENDING_ANNOUNCE := ["THE HERD BREAKS", "Old Ironbrow, the Horned Titan, falls in the dust.", "The herds scatter across the plain, and the white streak burns over the horizon."]  # TUNING (not in GDD) the words
## The ending text when he falls during the Stampede of Ash.
const LATE_ANNOUNCE := ["THE HERD BREAKS", "Old Ironbrow falls as the sky burns.", "The plain runs without its leader now, straight into the fire."]  # TUNING (not in GDD) the words

## Old Ironbrow's base max HP (x the boss HP multiplier and the stage's HP multiplier).
const MAX_HP: float = 11000.0  # TUNING (not in GDD) Scarmaw's 10,500 and a step (x the stage's 2.3)

## Old Ironbrow's design row.
const BOSS := {
	"display_name": "Old Ironbrow, the Horned Titan",
	"max_hp": MAX_HP,
	"move_speed": 48.0,  # TUNING (not in GDD) px/s; a titan's walk
	"damage": 13.0,  # TUNING (not in GDD) a horn in reach, before the time scaling
	"attack_interval": 1.4,  # TUNING (not in GDD) s
	"attack_range": 16.0,  # TUNING (not in GDD) px
	"radius": 26.0,  # TUNING (not in GDD) px (the sprite 112x80)
	"armor": 0.25,  # TUNING (not in GDD) a bone frill
	"xp": 0,
	"behavior": "melee",
	"projectile_speed": 0.0,
	"undead_damage_mult": 1.0,
	"heal_amount": 0.0,
	"heal_interval": 0.0,
	"heal_radius": 0.0,
	"target_priority": 0.9,  # GDD §4.11 archers prioritise the boss
	"mass": 16.0,  # TUNING (not in GDD)
	"faction": PrimevalEnemyData.FACTION,
	"group": "titans",  # The Horned Titan (the reports).
	"reward_xp": 600,  # TUNING (not in GDD) as Scarmaw
	"reward_crystals": 26,  # TUNING (not in GDD)
	"slow_resist": 0.5,  # TUNING (not in GDD) like every boss
	"recover_time": 0.6,  # TUNING (not in GDD) s he stands after a charge
	"advance_range": 460.0,  # TUNING (not in GDD) px; farther than this he strides faster
	"advance_speed_mult": 1.8,  # TUNING (not in GDD)
	"arrive_banner": "THE HERD: Old Ironbrow leads the stampede at you! Make him charge into a rock!",  # TUNING (not in GDD)
	# The Charge.
	"charge_first": 5.0,  # TUNING (not in GDD) s after he arrives
	"charge_every": 7.5,  # TUNING (not in GDD) s between two charges
	"charge_trigger": 520.0,  # TUNING (not in GDD) px to the necromancer for a charge to start
	"charge_windup": 1.0,  # TUNING (not in GDD) s he lowers his horns (the line shows)
	"charge_speed": 340.0,  # TUNING (not in GDD) px/s (the herd's front runs at Herds run_speed behind him)
	"charge_len": 460.0,  # TUNING (not in GDD) px at most (through the ring)
	"charge_damage": 11.0,  # TUNING (not in GDD) to the necromancer, before the time scaling
	"charge_damage_summon": 12.0,  # TUNING (not in GDD) to each summon he crosses, before the time scaling
	"charge_stun": 1.2,  # TUNING (not in GDD) s each summon he crosses is stunned
	"charge_knock": 40.0,  # TUNING (not in GDD) px a summon he crosses is thrown aside
	"rock_stun": 3.0,  # Owner-approved proposal: "missing into a rock stuns him for 3 s"
	# The Herd.
	"herd_every": 2,  # TUNING (not in GDD) every Nth charge leads the herd (the 1st, the 3rd, ...)
	"herd_size": 3,  # TUNING (not in GDD) beasts in his herd
	"herd_kinds": ["duckbill", "longneck", "duckbill"],  # TUNING (not in GDD) one kind per beast (cycled)
	"herd_back": 150.0,  # Owner-approved proposal: "the front runs behind him"; TUNING (not in GDD) px behind him his herd comes on
	"herd_reach": 420.0,  # TUNING (not in GDD) px: his grazing herd this close follows him again (else a new herd comes)
	"herd_cap": 9,  # TUNING (not in GDD) herd beasts alive at most for a new herd of his to come
	"herd_banner": "Old Ironbrow lowers his horns: the herd runs behind him!",  # TUNING (not in GDD)
	# The Break.
	"break_hp": 0.5,  # TUNING (not in GDD) HP share below which he snaps a horn
	"break_search": 420.0,  # TUNING (not in GDD) px he looks round for a rock to charge
	"break_banner": "THE BREAK: Old Ironbrow snaps a horn on the rock! Now he charges with the stump!",  # TUNING (not in GDD)
	"shards": 3,  # Owner-approved proposal: "the shards fly as 3 short lines"
	"shard_len": 240.0,  # TUNING (not in GDD) px each line
	"shard_spread": 28.0,  # TUNING (not in GDD) degrees between two lines
	"shard_width": 14.0,  # TUNING (not in GDD) px half width of a line
	"shard_warn": 0.7,  # TUNING (not in GDD) s the lines show before they strike
	"shard_damage": 10.0,  # TUNING (not in GDD) to the necromancer, before the time scaling
	"shard_damage_summon": 14.0,  # TUNING (not in GDD) to each summon, before the time scaling
	"stump_speed": 1.2,  # Owner-approved proposal: "then he charges with the stump"; TUNING (not in GDD) x the charge's speed
	"stump_every": 5.5,  # TUNING (not in GDD) s between two charges after the Break
}
