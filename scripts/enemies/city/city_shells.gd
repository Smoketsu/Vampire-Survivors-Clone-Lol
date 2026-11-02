## CityShells — every TELEGRAPHED LANDING CIRCLE of the Last Line (Act VIII;
## GDD §15.0 "Armour" and "Act VIII foundation (phase 1)"), owned by Game.city
## as `shells` (a child node, drawn on the ground). THE one path for a shell:
## add(at, delay, radius, dmg, source, both, stun) shows a ring that fills for
## `delay` s and then lands:
##   * a BLAST (stun 0): CityRules.blast(): `dmg` to every summon and
##     necromancer inside, and with `both` to every enemy inside except
##     civilians (the tank's cannon hurts only the dead's side; Martial Law's
##     artillery hurts both sides);
##   * a FLASHBANG (stun > 0, the SWAT breacher's): every summon inside is
##     stunned for `stun` s through CombatResolver.stun_unit() (the one summon
##     stun path; an enemy attack, not a summon rule), no damage.
## Shells are packed arrays (at most CityRulesData.SHELL_CAP pending: when
## full, the oldest lands at once). The autotest bot steps off a pending
## circle (danger_push()). Drawn: CityGlyphs.draw_shell() rings (textures);
## nothing drawn headless.
## Determinism: game time only; shells land in the order they were added.
class_name CityShells
extends Node2D

## Owning run.
var game: Game
## Landing point of each pending shell.
var _at: PackedVector2Array = PackedVector2Array()
## Game time (s) each was fired.
var _from: PackedFloat32Array = PackedFloat32Array()
## Game time (s) each lands.
var _land: PackedFloat32Array = PackedFloat32Array()
## Radius (px) of each.
var _radius: PackedFloat32Array = PackedFloat32Array()
## Damage of each (already scaled; 0 for a flashbang).
var _dmg: PackedFloat32Array = PackedFloat32Array()
## Stun (s) of each (0 = a blast).
var _stun: PackedFloat32Array = PackedFloat32Array()
## Damage tag of each.
var _source: PackedStringArray = PackedStringArray()
## 1 when each hurts both sides (enemies too), else 0.
var _both: PackedByteArray = PackedByteArray()
## True when this build draws (never headless).
var _draws: bool = false
## Scratch buffer for grid queries.
var _buf: Array = []


## Builds the shells for `p_game` (CityRules adds it as its child).
func _init(p_game: Game) -> void:
	game = p_game
	name = "CityShells"
	z_index = -4  # On the ground, over the floor and the buildings, under the bodies.
	_draws = DisplayServer.get_name() != "headless"


## THE SHELL PATH: a landing circle at `at` of `radius` px that lands after
## `delay` s: a blast of `dmg` tagged `source` (with `both`, enemies too), or,
## with `stun` > 0, a flashbang that stuns summons for `stun` s.
func add(at: Vector2, delay: float, radius: float, dmg: float, source: String, both: bool, stun: float = 0.0) -> void:
	if _at.size() >= CityRulesData.SHELL_CAP:
		_resolve(0)
		_remove(0)
	_at.append(at)
	_from.append(game.elapsed)
	_land.append(game.elapsed + delay)
	_radius.append(radius)
	_dmg.append(dmg)
	_stun.append(stun)
	_source.append(source)
	_both.append(1 if both else 0)
	game.stat_add("city_shells", 1.0)
	game.stat_add("city_shells_" + source, 1.0)


## Per-tick update (CityRules.step()): every due shell lands, in order.
func step(_delta: float) -> void:
	var now := game.elapsed
	var i := 0
	while i < _at.size():
		if now >= _land[i]:
			_resolve(i)
			_remove(i)
		else:
			i += 1
	if _draws:
		queue_redraw()


## Shell `i` lands.
func _resolve(i: int) -> void:
	var at := _at[i]
	var r := _radius[i]
	if _stun[i] > 0.0:
		game.ally_grid.query(at, r + UnitData.MAX_BLOCK_RADIUS + 8.0, _buf)
		for u: SummonedUnit in _buf.duplicate():
			if u.active and u.state != SummonedUnit.State.DEAD and u.position.distance_to(at) <= r + u.radius:
				game.combat.stun_unit(u, _stun[i], _source[i])
		game.effects.ring(at, r, Color.WHITE, 0.3)
		return
	game.city.blast(at, r, _dmg[i], _source[i], _both[i] == 1)
	game.effects.impact(at, r, Palette.CITY_HERO_ORANGE, "")
	game.city.play_sound("vehicle_wreck", at, 0.15)


## Drops shell `i`.
func _remove(i: int) -> void:
	_at.remove_at(i)
	_from.remove_at(i)
	_land.remove_at(i)
	_radius.remove_at(i)
	_dmg.remove_at(i)
	_stun.remove_at(i)
	_source.remove_at(i)
	_both.remove_at(i)


## The autotest autopilot's push out of every pending circle containing `p`
## (stronger the deeper and the nearer the landing).
func danger_push(p: Vector2) -> Vector2:
	var out := Vector2.ZERO
	for i in _at.size():
		var d := p - _at[i]
		var reach := _radius[i] + 14.0  # The circle and a body's margin (px).
		var dist := d.length()
		if dist < reach:
			out += (d / dist if dist > 0.5 else Vector2.RIGHT) * (1.0 - dist / reach)
	return out


func _draw() -> void:
	var now := game.elapsed
	for i in _at.size():
		var span := maxf(_land[i] - _from[i], 0.01)
		var col := Color.WHITE if _stun[i] > 0.0 else (Palette.CITY_SIREN_RED if _both[i] == 1 else Palette.CITY_HAZARD)
		CityGlyphs.draw_shell(self, _at[i], _radius[i], (now - _from[i]) / span, col)
