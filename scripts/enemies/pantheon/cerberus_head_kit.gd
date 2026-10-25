## CerberusHeadKit — one of the three heads of CERBERUS (UnderworldEnemyData
## "cerberus_head", kit "cerberus_head"; Act IV, the Asphodel Underworld; GDD
## §15.0 "The Asphodel Underworld (Act IV phase 2)"; owner-approved proposal:
## "three heads, three attacks, and each head must be killed on its own"). A
## structure: CerberusKit raises three of them when he arrives, sets their HP
## and calls attach(); every tick the head rides on the body (the body's
## position plus its row's head_offsets entry, mirrored with his facing), so
## summons, spells and the combat resolver strike it like any enemy (the body
## itself is untargetable). Drawn by the body (its sprite carries the heads):
## a head draws only its own HP bar and hit flash ring. Never recycled
## (is_objective). No RNG.
class_name CerberusHeadKit
extends CovenantKit

## The body it rides on (null until attach()).
var body: Enemy = null
## Generation of `body` when attached (stale guard).
var body_gen: int = 0
## Head index (0 left / fire, 1 middle / pounce, 2 right / howl).
var head: int = 0


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	body = null
	head = 0


## Puts the head on `p_body` as head `p_head`.
func attach(e: Enemy, p_body: Enemy, p_head: int) -> void:
	body = p_body
	body_gen = p_body.generation
	head = p_head
	e.is_objective = true
	_ride(e)


## Rides on its body; never moves on its own.
func physics(e: Enemy, _delta: float) -> bool:
	hold(e)
	e.knockback = Vector2.ZERO
	_ride(e)
	return true


## The head draws no body of its own (the body's sprite has the heads).
func draws_body(_e: Enemy) -> bool:
	return true


## Nothing: the body draws the heads (UnderworldGlyphs / the cerberus sprite).
func draw_body(_e: Enemy, _ci: CanvasItem) -> void:
	pass


## Puts the head at its offset on the body (mirrored with his facing).
func _ride(e: Enemy) -> void:
	if body == null or not body.active or body.generation != body_gen:
		return
	var offs: Array = body.kit.d["head_offsets"] if body.kit != null else []
	if offs.is_empty():
		return
	var o: Vector2 = offs[head % offs.size()]
	var face := signf(body.scale.x) if body.scale.x != 0.0 else 1.0  # +1 facing right, -1 left.
	e.position = body.position + Vector2(o.x * face, o.y)
