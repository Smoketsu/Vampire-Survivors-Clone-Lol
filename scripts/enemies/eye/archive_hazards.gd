## ArchiveHazards — the world hazards the Hollow Archive's kinds and boss leave
## (Act II; GDD §15.0 "Act II: the Hollow Archive"), on ANY stage: an Archive
## kind spawned elsewhere (--spawn=) brings its hazards with it, so this node
## does not belong to the Archive's director. EnemyDirector creates it on
## first use (archive_hazards()) and steps it after the stage directors.
## Numbers: ArchiveEnemyData.HAZARDS (the rules), the kinds' rows and
## ArchivistData (each hazard's size and life).
##   * Ink pools    — black ink (an Archivist page's hit, add_pool()). The
##                    necromancer standing in ink (a pool, or one of the Ink
##                    Wells' wells: ArchiveDirector.in_well()) is slowed
##                    (Necromancer.apply_ground_slow(), the one path) and his
##                    Dread rises ("ink"). Ink Wraiths rise out of them.
##   * Spore clouds — a Pilgrim of the Spore's (add_cloud()): Dread rises
##                    while he stands in one ("spores") and summons inside
##                    choke (light damage, source "spores").
##   * Pages        — the Archivist's Recitation (add_page()): they rise
##                    around her, hover (the telegraph), then home on the
##                    necromancer; one that touches him or a summon on the way
##                    hits it and bursts into an ink pool.
##   * Splits       — a Gibbering Mass that died queues its smaller masses
##                    (queue_split()); they spawn on the next step, outside
##                    the kill that caused them, at fixed offsets (no RNG).
## Dread is raised only through DreadMeter.add() and only where the stage has
## it (game.dread non-null). Deterministic: no RNG, game time only. Drawn
## here in world space under bodies; the pages and the Scribes' curse sigils
## are drawn on an overlay child above them.
class_name ArchiveHazards
extends Node2D

## One ink pool.
class InkPool:
	extends RefCounted
	## World centre.
	var pos: Vector2 = Vector2.ZERO
	## Radius (px).
	var radius: float = 30.0
	## Seconds left.
	var life: float = 4.0
	## Lifetime it started with (fade).
	var total: float = 4.0

## One spore cloud.
class SporeCloud:
	extends RefCounted
	## World centre.
	var pos: Vector2 = Vector2.ZERO
	## Radius (px).
	var radius: float = 44.0
	## Seconds left.
	var life: float = 6.0
	## Lifetime it started with (fade).
	var total: float = 6.0

## One Recitation page.
class Page:
	extends RefCounted
	## World position.
	var pos: Vector2 = Vector2.ZERO
	## Velocity (px/s).
	var vel: Vector2 = Vector2.ZERO
	## Where it hovers before it hunts.
	var hover: Vector2 = Vector2.ZERO
	## Seconds left of the hover (the telegraph); <= 0 while hunting.
	var rise_left: float = 0.5
	## Seconds left before it crumbles.
	var life: float = 4.5
	## The boss row it was read from (ArchivistData.BOSS: speed, damage...).
	var def: Dictionary = {}
	## Enemy damage multiplier when it was read (time scaling x aura).
	var mult: float = 1.0
	## Drawing phase (s; flutter).
	var t: float = 0.0

## One mass split waiting for the next step.
class Split:
	extends RefCounted
	## Kind of the smaller masses.
	var kind: String = ""
	## Where the mass fell.
	var pos: Vector2 = Vector2.ZERO
	## Unit direction from the mass to the necromancer when it fell.
	var dir: Vector2 = Vector2.RIGHT
	## How many.
	var count: int = 2
	## Px either side of `dir` they land.
	var offset: float = 18.0
	## True if the fallen mass was an elite (the splits are not).
	var elite: bool = false

## Owning run.
var game: Game
## Live ink pools.
var pools: Array[InkPool] = []
## Live spore clouds.
var clouds: Array[SporeCloud] = []
## Live pages.
var pages: Array[Page] = []
## Mass splits waiting for the next step.
var _splits: Array[Split] = []
## Seconds accumulated toward the next spore damage tick.
var _spore_tick: float = 0.0
## True if anything was drawn last frame (one more redraw clears it).
var _drew: bool = false
## The overlay (pages, curse sigils) drawn above the bodies.
var _overlay: ArchiveHazardOverlay = null
## Reusable query buffer.
var _tmp: Array = []


func _ready() -> void:
	z_index = -7  # On the ground, under bodies (like the Sanctum's chambers).
	_overlay = ArchiveHazardOverlay.new()
	_overlay.hazards = self
	_overlay.z_index = 12  # Above every body (the overlay's own z, not relative).
	_overlay.z_as_relative = false
	add_child(_overlay)


## Per-tick update (EnemyDirector, after the stage directors).
func step(delta: float) -> void:
	_release_splits()
	_age_pools(delta)
	_age_clouds(delta)
	_step_pages(delta)
	_apply_to_player(delta)
	_spore_damage(delta)
	var busy := not pools.is_empty() or not clouds.is_empty()
	if busy or _drew:
		queue_redraw()
	_drew = busy
	_overlay.step()


# =====================================================================================
# Adding hazards
# =====================================================================================

## A new ink pool of `radius` px at `pos` for `life` s (the oldest pool is
## dropped at HAZARDS.max_pools).
func add_pool(pos: Vector2, radius: float, life: float) -> void:
	if pools.size() >= int(ArchiveEnemyData.HAZARDS["max_pools"]):
		pools.remove_at(0)
	var p := InkPool.new()
	p.pos = pos
	p.radius = radius
	p.life = life
	p.total = life
	pools.append(p)
	game.stat_add("archive_ink_pools", 1.0)


## A new spore cloud of `radius` px at `pos` for `life` s (the oldest cloud is
## dropped at HAZARDS.max_clouds).
func add_cloud(pos: Vector2, radius: float, life: float) -> void:
	if clouds.size() >= int(ArchiveEnemyData.HAZARDS["max_clouds"]):
		clouds.remove_at(0)
	var c := SporeCloud.new()
	c.pos = pos
	c.radius = radius
	c.life = life
	c.total = life
	clouds.append(c)
	game.stat_add("archive_spore_clouds", 1.0)


## A Recitation page rising from `from` to hover at `hover`, reading its
## numbers from boss row `def`, its hits scaled by `mult`.
func add_page(from: Vector2, hover: Vector2, def: Dictionary, mult: float) -> void:
	var p := Page.new()
	p.pos = from
	p.hover = hover
	p.def = def
	p.mult = mult
	p.rise_left = float(def["page_rise_time"])
	p.life = float(def["page_life"])
	p.vel = (hover - from) / maxf(0.05, p.rise_left)
	p.t = float(pages.size()) * 0.37  # Flutter phase (look only, no RNG).
	pages.append(p)
	game.stat_add("archivist_pages", 1.0)


## Queues the split of a fallen Gibbering Mass (GibberingKit.on_killed()):
## `count` masses of `kind` land `offset` px either side of the fallen mass's
## line to the necromancer (`dir`) on the next step.
func queue_split(kind: String, pos: Vector2, dir: Vector2, count: int, offset: float, elite: bool) -> void:
	var s := Split.new()
	s.kind = kind
	s.pos = pos
	s.dir = dir
	s.count = count
	s.offset = offset
	s.elite = elite
	_splits.append(s)


## Spawns the queued splits (HARD_CAP respected).
func _release_splits() -> void:
	if _splits.is_empty():
		return
	var list := _splits.duplicate()  # Spawning never queues more, but stay safe.
	_splits.clear()
	for s: Split in list:
		var side := Vector2(-s.dir.y, s.dir.x)  # Perpendicular to the line to the necromancer.
		for i in s.count:
			if game.enemies.regular_alive() >= WaveData.HARD_CAP:
				game.stat_add("gibbering_splits_capped", 1.0)
				break
			var k := float(i) - float(s.count - 1) * 0.5  # -0.5, +0.5 for two.
			var at := s.pos + side * s.offset * 2.0 * k + s.dir * 4.0
			game.enemies.spawn_at(s.kind, at, false)
			game.stat_add("gibbering_splits", 1.0)
		game.effects.pop(s.pos, ArchiveEnemyData.SPORE_COLOR.darkened(0.3), 22.0)


# =====================================================================================
# Ageing and effects
# =====================================================================================

## Ink pools fade out.
func _age_pools(delta: float) -> void:
	var i := pools.size() - 1
	while i >= 0:
		pools[i].life -= delta
		if pools[i].life <= 0.0:
			pools.remove_at(i)
		i -= 1


## Spore clouds fade out.
func _age_clouds(delta: float) -> void:
	var i := clouds.size() - 1
	while i >= 0:
		clouds[i].life -= delta
		if clouds[i].life <= 0.0:
			clouds.remove_at(i)
		i -= 1


## True if `p` stands in ink: a pool here, or a well of the Archive's Ink Wells.
func in_ink(p: Vector2) -> bool:
	for pool in pools:
		if p.distance_squared_to(pool.pos) <= pool.radius * pool.radius:
			return true
	var ad := game.enemies.archive  # The Archive's director (null elsewhere).
	return ad != null and ad.in_well(p)


## The nearest ink (pool or well) centre within `reach` px of `p` that lies at
## least `min_gain` px nearer to `target` than `from` is (Ink Wraith dives),
## or Vector2.INF.
func ink_toward(target: Vector2, from: Vector2, reach: float, min_gain: float) -> Vector2:
	var best := Vector2.INF
	var best_d := reach
	var base := from.distance_to(target)  # How far the Wraith is now.
	var cands: Array[Vector2] = []
	for pool in pools:
		cands.append(pool.pos)
	var ad := game.enemies.archive  # The Archive's director (null elsewhere).
	if ad != null:
		cands.append_array(ad.wells_near(target, reach))
	for c in cands:
		var d := c.distance_to(target)
		if d < best_d and base - d >= min_gain:
			best_d = d
			best = c
	return best


## Spore clouds and ink act on the necromancer: Dread and the ink slow.
func _apply_to_player(delta: float) -> void:
	var pl := game.player
	var h: Dictionary = ArchiveEnemyData.HAZARDS
	if in_ink(pl.position):
		pl.apply_ground_slow(float(h["ink_slow"]), float(h["ink_linger"]))
		game.stat_add("archive_ink_seconds", delta)
		if game.dread != null:
			game.dread.add(float(h["ink_dread"]) * delta, "ink")
	for c in clouds:
		if pl.position.distance_squared_to(c.pos) <= c.radius * c.radius:
			game.stat_add("archive_spore_seconds", delta)
			if game.dread != null:
				game.dread.add(float(h["spore_dread"]) * delta, "spores")
			break


## Summons inside a spore cloud choke every spore_tick s (once a tick, however
## many clouds overlap).
func _spore_damage(delta: float) -> void:
	if clouds.is_empty():
		_spore_tick = 0.0
		return
	_spore_tick += delta
	var h: Dictionary = ArchiveEnemyData.HAZARDS
	var tick := float(h["spore_tick"])
	if _spore_tick < tick:
		return
	_spore_tick -= tick
	var dmg := float(h["spore_summon_dps"]) * tick * game.enemies.damage_mult  # Per summon this tick.
	var choked := {}  # Summons already hurt this tick (overlapping clouds hurt once).
	for c in clouds:
		game.ally_grid.query(c.pos, c.radius + UnitData.MAX_BLOCK_RADIUS, _tmp)
		for u: SummonedUnit in _tmp:
			if choked.has(u) or not u.active or u.state == SummonedUnit.State.SPAWNING or u.position.distance_to(c.pos) > c.radius + u.radius * 0.5:
				continue
			choked[u] = true
			game.combat.damage_unit(u, dmg, "spores")


## Pages hover, then hunt the necromancer; a hit hurts and leaves ink.
func _step_pages(delta: float) -> void:
	var i := pages.size() - 1
	var pl := game.player
	while i >= 0:
		var p := pages[i]
		p.t += delta
		p.life -= delta
		if p.rise_left > 0.0:
			p.rise_left -= delta
			p.pos += p.vel * delta
			if p.rise_left <= 0.0:
				p.pos = p.hover
				var to := pl.position - p.pos
				p.vel = (to.normalized() if to.length() > 0.5 else Vector2.RIGHT) * float(p.def["page_speed"])
			i -= 1
			continue
		# Home on the necromancer with a limited turn rate (a sidestep beats it).
		var want := (pl.position - p.pos).angle()
		var cur := p.vel.angle()
		var turn := clampf(angle_difference(cur, want), -float(p.def["page_turn"]) * delta, float(p.def["page_turn"]) * delta)
		p.vel = Vector2.from_angle(cur + turn) * float(p.def["page_speed"])
		p.pos += p.vel * delta
		var hit := _page_hit(p)
		if hit or p.life <= 0.0:
			if not hit:
				game.stat_add("archivist_pages_crumbled", 1.0)
			pages.remove_at(i)
		i -= 1


## Checks page `p` against the necromancer and the summons; on a hit: damage,
## an ink pool and true.
func _page_hit(p: Page) -> bool:
	var d := p.def
	var r := float(d["page_radius"])
	var pl := game.player
	if p.pos.distance_to(pl.position) <= r + pl.radius:
		game.combat.damage_player(float(d["page_damage_player"]) * p.mult, "archivist_page")
		game.stat_add("archivist_page_player_hits", 1.0)
		_page_burst(p)
		return true
	game.ally_grid.query(p.pos, r + UnitData.MAX_BLOCK_RADIUS, _tmp)
	for u: SummonedUnit in _tmp:
		if u.active and u.state != SummonedUnit.State.SPAWNING and p.pos.distance_to(u.position) <= r + u.radius:
			game.combat.damage_unit(u, float(d["page_damage_summon"]) * p.mult, "archivist_page")
			game.stat_add("archivist_page_summon_hits", 1.0)
			_page_burst(p)
			return true
	return false


## A page bursts into a short-lived ink pool where it hit.
func _page_burst(p: Page) -> void:
	add_pool(p.pos, float(p.def["page_pool_radius"]), float(p.def["page_pool_life"]))
	game.effects.pop(p.pos, ArchiveEnemyData.INK_SHEEN, 14.0)


## Drops every page (the Archivist fell).
func clear_pages() -> void:
	pages.clear()


# =====================================================================================
# Queries (autopilot)
# =====================================================================================

## Autopilot hint: away from hunting pages close to `p`, and out of spore
## clouds and ink (zero when none is near).
func danger_push(p: Vector2) -> Vector2:
	var push := Vector2.ZERO
	for pg in pages:
		var off := p - pg.pos
		var d := off.length()
		if d < 70.0 and d > 0.1:
			push += off / d * (1.0 - d / 70.0)
	for c in clouds:
		var off := p - c.pos
		var d := off.length()
		if d < c.radius + 16.0 and d > 0.1:
			push += off / d * 0.5
	for pool in pools:
		var off := p - pool.pos
		var d := off.length()
		if d < pool.radius + 12.0 and d > 0.1:
			push += off / d * 0.5
	return push.limit_length(1.0)


# =====================================================================================
# Drawing (ground layer)
# =====================================================================================

func _draw() -> void:
	var now := game.elapsed
	var h: Dictionary = ArchiveEnemyData.HAZARDS
	for pool in pools:
		var a := _fade(pool.life, pool.total, float(h["pool_fade"]))
		ArchiveGlyphs.draw_ink_pool(self, pool.pos, pool.radius, a, now)
	for c in clouds:
		var a := _fade(c.life, c.total, float(h["cloud_fade"]))
		ArchiveGlyphs.draw_spore_cloud(self, c.pos, c.radius, a, now, c.total - c.life)


## 0..1 alpha of a hazard `life` s from its end, `total` s long, fading over `fade` s.
static func _fade(life: float, total: float, fade: float) -> float:
	return clampf(minf(life, total - life + 0.05) / maxf(0.05, fade), 0.0, 1.0)
