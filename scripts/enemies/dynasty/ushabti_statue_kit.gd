## UshabtiStatueKit — the kit of the USHABTI STATUE (a stone servant, no sex;
## DynastyEnemyData "ushabti_statue"; temporary Act XII, the Temple of the
## Lioness; GDD §15.0 "The Temple of the Lioness (Dynasty phase 2)";
## owner-approved proposal: "A stone servant; wakes from an alcove; no
## Rebirth; armour 5 | Siegecraft"). A slow heavy walker with nothing of its
## own beyond the shared DynastyKit and its row: "flat_armor" 5 (the existing
## flat-armour path in CombatResolver.damage_enemy(): weak blows barely chip
## it; Wither shreds it, Siegecraft helps) and no "rebirth" (stone does not
## return). On the Temple it is not spawned at the edge of the screen: the
## Awakening Statues (LionessTempleDirector) wake it out of a statue row, which
## then leaves a gap in the layout; anywhere else (--spawn=) it walks in like
## any kind. Its woken-from-stone look is the director's (the eyes glow 2 s
## on the row before it steps out).
class_name UshabtiStatueKit
extends DynastyKit
