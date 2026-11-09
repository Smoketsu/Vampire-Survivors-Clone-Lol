## EmpyreanEnemyData — the kinds of The Empyrean (stage 3, the finale) (temporary Act XIII,
## the Celestial Host; GDD §15.0 "The Celestial Host foundation (phase 1)").
## EMPTY until phase 2 adds them: the Choir (every Choir Angel alive widens the light), the Herald of the Seventh Trumpet (the miniboss) and the Voice (the Holy, Be Not Afraid, the Last Word) with the act's ending.
## EnemyDirector.host_def() looks these rows up after HostEnemyData.
## Rows have every key of a HostEnemyData.ENEMIES row (same meaning; "kit" ids
## load scripts/enemies/host/<kit>_kit.gd, unique across every kit folder;
## "group", "halo", "regrows", "judge" switch the shared rules on for the kind).
class_name EmpyreanEnemyData
extends RefCounted

## Kind id -> design row (phase 2 fills it).
const ENEMIES := {}
