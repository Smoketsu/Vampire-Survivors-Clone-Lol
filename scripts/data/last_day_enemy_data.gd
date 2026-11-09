## LastDayEnemyData — the kinds of The Last Day (stage 3) (temporary Act XIV,
## the Age of Titans; GDD §15.0 "The Age of Titans foundation (phase 1)").
## EMPTY until phase 2 adds them: Fire from the Sky, the Stormwing, Thunderwing the Sky King (the miniboss), the Tyrant's swallow and roar, Old Gravejaw, the Tyrant King (the Roar, the Hunt, the Last Day) and the Extinction.
## EnemyDirector.primeval_def() looks these rows up after PrimevalEnemyData.
## Rows have every key of a PrimevalEnemyData.ENEMIES row (same meaning; "kit"
## ids load scripts/enemies/primeval/<kit>_kit.gd, unique across every kit
## folder; "group", "pack", "herd", "scavenger" switch the shared rules on for
## the kind).
class_name LastDayEnemyData
extends RefCounted

## Kind id -> design row (phase 2 fills it).
const ENEMIES := {}
