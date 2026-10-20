## CovenantRites — run-wide bookkeeping for the Covenant kits
## (SanctumEnemyData), owned by EnemyDirector (`game.enemies.rites`) and
## stepped by it once per tick, drawn in world space under the bodies:
##   * the recent-deaths ring buffer High Confessors raise soldiers from:
##     every kill of an ordinary soldier (not elite, structure, construct,
##     boss, miniboss, objective, Reckoning, or already raised once) records
##     its kind, position and time; no instance ids (CLAUDE.md determinism);
##   * pending revivals: a gold pillar for revive_telegraph s at the death
##     spot, tied to its Confessor (Enemy + generation). The Confessor's
##     death (or recycling) cancels it; while the Confessor is frozen it
##     pauses; when it completes, the soldier rises there through the normal
##     spawn path (HARD_CAP respected) with revive_hp_fraction of its HP and
##     no XP (no farming);
##   * the living enemies that own a CovenantKit, for the autotest
##     autopilot's danger hints (danger_push(); zero when there are none);
##   * the kill hook (on_enemy_killed): CovenantKit.on_killed, then the
##     death record (also read, never claimed, by death_near(): the Sister
##     of the Scourge's zeal).
## Stats: confessor_revives_started, confessor_revives,
## confessor_revives_cancelled, confessor_revives_capped, revived_killed.
class_name CovenantRites
extends Node2D

## One recorded death.
class Death:
	extends RefCounted
	## Enemy kind id of the fallen soldier ("" = empty slot).
	var kind: String = ""
	## World position where it fell.
	var pos: Vector2 = Vector2.ZERO
	## Game time (s) it fell.
	var time: float = 0.0
	## True once a Confessor claimed it (raised or being raised).
	var used: bool = true

## One revival in progress (a gold pillar).
class Revive:
	extends RefCounted
	## Where the soldier rises.
	var pos: Vector2 = Vector2.ZERO
	## Enemy kind id to raise.
	var kind: String = ""
	## Seconds left of the telegraph.
	var left: float = 1.5
	## Total telegraph length (s, for the drawing).
	var total: float = 1.5
	## HP fraction (0..1) the soldier comes back with.
	var hp_fraction: float = 0.6
	## The Confessor channelling it.
	var owner_enemy: Enemy = null
	## Generation of `owner_enemy` when it started (stale guard).
	var owner_gen: int = 0

## Owning run.
var game: Game
## Recent deaths (fixed-size ring of SanctumEnemyData.DEATH_BUFFER_SIZE).
var _deaths: Array[Death] = []
## Index of the ring slot the next death overwrites.
var _next: int = 0
## Revivals in progress.
var revives: Array[Revive] = []
## Living enemies that own a CovenantKit (danger hints).
var kit_enemies: Array[Enemy] = []
## True if something was drawn last frame (one final redraw clears it).
var _drew: bool = false


func _ready() -> void:
	z_index = -6
	for _i in SanctumEnemyData.DEATH_BUFFER_SIZE:
		_deaths.append(Death.new())


## An enemy with a kit entered the field (CovenantKit owners).
func register(e: Enemy) -> void:
	if not kit_enemies.has(e):
		kit_enemies.append(e)


## An enemy with a kit left the field.
func unregister(e: Enemy) -> void:
	kit_enemies.erase(e)


## Kill hook (EnemyDirector.on_enemy_killed, before the enemy is pooled):
## the kit's death action, then the death record.
func on_enemy_killed(e: Enemy) -> void:
	if e.kit != null:
		e.kit.on_killed(e)
	if e.is_revived:
		game.stat_add("revived_killed", 1.0)  # A raised soldier fell again.
	if e.is_elite or e.is_structure or e.is_construct or e.is_boss or e.is_miniboss \
			or e.is_objective or e.is_reckoning or e.is_revived:
		return
	var rec := _deaths[_next]
	_next = (_next + 1) % _deaths.size()
	rec.kind = e.kind
	rec.pos = e.position
	rec.time = game.elapsed
	rec.used = false


## True if an ordinary soldier (one the ring records) fell within `radius`
## px of `pos` after game time `since` (s). Read-only: a Sister of the
## Scourge's zeal (BattleSisterKit) never claims the death, so a Confessor
## can still raise it.
func death_near(pos: Vector2, radius: float, since: float) -> bool:
	for rec in _deaths:
		if rec.kind != "" and rec.time > since and rec.pos.distance_to(pos) <= radius:
			return true
	return false


## True while Confessor `owner` channels a revival.
func has_pending(owner: Enemy) -> bool:
	for r in revives:
		if r.owner_enemy == owner and r.owner_gen == owner.generation:
			return true
	return false


## Confessor `owner` tries to raise the most recent unclaimed soldier that
## fell within `radius` px of it in the last `max_age` s: a gold pillar for
## `telegraph` s, then it rises with `hp_fraction` of its HP. Returns false
## when there is nobody to raise.
func start_revive(owner: Enemy, radius: float, max_age: float, telegraph: float, hp_fraction: float) -> bool:
	var best: Death = null  # Newest eligible death.
	for rec in _deaths:
		if rec.used or game.elapsed - rec.time > max_age or rec.pos.distance_to(owner.position) > radius:
			continue
		if best == null or rec.time > best.time:
			best = rec
	if best == null:
		return false
	best.used = true
	var r := Revive.new()
	r.pos = best.pos
	r.kind = best.kind
	r.total = maxf(0.05, telegraph)
	r.left = r.total
	r.hp_fraction = hp_fraction
	r.owner_enemy = owner
	r.owner_gen = owner.generation
	revives.append(r)
	owner.queue_redraw()
	game.effects.beam(owner.position, r.pos, Palette.GOLD)
	Sfx.play("summon_rise", r.pos, 1.6)
	game.stat_add("confessor_revives_started", 1.0)
	return true


## Advances the pillars: cancelled by the Confessor's death, paused while it
## is frozen, the soldier rises when one completes.
func step(delta: float) -> void:
	var i := 0
	while i < revives.size():
		var r := revives[i]
		var o := r.owner_enemy
		if not o.active or o.generation != r.owner_gen:
			game.stat_add("confessor_revives_cancelled", 1.0)
			game.effects.pop(r.pos, Palette.GOLD, 16.0)
			revives.remove_at(i)
			continue
		if not o.frozen:
			r.left -= delta
		if r.left <= 0.0:
			_raise(r)
			o.queue_redraw()
			revives.remove_at(i)
			continue
		i += 1
	var busy := not revives.is_empty()
	if busy or _drew:
		queue_redraw()
	_drew = busy


## The soldier of revival `r` rises (unless the enemy hard cap is full).
func _raise(r: Revive) -> void:
	var ed := game.enemies
	if ed.regular_alive() >= ed.hard_cap():
		game.stat_add("confessor_revives_capped", 1.0)
		return
	var e := ed.spawn_at(r.kind, r.pos, false)
	e.hp = e.max_hp * clampf(r.hp_fraction, 0.05, 1.0)
	e.xp_value = 0  # Raised once already: no second XP drop.
	e.is_revived = true
	e.queue_redraw()
	game.effects.ring(e.position, 34.0, Palette.GOLD, 0.45)
	game.effects.spawn_ring(e.position, Palette.GOLD)
	game.stat_add("confessor_revives", 1.0)


## Autopilot hint: the sum of every live kit telegraph's push at `p`.
func danger_push(p: Vector2) -> Vector2:
	var push := Vector2.ZERO
	for e in kit_enemies:
		if e.active and e.kit != null:
			push += e.kit.danger_push(e, p)
	return push


func _draw() -> void:
	for r in revives:
		SanctumGlyphs.draw_revive_pillar(self, r.pos, 1.0 - r.left / r.total, game.elapsed)
