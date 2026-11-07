## InfernoKit — base class of the Inferno's kits (Act VI; GDD §15.0 "Act VI
## foundation (phase 1)"), a CovenantKit plugged into the shared Enemy AI like
## every kit. Kits load by name from scripts/enemies/inferno/<id>_kit.gd
## (CovenantKits, after the Eye's, the Empire's, the Pantheon's and the
## Shogunate's folders; an id must not repeat theirs). What every Inferno kind
## shares:
##   * creating the shared rules on first use (Game.inferno_rules()), so an
##     Inferno kind forced onto any stage with --spawn= still charms there (the
##     pits and the Last Judgment stay off off Act VI);
##   * the row flags as helpers: is_demon() (row "demon": the Hell Pits spare
##     it, HellPits.burns_enemy()), is_flier() (row "flier": it crosses the pits
##     and obstacles), is_charmer() (row "charmer": Temptation), is_damned()
##     (row "damned": it burns at damned_mult x);
##   * a CHARMER's death breaks its charms (on_killed() ->
##     HordeDirector.break_charms(), the one path);
##   * try_charm(): a charm from this body on a summon through
##     HordeDirector.charm() (the one path; phase 2's lilim and bosses call it
##     the same way).
## Phase 2 kinds extend this class (override physics() for a windup and call
## super.reset() / super.on_killed() when they override those).
## Determinism: no RNG, no instance ids.
class_name InfernoKit
extends CovenantKit


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	e.game.inferno_rules().note_spawn(e)  # The shared rules exist wherever an Inferno kind walks.


## A charmer's death breaks its charms (Temptation, the one path).
func on_killed(e: Enemy) -> void:
	if is_charmer() and e.game != null:
		e.game.horde.break_charms(e)


## The shared rules (created on first use).
static func rules(e: Enemy) -> InfernoRules:
	return e.game.inferno_rules()


## True for a demon (row "demon"): the Hell Pits spare it.
func is_demon() -> bool:
	return bool(d.get("demon", false))


## True for a flier (row "flier"): it crosses the pits and the obstacles.
func is_flier() -> bool:
	return bool(d.get("flier", false))


## True for a charmer (row "charmer"): it uses Temptation.
func is_charmer() -> bool:
	return bool(d.get("charmer", false))


## True for a damned soul (row "damned"): it burns in the pits, fast.
func is_damned() -> bool:
	return bool(d.get("damned", false))


## Charms summon `u` from enemy `e` for `duration` s through the one path
## (HordeDirector.charm(); co-op: the summon's own army). True when it took hold.
static func try_charm(e: Enemy, u: SummonedUnit, duration: float, opts: Dictionary = {}) -> bool:
	if u == null or u.director == null:
		return false
	return u.director.charm(u, e, duration, opts)
