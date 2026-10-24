## Phalanx — the PHALANX rule of the Olympian Republic (Act IV; GDD §15.0
## "Phalanx"), owned by PantheonRules (`Game.pantheon.phalanx`). Numbers in
## PantheonRulesData.PHALANX.
##   * LOCK: every check_every s, the "phalanx" kinds (PantheonKit with row
##     "phalanx") that are not paused by a break are linked when two stand
##     within lock_range px of each other (centres) and face the same way
##     (facings within facing_half_angle); every linked group of lock_count or
##     more is a locked WALL (union-find over the enemy spatial hash; no RNG, no
##     instance ids: each member's PantheonKit.idx is its index this check).
##   * ONE PACE: a locked wall advances as one: every member's move speed is the
##     slowest member's free speed (PantheonKit.free_speed, restored when it
##     leaves the wall). Its members still advance on the necromancer (enemies
##     always advance).
##   * THE FRONT: directed_hit_mult(), asked once by CombatResolver
##     .damage_enemy() for a hit with an origin (PantheonRules
##     .directed_hit_mult()): on a LOCKED member, a hit from the front
##     (PantheonRules.hit_from_front(), the one direction test) causes no
##     knockback and, for a PROJECTILE (arrows, bolts, volley shots, spears),
##     deals only front_shot_mult; a melee hit from the front deals full damage.
##     Bronze Breaker (counter-passive, not built: breaker_mult(), the one read)
##     raises summon hits on a locked front.
##   * THE FLANK: a directed hit from the side or behind deals full damage and
##     BREAKS the wall: every member unlocks and cannot lock again for
##     break_time s.
##   * Hits with no origin (area spells, stomps, dives, arcing boulders, mage
##     orbs bursting where they land, beams, damage over time) ignore the front.
##   * DRAWING: a bronze shield line across the front of every locked member,
##     so a wall reads as one bronze bar (above the units).
## Stats: phalanx_walls_formed, phalanx_members_locked, phalanx_front_shots,
## phalanx_front_melee, phalanx_front_dmg_prevented, phalanx_flank_breaks,
## phalanx_peak_locked.
class_name Phalanx
extends Node2D

## Owning run.
var game: Game
## Game time (s) of the next lock check.
var _next_check: float = 0.0
## The members locked at the last check (drawn; stale guard: _locked_gen).
var _locked: Array[Enemy] = []
## Generation of each _locked member when it locked.
var _locked_gen: PackedInt32Array = PackedInt32Array()
## Most bodies locked at once this run.
var peak_locked: int = 0
## Union-find parents of the current check (scratch).
var _parent: PackedInt32Array = PackedInt32Array()
## Members of the current check (scratch).
var _members: Array[Enemy] = []
## Reusable spatial-hash query buffer.
var _tmp: Array = []
## True if the last redraw showed shield lines (one more redraw clears them).
var _drawn: bool = false


## Builds the rule for `p_game` (PantheonRules adds it as a child).
func _init(p_game: Game) -> void:
	game = p_game
	name = "Phalanx"
	z_index = 2  # The shield lines above the units.


## Per-tick update: the lock check on its rhythm, the redraw of the lines.
func step(_delta: float) -> void:
	if game.elapsed >= _next_check:
		_next_check = game.elapsed + float(PantheonRulesData.PHALANX["check_every"])
		_check()
	if not _locked.is_empty() or _drawn:
		queue_redraw()
	_drawn = not _locked.is_empty()


## Finds the walls (see the header), sets every member's lock, wall id and pace.
func _check() -> void:
	var cfg := PantheonRulesData.PHALANX
	var t := game.elapsed  # Game time (s).
	_members.clear()
	for e in game.enemies.active:
		if not e.active or not (e.kit is PantheonKit):
			continue
		var k := e.kit as PantheonKit
		k.idx = -1
		if not k.is_phalanx():
			continue
		if k.free_speed < 0.0:
			k.free_speed = e.move_speed  # Not stepped yet: its own pace now.
		if k.broken_until > t or e.frozen:
			if k.locked:
				_unlock(e, k)
			continue
		k.idx = _members.size()
		_members.append(e)
	var n := _members.size()
	_parent.resize(n)
	for i in n:
		_parent[i] = i
	var reach := float(cfg["lock_range"])  # Shoulder-to-shoulder distance (px).
	var same := cos(float(cfg["facing_half_angle"]))  # Least facing dot of "the same way".
	for i in n:
		var a := _members[i]
		var ka := a.kit as PantheonKit
		game.enemy_grid.query(a.position, reach, _tmp)
		for o: Enemy in _tmp:
			if o == a or not o.active or not (o.kit is PantheonKit):
				continue
			var kb := o.kit as PantheonKit
			if kb.idx < 0 or kb.idx <= i:
				continue  # Not a member, or the pair is seen from the other side.
			if a.position.distance_to(o.position) > reach or ka.facing.dot(kb.facing) < same:
				continue
			_union(i, kb.idx)
	# Group sizes and slowest free pace per root.
	var size := PackedInt32Array()
	size.resize(n)
	size.fill(0)
	var pace := PackedFloat32Array()
	pace.resize(n)
	pace.fill(INF)
	var had_lock := PackedByteArray()  # Per root: a member was already locked (not a new wall).
	had_lock.resize(n)
	had_lock.fill(0)
	for i in n:
		var r := _find(i)
		size[r] += 1
		var k := _members[i].kit as PantheonKit
		pace[r] = minf(pace[r], k.free_speed)
		if k.locked:
			had_lock[r] = 1
	var need := int(cfg["lock_count"])  # Bodies a wall needs.
	_locked.clear()
	_locked_gen.clear()
	var formed := PackedByteArray()  # Per root: a new wall was announced this check.
	formed.resize(n)
	formed.fill(0)
	for i in n:
		var e := _members[i]
		var k := e.kit as PantheonKit
		var r := _find(i)
		if size[r] >= need:
			if not k.locked:
				game.stat_add("phalanx_members_locked", 1.0)
				if had_lock[r] == 0 and formed[r] == 0:
					formed[r] = 1
					game.stat_add("phalanx_walls_formed", 1.0)
					game.pantheon.play_sound("shield_lock", e.position)
			k.locked = true
			k.wall = _members[r].generation * 4096 + r  # Unique per wall this check (generation-salted).
			e.move_speed = pace[r]  # One pace: the slowest member's.
			_locked.append(e)
			_locked_gen.append(e.generation)
		elif k.locked:
			_unlock(e, k)
	peak_locked = maxi(peak_locked, _locked.size())


## Unlocks member `e` (kit `k`): its own pace back, no wall.
func _unlock(e: Enemy, k: PantheonKit) -> void:
	k.locked = false
	k.wall = -1
	if k.free_speed >= 0.0:
		e.move_speed = k.free_speed


## Union-find root of `i` (path halving).
func _find(i: int) -> int:
	while _parent[i] != i:
		_parent[i] = _parent[_parent[i]]
		i = _parent[i]
	return i


## Joins the groups of `a` and `b` (the smaller index becomes the root, so the
## result does not depend on the query order).
func _union(a: int, b: int) -> void:
	var ra := _find(a)
	var rb := _find(b)
	if ra == rb:
		return
	if ra < rb:
		_parent[rb] = ra
	else:
		_parent[ra] = rb


## Bronze Breaker hook (counter-passive, NOT built): the multiplier on a summon
## hit on a locked front, 1 + PassiveData row BRONZE_BREAKER's value (exactly 1
## while no such passive exists). The one read of it.
func breaker_mult() -> float:
	return 1.0 + game.abilities.passive_value(PantheonRulesData.BRONZE_BREAKER, PantheonRulesData.BRONZE_BREAKER_KEY)


## Multiplier on a directed hit on Pantheon enemy `e` from `origin` (`shot`:
## a projectile; `source`: its tag) — see the header. 1 for an unlocked body.
func directed_hit_mult(e: Enemy, origin: Vector2, shot: bool, source: String) -> float:
	var k := e.kit as PantheonKit
	if not k.locked:
		return 1.0
	var cfg := PantheonRulesData.PHALANX
	if PantheonRules.hit_from_front(e, origin):
		e.knockback = Vector2.ZERO  # A locked shield takes no knockback from the front.
		var m := 1.0  # Share of the hit dealt.
		if shot:
			m = float(cfg["front_shot_mult"])
			game.stat_add("phalanx_front_shots", 1.0)
		else:
			game.stat_add("phalanx_front_melee", 1.0)
		if game.combat.is_minion_source(source):
			m *= breaker_mult()  # Bronze Breaker (exactly 1 while it does not exist).
		return m
	# From the side or behind: the wall breaks.
	_break_wall(k.wall)
	game.stat_add("phalanx_flank_breaks", 1.0)
	game.pantheon.play_sound("shield_break", e.position)
	game.effects.ring(e.position, e.radius * 1.6, Palette.PANTHEON_BRONZE_LIGHT, 0.25)
	return 1.0


## Unlocks every member of wall `wall_id` for break_time s.
func _break_wall(wall_id: int) -> void:
	var until := game.elapsed + float(PantheonRulesData.PHALANX["break_time"])  # Game time (s) they may lock again.
	for i in _locked.size():
		var e := _locked[i]
		if not e.active or e.generation != _locked_gen[i]:
			continue
		var k := e.kit as PantheonKit
		if k == null or k.wall != wall_id:
			continue
		k.broken_until = until
		_unlock(e, k)


## Number of bodies locked right now (the last check; the report and screenshots).
func locked_count() -> int:
	var n := 0
	for i in _locked.size():
		var e := _locked[i]
		if e.active and e.generation == _locked_gen[i] and (e.kit as PantheonKit).locked:
			n += 1
	return n


## The locked shield line: a bronze bar across the front of every locked member
## (perpendicular to its facing, a little wider than the body), with a lit top
## edge. Visual only.
func _draw() -> void:
	for i in _locked.size():
		var e := _locked[i]
		if not e.active or e.generation != _locked_gen[i]:
			continue
		var k := e.kit as PantheonKit
		if not k.locked:
			continue
		var f := k.facing  # Facing (unit).
		var side := Vector2(-f.y, f.x) * (e.radius + 4.0)  # Half the bar.
		var c := e.position + f * (e.radius + 3.0)  # Bar centre.
		draw_line(c - side, c + side, Palette.PANTHEON_BRONZE_INK, 6.0)
		draw_line(c - side, c + side, Palette.PANTHEON_BRONZE, 4.0)
		draw_line(c - side + f, c + side + f, Palette.PANTHEON_BRONZE_LIGHT, 1.5)
		draw_circle(c, 2.5, Palette.GOLD)  # The shield boss.
