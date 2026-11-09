## WheelOfThronesEnemyData — the kinds of The Wheel of Thrones (stage 2) (temporary Act XIII,
## the Celestial Host; GDD §15.0 "The Celestial Host foundation (phase 1)").
## EMPTY until phase 2 adds them: the turning spheres (crystal rings that sweep the map as moving walls), the Ophan, the Dominion of the Spheres (the miniboss) and the Throne (the Rolling, the Gaze, the Core).
## EnemyDirector.host_def() looks these rows up after HostEnemyData.
## Rows have every key of a HostEnemyData.ENEMIES row (same meaning; "kit" ids
## load scripts/enemies/host/<kit>_kit.gd, unique across every kit folder;
## "group", "halo", "regrows", "judge" switch the shared rules on for the kind).
class_name WheelOfThronesEnemyData
extends RefCounted

## Kind id -> design row (phase 2 fills it).
const ENEMIES := {}
