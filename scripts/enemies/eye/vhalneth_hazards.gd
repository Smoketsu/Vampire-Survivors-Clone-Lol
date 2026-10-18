## VhalnethHazards — the world-space hazards of Vhal'Neth, the Dreaming Mother
## (BossVhalneth; numbers in VhalnethData.BOSS), drawn under the bodies:
##   * The GAZE (Stirring, Waking): an eye opens over a spot on the island
##     (the necromancer's, led by gaze_lead s of his movement) for
##     gaze_telegraph s, then her gaze rests there for gaze_rest s, drifting
##     after him at gaze_drift px/s (he outruns it). While he stands in it his
##     Dread climbs gaze_dread per second through THE Dread path
##     (game.dread.add(.., "gaze"); on a stage without Dread, a light hit
##     instead), and every summon in it withers (gaze_summon_damage every
##     gaze_tick s, time-scaled): the army has to move.
##   * The ROAR (Waking): a ring around her face, telegraphed roar_telegraph
##     s, then a blast: damage to the necromancer and every summon inside,
##     summons thrown out of it.
##   * The FINALE: after her death, the binding (the necromancer raises the
##     dead god; drawing only, the run goes on).
## The Eye's bioluminescence marks every telegraph (never gold, never the
## player's violet). Determinism: game time only, no RNG.
## Stats: boss_atk_gaze, boss_atk_roar, vhalneth_gaze_player_seconds,
## vhalneth_gaze_summon_ticks, vhalneth_roar_player_hits, vhalneth_roar_summon_hits.
class_name VhalnethHazards
extends Node2D

## Gaze phase: none.
const GAZE_NONE: int = 0
## Gaze phase: the eye opens (telegraph).
const GAZE_OPENING: int = 1
## Gaze phase: the gaze rests on the island.
const GAZE_RESTING: int = 2
## Damage source tag of the gaze (CombatResolver stats).
const GAZE_SOURCE: String = "vhalneth_gaze"
## Damage source tag of the roar (CombatResolver stats; an area hit).
const ROAR_SOURCE: String = "vhalneth_roar"

## Owning run.
var game: Game
## The boss.
var boss: BossVhalneth
## Her numbers (VhalnethData.BOSS).
var def: Dictionary = {}
## Current gaze phase.
var gaze_phase: int = GAZE_NONE
## Seconds in the current gaze phase.
var gaze_t: float = 0.0
## Where the gaze rests (world px).
var gaze_pos: Vector2 = Vector2.ZERO
## Radius (px) of the current gaze.
var gaze_radius: float = 120.0
## Seconds until the next gaze damage tick.
var _gaze_tick: float = 0.0
## True while a roar is telegraphed.
var roar_pending: bool = false
## Seconds the roar telegraph has run.
var roar_t: float = 0.0
## True while the finale (the binding) plays.
var finale_on: bool = false
## Seconds the finale has played.
var finale_t: float = 0.0
## Where the finale plays (her last position).
var finale_pos: Vector2 = Vector2.ZERO


## Wires the hazards to boss `b`.
func setup(p_game: Game, b: BossVhalneth) -> void:
	game = p_game
	boss = b
	def = b.boss_def
	z_index = -1  # Under the bodies, over the floor, the sea and the obstacles.


## Per-tick update (BossVhalneth.physics_step(); the finale steps itself).
func step(delta: float) -> void:
	_step_gaze(delta)
	_step_roar(delta)
	queue_redraw()


func _physics_process(delta: float) -> void:
	if finale_on and game != null and game.run_state == Game.RunState.PLAYING:
		finale_t += delta
		if finale_t >= float(def["finale_time"]):
			finale_on = false
		queue_redraw()


# =====================================================================================
# The gaze
# =====================================================================================

## Opens her eye over the necromancer's path (`r` px).
func start_gaze(r: float) -> void:
	var pl := game.player
	var p := pl.position + pl.velocity * float(def["gaze_lead"])
	gaze_pos = game.arena.free_point(p, 0.0)
	gaze_radius = r
	gaze_phase = GAZE_OPENING
	gaze_t = 0.0
	_gaze_tick = float(def["gaze_tick"])
	game.stat_add("boss_atk_gaze", 1.0)
	Sfx.play("boss_telegraph", gaze_pos, 0.6)


## True while a gaze opens or rests.
func gaze_busy() -> bool:
	return gaze_phase != GAZE_NONE


func _step_gaze(delta: float) -> void:
	if gaze_phase == GAZE_NONE:
		return
	gaze_t += delta
	if gaze_phase == GAZE_OPENING:
		if gaze_t >= float(def["gaze_telegraph"]):
			gaze_phase = GAZE_RESTING
			gaze_t = 0.0
		return
	if gaze_t >= float(def["gaze_rest"]):
		gaze_phase = GAZE_NONE
		return
	var pl := game.player
	gaze_pos = gaze_pos.move_toward(pl.position, float(def["gaze_drift"]) * delta)
	var inside := pl.position.distance_to(gaze_pos) <= gaze_radius + pl.radius
	if inside:
		game.stat_add("vhalneth_gaze_player_seconds", delta)
		if game.dread != null:
			game.dread.add(float(def["gaze_dread"]) * delta, "gaze")
	_gaze_tick -= delta
	if _gaze_tick > 0.0:
		return
	_gaze_tick += float(def["gaze_tick"])
	var scale := game.enemies.damage_mult
	if inside and game.dread == null:
		game.combat.damage_player(float(def["gaze_player_damage"]) * scale, GAZE_SOURCE)
	var n := 0  # Summons withering in the gaze this tick.
	for u in game.horde.units:
		if u.active and not u.airborne and u.state != SummonedUnit.State.SPAWNING and u.position.distance_to(gaze_pos) <= gaze_radius + u.radius:
			game.combat.damage_unit(u, float(def["gaze_summon_damage"]) * scale, GAZE_SOURCE)
			n += 1
	game.stat_add("vhalneth_gaze_summon_ticks", float(n))


# =====================================================================================
# The roar
# =====================================================================================

## Telegraphs a roar around her face.
func start_roar() -> void:
	roar_pending = true
	roar_t = 0.0
	game.stat_add("boss_atk_roar", 1.0)
	Sfx.play("boss_telegraph", boss.position, 0.5)


func _step_roar(delta: float) -> void:
	if not roar_pending:
		return
	roar_t += delta
	if roar_t < float(def["roar_telegraph"]):
		return
	roar_pending = false
	var c := boss.position
	var r := float(def["roar_radius"])
	var scale := game.enemies.damage_mult
	var pl := game.player
	if pl.position.distance_to(c) <= r + pl.radius:
		game.combat.damage_player(float(def["roar_damage_player"]) * scale, ROAR_SOURCE)
		game.stat_add("vhalneth_roar_player_hits", 1.0)
	var n := 0  # Summons struck.
	for u in game.horde.units:
		if not u.active or u.airborne or u.state == SummonedUnit.State.SPAWNING:
			continue
		var off := u.position - c
		if off.length() > r + u.radius:
			continue
		u.position += (off.normalized() if off.length() > 0.1 else Vector2.RIGHT) * float(def["roar_knockback"])
		game.combat.damage_unit(u, float(def["roar_damage_summon"]) * scale, ROAR_SOURCE)
		n += 1
	game.stat_add("vhalneth_roar_summon_hits", float(n))
	game.effects.ring(c, r, Palette.EYE_BIOLUME, 0.45)
	game.effects.impact(c, r * 0.5, Palette.EYE_DROWNED)
	game.shake(8.0)


# =====================================================================================
# The finale, the autopilot, clearing
# =====================================================================================

## Starts the binding at `pos` (her death).
func start_finale(pos: Vector2) -> void:
	clear()
	finale_on = true
	finale_t = 0.0
	finale_pos = pos


## Ends every hazard (her death).
func clear() -> void:
	gaze_phase = GAZE_NONE
	roar_pending = false


## Autopilot hint: out of the gaze, out of the roar ring.
func danger_push(p: Vector2) -> Vector2:
	var push := Vector2.ZERO
	if gaze_phase != GAZE_NONE:
		var off := p - gaze_pos
		if off.length() < gaze_radius + 40.0:
			push += off.normalized() if off.length() > 1.0 else Vector2.RIGHT
	if roar_pending and boss != null:
		var off := p - boss.position
		if off.length() < float(def["roar_radius"]) + 30.0:
			push += off.normalized() if off.length() > 1.0 else Vector2.RIGHT
	return push.limit_length(1.0)


func _draw() -> void:
	if game == null:
		return
	var now := game.elapsed
	if gaze_phase != GAZE_NONE:
		var k := clampf(gaze_t / maxf(0.05, float(def["gaze_telegraph"])), 0.0, 1.0) if gaze_phase == GAZE_OPENING else 1.0
		SpireGlyphs.draw_gaze(self, gaze_pos, gaze_radius, k, gaze_phase == GAZE_RESTING, now)
	if roar_pending and boss != null:
		var rk := clampf(roar_t / maxf(0.05, float(def["roar_telegraph"])), 0.0, 1.0)
		var r := float(def["roar_radius"])
		draw_circle(boss.position, r * rk, Color(Palette.EYE_BIOLUME, 0.12))
		draw_arc(boss.position, r, 0.0, TAU, 56, Color(Palette.EYE_BIOLUME, 0.7), 2.5)
		draw_arc(boss.position, r * rk, 0.0, TAU, 48, Color(Palette.EYE_BIOLUME_GLOW, 0.6), 1.5)
	if finale_on:
		SpireGlyphs.draw_binding(self, finale_pos, VhalnethData.BINDING_RADIUS, finale_t / maxf(0.1, float(def["finale_time"])), now)
