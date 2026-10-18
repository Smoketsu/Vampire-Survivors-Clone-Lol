## SirenKit — the Siren of the Eye's song (SpireEnemyData "eye_siren", kit
## "siren"; GDD §15.0 "Ul-Thalos, the Risen Spire"). Her body is the shared
## "banner" walk: she always advances on the necromancer (never kites) and
## strikes weakly in contact. On top of that:
##   * Song: when the cooldown is up and at least song_min_summons summons
##     stand within song_radius px of her (and one within song_range), she
##     stops and sings: rising biolume notes and a widening ring for
##     song_telegraph s (killing her now cancels it). Then every summon within
##     song_radius px of her (up to song_max_lured, the nearest first) is
##     LURED for song_lure s through the ONE compel path
##     (SummonedUnit.compel()): it drops its target and walks to her at
##     song_lure_speed x its speed, out of the Bone Ring, attacking nothing.
## Determinism (CLAUDE.md): no RNG; her first song is staggered by the think
## slot (CovenantKit.first_cd()); the lured are ordered by distance, ties in
## the spatial hash's order.
## Stats: siren_songs, siren_songs_cancelled (she died singing), siren_lured.
class_name SirenKit
extends CovenantKit

## Phase: the song is rising (the telegraph).
const SINGING: int = 1

## Seconds until the next song may start.
var cd: float = 0.0
## Reusable query buffer.
var _tmp: Array = []
## Lure candidates of a song: [distance, summon].
var _cands: Array = []


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	cd = first_cd(e, float(d["song_first"]))


## She died: a song still rising is cancelled.
func on_killed(e: Enemy) -> void:
	if phase == SINGING:
		e.game.stat_add("siren_songs_cancelled", 1.0)


func physics(e: Enemy, delta: float) -> bool:
	cd -= delta
	match phase:
		SINGING:
			phase_time += delta
			hold(e)
			if int(phase_time * 6.0) != int((phase_time - delta) * 6.0):
				e.queue_redraw()  # The notes rise (a few redraws a second).
			if phase_time >= float(d["song_telegraph"]):
				_lure(e)
				set_phase(e, IDLE)
				cd = float(d["song_cooldown"])
			return true
	if cd > 0.0:
		return false
	if not _worth_singing(e):
		cd = 0.5  # Nobody close enough: look again shortly.
		return false
	set_phase(e, SINGING)
	e.motion_lunge(Vector2.ZERO, MotionData.POWER_CAST)  # Engine motion: she draws breath (visual only).
	e.game.stat_add("siren_songs", 1.0)
	Sfx.play("boss_telegraph", e.position, 1.4)
	return true


## True when enough summons stand close enough to her to sing.
func _worth_singing(e: Enemy) -> bool:
	var g := e.game
	var r := float(d["song_radius"])
	g.ally_grid.query(e.position, maxf(r, float(d["song_range"])), _tmp)
	var near := 0  # Summons inside the song's reach.
	for u: SummonedUnit in _tmp:
		if u.active and not u.is_compelled() and u.position.distance_to(e.position) <= r:
			near += 1
	return near >= int(d["song_min_summons"])


## The song ends: the nearest summons in reach are lured to her.
func _lure(e: Enemy) -> void:
	var g := e.game
	var r := float(d["song_radius"])
	g.ally_grid.query(e.position, r + UnitData.MAX_BLOCK_RADIUS, _tmp)
	_cands.clear()
	for u: SummonedUnit in _tmp:
		if not u.active:
			continue
		var dist := u.position.distance_to(e.position)
		if dist <= r + u.radius:
			_cands.append([dist, u])
	_cands.sort_custom(func(a: Array, b: Array) -> bool: return float(a[0]) < float(b[0]))
	var until := g.elapsed + float(d["song_lure"])
	var n := 0  # Summons lured.
	for c: Array in _cands:
		if n >= int(d["song_max_lured"]):
			break
		var u: SummonedUnit = c[1]
		if u.compel(e.position, until, float(d["song_lure_speed"])):
			n += 1
	g.stat_add("siren_lured", float(n))
	g.effects.ring(e.position, r, Palette.EYE_BIOLUME, 0.5)
	g.effects.ring(e.position, r * 0.6, Palette.EYE_BIOLUME_GLOW, 0.4)


## The song's widening ring (under her).
func draw_under(e: Enemy) -> void:
	if phase != SINGING:
		return
	unmirror(e)
	var k := clampf(phase_time / maxf(0.05, float(d["song_telegraph"])), 0.0, 1.0)
	var r := float(d["song_radius"])
	e.draw_circle(Vector2.ZERO, r * k, Color(Palette.EYE_BIOLUME, 0.10))
	e.draw_arc(Vector2.ZERO, r, 0.0, TAU, 48, Color(Palette.EYE_BIOLUME, 0.55), 2.0)
	e.draw_arc(Vector2.ZERO, r * k, 0.0, TAU, 40, Color(Palette.EYE_BIOLUME_GLOW, 0.7), 1.5)
	e.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## Rising notes over her head while she sings.
func draw_over(e: Enemy, ci: CanvasItem) -> void:
	if phase != SINGING:
		return
	unmirror(e, ci)
	SpireGlyphs.draw_notes(ci, Vector2(0.0, e.marker_y(-e.radius * 2.2)), phase_time)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
