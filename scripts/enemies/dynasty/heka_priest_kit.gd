## HekaPriestKit — the kit of the HEKA PRIEST (male; DynastyEnemyData
## "heka_priest"; temporary Act XII, the Necropolis Dynasty; GDD §15.0 "Heka";
## owner-approved proposal: "A priest writes a glyph on a summon (a gold sigil
## above it) ... Writes the glyph; casting circle on his feet | Priority
## target; Gargoyles"). He walks in with the column (the support walk of the
## enemy-heal behaviour; he heals nothing) and, every heka "every" s while he
## has no glyph of his own on the field, picks the nearest summon within heka
## "range" px that carries no glyph (on the ground: not airborne, spawning,
## dead or charmed), plants his feet for heka "windup" s (a casting circle at
## his feet) and WRITES the glyph on it through Heka.write() (THE one call;
## the curse itself is CombatResolver.curse_unit()). A summon that fell or
## left his reach x1.25 in the windup is lost (counted). His death clears his
## glyph (Heka: the priest's death cleanses). Determinism: the first cast is
## staggered by the think slot; the target is the nearest (ties by the grid's
## order). Stats: heka_casts, heka_casts_lost.
class_name HekaPriestKit
extends DynastyKit

## Phase: casting (the circle at his feet).
const CAST: int = 1

## Seconds until he may start his next cast.
var _cd: float = 0.0
## The summon he is writing on.
var _target: SummonedUnit = null
## Its generation at the cast's start (a pooled unit is someone else).
var _target_gen: int = 0
## Ally query buffer.
var _tmp: Array = []


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	_cd = first_cd(e, float((d["heka"] as Dictionary)["every"]) * 0.4)
	_target = null


func physics(e: Enemy, delta: float) -> bool:
	super.physics(e, delta)
	var h: Dictionary = d["heka"]
	if phase == CAST:
		hold(e)
		phase_time += delta
		if phase_time >= float(h["windup"]):
			_write(e, h)
			set_phase(e, IDLE)
			_cd = float(h["every"])
		return true
	_cd -= delta
	if _cd > 0.0:
		return false
	var heka := rules(e).heka
	if heka.has_glyph_of(e):
		_cd = 0.5  # His glyph still runs: look again soon.
		return false
	var u := _pick(e, float(h["range"]))
	if u == null:
		_cd = 0.5
		return false
	_target = u
	_target_gen = u.generation
	set_phase(e, CAST)
	return true


## The nearest summon within `reach` px that carries no glyph and can take one.
func _pick(e: Enemy, reach: float) -> SummonedUnit:
	var g := e.game
	g.ally_grid.query(e.position, reach, _tmp)
	var best: SummonedUnit = null
	var best_d := reach
	for u: SummonedUnit in _tmp:
		if not Heka.can_take(g, u):
			continue
		var dd := u.position.distance_to(e.position)
		if dd <= best_d:
			best_d = dd
			best = u
	return best


## The windup ends: the glyph is written, unless the summon fell or left.
func _write(e: Enemy, h: Dictionary) -> void:
	var g := e.game
	var u := _target
	_target = null
	g.stat_add("heka_casts", 1.0)
	if u == null or not u.active or u.generation != _target_gen \
			or u.position.distance_to(e.position) > float(h["range"]) * 1.25 or not rules(e).heka.write(e, u):
		g.stat_add("heka_casts_lost", 1.0)


func on_deactivate(e: Enemy) -> void:
	_target = null
	super.on_deactivate(e)


func is_busy() -> bool:
	return phase != IDLE


## The casting circle at his feet (two disc textures, dull bronze-gold).
func draw_under(e: Enemy) -> void:
	if phase != CAST:
		return
	var r := e.radius * 1.9
	e.draw_texture_rect(SpriteBank.disc(), Rect2(Vector2(-r, e.radius * 0.6 - r * 0.4), Vector2(r * 2.0, r * 0.8)), false, Color(Palette.DYN_BRONZE, 0.45))
	e.draw_texture_rect(SpriteBank.disc(), Rect2(Vector2(-r * 0.7, e.radius * 0.6 - r * 0.28), Vector2(r * 1.4, r * 0.56)), false, Color(Palette.DYN_INK, 0.35))
