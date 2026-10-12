## DeathMark — the Death Mark spell (AbilityData "death_mark", GDD §15.0
## "Five more spells"): every `cooldown` s it brands the `count` STRONGEST
## enemies within `range` px (highest current HP, ties to the nearest, the
## Shadow Bolt "Strongest" rule; enemies already expected to die are never
## picked, unbranded enemies before branded ones, Crimson March structures
## last). A brand burns for `duration` s, dealing `damage` every
## GraveSpellData.DEATH_MARK_TICK s (owner decision: a plain damage over
## time, NO damage-taken amplification, so it can kill early foes on its
## own as a starting spell). Branding an enemy that is already branded
## refreshes its brand.
## When a branded enemy dies (to anything), a temporary Risen skeleton
## climbs out where it fell (HordeDirector.spawn_temporary(), the Lich
## raise path: outside the army cap, never replaced; its own cap is the
## `risen_cap` stat; Crimson March structures have no body to raise).
## Evolved into Doom Brand (EvolutionData "doom_brand", detected by the
## "detonation" key): three brands per cast, and a branded death also
## detonates for `detonation` x the tick damage within `radius` px.
## Kill-hook work (Risen, detonations) is queued and released on the next
## step, so nothing runs inside the kill that caused it.
## Brands are pooled Brand records simulated and drawn by this one node.
class_name DeathMark
extends NecroSpell

## One burning brand (pooled through `_pool`).
class Brand:
	extends RefCounted
	## Branded enemy.
	var enemy: Enemy = null
	## Its generation when branded (stale guard).
	var gen: int = 0
	## Seconds of brand left.
	var time_left: float = 0.0
	## Seconds until the next damage tick.
	var tick: float = 0.0
	## Damage per tick.
	var damage: float = 0.0
	## True for a Doom Brand (drawing, stats tag, detonation).
	var doom: bool = false

## Burning brands.
var _brands: Array[Brand] = []
## Idle Brand records ready for reuse.
var _pool: Array[Brand] = []
## Seconds until the next cast.
var _timer: float = 0.5
## Living Death Mark Risen as [SummonedUnit, generation] pairs.
var _risen: Array = []
## World positions of branded deaths waiting for their Risen (next step).
var _pending_risen: PackedVector2Array = PackedVector2Array()
## Pending Doom Brand detonations: Vector3(x, y, damage), released next step.
var _pending_bursts: Array[Vector3] = []
## Candidate [score, enemy] pairs of a cast.
var _cands: Array = []
## Seconds of animation time (sigil rotation).
var _phase: float = 0.0
## True if the last redraw showed brands (one more redraw clears them).
var _drawn: bool = false


func _ready() -> void:
	z_index = 2


## Releases queued Risen / detonations, casts on cooldown and ticks brands.
func step(delta: float, stats: Dictionary) -> void:
	_phase += delta
	if not _pending_risen.is_empty():
		_raise_pending(int(stats["risen_cap"]))
	if not _pending_bursts.is_empty():
		_release_bursts(float(stats.get("radius", 0.0)))
	_timer -= delta
	if _timer <= 0.0:
		_timer = float(stats["cooldown"]) if _cast(stats) else AbilityData.SPELL_RETRY
	var src := "doom_brand" if stats.has("detonation") else "death_mark"  # Stats tag.
	var i := 0  # Index into _brands (swap-remove).
	while i < _brands.size():
		var b := _brands[i]
		if _step_brand(b, delta, src):
			i += 1
		else:
			_brands[i] = _brands[_brands.size() - 1]
			_brands.pop_back()
			b.enemy = null
			_pool.append(b)
	if not _brands.is_empty() or _drawn:
		queue_redraw()
	_drawn = not _brands.is_empty()


## Brands the `count` strongest open enemies in range. Returns false when no
## enemy is in range (the cooldown is not spent).
func _cast(stats: Dictionary) -> bool:
	var p := game.player.position  # Necromancer.
	var reach := float(stats["range"])  # Search radius (px).
	game.enemy_grid.query(p, reach, _tmp)
	_cands.clear()
	for e: Enemy in _tmp:
		if not is_open_target(e):
			continue
		var d := p.distance_to(e.position)  # px; also breaks HP ties.
		if d > reach:
			continue
		# Strongest first (Shadow Bolt "Strongest" rule); branded enemies and
		# Crimson March structures (always the "strongest" by HP) rank last.
		var rank := -roundf(e.hp) * 10000.0 + d  # Lower = branded first.
		if _brand_of(e) != null:
			rank += GraveSpellData.DEATH_MARK_BRANDED_PENALTY
		if e.is_structure:
			rank += GraveSpellData.DEATH_MARK_BRANDED_PENALTY * 1000.0
		_cands.append([rank, e])
	if _cands.is_empty():
		return false
	_cands.sort_custom(func(a: Array, b: Array) -> bool: return float(a[0]) < float(b[0]))
	var doom := stats.has("detonation")  # Evolved into Doom Brand.
	for k in mini(int(stats["count"]), _cands.size()):
		var e: Enemy = _cands[k][1]
		_brand(e, stats, doom)
	game.stat_add("death_mark_casts", 1.0)
	Sfx.play("plague_cast", p)
	return true


## Brands `e` (or refreshes its brand) with the current stats.
func _brand(e: Enemy, stats: Dictionary, doom: bool) -> void:
	var b := _brand_of(e)  # Existing brand, if any.
	if b == null:
		if _brands.size() >= GraveSpellData.DEATH_MARK_MAX:
			return
		b = _pool.pop_back() if not _pool.is_empty() else Brand.new()
		b.enemy = e
		b.gen = e.generation
		b.tick = GraveSpellData.DEATH_MARK_TICK
		_brands.append(b)
		game.stat_add("death_mark_brands", 1.0)
	else:
		game.stat_add("death_mark_refreshes", 1.0)
	b.time_left = float(stats["duration"])
	b.damage = float(stats["damage"])
	b.doom = doom
	# The Doomsayer's Ill Omen innate (CharacterData death_mark_slow; 0 for
	# every other character): the brand also slows its enemy for the brand's
	# duration, through the one slow path (CombatResolver.slow_enemy()).
	var s := game.character.innate_value("death_mark_slow")  # Slow fraction 0..1.
	if s > 0.0:
		game.combat.slow_enemy(e, s, b.time_left)
		game.stat_add("ill_omen_slows", 1.0)
	game.effects.ring(e.position, e.radius + 8.0, GraveSpellGlyphs.DOOM if doom else Palette.VIOLET, 0.3)


## The live brand on `e` (null if it is not branded).
func _brand_of(e: Enemy) -> Brand:
	for b in _brands:
		if b.enemy == e and b.gen == e.generation and b.time_left > 0.0:
			return b
	return null


## Ticks one brand. Returns false once it burned out or its enemy is gone.
func _step_brand(b: Brand, delta: float, src: String) -> bool:
	var e := b.enemy
	if e == null or not e.active or e.generation != b.gen or b.time_left <= 0.0:
		return false
	b.time_left -= delta
	b.tick -= delta
	if b.tick <= 0.0:
		b.tick += GraveSpellData.DEATH_MARK_TICK
		game.combat.damage_enemy(e, b.damage, src)  # May kill: on_enemy_killed() queues the Risen.
	return b.time_left > 0.0 and e.active and e.generation == b.gen


## Kill hook (NecroSpellBook): a branded enemy that dies (to anything)
## queues its Risen and, for a Doom Brand, its detonation.
func on_enemy_killed(e: Enemy) -> void:
	var b := _brand_of(e)  # Its brand, if branded.
	if b == null:
		return
	b.time_left = 0.0  # Burned out with its bearer.
	game.stat_add("death_mark_branded_deaths", 1.0)
	if not e.is_structure:
		_pending_risen.append(e.position)
	if b.doom:
		var stats := game.abilities.spell_stats("death_mark")  # Effective Doom Brand stats.
		_pending_bursts.append(Vector3(e.position.x, e.position.y, b.damage * float(stats.get("detonation", 0.0))))


## Raises the queued Risen, up to `cap` alive at once (the rest are skipped).
func _raise_pending(cap: int) -> void:
	var pts := _pending_risen.duplicate()  # Raising never queues more, but stay safe.
	_pending_risen.clear()
	for pos: Vector2 in pts:
		if _risen_alive() >= cap:
			game.stat_add("death_mark_risen_capped", 1.0)
			continue
		var u := game.horde.spawn_temporary(GraveSpellData.DEATH_MARK_RISEN_CLASS, pos, GraveSpellData.DEATH_MARK_RISEN_LIFE,
				GraveSpellData.DEATH_MARK_RISEN_HP, GraveSpellData.DEATH_MARK_RISEN_DAMAGE)
		u.dmg_source = "death_mark_risen"
		u.glyph_kind = "risen"
		u.queue_redraw()
		_risen.append([u, u.generation])
		game.effects.ring(u.position, 22.0, Palette.VIOLET, 0.5)
		game.stat_add("death_mark_risen", 1.0)
		Sfx.play("summon_rise", pos)


## Living Death Mark Risen (stale entries are dropped).
func _risen_alive() -> int:
	var i := _risen.size() - 1
	while i >= 0:
		var u: SummonedUnit = _risen[i][0]
		if not u.active or u.generation != int(_risen[i][1]):
			_risen.remove_at(i)
		i -= 1
	return _risen.size()


## Releases the queued Doom Brand detonations (`r` px radius). A detonation
## that kills another branded enemy queues the next one for the next step.
func _release_bursts(r: float) -> void:
	var pts := _pending_bursts.duplicate()  # Bursts may queue new bursts (kills).
	_pending_bursts.clear()
	for v: Vector3 in pts:
		var pos := Vector2(v.x, v.y)  # Detonation centre.
		damage_area(pos, r, v.z, "doom_burst")
		game.effects.ring(pos, r, GraveSpellGlyphs.DOOM, 0.35, "doom_burst")
		game.effects.ring(pos, r * 0.6, Palette.VIOLET, 0.45)
		game.stat_add("doom_detonations", 1.0)
		Sfx.play("corpse_burst", pos)


## Autotest counters (NecroSpellBook.later_summary_line()).
func summary_extra() -> String:
	var st := game.stats  # Run counters.
	return "casts=%d brands=%d refreshes=%d branded_deaths=%d risen=%d risen_capped=%d risen_dmg=%d detonations=%d" % [
		int(st.get("death_mark_casts", 0.0)), int(st.get("death_mark_brands", 0.0)), int(st.get("death_mark_refreshes", 0.0)),
		int(st.get("death_mark_branded_deaths", 0.0)), int(st.get("death_mark_risen", 0.0)), int(st.get("death_mark_risen_capped", 0.0)),
		int(st.get("dmg_death_mark_risen", 0.0)), int(st.get("doom_detonations", 0.0))]


func _draw() -> void:
	for b in _brands:
		var e := b.enemy
		if e == null or not e.active or e.generation != b.gen:
			continue
		GraveSpellGlyphs.draw_brand(self, e.position, e.radius, _phase, b.doom, b.time_left)
