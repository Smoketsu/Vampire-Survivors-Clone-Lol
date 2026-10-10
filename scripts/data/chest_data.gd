## ChestData — designer-tunable data for TREASURE CHESTS (user request, the
## Vampire Survivors convention; also the GDD §6.1 "special elite reward"
## that the evolution recipes ask for). Every number is TUNING (not in GDD).
## ChestManager drops and collects chests; ChestPanel shows the reveal.
##
## Drops:
##   * an elite drops a chest with ELITE_CHANCE,
##   * Sir Alaric always drops one,
##   * pity: when PITY_TIME s pass without a chest, the next kill of ANY
##     regular enemy drops one (so one appears about every 2-3 minutes),
##   * no chests from Reckoning enemies or after 0:00 (like power-ups),
##   * chests never despawn; at most MAX_LIVE lie on the ground (a roll at
##     the cap is lost, the boss chest always appears).
## Opening: walking over a chest (within PICKUP_RADIUS px of the
## necromancer's body edge) pauses the run and opens it. It grants 1, 3 or 5
## upgrades (COUNT_WEIGHTS), each drawn from the normal level-up pool with
## the existing weighted-card logic (AbilityManager.chest_rewards), with
## every ready EVOLUTION granted first: evolutions are delivered ONLY by
## chests, never as level-up cards. The Profane Pact (a difficulty choice)
## is never granted by a chest. When nothing can be upgraded the chest
## gives the Dark Restoration heal instead.
class_name ChestData
extends RefCounted

## Chest drop chance of an elite kill.
const ELITE_CHANCE: float = 0.35  # TUNING (not in GDD)
## Seconds without a chest after which the next regular kill drops one.
const PITY_TIME: float = 150.0  # TUNING (not in GDD)
## Most chests lying on the ground at once.
const MAX_LIVE: int = 3  # TUNING (not in GDD)
## Collection distance (px) from the necromancer's body edge.
const PICKUP_RADIUS: float = 12.0  # TUNING (not in GDD)
## Half-width (px) of the chest's world shape.
const SIZE: float = 11.0  # TUNING (not in GDD)
## Upgrades granted -> relative weight (weighted toward 1).
const COUNT_WEIGHTS := {1: 70.0, 3: 24.0, 5: 6.0}  # TUNING (not in GDD)
## Seconds the reveal animation takes before the reward rows appear.
const REVEAL_TIME: float = 0.7  # TUNING (not in GDD)
## Seconds between two reward rows appearing.
const ROW_INTERVAL: float = 0.18  # TUNING (not in GDD)
## Radius (px) in which the autotest walks to a chest (larger than drops).
const AUTOTEST_SEEK_RADIUS: float = 450.0  # TUNING (not in GDD)
