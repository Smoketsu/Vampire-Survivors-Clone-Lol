## PlayerData — designer-tunable numbers for the necromancer, the XP curve and
## the ability-slot limits. GDD §5 lists the player statistics but gives no
## values, so most numbers here are prototype guesses (marked TUNING).
class_name PlayerData
extends RefCounted

## Starting and maximum health of the necromancer (HP).
const MAX_HP: float = 120.0  # TUNING (not in GDD)
## Movement speed in px/s. A little faster than summons (82–95 px/s, GDD §23)
## so the army visibly has to keep up, slower than a sprinting Purifier.
const MOVE_SPEED: float = 110.0  # TUNING (not in GDD)
## Collision / hit radius of the necromancer in px.
const RADIUS: float = 10.0  # TUNING (not in GDD)
## Invulnerability window after taking a hit, in seconds.
const IFRAMES: float = 0.5  # TUNING (not in GDD)
## Distance (px) at which XP crystals start flying toward the player.
const PICKUP_RADIUS: float = 120.0  # TUNING (not in GDD)
## Distance (px) at which a flying crystal is actually collected.
const COLLECT_RADIUS: float = 14.0  # TUNING (not in GDD)
## Acceleration (px/s^2) of a magnetised crystal toward the player.
const MAGNET_ACCEL: float = 900.0  # TUNING (not in GDD)
## Maximum speed (px/s) of a magnetised crystal.
const MAGNET_MAX_SPEED: float = 650.0  # TUNING (not in GDD)

## XP needed to go from level 1 to level 2 (first level-up about 20-30 s in).
const XP_BASE: int = 17  # TUNING (not in GDD)
## Piecewise-linear XP curve: each [from_level, growth] row adds `growth` XP
## to the requirement of every level from `from_level` on, until the next
## row. Growth rises in steps, so level-ups slow down over the 20-minute run
## and a focused build completes (every slot maxed, evolutions taken) only
## around 17:00-18:00, never before 15:00 (autotest army policy). Rows are
## sorted by from_level; the first starts at 2.
const XP_GROWTH_BRACKETS := [
	[2, 3],  # TUNING (not in GDD) L2-18: about 4 levels per minute at first
	[19, 4],  # TUNING (not in GDD) L19-35: about 3.4 per minute (5:00-10:00)
	[36, 6],  # TUNING (not in GDD) L36+: about 3 per minute, then slower
]

## Active ability slots (spells + summon abilities). GDD §6.
const ACTIVE_SLOTS: int = 6
## Passive ability slots. GDD §6.
const PASSIVE_SLOTS: int = 6
## Number of cards offered per level-up. GDD §3/§15 ("three randomized choices").
const CARDS_PER_LEVEL: int = 3

## Fraction of max HP restored by the fallback card shown once everything is
## maxed out ("Dark Restoration").
const FALLBACK_HEAL_FRACTION: float = 0.3  # TUNING (not in GDD)


## Returns the XP required to advance from `level` to `level + 1`:
## XP_BASE plus, for every level from 2 to `level`, the growth of the
## XP_GROWTH_BRACKETS row that level falls in.
static func xp_to_next(level: int) -> int:
	var need := XP_BASE  # XP requirement accumulated so far.
	for lvl in range(2, level + 1):
		var growth := 0  # Growth of the bracket `lvl` falls in.
		for row: Array in XP_GROWTH_BRACKETS:
			if lvl >= int(row[0]):
				growth = int(row[1])
		need += growth
	return need
