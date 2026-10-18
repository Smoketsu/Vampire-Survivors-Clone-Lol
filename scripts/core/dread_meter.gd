## DreadMeter — the run's DREAD (DreadData; GDD §15.0 "Act II: the Ancient
## Eye"): a 0..DreadData.MAX meter on the necromancer. Game owns one as
## `game.dread` only on a stage whose STAGE has "dread": true (null elsewhere,
## so Act I never runs any of this). Its ONE gameplay effect is
## taken_mult(), read by CombatResolver.damage_player(). Sources raise it
## through add() (each Eye hazard names itself: "spores", "ink", "gaze", ...);
## every kill lowers it (on_kill(), CombatResolver._kill_enemy()).
## Determinism: no RNG, game time only.
class_name DreadMeter
extends RefCounted

## Owning run.
var game: Game
## Current Dread (0..DreadData.MAX).
var value: float = 0.0
## Highest Dread this run.
var peak: float = 0.0
## Dread raised this run by source id (source -> amount, after Iron Mind).
var raised_by: Dictionary = {}
## Dread removed by kills this run.
var calmed: float = 0.0
## Seconds-weighted sum of Dread (for the run's average).
var _area: float = 0.0
## Seconds measured for the average.
var _time: float = 0.0
## Seconds spent at or above each step (index = full steps, 0..MAX/STEP).
var time_at_step: PackedFloat32Array = PackedFloat32Array()


func _init(p_game: Game) -> void:
	game = p_game
	time_at_step.resize(int(DreadData.MAX / DreadData.STEP) + 1)


## Raises Dread by `amount` (before Iron Mind) from `source`.
func add(amount: float, source: String) -> void:
	if amount <= 0.0:
		return
	var a := amount * (1.0 - game.abilities.passive_value(DreadData.IRON_MIND, DreadData.RISE_KEY))  # After Iron Mind.
	var before := value
	value = minf(DreadData.MAX, value + a)
	peak = maxf(peak, value)
	raised_by[source] = float(raised_by.get(source, 0.0)) + (value - before)


## A kill steadies the mind (CombatResolver._kill_enemy).
func on_kill() -> void:
	if value <= 0.0:
		return
	var fall := DreadData.FALL_PER_KILL  # Dread this kill removes.
	var mult := game.abilities.passive_value(DreadData.IRON_MIND, DreadData.FALL_KEY)  # Iron Mind's kill multiplier (0 = not owned).
	if mult > 0.0:
		fall *= mult
	var before := value
	value = maxf(0.0, value - fall)
	calmed += before - value


## Full steps of Dread (0..MAX/STEP).
func steps() -> int:
	return int(floorf(value / DreadData.STEP))


## Damage-taken multiplier of the necromancer (1 + TAKEN_PER_STEP per full step).
func taken_mult() -> float:
	return 1.0 + DreadData.TAKEN_PER_STEP * float(steps())


## 0..1 fill (HUD meter, vignette).
func fraction() -> float:
	return value / DreadData.MAX


## Per-tick bookkeeping (Game): the statistics only.
func step(delta: float) -> void:
	_area += value * delta
	_time += delta
	time_at_step[steps()] += delta


## Run's average Dread.
func average() -> float:
	return _area / _time if _time > 0.0 else 0.0


## One-line summary for the autotest.
func summary_line() -> String:
	var parts := PackedStringArray()
	var keys := raised_by.keys()
	keys.sort()
	for k: String in keys:
		parts.append("%s %.0f" % [k, float(raised_by[k])])
	var steps_txt := PackedStringArray()
	for i in time_at_step.size():
		steps_txt.append("%d:%.0fs" % [i, time_at_step[i]])
	return "peak %.0f | average %.1f | end %.0f | calmed by kills %.0f | time per step %s | raised by: %s" % [
		peak, average(), value, calmed, " ".join(steps_txt), ", ".join(parts) if not parts.is_empty() else "nothing"]
