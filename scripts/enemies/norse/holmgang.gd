## Holmgang — THE HOLMGANG's square of hazel rods (Sigrun, the Shield-Queen's
## second phase; Valgard, the Hall of the Slain temporarily Act XI; GDD §15.0
## "Sigrun, the Shield-Queen (the Hall of the Slain)"; owner-approved proposal:
## "a square of hazel rods closes around the two of them for 15 s, and summons
## cannot enter; spells and Grave Step only"). Owned by BossSigrun (a child of
## the Game, created once per boss), opened by open() and enforced by
## enforce() every tick of the duel, AFTER the summons and the necromancer have
## moved (BossSigrun.physics_step(), inside EnemyDirector.step(); the obstacle
## push-out runs after it):
##   * THE DUELLIST (the necromancer she challenged) cannot leave the square: he
##     is held inside it (Grave Step too; the rods are the duel's edge).
##   * SIGRUN is held inside it.
##   * EVERY SUMMON (both armies in co-op), every other necromancer and every
##     other enemy (structures aside) is pushed out to the nearest side and
##     cannot enter (the enemies ENEMY_BAND px further: the duel ground's
##     verge): the one keep-out path of the duel. Summons never get an
##     act-only rule: this is a world effect on positions, like an obstacle.
## Which hits land on Sigrun in the square is BossSigrun.damage_taken_mult()'s
## (spells only). Drawing: the rods close in over `close_time` s, then stand;
## posts and rope lines as rects (static: redrawn only while they move).
## Deterministic: no RNG; positions only. Stats: holmgang_pushed_summons,
## holmgang_pushed_enemies, holmgang_held_player.
class_name Holmgang
extends Node2D

## Px between two hazel rods along a side (drawing only).
const ROD_STEP: float = 22.0  # TUNING (not in GDD) visual only
## Rod colour (hazel bark).
const ROD_COLOR: Color = Color(0.42, 0.30, 0.18)  # TUNING (not in GDD) visual only
## Rope colour between the rods.
const ROPE_COLOR: Color = Color(0.78, 0.68, 0.46, 0.85)  # TUNING (not in GDD) visual only
## Tint of the duel ground inside the square (a faint gold).
const GROUND_TINT: Color = Color(0.96, 0.84, 0.48, 0.08)  # TUNING (not in GDD) visual only
## Px a body is set beyond the rods when it is pushed out.
const OUT_GAP: float = 2.0  # TUNING (not in GDD)
## Px every other ENEMY is kept beyond the rods (the duel ground's verge): the
## army is outside and cannot shield the duellist, so no blade may reach over
## the rope at a duellist pressed against it (melee reach is under 20 px).
const ENEMY_BAND: float = 34.0  # TUNING (not in GDD) first pass 0: the seed-7 army bot, hugging the rope, fell to 35 of 120 HP to the berserkers outside

## Owning run.
var game: Game
## True while the square stands.
var active: bool = false
## Centre of the square (world px).
var center: Vector2 = Vector2.ZERO
## Half the square's side (px).
var half: float = 150.0
## Game time the square closed (drawing).
var opened_at: float = 0.0
## Seconds the rods take to close in (drawing).
var close_time: float = 0.6
## Reusable query buffer.
var _tmp: Array = []
## True when this build draws (never headless).
var _draws: bool = false
## True while the rods still move (drawn every frame).
var _moving: bool = false


func _init(p_game: Game) -> void:
	game = p_game
	name = "Holmgang"
	z_index = -5  # On the ground, under the bodies.
	z_as_relative = false
	_draws = DisplayServer.get_name() != "headless"


## Closes the square around world point `at` (`p_half` px half side; the rods
## take `p_close` s to close, drawing only).
func open(at: Vector2, p_half: float, p_close: float) -> void:
	active = true
	center = at
	half = p_half
	close_time = p_close
	opened_at = game.elapsed
	_moving = true
	if _draws:
		queue_redraw()


## The rods fall: the square is gone.
func close() -> void:
	active = false
	_moving = false
	if _draws:
		queue_redraw()


## True when a body of radius `r` at `p` overlaps the square.
func overlaps(p: Vector2, r: float) -> bool:
	var rel := p - center
	return absf(rel.x) < half + r and absf(rel.y) < half + r


## `p` held inside the square, `margin` px from the rods.
func clamp_in(p: Vector2, margin: float) -> Vector2:
	var m := maxf(half - margin, 0.0)
	return Vector2(clampf(p.x, center.x - m, center.x + m), clampf(p.y, center.y - m, center.y + m))


## `p` (a body of radius `r` overlapping the square) set just outside the
## nearest side.
func push_out(p: Vector2, r: float) -> Vector2:
	var rel := p - center
	var ox := half + r - absf(rel.x)  # Overlap along x (px).
	var oy := half + r - absf(rel.y)  # Overlap along y (px).
	if ox < oy:
		return Vector2(center.x + (1.0 if rel.x >= 0.0 else -1.0) * (half + r + OUT_GAP), p.y)
	return Vector2(p.x, center.y + (1.0 if rel.y >= 0.0 else -1.0) * (half + r + OUT_GAP))


## THE KEEP-OUT (see the header), every tick of the duel: `duelist` and `boss`
## held in, everyone else pushed out.
func enforce(boss: Enemy, duelist: Necromancer) -> void:
	if not active:
		return
	if duelist != null and not duelist.dead:
		var held := clamp_in(duelist.position, duelist.radius + 2.0)
		if held != duelist.position:
			duelist.position = held
			game.stat_add("holmgang_held_player", 1.0)
	boss.position = clamp_in(boss.position, boss.radius * 0.5)
	for pl in game.all_players:
		if pl != duelist and not pl.dead and overlaps(pl.position, pl.radius):
			pl.position = push_out(pl.position, pl.radius)
	var reach := half * 1.5 + UnitData.MAX_BLOCK_RADIUS
	game.ally_grid.query(center, reach, _tmp)
	for u: SummonedUnit in _tmp:
		if not u.active or u.state == SummonedUnit.State.DEAD or not overlaps(u.position, u.radius):
			continue
		u.position = push_out(u.position, u.radius)
		game.stat_add("holmgang_pushed_summons", 1.0)
	game.enemy_grid.query(center, reach + ProjectileManager.MAX_BODY_RADIUS, _tmp)
	for e: Enemy in _tmp:
		if e == boss or not e.active or e.is_structure or e.is_boss or not overlaps(e.position, e.radius + ENEMY_BAND):
			continue
		e.position = push_out(e.position, e.radius + ENEMY_BAND)
		game.stat_add("holmgang_pushed_enemies", 1.0)
	if _draws and _moving:
		queue_redraw()


# =====================================================================================
# Drawing (visual only; never headless)
# =====================================================================================

## The duel ground (a faint gold), the rope between the rods and the rods,
## closing in from 1.5x the square while they move.
func _draw() -> void:
	if not active:
		return
	var k := clampf((game.elapsed - opened_at) / maxf(close_time, 0.01), 0.0, 1.0)  # 0 -> 1 as the rods close.
	if k >= 1.0:
		_moving = false
	var h := half * (1.5 - 0.5 * k)  # Drawn half side (px).
	var r := Rect2(center - Vector2(h, h), Vector2(h, h) * 2.0)
	draw_rect(r, GROUND_TINT)
	# The rope: four thin rects along the sides.
	draw_rect(Rect2(r.position + Vector2(0.0, -7.0), Vector2(r.size.x, 1.0)), ROPE_COLOR)
	draw_rect(Rect2(Vector2(r.position.x, r.end.y - 7.0), Vector2(r.size.x, 1.0)), ROPE_COLOR)
	draw_rect(Rect2(r.position + Vector2(-1.0, -7.0), Vector2(1.0, r.size.y)), ROPE_COLOR)
	draw_rect(Rect2(Vector2(r.end.x, r.position.y - 7.0), Vector2(1.0, r.size.y)), ROPE_COLOR)
	var n := maxi(2, roundi(h * 2.0 / ROD_STEP))  # Rods per side.
	for i in n + 1:
		var t := float(i) / float(n)
		for p: Vector2 in [Vector2(r.position.x + r.size.x * t, r.position.y), Vector2(r.position.x + r.size.x * t, r.end.y),
				Vector2(r.position.x, r.position.y + r.size.y * t), Vector2(r.end.x, r.position.y + r.size.y * t)]:
			draw_rect(Rect2(p + Vector2(-1.5, -10.0), Vector2(3.0, 11.0)), ROD_COLOR)
			draw_rect(Rect2(p + Vector2(-1.5, -11.0), Vector2(3.0, 2.0)), Palette.NORSE_PINE_LIGHT)  # A hazel leaf at the top.
