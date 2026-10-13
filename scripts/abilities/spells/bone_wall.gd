## BoneWall — the Bone Wall spell (AbilityData "bone_wall", GDD §15.0 "Five
## more spells"): every `cooldown` s it raises a straight wall of
## `segments` bone-spike segments `distance` px ahead of the necromancer,
## across the way he is walking (aim assist: it faces the nearest enemy
## inside GraveSpellData.BONE_WALL_AIM_CONE of the walking direction, else
## the nearest enemy). It stands `duration` s.
## Blocking (no physics engine, CLAUDE.md rule 6): after the enemies moved
## and obstacles were resolved, after_physics() pushes every enemy body out
## of every segment circle, like Arena's obstacle push-out. Enemies still
## advance (their AI is untouched): they press against the wall, slide
## along it and walk around its ends; nobody is turned away or kites.
## Every GraveSpellData.BONE_WALL_TICK s each enemy pressing on a wall takes
## `damage` (once per wall per tick, however many segments it touches).
## Never trapping: the wall blocks ENEMIES only (the necromancer and his
## summons walk through it), a segment is never placed inside an obstacle
## (Arena.is_blocked()), and bosses, minibosses, Reckoning enemies and
## Crimson March structures / carts are not held (a wall must not stall the
## boss fight, the run's end or a cart's fixed path); they still take the
## spike damage.
## Evolved into Charnel Bastion (EvolutionData "charnel_bastion", detected
## by the "pulse_damage" key): a RING of segments `radius` px around the
## necromancer (at most GraveSpellData.BASTION_SPACING apart) that, when it
## expires, bursts into shrapnel: `pulse_damage` once to every enemy within
## GraveSpellData.BASTION_SHRAPNEL_RADIUS px of any segment.
## Walls are pooled Wall records simulated and drawn by this one node.
class_name BoneWall
extends NecroSpell

## One standing wall (pooled through `_pool`).
class Wall:
	extends RefCounted
	## Segment centres (world px).
	var segs: PackedVector2Array = PackedVector2Array()
	## Push direction for an enemy sitting exactly on a segment centre: the
	## wall's facing (straight wall) — ignored for a ring, which pushes away
	## from `center`.
	var normal: Vector2 = Vector2.RIGHT
	## Ring centre (Charnel Bastion).
	var center: Vector2 = Vector2.ZERO
	## True for a Charnel Bastion ring.
	var ring: bool = false
	## Seconds left standing.
	var time_left: float = 0.0
	## Total lifetime (s), for the rise / crumble drawing.
	var duration: float = 1.0
	## Seconds until the next spike damage tick.
	var tick: float = 0.0
	## Spike damage per tick to each enemy pressing on it.
	var damage: float = 0.0
	## Charnel Bastion shrapnel damage when it expires (0 = none).
	var shrapnel: float = 0.0

## Standing walls (oldest first).
var _walls: Array[Wall] = []
## Idle Wall records ready for reuse.
var _pool: Array[Wall] = []
## Seconds until the next wall.
var _timer: float = 0.8
## Unit direction of the last movement (the wall faces it).
var _facing: Vector2 = Vector2.RIGHT
## Segments standing over every wall (cap check).
var _seg_count: int = 0
## Enemies already handled this pass (push-out stats / spike damage).
var _seen: Array[Enemy] = []
## Own query buffer for the push-out and damage passes (kills may query too).
var _hit: Array = []
## Seconds of animation time.
var _phase: float = 0.0
## True if the last redraw showed walls (one more redraw clears them).
var _drawn: bool = false


func _ready() -> void:
	z_index = 1


## Tracks the walking direction, raises walls and ticks / expires them.
func step(delta: float, stats: Dictionary) -> void:
	_phase += delta
	var v := game.player.velocity  # Current movement (px/s).
	if v.length_squared() > 1.0:
		_facing = v.normalized()
	_timer -= delta
	if _timer <= 0.0:
		_timer = float(stats["cooldown"]) if _cast(stats) else AbilityData.SPELL_RETRY
	var i := 0  # Index into _walls (ordered: the oldest is dropped first).
	while i < _walls.size():
		var w := _walls[i]
		if _step_wall(w, delta):
			i += 1
		else:
			_walls.remove_at(i)
			_seg_count -= w.segs.size()
			_pool.append(w)
	if not _walls.is_empty() or _drawn:
		queue_redraw()
	_drawn = not _walls.is_empty()


## Raises one wall (or Bastion ring). Returns false when no enemy is near or
## no segment fits (the cooldown is not spent).
func _cast(stats: Dictionary) -> bool:
	var p := game.player.position  # Necromancer.
	var target := _aim_target(p)  # Enemy the wall faces (null = nobody near).
	if target == null:
		return false
	var bastion := stats.has("pulse_damage")  # Evolved into Charnel Bastion.
	var r := GraveSpellData.BONE_WALL_SEGMENT_RADIUS  # Segment radius (px).
	var w: Wall = _pool.pop_back() if not _pool.is_empty() else Wall.new()
	w.segs.clear()
	w.ring = bastion
	w.center = p
	if bastion:
		var ring_r := float(stats["radius"])  # Ring radius (px, area-scaled).
		var n := maxi(8, ceili(TAU * ring_r / GraveSpellData.BASTION_SPACING))  # Segments on the ring.
		for k in n:
			var q := p + Vector2.from_angle(TAU * float(k) / float(n)) * ring_r
			if not game.arena.is_blocked(q, r):
				w.segs.append(q)
	else:
		var dir := (target.position - p).normalized() if target.position.distance_to(p) > 0.01 else _facing  # Wall facing.
		var mid := p + dir * float(stats["distance"])  # Wall centre.
		var across := dir.orthogonal()  # Along the wall.
		var n := int(stats["segments"])
		for k in n:
			var q := mid + across * (float(k) - float(n - 1) * 0.5) * GraveSpellData.BONE_WALL_SPACING
			if not game.arena.is_blocked(q, r):
				w.segs.append(q)
		w.normal = -dir  # An enemy on a segment centre is pushed back toward where it came from.
	if w.segs.is_empty():
		_pool.append(w)
		return false
	# The Barrow Warden's Stonebone innate (CharacterData bone_wall_duration;
	# 0 for every other character) lengthens every wall and Bastion ring.
	var stone := game.character.innate_value("bone_wall_duration")  # Extra lifetime fraction.
	w.duration = float(stats["duration"]) * (1.0 + stone)
	w.time_left = w.duration
	if stone > 0.0:
		game.stat_add("stonebone_extra_seconds", w.duration - float(stats["duration"]))
	w.tick = GraveSpellData.BONE_WALL_TICK
	w.damage = float(stats["damage"])
	w.shrapnel = float(stats.get("pulse_damage", 0.0))
	_walls.append(w)
	_seg_count += w.segs.size()
	while _seg_count > GraveSpellData.BONE_WALL_MAX_SEGMENTS and _walls.size() > 1:
		var old: Wall = _walls.pop_front()  # The oldest wall crumbles.
		_seg_count -= old.segs.size()
		_pool.append(old)
	game.stat_add("bastions_raised" if bastion else "walls_raised", 1.0)
	game.stat_add("wall_segments", float(w.segs.size()))
	for k in w.segs.size():
		if not bastion or k % 3 == 0:
			game.effects.ring(w.segs[k], r * 1.6, Palette.BONE, 0.25, "bone_wall_rise")
	Sfx.play("spear_cast" if not bastion else "lance_cast", p)
	game.player.cast_motion(p)  # Engine motion: a pulse as the wall rises (visual only).
	return true


## The enemy a new wall faces: the nearest within
## GraveSpellData.BONE_WALL_AIM_CONE of the walking direction, else the
## nearest within GraveSpellData.BONE_WALL_TRIGGER_RANGE (null if none).
func _aim_target(p: Vector2) -> Enemy:
	game.enemy_grid.query(p, GraveSpellData.BONE_WALL_TRIGGER_RANGE, _tmp)
	var near: Enemy = null  # Nearest enemy anywhere.
	var near_d := INF  # Its distance.
	var ahead: Enemy = null  # Nearest enemy inside the aim cone.
	var ahead_d := INF  # Its distance.
	for e: Enemy in _tmp:
		if not e.active:
			continue
		var to := e.position - p  # Offset to the enemy.
		var d := to.length()
		if d > GraveSpellData.BONE_WALL_TRIGGER_RANGE:
			continue
		if d < near_d:
			near_d = d
			near = e
		if d < ahead_d and d > 0.01 and absf(_facing.angle_to(to)) <= GraveSpellData.BONE_WALL_AIM_CONE:
			ahead_d = d
			ahead = e
	return ahead if ahead != null else near


## Ticks one wall: spike damage on the tick, the shrapnel burst on expiry.
## Returns false once it has crumbled.
func _step_wall(w: Wall, delta: float) -> bool:
	w.time_left -= delta
	w.tick -= delta
	if w.tick <= 0.0 and w.time_left > 0.0:
		w.tick += GraveSpellData.BONE_WALL_TICK
		_spike_tick(w)
	if w.time_left > 0.0:
		return true
	if w.shrapnel > 0.0:
		_shrapnel(w)
	return false


## One spike tick: `damage` once to every enemy pressing on the wall.
func _spike_tick(w: Wall) -> void:
	var src := "bastion" if w.ring else "bone_wall"  # Stats tag.
	var reach := GraveSpellData.BONE_WALL_SEGMENT_RADIUS + GraveSpellData.BONE_WALL_TOUCH_MARGIN  # Touch reach beyond the body.
	_seen.clear()
	for q: Vector2 in w.segs:
		game.enemy_grid.query(q, reach + ProjectileManager.MAX_BODY_RADIUS, _hit)
		for e: Enemy in _hit:
			if e.active and not _seen.has(e) and e.position.distance_to(q) <= reach + e.radius:
				_seen.append(e)
	for e: Enemy in _seen:
		if e.active:
			game.combat.damage_enemy(e, w.damage, src)
	game.stat_add("wall_spike_hits", float(_seen.size()))
	_seen.clear()


## Charnel Bastion expiry: shrapnel once to every enemy near any segment.
func _shrapnel(w: Wall) -> void:
	var r := GraveSpellData.BASTION_SHRAPNEL_RADIUS  # Burst reach (px).
	_seen.clear()
	for q: Vector2 in w.segs:
		game.enemy_grid.query(q, r + ProjectileManager.MAX_BODY_RADIUS, _hit)
		for e: Enemy in _hit:
			if e.active and not _seen.has(e) and e.position.distance_to(q) <= r + e.radius:
				_seen.append(e)
	var victims := _seen.duplicate()  # Own copy: kills may run other hooks.
	_seen.clear()
	for e: Enemy in victims:
		if e.active:
			game.combat.damage_enemy(e, w.shrapnel, "bastion_shrapnel")
	for k in w.segs.size():
		if k % 2 == 0:
			game.effects.ring(w.segs[k], r, Palette.BONE, 0.3, "bone_wall_burst")
	game.effects.ring(w.center, (w.segs[0] - w.center).length() + r, Palette.NECRO_GREEN, 0.4)
	game.stat_add("bastion_bursts", 1.0)
	game.shake(2.0)
	Sfx.play("eruption", w.center)


## Push-out pass (NecroSpellBook.after_physics, after Arena.resolve_all()):
## every held enemy body overlapping a segment is moved out of it. Counts
## enemy-seconds held (wall_hold_seconds) and push-outs (wall_pushes).
func after_physics(delta: float) -> void:
	if _walls.is_empty():
		return
	var r := GraveSpellData.BONE_WALL_SEGMENT_RADIUS  # Segment radius (px).
	_seen.clear()
	for w in _walls:
		for q: Vector2 in w.segs:
			# The grid was built at the start of the tick: the slack covers this tick's moves.
			game.enemy_grid.query(q, r + ProjectileManager.MAX_BODY_RADIUS + GraveSpellData.BONE_WALL_GRID_SLACK, _hit)
			for e: Enemy in _hit:
				if not e.active or not _holds(e):
					continue
				var diff := e.position - q  # Segment centre -> enemy.
				var d := diff.length()
				var min_d := r + e.radius  # Touching distance.
				if d >= min_d:
					continue
				var n := diff / d if d > 0.01 else (_ring_normal(w, q) if w.ring else w.normal)  # Push direction.
				e.position += n * (min_d - d)
				game.stat_add("wall_pushes", 1.0)
				if not _seen.has(e):
					_seen.append(e)
	game.stat_add("wall_hold_seconds", float(_seen.size()) * delta)
	_seen.clear()


## True if a wall holds enemy `e` (bosses, minibosses, Reckoning enemies and
## Crimson March structures / carts pass; see the header).
static func _holds(e: Enemy) -> bool:
	return not (e.is_boss or e.is_miniboss or e.is_reckoning or e.is_structure)


## Fallback push direction on a ring segment: away from the ring centre.
static func _ring_normal(w: Wall, q: Vector2) -> Vector2:
	var out := q - w.center  # Centre -> segment.
	return out.normalized() if out.length_squared() > 0.01 else Vector2.RIGHT


## Autotest counters (NecroSpellBook.later_summary_line()).
func summary_extra() -> String:
	var st := game.stats  # Run counters.
	return "walls=%d bastions=%d segments=%d pushes=%d hold_s=%d spike_hits=%d bursts=%d" % [
		int(st.get("walls_raised", 0.0)), int(st.get("bastions_raised", 0.0)), int(st.get("wall_segments", 0.0)),
		int(st.get("wall_pushes", 0.0)), int(st.get("wall_hold_seconds", 0.0)), int(st.get("wall_spike_hits", 0.0)),
		int(st.get("bastion_bursts", 0.0))]


func _draw() -> void:
	var r := GraveSpellData.BONE_WALL_SEGMENT_RADIUS  # Segment radius (px).
	for w in _walls:
		var age := w.duration - w.time_left  # Seconds standing.
		var rise := clampf(age / GraveSpellData.BONE_WALL_RISE_TIME, 0.0, 1.0)  # 0 -> 1 as it rises.
		var fade := clampf(w.time_left / GraveSpellData.BONE_WALL_RISE_TIME, 0.0, 1.0)  # 1 -> 0 as it crumbles.
		for k in w.segs.size():
			GraveSpellGlyphs.draw_wall_segment(self, w.segs[k], r, minf(rise, fade), k, w.ring, _phase)
