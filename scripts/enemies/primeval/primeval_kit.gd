## PrimevalKit — base class of the Age of Titans' kits (temporary Act XIV; GDD
## §15.0 "The Age of Titans foundation (phase 1)"), a CovenantKit plugged into
## the shared Enemy AI like every kit. Kits load by name from
## scripts/enemies/primeval/<id>_kit.gd (CovenantKits, after the Host's folder;
## an id must not repeat any other folder's). What every Titans kind shares:
##   * creating the shared rules on first use (Game.primeval_rules()), so a
##     Titans kind forced onto any stage with --spawn= keeps its pack, herd or
##     theft there (the herd and dive clocks stay off off the act);
##   * registering with the rule its row names (PrimevalRules.note_spawn():
##     "pack" -> PackBrain, "herd" -> Herds, "scavenger" -> Scavengers) and
##     leaving it (note_gone(), note_killed());
##   * move(): the one steering step of a kit that owns its tick (the slow,
##     the separation and the knockback, as every enemy walks).
## Phase 2 kinds extend this class: override physics() for a special and call
## super.reset() / super.on_deactivate() / super.on_killed() when they
## override those. Determinism: no RNG, no instance ids.
class_name PrimevalKit
extends CovenantKit


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	e.game.primeval_rules().note_spawn(e)


func on_deactivate(e: Enemy) -> void:
	super.on_deactivate(e)
	if e.game.primeval != null:
		e.game.primeval.note_gone(e)


func on_killed(e: Enemy) -> void:
	super.on_killed(e)
	if e.game.primeval != null:
		e.game.primeval.note_killed(e)


## The shared rules (created on first use).
static func rules(e: Enemy) -> PrimevalRules:
	return e.game.primeval_rules()


## The kind's group (row "group"; PrimevalRulesData.GROUPS).
func group() -> String:
	return String(d.get("group", ""))


## One steering step of a kit that owns the tick: `e` moves along `dir` (unit)
## at `speed` px/s (x the enemy's slow while one holds it), with the shared
## separation and its knockback, facing its way.
static func move(e: Enemy, dir: Vector2, speed: float, delta: float) -> void:
	var spd := speed * (1.0 - e.slow_factor if e.slow_timer > 0.0 else 1.0)
	e.velocity = dir * spd + e.sep * spd * EnemyData.SEPARATION_STRENGTH
	e.position += (e.velocity + e.knockback) * delta
	e._update_facing()
