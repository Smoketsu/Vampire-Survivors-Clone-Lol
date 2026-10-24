## VolleyDirector: the bullet heaven pass (GDD §15.0 "Bullet heaven pass"; numbers in
## VolleyData). Owns every volley shot: summon volleys (each class's signature attack from
## Lv 3, its evolution's showpiece), spell echoes (each owned spell from Lv 3) and the
## Rally Barrage (Dread Rally fires the whole army's volleys at once, then volleys come
## VolleyData.BARRAGE_RATE times as often while the rally buff runs).
## Shots are plain data in parallel packed arrays (no node per shot): moved without
## physics, collided through the enemy spatial hash, drawn in one _draw() pass. Every hit
## goes through CombatResolver.damage_enemy() with the source of what fired it (the unit's
## dmg_source, or the spell id), so synergies, crits, armour and the run statistics treat
## a volley hit as that class's or spell's own. A volley lands at most
## VolleyData.BOSS_HITS_PER_VOLLEY hits on bosses and minibosses.
## Off (Game.volleys_on false: the Volleys setting, or --volleys=off) every entry point
## returns at once and nothing here runs, draws or touches the RNG: the game without the
## pass. Deterministic per seed: every pattern is fixed math on the volley
## counter (rain landing points on a golden-angle spiral), never an RNG.
class_name VolleyDirector
extends Node2D

## Owning run.
var game: Game
## True while the pass is on for this run (copied from Game.volleys_on in setup()).
var on: bool = false
## False while this army's necromancer lies downed in co-op (CoopSession): his
## spells cast no echoes; shots already flying keep flying. Always true in solo.
var echoes_on: bool = true

# --- Shots (parallel arrays; slot i is one shot) ---------------------------------------

## Shot positions (world px).
var _pos := PackedVector2Array()
## Shot velocities (px/s).
var _vel := PackedVector2Array()
## Seconds of life left (<= 0 = free slot).
var _life := PackedFloat32Array()
## Damage of one hit.
var _dmg := PackedFloat32Array()
## Collision radius (px).
var _rad := PackedFloat32Array()
## Turn rate while flying (rad/s; spirals).
var _curve := PackedFloat32Array()
## Homing turn rate (rad/s; 0 = none).
var _homing := PackedFloat32Array()
## Extra enemies the shot may still pass through.
var _pierce := PackedInt32Array()
## Volley number of the shot (for the boss-hit cap; index into _boss_hits).
var _vid := PackedInt32Array()
## Style index (STYLES) for drawing.
var _style := PackedInt32Array()
## Shot colour.
var _col := PackedColorArray()
## Damage source string of each shot (the class's dmg_source or the spell id).
var _src := PackedStringArray()
## Homing target of each shot (Enemy or null).
var _target: Array = []
## The target's generation when aimed (a recycled enemy is not followed).
var _target_gen := PackedInt32Array()
## The last enemy each shot hit (a piercing shot never hits it twice in a row).
var _last_hit: Array = []
## Free slots, used as a stack.
var _free := PackedInt32Array()
## Shots in flight.
var alive: int = 0

## Boss / miniboss hits landed per volley slot (index = volley number % VOLLEY_SLOTS).
var _boss_hits := PackedInt32Array()
## Volleys fired so far (also the next volley's number).
var volleys_fired: int = 0
## Rally Barrage: game time (s) until which attack volleys come faster (0 = none).
var barrage_until: float = 0.0
## Per spell id: seconds until its next echo.
var _spell_timer: Dictionary = {}
## Per spell id: cooldowns counted toward its `every`.
var _spell_count: Dictionary = {}
## Reusable enemy query buffer.
var _tmp: Array = []
## Second query buffer (density checks inside a query loop).
var _tmp2: Array = []

## Style names, in style-index order (drawing).
const STYLES: Array[String] = ["shard", "orb", "dagger", "spark", "note", "feather", "wave"]

# --- Art and bursts (drawing only; GDD §15.0 "Volley art") ------------------------------

## Shot mask texture per style index (VolleyData.ART_DIR; null = no art, code shape).
var _art: Array = []
## True when the impact burst strip exists (VolleyData.HIT_ANIM).
var _has_hit_art: bool = false
## True when the launch flash strip exists (VolleyData.FLASH_ANIM).
var _has_flash_art: bool = false
## Burst ring buffer (VolleyData.FX_CAP slots): centre (world px).
var _fx_pos := PackedVector2Array()
## Burst game time of birth (s; -1 = empty slot).
var _fx_t0 := PackedFloat32Array()
## Burst diameter (px).
var _fx_size := PackedFloat32Array()
## Burst tint.
var _fx_col := PackedColorArray()
## Burst kind: 0 = impact (HIT_ANIM), 1 = launch flash (FLASH_ANIM).
var _fx_kind := PackedInt32Array()
## Next burst slot to write (the oldest is replaced).
var _fx_next: int = 0
## Glow disc texture of the art shots (_make_disc(); null headless / without art).
var _disc: Texture2D = null
## Scratch, reused every frame: sort keys (style index << 16 | slot) of the art
## shots drawn this frame (no per-frame allocation once grown).
var _order := PackedInt32Array()
## Per style index: drawn length of its mask as a multiple of the shot's drawn
## radius (VolleyData.ART_LEN, read once at setup).
var _art_len := PackedFloat32Array()
## Game time (s) until which some burst is still playing (keeps redrawing).
var _fx_until: float = 0.0

# --- Statistics (autotest volleys line) -------------------------------------------------

## Shots fired.
var shots_fired: int = 0
## Shots that hit something (hits, piercing ones counted per enemy).
var hits: int = 0
## Damage dealt by volley shots, by class / spell key.
var dmg_by: Dictionary = {}
## Most shots in flight at once.
var peak_alive: int = 0
## Volleys thinned by the shot cap (fewer, heavier shots).
var capped_volleys: int = 0
## Rally Barrages fired.
var barrages: int = 0
## Boss / miniboss hits refused by the per-volley cap.
var boss_hits_capped: int = 0


func _init() -> void:
	var n := VolleyData.SHOT_CAP  # Slots.
	_pos.resize(n)
	_vel.resize(n)
	_life.resize(n)
	_dmg.resize(n)
	_rad.resize(n)
	_curve.resize(n)
	_homing.resize(n)
	_pierce.resize(n)
	_vid.resize(n)
	_style.resize(n)
	_col.resize(n)
	_src.resize(n)
	_target.resize(n)
	_target_gen.resize(n)
	_last_hit.resize(n)
	_free.resize(n)
	for i in n:
		_free[i] = n - 1 - i
	_boss_hits.resize(VolleyData.VOLLEY_SLOTS)
	var f := VolleyData.FX_CAP  # Burst slots.
	_fx_pos.resize(f)
	_fx_t0.resize(f)
	_fx_size.resize(f)
	_fx_col.resize(f)
	_fx_kind.resize(f)
	_fx_t0.fill(-1.0)


## Called once by Game after the run's systems exist: reads the switch.
func setup(p_game: Game) -> void:
	game = p_game
	on = game.volleys_on
	z_index = 1  # Under the projectiles and telegraphs (z 2+): the Covenant's attacks read on top.
	# Additive blending: the shots glow and brighten what they cross (drawing only).
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = mat
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR  # The masks are scaled smoothly (effects art).
	if not on or DisplayServer.get_name() == "headless":
		return  # Nothing is drawn: no art to load.
	for st: String in STYLES:
		_art.append(SpriteBank.texture(VolleyData.ART_DIR + st))
		_art_len.append(float(VolleyData.ART_LEN.get(st, 5.0)))
	_disc = _make_disc()
	_has_hit_art = SpriteBank.has_anim(VolleyData.HIT_ANIM)
	_has_flash_art = SpriteBank.has_anim(VolleyData.FLASH_ANIM)


# =====================================================================================
# Entry points (each returns at once when the pass is off)
# =====================================================================================

## A summon released an attack (SummonedUnit._step_cast): counts it toward the class's
## attack-triggered volley and fires the volley every `every`-th release (twice as often
## during a Rally Barrage).
func on_attack(u: SummonedUnit) -> void:
	if not on:
		return
	var v := volley_of(u)  # The unit's volley ({} = none yet).
	if v.is_empty() or String(v["trigger"]) != "attack":
		return
	u.volley_count += 1
	var every := int(v.get("every", 1))  # Releases per volley.
	if game.elapsed < barrage_until:
		every = maxi(1, every / VolleyData.BARRAGE_RATE)
	if u.volley_count < every:
		return
	u.volley_count = 0
	var aim := u.target.position if u.target_alive() else u.position + Vector2.RIGHT.rotated(float(volleys_fired) * 0.7) * 40.0  # Aim point.
	_fire(v, u.position, aim, u.damage, u.dmg_source, _count_for(u, v), u.target if u.target_alive() else null)


## A class special happened (stomp, dash end, swoop impact, Dirge wave, boulder landing,
## mage explosion): fires the special-triggered volley of `u`'s class at `at`, aimed at
## `aim`, each shot a share of `damage` (the special's own damage). `u` may be null for a
## hit whose unit is gone (a mage orb landing): then `cls` and `evolution` name it.
func on_special(u: SummonedUnit, at: Vector2, aim: Vector2, damage: float, cls: String = "", evolution: String = "") -> void:
	if not on:
		return
	var c := cls  # Class id.
	var evo := evolution  # Evolution id ("" = none).
	var source := ""  # Damage source.
	if u != null:
		c = u.unit_class
		evo = u.evolution
		source = u.dmg_source
	else:
		source = evo if evo != "" else c
	var v := _volley_for(c, evo)
	if v.is_empty() or String(v["trigger"]) != "special":
		return
	_fire(v, at, aim, damage, source, _count_of(c, evo, v), null)


## A mage orb burst at `at` (ProjectileManager._explode): the forking sparks, by source.
func on_mage_burst(at: Vector2, damage: float, source: String) -> void:
	if not on:
		return
	var evo := source if source == "lich" else ""  # The Lich's spiral, else the mage's fork.
	on_special(null, at, at + Vector2.RIGHT, damage, "mage", evo)


## Dread Rally cast (DreadRally._cast): every summon fires its volley at once (at least
## its BARRAGE_MIN_LEVEL count), then attack volleys come faster until the buff ends.
func barrage(duration: float) -> void:
	if not on:
		return
	barrages += 1
	barrage_until = game.elapsed + duration
	for u in game.horde.units:
		if not u.active or u.state == SummonedUnit.State.DEAD:
			continue
		var v := _volley_for(u.unit_class, u.evolution)
		if v.is_empty():
			continue
		var aim := u.target.position if u.target_alive() else game.player.position + (u.position - game.player.position) * 2.0  # Outward when idle.
		var n := _count_of(u.unit_class, u.evolution, v, true)
		_fire(v, u.position, aim, u.damage, u.dmg_source, n, u.target if u.target_alive() else null)
	game.stat_add("volley_barrages", 1.0)


# =====================================================================================
# Per-tick update (Game, after the projectiles)
# =====================================================================================

## Spell echoes, then moves and collides every shot.
func step(delta: float) -> void:
	if not on:
		return
	_step_spells(delta)
	if alive == 0:
		if game.elapsed < _fx_until:
			queue_redraw()  # The last bursts are still playing.
		return
	var n := VolleyData.SHOT_CAP
	for i in n:
		if _life[i] <= 0.0:
			continue
		_life[i] -= delta
		if _life[i] <= 0.0:
			_kill(i)
			continue
		var v := _vel[i]
		if _homing[i] > 0.0:
			var t: Enemy = _target[i]
			if t != null and t.active and t.generation == _target_gen[i]:
				var cur := v.angle()
				var want := (t.position - _pos[i]).angle()
				var turn := clampf(wrapf(want - cur, -PI, PI), -_homing[i] * delta, _homing[i] * delta)
				v = v.rotated(turn)
		if _curve[i] != 0.0:
			v = v.rotated(_curve[i] * delta)
		_vel[i] = v
		_pos[i] += v * delta
		_collide(i)
	queue_redraw()


## Spell echoes: each owned spell at LEVEL_ON+ fires its echo every `every` cooldowns.
func _step_spells(delta: float) -> void:
	if not echoes_on:
		return
	var ab := game.abilities  # Spell owner.
	for id: String in VolleyData.SPELLS:
		var lvl := ab.spell_level(id)  # 0 = not owned.
		if lvl < VolleyData.LEVEL_ON:
			continue
		var s := ab.spell_stats(id)  # Effective stats (passives applied).
		var v: Dictionary = VolleyData.SPELLS[id]
		var t := float(_spell_timer.get(id, 0.0)) - delta
		if t > 0.0:
			_spell_timer[id] = t
			continue
		var cd := float(s.get(String(v["clock"]), s.get("cooldown", 2.0)))  # The spell's own rhythm (s).
		_spell_timer[id] = maxf(0.25, cd)
		var c := int(_spell_count.get(id, 0)) + 1
		if c < int(v["every"]):
			_spell_count[id] = c
			continue
		_spell_count[id] = 0
		var target := _spell_target(String(v["aim"]))
		if target == null:
			continue
		var counts: Array = v["counts"]
		var idx := 2 if ab.evolved.has(id) else (1 if lvl >= VolleyData.LEVEL_GROW else 0)  # Count column.
		# Base damage of the echo: the spell's effective damage, or a flat value for a
		# spell without one (Raise Dead).
		var base := float(v["flat"]) if v.has("flat") else float(s.get("damage", 0.0))
		_fire(v, game.player.position, target.position, base, id, int(counts[idx]), target)


## The enemy a spell echo aims at, within VolleyData.SPELL_RANGE of the necromancer:
## the nearest, the strongest (most max HP) or the one with the most others around it.
func _spell_target(mode: String) -> Enemy:
	var pp := game.player.position
	game.enemy_grid.query(pp, VolleyData.SPELL_RANGE, _tmp)
	var best: Enemy = null
	var best_score := -INF
	for e: Enemy in _tmp:
		if not e.active or e.is_structure:
			continue
		var d := pp.distance_to(e.position)
		if d > VolleyData.SPELL_RANGE:
			continue
		var score := -d  # Nearest by default.
		if mode == "strongest":
			score = e.max_hp - d * 0.01
		if score > best_score:
			best_score = score
			best = e
	if mode == "densest" and best != null:
		# The densest pack: of the nearest few, the one with the most others around it.
		var cands: Array = []
		for e: Enemy in _tmp:
			if e.active and not e.is_structure and pp.distance_to(e.position) <= VolleyData.SPELL_RANGE:
				cands.append(e)
		cands.sort_custom(func(a: Enemy, b: Enemy) -> bool: return pp.distance_squared_to(a.position) < pp.distance_squared_to(b.position))
		var most := -1
		for e: Enemy in cands.slice(0, VolleyData.DENSE_CANDIDATES):
			game.enemy_grid.query(e.position, VolleyData.DENSE_RADIUS, _tmp2)
			if _tmp2.size() > most:
				most = _tmp2.size()
				best = e
	return best


# =====================================================================================
# Firing
# =====================================================================================

## The volley of unit `u` ({} below LEVEL_ON or when its class has none).
func volley_of(u: SummonedUnit) -> Dictionary:
	if _class_level(u.unit_class) < VolleyData.LEVEL_ON:
		return {}
	return _volley_for(u.unit_class, u.evolution)


## The volley entry of class `cls` with evolution `evo` (the evolution's showpiece when
## it has one, else the class's).
func _volley_for(cls: String, evo: String) -> Dictionary:
	if evo != "" and VolleyData.EVOLVED.has(evo):
		return VolleyData.EVOLVED[evo]
	return VolleyData.CLASSES.get(cls, {})


## Shot count of unit `u`'s volley `v` at its class level.
func _count_for(u: SummonedUnit, v: Dictionary) -> int:
	return _count_of(u.unit_class, u.evolution, v)


## Shot count of volley `v` for class `cls` (evolution `evo`): the evolution's count, or
## the class's Lv 3-4 / Lv 5 count; 0 below LEVEL_ON unless `barrage` (then at least the
## Lv 3 count).
func _count_of(cls: String, evo: String, v: Dictionary, barrage_burst: bool = false) -> int:
	var counts: Array = v["counts"]
	if evo != "" and VolleyData.EVOLVED.has(evo):
		return int(counts[0])
	var lvl := _class_level(cls)
	if barrage_burst:
		lvl = maxi(lvl, VolleyData.BARRAGE_MIN_LEVEL)
	if lvl < VolleyData.LEVEL_ON:
		return 0
	return int(counts[1]) if lvl >= VolleyData.LEVEL_GROW and counts.size() > 1 else int(counts[0])


## The army's level in class `cls` (the Profane Bishop counts its best priest order).
func _class_level(cls: String) -> int:
	var lv: Dictionary = game.horde.class_levels
	if cls == "bishop":
		return maxi(int(lv.get("bishop", 0)), maxi(int(lv.get("mender", 0)), int(lv.get("warder", 0))))
	return int(lv.get(cls, 0))


## Fires `count` shots of volley `v` from `from` toward `aim`, each dealing
## share x `base_damage` as `source`. Over the shot cap the volley fires fewer, heavier
## shots (same total damage).
func _fire(v: Dictionary, from: Vector2, aim: Vector2, base_damage: float, source: String, count: int, target: Enemy) -> void:
	if count <= 0 or base_damage <= 0.0:
		return
	var free := _free.size()  # Free slots.
	var n := count  # Shots actually fired.
	var dmg := base_damage * float(v["share"])  # Damage per shot.
	if n > free:
		if free <= 0:
			capped_volleys += 1
			return
		dmg *= float(count) / float(free)
		n = free
		capped_volleys += 1
	var vid := volleys_fired % VolleyData.VOLLEY_SLOTS  # This volley's slot.
	_boss_hits[vid] = 0
	volleys_fired += 1
	var pattern := String(v["pattern"])
	var speed := float(v["speed"])
	var dir := aim - from
	var base := dir.angle() if dir.length() > 0.01 else 0.0  # Aim angle.
	var style := STYLES.find(String(v["style"]))
	var targets: Array = []  # Seek: one target per shot (nearest first).
	if pattern == "seek":
		targets = _nearest(from, n, target)
	for k in n:
		var ang := base  # Heading of this shot.
		var start := from  # Starting point.
		match pattern:
			"fan":
				var spread := deg_to_rad(float(v.get("spread", 0.0)))
				ang = base if n == 1 else base - spread * 0.5 + spread * float(k) / float(n - 1)
			"ring", "spiral":
				ang = base + TAU * float(k) / float(n) + float(volleys_fired) * 0.37
			"seek":
				var t: Enemy = targets[k % targets.size()] if not targets.is_empty() else null
				ang = (t.position - from).angle() if t != null else base + TAU * float(k) / float(n)
				ang += (float(k) - float(n - 1) * 0.5) * 0.35  # Fan out, then home in.
			"rain":
				# Landing points on a fixed pattern around the aim point (a golden-angle
				# spiral turned per volley: spread out, no RNG), each shot dropping in from above.
				var r := float(v.get("scatter", 40.0)) * sqrt((float(k) + 0.5) / float(n))
				var land := aim + Vector2.RIGHT.rotated(float(k) * 2.39996 + float(volleys_fired)) * r
				start = land + Vector2(0.0, -speed * float(v["life"]) * VolleyData.LIFE_MULT * 0.85)
				ang = PI * 0.5
		var i := _free[_free.size() - 1]
		_free.resize(_free.size() - 1)
		_pos[i] = start
		_vel[i] = Vector2.RIGHT.rotated(ang) * speed
		_life[i] = float(v["life"]) * VolleyData.LIFE_MULT
		_dmg[i] = dmg
		_rad[i] = float(v["radius"])
		_curve[i] = float(v.get("curve", 0.0)) if pattern == "spiral" else 0.0
		_homing[i] = float(v.get("homing", 0.0)) if pattern == "seek" else 0.0
		_pierce[i] = int(v["pierce"])
		_vid[i] = vid
		_style[i] = style
		_col[i] = v["color"]
		_src[i] = source
		var tt: Enemy = targets[k % targets.size()] if pattern == "seek" and not targets.is_empty() else null
		_target[i] = tt
		_target_gen[i] = tt.generation if tt != null else 0
		_last_hit[i] = null
		alive += 1
	shots_fired += n
	peak_alive = maxi(peak_alive, alive)
	if _has_flash_art:
		var at := aim if pattern == "rain" else from  # The rain flashes where it lands.
		_burst(1, at, minf(VolleyData.FLASH_MAX, VolleyData.FLASH_BASE + VolleyData.FLASH_PER_SHOT * float(n)), v["color"])


## Up to `n` enemies nearest to `from` (within the spell range), `first` first if given.
func _nearest(from: Vector2, n: int, first: Enemy) -> Array:
	game.enemy_grid.query(from, VolleyData.SPELL_RANGE, _tmp)
	var list: Array = []
	for e: Enemy in _tmp:
		if e.active and not e.is_structure and e != first:
			list.append(e)
	list.sort_custom(func(a: Enemy, b: Enemy) -> bool: return from.distance_squared_to(a.position) < from.distance_squared_to(b.position))
	if first != null and first.active:
		list.push_front(first)
	return list.slice(0, n)


# =====================================================================================
# Hits
# =====================================================================================

## Contact test of shot `i` against the enemies around it; damages what it touches.
func _collide(i: int) -> void:
	var p := _pos[i]
	var r := _rad[i]
	game.enemy_grid.query(p, r + VolleyData.MAX_BODY, _tmp)
	for e: Enemy in _tmp:
		if not e.active or e == _last_hit[i]:
			continue
		if e.position.distance_to(p) > e.radius + r:
			continue
		if e.kit != null and e.shield_blocks(_vel[i], _dmg[i]):
			_kill(i)  # Act III, the Scrap Wastes: an Aegis Bot's frontal shield stops it.
			return
		if e.is_boss or e.is_miniboss:
			var vid := _vid[i]
			if _boss_hits[vid] >= VolleyData.BOSS_HITS_PER_VOLLEY:
				boss_hits_capped += 1
				_kill(i)  # The shot is spent on the boss, harmlessly.
				return
			_boss_hits[vid] += 1
		var key := _src[i]
		var dealt := game.combat.damage_enemy(e, _dmg[i], key)
		hits += 1
		if _has_hit_art:
			_burst(0, p.lerp(e.position, 0.35), clampf(r * VolleyData.DRAW_SCALE * VolleyData.HIT_SIZE, VolleyData.HIT_MIN, VolleyData.HIT_MAX), _col[i])
		var cls := String(SynergyData.SOURCE_CLASS.get(key, key))  # Class (or spell) the damage counts for.
		dmg_by[cls] = float(dmg_by.get(cls, 0.0)) + dealt
		_last_hit[i] = e
		if _pierce[i] <= 0:
			_kill(i)
			return
		_pierce[i] -= 1


## Frees shot slot `i`.
func _kill(i: int) -> void:
	_life[i] = 0.0
	_target[i] = null
	_last_hit[i] = null
	_free.append(i)
	alive -= 1


## Records one burst (drawing only; kind 0 impact, 1 launch flash) in the ring buffer.
func _burst(kind: int, at: Vector2, size: float, col: Color) -> void:
	var j := _fx_next  # Slot written (the oldest burst).
	_fx_next = (_fx_next + 1) % VolleyData.FX_CAP
	_fx_pos[j] = at
	_fx_t0[j] = game.elapsed
	_fx_size[j] = size
	_fx_col[j] = col
	_fx_kind[j] = kind
	_fx_until = maxf(_fx_until, game.elapsed + maxf(VolleyData.HIT_TIME, VolleyData.FLASH_TIME))


## Bursts still playing now (MonitorProbe; drawing statistics only).
func burst_count() -> int:
	if game == null or game.elapsed >= _fx_until:
		return 0
	var n := 0
	for j in VolleyData.FX_CAP:
		var t0 := _fx_t0[j]
		if t0 >= 0.0 and game.elapsed - t0 < maxf(VolleyData.HIT_TIME, VolleyData.FLASH_TIME):
			n += 1
	return n


## Clears every shot and burst (run end).
func clear() -> void:
	for i in VolleyData.SHOT_CAP:
		if _life[i] > 0.0:
			_kill(i)
	_fx_t0.fill(-1.0)
	_fx_until = 0.0
	queue_redraw()


# =====================================================================================
# Drawing (cosmetic; never read by gameplay)
# =====================================================================================

func _draw() -> void:
	if not on:
		return
	var tier := AdaptiveQuality.tier()  # Visual tier (Effects setting / adaptive quality; drawing only).
	var view := _view_rect()  # Local rect on screen (+ margin): shots and bursts outside it are not drawn.
	_draw_bursts(tier, view)
	if alive == 0:
		return
	var cap: int = EffectsData.TIER_SHOTS[tier]  # Most shots drawn this frame.
	var drawn := 0
	_order.resize(0)
	for i in VolleyData.SHOT_CAP:
		if _life[i] <= 0.0:
			continue
		var p := _pos[i]
		if not view.has_point(p):
			continue  # Off screen: nothing to see (it still flies and hits).
		drawn += 1
		if drawn > cap:
			break
		var st := _style[i]  # Style index.
		var tex: Texture2D = _art[st] if st < _art.size() else null  # Its mask, or null.
		if tex != null:
			_order.append((st << 16) | i)  # Drawn below, grouped by mask (one batch each).
			continue
		var v := _vel[i]
		var c := _col[i]
		var r := _rad[i] * VolleyData.DRAW_SCALE  # Drawn size (px).
		var dir := v.normalized() if v.length() > 0.01 else Vector2.RIGHT
		var style := STYLES[st]  # Look of this shot.
		var tail := p - v * (VolleyData.TRAIL / 60.0)  # Trail start.
		var glow := Color(c, VolleyData.GLOW_ALPHA)
		var core := Color(c, VolleyData.CORE_ALPHA)
		match style:
			"shard":
				draw_line(tail, p, glow, r * 1.6)
				draw_line(p - dir * r * 2.2, p + dir * r * 0.8, core, maxf(1.5, r * 0.7))
			"dagger":
				draw_line(tail, p, glow, r * 1.4)
				draw_line(p - dir * r * 2.6, p + dir * r * 1.4, core, 2.0)
				draw_circle(p + dir * r * 1.4, 1.2, Color(1, 1, 1, 0.85))
			"wave":
				var side := dir.orthogonal()
				draw_line(p - side * r * 1.6, p + side * r * 1.6, glow, r * 0.9)
				draw_line(p - side * r * 1.3 + dir * 2.0, p + side * r * 1.3 + dir * 2.0, core, 3.0)
			"note":
				draw_circle(p, r * VolleyData.GLOW, glow)
				draw_arc(p, r, dir.angle() - 1.2, dir.angle() + 1.2, 8, core, 2.0)
			_:  # "orb", "spark", "feather".
				draw_line(tail, p, glow, r * 1.5)
				draw_circle(p, r * VolleyData.GLOW * 0.75, glow)
				draw_circle(p, r * 0.8, core)
				if style == "spark":
					draw_circle(p, r * 0.35, Color(1, 1, 1, 0.8))
	if not _order.is_empty():
		_draw_art_shots(bool(EffectsData.TIER_SHOT_GLOW[tier]))


## Draws the shots listed in _order from their tint masks: first every soft glow
## (one disc texture, so all of them batch into one draw call; a draw_circle is a
## polygon and a draw call of its own), then the masks grouped by style (one batch
## per mask texture), each rotated along its flight path (pointing right in the
## file), its head on the shot, tinted with the shot's colour lightened toward
## white. The node blends additively, so drawing all glows before all masks gives
## the same picture as glow-then-mask per shot.
func _draw_art_shots(glows: bool) -> void:
	_order.sort()  # By style, then slot.
	if glows and _disc != null:
		for key in _order:
			var i := key & 0xFFFF  # Slot.
			var gr := minf(_rad[i] * VolleyData.DRAW_SCALE * VolleyData.ART_GLOW, VolleyData.ART_GLOW_MAX)  # Glow radius (px).
			draw_texture_rect(_disc, Rect2(_pos[i] - Vector2(gr, gr), Vector2(gr, gr) * 2.0), false, Color(_col[i], VolleyData.ART_GLOW_ALPHA))
	for key in _order:
		var i := key & 0xFFFF
		var st := key >> 16
		var tex: Texture2D = _art[st]
		var v := _vel[i]
		var dir := v.normalized() if v.length() > 0.01 else Vector2.RIGHT
		var r := _rad[i] * VolleyData.DRAW_SCALE  # Drawn size (px).
		var w := float(tex.get_width())  # Mask width (px).
		var h := float(tex.get_height())  # Mask height (px).
		var k := r * _art_len[st] / maxf(w, h)  # Mask px -> world px.
		var size := Vector2(w, h) * k  # Drawn size (px).
		var c := _col[i]
		draw_set_transform(_pos[i] - dir * size.x * VolleyData.ART_LEAD, dir.angle(), Vector2.ONE)
		draw_texture_rect(tex, Rect2(-size * 0.5, size), false, Color(c.lerp(Color.WHITE, VolleyData.ART_WHITEN), VolleyData.ART_ALPHA))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## This node's rect on screen (local px, = world px), grown by VolleyData.DRAW_MARGIN.
func _view_rect() -> Rect2:
	var inv := get_global_transform_with_canvas().affine_inverse()  # Screen -> local.
	return (inv * get_viewport_rect()).grow(VolleyData.DRAW_MARGIN)


## The glow disc: a white circle (alpha 1 inside, a one-texel soft rim) on a clear
## VolleyData.DISC_PX square, drawn tinted. Made once per director (drawing only).
static func _make_disc() -> Texture2D:
	var n := VolleyData.DISC_PX  # Texture size (px).
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	var c := (float(n) - 1.0) * 0.5  # Centre (texel).
	var rad := float(n) * 0.5 - 0.5  # Radius (texels).
	for y in n:
		for x in n:
			var d := Vector2(float(x) - c, float(y) - c).length()
			img.set_pixel(x, y, Color(1.0, 1.0, 1.0, clampf(rad - d + 0.5, 0.0, 1.0)))
	return ImageTexture.create_from_image(img)


## Draws the impact bursts and launch flashes still playing on screen, at most
## EffectsData.TIER_BURSTS of the visual tier: all impacts first, then all flashes
## (one strip texture each, so each pass batches; additive, so the order does not
## change the picture), oldest first within each.
func _draw_bursts(tier: int, view: Rect2) -> void:
	if game.elapsed >= _fx_until:
		return
	var cap: int = EffectsData.TIER_BURSTS[tier]  # Most bursts drawn.
	var drawn := 0
	for kind in 2:  # 0 = impacts (HIT_ANIM), 1 = launch flashes (FLASH_ANIM).
		var hit := kind == 0
		var dur := VolleyData.HIT_TIME if hit else VolleyData.FLASH_TIME  # Burst length (s).
		for n in VolleyData.FX_CAP:
			var j := (_fx_next + n) % VolleyData.FX_CAP  # Oldest first.
			var t0 := _fx_t0[j]
			if t0 < 0.0 or _fx_kind[j] != kind:
				continue
			var prog := (game.elapsed - t0) / dur  # 0..1 through the strip.
			if prog >= 1.0 or prog < 0.0 or not view.has_point(_fx_pos[j]):
				continue
			drawn += 1
			if drawn > cap:
				return
			var c := _fx_col[j].lerp(Color.WHITE, VolleyData.ART_WHITEN) if hit else _fx_col[j]  # Impacts burn hot, flashes keep the class colour.
			SpriteBank.draw_anim(self, VolleyData.HIT_ANIM if hit else VolleyData.FLASH_ANIM, _fx_pos[j], _fx_size[j], prog,
					VolleyData.HIT_ALPHA if hit else VolleyData.FLASH_ALPHA, c)


# =====================================================================================
# Autotest
# =====================================================================================

## One-line summary for the autotest: shots, hits, peak, cap use and the volley damage
## by class / spell (largest first).
func summary_line() -> String:
	if not on:
		return "off"
	var keys := dmg_by.keys()
	keys.sort_custom(func(a: String, b: String) -> bool: return float(dmg_by[a]) > float(dmg_by[b]))
	var parts := PackedStringArray()
	var total := 0.0
	for k: String in keys:
		total += float(dmg_by[k])
	for k: String in keys.slice(0, 8):
		parts.append("%s %d" % [k, int(dmg_by[k])])
	return "shots %d | hits %d | dmg %d | peak %d/%d | capped volleys %d | boss hits capped %d | barrages %d | %s" % [
		shots_fired, hits, int(total), peak_alive, VolleyData.SHOT_CAP, capped_volleys, boss_hits_capped, barrages,
		", ".join(parts)]
