## ValgardDirector — the stage systems of Valgard, the Hall of Heroes (Stage 17
## in the final order; the Hall of the Slain, temporarily Act XI; GDD §15.0
## "Valgard, the Hall of Heroes (the Hall of the Slain phase 2)"; the act's
## section "Stage 17: Valgard, the Hall of Heroes" of
## docs/proposals/LAST_SIX_ACTS.md), owned and stepped by EnemyDirector on a
## stage whose STAGE has a "valgard" config (ValgardStage.VALGARD; null
## elsewhere). The zones are MarchDirector's (the looks: ValgardGround); the
## Long Winter, Berserkergang, the Rune-Stones and Ragnarök are the shared
## NorseRules'. Here:
##   * THE FEAST (owner-approved proposal: "Einherjar sit at the long tables as
##     obstacles that wake whenever a horn blows, then fight"): every
##     long_table obstacle of the arena seats per_table Einherjar (drawn here,
##     behind the table; no body, nothing to hit). wake_feast() is THE wake:
##     the tables within wake_reach px of a point, nearest first, give up their
##     seated heroes (ValgardEnemyData "einherjar", gold through
##     EinherjarKit / NorseKit.make_einherjar()), at most the zone's
##     wake_by_zone and never past the hard cap less cap_margin; an emptied
##     table is full again reseat_time s later. Three callers: every horn of a
##     Rune-Stone the hall holds (RuneStones.horn_blown, wake around the
##     necromancer), the Einherjar Champion's horn (EinherjarChampionKit) and
##     Sigrun's Doors of the Hall (BossSigrun, doors_wake).
##   * THE EINHERJAR CHAMPION ("einherjar_champion" event): the stage miniboss,
##     brought in on the spawn ring with an escort of Einherjar, tracked
##     (objective, kill time); his kit registers him on the HUD's miniboss bar.
##   * THE HALL'S HEARTHS (the Long Winter's braziers by the map): the hall's
##     long hearths repeat on a lattice of hearth_spacing px (each one
##     hearth_jitter px off its point, seeded by its lattice cell); every
##     lattice hearth within hearth_reach px of a necromancer is lit once
##     (LongWinter.place(), THE brazier call) unless a brazier already burns
##     within hearth_min_gap px (hearth_max at most in a run). The start's
##     hearths are the STAGE's long_winter "points".
##   * The HUD objective while the Champion stands.
## Seat states are keyed by the table's arena cell and the zone (a zone change
## rebuilds the obstacles), read from the arena's deterministic per-cell
## layout. Deterministic: the seeded arena layout and the global RNG only
## (where the Champion comes in); the seated figures are drawing only.
## Stats: valgard_hearths, feast_wakes, feast_woken, feast_woken_<cause>, feast_tables_emptied,
## feast_capped, valgard_champion_spawned, valgard_champion_killed.
class_name ValgardDirector
extends Node2D

## Kind id of the Feast's tables (ValgardStage.LONG_TABLE's obstacle kind).
const TABLE_KIND: String = "long_table"
## Sprite key of a seated hero (the art pass's Einherjar).
const SEAT_SPRITE: String = "norse/einherjar"
## Art px of the seated hero's sprite drawn above the table (head and chest).
const SEAT_CROP: float = 32.0  # TUNING (not in GDD) visual only
## Colour a seated, sleeping hero is drawn in (a dim gold-lit look).
const SEAT_TINT: Color = Color(0.78, 0.72, 0.62)  # TUNING (not in GDD) visual only

## Owning run.
var game: Game
## The stage's config (ValgardStage.VALGARD).
var config: Dictionary = {}
## Log of Valgard events, "m:ss name" (autotest summary).
var fired: Array[String] = []
## "m:ss" the Champion fell ("" while alive / never spawned).
var champion_time: String = ""
## Horns of the Rune-Stones heard (each one a wake).
var horns_heard: int = 0
## Table seat state: Vector3i(cell x, cell y, zone) -> game time (s) it was
## emptied (absent = full).
var _emptied: Dictionary = {}
## The Champion once spawned (null before / after; generation-checked).
var _champ: Enemy = null
## Generation of `_champ` when he spawned.
var _champ_gen: int = 0
## Hearth lattice cells already looked at (Vector2i -> true).
var _hearths: Dictionary = {}
## Seconds until the next hearth check.
var _hearth_cd: float = 0.0
## True once connected to the Rune-Stones' horn.
var _listening: bool = false
## True when this build draws (never headless).
var _draws: bool = false
## The seated heroes' drawing layer (a child of the Game, not of the y-sorted
## EnemyDirector, so its z_index puts it between the floor and the tables;
## null headless and before the first step).
var _layer: Node2D = null
## Arena redraw cell the seats were last drawn around.
var _drawn_cell: Vector2i = Vector2i(1 << 30, 1 << 30)
## Zone the seats were last drawn for.
var _drawn_zone: int = -1


func _ready() -> void:
	name = "ValgardDirector"
	_draws = DisplayServer.get_name() != "headless"


## Per-tick update (EnemyDirector, after the MarchDirector).
func step(_delta: float) -> void:
	if not _listening and game.norse != null:
		_listening = true
		game.norse.stones.horn_blown.connect(_on_horn)
	_hearth_cd -= _delta
	if _hearth_cd <= 0.0 and game.norse != null and game.norse.winter.enabled and not game.norse.winter.braziers.is_empty():
		_hearth_cd = 1.0
		for pl in game.all_players:
			_light_hearths(pl.position)
	if _champ != null and not (_champ.active and _champ.generation == _champ_gen):
		_champ = null
		game.stat_add("valgard_champion_killed", 1.0)
		champion_time = _clock()
		_log("champion_down")
	if _draws and _layer == null:
		_layer = Node2D.new()
		_layer.name = "FeastSeats"
		_layer.z_index = -7  # The seated heroes sit between the floor (-10) and the tables (-6): the table hides their legs.
		_layer.z_as_relative = false
		_layer.draw.connect(_draw_seats)
		game.add_child(_layer)
	if _draws:
		var c := Vector2i(floori(game.player.position.x / ArenaData.REDRAW_CELL), floori(game.player.position.y / ArenaData.REDRAW_CELL))
		if c != _drawn_cell or _zone() != _drawn_zone:
			_drawn_cell = c
			_drawn_zone = _zone()
			_layer.queue_redraw()


## THE HALL'S HEARTHS around world point `p` (see the header): each lattice
## cell within hearth_reach px is looked at once; its hearth is lit unless a
## brazier already burns near it.
func _light_hearths(p: Vector2) -> void:
	var step := float(config["hearth_spacing"])
	var reach := float(config["hearth_reach"])
	var jit := float(config["hearth_jitter"])
	var gap := float(config["hearth_min_gap"])
	var c0 := Vector2i(floori((p.x - reach) / step + 0.5), floori((p.y - reach) / step + 0.5))
	var c1 := Vector2i(floori((p.x + reach) / step + 0.5), floori((p.y + reach) / step + 0.5))
	var w := game.norse.winter
	if int(game.stats.get("valgard_hearths", 0.0)) >= int(config["hearth_max"]):
		return
	for cy in range(c0.y, c1.y + 1):
		for cx in range(c0.x, c1.x + 1):
			var key := Vector2i(cx, cy)
			if _hearths.has(key):
				continue
			var h := absi(hash(Vector3i(cx, cy, 1777)))
			var at := Vector2(float(cx) * step, float(cy) * step)  # The lattice point.
			at += Vector2(float(h % 1000) / 500.0 - 1.0, float((h >> 10) % 1000) / 500.0 - 1.0) * jit
			if at.distance_to(p) > reach:
				continue
			_hearths[key] = true
			var near := false
			for b in w.braziers:
				if b.pos.distance_to(at) < gap:
					near = true
					break
			if near:
				continue
			w.place(at)
			game.stat_add("valgard_hearths", 1.0)
			if int(game.stats.get("valgard_hearths", 0.0)) >= int(config["hearth_max"]):
				return


## A Rune-Stone's horn (RuneStones.horn_blown): the Feast wakes around the
## necromancer the horn blew for.
func _on_horn(_at: Vector2) -> void:
	horns_heard += 1
	var pl := game.nearest_player(_at)
	wake_feast(pl.position if pl != null else game.player.position, _zone_wake(), "horn")


## The current zone's index (0 when no march runs).
func _zone() -> int:
	return game.enemies.march.zone_index if game.enemies.march != null else 0


## Einherjar a horn wakes at most in the current zone.
func _zone_wake() -> int:
	var arr: Array = config["wake_by_zone"]
	return int(arr[clampi(_zone(), 0, arr.size() - 1)])


## THE WAKE (see the header): up to `n` seated Einherjar at the full tables
## within wake_reach px of `at` rise, the nearest tables first; `cause` names
## the caller in the stats ("horn", "champion", "doors"). Returns how many rose.
func wake_feast(at: Vector2, n: int, cause: String) -> int:
	if n <= 0:
		return 0
	var tables := _full_tables(at, float(config["wake_reach"]))
	var per: Array = config["per_table"]
	var woken := 0
	for entry: Array in tables:
		if woken >= n:
			break
		var o: Arena.Obstacle = entry[1]
		var key: Vector3i = entry[2]
		var seats := mini(int(per[clampi(o.size_index, 0, per.size() - 1)]), n - woken)
		var rose := 0
		for s in seats:
			if game.enemies.regular_alive() + int(config["cap_margin"]) >= game.enemies.hard_cap():
				game.stat_add("feast_capped", 1.0)
				break
			if game.enemies.spawn_at(ValgardEnemyData.EINHERJAR, _rise_point(o, at, s, seats), false) != null:
				rose += 1
		if rose == 0:
			break
		woken += rose
		_emptied[key] = game.elapsed
		game.stat_add("feast_tables_emptied", 1.0)
		game.effects.ring(o.center, 46.0, Palette.NORSE_VALKYRIE_GOLD, 0.5)
	if woken > 0:
		game.stat_add("feast_wakes", 1.0)
		game.stat_add("feast_woken", float(woken))
		game.stat_add("feast_woken_" + cause, float(woken))
		if game.norse != null:
			game.norse.play_sound("einherjar_march", at, 1.5)
		if cause == "horn" and game.stats.get("feast_wakes", 0.0) <= 1.0:
			game.enemies.show_banner("The horn wakes the Feast: the Einherjar rise from the long tables!")
		if _layer != null:
			_layer.queue_redraw()
	return woken


## Every FULL table within `reach` px of `at`, nearest first (ties by cell):
## [distance, obstacle, seat key].
func _full_tables(at: Vector2, reach: float) -> Array:
	var out: Array = []
	var cell := ArenaData.CELL
	var c0 := Vector2i(floori((at.x - reach) / cell), floori((at.y - reach) / cell))
	var c1 := Vector2i(floori((at.x + reach) / cell), floori((at.y + reach) / cell))
	var z := _zone()
	var reseat := float(config["reseat_time"])
	for cy in range(c0.y, c1.y + 1):
		for cx in range(c0.x, c1.x + 1):
			var o := game.arena.obstacle_at(Vector2((float(cx) + 0.5) * cell, (float(cy) + 0.5) * cell))
			if o == null or o.kind != TABLE_KIND:
				continue
			var dist := o.center.distance_to(at)
			if dist > reach:
				continue
			var key := Vector3i(cx, cy, z)
			if _emptied.has(key) and game.elapsed - float(_emptied[key]) < reseat:
				continue
			out.append([dist, o, key])
	out.sort_custom(func(a: Array, b: Array) -> bool:
		if float(a[0]) != float(b[0]):
			return float(a[0]) < float(b[0])
		var ka: Vector3i = a[2]
		var kb: Vector3i = b[2]
		return ka.x < kb.x or (ka.x == kb.x and ka.y < kb.y))
	return out


## Where seat `s` of `count` at table `o` steps out: beside the table on the
## side facing `toward`, spread along its long side.
func _rise_point(o: Arena.Obstacle, toward: Vector2, s: int, count: int) -> Vector2:
	var vertical := o.half.y > o.half.x  # A table laid out along y.
	var along := Vector2(0.0, 1.0) if vertical else Vector2(1.0, 0.0)
	var across := Vector2(1.0, 0.0) if vertical else Vector2(0.0, 1.0)
	var side := 1.0 if (toward - o.center).dot(across) >= 0.0 else -1.0
	var depth := (o.half.x if vertical else o.half.y) + float(config["rise_offset"])
	var spread := (float(s) - float(count - 1) * 0.5) * 24.0
	return o.center + across * side * depth + along * spread


## Runs a Valgard timeline event (EnemyDirector forwards the
## "einherjar_champion" type; keys in ValgardStage.EVENTS).
func start_event(ev: Dictionary) -> void:
	match String(ev["type"]):
		"einherjar_champion":
			var a := randf() * TAU
			var at := game.enemies.ring_point(a)
			var e := game.enemies.spawn_at(String(ev.get("kind", ValgardEnemyData.CHAMPION)), at, false)
			if e != null:
				_champ = e
				_champ_gen = e.generation
				game.stat_add("valgard_champion_spawned", 1.0)
				game.shake(4.0)
				if game.norse != null:
					game.norse.play_sound("horn", e.position)
				var side := Vector2.from_angle(a).orthogonal()
				for g: Dictionary in ev.get("escort", []):
					var n := int(g["count"])
					for k in n:
						if game.enemies.regular_alive() >= game.enemies.hard_cap():
							break
						var p := at + side * (float(k) - float(n - 1) * 0.5) * 44.0 - Vector2.from_angle(a) * 60.0
						game.enemies.spawn_at(String(g["kind"]), p, false)
				_log("champion_rises")
	game.enemies.show_banner(String(ev["banner"]))


## HUD objective while the Champion stands ("" otherwise).
func objective_override() -> String:
	if _champ != null:
		return String(config["champion_objective"])
	return ""


## One-line autotest summary.
func summary_line() -> String:
	var st := game.stats
	return "feast: horns heard %d, wakes %d, einherjar woken %d (horn %d, champion %d, doors %d), tables emptied %d, capped %d | champion %s | events %s" % [
		horns_heard, int(st.get("feast_wakes", 0.0)), int(st.get("feast_woken", 0.0)), int(st.get("feast_woken_horn", 0.0)),
		int(st.get("feast_woken_champion", 0.0)), int(st.get("feast_woken_doors", 0.0)), int(st.get("feast_tables_emptied", 0.0)),
		int(st.get("feast_capped", 0.0)),
		("killed at " + champion_time) if champion_time != "" else ("alive" if _champ != null else "not spawned"),
		", ".join(fired) if not fired.is_empty() else "-"]


## Records a Valgard event for the autotest summary.
func _log(event_name: String) -> void:
	fired.append("%s %s" % [_clock(), event_name])


## Elapsed game time as "m:ss".
func _clock() -> String:
	var s := int(game.elapsed)
	return "%d:%02d" % [floori(float(s) / 60.0), s % 60]


# =====================================================================================
# Drawing (visual only; never headless)
# =====================================================================================

## The seated heroes at every full table near the necromancer: the head and
## chest of the art's Einherjar behind the table (the table, one layer up,
## hides the rest), a dim gold light at each seat. Co-op drawing never fills
## the arena's gameplay cache (Arena._peek()). Drawn on `_layer`.
func _draw_seats() -> void:
	var ci := _layer
	var tex := SpriteBank.texture(SEAT_SPRITE)
	var p := game.player.position
	var reach := float(config["seat_scan"])
	var cell := ArenaData.CELL
	var coop := game.coop != null
	var c0 := Vector2i(floori((p.x - reach) / cell), floori((p.y - reach) / cell))
	var c1 := Vector2i(floori((p.x + reach) / cell), floori((p.y + reach) / cell))
	var z := _zone()
	var reseat := float(config["reseat_time"])
	var per: Array = config["per_table"]
	for cy in range(c0.y, c1.y + 1):
		for cx in range(c0.x, c1.x + 1):
			var at := Vector2((float(cx) + 0.5) * cell, (float(cy) + 0.5) * cell)
			var o := game.arena._peek(at) if coop else game.arena.obstacle_at(at)
			if o == null or o.kind != TABLE_KIND:
				continue
			var key := Vector3i(cx, cy, z)
			if _emptied.has(key) and game.elapsed - float(_emptied[key]) < reseat:
				continue
			var n := int(per[clampi(o.size_index, 0, per.size() - 1)])
			var vertical := o.half.y > o.half.x
			for s in n:
				var spread := (float(s) - float(n - 1) * 0.5) * (o.half.y if vertical else o.half.x) * 0.9
				var side := -1.0 if s % 2 == 0 else 1.0  # A vertical table's benches: one hero each side.
				var seat := o.center + (Vector2(side * (o.half.x + 4.0), spread * 0.5 + 8.0) if vertical else Vector2(spread, -2.0))
				ci.draw_texture_rect(SpriteBank.disc(), Rect2(seat - Vector2(14.0, 18.0), Vector2(28.0, 28.0)), false, Color(Palette.NORSE_VALKYRIE_GOLD, 0.16))
				if tex == null:
					SpriteBank.draw_disc(ci, seat + Vector2(0.0, -12.0), 6.0, Palette.NORSE_VALKYRIE_GOLD.darkened(0.3))
					continue
				var w := float(tex.get_width())
				var crop := minf(SEAT_CROP, float(tex.get_height()))
				SpriteBank.apply_sharp(ci)
				ci.draw_texture_rect_region(tex, Rect2((seat - Vector2(w * 0.5, crop)).round(), Vector2(w, crop)), Rect2(0.0, 0.0, w, crop), SEAT_TINT)
