## SuppressionField — holy suppression of the undead army (GDD §7.3 "holy
## suppression zones apply localized, temporary pressure"; "boss suppression
## must allow normal replacement afterward"), owned by HordeDirector
## (`game.horde.suppression`) and reached through ONE call,
## HordeDirector.add_suppression(). The Radiant Inquisitor casts it
## (InquisitorKit: 160 px, 4 s, 1 s telegraph, owner-approved) and Grand
## Inquisitor Seraphine casts it with her own numbers (BossSeraphine: 220
## px, 5 s, 1.5 s telegraph, half minion damage).
## A zone first ARMS for its telegraph time (a gold warning ring that fills
## up, no effect yet), then for `duration` s:
##   * no summon replacement spawns inside it (HordeDirector._try_spawn);
##   * a (non-temporary) summon that dies inside it is HELD: its class
##     cannot replace it until the zone ends. Replacement then resumes
##     normally (the class timer was only paused, never reset; other deaths
##     of the class keep being replaced as usual);
##   * minion attacks on an enemy standing inside it deal `damage_mult` of
##     their damage (CombatResolver.damage_enemy(); 1 = no change, the
##     Inquisitor's; Seraphine's halves it). The enemy's position is used
##     because damage has no attacker position; melee summons fight inside
##     the zone with their target, archers shooting into it are cut too.
## Nothing here uses RNG. Drawn in world space under the bodies.
## Stats: suppression_zones_<source>, suppression_replacements_delayed
## (deaths held), suppression_released (held deaths freed),
## suppression_paused_seconds (class-seconds of paused replacement),
## suppression_spawns_blocked (replacement spawn spots rejected),
## suppression_dmg_prevented (CombatResolver).
class_name SuppressionField
extends Node2D

## One suppression zone.
class Zone:
	extends RefCounted
	## World-space centre.
	var pos: Vector2 = Vector2.ZERO
	## Radius in px.
	var radius: float = 160.0
	## Seconds left of the telegraph (> 0 = arming, no effect yet).
	var arm_left: float = 0.0
	## Total telegraph time (s, for the drawing).
	var arm_total: float = 1.0
	## Seconds left once armed.
	var life: float = 4.0
	## Total armed lifetime (s, for the drawing).
	var life_total: float = 4.0
	## Multiplier (0..1) on minion damage to enemies inside (1 = none).
	var damage_mult: float = 1.0
	## Who cast it ("inquisitor", "seraphine"...; stats only).
	var source: String = ""

## One summon death held by a zone (its replacement waits).
class Hold:
	extends RefCounted
	## Summon class id of the fallen unit.
	var cls: String = ""
	## Game time (s) at which its replacement may resume.
	var until: float = 0.0

## Owning run.
var game: Game
## Arming and armed zones.
var zones: Array[Zone] = []
## Deaths held until their zone ends.
var holds: Array[Hold] = []
## Number of ARMED zones right now (0 = every check is skipped).
var active_count: int = 0
## True if something was drawn last frame (one final redraw clears it).
var _drew: bool = false


func _ready() -> void:
	z_index = -6


## Adds a zone at `pos` (`radius` px) that arms for `telegraph` s and then
## suppresses for `duration` s, with minion damage to enemies inside x
## `damage_mult`. `source` tags it for the stats.
func add(pos: Vector2, radius: float, duration: float, damage_mult: float, telegraph: float, source: String) -> void:
	var z := Zone.new()
	z.pos = pos
	z.radius = radius
	z.arm_total = maxf(0.0, telegraph)
	z.arm_left = z.arm_total
	z.life_total = maxf(0.05, duration)
	z.life = z.life_total
	z.damage_mult = clampf(damage_mult, 0.0, 1.0)
	z.source = source
	zones.append(z)
	game.stat_add("suppression_zones_" + source, 1.0)
	if z.arm_left <= 0.0:
		_on_armed(z)


## Per-tick update (HordeDirector.step, before replenishment): arms and ages
## zones, frees held deaths whose zone ended.
func step(delta: float) -> void:
	if zones.is_empty() and holds.is_empty() and not _drew:
		return
	var i := 0
	active_count = 0
	while i < zones.size():
		var z := zones[i]
		if z.arm_left > 0.0:
			z.arm_left -= delta
			if z.arm_left <= 0.0:
				_on_armed(z)
		else:
			z.life -= delta
		if z.life <= 0.0:
			zones.remove_at(i)
			continue
		if z.arm_left <= 0.0:
			active_count += 1
		i += 1
	var now := game.elapsed
	var h := 0
	while h < holds.size():
		if holds[h].until <= now:
			holds.remove_at(h)
			game.stat_add("suppression_released", 1.0)
		else:
			h += 1
	var busy := not zones.is_empty()
	if busy or _drew:
		queue_redraw()
	_drew = busy


## A zone finished its telegraph.
func _on_armed(z: Zone) -> void:
	game.effects.ring(z.pos, z.radius, Palette.IVORY, 0.35)


## True if `pos` lies inside an armed zone (no replacement spawns there).
func blocks(pos: Vector2) -> bool:
	if active_count <= 0:
		return false
	for z in zones:
		if z.arm_left <= 0.0 and pos.distance_to(z.pos) <= z.radius:
			game.stat_add("suppression_spawns_blocked", 1.0)
			return true
	return false


## Death hook (HordeDirector.on_unit_died, non-temporary deaths): a summon
## that dies inside an armed zone is held until the latest such zone ends.
func on_unit_died(u: SummonedUnit) -> void:
	if active_count <= 0:
		return
	var until := -1.0  # Latest end time of a zone holding this death.
	for z in zones:
		if z.arm_left <= 0.0 and u.position.distance_to(z.pos) <= z.radius:
			until = maxf(until, game.elapsed + z.life)
	if until < 0.0:
		return
	var hold := Hold.new()
	hold.cls = u.unit_class
	hold.until = until
	holds.append(hold)
	game.stat_add("suppression_replacements_delayed", 1.0)


## Held deaths of class `cls` right now.
func held_count(cls: String) -> int:
	var n := 0
	for hold in holds:
		if hold.cls == cls:
			n += 1
	return n


## True when every missing unit of `cls` is held (`count` alive of `cap`):
## its replacement timer must pause this tick.
func holds_class(cls: String, count: int, cap: int) -> bool:
	if holds.is_empty():
		return false
	var held := held_count(cls)
	return held > 0 and count + held >= cap


## True while a zone cast by `source` is arming or armed (Seraphine casts
## one at a time).
func has_source(source: String) -> bool:
	for z in zones:
		if z.source == source:
			return true
	return false


## Multiplier on a minion attack against an enemy at `pos`: the lowest
## damage_mult of the armed zones containing it (1 = none).
func damage_mult_at(pos: Vector2) -> float:
	var m := 1.0
	for z in zones:
		if z.arm_left <= 0.0 and z.damage_mult < m and pos.distance_to(z.pos) <= z.radius:
			m = z.damage_mult
	return m


func _draw() -> void:
	var now := game.elapsed
	for z in zones:
		if z.arm_left > 0.0:
			SanctumGlyphs.draw_suppression(self, z.pos, z.radius, 1.0 - z.arm_left / maxf(0.01, z.arm_total), -1.0, now)
		else:
			SanctumGlyphs.draw_suppression(self, z.pos, z.radius, 1.0, clampf(z.life / maxf(0.01, z.life_total), 0.0, 1.0), now)
