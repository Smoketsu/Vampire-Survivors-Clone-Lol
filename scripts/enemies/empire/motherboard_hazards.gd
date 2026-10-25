## MotherboardHazards — the world-space telegraphs of THE MOTHERBOARD
## (BossMotherboard; numbers in MotherboardData.BOSS), drawn under the bodies:
##   * PRESS-STAMPS: warning-red squares whose corner brackets close as the
##     stamp falls (stamp_telegraph s), then the stamp lands: the necromancer and
##     every summon inside take its damage.
##   * HURL LANDINGS: the circle where a hurled summon will land (hurl_flight s);
##     the landing hurts the necromancer if he is still in it and the summons it
##     lands among (the boss resolves the landing itself).
##   * TURRET FRAMES: the construction frames where Motherboard Turrets rise
##     (build_telegraph s; the boss spawns them).
## The Empire's warning red and amber mark every telegraph (never the
## Covenant's gold, never the player's violet). Determinism: game time only.
## Stats: motherboard_stamp_player_hits, motherboard_stamp_summon_hits.
class_name MotherboardHazards
extends Node2D

## Owning run.
var game: Game
## The boss.
var boss: Enemy = null
## Its numbers (MotherboardData.BOSS).
var def: Dictionary = {}
## Pending stamps: x, y = the square's centre (world px), z = the game time it lands.
var stamps: Array[Vector3] = []
## Pending hurl landings: x, y = the circle's centre, z = the game time it lands.
var landings: Array[Vector3] = []
## Turret frames: x, y = the frame's centre, z = the game time the turret rises.
var frames: Array[Vector3] = []
## True if the last redraw showed something (one more redraw clears it).
var _drawn: bool = false
## Reusable query buffer.
var _tmp: Array = []


## Binds the layer to `p_game` and `p_boss` (call after add_child).
func setup(p_game: Game, p_boss: Enemy) -> void:
	game = p_game
	boss = p_boss
	def = MotherboardData.BOSS
	z_index = -1  # On the ground, under the units.
	name = "MotherboardHazards"


## Lands the stamps whose time has come; keeps the drawing fresh.
func step(_delta: float) -> void:
	var t := game.elapsed
	var i := 0
	while i < stamps.size():
		var s := stamps[i]
		if t >= s.z:
			stamps.remove_at(i)
			_land_stamp(Vector2(s.x, s.y))
		else:
			i += 1
	_expire(landings, t)
	_expire(frames, t)
	var any := not stamps.is_empty() or not landings.is_empty() or not frames.is_empty()
	if any or _drawn:
		queue_redraw()
	_drawn = any


## Drops the entries of `list` whose time has passed (the boss resolves them).
static func _expire(list: Array[Vector3], t: float) -> void:
	var i := 0
	while i < list.size():
		if t >= list[i].z:
			list.remove_at(i)
		else:
			i += 1


## Telegraphs a stamp on the square centred on `at`.
func add_stamp(at: Vector2) -> void:
	stamps.append(Vector3(at.x, at.y, game.elapsed + float(def["stamp_telegraph"])))


## Shows a hurl landing circle at `at`, landing `after` s from now.
func add_landing(at: Vector2, after: float) -> void:
	landings.append(Vector3(at.x, at.y, game.elapsed + after))


## Shows a turret construction frame at `at`, rising `after` s from now.
func add_frame(at: Vector2, after: float) -> void:
	frames.append(Vector3(at.x, at.y, game.elapsed + after))


## A stamp lands at `at`: the necromancer and every summon inside are hit.
func _land_stamp(at: Vector2) -> void:
	var h := float(def["stamp_size"]) * 0.5  # Half the square's side (px).
	var mult := game.enemies.damage_mult * (boss.hit_mult() if boss != null and boss.active else 1.0)  # Time scaling x its buffs.
	game.effects.impact(at, h * 1.2, Palette.EMPIRE_SIGNAL_AMBER, EmpireFxData.BLAST)  # Its strip when the art exists (visual only).
	Sfx.play("press_stamp", at)
	game.shake(5.0)
	for p in game.all_players:  # (Co-op: either necromancer.)
		if absf(p.position.x - at.x) <= h + p.radius * 0.5 and absf(p.position.y - at.y) <= h + p.radius * 0.5:
			game.combat.damage_player(float(def["stamp_damage_player"]) * mult, MotherboardData.STAMP_SOURCE, p)
			game.stat_add("motherboard_stamp_player_hits", 1.0)
	game.ally_grid.query(at, h * 1.5 + UnitData.MAX_BLOCK_RADIUS, _tmp)
	var hits := 0
	for u: SummonedUnit in _tmp:
		if not u.active or u.state == SummonedUnit.State.SPAWNING or u.airborne:
			continue
		if absf(u.position.x - at.x) <= h + u.radius * 0.5 and absf(u.position.y - at.y) <= h + u.radius * 0.5:
			hits += 1
			game.combat.damage_unit(u, float(def["stamp_damage_summon"]) * mult, MotherboardData.STAMP_SOURCE)
	game.stat_add("motherboard_stamp_summon_hits", float(hits))


## Clears every pending telegraph (the boss fell).
func clear() -> void:
	stamps.clear()
	landings.clear()
	frames.clear()
	queue_redraw()


## Autopilot hint: out of a pending stamp square or hurl landing at `p`.
func danger_push(p: Vector2) -> Vector2:
	var push := Vector2.ZERO
	var h := float(def["stamp_size"]) * 0.5 + 16.0  # Square half-side plus a margin (px).
	for s in stamps:
		var off := p - Vector2(s.x, s.y)
		if absf(off.x) < h and absf(off.y) < h:
			push += (Vector2(signf(off.x), 0.0) if absf(off.x) > absf(off.y) else Vector2(0.0, signf(off.y) if off.y != 0.0 else 1.0)) * 1.2
	var r := float(def["hurl_radius"]) + 18.0
	for l in landings:
		var off := p - Vector2(l.x, l.y)
		if off.length() < r:
			push += (off.normalized() if off.length() > 0.1 else Vector2.RIGHT) * (1.0 - off.length() / r) * 1.5
	return push


func _draw() -> void:
	if game == null:
		return
	var t := game.elapsed
	var tele := maxf(0.01, float(def["stamp_telegraph"]))
	for s in stamps:
		AssemblyGlyphs.draw_stamp(self, Vector2(s.x, s.y), float(def["stamp_size"]), clampf(1.0 - (s.z - t) / tele, 0.0, 1.0))
	var fl := maxf(0.01, float(def["hurl_flight"]))
	var r := float(def["hurl_radius"])
	for l in landings:
		var c := Vector2(l.x, l.y)
		var k := clampf(1.0 - (l.z - t) / fl, 0.0, 1.0)
		if EmpireFx.telegraph_circle(self, c, r, k):
			continue  # The Empire's warning circle (GDD §15.0 "Act III AoE art").
		draw_circle(c, r * k, Color(Palette.EMPIRE_SIGNAL_RED, 0.16 + 0.14 * k))
		draw_arc(c, r, 0.0, TAU, 32, Color(Palette.EMPIRE_SIGNAL_RED, 0.85), 2.0)
		draw_line(c - Vector2(r * 0.3, 0), c + Vector2(r * 0.3, 0), Color(Palette.EMPIRE_SIGNAL_GLOW, 0.8), 1.0)
		draw_line(c - Vector2(0, r * 0.3), c + Vector2(0, r * 0.3), Color(Palette.EMPIRE_SIGNAL_GLOW, 0.8), 1.0)
	var bt := maxf(0.01, float(def["build_telegraph"]))
	for f in frames:
		var c := Vector2(f.x, f.y)
		var k := clampf(1.0 - (f.z - t) / bt, 0.0, 1.0)
		var side := 26.0  # Frame side (px).
		if EmpireFx.build_frame(self, c, side, k):
			continue
		var sq := Rect2(c - Vector2(side, side) * 0.5, Vector2(side, side))
		draw_rect(sq, Color(Palette.EMPIRE_SIGNAL_AMBER, 0.08 + 0.15 * k))
		draw_rect(sq, Color(Palette.EMPIRE_SIGNAL_AMBER, 0.9), false, 2.0)
		draw_line(Vector2(sq.position.x, sq.end.y - side * k), Vector2(sq.end.x, sq.end.y - side * k), Color(Palette.EMPIRE_SIGNAL_GLOW, 0.9), 1.0)
