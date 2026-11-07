## BlackSun — the Black Sun spell (AbilityData "black_sun"; Act V, the Road to
## the Sun; GDD §15.0 "Black Sun, Eclipse of Heaven, Stolen Dawn and the Shrine
## Maiden of Night"; owner-approved proposal: "a dark sun orbits the
## necromancer and fires a short beam at the nearest group"; unlocked by
## defeating Amaterasu, then offered on every stage at the later-item card
## weight). `suns` dark sun(s) orbit the necromancer (BlackSunData.ORBIT_RADIUS
## px, ORBIT_SPEED rad/s on game time, spread evenly). Every `cooldown` s each
## sun fires one BEAM at the NEAREST GROUP: the nearest open foe within
## BlackSunData.AIM_RANGE px of the sun, aimed at the centre of the foes within
## `group_radius` px of it; the beam runs `sun_reach` px from the sun and is
## `sun_width` px wide; every foe on it takes `damage` (CombatResolver
## .damage_enemy(), the friendly damage path). Evolved into ECLIPSE OF HEAVEN
## (EvolutionData "eclipse_of_heaven", detected by the "corona" key): two suns,
## longer and harder beams, and each beam ends in a CORONA burst (`corona` x
## the damage to every foe within CORONA_RADIUS px of its end). STOLEN DAWN (the
## paired passive): its cooldown share is applied by
## AbilityManager.apply_spell_mods(), and each volley that strikes heals the
## necromancer `beam_heal` HP (the effective stat it writes). The Shrine Maiden
## of Night's innate (Night Prayer, innate value black_sun_fork): each sun also
## fires a second beam at another group (the nearest foe the first beam missed)
## for that share of the damage.
## Determinism: no RNG; the nearest foe by distance, ties in the spatial hash's
## order. Stats: black_sun_volleys, black_sun_beams, black_sun_hits,
## black_sun_forks, black_sun_coronas, black_sun_healed; damage as
## dmg_black_sun / dmg_eclipse_of_heaven / dmg_eclipse_corona.
class_name BlackSun
extends NecroSpell

## Beams still shown: {a, b (world ends), w (width px), t (game time fired),
## evolved (bool), fork (bool)}. Visual only.
var shown: Array[Dictionary] = []
## Seconds until the next volley.
var _cd: float = 0.0
## Suns orbiting at the last step (drawing).
var _suns: int = 1
## True once Eclipse of Heaven (drawing).
var _evolved: bool = false
## True if the last redraw showed anything (one more redraw clears it).
var _drawn: bool = false
## Soft beam strip texture (made once, drawn stretched).
var _tex: ImageTexture = null


## Fires on its cooldown; ages the shown beams.
func step(delta: float, stats: Dictionary) -> void:
	_suns = int(stats["suns"])
	_evolved = stats.has("corona")
	var now := game.elapsed
	var i := shown.size() - 1
	while i >= 0:
		if now - float(shown[i]["t"]) > BlackSunData.BEAM_SHOW:
			shown.remove_at(i)
		i -= 1
	_cd -= delta
	if _cd <= 0.0:
		_cd = float(stats["cooldown"]) if _volley(stats) else AbilityData.SPELL_RETRY
	queue_redraw()  # The suns orbit (drawing only).


## World position of sun `k` of `n` now (around the necromancer).
func sun_pos(k: int, n: int, centre: Vector2) -> Vector2:
	var a := game.elapsed * BlackSunData.ORBIT_SPEED + TAU * float(k) / float(maxi(1, n))
	return centre + Vector2.from_angle(a) * BlackSunData.ORBIT_RADIUS


## One volley: each sun fires at its nearest group (and, with Night Prayer, at
## a second one). False when no sun found a foe.
func _volley(stats: Dictionary) -> bool:
	var n := int(stats["suns"])
	var centre := game.player.position
	var fired := false
	var hits := 0
	for k in n:
		var s := sun_pos(k, n, centre)
		var r := _fire(s, stats, {}, false)
		if r[0]:
			fired = true
			hits += int(r[1])
	if not fired:
		return false
	game.stat_add("black_sun_volleys", 1.0)
	Sfx.play("lance_cast", centre, 0.7)  # A startup-bank sound: the spell plays on every stage.
	var heal := float(stats.get("beam_heal", 0.0))  # Stolen Dawn (0 when not owned).
	if heal > 0.0 and hits > 0:
		game.stat_add("black_sun_healed", game.combat.heal_player(heal))
	return true


## Fires one sun's beam from `s` at the nearest group (skipping foes in
## `skip`; `fork`: Night Prayer's second beam, skipping the first beam's foes).
## Returns [fired, hits].
func _fire(s: Vector2, stats: Dictionary, skip: Dictionary, fork: bool) -> Array:
	var target := _nearest(s, BlackSunData.AIM_RANGE, skip)
	if target == null:
		return [false, 0]
	var aim := _group_centre(target, float(stats["group_radius"]))
	var to := aim - s
	var dir := to.normalized() if to.length() > 0.5 else Vector2.RIGHT
	var length := float(stats["sun_reach"])
	var b := s + dir * length
	var evolved := stats.has("corona")
	var dmg := float(stats["damage"]) * (game.character.innate_value(BlackSunData.FORK_KEY) if fork else 1.0)
	var src := BlackSunData.EVOLVED_SOURCE if evolved else BlackSunData.SOURCE
	var half := float(stats["sun_width"]) * 0.5
	var struck: Dictionary = {}  # Foes this beam struck (Night Prayer skips them).
	var hit_list: Array = []  # Own buffer: kill hooks may query the grid again.
	game.enemy_grid.query(s.lerp(b, 0.5), length * 0.5 + half + ProjectileManager.MAX_BODY_RADIUS, hit_list)
	for e: Enemy in hit_list:
		if not e.active or DivineWrath._seg_dist(e.position, s, b) > half + e.radius:
			continue
		struck[e] = true
		game.combat.damage_enemy(e, dmg, src)
	if evolved:
		damage_area(b, BlackSunData.CORONA_RADIUS, dmg * float(stats["corona"]), BlackSunData.CORONA_SOURCE)
		game.stat_add("black_sun_coronas", 1.0)
	shown.append({"a": s, "b": b, "w": float(stats["sun_width"]), "t": game.elapsed, "evolved": evolved, "fork": fork})
	game.stat_add("black_sun_beams", 1.0)
	game.stat_add("black_sun_hits", float(struck.size()))
	var hits := struck.size()
	# Night Prayer (the Shrine Maiden of Night): a second beam at another group.
	if not fork and game.character.innate_value(BlackSunData.FORK_KEY) > 0.0:
		var r := _fire(s, stats, struck, true)
		if r[0]:
			game.stat_add("black_sun_forks", 1.0)
			hits += int(r[1])
	return [true, hits]


## The nearest open foe within `reach` px of `p` not in `skip` (null when none).
func _nearest(p: Vector2, reach: float, skip: Dictionary) -> Enemy:
	var best: Enemy = null
	var best_d := reach
	game.enemy_grid.query(p, reach, _tmp)
	for e: Enemy in _tmp:
		if not is_open_target(e) or skip.has(e):
			continue
		var dd := p.distance_to(e.position)
		if dd < best_d:
			best_d = dd
			best = e
	return best


## The centre of the foes within `r` px of `e` (at most GROUP_MAX of them).
func _group_centre(e: Enemy, r: float) -> Vector2:
	game.enemy_grid.query(e.position, r, _tmp)
	var sum := Vector2.ZERO
	var n := 0
	for o: Enemy in _tmp:
		if o.active and o.position.distance_to(e.position) <= r:
			sum += o.position
			n += 1
			if n >= BlackSunData.GROUP_MAX:
				break
	return sum / float(n) if n > 0 else e.position


## Autotest counters (the Black Sun line of SunRoadReport).
func summary_extra() -> String:
	var st := game.stats
	return "volleys=%d beams=%d hits=%d forks=%d coronas=%d healed=%d" % [int(st.get("black_sun_volleys", 0.0)), int(st.get("black_sun_beams", 0.0)),
		int(st.get("black_sun_hits", 0.0)), int(st.get("black_sun_forks", 0.0)), int(st.get("black_sun_coronas", 0.0)), int(st.get("black_sun_healed", 0.0))]


## The soft beam strip (white, bright along its middle row), made once.
func _beam_texture() -> ImageTexture:
	if _tex == null:
		var h := 12  # Rows across the beam.
		var img := Image.create(4, h, false, Image.FORMAT_RGBA8)
		for y in h:
			var k := 1.0 - absf((float(y) + 0.5) / float(h) * 2.0 - 1.0)  # 0 at the edges, 1 in the middle.
			for x in 4:
				img.set_pixel(x, y, Color(1.0, 1.0, 1.0, k))
		_tex = ImageTexture.create_from_image(img)
	return _tex


## The dark suns (a black disc in a violet-gold corona) and the beams (a black
## core in a violet glow, gold-edged once evolved). Textures only. Visual only.
func _draw() -> void:
	if game == null:
		return
	var centre := caster_pos()
	var disc := SpriteBank.disc()
	var corona := Palette.GOLD if _evolved else Palette.VIOLET
	for k in _suns:
		var p := sun_pos(k, _suns, centre)
		draw_texture_rect(disc, Rect2(p - Vector2(9, 9), Vector2(18, 18)), false, Color(corona, 0.45))
		draw_texture_rect(disc, Rect2(p - Vector2(6, 6), Vector2(12, 12)), false, Color(0.03, 0.01, 0.05, 1.0))
	var now := game.elapsed
	for bm in shown:
		var a: Vector2 = bm["a"]
		var b: Vector2 = bm["b"]
		var fade := clampf(1.0 - (now - float(bm["t"])) / BlackSunData.BEAM_SHOW, 0.0, 1.0)
		var w := float(bm["w"]) * (0.7 if bool(bm["fork"]) else 1.0)
		var dir := (b - a).normalized()
		draw_set_transform(a, dir.angle(), Vector2.ONE)
		draw_texture_rect(_beam_texture(), Rect2(0.0, -w, a.distance_to(b), w * 2.0), false, Color(corona, 0.5 * fade))
		draw_texture_rect(_beam_texture(), Rect2(0.0, -w * 0.4, a.distance_to(b), w * 0.8), false, Color(0.02, 0.0, 0.04, 0.9 * fade))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		if bool(bm["evolved"]) and not bool(bm["fork"]):
			draw_texture_rect(disc, Rect2(b - Vector2.ONE * BlackSunData.CORONA_RADIUS, Vector2.ONE * BlackSunData.CORONA_RADIUS * 2.0), false, Color(Palette.GOLD, 0.25 * fade))
