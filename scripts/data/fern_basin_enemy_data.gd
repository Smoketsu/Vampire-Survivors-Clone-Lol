## FernBasinEnemyData — the kinds of The Fern Basin (stage 1) (temporary Act XIV,
## the Age of Titans; GDD §15.0 "The Age of Titans foundation (phase 1)").
## EMPTY until phase 2 adds them: the Tar Seeps (TerrainSlow), the Bog Croc, Ironjaw the Nest Mother (the miniboss) and Scarmaw, the Great Raptor (the Hunt, the Ambush, Blood Up).
## EnemyDirector.primeval_def() looks these rows up after PrimevalEnemyData.
## Rows have every key of a PrimevalEnemyData.ENEMIES row (same meaning; "kit"
## ids load scripts/enemies/primeval/<kit>_kit.gd, unique across every kit
## folder; "group", "pack", "herd", "scavenger" switch the shared rules on for
## the kind).
class_name FernBasinEnemyData
extends RefCounted

## Kind id -> design row (phase 2 fills it).
const ENEMIES := {}
