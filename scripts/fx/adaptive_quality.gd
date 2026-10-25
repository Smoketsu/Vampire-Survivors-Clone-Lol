## AdaptiveQuality: the one path for how much transient visual load a run draws
## (GDD §15.0 "Adaptive quality"; numbers in EffectsData, the TIER_* and ADAPT_*
## constants). The visual tier is the larger of two parts:
##   * the Effects setting (Full = tier 0, Reduced = tier 1; Settings.reduced_effects());
##   * the adaptive level: Game adds one AdaptiveQuality node per run, which times
##     the real interval between rendered frames and, when the rolling median over
##     EffectsData.ADAPT_WINDOW_S stays above ADAPT_DOWN_MS (slower than ~24 fps: a
##     phone in Low Power Mode is capped at 30 fps, 33 ms, and never trips it by
##     itself), steps one tier down; when the median has stayed under ADAPT_UP_MS
##     for the recovery wait it steps back up (the wait doubles after a step up that
##     had to be undone at once, so it does not flicker between two tiers).
## The tiers only change what the fx code DRAWS (volley shots and bursts, cosmetic
## effects, particles, damage numbers, animation bursts; tier() is read by
## VolleyDirector, EffectManager, FxLayer and AnimBursts): never what is simulated,
## spawned or rolled, so gameplay, RNG, the same-seed summaries and the co-op
## lockstep are untouched. It never changes Settings.reduced_effects() either.
## Under the autotest it runs as in a player's run (drawing only); --adaptive=off
## keeps the adaptive level at 0 and --adaptive=N pins it at N (measurements).
class_name AdaptiveQuality
extends Node

## Current adaptive level (0..EffectsData.ADAPT_MAX_TIER; 0 = none), shared by every
## draw site through tier(). Reset at the start of every run.
static var level: int = 0
## Adaptive steps down taken this run (MonitorProbe, the autotest line).
static var steps_down: int = 0
## Adaptive steps up taken this run.
static var steps_up: int = 0
## Highest adaptive level reached this run.
static var peak_level: int = 0

## Real frame intervals (ms), a ring buffer of EffectsData.ADAPT_SAMPLES entries.
var _ms := PackedFloat32Array()
## Time.get_ticks_usec() of each entry in _ms (to keep only the rolling window).
var _at := PackedInt64Array()
## Next ring-buffer slot to write.
var _next: int = 0
## Time.get_ticks_usec() of the previous rendered frame (0 = none yet / just resumed).
var _last_usec: int = 0
## Time.get_ticks_usec() of the next evaluation.
var _eval_usec: int = 0
## Time.get_ticks_usec() of the last level change (the window must refill after one).
var _changed_usec: int = 0
## Time.get_ticks_usec() since which the median has stayed under ADAPT_UP_MS (0 = it has not).
var _good_since: int = 0
## Current recovery wait (s): ADAPT_RECOVER_S, doubled after each undone step up.
var _recover_s: float = 0.0
## Time.get_ticks_usec() of the last step up (0 = none yet).
var _up_usec: int = 0
## Scratch copy of the window's samples for the median (reused, no per-frame allocation).
var _sorted := PackedFloat32Array()
## True when --adaptive= pins the level (no adapting).
var _pinned: bool = false


## The visual tier now (0 = Full .. EffectsData.ADAPT_MAX_TIER): the Effects setting
## (Reduced = 1) or the adaptive level, whichever is larger. Read by the draw sites.
static func tier() -> int:
	var t := level
	if Settings.reduced_effects():
		t = maxi(t, 1)
	return t


## Name of the current tier (EffectsData.TIER_NAMES; MonitorProbe and the autotest).
static func level_name() -> String:
	return "%s(adaptive %d)" % [EffectsData.TIER_NAMES[tier()], level]


## One line for the autotest summary: the adaptive steps of this run.
static func summary_line() -> String:
	return "level %d, peak %d, steps down %d, up %d" % [level, peak_level, steps_down, steps_up]


func _ready() -> void:
	name = "AdaptiveQuality"
	level = 0
	steps_down = 0
	steps_up = 0
	peak_level = 0
	_recover_s = EffectsData.ADAPT_RECOVER_S
	_ms.resize(EffectsData.ADAPT_SAMPLES)
	_at.resize(EffectsData.ADAPT_SAMPLES)
	_at.fill(0)
	if GameState.autotest:
		var a := GameState.autotest_adaptive  # "" = adapt as in a player's run.
		if a == "off":
			_pinned = true
		elif a.is_valid_int():
			_pinned = true
			level = clampi(a.to_int(), 0, EffectsData.ADAPT_MAX_TIER)
			peak_level = level


func _notification(what: int) -> void:
	if what == NOTIFICATION_UNPAUSED or what == NOTIFICATION_APPLICATION_FOCUS_IN:
		_last_usec = 0  # The gap of a pause / a trip to another app is not a slow frame.


func _process(_delta: float) -> void:
	var now := Time.get_ticks_usec()
	if _last_usec > 0:
		var ms := float(now - _last_usec) / 1000.0  # Real time since the previous frame.
		if ms <= EffectsData.ADAPT_HITCH_MS:  # A longer gap is a load or a pause, not the steady rate.
			_ms[_next] = ms
			_at[_next] = now
			_next = (_next + 1) % _ms.size()
	_last_usec = now
	if _pinned or now < _eval_usec:
		return
	_eval_usec = now + int(EffectsData.ADAPT_EVAL_S * 1000000.0)
	_evaluate(now)


## Applies the step rules to the rolling median at real time `now` (usec).
func _evaluate(now: int) -> void:
	var window := int(EffectsData.ADAPT_WINDOW_S * 1000000.0)  # usec.
	if now - _changed_usec < window:
		return  # The samples still include frames drawn at the previous tier.
	var from := now - window
	_sorted.resize(0)
	for i in _ms.size():
		if _at[i] >= from and _at[i] > _changed_usec:
			_sorted.append(_ms[i])
	if _sorted.size() < EffectsData.ADAPT_MIN_FRAMES:
		return
	_sorted.sort()
	var med := _sorted[_sorted.size() / 2]  # Median frame interval (ms).
	if med > EffectsData.ADAPT_DOWN_MS:
		_good_since = 0
		if level < EffectsData.ADAPT_MAX_TIER:
			if _up_usec > 0 and now - _up_usec < int(EffectsData.ADAPT_BOUNCE_S * 1000000.0):
				_recover_s = minf(_recover_s * 2.0, EffectsData.ADAPT_RECOVER_MAX_S)  # The step up did not hold.
			_set_level(level + 1, now)
			steps_down += 1
		return
	if med >= EffectsData.ADAPT_UP_MS or level == 0:
		_good_since = 0
		return
	if _good_since == 0:
		_good_since = now
	elif now - _good_since >= int(_recover_s * 1000000.0):
		_set_level(level - 1, now)
		steps_up += 1
		_up_usec = now
		_good_since = 0


## Sets the adaptive level to `l` at real time `now` (usec).
func _set_level(l: int, now: int) -> void:
	level = clampi(l, 0, EffectsData.ADAPT_MAX_TIER)
	peak_level = maxi(peak_level, level)
	_changed_usec = now
