## BosunGorranKit — BOSUN GORRAN, the Smuggler's Cutter's miniboss
## (CutterEnemyData "bosun_gorran"; Act X, the Black Tide; GDD §15.0 "The
## Smuggler's Cutter (Act X phase 2)"; owner-approved proposal: "Bosun Gorran
## and the Ram Longboat (male). A heavy longboat rams the hull (a stagger that
## knocks every summon back) before it boards"). An enormous, scarred male bosun
## with a ship's iron chain-hook. CutterDirector's "gorran" event brings him in
## his ram longboat (the ram is the director's); he steps aboard first and
## registers as EnemyDirector.miniboss (the HUD's miniboss bar; ChestManager
## drops the miniboss chest on his fall: the row's "miniboss"). The shared
## melee AI walks him in and he strikes with the chain-hook in reach. His
## specials (numbers in his row):
##   * THE CHAIN SWEEP: every sweep_every s he whirls the chain (sweep_windup
##     s, a telegraph ring of sweep_radius px), then every grounded summon in
##     reach takes sweep_damage and is knocked sweep_push px away from him
##     (TerrainSlow.push_summon() x CorsairRules.sea_legs_mult(), the act's one
##     shove path: the rail stops it), and a necromancer in reach takes
##     sweep_damage_player (CombatResolver).
##   * THE BELLOW: every bellow_every s his crew within bellow_radius px move
##     bellow_speed x faster for bellow_time s (BoatswainKit.bellow_at(), the
##     one bellow; no shield).
## On death: an XP burst (reward_xp in reward_crystals), the miniboss chest.
## He never drowns (a miniboss: DeckBounds).
## Determinism: no RNG. Stats: gorran_sweeps, gorran_sweep_hits,
## gorran_bellows, gorran_kills, gorran_ttk.
class_name BosunGorranKit
extends CorsairKit

## Phase: the chain whirls (the sweep's telegraph).
const WHIRL: int = 1

## Seconds until his next chain sweep.
var sweep_cd: float = 0.0
## Seconds until his next bellow.
var bellow_cd: float = 0.0
## Game time (s) he came aboard (his time to kill).
var spawned_at: float = 0.0


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	sweep_cd = float(d.get("sweep_every", 7.0)) * 0.5
	bellow_cd = 1.0
	spawned_at = e.game.elapsed
	e.game.enemies.set_miniboss(e)


func physics(e: Enemy, delta: float) -> bool:
	if super.physics(e, delta):
		return true
	sweep_cd -= delta
	bellow_cd -= delta
	if bellow_cd <= 0.0:
		bellow_cd = float(d.get("bellow_every", 10.0))
		BoatswainKit.bellow_at(e, {"radius": float(d.get("bellow_radius", 220.0)), "speed": float(d.get("bellow_speed", 1.25)),
			"shield": 0.0, "time": float(d.get("bellow_time", 4.0))})
		e.game.stat_add("gorran_bellows", 1.0)
		rules(e).play_sound("bosun_whistle", e.position, 0.5)
	if phase == WHIRL:
		phase_time += delta
		hold(e)
		if phase_time >= float(d.get("sweep_windup", 0.8)):
			_sweep(e)
			set_phase(e, IDLE)
		return true
	if sweep_cd <= 0.0 and _anyone_near(e):
		sweep_cd = float(d.get("sweep_every", 7.0))
		set_phase(e, WHIRL)
		e.game.effects.telegraph_circle(e.position, float(d.get("sweep_radius", 74.0)), float(d.get("sweep_windup", 0.8)), e)
		return true
	return false


## True when a summon or a necromancer stands within the sweep's reach.
func _anyone_near(e: Enemy) -> bool:
	var r := float(d.get("sweep_radius", 74.0))
	for pl in e.game.all_players:
		if not pl.dead and pl.position.distance_to(e.position) <= r + pl.radius:
			return true
	var tmp: Array = []
	e.game.ally_grid.query(e.position, r + UnitData.MAX_BLOCK_RADIUS, tmp)
	for u: SummonedUnit in tmp:
		if u.active and not u.airborne and u.position.distance_to(e.position) <= r + u.radius:
			return true
	return false


## THE CHAIN SWEEP: every grounded summon in reach is struck and knocked back.
func _sweep(e: Enemy) -> void:
	var g := e.game
	var r := float(d.get("sweep_radius", 74.0))
	var push := float(d.get("sweep_push", 70.0))
	var mult := hit_scale(e)
	var tmp: Array = []
	var hits := 0
	g.ally_grid.query(e.position, r + UnitData.MAX_BLOCK_RADIUS, tmp)
	for u: SummonedUnit in tmp:
		if not u.active or u.airborne or u.flies or u.state == SummonedUnit.State.DEAD:
			continue
		var off := u.position - e.position
		if off.length() > r + u.radius:
			continue
		g.combat.damage_unit(u, float(d.get("sweep_damage", 10.0)) * mult, e.kind, e)
		var dir := off.normalized() if off.length() > 0.01 else Vector2.RIGHT
		TerrainSlow.push_summon(g, u, dir * push * rules(e).sea_legs_mult(u), 1.0)
		hits += 1
	for pl in g.all_players:
		if not pl.dead and pl.position.distance_to(e.position) <= r + pl.radius:
			g.combat.damage_player(float(d.get("sweep_damage_player", 8.0)) * mult, e.kind, pl, e)
	g.stat_add("gorran_sweeps", 1.0)
	g.stat_add("gorran_sweep_hits", float(hits))
	g.effects.ring(e.position, r, Palette.CORSAIR_POWDER_LIGHT, 0.3)
	rules(e).play_sound("cutlass_slash", e.position, 0.2)


## The XP burst and the stats of his fall (the chest is ChestManager's).
func on_killed(e: Enemy) -> void:
	super.on_killed(e)
	var g := e.game
	var n := maxi(1, int(d.get("reward_crystals", 10)))
	var each := maxi(1, floori(float(d.get("reward_xp", 200)) / float(n)))  # XP per crystal.
	for i in n:
		g.pickups.spawn(e.position + Vector2.from_angle(TAU * float(i) / float(n)) * (24.0 + 6.0 * float(i % 3)), each)
	g.effects.impact(e.position, e.radius * 3.0, Palette.CORSAIR_LANTERN)
	g.shake(8.0)
	g.stat_add("gorran_kills", 1.0)
	g.stat_add("gorran_ttk", g.elapsed - spawned_at)


## Releases the HUD bar.
func on_deactivate(e: Enemy) -> void:
	super.on_deactivate(e)
	e.game.enemies.clear_miniboss(e)


func is_busy() -> bool:
	return in_water or phase != IDLE


## Autopilot hint: out of the chain's reach while it whirls.
func danger_push(e: Enemy, p: Vector2) -> Vector2:
	if phase != WHIRL:
		return Vector2.ZERO
	var reach := float(d.get("sweep_radius", 74.0)) + 24.0
	var off := p - e.position
	var dist := off.length()
	if dist >= reach:
		return Vector2.ZERO
	return (off / dist if dist > 0.01 else Vector2.RIGHT) * (1.0 - dist / reach) * 2.5


## The whirling chain: an iron link circling overhead. Visual only.
func draw_over(e: Enemy, ci: CanvasItem) -> void:
	if phase != WHIRL:
		return
	var a := phase_time * 16.0
	var r := e.radius * 1.6
	for k in 3:
		SpriteBank.draw_disc(ci, Vector2.from_angle(a - float(k) * 0.5) * r * (1.0 - 0.15 * float(k)) + Vector2(0.0, -e.radius), 3.0 - float(k) * 0.6, Palette.CORSAIR_POWDER_LIGHT)
