## Undertow — the Undertow spell (AbilityData "undertow", Act II, GDD §15.0
## "Gullhaven Harbour (Act II phase 2)"; owner-approved: "a wave rolls out in
## the aim direction, hits a 120° cone and shoves enemies back. Every third
## wave leaves shallow water that slows enemies for 3 s"). Unlocked by slaying
## Abbot Merrow (UnlockData); offered on every stage once unlocked.
##   * Every `cooldown` s, when an enemy is within `range` (+ a margin), a wave
##     rolls toward the aim: the nearest enemy inside UndertowData.AIM_CONE of
##     the walking direction, else the nearest enemy (Bone Spear's aim
##     assist). Every live enemy inside the cone (UndertowData.CONE_HALF_ANGLE
##     each side, out to `range` px) takes `damage` (source "undertow") and is
##     shoved back: a `push` px/s impulse along the necromancer -> enemy line,
##     divided by its mass, decaying like every knockback (bosses and
##     minibosses shrug it off in their own physics).
##   * Every UndertowData.SHALLOWS_EVERY-th wave (the Brine Widow's Riptide
##     innate makes it every second) also leaves a patch of shallow water out
##     along the aim for UndertowData.SHALLOWS_LIFE s: enemies in it are slowed
##     by `slow` for `slow_duration` s (CombatResolver.slow_enemy(): Spirit
##     Binding, Mournsong and Lingering Malediction lengthen it).
##   * Evolved into MAELSTROM (EvolutionData "maelstrom", detected by its
##     "whirl_damage" key): each wave ends in a whirlpool at the cone's heart
##     for `whirl_life` s that drags every enemy within
##     UndertowData.WHIRL_DRAG_RADIUS_MULT x `whirl_radius` toward its centre
##     at `whirl_pull` px/s (one knot) and grinds those inside `whirl_radius`
##     for `whirl_damage` every `whirl_tick` s (source "maelstrom"). Bosses and
##     minibosses are slowed, never dragged (owner-approved); structures and
##     the Reckoning are never dragged either.
## Damage goes through CombatResolver, so Salt of the Deep (more damage to
## slowed, chilled or frozen foes) multiplies on the shoved, slowed crowd.
## Drawn as rolling arcs of water (and the shallows and whirlpools under the
## bodies); the drawing never touches gameplay state. Deterministic: no RNG.
## Stats: undertow_waves, undertow_hits, undertow_shallows, undertow_slows,
## maelstrom_whirls, maelstrom_drags (enemy-ticks dragged), maelstrom_boss_slows.
class_name Undertow
extends NecroSpell

## One drawn wave (purely visual).
class Wave:
	extends RefCounted
	## Origin (world px).
	var at: Vector2 = Vector2.ZERO
	## Aim (unit).
	var dir: Vector2 = Vector2.RIGHT
	## Reach (px).
	var reach: float = 150.0
	## Seconds since it was cast.
	var t: float = 0.0

## One patch of shallow water.
class Shallows:
	extends RefCounted
	## Centre (world px).
	var pos: Vector2 = Vector2.ZERO
	## Radius (px).
	var radius: float = 60.0
	## Seconds left.
	var life: float = 0.0
	## Seconds until its next slow tick.
	var tick: float = 0.0

## One Maelstrom whirlpool.
class Whirl:
	extends RefCounted
	## Centre (world px).
	var pos: Vector2 = Vector2.ZERO
	## Seconds left.
	var life: float = 0.0
	## Seconds until its next grind tick.
	var tick: float = 0.0
	## Grind radius (px) when it formed (drawing only: the sprite's size).
	var radius: float = 60.0

## Seconds until the next wave.
var _timer: float = 0.6
## Last walking direction (unit).
var _facing: Vector2 = Vector2.RIGHT
## Waves cast so far (shallows every Nth).
var _waves: int = 0
## Drawn waves.
var _drawn_waves: Array[Wave] = []
## Live shallow-water patches.
var _shallows: Array[Shallows] = []
## Live whirlpools.
var _whirls: Array[Whirl] = []
## True if the last redraw showed something (one more redraw clears it).
var _drawn: bool = false


func _ready() -> void:
	z_index = -5  # On the ground: over the water and obstacles' bases, under bodies.


## Casts on cooldown, ages the patches and whirlpools, redraws.
func step(delta: float, stats: Dictionary) -> void:
	var v := game.player.velocity  # Current movement (px/s).
	if v.length_squared() > 1.0:
		_facing = v.normalized()
	_timer -= delta
	if _timer <= 0.0:
		_timer = float(stats["cooldown"]) if _cast(stats) else AbilityData.SPELL_RETRY
	_step_shallows(delta, stats)
	_step_whirls(delta, stats)
	var i := 0  # Index into _drawn_waves (swap-remove).
	while i < _drawn_waves.size():
		_drawn_waves[i].t += delta
		if _drawn_waves[i].t >= UndertowData.WAVE_TIME:
			_drawn_waves[i] = _drawn_waves[_drawn_waves.size() - 1]
			_drawn_waves.pop_back()
		else:
			i += 1
	var busy := not _drawn_waves.is_empty() or not _shallows.is_empty() or not _whirls.is_empty()
	if busy or _drawn:
		queue_redraw()
	_drawn = busy


## Rolls one wave. Returns false when no enemy is near enough.
func _cast(stats: Dictionary) -> bool:
	var p := game.player.position  # Wave origin.
	var reach := float(stats["range"])
	game.enemy_grid.query(p, reach + UndertowData.TRIGGER_MARGIN, _tmp)
	var near: Enemy = null  # Nearest enemy anywhere.
	var near_d := INF
	var ahead: Enemy = null  # Nearest enemy inside the aim cone.
	var ahead_d := INF
	for e: Enemy in _tmp:
		if not e.active:
			continue
		var to := e.position - p
		var d := to.length()
		if d > reach + UndertowData.TRIGGER_MARGIN:
			continue
		if d < near_d:
			near_d = d
			near = e
		if d < ahead_d and d > 0.01 and absf(_facing.angle_to(to)) <= UndertowData.AIM_CONE:
			ahead_d = d
			ahead = e
	if near == null:
		return false
	var target := ahead if ahead != null else near
	var aim := (target.position - p).normalized() if p.distance_to(target.position) > 0.01 else _facing  # Wave heading.
	var src := "maelstrom" if stats.has("whirl_damage") else "undertow"  # Stats tag.
	var hits: Array = []  # Own buffer: kill hooks may query the grid again.
	game.enemy_grid.query(p, reach + ProjectileManager.MAX_BODY_RADIUS, hits)
	var n := 0  # Enemies hit.
	for e: Enemy in hits:
		if not e.active or not CovenantKit.in_sector(p, aim, reach, UndertowData.CONE_HALF_ANGLE, game.player.radius, e.position, e.radius):
			continue
		var away := e.position - p
		var push := (away.normalized() if away.length() > 0.5 else aim) * float(stats["push"]) / maxf(e.mass, 0.1)  # Shove impulse.
		if not e.is_structure:
			e.knockback += push
		game.combat.damage_enemy(e, float(stats["damage"]), src)
		n += 1
	_waves += 1
	game.stat_add("undertow_waves", 1.0)
	game.stat_add("undertow_hits", float(n))
	var every := UndertowData.SHALLOWS_EVERY  # Waves per shallow-water patch.
	var riptide := int(game.character.innate_value("undertow_shallows_every"))  # The Brine Widow's Riptide (0 = none).
	if riptide > 0:
		every = mini(every, riptide)
	if _waves % maxi(1, every) == 0:
		_add_shallows(p + aim * reach * UndertowData.SHALLOWS_AT, reach * UndertowData.SHALLOWS_RADIUS_SHARE)
		if riptide > 0 and riptide < UndertowData.SHALLOWS_EVERY and _waves % UndertowData.SHALLOWS_EVERY != 0:
			game.stat_add("riptide_extra_shallows", 1.0)  # Patches only the innate allowed.
	if stats.has("whirl_damage"):
		_add_whirl(p + aim * reach * UndertowData.SHALLOWS_AT, stats)
	_add_wave(p, aim, reach)
	game.player.cast_motion(p + aim)  # Engine motion: toward the wave (visual only).
	Sfx.play("plague_cast", p, 0.75)
	return true


## A new patch of shallow water (the oldest dries up beyond the cap).
func _add_shallows(pos: Vector2, r: float) -> void:
	if _shallows.size() >= UndertowData.SHALLOWS_MAX:
		_shallows.remove_at(0)
	var s := Shallows.new()
	s.pos = pos
	s.radius = r
	s.life = UndertowData.SHALLOWS_LIFE
	s.tick = 0.0
	_shallows.append(s)
	game.stat_add("undertow_shallows", 1.0)


## Ages the patches; enemies standing in one are slowed.
func _step_shallows(delta: float, stats: Dictionary) -> void:
	var i := 0
	while i < _shallows.size():
		var s := _shallows[i]
		s.life -= delta
		if s.life <= 0.0:
			_shallows.remove_at(i)
			continue
		s.tick -= delta
		if s.tick <= 0.0:
			s.tick = UndertowData.SHALLOWS_TICK
			game.enemy_grid.query(s.pos, s.radius + ProjectileManager.MAX_BODY_RADIUS, _tmp)
			for e: Enemy in _tmp:
				if e.active and not e.is_structure and e.position.distance_to(s.pos) <= s.radius + e.radius:
					game.combat.slow_enemy(e, float(stats["slow"]), float(stats["slow_duration"]))
					game.stat_add("undertow_slows", 1.0)
		i += 1


## A new Maelstrom whirlpool (the oldest collapses beyond the cap).
func _add_whirl(pos: Vector2, stats: Dictionary) -> void:
	if _whirls.size() >= UndertowData.WHIRL_MAX:
		_whirls.remove_at(0)
	var w := Whirl.new()
	w.pos = pos
	w.life = float(stats["whirl_life"])
	w.tick = 0.0
	w.radius = float(stats.get("whirl_radius", 60.0))
	_whirls.append(w)
	game.stat_add("maelstrom_whirls", 1.0)


## Drags enemies into each whirlpool's knot and grinds those at its heart;
## bosses and minibosses are slowed instead of dragged.
func _step_whirls(delta: float, stats: Dictionary) -> void:
	if _whirls.is_empty():
		return
	var r := float(stats.get("whirl_radius", 60.0))
	var drag_r := r * UndertowData.WHIRL_DRAG_RADIUS_MULT  # Drag reach (px).
	var pull := float(stats.get("whirl_pull", 0.0)) * delta  # px dragged this tick.
	var i := 0
	while i < _whirls.size():
		var w := _whirls[i]
		w.life -= delta
		if w.life <= 0.0:
			_whirls.remove_at(i)
			continue
		w.tick -= delta
		var grind := w.tick <= 0.0  # A damage tick this frame.
		if grind:
			w.tick = float(stats["whirl_tick"])
		var hits: Array = []  # Own buffer: kill hooks may query the grid again.
		game.enemy_grid.query(w.pos, drag_r + ProjectileManager.MAX_BODY_RADIUS, hits)
		for e: Enemy in hits:
			if not e.active or e.is_structure:
				continue
			var to := w.pos - e.position
			var d := to.length()
			if d > drag_r + e.radius:
				continue
			if e.is_boss or e.is_miniboss:
				if grind:
					game.combat.slow_enemy(e, UndertowData.WHIRL_BOSS_SLOW, float(stats["whirl_tick"]) * 1.5)
					game.stat_add("maelstrom_boss_slows", 1.0)
			elif not e.is_reckoning and d > UndertowData.WHIRL_KNOT:
				e.position += to / d * minf(pull, d - UndertowData.WHIRL_KNOT)
				game.stat_add("maelstrom_drags", delta)
			if grind and d <= r + e.radius:
				game.combat.damage_enemy(e, float(stats["whirl_damage"]), "maelstrom")
		i += 1


## A drawn wave (the oldest is dropped beyond the cap).
func _add_wave(at: Vector2, dir: Vector2, reach: float) -> void:
	if _drawn_waves.size() >= UndertowData.WAVE_MAX:
		_drawn_waves.remove_at(0)
	var w := Wave.new()
	w.at = at
	w.dir = dir
	w.reach = reach
	_drawn_waves.append(w)


## Autotest counters (the Undertow line, HarbourReport).
func summary_extra() -> String:
	var st := game.stats
	var waves := maxf(1.0, float(st.get("undertow_waves", 0.0)))
	return "waves=%d hits=%d avg_hits=%.1f shallows=%d slows=%d whirlpools=%d drag_s=%.0f boss_slows=%d" % [
		int(st.get("undertow_waves", 0.0)), int(st.get("undertow_hits", 0.0)), float(st.get("undertow_hits", 0.0)) / waves,
		int(st.get("undertow_shallows", 0.0)), int(st.get("undertow_slows", 0.0)), int(st.get("maelstrom_whirls", 0.0)),
		float(st.get("maelstrom_drags", 0.0)), int(st.get("maelstrom_boss_slows", 0.0))]


func _draw() -> void:
	# Pixel art (MarkerArtData "Gullhaven Harbour": the foam crests of the wave and
	# of the shallows' rim, the whirlpool); the code shapes below are the fallback.
	var crest_art := SpriteBank.has(MarkerArtData.UNDERTOW_CREST)  # Foam crest sprite present.
	for s in _shallows:
		var a := clampf(s.life / 0.8, 0.0, 1.0)  # Fades as it dries.
		if crest_art:
			# A soft pool (the shared disc texture, no per-frame polygon) inside a rim of foam crests.
			SpriteBank.draw_disc(self, s.pos, s.radius, Color(UndertowData.SHALLOWS_COLOR, UndertowData.SHALLOWS_COLOR.a * a))
			var rim := maxi(6, ceili(TAU * s.radius / MarkerArtData.UNDERTOW_SHALLOWS_RIM_STEP))  # Crests on the rim.
			for i in rim:
				var ang := TAU * float(i) / float(rim)  # This crest's angle (rad), facing outward.
				SpriteBank.draw_flat(self, MarkerArtData.UNDERTOW_CREST, s.pos + Vector2.from_angle(ang) * s.radius, ang,
						Color(1.0, 1.0, 1.0, MarkerArtData.UNDERTOW_SHALLOWS_RIM_ALPHA * a))
			continue
		draw_circle(s.pos, s.radius, Color(UndertowData.SHALLOWS_COLOR, UndertowData.SHALLOWS_COLOR.a * a))
		draw_arc(s.pos, s.radius, 0.0, TAU, 28, Color(UndertowData.FOAM_COLOR, 0.25 * a), 1.0)
	var whirl_art := SpriteBank.has(MarkerArtData.MAELSTROM_WHIRL)  # Whirlpool sprite present.
	var whirl_px := float(SpriteData.FLAT_SIZES.get(MarkerArtData.MAELSTROM_WHIRL, 96.0))  # Its drawn size at scale 1 (px).
	for w in _whirls:
		var spin := w.life * 6.0  # Turning arms (visual).
		if whirl_art:
			var fade := clampf(w.life / 0.4, 0.0, 1.0)  # Fades out in its last 0.4 s.
			SpriteBank.draw_flat(self, MarkerArtData.MAELSTROM_WHIRL, w.pos, -spin, Color(1.0, 1.0, 1.0, 0.9 * fade),
					w.radius * 2.0 * MarkerArtData.MAELSTROM_WHIRL_FILL / whirl_px)
			continue
		var r := 18.0 + 10.0 * sin(w.life * 3.0)
		for k in 3:
			var a0 := spin + TAU * float(k) / 3.0
			draw_arc(w.pos, r + float(k) * 9.0, a0, a0 + 2.2, 12, Color(UndertowData.WHIRL_COLOR, 0.7 - 0.15 * float(k)), 2.0)
		draw_circle(w.pos, 5.0, Color(UndertowData.WHIRL_COLOR.darkened(0.4), 0.8))
	for w in _drawn_waves:
		var k := clampf(w.t / UndertowData.WAVE_TIME, 0.0, 1.0)  # 0 -> 1 as it rolls out.
		var r := lerpf(16.0, w.reach, k)
		var a0 := w.dir.angle() - UndertowData.CONE_HALF_ANGLE
		var a1 := w.dir.angle() + UndertowData.CONE_HALF_ANGLE
		if crest_art:
			# A rolling line of foam crests along the arc, each facing outward.
			var n := maxi(2, ceili(r * (a1 - a0) / MarkerArtData.UNDERTOW_CREST_STEP))  # Crests on this arc.
			var tint := Color(1.0, 1.0, 1.0, 1.0 - k * 0.6)  # Fades as it spends itself.
			for i in n:
				var ang := a0 + (a1 - a0) * (float(i) + 0.5) / float(n)  # This crest's angle (rad).
				SpriteBank.draw_flat(self, MarkerArtData.UNDERTOW_CREST, w.at + Vector2.from_angle(ang) * r, ang, tint)
			continue
		if SpriteBank.has_anim("undertow_wave"):
			SpriteBank.draw_anim(self, "undertow_wave", w.at + w.dir * r * 0.55, r * 1.2, k, 1.0 - k * 0.5)
		draw_arc(w.at, r, a0, a1, 18, Color(UndertowData.WAVE_COLOR, 0.85 * (1.0 - k * 0.6)), 6.0)
		draw_arc(w.at, r + 3.0, a0, a1, 18, Color(UndertowData.FOAM_COLOR, 0.9 * (1.0 - k)), 2.0)
