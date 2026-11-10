## FaeCourtEnemyData — the kinds of The Fae Court (stage 2) (temporary Act XV,
## the Turning Year; GDD §15.0 "The Turning Year foundation (phase 1)").
## EMPTY until phase 2 adds them: the fairy rings (half-speed time inside, both armies), the Winter Prince (the miniboss, one minute of winter through SeasonCycle.set_override()) and the Summer Queen (the Masque, the Bargain, the Court in Bloom).
## EnemyDirector.wild_def() looks these rows up after WildEnemyData.
## Rows have every key of a WildEnemyData.ENEMIES row (same meaning; "kit"
## ids load scripts/enemies/wild/<kit>_kit.gd, unique across every kit
## folder; "group", "season", "planter" switch the shared rules on for the
## kind).
class_name FaeCourtEnemyData
extends RefCounted

## Kind id -> design row (phase 2 fills it).
const ENEMIES := {}
