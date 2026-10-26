## SunRoadEnemyData — immutable design data for the Shogunate kinds that
## join on the Road to the Sun (Stage 15) (Act V; GDD §15.0 "Act V foundation (phase 1)"):
## the Kirin and the shrine's guardians (the stage agents choose).
## Each kind stays in play on the stages after it, and any stage can spawn it
## (--spawn=kind@T). EnemyDirector.shogunate_def() looks these rows up after
## ShogunateEnemyData. Rows have every key of a ShogunateEnemyData.ENEMIES row
## (same meaning; "kit" ids load scripts/enemies/shogunate/<kit>_kit.gd, unique
## across the Eye, Empire, Pantheon and Shogunate folders; "night", "draws",
## "ambusher", "ethereal" switch the shared rules on for the kind). Empty until
## the stage's kinds are built (Act V phase 2).
## The GDD gives no numbers: everything is TUNING (not in GDD).
class_name SunRoadEnemyData
extends RefCounted

## Kind id -> design row.
const ENEMIES := {
}
