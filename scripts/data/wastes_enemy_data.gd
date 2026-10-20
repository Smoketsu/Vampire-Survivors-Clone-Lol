## WastesEnemyData — immutable design data for the Electronic Empire kinds that join
## on the Scrap Wastes (Stage 7) (Act III; GDD §15.0 "Act III foundation (phase 1)"): Aegis Bot, Mortar Walker, Arc Engineer, Valkyrie Duelist, Sentry Turret or Juggernaut (the stage agents choose).
## Each kind stays in play on the stages after it, and any stage can spawn it
## (--spawn=kind@T). EnemyDirector.empire_def() looks these rows up after
## EmpireEnemyData. Rows have every key of an EmpireEnemyData.ENEMIES row (same
## meaning; "kit" ids load scripts/enemies/empire/<kit>_kit.gd; "body" is
## "machine" or "cyborg"). Empty until the stage's kinds are built (Act III
## phase 2).
## The GDD gives no numbers: everything is TUNING (not in GDD).
class_name WastesEnemyData
extends RefCounted

## Kind id -> design row.
const ENEMIES := {
}
