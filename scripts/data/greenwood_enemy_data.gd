## GreenwoodEnemyData — the kinds of The Greenwood (stage 1) (temporary Act XV,
## the Turning Year; GDD §15.0 "The Turning Year foundation (phase 1)").
## EMPTY until phase 2 adds them: the sacred groves (blighted in 10 s), the Huntsman of the Wild Hunt (the miniboss, three riders in a sweeping line) and the Stag King (the Hunt, the Rut, the Antler Crown).
## EnemyDirector.wild_def() looks these rows up after WildEnemyData.
## Rows have every key of a WildEnemyData.ENEMIES row (same meaning; "kit"
## ids load scripts/enemies/wild/<kit>_kit.gd, unique across every kit
## folder; "group", "season", "planter" switch the shared rules on for the
## kind).
class_name GreenwoodEnemyData
extends RefCounted

## Kind id -> design row (phase 2 fills it).
const ENEMIES := {}
