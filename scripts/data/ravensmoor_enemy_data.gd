## RavensmoorEnemyData — immutable design data for the Court kinds that join on
## Ravensmoor (Stage 19) (Act VII; GDD §15.0 "Act VII foundation (phase 1)"): Old Greymane (miniboss), the Ghoul packs, the Bloated Thrall, as the stage agent chooses
## (owner-approved proposal docs/act7/PROPOSAL.md, "Roster").
## Each kind stays in play on the stages after it, and any stage can spawn it
## (--spawn=kind@T). EnemyDirector.court_def() looks these rows up after
## CourtEnemyData. Rows have every key of a CourtEnemyData.ENEMIES row (same
## meaning; "kit" ids load scripts/enemies/court/<kit>_kit.gd, unique across the
## Eye, Empire, Pantheon, Shogunate, Inferno and Court folders; "feeds",
## "flies", "werebeast", "noble" switch the shared rules on for the kind). Empty
## until the stage's kinds are built (Act VII phase 2).
## The GDD gives no numbers: everything is TUNING (not in GDD).
class_name RavensmoorEnemyData
extends RefCounted

## Kind id -> design row.
const ENEMIES := {
}
