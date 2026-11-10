## WildKit — base class of the Turning Year's kits (temporary Act XV; GDD
## §15.0 "The Turning Year foundation (phase 1)"), a CovenantKit plugged into
## the shared Enemy AI like every kit. Kits load by name from
## scripts/enemies/wild/<id>_kit.gd (CovenantKits, after the Titans' folder; an
## id must not repeat any other folder's). What every Wild kind shares:
##   * creating the shared rules on first use (Game.wild_rules()), so a Wild
##     kind forced onto any stage with --spawn= keeps its seeds there (the
##     season clock stays off off the act);
##   * registering with the rules (WildRules.note_spawn(): its first time;
##     the heal on living ground is BloomField's, read from the row's faction).
## Phase 2 kinds extend this class: override physics() for a special and call
## super.reset() when they override it. Determinism: no RNG, no instance ids.
class_name WildKit
extends CovenantKit


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	e.game.wild_rules().note_spawn(e)


## The shared rules (created on first use).
static func rules(e: Enemy) -> WildRules:
	return e.game.wild_rules()


## The kind's group (row "group"; WildRulesData.GROUPS).
func group() -> String:
	return String(d.get("group", ""))
