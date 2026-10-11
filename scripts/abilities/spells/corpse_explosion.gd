## CorpseExplosion — the Corpse Explosion spell (AbilityData
## "corpse_explosion"): every enemy that dies, whoever killed it (the horde,
## spells, a Soul Nova), leaves a corpse for AbilityData.CORPSE_LIFE s
## (Crimson March structures leave none).
## Every `cooldown` s the spell detonates up to `count` corpses within
## `range` px of the necromancer, choosing the ones with the most live
## enemies inside `radius` (fresher corpses win ties); each burst deals
## `damage` to every enemy in its radius. Corpses with nobody near are kept,
## and a cast that finds none retries soon without spending its cooldown.
## The horde's kills feed it, so it rewards a big army.
## Evolved into Grave Eruption (EvolutionData "grave_eruption", GDD §5.3
## "bone spikes create damaging ground zones", detected by "zone_duration"):
## bigger bursts that each leave a bone-spike field for `zone_duration` s
## (`zone_damage` x damage per AbilityData.ZONE_TICK and a `zone_slow`
## slow inside), and an enemy an eruption kills erupts at once (up to
## `chain` extra bursts per cast).
## Corpses live in a fixed ring buffer (no allocation per kill).
class_name CorpseExplosion
extends NecroSpell

## One Grave Eruption bone-spike field (pooled through `_zone_pool`).
class Zone:
	extends RefCounted
	## Centre (world px).
	var pos: Vector2 = Vector2.ZERO
	## Radius (px).
	var radius: float = 0.0
	## Seconds left.
	var time_left: float = 0.0
	## Total lifetime (s), for the grow / fade drawing.
	var duration: float = 1.0
	## Seconds until the next damage tick.
	var tick: float = 0.0
	## Damage per tick to each enemy inside.
	var damage: float = 0.0
	## Fraction of speed removed inside.
	var slow: float = 0.0

## Corpse positions (ring buffer of AbilityData.CORPSE_MAX).
var _corpse_pos: PackedVector2Array = PackedVector2Array()
## Game time each corpse appeared (-1 = slot empty or already used).
var _corpse_time: PackedFloat32Array = PackedFloat32Array()
## Next ring-buffer slot to write.
var _next: int = 0
## Seconds until the next cast.
var _timer: float = 0.5
## True while the evolved (Grave Eruption) stats are in use.
var _eruption: bool = false
## True while this spell's own burst damage is being applied (kills made
## then chain instead of leaving a corpse).
var _bursting: bool = false
## Chain bursts still allowed in the current cast.
var _chain_left: int = 0
## Positions of chain bursts waiting to go off in the current cast.
var _chain_queue: PackedVector2Array = PackedVector2Array()
## Live bone-spike fields.
var _zones: Array[Zone] = []
## Idle Zone records ready for reuse.
var _zone_pool: Array[Zone] = []
## Recent bursts for drawing: x, y = centre, z = radius, w = age (s).
var _blasts: Array[Vector4] = []
## Reusable [score, slot] candidate list of a cast.
var _cands: Array = []
## Own query buffer for spike-field ticks (kill hooks use the others).
var _zone_tmp: Array = []


func _ready() -> void:
	z_index = -3
	_corpse_pos.resize(AbilityData.CORPSE_MAX)
	_corpse_time.resize(AbilityData.CORPSE_MAX)
	_corpse_time.fill(-1.0)


## Kill hook (NecroSpellBook): during one of this spell's own Grave
## Eruption bursts the victim erupts at once (chain); otherwise it leaves a
## corpse.
func on_enemy_killed(e: Enemy) -> void:
	if e.is_structure:
		return  # A destroyed Crimson March structure leaves rubble, not a corpse.
	if _bursting and _eruption and _chain_left > 0:
		_chain_left -= 1
		_chain_queue.append(e.position)
		return
	_corpse_pos[_next] = e.position
	_corpse_time[_next] = game.elapsed
	_next = (_next + 1) % AbilityData.CORPSE_MAX


## Casts on cooldown, ticks spike fields and ages the burst visuals.
func step(delta: float, stats: Dictionary) -> void:
	_eruption = stats.has("zone_duration")
	_timer -= delta
	if _timer <= 0.0:
		_timer = float(stats["cooldown"]) if _cast(stats) else AbilityData.SPELL_RETRY
	_step_zones(delta)
	var i := 0  # Index into _blasts.
	while i < _blasts.size():
		var b := _blasts[i]
		b.w += delta
		if b.w >= SpellGlyphs.BLAST_TIME:
			_blasts.remove_at(i)
		else:
			_blasts[i] = b
			i += 1
	queue_redraw()


## One cast: picks the best corpses and detonates them (plus chains).
## Returns false when no usable corpse has an enemy in reach.
func _cast(stats: Dictionary) -> bool:
	var p := game.player.position  # Necromancer.
	var r := float(stats["radius"])  # Burst radius.
	var reach := float(stats["range"])  # Corpse search radius.
	_cands.clear()
	for k in AbilityData.CORPSE_MAX:
		var t := _corpse_time[k]  # Death time of this slot.
		if t < 0.0 or game.elapsed - t > AbilityData.CORPSE_LIFE or _corpse_pos[k].distance_to(p) > reach:
			continue
		var n := count_enemies(_corpse_pos[k], r)  # Live enemies the burst would hit.
		if n > 0:
			# More victims first; fresher corpse breaks ties (score < 1).
			_cands.append([float(n) + t / maxf(game.elapsed, 1.0) * 0.5, k])
	if _cands.is_empty():
		return false
	_cands.sort_custom(func(a: Array, b: Array) -> bool: return float(a[0]) > float(b[0]))
	_chain_left = int(stats.get("chain", 0))
	_chain_queue.clear()
	var used := mini(int(stats["count"]), _cands.size())  # Corpses detonated.
	for j in used:
		var k: int = _cands[j][1]
		_corpse_time[k] = -1.0
		_detonate(_corpse_pos[k], stats, false)
	var c := 0  # Chain bursts released.
	while c < _chain_queue.size():
		_detonate(_chain_queue[c], stats, true)
		c += 1
	_chain_queue.clear()
	return true


## One burst at `pos` (a chained burst neither spawns a spike field nor
## chains past the cast's budget).
func _detonate(pos: Vector2, stats: Dictionary, chained: bool) -> void:
	var r := float(stats["radius"])  # Burst radius.
	_bursting = true
	damage_area(pos, r, float(stats["damage"]), "eruption" if _eruption else "corpse")
	_bursting = false
	_blasts.append(Vector4(pos.x, pos.y, r, 0.0))
	game.effects.ring(pos, r, Palette.BONE if not _eruption else Palette.NECRO_GREEN, 0.3)
	game.stat_add("corpse_bursts", 1.0)
	if chained:
		game.stat_add("eruption_chains", 1.0)
	Sfx.play("eruption" if _eruption else "corpse_burst", pos)
	if _eruption and not chained:
		_add_zone(pos, stats)


## Spawns a Grave Eruption bone-spike field (the oldest is replaced at
## AbilityData.ZONE_MAX).
func _add_zone(pos: Vector2, stats: Dictionary) -> void:
	var z: Zone = null  # Record to fill.
	if _zones.size() >= AbilityData.ZONE_MAX:
		z = _zones.pop_front()
	elif not _zone_pool.is_empty():
		z = _zone_pool.pop_back()
	else:
		z = Zone.new()
	z.pos = pos
	z.radius = float(stats["radius"])
	z.duration = float(stats["zone_duration"])
	z.time_left = z.duration
	z.tick = AbilityData.ZONE_TICK
	z.damage = float(stats["damage"]) * float(stats["zone_damage"])
	z.slow = float(stats["zone_slow"])
	_zones.append(z)


## Ticks the spike fields: damage and slow every ZONE_TICK, then expiry.
func _step_zones(delta: float) -> void:
	var i := 0  # Index into _zones.
	while i < _zones.size():
		var z := _zones[i]
		z.time_left -= delta
		z.tick -= delta
		if z.tick <= 0.0:
			z.tick += AbilityData.ZONE_TICK
			game.enemy_grid.query(z.pos, z.radius + ProjectileManager.MAX_BODY_RADIUS, _zone_tmp)
			for e: Enemy in _zone_tmp:
				if e.active and e.position.distance_to(z.pos) <= z.radius + e.radius:
					game.combat.slow_enemy(e, z.slow, AbilityData.ZONE_TICK + 0.1)
					game.combat.damage_enemy(e, z.damage, "eruption_spikes")
		if z.time_left <= 0.0:
			_zones.remove_at(i)
			_zone_pool.append(z)
		else:
			i += 1


func _draw() -> void:
	var now := game.elapsed  # For corpse fading.
	for k in AbilityData.CORPSE_MAX:
		var t := _corpse_time[k]  # Death time of this slot.
		if t >= 0.0 and now - t <= AbilityData.CORPSE_LIFE:
			SpellGlyphs.draw_corpse(self, _corpse_pos[k], 1.0 - (now - t) / AbilityData.CORPSE_LIFE, k)
	for z in _zones:
		SpellGlyphs.draw_spike_field(self, z.pos, z.radius, z.time_left / maxf(z.duration, 0.01), now)
	for b in _blasts:
		SpellGlyphs.draw_bone_burst(self, Vector2(b.x, b.y), b.z, b.w / SpellGlyphs.BLAST_TIME, _eruption)
