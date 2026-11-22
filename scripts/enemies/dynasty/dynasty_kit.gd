## DynastyKit — base class of the Necropolis Dynasty's kits (temporary Act XII;
## GDD §15.0 "The Necropolis Dynasty foundation (phase 1)"), a CovenantKit
## plugged into the shared Enemy AI like every kit. Kits load by name from
## scripts/enemies/dynasty/<id>_kit.gd (CovenantKits, after the Eye's, the
## Empire's, the Pantheon's, the Shogunate's, the Inferno's, the Court's, the
## City's and the Concord's folders; an id must not repeat theirs). What every
## Dynasty kind shares:
##   * creating the shared rules on first use (Game.dynasty_rules()), so a
##     Dynasty kind forced onto any stage with --spawn= still returns, writes
##     its glyphs and holds its Names there (the clocks stay off off the act);
##   * `returns`: how many times this body has returned (Rebirth sets it on
##     the returned body; Rebirth.on_death() reads it);
##   * THE SANDSTORM ON ITS BOW (one read, physics()): a "ranged" kind's
##     attack range is its row's x DynastyRules.reach_mult() (half while the
##     storm blows), and a "storm_silenced" row does not shoot at all then;
##   * FIRE (taken_mult()): a row's "fire_taken" multiplies every hit tagged
##     with a DynastyRulesData.FIRE_SOURCES source (the mummies, x1.5);
##   * the Embalmers' and the jars' registration (DynastyRules.note_spawn() /
##     note_gone()).
## Phase 2 kinds extend this class: override physics() for a special and call
## super.physics() first; call super.reset() / super.on_deactivate() /
## super.taken_mult() when they override those.
## Determinism: no RNG, no instance ids.
class_name DynastyKit
extends CovenantKit

## Times this body has returned (0 = its first life; Rebirth).
var returns: int = 0


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	returns = 0
	e.game.dynasty_rules().note_spawn(e)


func on_deactivate(e: Enemy) -> void:
	super.on_deactivate(e)
	if e.game.dynasty != null:
		e.game.dynasty.note_gone(e)


## The shared rules (created on first use).
static func rules(e: Enemy) -> DynastyRules:
	return e.game.dynasty_rules()


## The kind's group (row "group"; DynastyRulesData.GROUPS).
func group() -> String:
	return String(d.get("group", ""))


## Per-tick hook: the Sandstorm on a ranged kind's bow (its attack range x
## the storm's reach; a "storm_silenced" kind holds its shot while it blows).
## Never owns the tick (false); subclasses add their specials after calling it.
func physics(e: Enemy, _delta: float) -> bool:
	if e.behavior == "ranged":
		var g := e.game
		var m := g.dynasty.reach_mult() if g.dynasty != null else 1.0  # x reach now.
		e.attack_range = float(d["attack_range"]) * m
		if m < 1.0 and bool(d.get("storm_silenced", false)):
			e.attack_cd = maxf(e.attack_cd, 0.2)  # Silenced by the storm.
	return false


## Share of a friendly hit tagged `source` this kind takes: x its row's
## "fire_taken" for a fire source (the mummies); exactly 1 otherwise.
func taken_mult(e: Enemy, source: String) -> float:
	var f := float(d.get("fire_taken", 1.0))
	if f != 1.0 and source in DynastyRulesData.FIRE_SOURCES:
		e.game.stat_add("dynasty_fire_hits", 1.0)
		return f
	return 1.0
