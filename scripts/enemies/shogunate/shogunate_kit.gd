## ShogunateKit — base class of the Shogunate's kits (Act V; GDD §15.0 "Act V
## foundation (phase 1)"), a CovenantKit plugged into the shared Enemy AI like
## every kit. Kits load by name from scripts/enemies/shogunate/<id>_kit.gd
## (CovenantKits, after the Eye's, the Empire's and the Pantheon's folders; an
## id must not repeat theirs). What every Shogunate kind shares:
##   * creating the shared rules on first use (Game.shogunate_rules()), so a
##     Shogunate kind forced onto any stage with --spawn= still draws its Draw
##     there (the Sun's Course stays day off Act V);
##   * the row flags as helpers: is_night_kind() (row "night": the timeline
##     helper keeps it to the night), can_draw() (row "draws": the samurai's
##     elite; "draws_always" for a phase 2 kind that draws without being
##     elite), is_ambusher() (row "ambusher"), is_ethereal() (row "ethereal":
##     Enemy.ethereal is the one path);
##   * start_draw(): the Draw from this body toward a point, through
##     DrawCuts.draw() (the one path; phase 2's bosses call DrawCuts directly);
##   * light(): the Sun's Course's light where the body stands
##     (SunCourse.light_at(); phase 2's kitsune decoys are revealed in light).
## Phase 2 kinds extend this class (override physics() for a windup and call
## super.physics() first; draw_over() for their own marks).
## Determinism: no RNG, no instance ids.
class_name ShogunateKit
extends CovenantKit


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	e.game.shogunate_rules().note_spawn(e, is_night_kind())  # The shared rules exist wherever a Shogunate kind walks.


## The shared rules (created on first use).
static func rules(e: Enemy) -> ShogunateRules:
	return e.game.shogunate_rules()


## True for a night-only kind (row "night").
func is_night_kind() -> bool:
	return bool(d.get("night", false))


## True when enemy `e` may use the Draw: its row "draws" and it is an elite (or
## its row "draws_always").
func can_draw(e: Enemy) -> bool:
	return bool(d.get("draws", false)) and (e.is_elite or bool(d.get("draws_always", false)))


## True for an ambusher kind (row "ambusher": From the Shadows).
func is_ambusher() -> bool:
	return bool(d.get("ambusher", false))


## True for an ethereal kind (row "ethereal": Enemy.ethereal).
func is_ethereal() -> bool:
	return bool(d.get("ethereal", false))


## Starts a Draw from enemy `e` toward world point `at` (the line begins DRAW
## origin px out of its body) with DrawCuts options `opts`; true when the line
## was drawn (false when refused: too many lines flash).
func start_draw(e: Enemy, at: Vector2, opts: Dictionary = {}) -> bool:
	var to := at - e.position
	var dir := to.normalized() if to.length_squared() > 0.01 else Vector2.RIGHT
	var from := e.position + dir * float(ShogunateRulesData.DRAW["origin"])
	return rules(e).draws.draw(e, from, dir, opts)


## The Sun's Course's light (0..1) where `e` stands.
static func light(e: Enemy) -> float:
	return rules(e).sun.light_at(e.position)
