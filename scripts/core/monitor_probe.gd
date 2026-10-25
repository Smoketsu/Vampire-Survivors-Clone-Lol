## MonitorProbe: opt-in memory / draw / entity sampling of a run for the mobile
## Web performance pass (docs/perf/MOBILE.md; autotest flag --monitor=N). Every
## N game seconds it prints one "[mon]" line with the engine's Performance
## monitors (objects, nodes, resources, orphan nodes, static memory, video /
## texture / buffer memory, canvas items and draw calls of the last frame), the
## Web build's WebAssembly heap size, the live counts of the run's transient
## things (enemies, summons, projectiles, volley shots, volley bursts, effects,
## particles, damage numbers, XP crystals) and the rendered-frame times since the
## previous line (median / p95 / max real ms), plus the AdaptiveQuality level.
## --draw-probe=T (with --monitor, the Web build driven by tools/mobile_web_perf.js,
## which counts the WebGL objects the page creates in window.__gl): from game time T
## it hides one world layer at a time for DRAW_PROBE_FRAMES rendered frames
## (volleys, effects, enemies, army, ...) and prints "[draw]" lines with the WebGL
## buffers + vertex arrays created per frame in each phase: what draws the polygons
## Godot rebuilds every frame. Hiding a node only stops its drawing.
## It reads the clock, the monitors and the run's counters only: never gameplay
## state or RNG, so a run with it plays out exactly as one without.
class_name MonitorProbe
extends RefCounted

## Owning run.
var game: Game
## Game seconds between two "[mon]" lines (> 0).
var interval: float = 10.0
## Game time (s) of the next line.
var _next: float = 0.0
## Real ms between rendered frames since the last line.
var _frames := PackedFloat32Array()
## Time.get_ticks_usec() of the previous rendered frame (0 = none yet).
var _last_usec: int = 0
## Highest WebAssembly heap size seen (bytes; 0 off the Web).
var peak_heap: int = 0
## Highest object count seen.
var peak_objects: int = 0
## Rendered frames per --draw-probe phase.
const DRAW_PROBE_FRAMES: int = 30  # Measurement only (not in GDD).
## Game time (s) the draw probe starts (< 0 = off; --draw-probe=T).
var _probe_at: float = -1.0
## Current draw-probe phase (index into _probe_layers(); -1 = not started, -2 = done).
var _probe_phase: int = -1
## Rendered frames left in the current phase.
var _probe_left: int = 0
## WebGL object count (window.__gl buffers + vaos) at the phase start.
var _probe_gl0: int = 0


func _init(p_game: Game, p_interval: float) -> void:
	game = p_game
	interval = maxf(1.0, p_interval)
	_next = 0.0
	_probe_at = GameState.autotest_draw_probe


## One rendered frame (Game._process()): files the real time since the last
## one and prints a line when the game clock has passed the next sample time.
func frame() -> void:
	var now := Time.get_ticks_usec()
	if _last_usec > 0:
		_frames.append(float(now - _last_usec) / 1000.0)
	_last_usec = now
	if game.elapsed >= _next:
		_next = game.elapsed + interval
		print_line()
	if _probe_at >= 0.0 and game.elapsed >= _probe_at and _probe_phase != -2:
		_step_probe()


## The draw-probe phases: [name, node or null (nothing hidden)], each layer between
## two "none" phases so its count compares with the moment around it.
func _probe_layers() -> Array:
	var layers := [["volleys", game.volleys], ["effects", game.effects], ["enemies", game.enemies],
		["army", game.horde], ["projectiles", game.projectiles], ["pickups", game.pickups], ["fx", Juice.fx],
		["hud", game.hud], ["ground", game.ground], ["player", game.player], ["motion", game.motion],
		["chests", game.chests], ["powerups", game.powerups], ["arena", game.arena]]
	var out := [["none", null]]
	for l: Array in layers:
		out.append(l)
		out.append(["none", null])
	return out


## WebGL buffers + vertex arrays the page created so far (window.__gl; -1 = unknown).
static func gl_objects() -> int:
	if not OS.has_feature("web"):
		return -1
	var v: Variant = JavaScriptBridge.eval("window.__gl ? window.__gl.buffers + window.__gl.vaos : -1", true)
	return int(v) if (typeof(v) == TYPE_INT or typeof(v) == TYPE_FLOAT) else -1


## Advances the draw probe by one rendered frame.
func _step_probe() -> void:
	var layers := _probe_layers()
	if _probe_phase >= 0:
		_probe_left -= 1
		if _probe_left > 0:
			return
		var l: Array = layers[_probe_phase]
		var n := gl_objects()
		print("[draw] t=%d hidden=%s gl objects per frame=%.1f" % [int(game.elapsed), l[0], float(n - _probe_gl0) / float(DRAW_PROBE_FRAMES)])
		if l[1] != null and is_instance_valid(l[1]):
			(l[1] as CanvasItem).visible = true
	if _probe_phase < 0:
		Engine.time_scale = 1.0  # Real time while probing: the moment changes slowly between phases.
		Engine.physics_ticks_per_second = 60
	_probe_phase += 1
	if _probe_phase >= layers.size():
		_probe_phase = -2
		Engine.time_scale = GameState.autotest_speed
		Engine.physics_ticks_per_second = int(roundf(60.0 * GameState.autotest_speed))
		return
	var nl: Array = layers[_probe_phase]
	if nl[1] != null and is_instance_valid(nl[1]):
		(nl[1] as CanvasItem).visible = false
	_probe_left = DRAW_PROBE_FRAMES
	_probe_gl0 = gl_objects()


## The WebAssembly heap size in bytes (the Web build; 0 elsewhere or when the
## page's engine object cannot be reached).
static func wasm_heap() -> int:
	if not OS.has_feature("web"):
		return 0
	var v: Variant = JavaScriptBridge.eval("(typeof engine !== 'undefined' && engine.rtenv && engine.rtenv.HEAPU8) ? engine.rtenv.HEAPU8.length : 0", true)
	if typeof(v) == TYPE_INT or typeof(v) == TYPE_FLOAT:
		return int(v)
	return 0


## Prints one "[mon]" line now.
func print_line() -> void:
	var f := _frames.duplicate()
	f.sort()
	var n := f.size()
	var med := f[n / 2] if n > 0 else 0.0  # Median frame (ms).
	var p95 := f[mini(n - 1, int(float(n) * 0.95))] if n > 0 else 0.0
	var mx := f[n - 1] if n > 0 else 0.0
	_frames.clear()
	var heap := wasm_heap()
	peak_heap = maxi(peak_heap, heap)
	var objs := int(Performance.get_monitor(Performance.OBJECT_COUNT))
	peak_objects = maxi(peak_objects, objs)
	var mb := 1.0 / (1024.0 * 1024.0)
	var summons := 0
	for h in game.all_hordes:
		summons += h.units.size()
	var shots := 0
	var bursts := 0
	if game.coop == null:
		shots = game.volleys.alive
		bursts = game.volleys.burst_count()
	else:
		for s in game.coop.slots:
			shots += s.volleys.alive
			bursts += s.volleys.burst_count()
	var fx := Juice.fx
	var hz := Vector2i.ZERO  # Army ground patches (fire trails, shard fields) / boulders, every army.
	for h in game.all_hordes:
		if h.hazards != null:
			hz += h.hazards.live_counts()
	var aq := AdaptiveQuality.level_name()
	print("[mon] t=%02d:%02d heap=%.1fMB obj=%d nodes=%d res=%d orphans=%d static=%.1fMB vmem=%.1fMB tex=%.1fMB buf=%.1fMB items=%d draws=%d prims=%d | enemies=%d summons=%d proj=%d shots=%d bursts=%d effects=%d parts=%d nums=%d xp=%d patches=%d boulders=%d | frames n=%d med=%.1f p95=%.1f max=%.1f ms fps=%d aq=%s" % [
		int(game.elapsed) / 60, int(game.elapsed) % 60, float(heap) * mb, objs,
		int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)),
		int(Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT)),
		int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)),
		Performance.get_monitor(Performance.MEMORY_STATIC) * mb,
		Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) * mb,
		Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED) * mb,
		Performance.get_monitor(Performance.RENDER_BUFFER_MEM_USED) * mb,
		int(Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME)),
		int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)),
		int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)),
		game.enemies.active.size(), summons, game.projectiles.active.size(), shots, bursts,
		game.effects.active.size(), fx.particle_count() if fx != null else 0, fx.number_count() if fx != null else 0,
		game.pickups.active.size(), hz.x, hz.y, n, med, p95, mx, int(Engine.get_frames_per_second()), aq])


## Prints the run's peaks ("[mon] peak" line; Autotest.finish()).
func print_peaks() -> void:
	print_line()
	print("[mon] peak heap=%.1fMB peak objects=%d" % [float(peak_heap) / (1024.0 * 1024.0), peak_objects])
