## BurningEye — the BURNING EYE spell (AbilityData "burning_eye"; temporary
## Act XII, the Temple of the Lioness; GDD §15.0 "Burning Eye, Eye of
## Retribution, Desert Fury and the Lion-Priestess (Dynasty phase 2)";
## proposal: "a solar eye fires a beam that sweeps a 90° arc"). Unlocked by
## slaying Sekhmet (UnlockData), then offered on every stage; driven by
## NecroSpellBook's one dispatch (LIONESS_TEMPLE_IDS, stepped only) with its
## EFFECTIVE stats (AbilityManager.spell_stats(): the spell modifiers, and the
## Sandstorm's reach on its "range", like every ranged spell of the act).
##   * Every `cooldown` s (start to start; BurningEyeData.MIN_GAP at least
##     between two sweeps) a solar eye opens over the necromancer and fires a
##     beam `range` px long and `width` px wide at the nearest foe, then sweeps
##     it across an arc of `arc` degrees centred on that foe in `sweep_time` s.
##   * Every enemy the beam crosses takes `damage` once per pass (its body
##     radius counts; the angular test is exact for the swept sector). The
##     beam is FIRE (DynastyRulesData.FIRE_SOURCES: a mummy takes x1.5).
##   * Desert Fury (its paired passive, PassiveData "desert_fury", read only
##     here): x 1 + fury_dmg on the damage, + fury_arc degrees on the arc.
##   * The Lion-Priestess's innate (CharacterData "eye_reach_bonus"): x 1 + it
##     on the beam's length (0 for every other character).
## Evolved into Eye of Retribution (EvolutionData "eye_of_retribution",
## detected by the "retribution" key): the beam sweeps THERE AND BACK (two
## passes, each striking), and whenever the necromancer is hurt the eye opens
## again at once, at most every `retribution` s (RETRIBUTION).
## A beam is not a projectile (nothing blocks it). Drawn as a sun-white beam in
## a solar glow under a floating eye with a soul-teal pupil (textures and
## lines, no polygons). Deterministic: no RNG. Stats: eye_sweeps, eye_hits,
## eye_kills, eye_retributions, eye_reach_bonus_px.
class_name BurningEye
extends NecroSpell

## Seconds until the next sweep may start.
var _timer: float = BurningEyeData.FIRST_SWEEP
## True while a sweep is turning.
var _sweeping: bool = false
## Angle (rad) of the beam now.
var _angle: float = 0.0
## Signed turn rate direction of the current pass (+1 / -1).
var _dir: float = 1.0
## Radians swept so far this pass.
var _swept: float = 0.0
## Radians of the whole arc this sweep.
var _arc: float = 0.0
## Passes left after this one (Eye of Retribution: 1 more, the way back).
var _passes_left: int = 0
## Effective stats of the current sweep (spell_stats(), kept for drawing).
var _stats: Dictionary = {}
## Enemy -> generation struck by the current pass (lookups only).
var _struck: Dictionary = {}
## The necromancer's HP at the last step (Eye of Retribution's hit test).
var _last_hp: float = -1.0
## Seconds since the last sweep started (Eye of Retribution's floor).
var _since: float = 999.0
## Own query buffer of the sweep.
var _cand: Array = []
## True if the last redraw showed something (one more redraw clears it).
var _drawn: bool = false


func _ready() -> void:
	z_index = 3


## Starts sweeps on cooldown (or at once on a hit, evolved), turns the beam.
func step(delta: float, stats: Dictionary) -> void:
	_stats = stats
	_since += delta
	var evolved := stats.has("retribution")  # Eye of Retribution.
	var hp := game.player.hp  # The necromancer's HP now.
	var hurt := _last_hp >= 0.0 and hp < _last_hp - 0.01  # Hit since the last step.
	_last_hp = hp
	if _sweeping:
		_turn(delta, stats)
	else:
		_timer -= delta
		if evolved and hurt and _since >= maxf(BurningEyeData.RETRIBUTION_FLOOR, float(stats["retribution"])):
			_timer = 0.0  # The eye answers the blow.
			game.stat_add("eye_retributions", 1.0)
		if _timer <= 0.0:
			if not _start(stats):
				_timer = AbilityData.SPELL_RETRY
	if _sweeping or _drawn:
		queue_redraw()
	_drawn = _sweeping


## The beam's length now (px): its range x the Lion-Priestess's innate.
func _length(stats: Dictionary) -> float:
	return float(stats["range"]) * (1.0 + game.character.innate_value(BurningEyeData.INNATE_KEY))


## Starts a sweep centred on the nearest foe within the beam's reach. Returns
## false when no foe is in reach (the spell then waits).
func _start(stats: Dictionary) -> bool:
	var p := game.player.position  # The necromancer.
	var reach := _length(stats) + BurningEyeData.TRIGGER_SLACK  # Beam reach (px).
	game.enemy_grid.query(p, reach + ProjectileManager.MAX_BODY_RADIUS, _cand)
	var best: Enemy = null  # Nearest foe.
	var best_d := INF
	for e: Enemy in _cand:
		if not e.active or e.untargetable:
			continue
		var d := p.distance_to(e.position) - e.radius
		if d <= reach and d < best_d:
			best_d = d
			best = e
	if best == null:
		return false
	var ab := game.abilities
	var arc_deg := float(stats["arc"]) + ab.passive_value(BurningEyeData.PASSIVE, "fury_arc")  # Desert Fury widens it.
	_arc = deg_to_rad(clampf(arc_deg, 10.0, 300.0))
	_angle = (best.position - p).angle() - _arc * 0.5  # From one edge of the arc.
	_dir = 1.0
	_swept = 0.0
	_sweeping = true
	_struck.clear()
	_passes_left = 1 if stats.has("retribution") else 0
	_since = 0.0
	game.stat_add("eye_sweeps", 1.0)
	var bonus := game.character.innate_value(BurningEyeData.INNATE_KEY)
	if bonus > 0.0:
		game.stat_add("eye_reach_bonus_px", float(stats["range"]) * bonus)
	game.player.cast_motion(best.position)  # Engine motion: toward the foe (visual only).
	Sfx.play("bolt_cast", p, BurningEyeData.SWEEP_PITCH)  # A startup-bank sound: the spell plays on every stage.
	return true


## Turns the beam by this tick's share of the arc and strikes what it crosses.
func _turn(delta: float, stats: Dictionary) -> void:
	var rate := _arc / maxf(0.1, float(stats["sweep_time"]))  # rad/s.
	var da := minf(rate * delta, _arc - _swept)  # Angle swept this tick (rad).
	_strike(_angle if _dir > 0.0 else _angle - da, da, stats)
	_angle += da * _dir
	_swept += da
	if _swept >= _arc - 0.0001:
		if _passes_left > 0:
			_passes_left -= 1  # Eye of Retribution: the way back strikes again.
			_dir = -_dir
			_swept = 0.0
			_struck.clear()
			return
		_sweeping = false
		_timer = maxf(BurningEyeData.MIN_GAP, float(stats["cooldown"]) - float(stats["sweep_time"]) * (2.0 if stats.has("retribution") else 1.0))


## The beam sweeps the sector from angle `a0` by `da` rad: strikes every foe in it.
func _strike(a0: float, da: float, stats: Dictionary) -> void:
	var p := game.player.position  # The beam's origin.
	var length := _length(stats)  # px.
	var half_w := float(stats["width"]) * 0.5  # px.
	var fury := game.abilities.passive_value(BurningEyeData.PASSIVE, "fury_dmg")  # Desert Fury's share.
	var dmg := float(stats["damage"]) * (1.0 + fury)
	var src := BurningEyeData.EVOLVED_SOURCE if stats.has("retribution") else BurningEyeData.SOURCE  # Stats tag (fire).
	game.enemy_grid.query(p, length + ProjectileManager.MAX_BODY_RADIUS, _cand)
	var hits: Array[Enemy] = []  # Foes crossed this tick (struck after the scan).
	for e: Enemy in _cand:
		if not e.active or e.untargetable or int(_struck.get(e, -1)) == e.generation:
			continue
		var rel := e.position - p
		var d := rel.length()
		if d > length + e.radius:
			continue
		var tol := (half_w + e.radius) / maxf(d, BurningEyeData.MIN_HIT_DIST)  # Angular half-width of its body (rad).
		var off := wrapf(rel.angle() - a0, -PI, PI)  # Its angle past the sector's start.
		if off >= -tol and off <= da + tol:
			hits.append(e)
	for e in hits:
		if not e.active:
			continue  # Killed by an earlier strike's kill hook.
		_struck[e] = e.generation
		var gen := e.generation
		game.combat.damage_enemy(e, dmg, src)
		game.stat_add("eye_hits", 1.0)
		if not e.active or e.generation != gen:
			game.stat_add("eye_kills", 1.0)


## Autotest counters (LionessTempleReport's Burning Eye line).
func summary_extra() -> String:
	var st := game.stats  # Run counters.
	return "sweeps=%d hits=%d kills=%d retributions=%d reach_bonus_px=%d" % [int(st.get("eye_sweeps", 0.0)),
		int(st.get("eye_hits", 0.0)), int(st.get("eye_kills", 0.0)), int(st.get("eye_retributions", 0.0)),
		int(st.get("eye_reach_bonus_px", 0.0))]


## The eye over the necromancer and its beam (a solar glow behind a sun-white
## core, a fading afterglow). Visual only: textures and lines.
func _draw() -> void:
	if not _sweeping or _stats.is_empty():
		return
	var p := caster_pos()  # The beam's origin.
	var length := _length(_stats)
	var w := float(_stats["width"])
	for t in 3:
		var ta := _angle - _dir * BurningEyeData.TRAIL_ANGLE * float(t + 1) / 3.0  # Afterglow angle.
		draw_line(p, p + Vector2.from_angle(ta) * length, Color(BurningEyeData.GLOW, 0.14 - 0.04 * float(t)), w * 0.8)
	var tip := p + Vector2.from_angle(_angle) * length
	draw_line(p, tip, Color(BurningEyeData.GLOW, 0.4), w + 5.0)
	draw_line(p, tip, Color(BurningEyeData.GLOW, 0.85), w)
	draw_line(p, tip, BurningEyeData.CORE, maxf(1.0, w * 0.35))
	SpriteBank.draw_disc(self, tip, w * 0.7, Color(BurningEyeData.CORE, 0.7))
	var eye := p + Vector2(0.0, -BurningEyeData.EYE_HEIGHT)  # The floating eye.
	var r := BurningEyeData.EYE_RADIUS
	SpriteBank.draw_disc(self, eye, r * 1.9, Color(BurningEyeData.GLOW, 0.3))
	SpriteBank.draw_disc(self, eye, r, BurningEyeData.CORE)
	SpriteBank.draw_disc(self, eye + Vector2.from_angle(_angle) * r * 0.35, r * 0.45, BurningEyeData.PUPIL)
