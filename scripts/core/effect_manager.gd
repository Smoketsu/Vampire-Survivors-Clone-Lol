## EffectManager — pools and updates Effect nodes (GDD §36 EffectManager,
## §38 "Pool common ... effects"). Cosmetic effects are dropped when the
## active count hits MAX_COSMETIC so huge fights never spike; telegraphs are
## gameplay-critical and are always shown.
class_name EffectManager
extends Node2D

## Active cosmetic effects above which new cosmetic effects are skipped.
const MAX_COSMETIC: int = 220  # TUNING (not in GDD)

## Effects currently playing.
var active: Array[Effect] = []
## Idle effects ready for reuse.
var _pool: Array[Effect] = []
## Total Effect nodes ever created (debug: pool health).
var created: int = 0


## Advances all effects and returns finished ones to the pool.
func step(delta: float) -> void:
	var i := 0
	while i < active.size():
		var e := active[i]
		if e.step(delta):
			i += 1
		else:
			active[i] = active[active.size() - 1]
			active.pop_back()
			_pool.append(e)


## Takes an effect from the pool (or creates one) and starts it.
func _spawn(kind: Effect.Kind, pos: Vector2, color: Color, size: float, duration: float, vec: Vector2 = Vector2.RIGHT, width: float = 2.0, critical: bool = false) -> void:
	if not critical and active.size() >= MAX_COSMETIC:
		return
	var e: Effect
	if _pool.is_empty():
		e = Effect.new()
		add_child(e)
		created += 1
	else:
		e = _pool.pop_back()
	e.start(kind, pos, color, size, duration, vec, width)
	active.append(e)


## Death pop: expanding ring + bone shards (also stands in for a corpse).
func pop(pos: Vector2, color: Color, size: float) -> void:
	_spawn(Effect.Kind.POP, pos, color, size, 0.35)


## Melee swing arc facing `dir`.
func slash(pos: Vector2, dir: Vector2, color: Color, size: float) -> void:
	_spawn(Effect.Kind.SLASH, pos, color, size, 0.15, dir)


## Expanding filled ring (Shadow Blast, mage explosions).
func ring(pos: Vector2, radius: float, color: Color, duration: float = 0.3) -> void:
	_spawn(Effect.Kind.RING, pos, color, radius, duration)


## Straight beam from `a` to `b` (priest / chaplain heals).
func beam(a: Vector2, b: Vector2, color: Color) -> void:
	_spawn(Effect.Kind.BEAM, a, color, 0.0, 0.25, b - a, 2.0)


## Summon emergence / recall ring.
func spawn_ring(pos: Vector2, color: Color) -> void:
	_spawn(Effect.Kind.SPAWN, pos, color, 12.0, 0.5)


## Boss ground-AoE warning circle shown for `duration` seconds.
func telegraph_circle(pos: Vector2, radius: float, duration: float) -> void:
	_spawn(Effect.Kind.TELEGRAPH_CIRCLE, pos, Palette.GOLD, radius, duration, Vector2.RIGHT, 2.0, true)


## Boss charge-lane warning from `from` to `to`, `lane_width` px wide.
func telegraph_line(from: Vector2, to: Vector2, lane_width: float, duration: float) -> void:
	_spawn(Effect.Kind.TELEGRAPH_LINE, from, Palette.GOLD, 0.0, duration, to - from, lane_width, true)


## Big holy impact burst (Hammerfall landing, boss death).
func impact(pos: Vector2, radius: float, color: Color) -> void:
	_spawn(Effect.Kind.IMPACT, pos, color, radius, 0.4, Vector2.RIGHT, 2.0, true)
