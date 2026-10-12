## SoulChains — the Soul Chains spell (AbilityData "soul_chains", GDD §15.0
## "Five more spells"; owner change: a soul-LIGHTNING bolt, not tethers):
## every `cooldown` s a bolt strikes the nearest open enemy within `range` px
## (enemies attacking a summon first, like Shadow Bolt's Nearest mode;
## enemies already expected to die are skipped), then arcs up to `jumps`
## times, each time to the nearest enemy not yet struck within `jump_range`
## px of the last one. Strike k (0 = the first) deals
## `damage` x (1 - `falloff`)^k and slows the enemy by `slow` for
## `slow_duration` s (CombatResolver.slow_enemy(), so Spirit Binding and
## Lingering Malediction lengthen it). The whole chain is chosen before any
## damage lands, so a kill mid-chain never breaks it.
## Evolved into Chains of the Damned (EvolutionData "chains_of_the_damned",
## detected by the "pull" key): up to 8 jumps, and every enemy struck after
## the first is yanked toward the first one (a `pull` px/s impulse divided by
## its mass, decaying like knockback).
## Drawn as jagged violet-soul arcs that flicker out after
## GraveSpellData.CHAINS_ARC_TIME s; each strike also flashes a small ring
## ("soul_lightning" animation when its art exists). The jag offsets come
## from a cast counter, never from an RNG (cosmetic, deterministic).
class_name SoulChains
extends NecroSpell

## One drawn arc between two points (pooled through `_arc_pool`).
class Arc:
	extends RefCounted
	## Start (world px).
	var a: Vector2 = Vector2.ZERO
	## End (world px).
	var b: Vector2 = Vector2.ZERO
	## Seconds left visible.
	var time_left: float = 0.0
	## Jag pattern seed (cast counter x jump index).
	var jag_seed: int = 0
	## True for a Chains of the Damned arc (drawing).
	var damned: bool = false

## Visible arcs.
var _arcs: Array[Arc] = []
## Idle Arc records ready for reuse.
var _arc_pool: Array[Arc] = []
## Seconds until the next bolt.
var _timer: float = 0.4
## Casts so far (jag seeds).
var _casts: int = 0
## Enemies struck by the current chain, in order.
var _chain: Array[Enemy] = []
## Own query buffer for the jump search.
var _near: Array = []
## True if the last redraw showed arcs (one more redraw clears them).
var _drawn: bool = false


func _ready() -> void:
	z_index = 3


## Casts on cooldown and fades the drawn arcs.
func step(delta: float, stats: Dictionary) -> void:
	_timer -= delta
	if _timer <= 0.0:
		_timer = float(stats["cooldown"]) if _cast(stats) else AbilityData.SPELL_RETRY
	var i := 0  # Index into _arcs (swap-remove).
	while i < _arcs.size():
		var arc := _arcs[i]
		arc.time_left -= delta
		if arc.time_left > 0.0:
			i += 1
		else:
			_arcs[i] = _arcs[_arcs.size() - 1]
			_arcs.pop_back()
			_arc_pool.append(arc)
	if not _arcs.is_empty() or _drawn:
		queue_redraw()
	_drawn = not _arcs.is_empty()


## Picks the chain and strikes it. Returns false when no enemy is in range.
func _cast(stats: Dictionary) -> bool:
	var p := game.player.position  # Necromancer (the bolt leaves his hand).
	var first := _first_target(p, float(stats["range"]))
	if first == null:
		return false
	_chain.clear()
	_chain.append(first)
	var jumps := int(stats["jumps"])  # Arcs after the first strike.
	var jr := float(stats["jump_range"])  # px between two struck enemies.
	for _j in jumps:
		var nxt := _next_target(_chain[_chain.size() - 1].position, jr)
		if nxt == null:
			break
		_chain.append(nxt)
	_casts += 1
	var damned := stats.has("pull")  # Evolved into Chains of the Damned.
	var src := "chains_damned" if damned else "soul_chains"  # Stats tag.
	var anchor := first.position  # Pull target (the first struck enemy).
	var pts := PackedVector2Array([p])  # Arc path: hand, then every strike.
	for e in _chain:
		pts.append(e.position)
	var dmg := float(stats["damage"])  # Damage of this strike (falls off per jump).
	var keep := 1.0 - float(stats["falloff"])  # Damage kept per jump.
	for k in _chain.size():
		var e := _chain[k]
		if not e.active:
			continue  # Killed by an earlier strike's kill hook (e.g. a detonation).
		if damned and k > 0:
			var to := anchor - e.position  # Toward the first struck enemy.
			if to.length() > 1.0:
				e.knockback += to.normalized() * float(stats["pull"]) / maxf(e.mass, 0.1)
				game.stat_add("chains_pulls", 1.0)
		game.combat.slow_enemy(e, float(stats["slow"]), float(stats["slow_duration"]))
		var pos := e.position  # Strike point (before a kill pools it).
		game.combat.damage_enemy(e, dmg, src)
		game.effects.ring(pos, GraveSpellData.CHAINS_FLASH_RADIUS, Palette.VIOLET, 0.18, "soul_lightning")
		dmg *= keep
	for k in pts.size() - 1:
		_add_arc(pts[k], pts[k + 1], _casts * 31 + k, damned)
	game.stat_add("chains_casts", 1.0)
	game.stat_add("chains_jumps", float(_chain.size() - 1))
	game.stat_add("chains_strikes", float(_chain.size()))
	Sfx.play("bolt_cast", p)
	_chain.clear()
	return true


## The first target: the nearest open enemy within `reach` px of `p`,
## enemies attacking a summon first (AbilityData.BOLT_PROTECT_BONUS).
func _first_target(p: Vector2, reach: float) -> Enemy:
	game.enemy_grid.query(p, reach, _tmp)
	var best: Enemy = null  # Best target so far.
	var best_s := INF  # Its score (px, lower is better).
	for e: Enemy in _tmp:
		if not is_open_target(e):
			continue
		var d := p.distance_to(e.position)
		if d > reach:
			continue
		var s := d - (AbilityData.BOLT_PROTECT_BONUS if e.targeting_summon else 0.0)  # Nearest, protecting summons.
		if s < best_s:
			best_s = s
			best = e
	return best


## The nearest live enemy within `reach` px of `from` not struck yet.
func _next_target(from: Vector2, reach: float) -> Enemy:
	game.enemy_grid.query(from, reach + ProjectileManager.MAX_BODY_RADIUS, _near)
	var best: Enemy = null  # Nearest so far.
	var best_d := INF  # Its distance.
	for e: Enemy in _near:
		if not e.active or e.hp <= 0.0 or _chain.has(e):
			continue
		var d := from.distance_to(e.position) - e.radius
		if d <= reach and d < best_d:
			best_d = d
			best = e
	return best


## Adds a visible arc from `a` to `b` (the oldest is dropped beyond the cap).
func _add_arc(a: Vector2, b: Vector2, jag: int, damned: bool) -> void:
	var arc: Arc = null  # Record to fill.
	if _arcs.size() >= GraveSpellData.CHAINS_ARC_MAX:
		arc = _arcs[0]
		_arcs.remove_at(0)
	elif not _arc_pool.is_empty():
		arc = _arc_pool.pop_back()
	else:
		arc = Arc.new()
	arc.a = a
	arc.b = b
	arc.time_left = GraveSpellData.CHAINS_ARC_TIME
	arc.jag_seed = jag
	arc.damned = damned
	_arcs.append(arc)


## Autotest counters (NecroSpellBook.later_summary_line()).
func summary_extra() -> String:
	var st := game.stats  # Run counters.
	var casts := maxf(1.0, float(st.get("chains_casts", 0.0)))  # For the average.
	return "casts=%d strikes=%d jumps=%d avg_jumps=%.2f pulls=%d" % [int(st.get("chains_casts", 0.0)), int(st.get("chains_strikes", 0.0)),
		int(st.get("chains_jumps", 0.0)), float(st.get("chains_jumps", 0.0)) / casts, int(st.get("chains_pulls", 0.0))]


func _draw() -> void:
	for arc in _arcs:
		var life := arc.time_left / GraveSpellData.CHAINS_ARC_TIME  # 1 -> 0 as it fades.
		GraveSpellGlyphs.draw_lightning(self, arc.a, arc.b, arc.jag_seed, life, arc.damned)
