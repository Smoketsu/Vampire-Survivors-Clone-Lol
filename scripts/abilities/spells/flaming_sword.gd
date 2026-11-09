## FlamingSword — the FLAMING SWORD spell (AbilityData "flaming_sword"; temporary
## Act XIII, the Silver Stair; GDD §15.0 "Flaming Sword, Sword at the Gate,
## Fallen Light and the Fallen Herald"; owner-approved proposal: "a spectral
## sword sweeps a wide arc in front of the necromancer"). Unlocked by slaying
## Seraiel (UnlockData), then offered on every stage; driven by NecroSpellBook's
## one dispatch (SILVER_STAIR_IDS, stepped only) with its EFFECTIVE stats
## (AbilityManager.spell_stats(): its reach is the row's "radius", so every
## spell-area modifier widens it).
##   * Every `cooldown` s, once a foe stands within the sword's reach (+
##     FlamingSwordData.AIM_SLACK), a spectral sword sweeps an arc of `arc`
##     degrees centred on the NEAREST foe, `radius` px long: every foe in that
##     sector (its body radius counts) takes `damage` at once, through
##     CombatResolver.damage_enemy() (the spell is its own Grace kind). The
##     blade's sweep is drawn for SWEEP_SHOW s (visual only).
##   * Fallen Light (its paired passive, PassiveData "fallen_light", read only
##     here): x 1 + edge_bonus on the damage, + arc_bonus degrees on the arc.
##   * The Fallen Herald's Torn Wing (CharacterData "sword_reach_bonus"): + px
##     on the reach (0 for every other character).
## Evolved into SWORD AT THE GATE (EvolutionData "sword_at_the_gate", detected
## by the "echo_share" key): the sword turns a full circle round the
## necromancer, and echo_delay s later it sweeps back once more for
## echo_share of the damage.
## Deterministic: no RNG; the nearest foe in the spatial hash's order. Stats:
## sword_casts, sword_hits, sword_echoes, sword_reach_bonus_px; damage as
## dmg_flaming_sword / dmg_sword_at_the_gate.
class_name FlamingSword
extends NecroSpell

## Seconds until the next cast may start.
var _cd: float = 0.0
## Game time (s) the evolved echo sweeps (INF = none pending).
var _echo_at: float = INF
## Aim (rad) of the pending echo.
var _echo_aim: float = 0.0
## Drawn sweeps: {aim (rad), arc (rad), reach (px), t0 (game s), back (bool)}.
var _shown: Array[Dictionary] = []
## Effective stats of the last step.
var _stats: Dictionary = {}
## Own query buffer of a sweep (kill hooks may query the grid again).
var _cand: Array = []
## True if the last redraw showed something (one more redraw clears it).
var _drawn: bool = false


func _ready() -> void:
	z_index = 3


## Casts on the cooldown; the evolved echo; the drawn sweeps fade.
func step(delta: float, stats: Dictionary) -> void:
	_stats = stats
	_cd -= delta
	if _cd <= 0.0:
		_cd = float(stats["cooldown"]) if _cast(stats) else AbilityData.SPELL_RETRY
	if game.elapsed >= _echo_at:
		_echo_at = INF
		_sweep(stats, _echo_aim, float(stats.get("echo_share", 0.0)), true)
		game.stat_add("sword_echoes", 1.0)
	while not _shown.is_empty() and game.elapsed - float(_shown[0]["t0"]) > FlamingSwordData.SWEEP_SHOW:
		_shown.pop_front()
	var busy := not _shown.is_empty()
	if busy or _drawn:
		queue_redraw()
	_drawn = busy


## The sword's reach now (px): its radius + the Fallen Herald's innate.
func _reach(stats: Dictionary) -> float:
	return float(stats["radius"]) + game.character.innate_value(FlamingSwordData.INNATE_KEY)


## The sweep's arc now (rad): its arc + Fallen Light's degrees (a full circle
## at most).
func _arc(stats: Dictionary) -> float:
	var deg := float(stats["arc"]) + game.abilities.passive_value(FlamingSwordData.FALLEN_LIGHT, FlamingSwordData.ARC_KEY)
	return deg_to_rad(clampf(deg, 10.0, 360.0))


## One cast at the nearest foe within reach. Returns false when none is near
## (the spell then waits).
func _cast(stats: Dictionary) -> bool:
	var p := game.player.position  # The necromancer.
	var reach := _reach(stats) + FlamingSwordData.AIM_SLACK
	game.enemy_grid.query(p, reach + ProjectileManager.MAX_BODY_RADIUS, _cand)
	var best: Enemy = null  # The nearest open foe.
	var best_d := INF
	for e: Enemy in _cand:
		if not e.active or e.untargetable or e.civilian:
			continue
		var d := p.distance_to(e.position) - e.radius
		if d <= reach and d < best_d:
			best_d = d
			best = e
	if best == null:
		return false
	var aim := (best.position - p).angle()
	_sweep(stats, aim, 1.0, false)
	if stats.has("echo_share"):
		_echo_at = game.elapsed + float(stats.get("echo_delay", 0.3))
		_echo_aim = aim
	game.stat_add("sword_casts", 1.0)
	var bonus := game.character.innate_value(FlamingSwordData.INNATE_KEY)
	if bonus > 0.0:
		game.stat_add("sword_reach_bonus_px", bonus)
	game.player.cast_motion(best.position)  # Engine motion: toward the foe (visual only).
	Sfx.play("bolt_cast", p, FlamingSwordData.SWEEP_PITCH)  # A startup-bank sound: the spell plays on every stage.
	return true


## One sweep centred on `aim`: every foe in the sector takes `share` of the
## damage (`back`: the evolved echo, drawn the other way).
func _sweep(stats: Dictionary, aim: float, share: float, back: bool) -> void:
	var p := game.player.position  # The sword's hilt.
	var reach := _reach(stats)
	var arc := _arc(stats)
	var edge := game.abilities.passive_value(FlamingSwordData.FALLEN_LIGHT, FlamingSwordData.EDGE_KEY)  # Fallen Light's share.
	var dmg := float(stats["damage"]) * (1.0 + edge) * share
	var src := FlamingSwordData.EVOLVED_SOURCE if stats.has("echo_share") else FlamingSwordData.SOURCE
	var hits: Array = []  # Own buffer: kill hooks may query the grid again.
	game.enemy_grid.query(p, reach + ProjectileManager.MAX_BODY_RADIUS, hits)
	for e: Enemy in hits:
		if not e.active or e.untargetable or e.civilian:
			continue
		var rel := e.position - p
		var d := rel.length()
		if d > reach + e.radius:
			continue
		if arc < TAU - 0.001:
			var tol := e.radius / maxf(d, FlamingSwordData.MIN_HIT_DIST)  # Angular half-width of its body (rad).
			if absf(wrapf(rel.angle() - aim, -PI, PI)) > arc * 0.5 + tol:
				continue
		game.combat.damage_enemy(e, dmg, src)
		game.stat_add("sword_hits", 1.0)
	_shown.append({"aim": aim, "arc": arc, "reach": reach, "t0": game.elapsed, "back": back})


## Autotest counters (SilverStairReport's Flaming Sword line).
func summary_extra() -> String:
	var st := game.stats  # Run counters.
	return "casts=%d hits=%d echoes=%d reach_bonus_px=%d" % [int(st.get("sword_casts", 0.0)), int(st.get("sword_hits", 0.0)),
		int(st.get("sword_echoes", 0.0)), int(st.get("sword_reach_bonus_px", 0.0))]


## The spectral blade crossing its arc (soul-teal flame, bone-white core) with
## a short afterglow. Visual only: lines and disc textures.
func _draw() -> void:
	var p := caster_pos()  # The hilt.
	for s: Dictionary in _shown:
		var k := clampf((game.elapsed - float(s["t0"])) / FlamingSwordData.SWEEP_SHOW, 0.0, 1.0)  # How far across.
		var arc := float(s["arc"])
		var dir := -1.0 if bool(s["back"]) else 1.0
		var a0 := float(s["aim"]) - dir * arc * 0.5  # The edge it starts from.
		var reach := float(s["reach"])
		for t in 3:
			var ta := a0 + dir * arc * maxf(0.0, k - 0.12 * float(t + 1))  # Afterglow angle.
			draw_line(p, p + Vector2.from_angle(ta) * reach, Color(FlamingSwordData.FLAME, 0.16 - 0.045 * float(t)), 5.0)
		var tip := p + Vector2.from_angle(a0 + dir * arc * k) * reach
		draw_line(p, tip, Color(FlamingSwordData.FLAME, 0.75), 5.0)
		draw_line(p, tip, FlamingSwordData.CORE, 1.5)
		SpriteBank.draw_disc(self, tip, 4.0, Color(FlamingSwordData.FLAME, 0.6))
