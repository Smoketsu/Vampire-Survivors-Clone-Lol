## RiotCopKit — the kit of the Riot Cop (CityEnemyData "riot_cop"; Act VIII,
## GDD §15.0 "Act VIII foundation (phase 1)", "Armour" and "Tear gas (Act VIII
## phase 2)"): a police soldier with a riot shield and a baton, in a line. The
## shield is its FRONT (row "armour_front": Armour.front_mult(), the one path,
## reads the CityKit's facing, which points at the foe it fights): flank the
## line. TEAR GAS (Skid Row's piece of the police tier; owner-approved proposal:
## "tear gas that slows summons"): every gas_every s, with a summon within
## gas_range px, it lobs a canister at the nearest one; the canister flies
## gas_flight s, then a cloud of gas_radius px hangs where it landed for
## gas_time s, and every summon in it is slowed by gas_slow through
## TerrainSlow.slow_summon() (the one ground-slow path, so Brinewalker helps;
## refreshed gas_linger s every gas_tick s): an enemy effect on units, never a
## summon rule. No damage, and never the necromancer. Each cop keeps at most
## one cloud (its cooldown outlasts the cloud), and a cop's cloud clears when
## the cop leaves the field (own decision: the kit owns its cloud, so no second
## system steps it). Drawn: soft grey-green discs (textures; the cop redraws each
## tick while its cloud lives, so the cloud stays put while the cop walks).
## Determinism: no RNG (the first canister staggered by the think slot).
## Stats: riot_gas_thrown, riot_gas_slows.
class_name RiotCopKit
extends CityKit

## Seconds until its next canister.
var _gas_cd: float = 0.0
## Where its cloud is (world px; meaningful while _gas_until > now).
var _gas_at: Vector2 = Vector2.ZERO
## Game time (s) the canister lands (the cloud starts; INF = none thrown).
var _gas_from: float = INF
## Game time (s) the cloud clears (0 = none).
var _gas_until: float = 0.0
## Seconds toward the next slow refresh.
var _gas_acc: float = 0.0
## True once this cloud's landing sound played.
var _gas_landed: bool = false
## True while the cloud (or the canister) was drawn at the last tick (one more
## redraw clears it).
var _gas_drawn: bool = false
## Scratch buffer for grid queries.
var _buf: Array = []


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	_gas_cd = first_cd(e, float(d.get("gas_every", 14.0)) * 0.4)
	_gas_from = INF
	_gas_until = 0.0
	_gas_acc = 0.0
	_gas_landed = false
	_gas_drawn = false


func on_deactivate(e: Enemy) -> void:
	super.on_deactivate(e)
	_gas_until = 0.0  # Its cloud clears with it.
	_gas_from = INF


func physics(e: Enemy, delta: float) -> bool:
	var owned := super.physics(e, delta)
	var g := e.game
	var now := g.elapsed
	if now < _gas_until or _gas_drawn:
		_gas_drawn = now < _gas_until
		e.queue_redraw()  # The cloud is drawn in world axes from the moving cop: redrawn each tick while it lives (and once after).
	if now < _gas_until:
		if now >= _gas_from:
			if not _gas_landed:
				_gas_landed = true
				rules(e).play_sound("gas_hiss", _gas_at, 0.4)  # The canister lands.
			_gas_acc += delta
			if _gas_acc >= float(d.get("gas_tick", 0.25)):
				_gas_acc = 0.0
				_slow_in_cloud(e)
	_gas_cd -= delta
	if _gas_cd > 0.0 or not d.has("gas_every"):
		return owned
	var reach := float(d.get("gas_range", 200.0))
	var best: SummonedUnit = null
	var best_d := INF
	g.ally_grid.query(e.position, reach, _buf)
	for u: SummonedUnit in _buf:
		if u.active and u.state != SummonedUnit.State.DEAD and not u.airborne:
			var dist := u.position.distance_to(e.position)
			if dist < best_d:
				best_d = dist
				best = u
	if best == null:
		_gas_cd = 0.5  # Nobody in reach: look again shortly.
		return owned
	_gas_cd = float(d.get("gas_every", 14.0))
	_gas_at = best.position
	_gas_from = now + float(d.get("gas_flight", 0.6))
	_gas_until = _gas_from + float(d.get("gas_time", 4.0))
	_gas_acc = 0.0
	_gas_landed = false
	g.stat_add("riot_gas_thrown", 1.0)
	return owned


## Slows every summon on the ground inside the cloud (TerrainSlow, the one
## ground-slow path).
func _slow_in_cloud(e: Enemy) -> void:
	var g := e.game
	var r := float(d.get("gas_radius", 44.0))
	g.ally_grid.query(_gas_at, r + UnitData.MAX_BLOCK_RADIUS, _buf)
	for u: SummonedUnit in _buf:
		if not u.active or u.state == SummonedUnit.State.DEAD or u.airborne:
			continue
		if u.position.distance_to(_gas_at) <= r + u.radius:
			if TerrainSlow.slow_summon(g, u, float(d.get("gas_slow", 0.35)), float(d.get("gas_linger", 0.5))) > 0.0:
				g.stat_add("riot_gas_slows", 1.0)


## Its tear-gas cloud (soft grey-green discs, thinning as it clears) or the
## canister in flight (a small dark disc on its arc).
func draw_under(e: Enemy) -> void:
	super.draw_under(e)
	var now := e.game.elapsed
	if now >= _gas_until:
		return
	e.draw_set_transform_matrix(CourtGlyphs.unmirror_xf(e))
	var rel := _gas_at - e.position  # The cloud, from the cop (world axes).
	if now < _gas_from:
		var span := maxf(float(d.get("gas_flight", 0.6)), 0.01)
		var k := clampf(1.0 - (_gas_from - now) / span, 0.0, 1.0)
		var p := rel * k + Vector2(0.0, -40.0 * 4.0 * k * (1.0 - k))  # The canister's arc.
		SpriteBank.draw_disc(e, p, 3.0, Color(0.3, 0.32, 0.28, 0.9))
	else:
		var left := clampf((_gas_until - now) / maxf(float(d.get("gas_time", 4.0)), 0.01), 0.0, 1.0)
		var r := float(d.get("gas_radius", 44.0))
		var a := 0.32 * minf(1.0, left * 3.0)  # Fades over its last third.
		var col := Color(0.62, 0.68, 0.56, a)  # Grey-green gas.
		SpriteBank.draw_disc(e, rel, r, col)
		SpriteBank.draw_disc(e, rel + Vector2(-r * 0.35, -r * 0.2), r * 0.6, Color(col, a * 0.8))
		SpriteBank.draw_disc(e, rel + Vector2(r * 0.4, r * 0.15), r * 0.55, Color(col, a * 0.8))
	e.draw_set_transform_matrix(Transform2D.IDENTITY)
