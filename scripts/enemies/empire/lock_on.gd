## LockOn — LOCK-ON, the second of the Electronic Empire's shared rules (Act
## III; GDD §15.0 "Lock-On: the big shots are telegraphed"): a Spotter (any
## kit) paints a target, the necromancer or a summon, with a thin red laser
## for EmpireRulesData.LOCK_ON.paint_time s, then a heavy shot fires down that
## line through EmpireShots (so Line of Fire applies: a summon stepping into
## the line takes the shot). The ONE path of every Lock-On line:
##   paint(owner, target, damage, speed, reach, source, boss_override, paint_s)
## starts a line (false when refused), and the line then lives here:
##   * tracking: it turns toward its target at track_rate rad/s,
##   * locked: the last lock_time s it stops turning and blinks (the moment to
##     Grave Step out of it),
##   * fired: the heavy shot leaves the owner's muzzle along the line;
##   * cancelled: the owner died or was pooled ("kill the spotter first");
##     while the owner is frozen or stunned the line waits with it.
## At most max_lines lines are painted at once; a paint beyond it is refused
## (counted; the Spotter retries). BOSS OVERRIDE (documented for the Act III
## bosses, e.g. Deus Ex Machina's missile salvo of four lines at once): a paint
## with boss_override = true ignores max_lines, up to boss_max_lines.
## SIGNAL GHOST hook (the future Act III counter-passive; not built in phase
## 1): paint_time() lengthens a line painted on the necromancer by the passive's
## EmpireRulesData.SIGNAL_GHOST_KEY value (0 while the passive does not exist).
## Lines are stored in packed arrays (no nodes, no instance ids), the owner and
## target guarded by their pooling generations. Drawn by this node above the
## units (z 3), thin and clear. Stats: lockon_painted, lockon_on_player,
## lockon_on_summon, lockon_refused, lockon_fired, lockon_cancelled.
class_name LockOn
extends Node2D

## Owning run.
var game: Game
## Painted lines now (indices [0, count) of every array below).
var count: int = 0
## Most lines painted at once this run (the autotest's "lock-on" line).
var peak: int = 0
## Owner enemy of each line (the painter; its kit holds still while it paints).
var _owner: Array[Enemy] = []
## Generation of each owner when it painted (stale guard).
var _owner_gen: PackedInt32Array = PackedInt32Array()
## Target of each line: the Necromancer or a SummonedUnit.
var _target: Array[Node2D] = []
## Generation of each summon target when painted (0 for the necromancer).
var _target_gen: PackedInt32Array = PackedInt32Array()
## Unit direction of each line (from the owner's muzzle).
var _dir: PackedVector2Array = PackedVector2Array()
## Seconds each line has been painted.
var _time: PackedFloat32Array = PackedFloat32Array()
## Total paint time (s) of each line (paint_time(), or a boss's own).
var _paint: PackedFloat32Array = PackedFloat32Array()
## Damage of each line's heavy shot (already time-scaled).
var _dmg: PackedFloat32Array = PackedFloat32Array()
## Speed (px/s) of each line's heavy shot.
var _speed: PackedFloat32Array = PackedFloat32Array()
## Reach (px) of each line (the owner's range): drawn length / shot flight.
var _reach: PackedFloat32Array = PackedFloat32Array()
## Damage tag of each line's heavy shot.
var _src: PackedStringArray = PackedStringArray()
## Hard cap on lines (EmpireRulesData.LOCK_ON boss_max_lines).
var _cap: int = 0
## True if the last redraw showed lines (one more redraw clears them).
var _drawn: bool = false


## Builds the line store for `p_game` (EmpireRules adds it as its child).
func _init(p_game: Game) -> void:
	game = p_game
	name = "LockOn"
	z_index = 3  # Above the units and the shots: the lines must read clearly.
	z_as_relative = false  # Not under EmpireRules' ground layer.
	_cap = int(EmpireRulesData.LOCK_ON["boss_max_lines"])
	_owner.resize(_cap)
	_owner_gen.resize(_cap)
	_target.resize(_cap)
	_target_gen.resize(_cap)
	_dir.resize(_cap)
	_time.resize(_cap)
	_paint.resize(_cap)
	_dmg.resize(_cap)
	_speed.resize(_cap)
	_reach.resize(_cap)
	_src.resize(_cap)


## Paint time (s) of a line on `target`: EmpireRulesData.LOCK_ON paint_time,
## lengthened on the necromancer by the Signal Ghost passive (the documented
## hook: 0 while that passive does not exist, so exactly paint_time today).
func paint_time(target: Node2D) -> float:
	var t := float(EmpireRulesData.LOCK_ON["paint_time"])  # Base paint (s).
	if target == game.player:
		t *= 1.0 + game.abilities.passive_value(EmpireRulesData.SIGNAL_GHOST, EmpireRulesData.SIGNAL_GHOST_KEY)
	return t


## Starts a Lock-On line from `owner` onto `target` (the necromancer or a
## summon): after the paint its heavy shot deals `damage` (time-scaled) at
## `speed` px/s over `reach` px, tagged `source`. Refused (false) when the owner
## already paints or max_lines lines are painted; `boss_override` lifts
## max_lines up to boss_max_lines; `paint_s` > 0 sets a boss's own paint time.
func paint(owner: Enemy, target: Node2D, damage: float, speed: float, reach: float, source: String,
		boss_override: bool = false, paint_s: float = -1.0) -> bool:
	if owner == null or target == null or has_line(owner):
		return false
	var limit := _cap if boss_override else mini(_cap, int(EmpireRulesData.LOCK_ON["max_lines"]))  # Lines allowed now.
	if count >= limit:
		game.stat_add("lockon_refused", 1.0)
		return false
	var i := count
	count += 1
	peak = maxi(peak, count)
	_owner[i] = owner
	_owner_gen[i] = owner.generation
	_target[i] = target
	_target_gen[i] = (target as SummonedUnit).generation if target is SummonedUnit else 0
	var to := target.position - owner.position  # Owner -> target.
	_dir[i] = to.normalized() if to.length_squared() > 0.01 else Vector2.RIGHT
	_time[i] = 0.0
	_paint[i] = paint_s if paint_s > 0.0 else paint_time(target)
	_dmg[i] = damage
	_speed[i] = speed
	_reach[i] = reach
	_src[i] = source
	game.stat_add("lockon_painted", 1.0)
	game.stat_add("lockon_on_player" if target == game.player else "lockon_on_summon", 1.0)
	Sfx.play("lock_on", owner.position)
	return true


## True while `owner` paints a line.
func has_line(owner: Enemy) -> bool:
	for i in count:
		if _owner[i] == owner and _owner_gen[i] == owner.generation:
			return true
	return false


## Removes line `i` (the last line moves into its slot).
func _remove(i: int) -> void:
	var last := count - 1
	if i != last:
		_owner[i] = _owner[last]
		_owner_gen[i] = _owner_gen[last]
		_target[i] = _target[last]
		_target_gen[i] = _target_gen[last]
		_dir[i] = _dir[last]
		_time[i] = _time[last]
		_paint[i] = _paint[last]
		_dmg[i] = _dmg[last]
		_speed[i] = _speed[last]
		_reach[i] = _reach[last]
		_src[i] = _src[last]
	_owner[last] = null
	_target[last] = null
	count = last


## Ages every line (EmpireRules.step()): cancels the lines whose owner is
## gone, tracks, locks and fires the others.
func step(delta: float) -> void:
	var lock := float(EmpireRulesData.LOCK_ON["lock_time"])  # Last seconds without tracking.
	var rate := float(EmpireRulesData.LOCK_ON["track_rate"])  # Tracking turn rate (rad/s).
	var i := 0
	while i < count:
		var o := _owner[i]
		if o == null or not o.active or o.generation != _owner_gen[i]:
			game.stat_add("lockon_cancelled", 1.0)  # The Spotter died first.
			_remove(i)
			continue
		if o.frozen:
			i += 1
			continue  # Held by Stasis, a Deep Freeze or a stun: the line waits.
		_time[i] += delta
		if _time[i] < _paint[i] - lock and _target_alive(i):
			var want := (_target[i].position - o.position).angle()  # Toward the target.
			var cur := _dir[i].angle()
			var diff := wrapf(want - cur, -PI, PI)
			_dir[i] = Vector2.from_angle(cur + clampf(diff, -rate * delta, rate * delta))
		if _time[i] >= _paint[i]:
			_fire(i)
			_remove(i)
			continue
		i += 1
	if count > 0 or _drawn:
		queue_redraw()
	_drawn = count > 0


## True if line `i`'s target is still the same living body.
func _target_alive(i: int) -> bool:
	var t := _target[i]
	if t == null:
		return false
	if t is SummonedUnit:
		var u := t as SummonedUnit
		return u.active and u.generation == _target_gen[i]
	return true


## The muzzle (world px) of line `i`: its owner's centre moved along the line.
func _muzzle(i: int) -> Vector2:
	return _owner[i].position + _dir[i] * float(EmpireRulesData.LOCK_ON["muzzle"])


## Fires line `i`'s heavy shot down the line (EmpireShots: Line of Fire applies).
func _fire(i: int) -> void:
	var at := _muzzle(i)
	game.empire.shots.fire(at, _dir[i], _speed[i], _dmg[i], _owner[i].undead_damage_mult, "rail", _src[i], _reach[i])
	_owner[i].motion_lunge(_dir[i], MotionData.POWER_SHOT)
	game.effects.pop(at, Palette.EMPIRE_SIGNAL_GLOW, 8.0)
	game.stat_add("lockon_fired", 1.0)
	Sfx.play("rail_shot", at)


## Autopilot hint (the autotest bot): a push sideways off every painted line
## passing within danger_reach px of `p`, stronger as its shot nears.
func danger_push(p: Vector2) -> Vector2:
	var push := Vector2.ZERO
	var reach := float(EmpireRulesData.LOCK_ON["danger_reach"]) + game.player.radius  # Danger band (px).
	for i in count:
		var a := _muzzle(i)
		var d := _dir[i]
		var along := (p - a).dot(d)  # Distance down the line (px).
		if along < 0.0 or along > _reach[i] * float(EmpireRulesData.LOCK_ON["length_mult"]):
			continue
		var side := (p - a) - d * along  # Offset from the line.
		var dist := side.length()
		if dist >= reach:
			continue
		var urgency := clampf(_time[i] / maxf(_paint[i], 0.01), 0.3, 1.0)  # Stronger as it fires.
		var n := side / dist if dist > 0.01 else d.orthogonal()
		push += n * (1.0 - dist / reach) * 2.0 * urgency
	return push


## Draws every painted line: a thin warning-red laser from the muzzle, a
## reticle on the target; locked lines blink brighter and thicker. Blinks run on
## game time (they freeze with the run). Visual only.
func _draw() -> void:
	var lock := float(EmpireRulesData.LOCK_ON["lock_time"])  # Locked phase (s).
	var lm := float(EmpireRulesData.LOCK_ON["length_mult"])  # Drawn length / reach.
	for i in count:
		var a := _muzzle(i)
		var locked := _time[i] >= _paint[i] - lock  # Last seconds: no tracking.
		var b := a + _dir[i] * _reach[i] * lm  # Far end of the line.
		var blink := locked and fmod(game.elapsed * 12.0, 1.0) < 0.5  # Locked lines blink.
		var w := float(EmpireRulesData.LOCK_ON["locked_width" if locked else "width"])  # Line width (px).
		var col := Palette.EMPIRE_SIGNAL_GLOW if blink else Palette.EMPIRE_SIGNAL_RED
		draw_line(a, b, Color(Palette.EMPIRE_SIGNAL_RED, 0.22), w + 3.0)
		draw_line(a, b, Color(col, 0.95 if locked else 0.7), w)
		if _target_alive(i):
			var t := _target[i].position  # Reticle on the painted target.
			var r := 9.0 if locked else 12.0 - 3.0 * _time[i] / maxf(_paint[i], 0.01)
			draw_arc(t, r, 0.0, TAU, 20, Color(col, 0.9), 1.5)
			for k in 4:
				var q := Vector2.from_angle(PI * 0.5 * float(k))
				draw_line(t + q * (r - 3.0), t + q * (r + 4.0), Color(col, 0.9), 1.5)
