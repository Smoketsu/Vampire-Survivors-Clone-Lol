## GreatPlainEnemyData — the kinds of The Great Plain (stage 2) (temporary Act XIV,
## the Age of Titans; GDD §15.0 "The Age of Titans foundation (phase 1)").
## EMPTY until phase 2 adds them: the Watering Hole and the Canyon, the Horncharger, the Clubtail, Mother Clubtail (the miniboss) and Old Ironbrow, the Horned Titan (the Herd, the Charge, the Break).
## EnemyDirector.primeval_def() looks these rows up after PrimevalEnemyData.
## Rows have every key of a PrimevalEnemyData.ENEMIES row (same meaning; "kit"
## ids load scripts/enemies/primeval/<kit>_kit.gd, unique across every kit
## folder; "group", "pack", "herd", "scavenger" switch the shared rules on for
## the kind).
class_name GreatPlainEnemyData
extends RefCounted

## Kind id -> design row (phase 2 fills it).
const ENEMIES := {}
