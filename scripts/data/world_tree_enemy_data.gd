## WorldTreeEnemyData — the kinds of The World-Tree (stage 3, the campaign finale) (temporary Act XV,
## the Turning Year; GDD §15.0 "The Turning Year foundation (phase 1)").
## EMPTY until phase 2 adds them: the Gardener of Roots (the miniboss) and the Green Mother (the Turning, the Burial, the Last Claim; docs/year/BRIEF_PHASE2.md).
## EnemyDirector.wild_def() looks these rows up after WildEnemyData.
## Rows have every key of a WildEnemyData.ENEMIES row (same meaning; "kit"
## ids load scripts/enemies/wild/<kit>_kit.gd, unique across every kit
## folder; "group", "season", "planter" switch the shared rules on for the
## kind).
class_name WorldTreeEnemyData
extends RefCounted

## Kind id -> design row (phase 2 fills it).
const ENEMIES := {}
