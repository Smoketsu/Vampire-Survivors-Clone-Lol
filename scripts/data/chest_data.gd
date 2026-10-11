## ChestData — designer-tunable data for TREASURE CHESTS (user request, the
## Vampire Survivors convention; also the GDD §6.1 "special elite reward"
## that the evolution recipes ask for). Every number is TUNING (not in GDD).
## ChestManager drops and collects chests; ChestPanel shows the reveal.
##
## Drops:
##   * an elite drops a chest with ELITE_CHANCE,
##   * Sir Alaric always drops one,
##   * pity: when PITY_TIME s pass without a chest, the next kill of ANY
##     regular enemy drops one; while an evolution is ready (and waiting for
##     its chest) the pity time shrinks to EVOLUTION_PITY_TIME, so the
##     evolution arrives soon after it unlocks,
##   * no chests from Reckoning enemies or after 0:00 (like power-ups),
##   * chests never despawn; at most MAX_LIVE lie on the ground (a roll at
##     the cap is lost, the boss chest always appears).
## Opening: walking over a chest (within PICKUP_RADIUS px of the
## necromancer's body edge) pauses the run and opens it. Before
## LARGE_CHEST_TIME it grants 1 upgrade; from then on 1, 3 or 5
## (COUNT_WEIGHTS, the late-run treat), each drawn from the normal level-up pool with
## the existing weighted-card logic (AbilityManager.chest_rewards), with
## every ready EVOLUTION granted first: evolutions are delivered ONLY by
## chests, never as level-up cards. A chest only UPGRADES items the player
## already owns (GRANTS_NEW_ITEMS): it never puts a new spell, summon class
## or passive into an empty slot. The Profane Pact (a difficulty choice)
## is never granted by a chest. When nothing can be upgraded the chest
## gives the Dark Restoration heal instead.
class_name ChestData
extends RefCounted

## False (survivor-genre convention, combined balance pass): a chest draws
## only upgrades of items the player already owns, plus ready evolutions and
## the Dark Restoration fallback. With 7 spells and 8 summon classes in the
## pool, chests that could grant NEW items filled slots a build had planned
## for something else (a chest put Plague Cloud where the army's Mages were
## meant to go, and that army failed to kill Marshal Vael). True restores
## the old behaviour (new items drawn like level-up cards).
const GRANTS_NEW_ITEMS: bool = false  # TUNING (not in GDD)

## Chest drop chance of an elite kill (was 0.35: ~12 chests per run and
## builds complete at ~13:50 instead of ~17:20).
const ELITE_CHANCE: float = 0.10  # TUNING (not in GDD)
## Seconds without a chest after which the next regular kill drops one (was
## 150: pity alone dropped ~6 chests per run).
const PITY_TIME: float = 360.0  # TUNING (not in GDD)
## Pity time while an evolution is ready: its chest comes within about this
## many seconds (evolutions are delivered only by chests).
const EVOLUTION_PITY_TIME: float = 40.0  # TUNING (not in GDD)
## Most chests lying on the ground at once.
const MAX_LIVE: int = 3  # TUNING (not in GDD)
## Collection distance (px) from the necromancer's body edge.
const PICKUP_RADIUS: float = 12.0  # TUNING (not in GDD)
## Half-width (px) of the chest's world shape.
const SIZE: float = 11.0  # TUNING (not in GDD)
## Upgrades granted -> relative weight (weighted toward 1), used from
## LARGE_CHEST_TIME on. Was 70 / 24 / 6 from the start: with ~12 chests that
## added ~17 upgrades and completed builds ~3.5 min early (13:53 vs 17:20).
const COUNT_WEIGHTS := {1: 85.0, 3: 12.0, 5: 3.0}  # TUNING (not in GDD)
## Elapsed seconds before which every chest holds exactly 1 upgrade (3 / 5
## upgrade chests are a late-run treat, so early power stays paced).
const LARGE_CHEST_TIME: float = 900.0  # TUNING (not in GDD) 15:00 elapsed (timer 5:00)
## Seconds the reveal animation takes before the reward rows appear.
const REVEAL_TIME: float = 0.7  # TUNING (not in GDD)
## Seconds between two reward rows appearing.
const ROW_INTERVAL: float = 0.18  # TUNING (not in GDD)
## Radius (px) in which the autotest walks to a chest (larger than drops).
const AUTOTEST_SEEK_RADIUS: float = 450.0  # TUNING (not in GDD)
