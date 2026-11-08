## LionessTempleDirector — the stage systems of the Temple of the Lioness
## (temporary Act XII, Stage 35, final stage 20; GDD §15.0 "The Temple of the
## Lioness (Dynasty phase 2)", "The Awakening Statues" and "The Lion Warden
## (Dynasty phase 2)"; proposal docs/proposals/NEW_ACTS_AND_ORDER.md Part 3
## "Stage B"), owned and stepped by EnemyDirector on a stage whose STAGE has a
## "lioness_temple" config (LionessTempleStage.LIONESS_TEMPLE; null elsewhere).
## The zones are MarchDirector's (the looks: LionessTempleGround); Rebirth, the
## Black Land, Heka and the Devourer's Hour are the shared DynastyRules'. Here:
##   * THE AWAKENING STATUES (wake_rows(), the one path): the temple's statue
##     rows (the obstacle kind STATUE_KIND) are ordinary Arena obstacles until a
##     zone change (zone_wakes[zone], zone_wake_delay s after the zone's
##     start), a "statues_wake" timeline event or the Lion Warden's roar wakes
##     some: the nearest rows between wake_min and wake_max px of the
##     necromancer glow (their eyes, glow_time s: owner-approved "eyes glow for
##     2 s"), then each row is REMOVED from the layout through Arena's own path
##     (Arena.remove_obstacle(): the gap is recorded, so no later look at that
##     cell rebuilds it) and its stone walks: a short row as small_row Ushabti
##     Statues, a long row as long_row Ushabti, except every colossus_every-th
##     long row, which wakes as one Woken Colossus. No enemy appears from
##     outside; the stone itself walks (under the hard cap: a row that would
##     pass it stays asleep for a later wake).
##   * THE LION WARDEN ("lion_warden" event): the hall SEALS around the
##     necromancer (a ring of seal_radius px, drawn as standing statues) with
##     one DOORWAY, where the Warden stands (LionWardenKit holds it). While he
##     stands no necromancer can leave the hall (clamped back inside each
##     tick, the seal's one rule; summons and enemies pass freely). His death
##     opens the way; after seal_time s the seal falls anyway and he steps out
##     of the doorway (LionWardenKit.release()), so the boss always finds the
##     way open.
##   * The HUD objective: the sealed hall while it holds.
## Determinism: the cell scan in a fixed order, the seeded global RNG only for
## the doorway's side. Stats: temple_rows_woken, temple_rows_woken_<why>,
## temple_gaps, temple_ushabti_woken, temple_colossi_woken,
## temple_rows_refused, temple_seal_clamps, temple_seal_time.
class_name LionessTempleDirector
extends Node2D

## Obstacle kind of the statue rows that can wake (LionessTempleStage.ZONES).
const STATUE_KIND: String = "dyn_statue_row"

## Owning run.
var game: Game
## The stage's config (LionessTempleStage.LIONESS_TEMPLE).
var config: Dictionary = {}
## Log of Temple events, "m:ss name" (autotest summary).
var fired: Array[String] = []
## Statue rows glowing before they wake: [Arena.Obstacle, wake_at (s), why].
var waking: Array = []
## Long rows woken so far (every colossus_every-th wakes as a colossus).
var long_rows: int = 0
## True while the Warden's seal holds the hall.
var sealed: bool = false
## Centre of the sealed hall (world px).
var seal_center: Vector2 = Vector2.ZERO
## Angle (rad) of the doorway on the seal.
var door_angle: float = 0.0
## Game time the seal falls by itself (s).
var seal_until: float = 0.0
## Game time the seal formed (s).
var sealed_at: float = 0.0
## "m:ss" the Warden fell ("" while alive / never).
var warden_time: String = ""
## How the seal ended ("" while it holds / never formed): "warden" or "timeout".
var seal_end: String = ""
## The Lion Warden once spawned (null before / after; generation-checked).
var _warden: Enemy = null
## Generation of `_warden` when it spawned.
var _warden_gen: int = 0
## Index of the zone seen last (MarchDirector.zone_index).
var _zone_seen: int = 0
## Game time of a pending zone wake (INF = none) and its row count.
var _zone_wake_at: float = INF
## Rows of the pending zone wake.
var _zone_wake_rows: int = 0
## True if the last redraw showed something (one more redraw clears it).
var _drawn: bool = false
## True when this run draws (never headless).
var _draws: bool = false


func _ready() -> void:
	z_index = 2
	_draws = DisplayServer.get_name() != "headless"


## Per-tick update (EnemyDirector, after the MarchDirector): the zone wakes,
## the rows waking, the Warden and his seal.
func step(delta: float) -> void:
	var now := game.elapsed
	var m := game.enemies.march
	if m != null and m.zone_index != _zone_seen:
		_zone_seen = m.zone_index
		var wakes: Array = config["zone_wakes"]
		if _zone_seen < wakes.size() and int(wakes[_zone_seen]) > 0:
			_zone_wake_at = now + float(config["zone_wake_delay"])
			_zone_wake_rows = int(wakes[_zone_seen])
	if now >= _zone_wake_at:
		_zone_wake_at = INF
		if wake_rows(_zone_wake_rows, "zone") > 0:
			game.enemies.show_banner(String(config["zone_wake_banner"]))
	var i := 0
	while i < waking.size():
		var w: Array = waking[i]
		if now >= float(w[1]):
			if _wake(w[0] as Arena.Obstacle, String(w[2])):
				waking.remove_at(i)
				continue
			w[1] = now + 1.0  # The hard cap is full: the row stays asleep a little longer.
		i += 1
	if _warden != null and not (_warden.active and _warden.generation == _warden_gen):
		_warden = null
	if sealed:
		if now >= seal_until or (game.enemies.boss != null and game.enemies.boss.active):
			_break_seal("timeout")
		else:
			_hold_seal()
			game.stat_add("temple_seal_time", delta)
	var busy := sealed or not waking.is_empty()
	if _draws and (busy or _drawn):
		queue_redraw()
	_drawn = busy


# =====================================================================================
# The Awakening Statues
# =====================================================================================

## THE ONE PATH: wakes up to `n` statue rows near the necromancer (the
## nearest between wake_min and wake_max px first), their eyes glowing
## glow_time s before the stone walks; `why` tags the stats ("zone", "event",
## "warden"). Returns how many rows began to glow.
func wake_rows(n: int, why: String) -> int:
	if n <= 0:
		return 0
	var p := game.player.position
	var lo := float(config["wake_min"])
	var hi := float(config["wake_max"])
	var cell := ArenaData.CELL
	var c0 := Vector2i(floori((p.x - hi) / cell), floori((p.y - hi) / cell))
	var c1 := Vector2i(floori((p.x + hi) / cell), floori((p.y + hi) / cell))
	var cands: Array = []  # [distance, obstacle].
	for cy in range(c0.y, c1.y + 1):
		for cx in range(c0.x, c1.x + 1):
			var o := game.arena.obstacle_at(Vector2((float(cx) + 0.5) * cell, (float(cy) + 0.5) * cell))
			if o == null or o.kind != STATUE_KIND or _is_waking(o):
				continue
			var dd := o.center.distance_to(p)
			if dd >= lo and dd <= hi:
				cands.append([dd, o])
	cands.sort_custom(func(a: Array, b: Array) -> bool:
		if float(a[0]) != float(b[0]):
			return float(a[0]) < float(b[0])
		var pa := (a[1] as Arena.Obstacle).center
		var pb := (b[1] as Arena.Obstacle).center
		return pa.x < pb.x or (pa.x == pb.x and pa.y < pb.y))
	var started := 0
	for k in mini(n, cands.size()):
		var o: Arena.Obstacle = cands[k][1]
		waking.append([o, game.elapsed + float(config["glow_time"]), why])
		started += 1
	if started > 0:
		game.stat_add("temple_rows_glowing", float(started))
		_log("statues_%s_%d" % [why, started])
		if game.dynasty != null:
			game.dynasty.play_sound("statue_wake", p, 1.0)
	return started


## True while obstacle `o` already glows.
func _is_waking(o: Arena.Obstacle) -> bool:
	for w: Array in waking:
		if w[0] == o:
			return true
	return false


## The row wakes: the obstacle leaves the layout (the gap) and its stone
## walks. False when the hard cap left no room (the row stays).
func _wake(o: Arena.Obstacle, why: String) -> bool:
	var ed := game.enemies
	var long := o.size_index > 0  # A long row (5 statues) or a short one (3).
	var colossus := long and (long_rows + 1) % maxi(1, int(config["colossus_every"])) == 0
	var count := 1 if colossus else int(config["long_row" if long else "small_row"])
	if ed.regular_alive() + count > ed.hard_cap():
		game.stat_add("temple_rows_refused", 1.0)
		return false
	if not game.arena.remove_obstacle(o):
		return true  # Already gone (a zone change rebuilt the layout): nothing walks.
	if long:
		long_rows += 1
	game.stat_add("temple_rows_woken", 1.0)
	game.stat_add("temple_rows_woken_" + why, 1.0)
	game.stat_add("temple_gaps", 1.0)
	var axis := Vector2.RIGHT if o.half.x >= o.half.y else Vector2.DOWN  # Along the row.
	var span := maxf(o.half.x, o.half.y) * 2.0 * 0.8  # px the statues stand along.
	for k in count:
		var off := 0.0 if count == 1 else (float(k) / float(count - 1) - 0.5) * span
		var kind := LionessTempleEnemyData.WOKEN_COLOSSUS if colossus else DynastyEnemyData.USHABTI_STATUE
		var e := ed.spawn_at(kind, game.arena.free_point(o.center + axis * off, 12.0), false)
		if e == null:
			continue
		game.stat_add("temple_colossi_woken" if colossus else "temple_ushabti_woken", 1.0)
		game.effects.pop(e.position, Palette.DYN_SAND_LIGHT, e.radius * 2.0)
	game.effects.impact(o.center, maxf(o.half.x, o.half.y) + 10.0, Palette.DYN_SAND)
	game.shake(2.0)
	return true


## Runs a Temple timeline event (EnemyDirector forwards the "statues_wake"
## and "lion_warden" types; keys in LionessTempleStage.EVENTS).
func start_event(ev: Dictionary) -> void:
	match String(ev["type"]):
		"statues_wake":
			wake_rows(int(ev.get("rows", 2)), "event")
		"lion_warden":
			_raise_warden(ev)
	game.enemies.show_banner(String(ev["banner"]))


# =====================================================================================
# The Lion Warden and the sealed hall
# =====================================================================================

## The hall seals around the necromancer; the Warden stands in its doorway.
func _raise_warden(ev: Dictionary) -> void:
	seal_center = game.player.position
	door_angle = randf() * TAU  # The seeded global RNG: which side the door is on.
	var r := float(config["seal_radius"])
	var door := seal_center + Vector2.from_angle(door_angle) * r
	var e := game.enemies.spawn_at(String(ev.get("kind", LionessTempleEnemyData.LION_WARDEN)), game.arena.free_point(door, 30.0), false)
	if e == null:
		return
	_warden = e
	_warden_gen = e.generation
	sealed = true
	sealed_at = game.elapsed
	seal_until = game.elapsed + float(config["seal_time"])
	game.stat_add("temple_warden_spawned", 1.0)
	game.shake(5.0)
	if game.dynasty != null:
		game.dynasty.play_sound("warden_roar", door, 0.5)
	_log("warden_seal")


## Keeps every standing necromancer inside the sealed hall (the seal's one rule).
func _hold_seal() -> void:
	var r := float(config["seal_radius"])
	for pl in game.all_players:
		if pl.dead:
			continue
		var off := pl.position - seal_center
		var lim := r - pl.radius
		if off.length() > lim:
			pl.position = seal_center + off.normalized() * lim
			game.stat_add("temple_seal_clamps", 1.0)


## The seal falls (`why`: "warden" when he fell, "timeout" when its time ran out).
func _break_seal(why: String) -> void:
	if not sealed:
		return
	sealed = false
	seal_end = why
	_log("seal_" + why)
	if why == "timeout":
		if _warden != null and _warden.kit is LionWardenKit:
			(_warden.kit as LionWardenKit).release(_warden)
		game.enemies.show_banner(String(config["seal_timeout_banner"]))


## The Warden fell (LionWardenKit.on_killed()): the way is open.
func on_warden_down(_e: Enemy) -> void:
	warden_time = _clock()
	game.stat_add("temple_warden_killed", 1.0)
	_break_seal("warden")
	game.enemies.show_banner(String(config["warden_down_banner"]))


## HUD objective while the hall is sealed ("" otherwise).
func objective_override() -> String:
	if sealed:
		return String(config["seal_objective"]) % ceili(maxf(0.0, seal_until - game.elapsed))
	return ""


## The autotest autopilot's push back into the hall near its edge (the bot
## learns the seal holds it, it does not walk into it).
func danger_push(p: Vector2) -> Vector2:
	if not sealed:
		return Vector2.ZERO
	var r := float(config["seal_radius"])
	var off := p - seal_center
	var edge := r - off.length()
	if edge > 60.0 or off.length() < 0.01:
		return Vector2.ZERO
	return -off.normalized() * (1.0 - edge / 60.0)


# =====================================================================================
# Summary and drawing
# =====================================================================================

## One-line autotest summary.
func summary_line() -> String:
	var st := game.stats
	return "rows woken %d (zone %d, event %d, warden %d; refused at the cap %d), gaps %d | ushabti %d, colossi %d | warden %s, seal %s (held %ds, clamps %d) | events %s" % [
		int(st.get("temple_rows_woken", 0.0)), int(st.get("temple_rows_woken_zone", 0.0)), int(st.get("temple_rows_woken_event", 0.0)),
		int(st.get("temple_rows_woken_warden", 0.0)), int(st.get("temple_rows_refused", 0.0)), int(st.get("temple_gaps", 0.0)),
		int(st.get("temple_ushabti_woken", 0.0)), int(st.get("temple_colossi_woken", 0.0)),
		("killed at " + warden_time) if warden_time != "" else ("standing" if _warden != null else ("not spawned" if st.get("temple_warden_spawned", 0.0) == 0.0 else "gone")),
		seal_end if seal_end != "" else ("holding" if sealed else "never formed"), int(st.get("temple_seal_time", 0.0)),
		int(st.get("temple_seal_clamps", 0.0)), ", ".join(fired) if not fired.is_empty() else "-"]


## Records a Temple event for the autotest summary.
func _log(event_name: String) -> void:
	fired.append("%s %s" % [_clock(), event_name])


## Elapsed game time as "m:ss".
func _clock() -> String:
	var s := int(game.elapsed)
	return "%d:%02d" % [floori(float(s) / 60.0), s % 60]


## The glowing eyes of the waking rows, and the sealed hall's ring of statues
## with its doorway. Visual only (textures).
func _draw() -> void:
	var now := game.elapsed
	for w: Array in waking:
		var o: Arena.Obstacle = w[0]
		var k := clampf(1.0 - (float(w[1]) - now) / maxf(0.01, float(config["glow_time"])), 0.0, 1.0)  # 0 -> 1 as it wakes.
		LionessTempleGlyphs.draw_waking_row(self, o, k, now)
	if sealed:
		LionessTempleGlyphs.draw_seal(self, seal_center, float(config["seal_radius"]), door_angle, float(config["door_gap"]), now)
