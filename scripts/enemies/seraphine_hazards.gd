## SeraphineHazards — the battlefield hazards of Grand Inquisitor Seraphine
## (BossSeraphine, GDD §7.5), kept in world space because the boss node is
## mirrored for facing. It times, resolves and draws:
##   * delayed holy circles  — gold warning circles (EffectManager
##                             telegraph_circle) that blast after their delay;
##   * rotating holy beams   — thin warning rays, then two bright beams that
##                             sweep around her and pulse damage on the
##                             necromancer and every summon they cross;
##   * the Judgment nova     — the whole area around her glows gold while 2-3
##                             cool, dark safe circles are marked; when it
##                             detonates, the necromancer and summons outside
##                             the safe circles take heavy holy damage;
##   * the collapsing arena  — holy fire closing in from the rim of a circle
##                             around her (the Last Light), burning whatever
##                             stands outside it.
## Her undead suppression is not here: it goes through the horde's one
## suppression path (HordeDirector.add_suppression(), SuppressionField),
## which times and draws it.
## The boss steps it from its own physics step, so every hazard pauses while
## she is frozen (Stasis, Deep Freeze), like her telegraphs. Damage goes
## through CombatResolver; nothing here uses randomness (the boss picks every
## position), so runs stay deterministic per seed. All numbers come from
## SeraphineData.BOSS. Ground parts draw under the bodies (z_index below);
## beams, flames and safe-circle rims draw on `overlay`, above them.
class_name SeraphineHazards
extends Node2D

## Draw layer of the ground parts (above telegraphs and obstacles, under bodies).
const GROUND_Z: int = -4
## Draw layer of the bright parts (over bodies, under projectiles).
const OVERLAY_Z: int = 3
## Segments of the collapse fire ring and other large circles.
const RING_SEGMENTS: int = 72
## Flame tongues licking inward along the collapse edge.
const FLAME_TONGUES: int = 56
## How far (px) outside the collapse edge the drawn fire band reaches.
const FIRE_BAND: float = 900.0
## Seconds the safe circles keep glowing after a nova blast.
const NOVA_AFTERGLOW: float = 0.5

## One delayed holy circle.
class HolyCircle:
	extends RefCounted
	## World-space centre.
	var pos: Vector2 = Vector2.ZERO
	## Radius in px.
	var radius: float = 50.0
	## Seconds left until it blasts.
	var left: float = 1.0

## Owning run.
var game: Game
## The boss these hazards belong to.
var boss: BossSeraphine
## SeraphineData.BOSS (numbers).
var def: Dictionary = {}
## Bright layer drawn over the bodies (beams, flames, safe-circle rims).
var overlay: Node2D
## Pending holy circles.
var circles: Array[HolyCircle] = []
## Beam state: 0 = none, 1 = warning rays, 2 = sweeping.
var beam_state: int = 0
## Angle (rad) of the first beam (the others are spread evenly).
var beam_angle: float = 0.0
## Sweep direction (+1 / -1).
var beam_dir: float = 1.0
## Sweep speed (rad/s).
var beam_speed: float = 0.85
## Seconds left in the current beam state.
var beam_left: float = 0.0
## Seconds until the next beam damage pulse.
var beam_tick_left: float = 0.0
## Seconds the beams sweep once their warning ends.
var beam_duration: float = 4.0
## True while a Judgment nova is telegraphed.
var nova_pending: bool = false
## Centre of the nova (her position at the cast).
var nova_center: Vector2 = Vector2.ZERO
## Seconds left until the nova blasts.
var nova_left: float = 0.0
## Total telegraph seconds (fill animation).
var nova_total: float = 2.5
## Centres of the safe circles.
var nova_safe: Array[Vector2] = []
## Seconds left of the safe circles' afterglow after a blast.
var nova_glow_left: float = 0.0
## True once the arena collapse started (the Last Light).
var collapse_on: bool = false
## Centre of the collapsing circle.
var collapse_center: Vector2 = Vector2.ZERO
## Seconds since the collapse started.
var collapse_t: float = 0.0
## Seconds until the next collapse damage tick.
var collapse_tick_left: float = 0.0
## Where a teleport will land (drawn while tele_left > 0).
var tele_dest: Vector2 = Vector2.ZERO
## Seconds left of the teleport landing marker (0 = none).
var tele_left: float = 0.0
## Total seconds of the landing marker (animation).
var tele_total: float = 1.0
## Reusable query buffer.
var _tmp: Array = []


## Binds the hazards to `p_boss` (call once, right after setup_boss()).
func setup(p_game: Game, p_boss: BossSeraphine) -> void:
	game = p_game
	boss = p_boss
	def = p_boss.boss_def
	z_index = GROUND_Z
	overlay = Node2D.new()
	overlay.z_index = OVERLAY_Z
	overlay.draw.connect(_draw_overlay)
	add_child(overlay)


## Advances every hazard by `delta` s (called by the boss's physics step).
func step(delta: float) -> void:
	_step_circles(delta)
	_step_beams(delta)
	_step_nova(delta)
	_step_collapse(delta)
	if tele_left > 0.0:
		tele_left -= delta
	queue_redraw()
	overlay.queue_redraw()


## Removes every hazard (the boss died): nothing more blasts or burns.
func clear() -> void:
	circles.clear()
	beam_state = 0
	nova_pending = false
	nova_glow_left = 0.0
	collapse_on = false
	tele_left = 0.0
	queue_redraw()
	overlay.queue_redraw()


## Shows where a teleport lands for `duration` s (a column of light and a
## closing ring); `duration` 0 removes it (the teleport was cut short).
func mark_teleport(dest: Vector2, duration: float) -> void:
	tele_dest = dest
	tele_left = duration
	tele_total = maxf(0.05, duration)


# =====================================================================================
# Delayed holy circles
# =====================================================================================

## Marks a holy circle at `pos` that blasts after `delay` s (gold warning
## circle owned by the boss, so it pauses with her).
func add_circle(pos: Vector2, radius: float, delay: float) -> void:
	var c := HolyCircle.new()
	c.pos = pos
	c.radius = radius
	c.left = delay
	circles.append(c)
	game.effects.telegraph_circle(pos, radius, delay, boss)


## Counts circles down and blasts the ready ones.
func _step_circles(delta: float) -> void:
	var i := 0
	while i < circles.size():
		var c := circles[i]
		c.left -= delta
		if c.left > 0.0:
			i += 1
			continue
		_blast_circle(c)
		circles.remove_at(i)


## A holy circle blasts: summons inside and the necromancer take its damage.
func _blast_circle(c: HolyCircle) -> void:
	game.effects.impact(c.pos, c.radius, Palette.GOLD, "holy_impact")  # Animation when its art exists (visual only).
	game.shake(3.0)
	game.ally_grid.query(c.pos, c.radius + UnitData.MAX_BLOCK_RADIUS, _tmp)
	var hits := 0  # Summons caught.
	for u: SummonedUnit in _tmp:
		if u.active and u.state != SummonedUnit.State.SPAWNING and u.position.distance_to(c.pos) <= c.radius + u.radius:
			hits += 1
			game.combat.damage_unit(u, float(def["circles_damage_summon"]), "seraphine_circle")
	game.stat_add("seraphine_circle_summon_hits", float(hits))
	for pl in game.all_players:  # (Co-op: either necromancer.)
		if pl.position.distance_to(c.pos) <= c.radius + pl.radius:
			game.combat.damage_player(float(def["circles_damage_player"]) * game.enemies.damage_mult, "seraphine_circle", pl)


# =====================================================================================
# Rotating holy beams
# =====================================================================================

## Starts the beams: warning rays at `angle` for `telegraph` s, then a sweep
## in direction `dir` at `speed` rad/s for `duration` s.
func start_beams(angle: float, dir: float, speed: float, telegraph: float, duration: float) -> void:
	beam_state = 1
	beam_angle = angle
	beam_dir = dir
	beam_speed = speed
	beam_left = telegraph
	beam_tick_left = 0.0
	beam_duration = duration
	Sfx.play("boss_telegraph", boss.position)


## True while the beams are telegraphed or sweeping (she channels them).
func beams_busy() -> bool:
	return beam_state != 0


## Ends the beams at once (phase change).
func stop_beams() -> void:
	beam_state = 0


## Unit direction of beam `i`.
func _beam_vec(i: int) -> Vector2:
	var n := int(def["beams_count"])
	return Vector2.from_angle(beam_angle + TAU * float(i) / float(maxi(1, n)))


## Warning -> sweep -> done; damage pulses every beams_tick s while sweeping.
func _step_beams(delta: float) -> void:
	if beam_state == 0:
		return
	beam_left -= delta
	if beam_state == 1:
		if beam_left <= 0.0:
			beam_state = 2
			beam_left = beam_duration
			game.effects.ring(boss.position, boss.radius * 3.0, Palette.IVORY, 0.4, "holy_beam")
			Sfx.play("boss_impact", boss.position, 1.6)
		return
	beam_angle += beam_dir * beam_speed * delta
	beam_tick_left -= delta
	if beam_tick_left <= 0.0:
		beam_tick_left += float(def["beams_tick"])
		_beam_pulse()
	if beam_left <= 0.0:
		beam_state = 0


## True if a body of radius `r` at `p` lies in beam `i`.
func _in_beam(i: int, p: Vector2, r: float) -> bool:
	var v := _beam_vec(i)
	var rel := p - boss.position
	var along := rel.dot(v)
	if along < 0.0 or along > float(def["beams_length"]) + r:
		return false
	return absf(rel.cross(v)) <= float(def["beams_width"]) * 0.5 + r


## One damage pulse of every beam on the necromancer and the summons.
func _beam_pulse() -> void:
	var n := int(def["beams_count"])
	for pl in game.all_players:  # (Co-op: either necromancer.)
		for i in n:
			if _in_beam(i, pl.position, pl.radius):
				game.combat.damage_player(float(def["beams_damage_player"]) * game.enemies.damage_mult, "seraphine_beam", pl)
				game.stat_add("seraphine_beam_player_pulses", 1.0)
				break
	game.ally_grid.query(boss.position, float(def["beams_length"]) + UnitData.MAX_BLOCK_RADIUS, _tmp)
	var hits := 0  # Summon pulses this tick.
	for u: SummonedUnit in _tmp:
		if not u.active or u.state == SummonedUnit.State.SPAWNING:
			continue
		for i in n:
			if _in_beam(i, u.position, u.radius):
				hits += 1
				game.combat.damage_unit(u, float(def["beams_damage_summon"]), "seraphine_beam")
				break
	game.stat_add("seraphine_beam_summon_pulses", float(hits))


# =====================================================================================
# Judgment nova
# =====================================================================================

## Telegraphs a Judgment nova around `center` with safe circles at `safe`;
## it blasts after `telegraph` s.
func start_nova(center: Vector2, safe: Array[Vector2], telegraph: float) -> void:
	nova_pending = true
	nova_center = center
	nova_safe = safe
	nova_left = telegraph
	nova_total = telegraph
	nova_glow_left = 0.0
	Sfx.play("boss_telegraph", center)


## True if `p` (a body of radius `r`) stands inside a safe circle. The body
## only has to reach in with its centre (a fair, generous rule).
func in_safe(p: Vector2, _r: float) -> bool:
	var sr := float(def["nova_safe_radius"])
	for s in nova_safe:
		if p.distance_to(s) <= sr:
			return true
	return false


## Counts the nova down and blasts it.
func _step_nova(delta: float) -> void:
	if nova_glow_left > 0.0:
		nova_glow_left -= delta
	if not nova_pending:
		return
	nova_left -= delta
	if nova_left <= 0.0:
		nova_pending = false
		nova_glow_left = NOVA_AFTERGLOW
		_blast_nova()


## The nova blasts: everything within nova_radius of its centre and outside
## every safe circle takes heavy holy damage.
func _blast_nova() -> void:
	var r := float(def["nova_radius"])
	game.effects.ring(nova_center, r, Palette.GOLD, 0.55, "seraphine_nova")
	game.effects.impact(nova_center, boss.radius * 4.0, Palette.IVORY, "holy_impact")  # The nova's centre flash (animation when its art exists).
	for s in nova_safe:
		game.effects.ring(s, float(def["nova_safe_radius"]), Palette.COLD_BLUE, 0.5)
	game.shake(9.0)
	Sfx.play("boss_impact", nova_center, 0.8)
	game.stat_add("seraphine_novas", 1.0)
	for pl in game.all_players:  # (Co-op: either necromancer.)
		if pl.position.distance_to(nova_center) <= r:
			if in_safe(pl.position, pl.radius):
				game.stat_add("seraphine_nova_player_safe", 1.0)
			else:
				game.combat.damage_player(float(def["nova_damage_player"]) * game.enemies.damage_mult, "seraphine_nova", pl)
				game.stat_add("seraphine_nova_player_hit", 1.0)
	var hit := 0  # Summons burned.
	var spared := 0  # Summons standing in a safe circle.
	for h in game.all_hordes:  # (Co-op: every army.)
		for u in h.units:
			if not u.active or u.state == SummonedUnit.State.SPAWNING or u.position.distance_to(nova_center) > r:
				continue
			if in_safe(u.position, u.radius):
				spared += 1
				continue
			hit += 1
			game.combat.damage_unit(u, float(def["nova_damage_summon"]), "seraphine_nova")
	game.stat_add("seraphine_nova_summon_hits", float(hit))
	game.stat_add("seraphine_nova_summon_spared", float(spared))


# =====================================================================================
# Collapsing arena
# =====================================================================================

## Starts the collapse around `center` (the Last Light).
func start_collapse(center: Vector2) -> void:
	collapse_on = true
	collapse_center = center
	collapse_t = 0.0
	collapse_tick_left = float(def["collapse_tick"])


## Current radius (px) of the shrinking circle (INF before the collapse).
func collapse_radius() -> float:
	if not collapse_on:
		return INF
	var k := clampf(collapse_t / float(def["collapse_time"]), 0.0, 1.0)
	return lerpf(float(def["collapse_start_radius"]), float(def["collapse_end_radius"]), k)


## Shrinks the circle and burns whatever stands outside it every tick.
func _step_collapse(delta: float) -> void:
	if not collapse_on:
		return
	collapse_t += delta
	collapse_tick_left -= delta
	if collapse_tick_left > 0.0:
		return
	collapse_tick_left += float(def["collapse_tick"])
	var r := collapse_radius()
	for pl in game.all_players:  # (Co-op: either necromancer.)
		if pl.position.distance_to(collapse_center) > r:
			game.combat.damage_player(float(def["collapse_damage_player"]) * game.enemies.damage_mult, "seraphine_collapse", pl)
			game.stat_add("seraphine_collapse_player_ticks", 1.0)
	var burned := 0  # Summons outside this tick.
	for h in game.all_hordes:  # (Co-op: every army.)
		for u in h.units:
			if u.active and u.state != SummonedUnit.State.SPAWNING and u.position.distance_to(collapse_center) > r:
				burned += 1
				game.combat.damage_unit(u, float(def["collapse_damage_summon"]), "seraphine_collapse")
	game.stat_add("seraphine_collapse_summon_ticks", float(burned))


# =====================================================================================
# Autopilot hint
# =====================================================================================

## Danger push at `p` for the autotest autopilot: out of holy circles, out
## of the beams' path, into a safe circle before the nova, and back inside
## the collapsing arena.
func danger_push(p: Vector2) -> Vector2:
	var push := Vector2.ZERO
	for c in circles:
		var diff := p - c.pos
		var d := diff.length()
		var reach := c.radius + 30.0
		if d < reach:
			push += (diff / d if d > 0.1 else Vector2.RIGHT) * (1.0 - d / reach * 0.5)
	if beam_state != 0:
		var rel := p - boss.position
		var d := rel.length()
		if d < float(def["beams_length"]) + 30.0 and d > 0.1:
			for i in int(def["beams_count"]):
				# Angle from the beam to `p`, measured in the sweep direction.
				var ahead := wrapf((rel.angle() - _beam_vec(i).angle()) * beam_dir, 0.0, TAU)
				if ahead < 0.7:
					push += rel / d
					break
	if nova_pending:
		var sr := float(def["nova_safe_radius"])
		var best := Vector2.INF
		var best_d := INF
		for s in nova_safe:
			var d := p.distance_to(s)
			if d < best_d:
				best_d = d
				best = s
		if best != Vector2.INF:
			if best_d > sr * 0.7:
				push += (best - p).normalized() * (1.0 if best_d > sr else 0.4)
	if collapse_on:
		var r := collapse_radius()
		var off := p - collapse_center
		var d := off.length()
		if d > r - 70.0 and d > 0.1:
			push -= off / d * clampf((d - (r - 70.0)) / 70.0, 0.3, 1.0)
	return push.limit_length(1.0)


# =====================================================================================
# Drawing
# =====================================================================================

## The camera's view in world space, grown by a margin (px): the huge rings of
## the nova and the collapse draw only their pieces inside it (visual only).
func _view_cull() -> Rect2:
	if game == null or game.camera == null:
		return Rect2()
	var vs := game.view_size()  # Visible world size (px).
	return Rect2(game.camera.get_screen_center_position() - vs * 0.5, vs).grow(48.0)


## Ground parts: the nova glow and safe circles and the collapse fire band.
## With the Covenant pixel art (CovenantFx, GDD §15.0 "Act I enemy AoE art"):
## the nova's glow is the shared disc texture rippled by dashed pulse rings
## and edged by the telegraph band, each safe circle a baked cold sanctuary.
func _draw() -> void:
	var now := game.elapsed if game != null else 0.0  # Animation clock (visual only).
	if nova_pending and CovenantFx.has(CovenantFxData.NOVA_WAVE) and CovenantFx.has(CovenantFxData.T_EDGE):
		var kk := 1.0 - clampf(nova_left / nova_total, 0.0, 1.0)  # Telegraph progress 0..1.
		var rr := float(def["nova_radius"])
		var view := _view_cull()  # Pieces off the view are skipped.
		SpriteBank.draw_disc(self, nova_center, rr, Color(Palette.GOLD, 0.07 + 0.2 * kk))
		for j in 3:
			var f := fposmod(now * 0.9 + float(j) / 3.0, 1.0)
			CovenantFx.ring(self, nova_center, rr * f, CovenantFxData.NOVA_WAVE, Color(1.0, 1.0, 1.0, 0.5 * (1.0 - f) + 0.15 * kk), 1.0,
				0.0, TAU, 0.0, "", 0, view)
		CovenantFx.ring(self, nova_center, rr, CovenantFxData.T_EDGE, Color(1.0, 1.0, 1.0, 0.7 + 0.3 * kk), CovenantFxData.T_EDGE_ROW,
			0.0, TAU, 0.0, CovenantFxData.T_EDGE_TOOTH, CovenantFxData.T_TOOTH_EVERY, view)
		var ssr := float(def["nova_safe_radius"])
		for s in nova_safe:
			if not CovenantFx.disc(self, s, ssr, CovenantFxData.SAFE_DISCS):
				draw_circle(s, ssr, Color(0.02, 0.05, 0.1, 0.82))
			SpriteBank.draw_disc(self, s, ssr * 0.6, Color(Palette.COLD_BLUE, 0.12 + 0.08 * sin(now * 8.0)))
		if collapse_on:
			_draw_collapse_band(collapse_radius(), now)
		return
	if nova_pending:
		var k := 1.0 - clampf(nova_left / nova_total, 0.0, 1.0)  # Telegraph progress 0..1.
		var r := float(def["nova_radius"])
		draw_circle(nova_center, r, Color(Palette.GOLD, 0.07 + 0.2 * k))
		# Radiant pulses rolling outward from her.
		for j in 3:
			var f := fposmod(now * 0.9 + float(j) / 3.0, 1.0)
			draw_arc(nova_center, r * f, 0.0, TAU, RING_SEGMENTS, Color(Palette.IVORY, 0.25 * (1.0 - f) + 0.1 * k), 3.0)
		draw_arc(nova_center, r, 0.0, TAU, RING_SEGMENTS, Color(Palette.GOLD, 0.6 + 0.3 * k), 4.0)
		var sr := float(def["nova_safe_radius"])
		for s in nova_safe:
			# The safe circle "cuts" a cool, dark hole in the gold glow.
			draw_circle(s, sr, Color(0.02, 0.05, 0.1, 0.82))
			draw_circle(s, sr * 0.6, Color(Palette.COLD_BLUE, 0.12 + 0.08 * sin(now * 8.0)))
	elif nova_glow_left > 0.0:
		var g := nova_glow_left / NOVA_AFTERGLOW  # Afterglow 1..0.
		for s in nova_safe:
			SpriteBank.draw_disc(self, s, float(def["nova_safe_radius"]), Color(Palette.COLD_BLUE, 0.25 * g))  # Shared disc texture.
	if collapse_on:
		_draw_collapse_band(collapse_radius(), now)


## Bright parts over the bodies: the beams, the safe-circle rims and the
## flames on the collapse edge.
func _draw_overlay() -> void:
	var now := game.elapsed if game != null else 0.0  # Animation clock (visual only).
	if beam_state != 0 and boss != null:
		_draw_beams(now)
	if nova_pending:
		var k := 1.0 - clampf(nova_left / nova_total, 0.0, 1.0)  # Telegraph progress 0..1.
		var sr := float(def["nova_safe_radius"])
		for s in nova_safe:
			var pulse := 0.5 + 0.5 * sin(now * 10.0)
			if CovenantFx.disc(overlay, s, sr, CovenantFxData.SAFE_RIMS, Color(1.0, 1.0, 1.0, 0.75 + 0.25 * pulse)):
				# Pixel art: the baked icy rim, the countdown draining as ice pieces.
				CovenantFx.ring(overlay, s, sr - 7.0, CovenantFxData.SAFE_TICK, Color(1.0, 1.0, 1.0, 0.9), 2.0, -PI * 0.5, -PI * 0.5 + TAU * (1.0 - k))
				if not SpriteBank.draw_flat(overlay, MarkerArtData.SANCTUARY_CROSS, s, 0.0, Color(1.0, 1.0, 1.0, MarkerArtData.SANCTUARY_CROSS_ALPHA)):
					CovenantFx.still(overlay, CovenantFxData.GLINT, s)
				continue
			overlay.draw_arc(s, sr, 0.0, TAU, 40, Color(Palette.IVORY, 0.85), 3.0)
			overlay.draw_arc(s, sr + 4.0 + 3.0 * pulse, 0.0, TAU, 40, Color(Palette.COLD_BLUE, 0.6), 2.0)
			# Countdown: the inner arc drains as the blast nears.
			overlay.draw_arc(s, sr - 7.0, -PI * 0.5, -PI * 0.5 + TAU * (1.0 - k), 40, Color(Palette.COLD_BLUE, 0.9), 4.0)
			# A small ward sigil in the middle (a cross in a ring): its pixel art when present.
			if SpriteBank.draw_flat(overlay, MarkerArtData.SANCTUARY_CROSS, s, 0.0, Color(1.0, 1.0, 1.0, MarkerArtData.SANCTUARY_CROSS_ALPHA)):
				continue
			overlay.draw_arc(s, 9.0, 0.0, TAU, 16, Color(Palette.IVORY, 0.8), 2.0)
			overlay.draw_line(s + Vector2(0, -14), s + Vector2(0, 14), Color(Palette.IVORY, 0.8), 2.0)
			overlay.draw_line(s + Vector2(-10, -3), s + Vector2(10, -3), Color(Palette.IVORY, 0.8), 2.0)
	if collapse_on:
		_draw_collapse_flames(collapse_radius(), now)
	if tele_left > 0.0:
		_draw_teleport_mark(now)


## The teleport landing marker: a disc of light filling in, a ring closing
## on the spot and a column of light rising from it.
func _draw_teleport_mark(now: float) -> void:
	var k := 1.0 - clampf(tele_left / tele_total, 0.0, 1.0)  # Glow progress 0..1.
	var c := tele_dest
	var rr := boss.radius * 1.3  # Landing body size (px).
	if CovenantFx.has(CovenantFxData.LIGHT_COLUMN) and CovenantFx.has(CovenantFxData.T_FRONT):
		# Pixel art (CovenantFx): a disc of light filling in, a white-gold ring
		# closing on the spot, a dashed gold landing ring, a column rising.
		SpriteBank.draw_disc(overlay, c, rr * (0.4 + 0.6 * k), Color(Palette.IVORY, 0.15 + 0.3 * k))
		CovenantFx.ring(overlay, c, rr * (2.6 - 1.6 * k), CovenantFxData.T_FRONT, Color(1.0, 1.0, 1.0, 0.5 + 0.4 * k), 1.5)
		CovenantFx.ring(overlay, c, rr, CovenantFxData.AURA_DASH, Color(1.0, 1.0, 1.0, 0.85), 1.0)
		var cw := rr * (0.5 + 0.3 * sin(now * 18.0) * k)  # Column half-width (px).
		CovenantFx.light_column(overlay, c, cw, 70.0 + 50.0 * k, Color(1.0, 1.0, 1.0, 0.35 + 0.55 * k))
		return
	overlay.draw_circle(c, rr * (0.4 + 0.6 * k), Color(Palette.IVORY, 0.15 + 0.3 * k))
	overlay.draw_arc(c, rr * (2.6 - 1.6 * k), 0.0, TAU, 32, Color(Palette.IVORY, 0.5 + 0.4 * k), 2.5)
	overlay.draw_arc(c, rr, 0.0, TAU, 32, Color(Palette.GOLD, 0.8), 1.5)
	var w := rr * (0.5 + 0.3 * sin(now * 18.0) * k)  # Column half-width (px).
	var h := 70.0 + 50.0 * k  # Column height (px).
	overlay.draw_colored_polygon(PackedVector2Array([c + Vector2(-w, 0), c + Vector2(-w * 0.4, -h), c + Vector2(w * 0.4, -h), c + Vector2(w, 0)]),
		Color(Palette.IVORY, 0.12 + 0.25 * k))


## The two beams: thin pulsing warning rays with sweep arrows, then wide
## white-gold rays with a glow.
func _draw_beams(now: float) -> void:
	var length := float(def["beams_length"]) - boss.radius * 0.8  # Drawn ray length from her edge (px).
	var w := float(def["beams_width"])
	for i in int(def["beams_count"]):
		var v := _beam_vec(i)
		var perp := Vector2(-v.y, v.x)
		var o := boss.position + v * boss.radius * 0.8  # Rays leave her body edge (drawn only).
		if beam_state == 1:
			var a := 0.45 + 0.35 * sin(now * 14.0)
			if CovenantFx.ray_strip(overlay, o, o + v * length, CovenantFxData.WARN_LINE, 3.0, now * 40.0, Color(1.0, 1.0, 1.0, a)):
				# Pixel art (CovenantFx): a dashed warning ray, dashed sides and
				# chevrons pointing the way it will sweep.
				CovenantFx.ray_strip(overlay, o + perp * w * 0.5, o + v * length + perp * w * 0.5, CovenantFxData.AURA_DASH, 2.0, 0.0, Color(1.0, 1.0, 1.0, 0.55))
				CovenantFx.ray_strip(overlay, o - perp * w * 0.5, o + v * length - perp * w * 0.5, CovenantFxData.AURA_DASH, 2.0, 0.0, Color(1.0, 1.0, 1.0, 0.55))
				for j in 3:
					var side := perp * beam_dir  # The sweep direction here.
					CovenantFx.still(overlay, CovenantFxData.T_CHEVRON, o + v * length * (0.4 + 0.25 * float(j)) + side * 8.0, Color(1.0, 1.0, 1.0, a), side.angle())
				continue
			overlay.draw_line(o, o + v * length, Color(Palette.GOLD, a), 3.0)
			overlay.draw_line(o + perp * w * 0.5, o + v * length + perp * w * 0.5, Color(Palette.GOLD, 0.3), 1.0)
			overlay.draw_line(o - perp * w * 0.5, o + v * length - perp * w * 0.5, Color(Palette.GOLD, 0.3), 1.0)
			# Arrowheads along the ray pointing the way it will sweep.
			for j in 3:
				var c := o + v * length * (0.4 + 0.25 * float(j))
				var side := perp * beam_dir
				overlay.draw_line(c + side * 14.0, c + side * 2.0 + v * 8.0, Color(Palette.IVORY, a), 2.0)
				overlay.draw_line(c + side * 14.0, c + side * 2.0 - v * 8.0, Color(Palette.IVORY, a), 2.0)
		else:
			var flick := 0.85 + 0.15 * sin(now * 30.0 + float(i))
			if CovenantFx.great_beam(overlay, o, o + v * length, w, now * CovenantFxData.BEAM_SCROLL, flick):
				continue  # Pixel art: the great holy beam (CovenantFx).
			var glow := PackedVector2Array([o + perp * w, o + v * length + perp * w * 1.2, o + v * length - perp * w * 1.2, o - perp * w])
			overlay.draw_colored_polygon(glow, Color(Palette.GOLD, 0.18 * flick))
			var body := PackedVector2Array([o + perp * w * 0.5, o + v * length + perp * w * 0.6, o + v * length - perp * w * 0.6, o - perp * w * 0.5])
			overlay.draw_colored_polygon(body, Color(Palette.GOLD, 0.55 * flick))
			overlay.draw_line(o, o + v * length, Color(Palette.IVORY, 0.95), w * 0.3)
			overlay.draw_circle(o + v * length, w * 0.6, Color(Palette.IVORY, 0.5 * flick))
	if beam_state == 1:
		if not CovenantFx.ring(overlay, boss.position, float(def["beams_length"]), CovenantFxData.AURA_DASH, Color(1.0, 1.0, 1.0, 0.45), 1.0):
			overlay.draw_arc(boss.position, float(def["beams_length"]), 0.0, TAU, RING_SEGMENTS, Color(Palette.GOLD, 0.25), 1.5)


## Ground fire band of the collapse: hot at the edge, a steady burn beyond,
## and a faint ring where the circle will stop shrinking.
func _draw_collapse_band(r: float, now: float) -> void:
	var c := collapse_center
	var scorch := CovenantFx.tex(CovenantFxData.COLLAPSE_SCORCH)  # Pixel-art burning ground, or null.
	if scorch != null:
		# The scorch square scaled so its hole is the arena, then the far burn
		# as four plain rects out to FIRE_BAND past the edge (no polygons).
		var half := float(scorch.get_width()) * 0.5 * r / CovenantFxData.COLLAPSE_SCORCH_HOLE  # Square half-size (px).
		SpriteBank.apply_sharp(self)
		draw_texture_rect(scorch, Rect2(c - Vector2(half, half), Vector2(half, half) * 2.0), false)
		var outer := r + FIRE_BAND  # Far edge of the burn (px).
		if outer > half:
			var far := CovenantFxData.COLLAPSE_FAR
			draw_rect(Rect2(c.x - outer, c.y - outer, outer * 2.0, outer - half), far)
			draw_rect(Rect2(c.x - outer, c.y + half, outer * 2.0, outer - half), far)
			draw_rect(Rect2(c.x - outer, c.y - half, outer - half, half * 2.0), far)
			draw_rect(Rect2(c.x + half, c.y - half, outer - half, half * 2.0), far)
		CovenantFx.ring(self, c, float(def["collapse_end_radius"]), CovenantFxData.AURA_DASH, Color(1.0, 1.0, 1.0, 0.35 + 0.1 * sin(now * 3.0)), 1.0,
			0.0, TAU, 0.0, "", 0, _view_cull())
		return
	var hot := Color(1.0, 0.62, 0.2, 0.55)
	var warm := Color(1.0, 0.45, 0.1, 0.28)
	_annulus(c, r, r + 70.0, hot, warm)
	_annulus(c, r + 70.0, r + FIRE_BAND, warm, Color(0.8, 0.3, 0.05, 0.22))
	draw_arc(c, float(def["collapse_end_radius"]), 0.0, TAU, RING_SEGMENTS, Color(Palette.GOLD, 0.18 + 0.06 * sin(now * 3.0)), 2.0)


## Bright flames along the collapse edge (over the bodies).
func _draw_collapse_flames(r: float, now: float) -> void:
	var c := collapse_center
	if CovenantFx.has(CovenantFxData.COLLAPSE_FLAME) and CovenantFx.has(CovenantFxData.COLLAPSE_EDGE):
		# Pixel art (CovenantFx): the burning edge band and flame tongues
		# licking inward, each on its own frame offset; off-view pieces skipped.
		var view := _view_cull()
		CovenantFx.ring(overlay, c, r, CovenantFxData.COLLAPSE_EDGE, Color.WHITE, 3.0, 0.0, TAU, 0.0, "", 0, view)
		var n := maxi(12, int(TAU * r / CovenantFxData.COLLAPSE_FLAME_PITCH))  # Tongues round the edge.
		for j in n:
			var a := TAU * float(j) / float(n) + now * 0.05
			var foot := c + Vector2.from_angle(a) * (r + 3.0)
			if view.size != Vector2.ZERO and not view.has_point(foot):
				continue
			CovenantFx.flame_tongue(overlay, foot, a + PI, now, (j * 7) % CovenantFxData.COLLAPSE_FLAME_FRAMES)
		return
	overlay.draw_arc(c, r, 0.0, TAU, RING_SEGMENTS * 2, Color(Palette.IVORY, 0.9), 3.0)
	overlay.draw_arc(c, r + 5.0, 0.0, TAU, RING_SEGMENTS * 2, Color(Palette.FLAME, 0.8), 4.0)
	for j in FLAME_TONGUES:
		var a := TAU * float(j) / float(FLAME_TONGUES) + now * 0.05
		var flick := 0.5 + 0.5 * sin(now * 9.0 + float(j) * 2.3)
		var height := 12.0 + 16.0 * flick
		var half := TAU / float(FLAME_TONGUES) * 0.45
		var base_l := c + Vector2.from_angle(a - half) * (r + 6.0)
		var base_r := c + Vector2.from_angle(a + half) * (r + 6.0)
		var tip := c + Vector2.from_angle(a + 0.02 * sin(now * 5.0 + float(j))) * (r - height)
		overlay.draw_colored_polygon(PackedVector2Array([base_l, tip, base_r]), Color(Palette.FLAME, 0.75))
		var inner_tip := c + Vector2.from_angle(a) * (r - height * 0.55)
		overlay.draw_colored_polygon(PackedVector2Array([base_l.lerp(base_r, 0.25), inner_tip, base_l.lerp(base_r, 0.75)]), Color(Palette.GOLD, 0.85))


## A filled ring from `r0` to `r1` around `c` with a radial colour gradient.
func _annulus(c: Vector2, r0: float, r1: float, col0: Color, col1: Color) -> void:
	for j in RING_SEGMENTS:
		var a0 := TAU * float(j) / float(RING_SEGMENTS)
		var a1 := TAU * float(j + 1) / float(RING_SEGMENTS)
		var d0 := Vector2.from_angle(a0)
		var d1 := Vector2.from_angle(a1)
		draw_polygon(PackedVector2Array([c + d0 * r0, c + d0 * r1, c + d1 * r1, c + d1 * r0]),
			PackedColorArray([col0, col1, col1, col0]))
