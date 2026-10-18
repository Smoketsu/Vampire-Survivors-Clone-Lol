## ForbiddenVerse — the Forbidden Verse spell (AbilityData "forbidden_verse";
## Act II, unlocked by slaying the Archivist: UnlockData; GDD §15.0 "Act II:
## the Hollow Archive", owner-approved proposal "Unlockable spells and
## passives"): the necromancer reads the Archivist's own scripture back at the
## Eye. `pages` pages orbit him at `orbit_radius` px (`orbit_speed` rad/s);
## every `cooldown` s they sweep wide (VerseData.SWEEP_REACH x the orbit for
## VerseData.SWEEP_TIME s). A page CUTS every enemy it passes (`damage`, at
## most once per `hit_cooldown` s per enemy) and INSCRIBES it for `inscribe`
## s (Enemy.inscribed_until, a timed mark written only here, i.e. only while
## someone owns the spell). An inscribed enemy that dies, to anything, BURSTS
## INTO INK: `burst` x `damage` to every enemy within `radius` px (source
## "ink_burst": Marginalia's on-death bonus applies in CombatResolver).
## A burst never sets off another one, except evolved:
## The Unwritten Word (EvolutionData "unwritten_word", detected by the "chain"
## key): six pages, and each ink burst can set off `chain` more (the first
## inscribed enemies it kills burst too, up to VerseData.CHAIN_MAX_DEPTH
## links). Kill-hook work (the bursts) is queued and released on the next
## step, so nothing runs inside the kill that caused it.
## The Heretic Scribe's innate Illuminated Margins (CharacterData
## "verse_burst_radius"; 0 for every other character) widens every burst.
## Pages, marks and bursts are simulated and drawn by this one node.
class_name ForbiddenVerse
extends NecroSpell

## Seconds of orbit (the pages' angle is orbit_speed x this).
var _orbit_t: float = 0.0
## Seconds until the next sweep starts.
var _sweep_cd: float = 2.0
## Seconds left of the running sweep (0 = none).
var _sweep_left: float = 0.0
## Enemy -> Vector2(generation, game time it may be cut again).
var _hit_until: Dictionary = {}
## Inscribed enemies to draw marks on: [Enemy, generation] pairs.
var _marked: Array = []
## Pending bursts: Vector4(x, y, damage, chain depth), released next step.
var _pending: Array[Vector4] = []
## Chain depth of the burst whose damage is running now (-1 = none: a kill
## outside a burst).
var _burst_depth: int = -1
## Bursts the running burst may still set off (The Unwritten Word's chain).
var _burst_chain_left: int = 0
## Current effective stats (cached each step for the kill hook).
var _stats: Dictionary = {}
## Page world positions this step (drawing).
var _page_pos: PackedVector2Array = PackedVector2Array()
## Page angles this step (drawing; the art points along the orbit).
var _page_ang: PackedFloat32Array = PackedFloat32Array()
## Physics ticks since the spell was learned (purges the hit cooldowns).
var _frame: int = 0


func _ready() -> void:
	z_index = 2


## Releases queued bursts, turns the pages, cuts what they touch.
func step(delta: float, stats: Dictionary) -> void:
	_stats = stats
	_frame += 1
	if not _pending.is_empty():
		_release_bursts()
	_orbit_t += delta
	_sweep_cd -= delta
	if _sweep_left > 0.0:
		_sweep_left -= delta
	elif _sweep_cd <= 0.0:
		_sweep_cd = float(stats["cooldown"])
		_sweep_left = VerseData.SWEEP_TIME
		game.stat_add("verse_sweeps", 1.0)
	var n := int(stats["pages"])
	var reach := float(stats["orbit_radius"])
	if _sweep_left > 0.0:
		var k := 1.0 - _sweep_left / VerseData.SWEEP_TIME  # 0 -> 1 through the sweep.
		reach *= 1.0 + (VerseData.SWEEP_REACH - 1.0) * sin(k * PI)
	var base := _orbit_t * float(stats["orbit_speed"])
	var c := game.player.position
	var evolved := stats.has("chain")
	var src := VerseData.SOURCE_EVOLVED if evolved else VerseData.SOURCE
	_page_pos.resize(n)
	_page_ang.resize(n)
	for i in n:
		var a := base + TAU * float(i) / float(n)
		var p := c + Vector2.from_angle(a) * reach
		_page_pos[i] = p
		_page_ang[i] = a + PI * 0.5
		_cut_at(p, stats, src)
	_prune_marks()
	if _frame % 600 == 0:
		_purge_hits()
	queue_redraw()


## Cuts and inscribes every enemy a page at `p` touches (once per
## hit_cooldown s per enemy).
func _cut_at(p: Vector2, stats: Dictionary, src: String) -> void:
	var hits: Array = []  # Own buffer: a kill may run other hooks.
	game.enemy_grid.query(p, VerseData.PAGE_RADIUS + ProjectileManager.MAX_BODY_RADIUS, hits)
	var now := game.elapsed
	for e: Enemy in hits:
		if not e.active or e.position.distance_to(p) > VerseData.PAGE_RADIUS + e.radius:
			continue
		var rec: Variant = _hit_until.get(e)
		if rec != null and int((rec as Vector2).x) == e.generation and (rec as Vector2).y > now:
			continue
		_hit_until[e] = Vector2(float(e.generation), now + float(stats["hit_cooldown"]))
		if e.inscribed_until <= now:
			_marked.append([e, e.generation])
			game.stat_add("verse_inscribed", 1.0)
		e.inscribed_until = maxf(e.inscribed_until, now + float(stats["inscribe"]))
		game.stat_add("verse_cuts", 1.0)
		game.combat.damage_enemy(e, float(stats["damage"]), src)  # May kill: on_enemy_killed() queues its burst.


## Kill hook (NecroSpellBook): an inscribed enemy that dies queues its ink
## burst. Inside a burst's own damage only The Unwritten Word chains (at most
## `chain` more per burst, up to CHAIN_MAX_DEPTH links).
func on_enemy_killed(e: Enemy) -> void:
	if e.inscribed_until <= game.elapsed or _stats.is_empty():
		return
	e.inscribed_until = 0.0
	var depth := 0
	if _burst_depth >= 0:
		if not _stats.has("chain") or _burst_chain_left <= 0 or _burst_depth + 1 > VerseData.CHAIN_MAX_DEPTH:
			return  # A burst sets off no other (base), or this one's chain is spent.
		_burst_chain_left -= 1
		depth = _burst_depth + 1
		game.stat_add("verse_chain_bursts", 1.0)
	if _pending.size() >= VerseData.BURST_QUEUE_MAX:
		game.stat_add("verse_bursts_dropped", 1.0)
		return
	var dmg := float(_stats["damage"]) * float(_stats["burst"])
	_pending.append(Vector4(e.position.x, e.position.y, dmg, float(depth)))


## Releases the queued bursts. A burst that kills inscribed enemies may queue
## the next links (released on the next step).
func _release_bursts() -> void:
	var list := _pending.duplicate()  # Bursts may queue new bursts (kills).
	_pending.clear()
	var r := float(_stats["radius"]) * (1.0 + game.character.innate_value("verse_burst_radius"))  # Burst radius (px).
	for v: Vector4 in list:
		var pos := Vector2(v.x, v.y)
		_burst_depth = int(v.w)
		_burst_chain_left = int(_stats.get("chain", 0))
		damage_area(pos, r, v.z, VerseData.SOURCE_BURST)
		_burst_depth = -1
		game.stat_add("verse_bursts", 1.0)
		game.effects.ring(pos, r, VerseData.BURST_COLOR, 0.35, "ink_burst")
		game.effects.pop(pos, VerseData.INK_COLOR, r * 0.5)
		Sfx.play("corpse_burst", pos, 0.6)


## Drops marks whose enemy is gone or whose inscription ran out.
func _prune_marks() -> void:
	var now := game.elapsed
	var i := _marked.size() - 1
	while i >= 0:
		var e: Enemy = _marked[i][0]
		if not e.active or e.generation != int(_marked[i][1]) or e.inscribed_until <= now:
			_marked[i] = _marked[_marked.size() - 1]
			_marked.pop_back()
		i -= 1


## Forgets expired hit cooldowns (keeps the dictionary small).
func _purge_hits() -> void:
	var now := game.elapsed
	for e: Enemy in _hit_until.keys():
		if (_hit_until[e] as Vector2).y < now or not e.active:
			_hit_until.erase(e)


## Autotest counters (NecroSpellBook.later_summary_line()).
func summary_extra() -> String:
	var st := game.stats
	return "cuts=%d inscribed=%d sweeps=%d bursts=%d chain_bursts=%d burst_dmg=%d marginalia_bonus=%d" % [
		int(st.get("verse_cuts", 0.0)), int(st.get("verse_inscribed", 0.0)), int(st.get("verse_sweeps", 0.0)),
		int(st.get("verse_bursts", 0.0)), int(st.get("verse_chain_bursts", 0.0)), int(st.get("dmg_ink_burst", 0.0)),
		int(st.get("marginalia_bonus_dmg", 0.0))]


func _draw() -> void:
	var evolved := _stats.has("chain")
	for i in _page_pos.size():
		ArchiveGlyphs.draw_verse_page(self, _page_pos[i], _page_ang[i], evolved)
	var ph := _orbit_t * 3.0
	for m: Array in _marked:
		var e: Enemy = m[0]
		if e.active and e.generation == int(m[1]):
			ArchiveGlyphs.draw_inscription(self, e.position + Vector2(0.0, e.marker_y(-e.radius * 2.0)), ph)
