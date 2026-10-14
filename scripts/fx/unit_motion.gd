## UnitMotion: the tier-0 procedural motion of one unit (GDD §15.0 "Art
## pass (true pixel art)"): step bob, lean, turn squash, attack lunge and
## recoil, hit squash and the summon rise. One per pooled unit (Necromancer,
## Enemy and its bosses, SummonedUnit), created on first use and reset on
## every activation, so pool reuse never carries a pose over.
##
## The unit draws in three canvas layers: its own node (ground effects:
## auras, telegraphs, flight shadows), `body` (the sprite or glyph, with its
## drop shadow) and `over` (HP bar, shields, status marks). Only `body` moves:
## MotionDirector calls update() once per rendered frame and this sets the
## body layer's transform, a scale and shear about the FEET (the sprite's
## shadow centre), with no translation. The feet and the shadow therefore
## stay planted: the bob is a stretch, the lean and the lunge a shear, the
## squashes a scale; the facing mirror of the unit node applies on top.
##
## Walk cycles (WalkData): when the body's sprite has a walk strip (the body
## layer's walk_count, reported by SpriteBank.draw()), update() also picks
## the walk frame from the same step phase as the bob, so the legs keep time
## with the bob and the speed; a standing unit shows its still. The body
## layer is redrawn only when the frame changes (a few times per second per
## walking unit). The bob is cut to WalkData.BOB_SCALE then, as the strip
## carries its own 1 art px dip.
##
## Idle strips (IdleData, GDD §15.0 "Idle breathing bounce"): when the body's
## sprite has an idle strip (the body layer's idle_count), a standing unit
## plays it, frame floor((now - idle_at) * IdleData.FPS) mod n, where idle_at
## is the game time it began standing, so each unit's breath starts on frame 0
## (the still) when it stops and units fall out of step without any RNG or id.
## Frozen, stunned, stone, dead, dashing, airborne and structure bodies show
## the still; walking always shows the walk frame instead.
##
## Visual only: it reads the unit's position, facing and state and never
## writes any of them; events (hit(), lunge(), begin_rise()) only store game
## times. Its clock is Game.elapsed, so it slows with the hit-stop and stops
## with the pause like every other effect. No RNG of any kind.
class_name UnitMotion
extends RefCounted

## The unit whose body this animates.
var host: Node2D
## Body layer (sprite or glyph; the only layer that moves).
var body: UnitLayer
## Overlay layer above the body (HP bar, shields, marks; never moves).
var over: UnitLayer
## Pivot: the feet line in unit-local px (positive = below the origin).
var feet: float = 0.0
## Amplitude factor of every deformation (0..1; size, boss and structure rules).
var amp: float = 1.0
## Stride in px travelled per bob.
var stride: float = 20.0
## True for structures: only the hit squash plays.
var hit_only: bool = false
## Game time (s) the current rise started (far past = no rise).
var rise_at: float = -100.0
## Game time (s) of the last hit squash.
var hit_at: float = -100.0
## Game time (s) of the last facing flip.
var turn_at: float = -100.0
## Game time (s) of the last lunge.
var lunge_at: float = -100.0
## World direction of the last lunge (unit vector, or zero for a slam).
var lunge_dir: Vector2 = Vector2.ZERO
## Power (0..1) of the last lunge.
var lunge_power: float = 0.0
## Bob phase (rad, wraps at TAU; one hump per PI).
var phase: float = 0.0
## Smoothed velocity measured from the position (px/s, world).
var vel: Vector2 = Vector2.ZERO
## Current lean (shear, + = forward in the unit's mirrored space).
var lean: float = 0.0
## Position at the last update (px, world).
var last_pos: Vector2 = Vector2.ZERO
## Facing sign at the last update (+1 / -1).
var facing: float = 1.0
## True while the body transform is the identity (lets idle units skip the write).
var _identity: bool = true
## Body alpha currently applied (the rise fades the body in).
var _alpha: float = 1.0
## Width factor of the lunge computed by the last _lunge_terms() call.
var _lunge_sx: float = 1.0
## Height factor of the lunge computed by the last _lunge_terms() call.
var _lunge_sy: float = 1.0
## True while the unit counts as walking for its walk strip (WalkData
## START_SPEED / STOP_SPEED hysteresis); false = the still is shown.
var walking: bool = false
## True while the idle loop runs (standing with an idle strip); false = it
## restarts at frame 0 the next time the unit stands.
var _idle_on: bool = false
## Game time (s) the current idle loop started (valid while _idle_on).
var idle_at: float = 0.0


## Builds the two layers as children of `p_host`: `body_fn` draws the body
## and `over_fn` the overlays (each func(ci: CanvasItem) -> void).
func _init(p_host: Node2D, body_fn: Callable, over_fn: Callable) -> void:
	host = p_host
	body = UnitLayer.new()
	body.draw_fn = body_fn
	host.add_child(body)
	over = UnitLayer.new()
	over.draw_fn = over_fn
	host.add_child(over)


## Clears every pose for a fresh activation. `p_feet` is the pivot
## (feet_of()), `radius` the body radius (amplitude and stride), `scale_k`
## an extra amplitude factor (bosses), `p_hit_only` for structures.
func reset(p_feet: float, radius: float, scale_k: float, p_hit_only: bool) -> void:
	feet = p_feet
	amp = clampf(MotionData.REF_RADIUS / maxf(radius, 1.0), MotionData.MIN_SIZE_SCALE, 1.0) * scale_k
	stride = MotionData.STRIDE_BASE + radius * MotionData.STRIDE_PER_RADIUS
	hit_only = p_hit_only
	rise_at = -100.0
	hit_at = -100.0
	turn_at = -100.0
	lunge_at = -100.0
	lunge_dir = Vector2.ZERO
	lunge_power = 0.0
	phase = 0.0
	vel = Vector2.ZERO
	lean = 0.0
	last_pos = host.position
	facing = 1.0 if host.scale.x >= 0.0 else -1.0
	walking = false
	body.walk_frame = -1  # Starts on the still (the activation redraws the layers).
	body.idle_frame = -1
	_idle_on = false
	idle_at = 0.0
	_set_identity()


## Redraws both layers (called from the unit's own _draw(), so every state
## change that redraws the unit refreshes its body and overlays too).
func redraw_layers() -> void:
	body.queue_redraw()
	over.queue_redraw()


## Starts the rise out of the ground at game time `now` (new summons).
func begin_rise(now: float) -> void:
	rise_at = now


## A hit at game time `now`: squash (a hit while the last squash still
## plays is absorbed, so damage over time pulses instead of pinning it).
func hit(now: float) -> void:
	if now - hit_at >= MotionData.HIT_MIN_GAP:
		hit_at = now


## An attack at game time `now` toward world direction `dir` (zero = a
## slam / pulse without direction) with `power` (MotionData.POWER_*).
func lunge(dir: Vector2, power: float, now: float) -> void:
	if now - lunge_at < MotionData.LUNGE_TIME * MotionData.LUNGE_RETRIGGER:
		return
	lunge_at = now
	lunge_dir = dir.normalized() if dir.length_squared() > 0.0001 else Vector2.ZERO
	lunge_power = power


## Per-frame update at game time `now`, `dt` game seconds after the last
## one (0 while paused). `still` freezes the body (frozen, stunned, stone,
## dead), `quiet` drops the bob, lean and lunge (airborne swoop, Grave Step
## keeps its lean through `no_bob` instead).
func update(now: float, dt: float, still: bool, quiet: bool, no_bob: bool = false) -> void:
	var pos := host.position  # World position this frame.
	var f := 1.0 if host.scale.x >= 0.0 else -1.0  # Facing sign this frame.
	if f != facing:
		facing = f
		if now - turn_at >= MotionData.TURN_MIN_GAP:
			turn_at = now
	if dt > 0.0:
		var d := pos - last_pos  # Movement since the last update (px).
		last_pos = pos
		if d.length_squared() > MotionData.TELEPORT_PX * MotionData.TELEPORT_PX:
			d = Vector2.ZERO
			vel = Vector2.ZERO
		vel += (d / dt - vel) * minf(1.0, dt * MotionData.SPEED_SMOOTH)
		phase = fposmod(phase + vel.length() * dt / stride * PI, TAU)
		var target := clampf(vel.x * facing / MotionData.LEAN_FULL_SPEED, -1.0, 1.0) * MotionData.LEAN_MAX  # Lean wanted.
		lean += (target - lean) * minf(1.0, dt * MotionData.LEAN_RATE)
	if (body.walk_count > 0 or body.idle_count > 0) and not still and not no_bob:
		_update_walk(quiet or hit_only)  # Frozen, dead and dashing bodies keep their frame.
	if body.idle_count > 0:
		_update_idle(now, still or no_bob or quiet or hit_only)
	if still:
		if not _identity:
			_set_identity()
		return
	var sx := 1.0  # Width scale.
	var sy := 1.0  # Height scale.
	var k := 0.0  # Forward shear (px of x per px of height).
	if not hit_only and not quiet:
		if not no_bob:
			var bk := clampf((vel.length() - MotionData.BOB_MIN_SPEED) / (MotionData.BOB_FULL_SPEED - MotionData.BOB_MIN_SPEED), 0.0, 1.0)  # Bob strength.
			if bk > 0.0:
				var bob := MotionData.BOB_STRETCH * (WalkData.BOB_SCALE if body.walk_count > 0 else 1.0)  # Peak stretch (the walk strip has its own dip).
				var s := bob * amp * bk * (absf(sin(phase)) * 2.0 - 1.0)  # Stretch this frame.
				sy += s
				sx -= s * MotionData.BOB_VOLUME
		k += lean * amp
		k += _lunge_terms(now)
		sx *= _lunge_sx
		sy *= _lunge_sy
		var tu := (now - turn_at) / MotionData.TURN_TIME  # Turn progress.
		if tu >= 0.0 and tu < 1.0:
			sx *= 1.0 - MotionData.TURN_SQUASH * amp * sin(PI * tu)
	var hu := (now - hit_at) / MotionData.HIT_TIME  # Hit progress.
	if hu >= 0.0 and hu < 1.0:
		var env := cos(hu * PI * 1.5) * (1.0 - hu)  # Squash, then a small spring past rest.
		var hs := MotionData.HIT_SQUASH * (MotionData.STRUCTURE_SCALE if hit_only else amp) * env
		sy *= 1.0 - hs
		sx *= 1.0 + hs * MotionData.HIT_WIDEN
	var alpha := 1.0  # Body opacity.
	var ru := (now - rise_at) / MotionData.RISE_TIME  # Rise progress.
	if ru >= 0.0 and ru < 1.0:
		var e := maxf(0.05, 1.0 - (1.0 - ru) * (1.0 - ru))  # Ease out (never a zero, singular scale).
		sy *= e * (1.0 + MotionData.RISE_OVERSHOOT * sin(PI * ru))
		sx *= 1.0 + MotionData.RISE_WIDEN * (1.0 - ru)
		alpha = clampf(ru * 2.5, 0.0, 1.0)
	if alpha != _alpha:
		_alpha = alpha
		body.modulate.a = alpha
	if absf(sx - 1.0) < 0.002 and absf(sy - 1.0) < 0.002 and absf(k) < 0.002:
		if not _identity:
			_set_identity()
		return
	# Scale, then shear, about the feet (0, feet): the feet line stays put.
	body.transform = Transform2D(Vector2(sx, 0.0), Vector2(-k * sy, sy), Vector2(k * sy * feet, feet * (1.0 - sy)))
	_identity = false



## Picks the walk frame from the step phase (WalkData): frame i is centred
## on phase PHASE_AT_FRAME_0 + i * TAU / n, so the contact frames sit on the
## bob's low points and the passing frames on its tops; -1 (the still) while
## standing or when `stand` (airborne bodies, structures). Redraws the body
## layer only when the frame changes.
func _update_walk(stand: bool) -> void:
	var speed := vel.length()  # Smoothed measured speed (px/s).
	if stand:
		walking = false
	elif walking:
		walking = speed >= WalkData.STOP_SPEED
	else:
		walking = speed >= WalkData.START_SPEED
	var f := -1  # Frame to show (-1 = the still).
	if walking and body.walk_count > 0:
		var n := body.walk_count  # Frames in the strip.
		var slot := TAU / float(n)  # Phase covered by one frame (rad).
		f = int(fposmod(phase - WalkData.PHASE_AT_FRAME_0 + slot * 0.5, TAU) / slot) % n
	if f != body.walk_frame:
		body.walk_frame = f
		body.queue_redraw()


## Picks the idle frame at game time `now` (IdleData): while the unit
## stands, the loop runs from the game time it began standing; -1 (the still)
## while it walks or when `off` (frozen, dead, dashing, airborne, structure).
## Redraws the body layer only when the frame changes.
func _update_idle(now: float, off: bool) -> void:
	var f := -1  # Frame to show (-1 = the still).
	if off or walking:
		_idle_on = false
	else:
		if not _idle_on:
			_idle_on = true
			idle_at = now
		f = int(maxf(0.0, now - idle_at) * IdleData.FPS) % body.idle_count
	if f != body.idle_frame:
		body.idle_frame = f
		body.queue_redraw()


## Lunge at game time `now`: returns its shear and leaves its width / height
## factors in _lunge_sx / _lunge_sy (1 when no lunge plays).
func _lunge_terms(now: float) -> float:
	_lunge_sx = 1.0
	_lunge_sy = 1.0
	var u := (now - lunge_at) / MotionData.LUNGE_TIME  # Lunge progress.
	if u < 0.0 or u >= 1.0:
		return 0.0
	var e := 0.0  # Push envelope: 0 -> 1 forward, then back past 0 (recoil).
	if u < MotionData.LUNGE_PEAK:
		e = sin(u / MotionData.LUNGE_PEAK * PI * 0.5)
	else:
		var v := (u - MotionData.LUNGE_PEAK) / (1.0 - MotionData.LUNGE_PEAK)  # Return progress.
		e = cos(v * PI) * (1.0 - v)
	e *= lunge_power * amp
	if lunge_dir == Vector2.ZERO:
		_lunge_sy = 1.0 - MotionData.SLAM_SQUASH * e
		_lunge_sx = 1.0 + MotionData.SLAM_SQUASH * MotionData.HIT_WIDEN * e
		return 0.0
	var lx := lunge_dir.x * facing  # Forward share in the mirrored body space.
	_lunge_sx = 1.0 + MotionData.LUNGE_STRETCH * e * absf(lx)
	_lunge_sy = 1.0 - MotionData.LUNGE_LIFT * e * lunge_dir.y
	return MotionData.LUNGE_SHEAR * e * lx


## Puts the body back to rest (identity transform, full opacity).
func _set_identity() -> void:
	body.transform = Transform2D.IDENTITY
	_identity = true
	if _alpha != 1.0:
		_alpha = 1.0
		body.modulate.a = 1.0


## Pivot (feet line, unit-local px) of a unit drawn as sprite `key` (or
## `alt_key` when `key` has no art), else as a glyph of body radius `r`;
## `lift` raises it for a floating body (Banshee).
static func feet_of(key: String, alt_key: String, r: float, lift: float = 0.0) -> float:
	var k := key  # Sprite key with art, or "".
	if not SpriteBank.has(k):
		k = alt_key if alt_key != "" and SpriteBank.has(alt_key) else ""
	if k == "":
		return r * MotionData.GLYPH_FEET - lift
	return float(SpriteData.HEIGHTS.get(k, SpriteData.DEFAULT_HEIGHT)) * MotionData.FEET_FRACTION - lift
