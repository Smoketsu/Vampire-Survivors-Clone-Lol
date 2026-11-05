## MovieSpans: opt-in capture helper for promo clips (autotest only, `--movie-spans=T:N,...`).
##
## Recording a Godot Movie Maker video (`--write-movie out.avi --fixed-fps 30`) of a 16 minute run
## at real speed would take far too long, so this node fast-forwards the run (the normal
## `--speed`, with drawing switched off (the viewport stops updating; the AVI still gets a frame per tick, which the tool cuts)) and only slows it to real time (x1) for the listed spans:
## each "T:N" is N game seconds starting at game second T. Every frame it writes is counted, and
## the start / end frame of each span is printed as a `[movie] span ...` line so
## `tools/make_promo_clip.py` can cut the AVI. Nothing here touches gameplay state or RNG
## (the simulation runs the same ticks at any speed); it only changes Engine.time_scale, the tick
## rate and whether frames are drawn. Never created unless --movie-spans is passed.
class_name MovieSpans
extends Node

## Game seconds before a span at which the run drops from the fast speed to SLOW_SPEED (s), so
## the fast frames' overshoot (about a second of game time at x32) never eats into the span.
const LEAD_S: float = 4.0
## Time scale used in the LEAD_S window before a span (x; small overshoot, drawing off).
const SLOW_SPEED: float = 4.0
## Time scale inside a span (x; 1 = real time, the clip looks and sounds natural).
const SPAN_SPEED: float = 1.0
## Game seconds before a span at which drawing is switched back on (s), so the first
## frames of the span are not blank.
const DRAW_LEAD_S: float = 1.0

## Extra game seconds recorded after each span's N (s): the first frames of a span run a little fast
## (the speed change lands a frame late), so the tool needs a few frames more than N x fps.
const TAIL_S: float = 0.3

## The spans, ascending: each {"t": start game second, "n": length in game seconds}.
var spans: Array[Dictionary] = []
## The autotest's fast speed (x), restored between spans.
var fast_speed: float = 8.0
## Index of the next span not yet finished.
var _idx: int = 0
## True while inside a span (speed x1, drawing on).
var _in_span: bool = false
## Process frames counted since this node started (one movie frame each, video and audio; +-1).
var _frames: int = 0


## Parses "T:N,T:N" into spans (ascending by start).
func setup(text: String, fast: float) -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	fast_speed = fast
	for part: String in text.split(",", false):
		spans.append({"t": part.get_slice(":", 0).to_float(), "n": maxf(0.5, part.get_slice(":", 1).to_float())})
	spans.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["t"]) < float(b["t"]))
	_set_speed(fast_speed, false)


## Counts the frames Godot Movie Maker writes (one per process frame, drawn or not).
func _process(_delta: float) -> void:
	_frames += 1


## Called by Autotest.step() after each simulation step with the game clock (s).
## Returns true once every span is finished (the autotest then ends the run).
func update(elapsed: float) -> bool:
	if _idx >= spans.size():
		return true
	var t: float = float(spans[_idx]["t"])  # Start of the current span (s).
	var n: float = float(spans[_idx]["n"])  # Its length (s).
	if _in_span:
		if elapsed >= t + n + TAIL_S:
			print("[movie] span %d end frame=%d game=%.2f" % [_idx, _frames, elapsed])
			_in_span = false
			_idx += 1
			_set_speed(fast_speed, false)
			return _idx >= spans.size()
		return false
	if elapsed >= t:
		_in_span = true
		print("[movie] span %d start frame=%d game=%.2f" % [_idx, _frames, elapsed])
		_set_speed(SPAN_SPEED, true)
	elif elapsed >= t - DRAW_LEAD_S:
		_set_speed(SLOW_SPEED, true)
	elif elapsed >= t - LEAD_S:
		_set_speed(SLOW_SPEED, false)
	return false


## Time scale, matching physics tick rate and tick cap (as Autotest._ready does), and drawing.
func _set_speed(speed: float, draw: bool) -> void:
	Engine.time_scale = speed
	Engine.physics_ticks_per_second = int(roundf(60.0 * speed))
	Engine.max_physics_steps_per_frame = maxi(8, int(ceilf(8.0 * speed)))
	RenderingServer.viewport_set_update_mode(get_viewport().get_viewport_rid(),
		RenderingServer.VIEWPORT_UPDATE_ALWAYS if draw else RenderingServer.VIEWPORT_UPDATE_DISABLED)
