## ArchiveEnemyData — immutable design data for the Ancient Eye kinds that
## join on The Hollow Archive (Stage 5) (GDD §15.0 "Act II: the Ancient Eye"): Scribe of the Unwritten, Ink Wraith, Pilgrim of the Spore, Gibbering Mass and the Librarian.
## Each kind stays in play on the stages after it, and any stage can spawn it
## (--spawn=kind@T). EnemyDirector.enemy_def() looks these rows up after
## EyeEnemyData. Rows have every key of an EyeEnemyData.ENEMIES row (same
## meaning). Empty until the stage's kinds are built (Act II phase 2).
## The GDD gives no numbers: everything is TUNING (not in GDD).
class_name ArchiveEnemyData
extends RefCounted

## Kind id -> design row.
const ENEMIES := {
}
