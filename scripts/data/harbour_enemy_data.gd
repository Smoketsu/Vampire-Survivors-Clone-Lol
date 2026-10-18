## HarbourEnemyData — immutable design data for the Ancient Eye kinds that
## join on Gullhaven Harbour (Stage 4) (GDD §15.0 "Act II: the Ancient Eye"): Deep Kin, Tide Caller, Netcaster and the Harbourmaster.
## Each kind stays in play on the stages after it, and any stage can spawn it
## (--spawn=kind@T). EnemyDirector.enemy_def() looks these rows up after
## EyeEnemyData. Rows have every key of an EyeEnemyData.ENEMIES row (same
## meaning). Empty until the stage's kinds are built (Act II phase 2).
## The GDD gives no numbers: everything is TUNING (not in GDD).
class_name HarbourEnemyData
extends RefCounted

## Kind id -> design row.
const ENEMIES := {
}
