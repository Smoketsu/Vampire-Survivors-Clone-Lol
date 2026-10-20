## PerfProbe — opt-in timing of a run for the co-op performance question
## (docs/coop/PERF.md; autotest flag --perf). Game hands it the length of every
## simulation tick (Game._physics_process(), Time.get_ticks_usec()) and, once
## per rendered frame, the real time since the previous frame; the probe files
## each tick under its game minute and under the busy moments it falls in:
##   boss      the stage boss is alive
##   reckoning the countdown has ended (the Reckoning waves)
##   barrage   a Rally Barrage runs (any army's VolleyDirector.barrage_until)
##   barrage2  both armies' Rally Barrages run at once (co-op only)
##   late      15:00 or later before 0:00 (full builds, full volleys)
## At the end of the run it prints a table (mean / p95 / max ms per minute and
## per moment, with the average enemies, summons and volley shots alive) and
## the rendered-frame times (only meaningful with a renderer, e.g. the Web build).
## --perf-real=A-B,C-D (game seconds) runs those windows at real time (1x) so the
## frame times there are real frames; outside them the autotest's speed applies.
## It reads the clock and the run's counters only: never gameplay state or RNG.
class_name PerfProbe
extends RefCounted

## Ticks slower than this (ms) count as over the 60 Hz frame budget.
const BUDGET_MS: float = 16.7  # 60 fps frame budget (TUNING (not in GDD) measurement only)
## The moments, in print order.
const MOMENTS: Array[String] = ["boss", "reckoning", "barrage", "barrage2", "late"]
## Game time (s) from which a tick counts as "late" (until 0:00).
const LATE_FROM: float = 900.0  # TUNING (not in GDD) measurement only

## Owning run.
var game: Game
## Per game minute: tick lengths (usec).
var _minutes: Array[PackedInt32Array] = []
## Per game minute: [ticks, enemy sum, summon sum, shot sum] for the averages.
var _counts: Array[PackedInt64Array] = []
## Moment id -> tick lengths (usec; a plain Array, appended in place).
var _moments: Dictionary = {}
## Moment id -> [ticks, enemy sum, summon sum, shot sum].
var _moment_counts: Dictionary = {}
## Rendered-frame intervals (usec) inside the real-time windows (or always,
## when no window is given and a renderer runs).
var _frames := PackedInt32Array()
## Moment id -> rendered-frame intervals (usec; a plain Array).
var _moment_frames: Dictionary = {}
## Time.get_ticks_usec() of the previous rendered frame (0 = none yet).
var _last_frame_usec: int = 0
## The --perf-real windows ([from, to] game seconds each; empty = none).
var _windows: Array[Vector2] = []
## True while the clock runs at real time for a window.
var _in_window: bool = false
## The autotest's speed (restored after a window).
var _speed: float = 1.0
## Most volley shots alive at once (every army together).
var peak_shots: int = 0
## Most volley shots alive at once in one army.
var peak_shots_one: int = 0
## Volleys thinned by the shot cap at the end (every army together).
var capped: int = 0


func _init(p_game: Game) -> void:
	game = p_game
	for id: String in MOMENTS:
		_moments[id] = []
		_moment_counts[id] = [0, 0, 0, 0]
		_moment_frames[id] = []
	_speed = GameState.autotest_speed
	for part: String in GameState.autotest_perf_real.split(",", false):
		if part.contains("-"):
			_windows.append(Vector2(part.get_slice("-", 0).to_float(), part.get_slice("-", 1).to_float()))


## One simulation tick took `usec` microseconds (Game._physics_process()).
func record(usec: int) -> void:
	var m := int(game.elapsed / 60.0)  # Game minute of this tick.
	while _minutes.size() <= m:
		_minutes.append(PackedInt32Array())
		_counts.append(PackedInt64Array([0, 0, 0, 0]))
	var enemies := game.enemies.active.size()
	var summons := 0
	var shots := 0
	var barrages := 0  # Armies whose Rally Barrage runs.
	for h in game.all_hordes:
		summons += h.units.size()
	for v in _volley_directors():
		shots += v.alive
		peak_shots_one = maxi(peak_shots_one, v.alive)
		if game.elapsed < v.barrage_until:
			barrages += 1
	peak_shots = maxi(peak_shots, shots)
	_minutes[m].append(usec)
	_add(_counts[m], enemies, summons, shots)
	for id: String in _moments_now(barrages):
		(_moments[id] as Array).append(usec)
		_add_row(_moment_counts[id] as Array, enemies, summons, shots)
	_update_window()


## One rendered frame (Game._process()): files the real time since the last one.
func frame() -> void:
	var now := Time.get_ticks_usec()
	if _last_frame_usec > 0 and (_windows.is_empty() or _in_window):
		var dt := now - _last_frame_usec  # Real time since the previous frame (usec).
		_frames.append(dt)
		var barrages := 0
		for v in _volley_directors():
			if game.elapsed < v.barrage_until:
				barrages += 1
		for id: String in _moments_now(barrages):
			(_moment_frames[id] as Array).append(dt)
	_last_frame_usec = now


## The moments the run is in now (`barrages` armies in a Rally Barrage).
func _moments_now(barrages: int) -> Array[String]:
	var out: Array[String] = []
	var b := game.enemies.boss
	if b != null and b.active:
		out.append("boss")
	if game.enemies.reckoning_wave > 0:
		out.append("reckoning")
	if barrages > 0:
		out.append("barrage")
	if barrages > 1:
		out.append("barrage2")
	if game.elapsed >= LATE_FROM and game.elapsed < WaveData.RUN_DURATION:
		out.append("late")
	return out


## Every army's volley director (one in solo).
func _volley_directors() -> Array[VolleyDirector]:
	var out: Array[VolleyDirector] = []
	if game.coop == null:
		out.append(game.volleys)
	else:
		for s in game.coop.slots:
			out.append(s.volleys)
	return out


## Adds one tick's entity counts to a moment's averages row (a plain Array).
static func _add_row(row: Array, enemies: int, summons: int, shots: int) -> void:
	row[0] = int(row[0]) + 1
	row[1] = int(row[1]) + enemies
	row[2] = int(row[2]) + summons
	row[3] = int(row[3]) + shots


## Adds one tick's entity counts to an averages row.
static func _add(row: PackedInt64Array, enemies: int, summons: int, shots: int) -> void:
	row[0] += 1
	row[1] += enemies
	row[2] += summons
	row[3] += shots


## Enters / leaves a --perf-real window (real-time clock inside it).
func _update_window() -> void:
	if _windows.is_empty():
		return
	var inside := false
	for w in _windows:
		inside = inside or (game.elapsed >= w.x and game.elapsed < w.y)
	if inside == _in_window:
		return
	_in_window = inside
	var sp := 1.0 if inside else _speed  # Clock speed from now on.
	Engine.time_scale = sp
	Engine.physics_ticks_per_second = int(roundf(60.0 * sp))
	Engine.max_physics_steps_per_frame = maxi(8, int(ceilf(8.0 * sp)))
	_last_frame_usec = 0  # Do not count the switch itself.


## "mean / p95 / max" in ms of `samples` (usec), and the share over the budget.
static func stats_line(samples: PackedInt32Array) -> String:
	if samples.is_empty():
		return "-"
	var s := samples.duplicate()
	s.sort()
	var total := 0.0
	var over := 0
	for v in s:
		total += float(v)
		if float(v) / 1000.0 > BUDGET_MS:
			over += 1
	var n := s.size()
	return "%.2f / %.2f / %.2f ms (over %.1f ms: %.1f%%)" % [total / float(n) / 1000.0, float(s[mini(n - 1, int(float(n) * 0.95))]) / 1000.0,
		float(s[n - 1]) / 1000.0, BUDGET_MS, 100.0 * float(over) / float(n)]


## Prints the table ("[perf]" lines; Autotest.finish()).
func print_table() -> void:
	for v in _volley_directors():
		capped += v.capped_volleys
	print("[perf] ===== SIMULATION TICK (ms; mean / p95 / max) — %s =====" % ("co-op, 2 slots" if game.coop != null else "solo"))
	print("[perf] min | ticks | tick mean / p95 / max | avg enemies | avg summons | avg shots")
	for m in _minutes.size():
		var c := _counts[m]
		if c[0] <= 0:
			continue
		print("[perf] %02d | %d | %s | %.0f | %.0f | %.0f" % [m, c[0], stats_line(_minutes[m]),
			float(c[1]) / float(c[0]), float(c[2]) / float(c[0]), float(c[3]) / float(c[0])])
	var all := PackedInt32Array()
	for row in _minutes:
		all.append_array(row)
	print("[perf] whole run | %d | %s" % [all.size(), stats_line(all)])
	for id: String in MOMENTS:
		var c: Array = _moment_counts[id]
		if int(c[0]) <= 0:
			print("[perf] moment %s: none" % id)
			continue
		print("[perf] moment %s | %d ticks | %s | enemies %.0f, summons %.0f, shots %.0f" % [id, c[0], stats_line(PackedInt32Array(_moments[id])),
			float(c[1]) / float(c[0]), float(c[2]) / float(c[0]), float(c[3]) / float(c[0])])
	print("[perf] volley shots: peak all armies %d, peak one army %d (cap %d per army) | volleys thinned by the cap %d" % [
		peak_shots, peak_shots_one, VolleyData.SHOT_CAP, capped])
	if not _frames.is_empty():
		print("[perf] rendered frames (real ms between frames): all %s" % stats_line(_frames))
		for id: String in MOMENTS:
			var f := PackedInt32Array(_moment_frames[id])
			if not f.is_empty():
				print("[perf] frames during %s: %s" % [id, stats_line(f)])
