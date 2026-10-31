## SilkPalaceEnemyData — immutable design data for the Inferno kinds that
## join on the Palace of Silk and Ash (Stage 17) (Act VI; GDD §15.0 "Act VI foundation (phase 1)"):
## the Twin Succubi (miniboss), the Lilim Witch, as the stage agent chooses (owner-approved proposal
## docs/act6/PROPOSAL.md, "Roster").
## Each kind stays in play on the stages after it, and any stage can spawn it
## (--spawn=kind@T). EnemyDirector.inferno_def() looks these rows up after
## InfernoEnemyData. Rows have every key of an InfernoEnemyData.ENEMIES row
## (same meaning; "kit" ids load scripts/enemies/inferno/<kit>_kit.gd, unique
## across the Eye, Empire, Pantheon, Shogunate and Inferno folders; "demon",
## "flier", "charmer", "damned" switch the shared rules on for the kind). Empty
## until the stage's kinds are built (Act VI phase 2).
## The GDD gives no numbers: everything is TUNING (not in GDD).
class_name SilkPalaceEnemyData
extends RefCounted

## Kind id -> design row.
const ENEMIES := {
}
