## SilverStairEnemyData — the kinds of The Silver Stair (stage 1) (temporary Act XIII,
## the Celestial Host; GDD §15.0 "The Celestial Host foundation (phase 1)").
## EMPTY until phase 2 adds them: the Stair (each zone a wider step, low cloud banks as shadows), the Cherub of the Gate (the miniboss) and Seraiel, Warden of the Gate (the Gate, the Sword, the Trial).
## EnemyDirector.host_def() looks these rows up after HostEnemyData.
## Rows have every key of a HostEnemyData.ENEMIES row (same meaning; "kit" ids
## load scripts/enemies/host/<kit>_kit.gd, unique across every kit folder;
## "group", "halo", "regrows", "judge" switch the shared rules on for the kind).
class_name SilverStairEnemyData
extends RefCounted

## Kind id -> design row (phase 2 fills it).
const ENEMIES := {}
