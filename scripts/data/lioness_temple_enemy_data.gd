## LionessTempleEnemyData — the kinds of the Temple of the Lioness (stage 2) (temporary Act XII, the
## Necropolis Dynasty; GDD §15.0 "The Necropolis Dynasty foundation (phase
## 1)"). EMPTY until phase 2 adds them: the Bastet Hunter, the Ushabti Statue and the Sand Colossus woken from the statue rows, the Lion Warden (the miniboss) and Sekhmet's wine jars.
## EnemyDirector.dynasty_def() looks these rows up after DynastyEnemyData.
## Rows have every key of a DynastyEnemyData.ENEMIES row (same meaning; "kit"
## ids load scripts/enemies/dynasty/<kit>_kit.gd, unique across every kit
## folder; "group", "rebirth", "fire_taken", "embalms", "holds_names" and
## "storm_silenced" switch the shared rules on for the kind).
class_name LionessTempleEnemyData
extends RefCounted

## Kind id -> design row (phase 2 fills it).
const ENEMIES := {}
