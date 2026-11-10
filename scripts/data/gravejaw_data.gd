## GravejawData — immutable design data for OLD GRAVEJAW, THE TYRANT KING, the
## boss of the Last Day, the Age of Titans' finale (temporary Act XIV, final
## slot XIV; GDD §15.0 "Old Gravejaw, the Tyrant King (Act XIV phase 2)";
## owner-approved proposal docs/proposals/NEW_ACTS_AND_ORDER.md Part 2, "Stage
## C: The Last Day": "Boss: Old Gravejaw, the Tyrant King (male). The Roar: a
## roar that stuns the ring and calls every beast on the map to him. The Hunt:
## he hunts the necromancer, ignoring summons; he bites through the ring and
## swallows. The Last Day: the sky is white. He turns toward the impact and
## rampages toward the Mound."). BossGravejaw
## (scripts/enemies/primeval/boss_gravejaw.gd, loaded by name for the boss id
## "gravejaw") reads it. The greatest tyrant, scarred, a lava glow in the
## throat (art `primeval/gravejaw`, 128x104; pose 1 the roar; a beast: no
## figure style). His fight:
##   * THE HUNT (all fight): he walks at the nearest necromancer and only at
##     him (no summon draws him; blockers still hold his body). Every
##     bite_every s, with the necromancer within bite_trigger px, he rears for
##     bite_windup s (a line shows the lunge) and BITES THROUGH THE RING:
##     bite_speed px/s up to bite_len px at him; every grounded summon on the
##     line takes bite_damage_summon (x the time scaling x Thick Marrow) and is
##     thrown bite_knock px aside, the first one he reaches is SWALLOWED
##     (TyrantKit.swallow(): held swallow_time s inside him, swallow_dps a
##     second; cut out by his losing cut_share of his max HP); the necromancer
##     takes bite_damage.
##   * THE ROAR (every roar_every s): he rears for roar_windup s (a circle
##     shows it), then every grounded summon within roar_radius px of him is
##     stunned roar_stun s (TyrantKit.roar()), every grazing herd within
##     call_reach px stampedes away from him (Herds.launch(), the one start)
##     and the beasts answer: `call` (groups of {kind, count}) come from the
##     spawn ring on his side.
##   * THE LAST DAY (from last_day_time game s, the sky white): he turns from
##     the necromancer toward the impact and RAMPAGES rampage_speed px/s to the
##     MOUND, mound_dist px away on his far side, goring every summon in his
##     path once (HornchargerKit.gore(): rampage_damage_summon, rampage_stun,
##     rampage_knock; the necromancer rampage_damage); at the Mound he stands
##     and roars at the sky, taking x mound_taken damage (exposed: the last
##     chance to slay him), roaring every roar_every s.
##   * THE IMPACT (the Extinction): a Gravejaw still alive drops to 10% HP and
##     lies broken out of reach (on_extinction(): he takes no damage again);
##     only a Gravejaw slain before the impact gives his spell.
## Beaten: a short ending text (no epilogue part until the reorder pass).
## Killing him drops a big XP burst and the boss chest; slaying him unlocks
## Meteor Call, Cosmic Dust, the Bonehorn and Petrified Horns (UnlockData,
## boss "gravejaw"). The GDD gives no numbers: everything is TUNING (not in
## GDD) unless marked as the owner-approved proposal.
class_name GravejawData
extends RefCounted

## Special ids in report order (the autotest "boss attacks" line, boss_atk_<id>).
const SPECIALS := ["bite", "roar", "last_day"]

## Sprite key of his art (assets/sprites/primeval/gravejaw.png, 128x104, walk
## strip; pose 1 `gravejaw_roar`, the roar).
const SPRITE: String = "primeval/gravejaw"
## Damage tag of his bite (stats, the death line).
const BITE_SOURCE: String = "gravejaw_bite"
## Damage tag of his rampage (stats, the death line).
const RAMPAGE_SOURCE: String = "gravejaw_rampage"
## Seconds the ending line (the arrival's defeat_banner) stays on the HUD banner.
const ENDING_BANNER_TIME: float = 10.0  # TUNING (not in GDD)
## The short ending text shown when he falls (HUD announce: title, line, text).
const ENDING_ANNOUNCE := ["THE TYRANT KING FALLS", "Old Gravejaw, the Tyrant King, falls under the white sky.", "The beasts of the world fall silent. Above them the meteor fills the heavens, and it answers to you."]  # TUNING (not in GDD) the words

## Old Gravejaw's base max HP (x the boss HP multiplier and the stage's HP multiplier).
const MAX_HP: float = 10500.0  # TUNING (not in GDD) as Scarmaw: the act's last boss on the hardest stage (x the stage's HP multiplier)

## Old Gravejaw's design row.
const BOSS := {
	"display_name": "Old Gravejaw, the Tyrant King",
	"max_hp": MAX_HP,
	"move_speed": 50.0,  # TUNING (not in GDD) px/s; a titan's walk
	"damage": 12.0,  # TUNING (not in GDD) a bite in reach, before the time scaling
	"attack_interval": 1.4,  # TUNING (not in GDD) s
	"attack_range": 18.0,  # TUNING (not in GDD) px
	"radius": 28.0,  # TUNING (not in GDD) px (the sprite 128x104)
	"armor": 0.25,  # TUNING (not in GDD) a scarred hide
	"xp": 0,
	"behavior": "melee",
	"projectile_speed": 0.0,
	"undead_damage_mult": 1.0,
	"heal_amount": 0.0,
	"heal_interval": 0.0,
	"heal_radius": 0.0,
	"target_priority": 0.9,  # GDD §4.11 archers prioritise the boss
	"mass": 18.0,  # TUNING (not in GDD)
	"faction": PrimevalEnemyData.FACTION,
	"group": "titans",  # The Tyrant King (the reports).
	"reward_xp": 600,  # TUNING (not in GDD) as Scarmaw and Old Ironbrow
	"reward_crystals": 26,  # TUNING (not in GDD)
	"slow_resist": 0.5,  # TUNING (not in GDD) like every boss
	"recover_time": 1.0,  # TUNING (not in GDD) s he stands after a bite (the army's window)
	"advance_range": 460.0,  # TUNING (not in GDD) px; farther than this he strides faster
	"advance_speed_mult": 1.8,  # TUNING (not in GDD)
	"arrive_banner": "THE HUNT: Old Gravejaw hunts only you, and he bites through your ring!",  # TUNING (not in GDD)
	# The Hunt: the bite.
	"bite_first": 5.0,  # TUNING (not in GDD) s after he arrives
	"bite_every": 7.0,  # TUNING (not in GDD) s between two bites
	"bite_trigger": 300.0,  # TUNING (not in GDD) px to the necromancer for a bite to start
	"bite_windup": 0.9,  # TUNING (not in GDD) s he rears (the line shows)
	"bite_speed": 360.0,  # TUNING (not in GDD) px/s
	"bite_len": 260.0,  # TUNING (not in GDD) px at most (through the Bone Ring)
	"bite_damage": 12.0,  # TUNING (not in GDD) to the necromancer, before the time scaling
	"bite_damage_summon": 9.0,  # TUNING (not in GDD) to each summon on the line, before the time scaling
	"bite_knock": 36.0,  # TUNING (not in GDD) px a summon on the line is thrown aside
	"swallow_time": 4.0,  # Owner-approved proposal: the Tyrant's swallow ("a summon for 4 s")
	"swallow_dps": 7.0,  # TUNING (not in GDD) damage a second to the swallowed summon, before the time scaling
	"cut_share": 0.04,  # TUNING (not in GDD) share of his max HP lost that frees it (a titan's belly is tougher; his HP is huge)
	# The Roar.
	"roar_first": 9.0,  # TUNING (not in GDD) s after he arrives
	"roar_every": 14.0,  # TUNING (not in GDD) s between two roars
	"roar_windup": 1.0,  # TUNING (not in GDD) s of telegraph
	"roar_radius": 220.0,  # Owner-approved proposal: "a roar that stuns the ring"; TUNING (not in GDD) px round him
	"roar_stun": 1.2,  # TUNING (not in GDD) s (the Tyrant's 1.2)
	"call_reach": 700.0,  # Owner-approved proposal: "calls every beast on the map to him"; TUNING (not in GDD) px: the herds within it stampede
	"call": [{"kind": "razorclaw", "count": 4}, {"kind": "scuttler", "count": 8}],  # TUNING (not in GDD) the beasts that answer each roar
	"roar_banner": "THE ROAR: Old Gravejaw calls every beast on the map!",  # TUNING (not in GDD)
	# The Last Day.
	"last_day_time": 1140.0,  # Owner-approved proposal: "the sky is white"; TUNING (not in GDD) game s (1:00 left)
	"mound_dist": 300.0,  # TUNING (not in GDD) px from him to the Mound, on his far side from the necromancer
	"rampage_speed": 260.0,  # TUNING (not in GDD) px/s
	"rampage_damage": 10.0,  # TUNING (not in GDD) to the necromancer, before the time scaling
	"rampage_damage_summon": 8.0,  # TUNING (not in GDD) to each summon in his path, before the time scaling
	"rampage_stun": 0.6,  # TUNING (not in GDD) s
	"rampage_knock": 40.0,  # TUNING (not in GDD) px
	"mound_taken": 1.3,  # TUNING (not in GDD) x damage he takes at the Mound (exposed)
	"last_day_banner": "THE LAST DAY: the sky is white! Old Gravejaw turns toward the impact: slay him before it falls!",  # TUNING (not in GDD)
}
