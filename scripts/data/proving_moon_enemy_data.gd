## ProvingMoonEnemyData — immutable design data for the Concord kinds that join on
## the Proving Moon (Stage 26) (Act IX, the Concord of Stars; GDD §15.0 "Act IX foundation
## (phase 1)"; owner-approved proposal docs/act9/PROPOSAL.md). EMPTY in the
## foundation: phase 2 adds the stage's own kinds here (the Warbeast and Vrask'Tal's allies).
## EnemyDirector.concord_def() looks these rows up after ConcordEnemyData.
## Rows have every key of a ConcordEnemyData.ENEMIES row (same meaning; "kit"
## ids load scripts/enemies/concord/<kit>_kit.gd, unique across the Eye,
## Empire, Pantheon, Shogunate, Inferno, Court, City and Concord folders;
## "race", "beam", "abducts", "cloak" and "heals_on_turf" switch the shared
## rules on for the kind). The GDD gives no numbers: everything is TUNING (not
## in GDD).
class_name ProvingMoonEnemyData
extends RefCounted

## Kind id -> design row (phase 2 fills it).
const ENEMIES := {}
