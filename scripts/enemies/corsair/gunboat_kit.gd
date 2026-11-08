## GunboatKit — the kit of the Gunboat (CorsairEnemyData "gunboat"; Act X, the
## Black Tide, the Treasure Galleon's block; GDD §15.0 "The Treasure Galleon
## (Act X phase 2)"; owner-approved proposal: "Never boards; shells the deck in
## lines from range | Cannons, fliers, ranged"). A STRUCTURE in the water that
## never boards:
##   * LAUNCH (launch(), the one way a gunboat comes): CorsairRules
##     .route_spawn() hands it every timeline spawn of a "gunboat" row, and the
##     Black Tide brings one every "gunboat_every" s. It comes alongside a
##     seeded point of the straight rail, its hull over the rail line like a
##     boarding boat's (so a summon at the rail, ranged summons, spells and
##     the deck cannons reach it); at most shell "cap" alive (shell "tide_cap"
##     during the Black Tide); refused past it (counted).
##   * THE SHELLING: every shell "every" s (first after shell "first") it
##     shows shell "lines" lanes straight across the deck from its rail (shell
##     "telegraph" s, EffectManager.telegraph_line() owned by it), spread
##     shell "spread" px apart (+- shell "jitter", seeded) around the nearest
##     necromancer's x; then the shells land along each lane: every summon and
##     necromancer in it takes shell dmg_summon / dmg_player x the time
##     scaling (OlympusHits.lane(), once per lane). Enemies are not hit (the
##     Brotherhood's own gunners). Killed before the telegraph ends, it fires
##     nothing.
##   * After shell "stay" s it casts off (drifts out and is despawned).
## Off Act X (no deck) it is an inert structure where it was spawned.
## Barnacle Bones applies (CorsairKit.taken_mult(): it lies in the water).
## Determinism: the seeded gameplay RNG only (rail point, side, jitter).
## Stats: gunboats_launched, gunboats_refused, gunboat_volleys,
## gunboat_lane_hits, gunboats_sunk, gunboats_left.
class_name GunboatKit
extends CorsairKit

## px the autotest bot keeps from a lane's edge.
const DANGER_MARGIN: float = 16.0  # TUNING (not in GDD) autotest hint only
## Kind id of the gunboat.
const KIND: String = "gunboat"

## Its rail's outward normal (from the deck to the sea).
var _n: Vector2 = Vector2.UP
## Seconds until its next volley's telegraph.
var _shell_cd: float = 0.0
## Game time (s) the current volley lands (-1 = none telegraphed).
var _land_t: float = -1.0
## The current volley's lanes: each [from (on its rail), unit dir across the deck, length].
var _lanes: Array = []
## Game time (s) it came alongside.
var _since: float = 0.0
## True once it cast off (drifting out).
var _leaving: bool = false
## Scratch query buffer.
var _buf: Array = []


## Brings one gunboat alongside (see the header); null when refused or off Act X.
static func launch(game: Game, hp_scale: float, dmg_scale: float, reckoning: bool) -> Enemy:
	var row := game.enemies.enemy_def(KIND)
	var shell: Dictionary = row.get("shell", {})
	var tide := game.corsair != null and game.corsair.tide.running()
	var cap := int(shell.get("tide_cap", 3)) if tide else int(shell.get("cap", 2))
	if alive(game) >= cap or game.deck == null:
		game.stat_add("gunboats_refused", 1.0)
		return null
	var deck := game.deck
	var side := 1 if randf() < 0.5 else -1
	var x := (randf() - 0.5) * deck.straight_rail_length() * 0.85
	var rail := deck.rail_point(x, side)
	var n := Vector2(0.0, float(side))
	var e := game.enemies.spawn_routed(KIND, rail, hp_scale, false)
	e.position = rail + n * float(row["radius"]) * 0.6  # In the water, its hull over the rail line.
	if dmg_scale != 1.0:
		e.damage *= dmg_scale
	if reckoning:
		e.is_reckoning = true
	if e.kit is GunboatKit:
		(e.kit as GunboatKit)._n = n
	game.stat_add("gunboats_launched", 1.0)
	if game.corsair != null:
		game.corsair.play_sound("cannon_fire", e.position, 0.5)
	return e


## Gunboats afloat now.
static func alive(game: Game) -> int:
	var n := 0
	for e in game.enemies.active:
		if e.active and e.kind == KIND:
			n += 1
	return n


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	_n = Vector2.UP
	_shell_cd = float((d.get("shell", {}) as Dictionary).get("first", 3.0)) + float(e.think_slot) * SLOT_STAGGER
	_land_t = -1.0
	_lanes.clear()
	_since = e.game.elapsed
	_leaving = false


func on_deactivate(e: Enemy) -> void:
	_lanes.clear()
	_land_t = -1.0
	super.on_deactivate(e)


func on_killed(e: Enemy) -> void:
	super.on_killed(e)
	e.game.stat_add("gunboats_sunk", 1.0)
	e.game.effects.ring(e.position, e.radius * 1.4, Palette.CORSAIR_FOAM, 0.45)
	if e.game.corsair != null:
		e.game.corsair.play_sound("hull_creak", e.position, 0.2)


func physics(e: Enemy, delta: float) -> bool:
	if in_water and e.game.deck != null:
		_step_gunboat(e, delta)
	return super.physics(e, delta)


## Its shelling and its leaving (in the water on a deck stage).
func _step_gunboat(e: Enemy, delta: float) -> void:
	var g := e.game
	var sh: Dictionary = d.get("shell", {})
	if _leaving:
		e.position += _n * 34.0 * delta
		if g.elapsed - _since >= float(sh.get("stay", 75.0)) + 2.5:
			g.stat_add("gunboats_left", 1.0)
			g.enemies.despawn(e)
		return
	if _land_t >= 0.0 and g.elapsed >= _land_t:
		_shell(e, sh)
	if g.elapsed - _since >= float(sh.get("stay", 75.0)) and _land_t < 0.0:
		_leaving = true
		return
	_shell_cd -= delta
	if _shell_cd <= 0.0 and _land_t < 0.0:
		_shell_cd = float(sh.get("every", 7.5))
		_aim(e, sh)


## The volley's lanes, across the deck at the nearest necromancer (telegraphed).
func _aim(e: Enemy, sh: Dictionary) -> void:
	var g := e.game
	if g.ultimates.player_untargetable():
		return
	var pl := g.nearest_player(e.position)
	var deck := g.deck
	var lines := int(sh.get("lines", 2))
	var length := deck.half_beam * 2.0
	var dir := -_n  # From its rail across the deck.
	_lanes.clear()
	for i in lines:
		var x := pl.position.x + (float(i) - float(lines - 1) * 0.5) * float(sh.get("spread", 120.0)) + (randf() * 2.0 - 1.0) * float(sh.get("jitter", 30.0))
		var from := Vector2(x, deck.center.y + deck.half_beam * _n.y)
		_lanes.append([from, dir, length])
		g.effects.telegraph_line(from, from + dir * length, float(sh.get("width", 34.0)), float(sh.get("telegraph", 1.4)), e)
	_land_t = g.elapsed + float(sh.get("telegraph", 1.4))
	g.stat_add("gunboat_volleys", 1.0)
	if g.corsair != null:
		g.corsair.play_sound("cannon_fire", e.position, 0.4)


## The shells land along every lane (the army only).
func _shell(e: Enemy, sh: Dictionary) -> void:
	var g := e.game
	_land_t = -1.0
	var s := hit_scale(e)
	for ln: Array in _lanes:
		var from: Vector2 = ln[0]
		var dir: Vector2 = ln[1]
		var length := float(ln[2])
		var hits := OlympusHits.lane(g, from, dir, length, float(sh.get("width", 34.0)), float(sh.get("dmg_player", 8.0)) * s,
				float(sh.get("dmg_summon", 10.0)) * s, e.kind, e, {}, _buf)
		g.stat_add("gunboat_lane_hits", float(hits))
		for k in 3:
			g.effects.impact(from + dir * length * (0.2 + 0.3 * float(k)), 18.0, Palette.CORSAIR_LANTERN)
	_lanes.clear()
	if g.corsair != null:
		g.corsair.play_sound("cannon_hit", e.position, 0.3)


## Autotest hint: sideways out of a telegraphed lane.
func danger_push(e: Enemy, p: Vector2) -> Vector2:
	if _land_t < 0.0:
		return Vector2.ZERO
	var half := float((d.get("shell", {}) as Dictionary).get("width", 34.0)) * 0.5 + DANGER_MARGIN + e.game.player.radius
	var push := Vector2.ZERO
	for ln: Array in _lanes:
		var dx := p.x - (ln[0] as Vector2).x
		if absf(dx) < half:
			push.x += (signf(dx) if absf(dx) > 0.5 else 1.0) * (1.0 - absf(dx) / half) * 2.2
	return push
