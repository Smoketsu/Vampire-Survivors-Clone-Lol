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
const PICKUP_RADIUS: float = 60.0  # TUNING (not in GDD)
## Distance (px) at which a flying crystal is actually collected.
const COLLECT_RADIUS: float = 14.0  # TUNING (not in GDD)
## Acceleration (px/s^2) of a magnetised crystal toward the player.
const MAGNET_ACCEL: float = 900.0  # TUNING (not in GDD)
## Maximum speed (px/s) of a magnetised crystal.
const MAGNET_MAX_SPEED: float = 650.0  # TUNING (not in GDD)

## XP needed to go from level 1 to level 2.
const XP_BASE: int = 5  # TUNING (not in GDD)
## Additional XP needed per level after that (linear curve).
const XP_GROWTH: int = 7  # TUNING (not in GDD)

## Active ability slots (spells + summon abilities). GDD §6.
const ACTIVE_SLOTS: int = 6
## Passive ability slots. GDD §6.
const PASSIVE_SLOTS: int = 6
## Number of cards offered per level-up. GDD §3/§15 ("three randomized choices").
const CARDS_PER_LEVEL: int = 3

## Fraction of max HP restored by the fallback card shown once everything is
## maxed out ("Dark Restoration").
const FALLBACK_HEAL_FRACTION: float = 0.3  # TUNING (not in GDD)


## Returns the XP required to advance from `level` to `level + 1`.
static func xp_to_next(level: int) -> int:
	return XP_BASE + XP_GROWTH * (level - 1)
