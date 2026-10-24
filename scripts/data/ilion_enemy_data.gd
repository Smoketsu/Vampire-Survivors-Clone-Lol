## IlionEnemyData — immutable design data for the Olympian Republic kinds that
## join on the Shores of Ilion (Stage 10) (Act IV; GDD §15.0 "Act IV foundation (phase 1)"):
## Siege towers, Polyphemus the Cyclops, the Legionary, the Wolf of Rome, Centaur Archer, Amazon or Gorgon (the stage agents choose).
## Each kind stays in play on the stages after it, and any stage can spawn it
## (--spawn=kind@T). EnemyDirector.pantheon_def() looks these rows up after
## PantheonEnemyData. Rows have every key of a PantheonEnemyData.ENEMIES row
## (same meaning; "kit" ids load scripts/enemies/pantheon/<kit>_kit.gd, unique
## across the Eye, Empire and Pantheon folders; "bronze", "phalanx", "hero",
## "fodder" switch the shared rules on for the kind). Empty until the stage's
## kinds are built (Act IV phase 2).
## The GDD gives no numbers: everything is TUNING (not in GDD).
class_name IlionEnemyData
extends RefCounted

## Kind id -> design row.
const ENEMIES := {
}
