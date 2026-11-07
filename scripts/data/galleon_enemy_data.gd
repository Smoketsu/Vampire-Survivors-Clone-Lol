## GalleonEnemyData — the kinds of the Treasure Galleon only (Act X, the Black Tide; GDD §15.0
## "Act X foundation: the Black Tide (phase 1)"). EMPTY in the foundation: phase
## 2 adds the stage's own kinds here (rows as CorsairEnemyData's, kits in
## scripts/enemies/corsair/). EnemyDirector.corsair_def() looks them up after
## CorsairEnemyData.
class_name GalleonEnemyData
extends RefCounted

## The stage's own kinds, keyed by kind id (phase 2 fills it).
const ENEMIES := {}
