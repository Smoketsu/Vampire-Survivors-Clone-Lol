## LibertyHeightsEnemyData — immutable design data for the City kinds that join on
## Liberty Heights (Stage 24) (Act VIII, the Last Line; GDD §15.0 "Act VIII foundation (phase
## 1)"; owner-approved proposal docs/act8/PROPOSAL.md). EMPTY in the
## foundation: phase 2 adds the stage's own kinds here (Atlas, Aurora and Nightjar (Supers on SuperKit), the attack helicopter).
## EnemyDirector.city_def() looks these rows up after CityEnemyData. Rows have
## every key of a CityEnemyData.ENEMIES row (same meaning; "kit" ids load
## scripts/enemies/city/<kit>_kit.gd, unique across the Eye, Empire, Pantheon,
## Shogunate, Inferno, Court and City folders; "tier", "armour_front",
## "vehicle", "super" and "civilian" switch the shared rules on for the kind).
## The GDD gives no numbers: everything is TUNING (not in GDD).
class_name LibertyHeightsEnemyData
extends RefCounted

## Kind id -> design row (phase 2 fills it).
const ENEMIES := {}
