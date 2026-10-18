## SeraphFeathers — the Fallen Seraph's rings of black feathers (Act II, GDD
## §15.0 "Fallen Seraph"; SeraphBehavior lays them at each dive impact).
## Owned by HordeDirector and created the first time a ring is laid
## (HordeDirector.seraph_feathers()), so a run without a Fallen Seraph never
## creates it and stays exactly as before.
## A ring waits `delay` s, then its cutting front expands from
## start x radius to `radius` px in `time` s (linear). Every tick the front
## cuts each living enemy it has reached (body edges count half: distance <=
## front + body radius x 0.5) and has not cut before, for `damage` through
## CombatResolver.damage_enemy() with the ring's source ("seraph_feathers").
## An enemy is cut once per ring (a stored list of enemies and their pooling
## generation, never instance ids); a recycled enemy can be cut again.
## Everything is pooled (Ring objects reused) and capped by MAX_RINGS (a
## safety cap, not a balance number: a cap hit drops the new ring and counts
## it in seraph_rings_dropped). No RNG: deterministic per seed.
## Drawing: `feathers` black feather blades spaced around the front, turning
## a little as the ring grows and fading at its end (SeraphGlyphs.draw_ring();
## the feather sprite when it exists). Purely visual.
## Stats: seraph_rings, seraph_feather_hits, seraph_rings_dropped.
class_name SeraphFeathers
extends Node2D

## One expanding feather ring.
class Ring:
	extends RefCounted
	## True while the ring lives (false = pooled).
	var active: bool = false
	## Centre (world px).
	var pos: Vector2 = Vector2.ZERO
	## Final radius of the cutting front (px).
	var radius: float = 80.0
	## Fraction of `radius` the front starts at (0..1).
	var start: float = 0.3
	## Seconds the front takes to reach `radius`.
	var time: float = 0.4
	## Seconds left before the ring starts expanding.
	var delay: float = 0.0
	## Seconds the ring has expanded so far.
	var t: float = 0.0
	## Damage of one cut.
	var damage: float = 0.0
	## Feathers drawn on the front (drawing only).
	var feathers: int = 12
	## Damage-source tag of the cuts.
	var source: String = ""
	## Enemies this ring already cut ...
	var cut: Array[Enemy] = []
	## ... and their pooling generation when cut (stale-reference guard).
	var cut_gen: PackedInt32Array = PackedInt32Array()

## Safety cap on rings alive at once (not a balance number: 3 Seraphs of Ruin
## laying two rings a dive stay far below it).
const MAX_RINGS: int = 24
## Seconds a finished ring keeps fading on screen (drawing only).
const FADE_TIME: float = 0.18

## Owning run.
var game: Game
## Ring pool (active and free entries).
var _rings: Array[Ring] = []
## Rings alive (waiting or expanding) right now.
var _alive: int = 0
## True if something was drawn last frame (one final redraw clears it).
var _drew: bool = false
## Reusable enemy query buffer.
var _buf: Array = []
## Reusable victim list (damage may trigger kill hooks that touch the grid).
var _victims: Array[Enemy] = []


func _ready() -> void:
	z_index = 4  # Above the bodies, under the cosmetic effects.


## Lays a ring at `pos` (see the header). Returns false when the safety cap
## dropped it.
func add_ring(pos: Vector2, radius: float, start: float, time: float, delay: float, damage: float,
		feathers: int, source: String) -> bool:
	var r := _free_ring()
	if r == null:
		game.stat_add("seraph_rings_dropped", 1.0)
		return false
	r.active = true
	r.pos = pos
	r.radius = radius
	r.start = clampf(start, 0.0, 1.0)
	r.time = maxf(time, 0.05)
	r.delay = maxf(delay, 0.0)
	r.t = 0.0
	r.damage = damage
	r.feathers = maxi(feathers, 1)
	r.source = source
	r.cut.clear()
	r.cut_gen.resize(0)
	_alive += 1
	game.stat_add("seraph_rings", 1.0)
	queue_redraw()
	return true


## A free pooled ring (grown up to MAX_RINGS), or null at the cap.
func _free_ring() -> Ring:
	for r in _rings:
		if not r.active:
			return r
	if _rings.size() >= MAX_RINGS:
		return null
	var nr := Ring.new()
	_rings.append(nr)
	return nr


## Radius (px) of ring `r`'s cutting front now.
static func front(r: Ring) -> float:
	return r.radius * lerpf(r.start, 1.0, clampf(r.t / r.time, 0.0, 1.0))


## Advances every ring and cuts what its front reached (HordeDirector.step).
func step(delta: float) -> void:
	if _alive <= 0:
		if _drew:
			queue_redraw()
		return
	for r in _rings:
		if not r.active:
			continue
		if r.delay > 0.0:
			r.delay -= delta
			continue
		r.t += delta
		_cut(r)
		if r.t >= r.time + FADE_TIME:
			r.active = false
			r.cut.clear()
			_alive -= 1
	queue_redraw()


## Cuts every living enemy inside ring `r`'s front that it has not cut yet.
func _cut(r: Ring) -> void:
	if r.t > r.time:
		return  # Fully expanded: only fading now.
	var f := front(r)  # Front radius (px).
	game.enemy_grid.query(r.pos, f + ProjectileManager.MAX_BODY_RADIUS, _buf)
	_victims.clear()
	for e: Enemy in _buf:
		if e.active and e.position.distance_to(r.pos) <= f + e.radius * 0.5 and not _was_cut(r, e):
			_victims.append(e)
	for e in _victims:
		if not e.active:
			continue
		r.cut.append(e)
		r.cut_gen.append(e.generation)
		game.combat.damage_enemy(e, r.damage, r.source)
		game.stat_add("seraph_feather_hits", 1.0)


## True when ring `r` already cut enemy `e` in its current life.
static func _was_cut(r: Ring, e: Enemy) -> bool:
	for i in r.cut.size():
		if r.cut[i] == e and r.cut_gen[i] == e.generation:
			return true
	return false


## Draws every live ring's feathers (SeraphGlyphs).
func _draw() -> void:
	_drew = _alive > 0
	if _alive <= 0:
		return
	for r in _rings:
		if not r.active or r.delay > 0.0:
			continue
		var fade := 1.0 - clampf((r.t - r.time) / FADE_TIME, 0.0, 1.0)  # 1 while expanding, then fades.
		SeraphGlyphs.draw_ring(self, r.pos, front(r), r.feathers, r.t, fade)
