## BarrowFieldsEnemyData — immutable design data for the Norse kinds that join on the Barrow Fields
## (Stage 16 in the final order; the Hall of the Slain, temporarily Act XI;
## GDD §15.0 "The Hall of the Slain foundation (phase 1)"; the act's section of
## docs/proposals/LAST_SIX_ACTS.md). EMPTY in the foundation: phase 2 adds the
## stage's own kinds here (the open barrows' draugr, the Barrow-Wight miniboss and Hrimgar's allies).
## EnemyDirector.norse_def() looks these rows up after NorseEnemyData.
## Rows have every key of a NorseEnemyData.ENEMIES row (same meaning; "kit" ids
## load scripts/enemies/norse/<kit>_kit.gd, unique across the Eye, Empire,
## Pantheon, Shogunate, Inferno, Court, City, Concord and Norse folders;
## "warrior" puts a kind under the Choosing and Berserkergang). The GDD gives no
## numbers: everything is TUNING (not in GDD).
class_name BarrowFieldsEnemyData
extends RefCounted

## Kind id -> design row (phase 2 fills it).
const ENEMIES := {}
