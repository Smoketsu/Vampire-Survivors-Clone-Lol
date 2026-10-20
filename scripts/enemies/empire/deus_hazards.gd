## DeusHazards — the world hazards of DEUS EX MACHINA (BossDeusExMachina; Act
## III, the Iron Citadel; GDD §15.0 "The Iron Citadel (Act III phase 2)"),
## drawn under the bodies like Vhal'Neth's (a child of EnemyDirector, created by
## the boss, its numbers in DeusData.BOSS):
##   rings  — FOOTFALLS and STOMPS (and the Founder's arrival stomp): a
##            telegraphed circle on the ground that lands after its telegraph:
##            the necromancer inside takes its player damage, every summon on the
##            ground inside its summon damage and is thrown out of the circle.
##            Undead do not dodge; only the necromancer steps out.
##   pulses — the Founder's OVERLOAD PULSES: a charging glow around the hull for
##            pulse_charge s (the telegraph), then a ring rolls out at pulse_speed
##            px/s to pulse_reach px; every body its pulse_front px thick front
##            passes is hit once (its damage grows pulse by pulse, set by the
##            boss). The necromancer far enough away, or in a Grave Step's
##            i-frames, is spared.
##   finale — the soul-binding rings when it falls (drawing only).
## All damage goes through CombatResolver; everything is time-scaled when it
## lands (the enemies' damage scaling). Determinism: no RNG. Stats:
## deus_footfall_player_hits, deus_stomp_player_hits, deus_ring_summon_hits,
## deus_pulse_player_hits, deus_pulse_summon_hits; damage as
## player_dmg_from_deus_<source>.
class_name DeusHazards
extends Node2D

## Owning run.
var game: Game
## The boss (its position is the pulses' origin).
var boss: Enemy = null
## Pending rings: each [centre, radius, land time, telegraph, player damage,
## summon damage, knockback px, source tag, stat prefix].
var _rings: Array = []
## Rings that just landed, for the shock drawing: [centre, radius, game time].
var _shocks: Array = []
## Rolling pulses: each [origin, release time, player damage, summon damage,
## hit dictionary (Object -> generation)].
var _pulses: Array = []
## Game time the next pulse is released (INF = no pulse charging).
var _charge_until: float = INF
## Player / summon damage of the pulse now charging.
var _charge_dmg: Vector2 = Vector2.ZERO
## Game time the finale began (-1 = not yet).
var _finale_at: float = -1.0
## Where the finale plays.
var _finale_pos: Vector2 = Vector2.ZERO
## Reusable query buffer.
var _tmp: Array = []


## Sets up the hazards for `p_game` and `p_boss`.
func setup(p_game: Game, p_boss: Enemy) -> void:
	game = p_game
	boss = p_boss
	z_index = -1  # On the ground, under the bodies.


## Queues a ring at `at` (`r` px) landing `tele` s from now, dealing `dmg_p` to
## the necromancer and `dmg_s` to each summon inside (both before the time
## scaling), throwing summons `knock` px out; `source` tags the damage.
func ring(at: Vector2, r: float, tele: float, dmg_p: float, dmg_s: float, knock: float, source: String, stat: String) -> void:
	_rings.append([at, r, game.elapsed + tele, tele, dmg_p, dmg_s, knock, source, stat])


## Starts charging an overload pulse (released after `charge` s) with these damages.
func charge_pulse(charge: float, dmg_p: float, dmg_s: float) -> void:
	_charge_until = game.elapsed + charge
	_charge_dmg = Vector2(dmg_p, dmg_s)


## True while a pulse charges (the boss waits before the next).
func pulse_charging() -> bool:
	return _charge_until != INF


## Drops every pending ring and pulse (a phase change, the boss's death).
func clear() -> void:
	_rings.clear()
	_pulses.clear()
	_charge_until = INF


## Starts the finale's soul-binding rings at `pos` (drawing only).
func start_finale(pos: Vector2) -> void:
	clear()
	_finale_at = game.elapsed
	_finale_pos = pos


## Keeps the soul binding animating after the boss (which drives step()) is gone;
## stops redrawing once it has played. Drawing only.
func _process(_delta: float) -> void:
	if _finale_at >= 0.0 and game != null and game.elapsed - _finale_at <= float(DeusData.BOSS["finale_time"]) + 0.1:
		queue_redraw()


## Per-tick update (the boss calls it): lands due rings, releases and rolls pulses.
func step(_delta: float) -> void:
	var t := game.elapsed
	var i := 0
	while i < _rings.size():
		var rg: Array = _rings[i]
		if t >= float(rg[2]):
			_rings.remove_at(i)
			_land(rg)
		else:
			i += 1
	if _charge_until != INF and t >= _charge_until:
		_charge_until = INF
		_pulses.append([boss.position, t, _charge_dmg.x, _charge_dmg.y, {}])
		Sfx.play("overload_pulse", boss.position)
		game.shake(5.0)
	_step_pulses(t)
	var j := _shocks.size() - 1
	while j >= 0:
		if t - float(_shocks[j][2]) > 0.35:
			_shocks.remove_at(j)
		j -= 1
	queue_redraw()


## A ring lands: the necromancer and the summons inside are hit.
func _land(rg: Array) -> void:
	var at: Vector2 = rg[0]
	var r := float(rg[1])
	var mult := game.enemies.damage_mult  # Time scaling.
	var src := String(rg[7])
	for pl in game.all_players:  # (Co-op: every necromancer inside.)
		if pl.position.distance_to(at) <= r + pl.radius:
			game.combat.damage_player(float(rg[4]) * mult, src, pl)
			game.stat_add(String(rg[8]) + "_player_hits", 1.0)
	game.ally_grid.query(at, r + UnitData.MAX_BLOCK_RADIUS, _tmp)
	var hits := 0  # Summons struck.
	for u: SummonedUnit in _tmp:
		if not u.active or u.airborne or u.state == SummonedUnit.State.SPAWNING:
			continue
		if u.position.distance_to(at) > r + u.radius:
			continue
		var away := u.position - at
		u.position += (away.normalized() if away.length() > 0.5 else Vector2.UP) * float(rg[6])
		game.combat.damage_unit(u, float(rg[5]) * mult, src)
		hits += 1
	game.stat_add("deus_ring_summon_hits", float(hits))
	_shocks.append([at, r, game.elapsed])
	game.effects.impact(at, r * 0.8, Palette.EMPIRE_CHROME_LIGHT)
	game.shake(3.0 if r < 80.0 else 6.0)
	Sfx.play("servo_step" if r < 80.0 else "boss_impact", at)


## Rolls every pulse out and hits what its front passes.
func _step_pulses(t: float) -> void:
	var speed := float(DeusData.BOSS["pulse_speed"])
	var reach := float(DeusData.BOSS["pulse_reach"])
	var half := float(DeusData.BOSS["pulse_front"]) * 0.5
	var mult := game.enemies.damage_mult
	var i := _pulses.size() - 1
	while i >= 0:
		var pu: Array = _pulses[i]
		var r := (t - float(pu[1])) * speed  # Front radius now (px).
		if r > reach + half:
			_pulses.remove_at(i)
			i -= 1
			continue
		var o: Vector2 = pu[0]
		var hit: Dictionary = pu[4]
		for pl in game.all_players:  # (Co-op: every necromancer the front passes, once.)
			var dp := pl.position.distance_to(o)
			if not hit.has(pl) and absf(dp - r) <= half + pl.radius:
				hit[pl] = 0
				game.combat.damage_player(float(pu[2]) * mult, "deus_pulse", pl)
				game.stat_add("deus_pulse_player_hits", 1.0)
		game.ally_grid.query(o, r + half + UnitData.MAX_BLOCK_RADIUS, _tmp)
		for u: SummonedUnit in _tmp:
			if not u.active or u.airborne or u.state == SummonedUnit.State.SPAWNING:
				continue
			if hit.has(u) and int(hit[u]) == u.generation:
				continue
			if absf(u.position.distance_to(o) - r) <= half + u.radius:
				hit[u] = u.generation
				game.combat.damage_unit(u, float(pu[3]) * mult, "deus_pulse")
				game.stat_add("deus_pulse_summon_hits", 1.0)
		i -= 1


## Autopilot hint: out of a pending ring, and away from a charging hull (a
## pulse rolls out; the bot Grave Steps through the front, Autotest).
func danger_push(p: Vector2) -> Vector2:
	var push := Vector2.ZERO
	for rg: Array in _rings:
		var off := p - (rg[0] as Vector2)
		var reach := float(rg[1]) + game.player.radius + 12.0
		var dist := off.length()
		if dist < reach:
			push += (off / dist if dist > 0.01 else Vector2.RIGHT) * (1.0 - dist / reach) * 1.5
	return push


## True while an overload pulse's front is about to reach `p` (the autotest bot
## Grave Steps through it).
func pulse_near(p: Vector2) -> bool:
	var speed := float(DeusData.BOSS["pulse_speed"])
	for pu: Array in _pulses:
		var r := (game.elapsed - float(pu[1])) * speed
		var d := p.distance_to(pu[0] as Vector2)
		if d > r and d - r < 40.0:
			return true
	return false


## Rings (warning red, filling as they near), shocks, the charging glow, the
## rolling pulse fronts and the finale. Visual only.
func _draw() -> void:
	if game == null:
		return
	var t := game.elapsed
	for rg: Array in _rings:
		var k := clampf(1.0 - (float(rg[2]) - t) / maxf(0.01, float(rg[3])), 0.0, 1.0)
		CitadelGlyphs.draw_stomp_ring(self, rg[0], float(rg[1]), k)
	for sh: Array in _shocks:
		var k2 := clampf((t - float(sh[2])) / 0.35, 0.0, 1.0)
		draw_arc(sh[0], float(sh[1]) * (0.7 + 0.5 * k2), 0.0, TAU, 40, Color(Palette.EMPIRE_CHROME_LIGHT, 0.6 * (1.0 - k2)), 3.0)
	if _charge_until != INF and boss != null:
		var k3 := clampf(1.0 - (_charge_until - t) / maxf(0.01, float(DeusData.BOSS["pulse_charge"])), 0.0, 1.0)
		CitadelGlyphs.draw_pulse_charge(self, boss.position, boss.radius, k3, t)
	var speed := float(DeusData.BOSS["pulse_speed"])
	var reach := float(DeusData.BOSS["pulse_reach"])
	for pu: Array in _pulses:
		var r := (t - float(pu[1])) * speed
		CitadelGlyphs.draw_pulse_front(self, pu[0], r, float(DeusData.BOSS["pulse_front"]), clampf(1.0 - r / reach, 0.0, 1.0))
	if _finale_at >= 0.0:
		var age := t - _finale_at
		var ft := float(DeusData.BOSS["finale_time"])
		if age <= ft:
			CitadelGlyphs.draw_soul_binding(self, _finale_pos, DeusData.BINDING_RADIUS, age / ft, t)
