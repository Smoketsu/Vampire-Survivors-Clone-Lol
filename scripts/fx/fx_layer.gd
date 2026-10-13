## FxLayer — world-space "juice" drawn by ONE node in ONE _draw() call
## (GDD §13.4 "batched/simple effects"): death-pop particles, XP sparkles and
## floating damage numbers. Nothing here is a node per particle or per
## number: both live in fixed-size ring buffers of packed arrays (the pool),
## so the cost is bounded no matter how many enemies die at once; when a
## buffer is full the oldest entry is overwritten.
## Damage numbers are batched per enemy: hits on the same enemy within
## MERGE_WINDOW add up into one number instead of spawning a new one.
## Owned by the Juice autoload; it sits on the default canvas so the run's
## Camera2D transforms it like any world node. It pauses with the tree (the
## level-up panel freezes it) and slows with Engine.time_scale (hit-stop).
class_name FxLayer
extends Node2D

## Particle ring-buffer size (max live particles).
const MAX_PARTICLES: int = 320  # TUNING (not in GDD)
## Damage-number ring-buffer size (max numbers on screen).
const MAX_NUMBERS: int = 40  # TUNING (not in GDD)
## Seconds a damage number lives.
const NUMBER_LIFE: float = 0.65  # TUNING (not in GDD)
## Hits on the same enemy within this many seconds merge into one number.
const MERGE_WINDOW: float = 0.22  # TUNING (not in GDD)
## Pixels a damage number rises over its life.
const NUMBER_RISE: float = 26.0  # TUNING (not in GDD)
## Font size (px, world space) of a regular damage number.
const NUMBER_FONT_SIZE: int = 11  # TUNING (not in GDD)
## Font size of a big number (boss hits or >= BIG_HIT damage).
const NUMBER_FONT_SIZE_BIG: int = 15  # TUNING (not in GDD)
## Damage at or above which a number is drawn big.
const BIG_HIT: float = 40.0  # TUNING (not in GDD)
## Particle drag (fraction of velocity kept per second).
const DRAG: float = 0.06  # TUNING (not in GDD)

## Particle positions (world px).
var _p_pos: PackedVector2Array = PackedVector2Array()
## Particle velocities (px/s).
var _p_vel: PackedVector2Array = PackedVector2Array()
## Particle remaining life (s); <= 0 means the slot is free.
var _p_life: PackedFloat32Array = PackedFloat32Array()
## Particle total life (s), for the fade.
var _p_max: PackedFloat32Array = PackedFloat32Array()
## Particle square size (px).
var _p_size: PackedFloat32Array = PackedFloat32Array()
## Particle colours.
var _p_col: PackedColorArray = PackedColorArray()
## Next particle slot to write (ring cursor).
var _p_next: int = 0
## Number of particle slots with life > 0 (upper bound; refreshed per frame).
var _p_alive: int = 0
## Damage-number positions.
var _n_pos: PackedVector2Array = PackedVector2Array()
## Damage-number values.
var _n_val: PackedFloat32Array = PackedFloat32Array()
## Damage-number ages (s); >= NUMBER_LIFE means the slot is free.
var _n_age: PackedFloat32Array = PackedFloat32Array()
## Damage-number colours.
var _n_col: PackedColorArray = PackedColorArray()
## Damage-number "big" flags (1 = big font).
var _n_big: PackedByteArray = PackedByteArray()
## Damage-number owner key (enemy instance id) for merging.
var _n_key: PackedInt64Array = PackedInt64Array()
## Enemy instance id -> number slot, for merging.
var _n_slot_of: Dictionary = {}
## Next number slot to write (ring cursor).
var _n_next: int = 0
## Number of live damage numbers (upper bound; refreshed per frame).
var _n_alive: int = 0
## Cosmetic RNG (never the global, seeded RNG).
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
## Font used for damage numbers (engine fallback font; no assets).
var _font: Font


func _ready() -> void:
	z_index = 20
	_rng.randomize()
	_font = ThemeDB.fallback_font
	_p_pos.resize(MAX_PARTICLES)
	_p_vel.resize(MAX_PARTICLES)
	_p_life.resize(MAX_PARTICLES)
	_p_max.resize(MAX_PARTICLES)
	_p_size.resize(MAX_PARTICLES)
	_p_col.resize(MAX_PARTICLES)
	_n_pos.resize(MAX_NUMBERS)
	_n_val.resize(MAX_NUMBERS)
	_n_age.resize(MAX_NUMBERS)
	_n_age.fill(NUMBER_LIFE)
	_n_col.resize(MAX_NUMBERS)
	_n_big.resize(MAX_NUMBERS)
	_n_key.resize(MAX_NUMBERS)


## Spawns `count` particles at `pos` flying outward at up to `speed` px/s.
## Alternate particles use `alt` (e.g. bone shards with a crimson pop).
func burst(pos: Vector2, color: Color, alt: Color, count: int, speed: float, life: float, size: float) -> void:
	for i in count:
		var s := _p_next
		_p_next = (_p_next + 1) % MAX_PARTICLES
		_p_pos[s] = pos
		_p_vel[s] = Vector2.from_angle(_rng.randf() * TAU) * speed * _rng.randf_range(0.35, 1.0)
		var l := life * _rng.randf_range(0.6, 1.0)
		_p_life[s] = l
		_p_max[s] = l
		_p_size[s] = size * _rng.randf_range(0.6, 1.2)
		_p_col[s] = color if i % 2 == 0 else alt
	_p_alive = mini(MAX_PARTICLES, _p_alive + count)


## XP sparkle: a few small particles drifting upward around `pos`.
func sparkle(pos: Vector2, color: Color, count: int) -> void:
	for i in count:
		var s := _p_next
		_p_next = (_p_next + 1) % MAX_PARTICLES
		_p_pos[s] = pos + Vector2(_rng.randf_range(-8.0, 8.0), _rng.randf_range(-6.0, 6.0))
		_p_vel[s] = Vector2(_rng.randf_range(-12.0, 12.0), _rng.randf_range(-55.0, -25.0))
		var l := _rng.randf_range(0.3, 0.55)
		_p_life[s] = l
		_p_max[s] = l
		_p_size[s] = _rng.randf_range(1.5, 2.5)
		_p_col[s] = color if i % 2 == 0 else Color.WHITE
	_p_alive = mini(MAX_PARTICLES, _p_alive + count)


## Grave dust / holy ash (engine motion, MotionDirector): `count` square
## motes spread across a body of radius `r` px at its feet `pos`, drifting
## up and sideways (MotionData.DUST_*), alternating `color` and `alt`.
func dust(pos: Vector2, color: Color, alt: Color, count: int, r: float) -> void:
	for i in count:
		var s := _p_next
		_p_next = (_p_next + 1) % MAX_PARTICLES
		_p_pos[s] = pos + Vector2(_rng.randf_range(-r, r), _rng.randf_range(-r * 0.4, r * 0.2))
		_p_vel[s] = Vector2(_rng.randf_range(-MotionData.DUST_SPREAD, MotionData.DUST_SPREAD),
				-MotionData.DUST_RISE * _rng.randf_range(0.5, 1.3))
		var l := MotionData.DUST_LIFE * _rng.randf_range(0.6, 1.0)
		_p_life[s] = l
		_p_max[s] = l
		_p_size[s] = MotionData.DUST_SIZE
		_p_col[s] = color if i % 2 == 0 else alt
	_p_alive = mini(MAX_PARTICLES, _p_alive + count)


## Shows (or merges) a damage number for the enemy with instance id `key`.
func number(key: int, pos: Vector2, value: float, color: Color, big: bool) -> void:
	var s: int = _n_slot_of.get(key, -1)
	if s >= 0 and _n_key[s] == key and _n_age[s] < MERGE_WINDOW:
		_n_val[s] += value
		if big or _n_val[s] >= BIG_HIT:
			_n_big[s] = 1
		return
	s = _n_next
	_n_next = (_n_next + 1) % MAX_NUMBERS
	if _n_age[s] < NUMBER_LIFE and int(_n_slot_of.get(_n_key[s], -1)) == s:
		_n_slot_of.erase(_n_key[s])
	_n_pos[s] = pos + Vector2(_rng.randf_range(-5.0, 5.0), -8.0)
	_n_val[s] = value
	_n_age[s] = 0.0
	_n_col[s] = color
	_n_big[s] = 1 if (big or value >= BIG_HIT) else 0
	_n_key[s] = key
	_n_slot_of[key] = s
	_n_alive = mini(MAX_NUMBERS, _n_alive + 1)


## Removes every particle and number (run ended / restarted).
func clear() -> void:
	_p_life.fill(0.0)
	_n_age.fill(NUMBER_LIFE)
	_n_slot_of.clear()
	_p_alive = 0
	_n_alive = 0
	queue_redraw()


func _process(delta: float) -> void:
	if _p_alive == 0 and _n_alive == 0:
		return
	var alive := 0
	if _p_alive > 0:
		var keep := pow(DRAG, delta)
		for i in MAX_PARTICLES:
			var l := _p_life[i]
			if l <= 0.0:
				continue
			l -= delta
			_p_life[i] = l
			if l > 0.0:
				alive += 1
				_p_pos[i] += _p_vel[i] * delta
				_p_vel[i] *= keep
	_p_alive = alive
	alive = 0
	if _n_alive > 0:
		for i in MAX_NUMBERS:
			var a := _n_age[i]
			if a >= NUMBER_LIFE:
				continue
			a += delta
			_n_age[i] = a
			if a < NUMBER_LIFE:
				alive += 1
			elif int(_n_slot_of.get(_n_key[i], -1)) == i:
				_n_slot_of.erase(_n_key[i])
	_n_alive = alive
	queue_redraw()


func _draw() -> void:
	for i in MAX_PARTICLES:
		var l := _p_life[i]
		if l <= 0.0:
			continue
		var sz := _p_size[i]
		draw_rect(Rect2(_p_pos[i] - Vector2(sz, sz) * 0.5, Vector2(sz, sz)), Color(_p_col[i], l / _p_max[i]))
	for i in MAX_NUMBERS:
		var a := _n_age[i]
		if a >= NUMBER_LIFE:
			continue
		var k := a / NUMBER_LIFE
		var alpha := 1.0 if k < 0.6 else (1.0 - k) / 0.4
		var fs := NUMBER_FONT_SIZE_BIG if _n_big[i] == 1 else NUMBER_FONT_SIZE
		var p := _n_pos[i] + Vector2(-20.0, -NUMBER_RISE * (1.0 - (1.0 - k) * (1.0 - k)))
		var text := str(int(ceilf(_n_val[i])))
		draw_string_outline(_font, p, text, HORIZONTAL_ALIGNMENT_CENTER, 40.0, fs, 3, Color(0.0, 0.0, 0.0, 0.75 * alpha))
		draw_string(_font, p, text, HORIZONTAL_ALIGNMENT_CENTER, 40.0, fs, Color(_n_col[i], alpha))
