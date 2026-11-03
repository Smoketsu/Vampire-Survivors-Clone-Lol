## Terraforming — TERRAFORMING, the third of the Concord of Stars' shared rules
## (Act IX; GDD §15.0 "Terraforming"; owner answer Oct 31, 2026: "Alien ground
## spreads across the arena over the run and heals Concord units standing on
## it. The necromancer's spells burn it back"; it replaces the proposal's
## Adaptation). Owned by Game.concord, built like HellPits. THE one path of the
## alien ground:
##   * THE GROUND: a sparse map of `cell` px cells (Vector2i -> [state, game s
##     of the state's start]): GROWING (it shows growing for grow_time s), LIVE
##     (it heals), SCORCHED (burnt: black for regrow_delay s, nothing grows
##     into it, then the cell is bare again). Deterministic: the map is only
##     changed in this order by game events. Only cells within active_radius of
##     a standing necromancer are drawn and simulated (pods there grow, units
##     there heal); at most max_cells live or growing cells (the oldest go
##     first).
##   * WHERE IT COMES FROM: "concord_terraformer" landing pods. On an Act IX
##     stage (`enabled`), every pod_every s (shorter each minute, down to
##     pod_every_min) a pod falls on a telegraphed streak (pod_warn s) at a
##     seeded point pod_min..pod_max px from a standing necromancer (the seeded
##     gameplay RNG, Act IX only), at most max_pods alive (pending included).
##     A live pod (ConcordTerraformerKit registers it: add_pod()) grows its
##     patch by one ring of cells every spread_every s, up to pod_radius. A
##     destroyed pod stops growing; its ground stays until burnt.
##   * seed(at, radius, opts): THE ONE PUBLIC CALL for phase 2 (the Hive
##     Mother's crater, the Ark's vents): grows every bare cell within `radius`
##     px of `at` at once (opts "live": true skips the growing look; "tag":
##     stats).
##   * THE HEAL (every `tick` s): each Concord enemy whose row heals on turf
##     (ConcordKit.heals_on_turf()) standing on a LIVE cell heals heal_frac of
##     its max HP per second through CombatResolver.heal_enemy(e, amount) (no
##     healer, so a silence does not stop it); a boss or miniboss heals at
##     boss_mult (0 by default). The ground does nothing to summons or the
##     necromancer.
##   * THE BURN: burn(pos, r), called only from ConcordRules.on_enemy_hit() (THE
##     one check, burns_ground(): a SPELL hit, at the end of
##     CombatResolver.damage_enemy()): every live or growing cell within `r` px
##     of `pos` is scorched. At most burn_cap burns a tick (a big area spell
##     stays cheap). Nothing else burns the ground, and summons never do.
##   * A green heal shimmer over a healed enemy (drawing only).
## A stage's STAGE "terraforming" dictionary overrides any
## ConcordRulesData.TERRAFORMING key ({} = the defaults). Drawn as textures on
## the ground (z -8: over the floor, under the obstacles and the bodies; the
## `tiles/concord_turf` and `tiles/concord_scorch` tiles when present, else a
## code glyph texture); nothing is drawn headless.
## Stats (the "terraforming" line): terra_pods_landed, terra_pods_destroyed,
## terra_cells_grown, terra_cells_burnt, terra_burns_capped,
## terra_heal_<race>, terra_heals.
class_name Terraforming
extends Node2D

## Cell state: growing (not healing yet).
const GROWING: int = 0
## Cell state: live alien ground (it heals).
const LIVE: int = 1
## Cell state: scorched (burnt; nothing grows into it until it clears).
const SCORCHED: int = 2
## Sprite key of the live turf tile (the art pass; a centre piece).
const TURF_ART: String = "tiles/concord_turf"
## Sprite key of the scorched tile (the art pass).
const SCORCH_ART: String = "tiles/concord_scorch"

## Owning run.
var game: Game
## True on an Act IX stage: the pods fall (a forced kind elsewhere: the map
## only grows through seed(), and units still heal on any of it).
var enabled: bool = false
## The ground's numbers (ConcordRulesData.TERRAFORMING, then the stage's
## "terraforming" overrides).
var cfg: Dictionary = {}
## The ground: Vector2i cell -> [state (GROWING / LIVE / SCORCHED), game s the
## state began]. Insertion order = growth order (the oldest first).
var cells: Dictionary = {}
## Live pods: each [pod Enemy, its generation, its centre cell (Vector2i), the
## ring it reached, game s of its next ring].
var pods: Array = []
## Pods falling: each [landing point (Vector2), game s it lands, game s it was
## announced].
var falling: Array = []
## Live or growing cells now (cells minus scorched ones).
var live_count: int = 0
## Most live or growing cells at once this run.
var peak_live: int = 0
## Pods landed this run.
var pods_landed: int = 0
## Pods destroyed this run.
var pods_destroyed: int = 0
## Cells grown this run.
var cells_grown: int = 0
## Cells burnt this run.
var cells_burnt: int = 0
## HP healed on the turf this run, by race id.
var healed_by_race: Dictionary = {}
## Game time (s) of the next pod.
var _next_pod: float = INF
## Seconds toward the next heal tick.
var _tick_acc: float = 0.0
## Burns left this tick (burn_cap, refilled each step).
var _burns_left: int = 0
## Healed enemy -> game s of its last heal (the shimmer; drawing only).
var _shimmer: Dictionary = {}
## The code glyph's turf / scorch textures (made on first use; drawing only).
static var _glyph_tex: Dictionary = {}
## True when this build draws (never headless).
var _draws: bool = false
## True if the last redraw showed something.
var _drawn: bool = false


## Builds the ground for `p_game` (ConcordRules adds it as its child);
## `p_enabled`: an Act IX stage (the pods fall).
func _init(p_game: Game, p_enabled: bool) -> void:
	game = p_game
	enabled = p_enabled
	name = "Terraforming"
	z_index = -8  # Over the floor (-10), under the obstacles (-6) and the bodies (as HellPits).
	z_as_relative = false
	cfg = ConcordRulesData.TERRAFORMING.duplicate()
	var over: Dictionary = p_game.stage_def.get("terraforming", {})  # The stage's own overrides.
	for key: String in over:
		cfg[key] = over[key]
	_next_pod = float(cfg["start_at"]) if enabled else INF
	_draws = DisplayServer.get_name() != "headless"


# =====================================================================================
# Public API
# =====================================================================================

## The cell (Vector2i) of world point `p`.
func cell_of(p: Vector2) -> Vector2i:
	var c := float(cfg["cell"])
	return Vector2i(floori(p.x / c), floori(p.y / c))


## World centre of cell `c`.
func cell_centre(c: Vector2i) -> Vector2:
	var s := float(cfg["cell"])
	return Vector2((float(c.x) + 0.5) * s, (float(c.y) + 0.5) * s)


## True when world point `p` stands on a LIVE cell.
func live_at(p: Vector2) -> bool:
	var c := cell_of(p)
	return cells.has(c) and int((cells[c] as Array)[0]) == LIVE


## THE ONE PUBLIC CALL for phase 2 (the Hive Mother's crater, the Ark's vents):
## grows every bare cell within `radius` px of `at` (opts "live": true = live at
## once, no growing look). Returns the cells grown.
func seed(at: Vector2, radius: float, opts: Dictionary = {}) -> int:
	var n := _grow_disc(at, radius, bool(opts.get("live", false)))
	game.stat_add("terra_seeded_" + String(opts.get("tag", "seed")), float(n))
	return n


## A landing pod `e` rooted (ConcordTerraformerKit.reset()): it grows from its
## centre cell, the first ring at once.
func add_pod(e: Enemy) -> void:
	pods.append([e, e.generation, cell_of(e.position), 0, game.elapsed])
	pods_landed += 1
	game.stat_add("terra_pods_landed", 1.0)


## A landing pod `e` was destroyed (ConcordTerraformerKit.on_killed()): it
## stops growing; its ground stays until burnt.
func pod_destroyed(e: Enemy) -> void:
	pods_destroyed += 1
	game.stat_add("terra_pods_destroyed", 1.0)
	_drop_pod(e)


## THE BURN (ConcordRules.on_enemy_hit(), the one check): every live or growing
## cell within `r` px of `pos` is scorched. At most burn_cap burns a tick.
func burn(pos: Vector2, r: float) -> void:
	if live_count <= 0:
		return
	if _burns_left <= 0:
		game.stat_add("terra_burns_capped", 1.0)
		return
	_burns_left -= 1
	var s := float(cfg["cell"])
	var c0 := cell_of(pos - Vector2(r, r))
	var c1 := cell_of(pos + Vector2(r, r))
	var burnt := 0
	for cy in range(c0.y, c1.y + 1):
		for cx in range(c0.x, c1.x + 1):
			var c := Vector2i(cx, cy)
			if not cells.has(c):
				continue
			var st: Array = cells[c]
			if int(st[0]) == SCORCHED:
				continue
			# The cell's nearest point to the burn (a cell touched by the circle burns).
			var lo := Vector2(float(cx) * s, float(cy) * s)
			var q := Vector2(clampf(pos.x, lo.x, lo.x + s), clampf(pos.y, lo.y, lo.y + s))
			if q.distance_to(pos) > r:
				continue
			cells[c] = [SCORCHED, game.elapsed]
			live_count -= 1
			burnt += 1
	if burnt > 0:
		cells_burnt += burnt
		game.stat_add("terra_cells_burnt", float(burnt))
		if game.concord != null:
			game.concord.play_sound("ground_burn", pos, 0.3)
		if _draws:
			queue_redraw()


# =====================================================================================
# Per tick
# =====================================================================================

## Per-tick update (ConcordRules.step()): new pods, landings, the pods' rings,
## cleared scorch, then the heal.
func step(delta: float) -> void:
	var now := game.elapsed
	_burns_left = int(cfg["burn_cap"])
	if enabled and now >= _next_pod:
		_next_pod = now + _pod_interval()
		_announce_pod()
	var i := 0
	while i < falling.size():
		var f: Array = falling[i]
		if now >= float(f[1]):
			falling.remove_at(i)
			_land_pod(f[0] as Vector2)
			continue
		i += 1
	_grow_pods(now)
	_clear_scorch(now)
	_tick_acc += delta
	var tick := float(cfg["tick"])
	if _tick_acc >= tick:
		_tick_acc -= tick
		_heal(tick)
	if _draws:
		var busy := not cells.is_empty() or not falling.is_empty()
		if busy or _drawn:
			queue_redraw()
		_drawn = busy


## Seconds until the next pod: pod_every, shorter each minute, down to pod_every_min.
func _pod_interval() -> float:
	var mins := game.elapsed / 60.0
	return maxf(float(cfg["pod_every_min"]), float(cfg["pod_every"]) - float(cfg["pod_every_step"]) * mins)


## A pod is announced: a telegraphed streak at a seeded point pod_min..pod_max
## px from a standing necromancer (the seeded gameplay RNG), unless max_pods
## are alive or falling.
func _announce_pod() -> void:
	var standing: Array[Necromancer] = []
	for pl in game.all_players:
		if not pl.dead:
			standing.append(pl)
	if standing.is_empty():
		return
	_prune_pods()
	if pods.size() + falling.size() >= int(cfg["max_pods"]):
		game.stat_add("terra_pods_refused", 1.0)
		return
	var pl: Necromancer = standing[randi() % standing.size()]
	var a := randf() * TAU
	var dist := randf_range(float(cfg["pod_min"]), float(cfg["pod_max"]))
	var r := float(ConcordEnemyData.ENEMIES[ConcordEnemyData.TERRAFORMER]["radius"])
	var at := game.arena.free_point(pl.position + Vector2.from_angle(a) * dist, r)
	var warn := float(cfg["pod_warn"])
	falling.append([at, game.elapsed + warn, game.elapsed])
	game.effects.telegraph_circle(at, r * 2.0, warn)


## A pod lands at `at`: the terraformer structure is spawned (its kit roots it).
func _land_pod(at: Vector2) -> void:
	var e := game.enemies.spawn_at(ConcordEnemyData.TERRAFORMER, at, false)
	if e != null:
		game.effects.ring(at, 40.0, Palette.CONCORD_PLASMA, 0.4)
		game.shake(2.0)


## Drops dead or pooled pods from the growing list (each counted once by its kit).
func _prune_pods() -> void:
	var i := 0
	while i < pods.size():
		var p: Array = pods[i]
		var e: Enemy = p[0]
		if not e.active or e.generation != int(p[1]):
			pods.remove_at(i)
			continue
		i += 1


## Removes pod `e` from the growing list.
func _drop_pod(e: Enemy) -> void:
	var i := 0
	while i < pods.size():
		if (pods[i] as Array)[0] == e:
			pods.remove_at(i)
			continue
		i += 1


## Every live pod near a standing necromancer grows one more ring of cells
## every spread_every s, up to pod_radius px.
func _grow_pods(now: float) -> void:
	_prune_pods()
	var s := float(cfg["cell"])
	var max_ring := int(ceilf(float(cfg["pod_radius"]) / s))
	for p: Array in pods:
		if now < float(p[4]) or int(p[3]) > max_ring:
			continue
		var e: Enemy = p[0]
		if not _near_player(e.position):
			continue  # Out of the live window: it waits.
		p[4] = now + float(cfg["spread_every"])
		var ring := int(p[3])
		p[3] = ring + 1
		_grow_disc(e.position, minf(float(ring) * s + s * 0.5, float(cfg["pod_radius"])), false)


## Grows every bare cell whose centre lies within `radius` px of `at` (a
## scorched cell stays scorched). `live`: no growing look. Returns the cells
## grown. Keeps the live count under max_cells (the oldest go first).
func _grow_disc(at: Vector2, radius: float, live: bool) -> int:
	var c0 := cell_of(at - Vector2(radius, radius))
	var c1 := cell_of(at + Vector2(radius, radius))
	var n := 0
	for cy in range(c0.y, c1.y + 1):
		for cx in range(c0.x, c1.x + 1):
			var c := Vector2i(cx, cy)
			if cells.has(c) or cell_centre(c).distance_to(at) > radius:
				continue
			cells[c] = [LIVE if live else GROWING, game.elapsed]
			live_count += 1
			n += 1
	if n > 0:
		cells_grown += n
		game.stat_add("terra_cells_grown", float(n))
		_trim()
		peak_live = maxi(peak_live, live_count)
	return n


## Keeps at most max_cells live or growing cells: the oldest go first.
func _trim() -> void:
	var excess := live_count - int(cfg["max_cells"])
	if excess <= 0:
		return
	var drop: Array[Vector2i] = []
	for c: Vector2i in cells:
		if excess <= 0:
			break
		if int((cells[c] as Array)[0]) != SCORCHED:
			drop.append(c)
			excess -= 1
	for c in drop:
		cells.erase(c)
		live_count -= 1


## Growing cells go live after grow_time s; scorched cells clear after
## regrow_delay s (the cell is bare again).
func _clear_scorch(now: float) -> void:
	var grow := float(cfg["grow_time"])
	var regrow := float(cfg["regrow_delay"])
	var gone: Array[Vector2i] = []
	for c: Vector2i in cells:
		var st: Array = cells[c]
		var state := int(st[0])
		if state == GROWING and now - float(st[1]) >= grow:
			st[0] = LIVE
		elif state == SCORCHED and now - float(st[1]) >= regrow:
			gone.append(c)
	for c in gone:
		cells.erase(c)


## True when `p` is within active_radius of a standing necromancer.
func _near_player(p: Vector2) -> bool:
	var reach := float(cfg["active_radius"])
	for pl in game.all_players:
		if not pl.dead and pl.position.distance_to(p) <= reach:
			return true
	return false


## THE HEAL: every Concord enemy that heals on turf, near a standing
## necromancer and on a live cell, heals heal_frac of its max HP per second
## (boss_mult for a boss or miniboss) through CombatResolver.heal_enemy().
func _heal(tick: float) -> void:
	if live_count <= 0:
		return
	var frac := float(cfg["heal_frac"]) * tick
	var boss := float(cfg["boss_mult"])
	for e in game.enemies.active:
		if not e.active or not (e.kit is ConcordKit) or e.hp >= e.max_hp:
			continue
		var k := e.kit as ConcordKit
		if not k.heals_on_turf() or not live_at(e.position) or not _near_player(e.position):
			continue
		var amount := e.max_hp * frac * (boss if (e.is_boss or e.is_miniboss) else 1.0)
		if amount <= 0.0:
			continue
		var healed := game.combat.heal_enemy(e, amount)
		if healed > 0.0:
			var race := k.race()
			healed_by_race[race] = float(healed_by_race.get(race, 0.0)) + healed
			game.stat_add("terra_heals", 1.0)
			game.stat_add("terra_heal_" + race, healed)
			if _draws:
				_shimmer[e] = game.elapsed


# =====================================================================================
# Drawing (visual only; never headless)
# =====================================================================================

## Draws the falling pods' streaks, every cell in view (growing: fading in;
## live: the turf; scorched: black, fading as it clears) and the heal
## shimmers.
func _draw() -> void:
	var now := game.elapsed
	var s := float(cfg["cell"])
	var view := Rect2(game.player.position - Vector2(1400, 900), Vector2(2800, 1800))  # Generous: co-op and zoom.
	var turf := SpriteBank.texture(TURF_ART)
	var scorch := SpriteBank.texture(SCORCH_ART)
	for c: Vector2i in cells:
		var lo := Vector2(float(c.x) * s, float(c.y) * s)
		if not view.has_point(lo):
			continue
		var st: Array = cells[c]
		var state := int(st[0])
		var rect := Rect2(lo, Vector2(s, s))
		match state:
			GROWING:
				var k := clampf((now - float(st[1])) / maxf(float(cfg["grow_time"]), 0.01), 0.0, 1.0)
				draw_texture_rect(turf if turf != null else glyph_texture(false), rect.grow(-s * 0.3 * (1.0 - k)), false, Color(1, 1, 1, 0.4 + 0.5 * k))
			LIVE:
				var pulse := 0.92 + 0.08 * sin(now * 1.6 + float(c.x * 7 + c.y * 3))  # The flesh breathes.
				draw_texture_rect(turf if turf != null else glyph_texture(false), rect, false, Color(pulse, pulse, pulse, 1.0))
			_:
				var left := float(cfg["regrow_delay"]) - (now - float(st[1]))  # s until it clears.
				var a := clampf(left / maxf(float(cfg["scorch_fade"]), 0.01), 0.0, 1.0)
				draw_texture_rect(scorch if scorch != null else glyph_texture(true), rect, false, Color(1, 1, 1, a))
	for f: Array in falling:
		var at: Vector2 = f[0]
		var k := clampf((now - float(f[2])) / maxf(float(f[1]) - float(f[2]), 0.01), 0.0, 1.0)  # 0 announced .. 1 lands.
		var top := at + Vector2(-180.0, -420.0) * (1.0 - k)  # The pod streaks in from the sky.
		ConcordGlyphs.draw_streak(self, top, at, k)
	var rise := float(cfg["shimmer_rise"])
	var life := float(cfg["shimmer_time"])
	var stale: Array = []
	for e: Enemy in _shimmer:
		var age := now - float(_shimmer[e])
		if age > life or not e.active:
			stale.append(e)
			continue
		var a2 := 1.0 - age / life
		SpriteBank.draw_disc(self, e.position + Vector2(0.0, -e.radius - rise * (age / life)), 3.0, Color(Palette.CONCORD_PLASMA, 0.8 * a2))
		SpriteBank.draw_disc(self, e.position + Vector2(e.radius * 0.6, -e.radius * 0.5 - rise * (age / life)), 2.0, Color(Palette.CONCORD_PLASMA, 0.6 * a2))
	for e in stale:
		_shimmer.erase(e)


## The code glyph's cell texture (16 x 16, made once): the alien flesh turf
## (veined purple with green spores) or the scorched char.
static func glyph_texture(scorched: bool) -> Texture2D:
	var key := "scorch" if scorched else "turf"
	if _glyph_tex.has(key):
		return _glyph_tex[key]
	var n := 16
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	for y in n:
		for x in n:
			var h := (x * 73 + y * 151 + x * y * 7) % 23  # A fixed texel pattern (no RNG).
			var col: Color
			if scorched:
				col = Palette.CONCORD_TURF_DARK.darkened(0.3 if h < 6 else 0.0)
				col.a = 0.9
			else:
				col = Palette.CONCORD_TURF
				if h < 3:
					col = Palette.CONCORD_PLASMA_DARK  # A spore.
				elif h < 9:
					col = Palette.CONCORD_TURF.darkened(0.25)  # A vein.
				var edge := mini(mini(x, y), mini(n - 1 - x, n - 1 - y))  # Texels from the border.
				col.a = 0.85 if edge > 0 else 0.6
			img.set_pixel(x, y, col)
	var tex := ImageTexture.create_from_image(img)
	_glyph_tex[key] = tex
	return tex
