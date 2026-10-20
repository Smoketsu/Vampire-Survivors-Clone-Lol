## AssemblyEnemyData — immutable design data for the Electronic Empire kinds that join
## on the Assembly Halls (Stage 8) (Act III; GDD §15.0 "Act III foundation (phase 1)"): the remaining Empire kinds the stage agents assign here.
## Each kind stays in play on the stages after it, and any stage can spawn it
## (--spawn=kind@T). EnemyDirector.empire_def() looks these rows up after
## EmpireEnemyData. Rows have every key of an EmpireEnemyData.ENEMIES row (same
## meaning; "kit" ids load scripts/enemies/empire/<kit>_kit.gd; "body" is
## "machine" or "cyborg"). Empty until the stage's kinds are built (Act III
## phase 2).
## The GDD gives no numbers: everything is TUNING (not in GDD).
class_name AssemblyEnemyData
extends RefCounted

## Kind id -> design row.
const ENEMIES := {
}
