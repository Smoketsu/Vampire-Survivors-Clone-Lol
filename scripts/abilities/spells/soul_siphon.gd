## SoulSiphon — the Soul Siphon spell (AbilityData "soul_siphon", GDD §5.3
## "nearby damage and capped lifesteal"): up to `targets` soul tethers hold
## the STRONGEST enemies (highest current HP, ties to the nearest) within
## `range` px. Every `cooldown` s each tether drains `damage`, and
## `lifesteal` of the damage dealt heals the necromancer, but never more
## than `heal_cap` HP per second (a leaky budget that banks at most
## AbilityData.SIPHON_BUDGET_SECONDS of it). A tether holds its enemy until
## it dies or strays AbilityData.SIPHON_LEASH px beyond the range; enemies
## already expected to die (overkill reservation) are never picked.
## Evolved into Soul Rapture (EvolutionData "soul_rapture", detected by the
## "burst" key): five tethers, a tethered enemy that dies (to anything)
## bursts for `burst` x the drain damage within `radius` px, and lifesteal
## the necromancer cannot use (full HP) mends the most wounded summon in
## range instead (`overflow`; barriers count as HP, flying Gargoyles are
## skipped).
class_name SoulSiphon
extends NecroSpell

## Tethered enemies.
var _targets: Array[Enemy] = []
## Generation of each tethered enemy when it was tethered.
var _gens: PackedInt32Array = PackedInt32Array()
## Seconds until the next drain pulse.
var _timer: float = 0.3
## Lifesteal HP still allowed by the per-second cap.
var _budget: float = 0.0
## Soul Rapture: world positions of pending death bursts (released next tick
## so a burst never runs inside the kill that caused it).
var _bursts: PackedVector2Array = PackedVector2Array()
## True while the evolved (Soul Rapture) stats are in use.
var _rapture: bool = false
## Necromancer position this tick (beam origin for drawing).
var _from: Vector2 = Vector2.ZERO
## Seconds of animation time (beam ripple, soul motes).
var _phase: float = 0.0
## 1 right after a drain pulse, fading to 0 (beam brightness).
var _glow: float = 0.0
## True if the last redraw showed tethers (one more redraw clears them).
var _drawn: bool = false
## Candidate [score, enemy] pairs when tethers are filled.
var _cands: Array = []


func _ready() -> void:
	z_index = 3


## Keeps tethers valid, releases Rapture bursts and drains on the pulse.
func step(delta: float, stats: Dictionary) -> void:
	_rapture = stats.has("burst")
	_from = game.player.position
	_phase += delta
	_glow = maxf(0.0, _glow - delta * 3.0)
	var cap := float(stats["heal_cap"])  # HP/s.
	_budget = minf(_budget + cap * delta, cap * AbilityData.SIPHON_BUDGET_SECONDS)
	_prune(float(stats["range"]) + AbilityData.SIPHON_LEASH)
	if not _bursts.is_empty():
		_release_bursts(stats)
	_timer -= delta
	if _timer <= 0.0:
		_fill(stats)
		if _targets.is_empty():
			_timer = AbilityData.SPELL_RETRY
		else:
			_drain(stats)
			_timer = float(stats["cooldown"])
	if not _targets.is_empty() or _drawn:
		queue_redraw()
	_drawn = not _targets.is_empty()


## Drops tethers whose enemy died, was recycled or strayed beyond `reach`.
func _prune(reach: float) -> void:
	var i := 0  # Index into _targets.
	while i < _targets.size():
		var e := _targets[i]
		if e.active and e.generation == _gens[i] and e.position.distance_to(_from) <= reach:
			i += 1
		else:
			_targets.remove_at(i)
			_gens.remove_at(i)


## Tethers the strongest open enemies in range until `targets` are held.
func _fill(stats: Dictionary) -> void:
	var want := int(stats["targets"])  # Tethers wanted.
	if _targets.size() >= want:
		return
	game.enemy_grid.query(_from, float(stats["range"]), _tmp)
	_cands.clear()
	for e: Enemy in _tmp:
		if not is_open_target(e) or _targets.has(e):
			continue
		var d := _from.distance_to(e.position)  # px; also breaks HP ties.
		if d > float(stats["range"]):
			continue
		_cands.append([-roundf(e.hp) * 10000.0 + d, e])
	_cands.sort_custom(func(a: Array, b: Array) -> bool: return float(a[0]) < float(b[0]))
	for c: Array in _cands:
		if _targets.size() >= want:
			break
		var e: Enemy = c[1]
		_targets.append(e)
		_gens.append(e.generation)


## One drain pulse: damages every tethered enemy, then heals (capped).
func _drain(stats: Dictionary) -> void:
	var dealt := 0.0  # Damage dealt this pulse.
	var src := "rapture" if _rapture else "siphon"  # Stats tag.
	for i in _targets.size():
		dealt += game.combat.damage_enemy(_targets[i], float(stats["damage"]), src)
	_glow = 1.0  # The drain sound is the per-hit "siphon_hit" (Juice).
	var want := minf(dealt * float(stats["lifesteal"]), _budget)  # Heal allowed this pulse.
	if want <= 0.0:
		return
	var healed := game.combat.heal_player(want)  # HP the necromancer took.
	_budget -= healed
	game.stat_add("siphon_healed", healed)
	var spare := (want - healed) * float(stats.get("overflow", 0.0))  # Rapture overflow.
	if spare > 0.5:
		var u := _most_wounded_summon(float(stats["range"]))
		if u != null:
			var mended := game.combat.heal_unit(u, spare)  # HP the summon took.
			_budget -= mended
			game.stat_add("siphon_summon_heal", mended)


## The living summon within `r` px of the necromancer missing the largest
## fraction of its HP (null if none is hurt). Its barrier (Shieldwall, or a
## Warder / Profane Bishop ally barrier) counts as HP it still has, so a
## shielded summon only wins if its barrier does not cover the wound. Units
## still rising from the grave and airborne Gargoyles are skipped (the
## latter are not in the ally grid while flying anyway, and cannot be hit).
func _most_wounded_summon(r: float) -> SummonedUnit:
	game.ally_grid.query(_from, r, _tmp)
	var best: SummonedUnit = null  # Most wounded so far.
	var best_frac := 0.0  # Its uncovered missing HP fraction.
	for u: SummonedUnit in _tmp:
		if not u.active or u.state == SummonedUnit.State.DEAD or u.state == SummonedUnit.State.SPAWNING \
				or u.airborne or u.hp >= u.max_hp:
			continue
		var frac := (u.max_hp - u.hp - u.barrier_hp) / u.max_hp  # Wound not covered by a barrier.
		if frac > best_frac:
			best_frac = frac
			best = u
	return best


## Kill hook (NecroSpellBook): a tethered enemy that dies while Soul Rapture
## is active queues a death burst at its position.
func on_enemy_killed(e: Enemy) -> void:
	if not _rapture:
		return
	var idx := _targets.find(e)  # Tether slot of this enemy, if any.
	if idx >= 0 and _gens[idx] == e.generation:
		_bursts.append(e.position)


## Releases the queued Soul Rapture death bursts.
func _release_bursts(stats: Dictionary) -> void:
	var pts := _bursts.duplicate()  # Bursts may queue new bursts (kills).
	_bursts.clear()
	var r := float(stats.get("radius", 60.0))  # Burst radius (px).
	var dmg := float(stats["damage"]) * float(stats.get("burst", 0.0))  # Burst damage.
	for p: Vector2 in pts:
		damage_area(p, r, dmg, "rapture_burst")
		game.effects.ring(p, r, Palette.NECRO_GREEN, 0.35)
		game.effects.pop(p, Palette.BONE, 9.0)
		game.stat_add("rapture_bursts", 1.0)
		Sfx.play("rapture_burst", p)


func _draw() -> void:
	for i in _targets.size():
		var e := _targets[i]
		if not e.active:
			continue
		if _rapture:
			SpellGlyphs.draw_rapture_tether(self, _from, e.position, _phase + float(i) * 0.7, _glow)
		else:
			SpellGlyphs.draw_siphon_tether(self, _from, e.position, _phase + float(i) * 0.7, _glow)
