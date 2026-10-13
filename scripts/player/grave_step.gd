## GraveStep — the necromancer's dash (GDD §3.1 / §5.5 "Shift: dash"; open
## question 10, resolved in GDD §15.0). Shift (gamepad RB, action `dash`)
## steps PlayerAbilityData.DASH_DISTANCE px through the shadows over
## DASH_DURATION s in the movement direction (the last one when standing
## still), with DASH_IFRAMES s of invulnerability. It passes through enemies
## and summons (the necromancer never collides with bodies) but NOT through
## obstacles: the step is measured with Arena.clear_length() and ends on
## Arena.free_point(), so it never stops inside an obstacle. The open arena
## has no outer bounds, so obstacles are the only limit.
## Charges recharge one at a time; available from the first run. The Ossuary
## adds a second charge (Twin Shadow, meta "dash_charges") and shortens the
## cooldown (Restless Shade, meta "dash_cooldown"), read once at run start
## through game.meta (MetaModifiers, the one Soul Ash path).
## Necromancer.step() calls step() first each tick; while a step runs it moves
## the necromancer itself and his normal movement is skipped, so the army
## simply follows as it does when he walks. Everything runs on game time
## (physics delta), so pause, level-up and hit-stop freeze it.
## The node also draws the shadow trail (fading afterimages, purely visual),
## and the departure puff goes through EffectManager.ring() with anim id
## "grave_step_trail" so sprite-sheet art plugs in (AnimData).
## Input: Game._unhandled_input() calls request(); the autotest bots call
## request(dir) with their own direction. Deterministic: no RNG at all.
class_name GraveStep
extends Node2D

## Owning run.
var game: Game
## Charges this run (PlayerAbilityData.DASH_CHARGES + Twin Shadow), >= 1.
var max_charges: int = PlayerAbilityData.DASH_CHARGES
## Charges ready now (0..max_charges).
var charges: int = PlayerAbilityData.DASH_CHARGES
## Seconds to recharge one charge this run (DASH_COOLDOWN x (1 - Restless
## Shade), never below DASH_MIN_COOLDOWN).
var cooldown: float = PlayerAbilityData.DASH_COOLDOWN
## Seconds accumulated toward the next charge (0..cooldown; 0 when full).
var recharge: float = 0.0
## Remaining dash i-frames in seconds (> 0 while the step protects him).
var dodge_time: float = 0.0
## Last non-zero movement direction (unit vector): the step direction when
## standing still.
var facing_dir: Vector2 = Vector2.RIGHT
## Steps taken this run (also the "dashes" stat).
var dashes: int = 0
## True while a step is in progress.
var _dashing: bool = false
## Start of the current step (world px).
var _from: Vector2 = Vector2.ZERO
## End of the current step (world px, a free point).
var _to: Vector2 = Vector2.ZERO
## Seconds since the current step began (0..DASH_DURATION).
var _t: float = 0.0
## True when a step was requested and not processed yet.
var _queued: bool = false
## Direction of the queued request (zero = movement / facing direction).
var _queued_dir: Vector2 = Vector2.ZERO
## Seconds since the last afterimage was left during the step.
var _trail_accum: float = 0.0
## Afterimages: each [position (Vector2), age in s (float), facing sign (float)].
var _trail: Array = []


func _ready() -> void:
	z_index = 0  # Under the necromancer (z 1), over the ground layers.
	max_charges = maxi(1, PlayerAbilityData.DASH_CHARGES + game.meta.int_value("dash_charges"))
	charges = max_charges
	cooldown = maxf(PlayerAbilityData.DASH_MIN_COOLDOWN,
			PlayerAbilityData.DASH_COOLDOWN * (1.0 - game.meta.value("dash_cooldown")))


## Asks for a step on the next tick. `dir` (optional, any length) overrides
## the movement direction (autotest bots); zero = movement / facing.
func request(dir: Vector2 = Vector2.ZERO) -> void:
	_queued = true
	_queued_dir = dir


## True while a step is moving the necromancer.
func is_dashing() -> bool:
	return _dashing


## Fraction 0..1 of the next charge's recharge (1 when every charge is ready).
func recharge_fraction() -> float:
	if charges >= max_charges:
		return 1.0
	return clampf(recharge / cooldown, 0.0, 1.0)


## Per-tick update, called first by Necromancer.step() with the movement
## input of this tick. Recharges, starts a queued step and advances a running
## one. Returns true when it moved the necromancer this tick (his normal
## movement is then skipped).
func step(delta: float, input: Vector2) -> bool:
	var p := game.player
	if charges < max_charges:
		recharge += delta
		if recharge >= cooldown:
			recharge -= cooldown
			charges += 1
			if charges >= max_charges:
				recharge = 0.0
	if dodge_time > 0.0:
		dodge_time -= delta
	if input.length() > 0.1:
		facing_dir = input.normalized()
	_age_trail(delta)
	if _queued:
		_queued = false
		if not _dashing and not p.dead:
			_try_start(_queued_dir if _queued_dir.length() > 0.01 else facing_dir)
	if not _dashing:
		return false
	_t += delta
	var k := clampf(_t / PlayerAbilityData.DASH_DURATION, 0.0, 1.0)  # Progress through the step.
	p.position = _from.lerp(_to, k)
	p.velocity = (_to - _from) / PlayerAbilityData.DASH_DURATION
	_trail_accum += delta
	if _trail_accum >= PlayerAbilityData.TRAIL_INTERVAL:
		_trail_accum = 0.0
		_trail.append([p.position, 0.0, p.scale.x])
	if k >= 1.0:
		_dashing = false
		if game.arena.is_blocked(p.position, p.radius):
			game.stat_add("dash_end_blocked", 1.0)  # Must stay 0 (autotest check).
	return true


## Starts a step along `dir` when a charge is ready and the way is clear
## for at least DASH_MIN_LENGTH px.
func _try_start(dir: Vector2) -> void:
	if charges <= 0:
		game.stat_add("dash_not_ready", 1.0)
		return
	var p := game.player
	var d := dir.normalized()
	var length := game.arena.clear_length(p.position, d, PlayerAbilityData.DASH_DISTANCE, p.radius)  # Clear distance (px).
	if length < PlayerAbilityData.DASH_MIN_LENGTH:
		game.stat_add("dash_blocked", 1.0)
		return
	_from = p.position
	_to = game.arena.free_point(p.position + d * length, p.radius)
	_t = 0.0
	_trail_accum = 0.0
	_dashing = true
	charges -= 1  # A full set starts recharging from 0 (recharge stays 0 while full).
	dashes += 1
	p.iframes = maxf(p.iframes, PlayerAbilityData.DASH_IFRAMES)
	dodge_time = PlayerAbilityData.DASH_IFRAMES
	game.stat_add("dashes", 1.0)
	game.stat_add("dash_distance", _from.distance_to(_to))
	if length < PlayerAbilityData.DASH_DISTANCE:
		game.stat_add("dash_shortened", 1.0)
	_trail.append([_from, 0.0, p.scale.x])
	game.effects.ring(_from, PlayerAbilityData.TRAIL_PUFF_RADIUS, Palette.VIOLET, 0.3, "grave_step_trail")
	game.shake(PlayerAbilityData.DASH_SHAKE)
	Sfx.play("rogue_dash", _from, 0.85)


## Ages the afterimages and drops the faded ones.
func _age_trail(delta: float) -> void:
	if _trail.is_empty():
		return
	var i := _trail.size() - 1
	while i >= 0:
		var g: Array = _trail[i]
		g[1] = float(g[1]) + delta
		if float(g[1]) >= PlayerAbilityData.TRAIL_LIFE:
			_trail.remove_at(i)
		i -= 1
	queue_redraw()


func _draw() -> void:
	# Sprite key of the afterimage: the run's character as drawn (its own art, else the necromancer's).
	var key := "player/necromancer"
	if game != null and not game.character.is_default():
		var drawn := CharacterGlyphs.drawn_sprite_key(game.character.id)  # "" when no art exists.
		if drawn != "":
			key = drawn
	if game != null and game.player != null and game.player.skin_id != "":
		# A worn skin with its own art (SkinData, cosmetic): the afterimage takes its silhouette.
		var skin_key := String(SkinData.skin(game.player.skin_id).get("sprite", ""))  # The skin's sprite key ("" = unknown skin).
		if skin_key != "" and SpriteBank.has(skin_key):
			key = skin_key
	var tex := SpriteBank.texture(key)  # Sprite art, or null (drawn shape).
	if tex != null and SpriteBank.is_grid(key):
		SpriteBank.apply_sharp(self)  # Grid art draws through the sharp-pixel shader.
	for g: Array in _trail:
		var a := PlayerAbilityData.TRAIL_ALPHA * (1.0 - float(g[1]) / PlayerAbilityData.TRAIL_LIFE)  # Afterimage opacity.
		var pos: Vector2 = g[0]
		var tint := Color(0.42, 0.24, 0.72, a)  # Shadow violet.
		draw_set_transform(pos, 0.0, Vector2(float(g[2]), 1.0))
		if tex != null:
			var h: float = SpriteData.HEIGHTS.get(key, SpriteData.DEFAULT_HEIGHT)  # Drawn height (px).
			var size := Vector2(h * float(tex.get_width()) / float(tex.get_height()), h)  # Drawn size (px).
			var centre := Vector2(0.0, h * SpriteData.CENTER_OFFSET)  # Sprite centre (px).
			draw_texture_rect(tex, Rect2(centre - size * 0.5, size), false, tint)
		else:
			var r := PlayerData.RADIUS  # Body radius (px).
			draw_colored_polygon(PackedVector2Array([Vector2(0, -r * 1.25), Vector2(-r, r * 1.05), Vector2(r, r * 1.05)]), tint)
			draw_circle(Vector2(0, -r * 0.6), r * 0.52, tint)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
