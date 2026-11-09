## HallowedLight — HALLOWED LIGHT, the Celestial Host's ground hazard
## (temporary Act XIII; GDD §15.0 "Hallowed Light"; proposal: "Shafts of white
## light sweep the arena on telegraphed paths (a thin line 1.5 s ahead) and
## burn the undead standing in them, summons and the necromancer alike; angels
## in the light are healed. The shadows of clouds and pillars are safe ground,
## Warder barriers and Orb Shields block a shaft, and the necromancer can lead
## the ring through the dark. One ground-hazard path, like Act VI's pits"),
## owned by Game.host as `light`. THE ONE PATH of the Light:
##   * THE SHAFTS: from LIGHT "first" s, every "every" s (shorter by
##     every_step each minute, never below every_min; x every_mult once the
##     Last Trumpet sounds), at most max_live at once, a shaft opens
##     start_offset px to one side of a standing necromancer at a seeded angle
##     (the gameplay RNG) and sweeps "speed" px/s across him for "travel" px:
##     a band "width" px wide (x width_mult) and "length" px long. A thin line
##     always runs `lead` s ahead of it (the telegraph). add_shaft() is the
##     call for phase 2 (the Throne's Gaze, the Voice's Holy).
##   * THE BURN: every "tick" s, every summon in a band takes summon_burn and
##     every necromancer player_burn (x the time scaling), unless it stands in
##     shade (CloudShade.in_shade(), or within pillar_pad px of an obstacle:
##     the pillar's shadow), or a barrier blocks it (a summon's barrier_hp, the
##     necromancer's ward shield_hp, or one of his charged orbs, spent:
##     AbilityManager.try_intercept()); counted as shaded / blocked.
##   * THE HEAL: every Host kind in a band heals angel_heal of its max HP a
##     tick (CombatResolver.heal_enemy()).
## Summons get no act-only rule: the Light is a hazard on the ground, read by
## the army only as damage. Off a Host stage (a forced Host kind) no shaft
## opens unless phase 2 adds one. Drawn: the shafts (rotated rects, starlight
## white) and their cerulean lines, z 14. Determinism: game time and the
## seeded gameplay RNG, only on a Host stage.
## Stats: light_shafts, light_summon_burns, light_summon_dmg,
## light_player_burns, light_shaded, light_blocked, light_angel_heals.
class_name HallowedLight
extends Node2D

## Owning run.
var game: Game
## True on a Host stage (the clock opens shafts).
var enabled: bool = false
## The Light's numbers (HostRulesData.LIGHT, the stage's "light" over it).
var cfg: Dictionary = {}
## The cloud banks (child node: drawn on the ground).
var clouds: CloudShade
## Live shafts: [origin (Vector2, its centre line at t0), axis (Vector2, unit,
## along the shaft), normal (Vector2, unit, its motion), t0 (game s), width
## (px), travel (px)].
var shafts: Array = []
## x every shaft's width (the Last Trumpet; phase 2's Choir). 1 = the data.
var width_mult: float = 1.0
## x the clock's gap (the Last Trumpet). 1 = the data.
var every_mult: float = 1.0
## Shafts at once allowed now (max_live, raised when the sky opens).
var max_live: int = 0
## Shafts opened this run.
var opened: int = 0
## Shafts refused (max_live reached).
var refused: int = 0
## Game time (s) of the next shaft (INF = the clock is off).
var _next: float = INF
## Seconds banked toward the next burn tick.
var _tick_acc: float = 0.0
## True when this build draws (never headless).
var _draws: bool = false
## True while the last redraw showed a shaft (one more redraw clears it).
var _drawn_any: bool = false


## Builds the Light for `p_game`; `p_enabled`: a Host stage.
func _init(p_game: Game, p_enabled: bool) -> void:
	game = p_game
	name = "HallowedLight"
	z_index = 14  # Over the units; under the Verdict's pillars.
	z_as_relative = false
	enabled = p_enabled
	cfg = HostRulesData.LIGHT.duplicate()
	var over: Dictionary = p_game.stage_def.get("light", {})  # The stage's own overrides.
	for key: String in over:
		cfg[key] = over[key]
	max_live = int(cfg["max_live"])
	if enabled:
		_next = float(cfg["first"])
	clouds = CloudShade.new(p_game, p_enabled)
	_draws = DisplayServer.get_name() != "headless"


## Seconds until the next shaft now: every - every_step per minute, never
## below every_min, x every_mult.
func interval() -> float:
	var minutes := floorf(game.elapsed / 60.0)
	return maxf(float(cfg["every_min"]), float(cfg["every"]) - float(cfg["every_step"]) * minutes) * every_mult


## THE public call for phase 2: a shaft whose centre line starts at `origin`
## and sweeps along `normal` (unit) for `travel` px, `width` px wide. False
## when max_live shafts already run.
func add_shaft(origin: Vector2, normal: Vector2, width: float, travel: float) -> bool:
	if shafts.size() >= max_live:
		refused += 1
		return false
	var n := normal.normalized()
	shafts.append([origin, n.orthogonal(), n, game.elapsed, width * width_mult, travel])
	opened += 1
	game.stat_add("light_shafts", 1.0)
	game.host.play_sound("light_warn", origin, 0.5)
	return true


## A shaft's centre line now.
func centre(sh: Array, t: float) -> Vector2:
	return (sh[0] as Vector2) + (sh[2] as Vector2) * float(cfg["speed"]) * (t - float(sh[3]))


## True when a body of radius `r` at `p` stands inside shaft `sh` at time `t`.
func in_band(sh: Array, p: Vector2, r: float, t: float) -> bool:
	var rel := p - centre(sh, t)
	return absf(rel.dot(sh[2])) <= float(sh[4]) * 0.5 + r * 0.5 and absf(rel.dot(sh[1])) <= float(cfg["length"]) * 0.5


## True when a body of radius `r` at `p` stands in shade: a cloud's shadow,
## or a pillar's (within pillar_pad px of an obstacle).
func shaded(p: Vector2, r: float) -> bool:
	return clouds.in_shade(p, r) or game.arena.is_blocked(p, r + float(cfg["pillar_pad"]))


## Per tick (HostRules.step()): the clouds, the clock, the burn, the sweep.
func step(delta: float) -> void:
	clouds.step(delta)
	var now := game.elapsed
	if now >= _next:
		_next = now + interval()
		_open_auto()
	if shafts.is_empty():
		if _draws and _drawn_any:
			_drawn_any = false
			queue_redraw()
		return
	_tick_acc += delta
	var tick := float(cfg["tick"])
	if _tick_acc >= tick:
		_tick_acc -= tick
		_burn(now)
	var i := shafts.size() - 1
	while i >= 0:
		var sh: Array = shafts[i]
		if float(cfg["speed"]) * (now - float(sh[3])) >= float(sh[5]):
			shafts.remove_at(i)
		i -= 1
	if _draws:
		_drawn_any = true
		queue_redraw()


## The clock's shaft: start_offset px to one side of a standing necromancer
## at a seeded angle, sweeping across him.
func _open_auto() -> void:
	var standing: Array[Necromancer] = []
	for pl in game.all_players:
		if not pl.dead:
			standing.append(pl)
	if standing.is_empty():
		return
	var pl: Necromancer = standing[randi() % standing.size()]
	var n := Vector2.from_angle(randf() * TAU)
	add_shaft(pl.position - n * float(cfg["start_offset"]), n, float(cfg["width"]), float(cfg["travel"]))


## One burn tick: the undead in every band are burnt (unless shaded or
## blocked), the angels in it healed.
func _burn(now: float) -> void:
	var ts := game.enemies.damage_mult  # The time scaling (and the difficulty).
	var burnt := false
	for sh: Array in shafts:
		for h in game.all_hordes:
			for u in h.units:
				if not u.active or u.state == SummonedUnit.State.SPAWNING or not in_band(sh, u.position, u.radius, now):
					continue
				if shaded(u.position, u.radius):
					game.stat_add("light_shaded", 1.0)
				elif u.barrier_hp > 0.0:
					game.stat_add("light_blocked", 1.0)
				else:
					var dmg := float(cfg["summon_burn"]) * ts * game.host.smoked_glass_mult()  # Smoked Glass: exactly 1 until phase 2 builds it.
					game.combat.damage_unit(u, dmg, HostRulesData.LIGHT_SOURCE)
					game.stat_add("light_summon_burns", 1.0)
					game.stat_add("light_summon_dmg", dmg)
					burnt = true
		for k in game.all_players.size():
			var pl := game.all_players[k]
			if pl.dead or not in_band(sh, pl.position, pl.radius, now):
				continue
			if shaded(pl.position, pl.radius):
				game.stat_add("light_shaded", 1.0)
			elif pl.shield_hp > 0.0 or _orb_blocks(k, pl):
				game.stat_add("light_blocked", 1.0)
			else:
				game.combat.damage_player(float(cfg["player_burn"]) * ts, HostRulesData.LIGHT_SOURCE, pl)
				game.stat_add("light_player_burns", 1.0)
				burnt = true
		for e in game.enemies.active:
			if e.active and e.kit is HostKit and e.hp < e.max_hp and in_band(sh, e.position, e.radius, now):
				if game.combat.heal_enemy(e, e.max_hp * float(cfg["angel_heal"])) > 0.0:
					game.stat_add("light_angel_heals", 1.0)
	if burnt:
		game.host.play_sound("light_burn", game.player.position, 0.5)


## True when one of necromancer `pl`'s (slot `k`) charged orbs takes the
## light for him (the orb is spent: AbilityManager.try_intercept()).
func _orb_blocks(k: int, pl: Necromancer) -> bool:
	var prev := game.bind_index(k)
	var stop := game.abilities.try_intercept(pl.position, float(cfg["orb_reach"]))
	game.unbind(prev)
	return stop


## The autotest autopilot's push across every shaft it stands in (toward the
## side the shaft has already passed, the quickest way out of the light).
func danger_push(p: Vector2) -> Vector2:
	var push := Vector2.ZERO
	var now := game.elapsed
	for sh: Array in shafts:
		if in_band(sh, p, 24.0, now) and not shaded(p, 10.0):
			push -= (sh[2] as Vector2) * 1.2
	return push


## Every shaft (a starlight band) and its cerulean line `lead` s ahead
## (rotated rects only).
func _draw() -> void:
	var now := game.elapsed
	var length := float(cfg["length"])
	var ahead := float(cfg["speed"]) * float(cfg["lead"])
	for sh: Array in shafts:
		var c := centre(sh, now)
		var w := float(sh[4])
		draw_set_transform(c, (sh[2] as Vector2).angle(), Vector2.ONE)
		draw_rect(Rect2(Vector2(-w * 0.5, -length * 0.5), Vector2(w, length)), Color(Palette.HOST_STARLIGHT, 0.28))
		draw_rect(Rect2(Vector2(-w * 0.2, -length * 0.5), Vector2(w * 0.4, length)), Color(Palette.HOST_STARLIGHT, 0.22))
		draw_rect(Rect2(Vector2(ahead - 1.0, -length * 0.5), Vector2(2.0, length)), Color(Palette.HOST_CERULEAN, 0.75))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
