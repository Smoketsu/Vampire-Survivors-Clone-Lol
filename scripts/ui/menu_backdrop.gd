## MenuBackdrop: the animated pixel-art diorama behind the main menu and every
## out-of-run screen (GDD §15.0 "Menu diorama"; numbers in MenuBackdropData;
## art in assets/sprites/menu/ plus the game's own obstacle, tile and walk
## art; docs/art/ART_BIBLE.md "Menu diorama"). A graveyard at night: a banded
## sky with a pixel moon, twinkling stars and drifting clouds; far hills with
## the Covenant's cathedral, a watchtower and its torches; a mid graveyard of
## gravestones, dead trees, crypt walls, a mausoleum, an angel and an iron
## fence; the near ground on the Graveyard tile; three drifting fog banks;
## soul wisps rising from the graves; flickering soul lanterns and candles;
## a few bats and a rare shooting star crossing the sky; and small troupes of undead
## shuffling past on their walk strips.
##
## Structure: a full-rect Control holding one Node2D per depth layer, back to
## front: sky, sky_fx, far, far_fx, mid, mid_fx, near, near_fx, shade. The
## plain layers (sky bands, hills, props, ground) are drawn once and only
## redrawn on a resize or a mood fade; the *_fx layers (stars, clouds, moon
## halo, fog, flames, glows, wisps, walkers) redraw every frame. The slow
## camera drift moves each layer's NODE by its parallax factor
## (MenuBackdropData.PARALLAX), so the static layers never redraw for it.
## Every layer except shade draws its grid art through the sharp-pixel shader
## (1 art px = 1 layout px, SpriteBank.apply_sharp()); shade draws the soft
## column band, the vignette and the dim (smooth gradients, no shader).
##
## Layer coordinates are design px (MenuBackdropData header): x from the
## screen's centre line, y in a 720 px frame pinned to the screen's bottom.
##
## Hooks for other screens (W2):
##   set_dim(on, instant)          darkens the diorama while a sub-screen is open
##                                 (MainMenu calls it when an overlay opens / closes);
##   set_band(center_x, width, alpha)  moves / resizes the dark band behind the
##                                 menu column (0 alpha = no band);
##   set_mood(id, instant)         fades the colours to another MOODS entry
##                                 ("graveyard", "crimson_march", "sanctum"): e.g.
##                                 a stage select could follow the focused stage.
## A MenuBackdrop works anywhere: add one as the first child of any full-rect
## Control to put the living graveyard behind it.
##
## Purely cosmetic: real (unscaled) time, a private RandomNumberGenerator
## (seeded only for the fixed star field), no gameplay state, so runs and the
## autotest (which skips the menu) are unaffected.
class_name MenuBackdrop
extends Control

## Plain layers (redrawn on resize / mood fades), by depth name.
var _static: Dictionary = {}
## Animated layers (redrawn every frame), by depth name.
var _fx: Dictionary = {}
## The sky's plain layer (bands only; its fx layer holds the moon and stars).
var _sky: Node2D
## The top layer: column band, vignette and dim (no sharp shader).
var _shade: Node2D
## Private RNG for the wisps and troupes (never the gameplay RNG).
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
## Real seconds since the backdrop appeared (drives every animation).
var _t: float = 0.0
## Half the current width (layout px): the visible x range is -_half_w.._half_w.
var _half_w: float = 640.0
## Extra sky height above the 720 px design frame (layout px; > 0 on a tall window).
var _extra_top: float = 0.0

## Star field: one Vector4 per star (x, design y, twinkle speed rad/s, phase rad).
var _stars: Array[Vector4] = []
## Strip frame (0-2) of each star in _stars (same order).
var _star_frames: PackedInt32Array = PackedInt32Array()

## Current dim strength (0 = none, 1 = MenuBackdropData.DIM_ALPHA).
var _dim: float = 0.0
## Target dim strength (0 or 1).
var _dim_target: float = 0.0
## Column band: centre x (from the screen centre), full width (px) and peak alpha (0-1).
var _band: Vector3 = Vector3(MenuBackdropData.BAND_CENTER_X, MenuBackdropData.BAND_WIDTH, MenuBackdropData.BAND_ALPHA)
## Horizontal gradient texture of the column band (alpha 0 -> 1 -> 0).
var _band_tex: GradientTexture2D
## Radial gradient texture of the vignette (alpha 0 in the middle -> 1 at the corners).
var _vignette_tex: GradientTexture2D

## Mood fade: colours at the start of the fade (a MOODS entry), the target
## entry, and the fade progress 0..1 (1 = settled on the target).
var _mood_from: Dictionary = {}
var _mood_to: Dictionary = {}
var _mood_k: float = 1.0
## Id of the current (or target) mood.
var _mood_id: String = MenuBackdropData.DEFAULT_MOOD

## Rising soul wisps. Each: {pos: Vector2 design px, depth: "mid"/"near",
## age: s, life: s, rise: px/s, sway: px, sway_speed: rad/s, phase: rad, frame0: int}.
var _wisps: Array[Dictionary] = []
## Seconds until the next wisp spawns.
var _wisp_timer: float = 0.3
## Walking troupes. Each: {keys: Array of sprite keys, lane: int, dir: 1 / -1,
## speed: px/s, x: leader design x, gaps: Array of float px behind the leader,
## walked: px since entering}.
var _troupes: Array[Dictionary] = []
## Seconds until the next troupe may enter.
var _troupe_timer: float = MenuBackdropData.FIRST_TROUPE_DELAY
## Bats in the sky. Each: {x: design px, y: path design y, dir: 1 / -1,
## speed: px/s, phase: rad (bob and wing phase)}.
var _bats: Array[Dictionary] = []
## Seconds until the next flock of bats.
var _bat_timer: float = MenuBackdropData.BAT_FIRST
## The shooting star in flight: {start: design px, dir: unit Vector2, age: s},
## empty when none.
var _meteor: Dictionary = {}
## Seconds until the next shooting star.
var _meteor_timer: float = MenuBackdropData.METEOR_FIRST
## Random phase offset (s) per flame (lanterns, candles, torches), by index.
var _flame_phase: PackedFloat32Array = PackedFloat32Array()


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_ALWAYS  # Keeps living behind a paused screen too.
	_rng.randomize()
	_mood_to = MenuBackdropData.MOODS[_mood_id]
	_mood_from = _mood_to
	for i in 16:
		_flame_phase.append(_rng.randf() * 10.0)
	_sky = _layer(_draw_sky, true)
	_fx["sky"] = _layer(_draw_sky_fx, true)
	_static["far"] = _layer(_draw_far, true)
	_fx["far"] = _layer(_draw_far_fx, true)
	_static["mid"] = _layer(_draw_mid, true)
	_fx["mid"] = _layer(_draw_mid_fx, true)
	_static["near"] = _layer(_draw_near, true)
	_fx["near"] = _layer(_draw_near_fx, true)
	_shade = _layer(_draw_shade, false)
	_static["sky"] = _sky
	_band_tex = _gradient_tex(false)
	_vignette_tex = _gradient_tex(true)
	resized.connect(_on_resized)
	_on_resized()


## Darkens the diorama (`on`) while a sub-screen covers the menu, or lifts the
## dim; fades over MenuBackdropData.DIM_TIME unless `instant`.
func set_dim(on: bool, instant: bool = false) -> void:
	_dim_target = 1.0 if on else 0.0
	if instant:
		_dim = _dim_target
	_shade.queue_redraw()


## Places the dark band behind the menu column: centre x (layout px from the
## screen centre), full width (px) and peak alpha (0-1; 0 hides it).
func set_band(center_x: float, width: float, alpha: float) -> void:
	_band = Vector3(center_x, width, alpha)
	_shade.queue_redraw()


## Fades the scene's colours to mood `id` (a MenuBackdropData.MOODS key) over
## MOOD_FADE s, or at once when `instant`. Unknown ids are ignored.
func set_mood(id: String, instant: bool = false) -> void:
	if not MenuBackdropData.MOODS.has(id) or (id == _mood_id and _mood_k >= 1.0):
		return
	_mood_from = _current_mood()
	_mood_to = MenuBackdropData.MOODS[id]
	_mood_id = id
	_mood_k = 1.0 if instant else 0.0
	_redraw_static()


## The current mood id ("graveyard" by default).
func mood() -> String:
	return _mood_id


func _process(delta: float) -> void:
	var dt := delta / Engine.time_scale if Engine.time_scale > 0.0 else delta  # Real seconds (UI never scales).
	_t += dt
	if _mood_k < 1.0:
		_mood_k = minf(1.0, _mood_k + dt / MenuBackdropData.MOOD_FADE)
		_redraw_static()
	if not is_equal_approx(_dim, _dim_target):
		_dim = move_toward(_dim, _dim_target, dt / MenuBackdropData.DIM_TIME)
		_shade.queue_redraw()
	_place_layers()
	_update_wisps(dt)
	_update_troupes(dt)
	_update_bats(dt)
	_update_meteor(dt)
	for depth in _fx:
		(_fx[depth] as Node2D).queue_redraw()


# ------------------------------------------------------------------ setup


## A new depth layer node drawn by `painter` (called with no arguments from
## the node's draw signal); `sharp` gives it the sharp-pixel material.
func _layer(painter: Callable, sharp: bool) -> Node2D:
	var n := Node2D.new()  # The layer.
	add_child(n)
	n.draw.connect(painter)
	if sharp:
		SpriteBank.apply_sharp(n)
	return n


## A gradient texture: radial (the vignette, transparent centre to opaque
## corners) or horizontal (the column band, transparent edges, opaque centre).
func _gradient_tex(radial: bool) -> GradientTexture2D:
	var g := Gradient.new()  # Alpha ramp of SHADE_COLOR.
	var c := MenuBackdropData.SHADE_COLOR  # Shade colour.
	var ramp: Array = MenuBackdropData.VIGNETTE_RAMP if radial else MenuBackdropData.BAND_RAMP  # [offset, alpha] stops.
	var offsets := PackedFloat32Array()  # Stop positions (0-1).
	var colors := PackedColorArray()  # Stop colours.
	for stop in ramp:
		offsets.append((stop as Vector2).x)
		colors.append(Color(c, (stop as Vector2).y))
	g.offsets = offsets
	g.colors = colors
	var tex := GradientTexture2D.new()  # The baked texture.
	tex.gradient = g
	tex.width = 128 if radial else 256
	tex.height = 128 if radial else 1
	if radial:
		tex.fill = GradientTexture2D.FILL_RADIAL
		tex.fill_from = Vector2(0.5, 0.5)
		tex.fill_to = Vector2(1.0, 1.0)
	return tex


## Rebuilds the size-dependent parts (star field, layer positions, plain layers).
func _on_resized() -> void:
	_half_w = maxf(size.x, 1.0) * 0.5
	_extra_top = maxf(0.0, size.y - MenuBackdropData.DESIGN_H)
	_build_stars()
	_place_layers()
	_redraw_static()
	_shade.queue_redraw()


## Places every layer node: the screen centre plus the camera drift times the
## layer's parallax, the design frame's bottom on the screen's bottom.
func _place_layers() -> void:
	var w := TAU * _t / MenuBackdropData.DRIFT_PERIOD  # Drift phase (rad).
	var drift := Vector2(sin(w), sin(w * 2.0) * MenuBackdropData.DRIFT_Y_SHARE) * MenuBackdropData.DRIFT_PX  # Near-layer offset (px).
	var origin := Vector2(size.x * 0.5, size.y - MenuBackdropData.DESIGN_H)  # Design (0, 0) on screen.
	for depth in MenuBackdropData.PARALLAX:
		var p := origin + drift * float(MenuBackdropData.PARALLAX[depth])  # This depth's origin.
		(_static[depth] as Node2D).position = p
		(_fx[depth] as Node2D).position = p


## Queues a redraw of every plain layer.
func _redraw_static() -> void:
	for depth in _static:
		(_static[depth] as Node2D).queue_redraw()


## Seeds the star field (fixed seed: the same sky on every visit) over the
## current width, keeping clear of the moon.
func _build_stars() -> void:
	var rng := RandomNumberGenerator.new()  # Star placement only.
	rng.seed = MenuBackdropData.STAR_SEED
	_stars.clear()
	_star_frames.clear()
	var top := -_extra_top  # Highest design y on screen.
	var area := (_half_w * 2.0) * (MenuBackdropData.STAR_MAX_Y - top)  # Sky area (px²).
	var n := int(area / 10000.0 * MenuBackdropData.STAR_DENSITY)  # Star count.
	var tries := 0  # Placement attempts (bounded).
	while _stars.size() < n and tries < n * 6:
		tries += 1
		var x := rng.randf_range(-_half_w, _half_w)  # Star x (design px).
		var y := top + (MenuBackdropData.STAR_MAX_Y - top) * pow(rng.randf(), MenuBackdropData.STAR_HIGH_BIAS)  # Denser high up.
		if Vector2(x, y).distance_to(MenuBackdropData.MOON_POS) < MenuBackdropData.STAR_MOON_CLEAR:
			continue
		_stars.append(Vector4(roundf(x), roundf(y),
				rng.randf_range(MenuBackdropData.STAR_TWINKLE_SPEED.x, MenuBackdropData.STAR_TWINKLE_SPEED.y),
				rng.randf() * TAU))
		var roll := rng.randf()  # Star size roll.
		_star_frames.append(2 if roll < MenuBackdropData.STAR_BRIGHT_SHARE
				else (1 if roll < MenuBackdropData.STAR_BRIGHT_SHARE + MenuBackdropData.STAR_PLUS_SHARE else 0))


# ------------------------------------------------------------------ helpers


## The current mood colours (the fade between _mood_from and _mood_to).
func _current_mood() -> Dictionary:
	if _mood_k >= 1.0:
		return _mood_to
	var out := {}  # Blended entry.
	for k in _mood_to:
		var a: Variant = _mood_from.get(k, _mood_to[k])  # Start value.
		var b: Variant = _mood_to[k]  # Target value.
		if b is Array:
			var arr: Array = []  # Blended colour list.
			for i in (b as Array).size():
				arr.append((a[i] as Color).lerp(b[i] as Color, _mood_k))
			out[k] = arr
		else:
			out[k] = (a as Color).lerp(b as Color, _mood_k)
	return out


## Mood colour `name` right now.
func _c(name: String) -> Color:
	if _mood_k >= 1.0:
		return _mood_to[name]
	return (_mood_from[name] as Color).lerp(_mood_to[name] as Color, _mood_k)


## Texture of sprite `key` (EnvironmentArt cache: the sharp-shader wrapper),
## repeating when `repeat`; null when the PNG is missing.
static func _tex(key: String, repeat: bool = false) -> Texture2D:
	return EnvironmentArt.texture(key, repeat)


## Draws sprite `key` on `ci` with its bottom edge centred on `base` (design
## px), whole layout px, mirrored when `flip`, multiplied by `tint`.
static func _draw_prop(ci: CanvasItem, key: String, base: Vector2, flip: bool, tint: Color) -> void:
	var tex := _tex(key)  # The prop's art, or null (then nothing is drawn).
	if tex == null:
		return
	var s := Vector2(float(tex.get_width()), float(tex.get_height()))  # Size (px).
	var corner := Vector2(roundf(base.x - s.x * 0.5), roundf(base.y - s.y))  # Top-left (whole px).
	if flip:
		ci.draw_set_transform(Vector2(corner.x + s.x, corner.y), 0.0, Vector2(-1.0, 1.0))
		ci.draw_texture_rect(tex, Rect2(Vector2.ZERO, s), false, tint)
		ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	else:
		ci.draw_texture_rect(tex, Rect2(corner, s), false, tint)


## Draws the repeating strip `key` (a tileable texture) across the visible
## width on `ci`, its bottom edge at design y `bottom`, scrolled by `scroll`
## px, multiplied by `tint`.
func _draw_strip(ci: CanvasItem, key: String, bottom: float, scroll: float, tint: Color) -> void:
	var tex := _tex(key, true)  # The strip (repeating).
	if tex == null:
		return
	var w := float(tex.get_width())  # Strip period (px).
	var h := float(tex.get_height())  # Strip height (px).
	var margin := MenuBackdropData.DRIFT_PX + w  # Covers the drift.
	var x0 := floorf((-_half_w - margin - scroll) / w) * w + scroll  # First period's left edge.
	ci.draw_texture_rect(tex, Rect2(x0, roundf(bottom - h), ceilf((_half_w + margin - x0) / w) * w, h), true, tint)


## Draws frame `frame` of the horizontal strip `key` (frames `fw` px wide) on
## `ci`, its bottom-centre at `base` (design px), multiplied by `tint`.
static func _draw_frame(ci: CanvasItem, key: String, fw: float, frame: int, base: Vector2, tint: Color) -> void:
	var tex := _tex(key)  # The strip, or null.
	if tex == null:
		return
	var h := float(tex.get_height())  # Frame height (px).
	ci.draw_texture_rect_region(tex, Rect2(Vector2(roundf(base.x - fw * 0.5), roundf(base.y - h)), Vector2(fw, h)),
			Rect2(fw * float(frame), 0.0, fw, h), tint)


## Draws the glow disc centred on `c` (design px), `scale` times its size, in `col`.
static func _draw_glow(ci: CanvasItem, c: Vector2, scale: float, col: Color) -> void:
	var tex := _tex(MenuBackdropData.ART + "glow")  # Stepped glow disc, or null.
	if tex == null:
		return
	var s := Vector2(float(tex.get_width()), float(tex.get_height())) * scale  # Drawn size (px).
	ci.draw_texture_rect(tex, Rect2(c - s * 0.5, s), false, col)


## A flicker factor around 1 (±FLICKER) for flame `i` at time `_t`: two
## incommensurate sines, so it never visibly repeats.
func _flicker(i: int) -> float:
	var p := _flame_phase[i % _flame_phase.size()]  # This flame's phase (s).
	var f := 0.6 * sin((_t + p) * 7.3) + 0.4 * sin((_t + p) * 12.9 + 1.7)  # -1..1.
	return 1.0 + MenuBackdropData.FLICKER * f


## Flame strip frame (0-2) of flame `i` right now.
func _flame_frame(i: int) -> int:
	return int((_t + _flame_phase[i % _flame_phase.size()]) * MenuBackdropData.FLAME_FPS) % 3


# ------------------------------------------------------------------ sky


## Sky: flat colour bands, the top one stretched up over any extra height.
func _draw_sky() -> void:
	var cols: Array = _current_mood()["sky"]  # Band colours, top to bottom.
	var top := -_extra_top - 4.0  # Screen top in design px.
	var x0 := -_half_w - MenuBackdropData.DRIFT_PX - 4.0  # Left edge (px).
	var w := (_half_w + MenuBackdropData.DRIFT_PX + 4.0) * 2.0  # Width (px).
	var y := top  # Current band top.
	for i in MenuBackdropData.SKY_BAND_ENDS.size():
		var end := float(MenuBackdropData.SKY_BAND_ENDS[i])  # Band bottom (design px).
		_sky.draw_rect(Rect2(x0, y, w, end - y), cols[mini(i, cols.size() - 1)])
		y = end


## Stars (twinkling), the moon's breathing halo, the moon, the bats and the clouds.
func _draw_sky_fx() -> void:
	var ci := _fx["sky"] as Node2D  # This layer.
	var star_col := _c("star")  # Star colour (alpha = brightness).
	var stars := _tex(MenuBackdropData.ART + "stars")  # 3-frame star strip.
	if stars != null:
		for i in _stars.size():
			var s := _stars[i]  # x, y, speed, phase.
			var tw := 1.0 - MenuBackdropData.STAR_TWINKLE * (0.5 + 0.5 * sin(_t * s.z + s.w))  # Twinkle 0..1.
			var f := _star_frames[i]  # Strip frame.
			ci.draw_texture_rect_region(stars, Rect2(s.x - 2.0, s.y - 2.0, 5.0, 5.0), Rect2(5.0 * float(f), 0.0, 5.0, 5.0),
					Color(star_col, star_col.a * tw))
	_draw_meteor(ci, star_col)
	var moon := MenuBackdropData.MOON_POS  # Moon centre (design px).
	var halo := _c("halo")  # Halo colour and strength.
	var breath := 1.0 + MenuBackdropData.HALO_PULSE * sin(TAU * _t / MenuBackdropData.HALO_PERIOD)  # Halo pulse.
	var halo_tex := _tex(MenuBackdropData.ART + "moon_halo")  # Stepped halo.
	if halo_tex != null:
		var hs := Vector2(float(halo_tex.get_width()), float(halo_tex.get_height()))  # Halo size (px).
		ci.draw_texture_rect(halo_tex, Rect2((moon - hs * 0.5).round(), hs), false, Color(halo, halo.a * breath))
	var moon_tex := _tex(MenuBackdropData.ART + "moon")  # The moon.
	if moon_tex != null:
		var ms := Vector2(float(moon_tex.get_width()), float(moon_tex.get_height()))  # Moon size (px).
		ci.draw_texture_rect(moon_tex, Rect2((moon - ms * 0.5).round(), ms), false, _c("moon"))
	_draw_bats(ci)
	var cloud_col := _c("cloud")  # Cloud tint.
	var span := (_half_w + MenuBackdropData.CLOUD_WRAP_MARGIN) * 2.0  # Wrap length (px).
	for cl in MenuBackdropData.CLOUDS:
		var tex := _tex(MenuBackdropData.ART + String(cl[0]))  # Cloud art.
		if tex == null:
			continue
		var x := fposmod(float(cl[2]) + float(cl[3]) * _t + span * 0.5, span) - span * 0.5  # Wrapped centre x.
		var cs := Vector2(float(tex.get_width()), float(tex.get_height()))  # Cloud size (px).
		ci.draw_texture_rect(tex, Rect2(Vector2(x - cs.x * 0.5, float(cl[1]) - cs.y * 0.5), cs), false,
				Color(cloud_col, cloud_col.a * float(cl[4])))


## Ages the shooting star and launches a new one now and then.
func _update_meteor(dt: float) -> void:
	if not _meteor.is_empty():
		_meteor["age"] = float(_meteor["age"]) + dt
		if float(_meteor["age"]) >= MenuBackdropData.METEOR_LIFE:
			_meteor = {}
		return
	_meteor_timer -= dt
	if _meteor_timer > 0.0:
		return
	_meteor_timer = _rng.randf_range(MenuBackdropData.METEOR_INTERVAL.x, MenuBackdropData.METEOR_INTERVAL.y)
	var side := 1.0 if _rng.randf() < 0.5 else -1.0  # 1 = falls toward the right.
	_meteor = {
		"start": Vector2(_rng.randf_range(-_half_w * 0.9, _half_w * 0.9), _rng.randf_range(MenuBackdropData.METEOR_Y.x, MenuBackdropData.METEOR_Y.y)),
		"dir": Vector2(side, _rng.randf_range(MenuBackdropData.METEOR_SLOPE.x, MenuBackdropData.METEOR_SLOPE.y)).normalized(), "age": 0.0,
	}


## Draws the shooting star: a bright head and a fading tail of 2x1 px dashes
## (whole px, pixel-art style; the head 2x2), fading in and out over its short life.
func _draw_meteor(ci: CanvasItem, col: Color) -> void:
	if _meteor.is_empty():
		return
	var age := float(_meteor["age"])  # Seconds in flight.
	var dir := _meteor["dir"] as Vector2  # Flight direction.
	var head := (_meteor["start"] as Vector2) + dir * MenuBackdropData.METEOR_SPEED * age  # Head (design px).
	var life := age / MenuBackdropData.METEOR_LIFE  # 0..1.
	var fade := minf(1.0, life * 5.0) * minf(1.0, (1.0 - life) * 3.0)  # In and out.
	var steps := int(MenuBackdropData.METEOR_TAIL / 2.0)  # Dashes in the tail.
	for i in steps:
		var p := (head - dir * float(i) * 2.0).round()  # Dash position (whole px).
		var a := fade * (1.0 - float(i) / float(steps))  # Tail fade.
		ci.draw_rect(Rect2(p, Vector2(2.0, 1.0 if i > 0 else 2.0)), Color(col, a))


## Moves the bats, drops those out of the sky, and sends in a new flock now and then.
func _update_bats(dt: float) -> void:
	for i in range(_bats.size() - 1, -1, -1):
		var b := _bats[i]  # One bat.
		b["x"] = float(b["x"]) + float(b["speed"]) * float(b["dir"]) * dt
		if float(b["x"]) * float(b["dir"]) > _half_w + MenuBackdropData.EDGE_MARGIN:
			_bats.remove_at(i)
	_bat_timer -= dt
	if _bat_timer > 0.0 or not _bats.is_empty():
		return
	_bat_timer = _rng.randf_range(MenuBackdropData.BAT_INTERVAL.x, MenuBackdropData.BAT_INTERVAL.y)
	var dir := 1.0 if _rng.randf() < 0.5 else -1.0  # 1 = flies right.
	var y := _rng.randf_range(MenuBackdropData.BAT_Y.x, MenuBackdropData.BAT_Y.y)  # Flock path (design y).
	var speed := _rng.randf_range(MenuBackdropData.BAT_SPEED.x, MenuBackdropData.BAT_SPEED.y)  # Flock speed (px/s).
	for i in _rng.randi_range(MenuBackdropData.BAT_COUNT.x, MenuBackdropData.BAT_COUNT.y):
		_bats.append({
			"x": -dir * (_half_w + MenuBackdropData.EDGE_MARGIN * 0.5 + float(i) * _rng.randf_range(MenuBackdropData.BAT_SPACING.x, MenuBackdropData.BAT_SPACING.y)),
			"y": y + _rng.randf_range(-MenuBackdropData.BAT_Y_JITTER, MenuBackdropData.BAT_Y_JITTER), "dir": dir,
			"speed": speed * _rng.randf_range(1.0 - MenuBackdropData.BAT_SPEED_JITTER, 1.0 + MenuBackdropData.BAT_SPEED_JITTER), "phase": _rng.randf() * TAU,
		})


## Draws the bats (2-frame wing strip, mirrored for a bat flying left).
func _draw_bats(ci: CanvasItem) -> void:
	var tex := _tex(MenuBackdropData.ART + "bat")  # Bat strip, or null.
	if tex == null:
		return
	var fw := float(tex.get_width()) * 0.5  # Frame width (px).
	var fh := float(tex.get_height())  # Frame height (px).
	for b in _bats:
		var ph := float(b["phase"]) + _t * MenuBackdropData.BAT_FLAP_FPS * PI  # Wing phase (rad).
		var f := 0 if sin(ph) > 0.0 else 1  # Wings up / down.
		var p := Vector2(float(b["x"]), float(b["y"]) + sin(ph * 0.5) * MenuBackdropData.BAT_BOB)  # Position (design px).
		ci.draw_set_transform(p, 0.0, Vector2(float(b["dir"]), 1.0))
		ci.draw_texture_rect_region(tex, Rect2(Vector2(-fw * 0.5, -fh * 0.5), Vector2(fw, fh)), Rect2(fw * float(f), 0.0, fw, fh))
		ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


# ------------------------------------------------------------------ far


## The far set pieces, then the far hill strip over their bases.
func _draw_far() -> void:
	var ci := _static["far"] as Node2D  # This layer.
	var tint := _c("far")  # Far props tint (haze).
	for p in MenuBackdropData.FAR_PROPS:
		var k := float(p[4])  # This piece's brightness.
		_draw_prop(ci, String(p[0]), Vector2(float(p[1]), float(p[2])), bool(p[3]), Color(tint.r * k, tint.g * k, tint.b * k))
	_draw_strip(ci, MenuBackdropData.ART + "hills_far", MenuBackdropData.HILLS_FAR_BOTTOM, 0.0, _c("far_hills"))


## The far fog bank and the Covenant torches on the horizon.
func _draw_far_fx() -> void:
	var ci := _fx["far"] as Node2D  # This layer.
	var torch := _c("torch")  # Torch colour.
	var i := 0  # Flame index (flicker phase).
	for tp in MenuBackdropData.TORCHES:
		var a := MenuBackdropData.TORCH_GLOW_ALPHA * _flicker(i)  # Glow alpha.
		_draw_glow(ci, tp, MenuBackdropData.TORCH_GLOW_SCALE, Color(torch, a * 0.5))
		ci.draw_rect(Rect2((tp as Vector2).round() - Vector2(1.0, 1.0), Vector2(2.0, 2.0)), Color(torch.lightened(0.4), minf(1.0, a + 0.3)))
		i += 1
	_draw_fog(ci, "far")


## The fog banks that belong after depth `depth` (MenuBackdropData.FOG).
func _draw_fog(ci: CanvasItem, depth: String) -> void:
	var fog := _c("fog")  # Fog colour.
	var swell := 1.0 + MenuBackdropData.FOG_PULSE * sin(TAU * _t / MenuBackdropData.FOG_PERIOD)  # Breathing.
	for f in MenuBackdropData.FOG:
		if String(f[4]) != depth:
			continue
		var a := float(f[3]) * (swell if depth != "mid" else 2.0 - swell)  # Banks breathe out of step.
		_draw_strip(ci, MenuBackdropData.ART + String(f[0]), float(f[1]), float(f[2]) * _t, Color(fog, a))


# ------------------------------------------------------------------ mid


## The mid graveyard: fences, props, lantern posts and candle clusters.
func _draw_mid() -> void:
	var ci := _static["mid"] as Node2D  # This layer.
	var tint := _c("mid")  # Night light on the mid props.
	_draw_strip(ci, MenuBackdropData.ART + "hills_mid", MenuBackdropData.HILLS_MID_BOTTOM, 0.0, _c("mid_hills"))
	_draw_fences(ci, tint)
	for p in MenuBackdropData.MID_PROPS:
		_draw_prop(ci, String(p[0]), Vector2(float(p[1]), float(p[2])), bool(p[3]), tint)
	_draw_fixtures(ci, "mid", tint)


## The fence runs (repeating fence sections, clipped to each run's span).
func _draw_fences(ci: CanvasItem, tint: Color) -> void:
	var tex := _tex(MenuBackdropData.ART + "fence", true)  # Fence section (repeating).
	if tex == null:
		return
	var h := float(tex.get_height())  # Fence height (px).
	for run in MenuBackdropData.FENCES:
		var x0 := float(run[0])  # Run start (px).
		var x1 := float(run[1])  # Run end (px).
		ci.draw_texture_rect(tex, Rect2(roundf(x0), roundf(float(run[2]) - h), roundf(x1 - x0), h), true, tint)


## Lantern posts and candle clusters of depth `depth` (their flames are fx).
func _draw_fixtures(ci: CanvasItem, depth: String, tint: Color) -> void:
	for l in MenuBackdropData.LANTERNS:
		if String(l[2]) == depth:
			_draw_prop(ci, MenuBackdropData.ART + "lantern", Vector2(float(l[0]), float(l[1])), false, tint)
	for c in MenuBackdropData.CANDLES:
		if String(c[2]) == depth:
			_draw_prop(ci, MenuBackdropData.ART + "candles", Vector2(float(c[0]), float(c[1])), false, tint.lightened(0.15))


## The mid fog bank, lantern / candle flames and glows, and the mid wisps.
func _draw_mid_fx() -> void:
	var ci := _fx["mid"] as Node2D  # This layer.
	_draw_fog(ci, "mid")
	_draw_flames(ci, "mid")
	_draw_wisps(ci, "mid")


## Flames and glows of the lanterns and candle clusters of depth `depth`.
func _draw_flames(ci: CanvasItem, depth: String) -> void:
	var soul := MenuBackdropData.SOUL_GLOW  # Soul-fire glow colour (teal).
	var warm := MenuBackdropData.CANDLE_GLOW  # Candle glow colour.
	var i := 0  # Flame index.
	for l in MenuBackdropData.LANTERNS:
		i += 1
		if String(l[2]) != depth:
			continue
		var c := Vector2(float(l[0]), float(l[1]) - MenuBackdropData.LANTERN_FLAME_UP)  # Flame centre.
		_draw_glow(ci, c, MenuBackdropData.LANTERN_GLOW_SCALE, Color(soul, MenuBackdropData.LANTERN_GLOW_ALPHA * _flicker(i)))
		_draw_frame(ci, MenuBackdropData.ART + "flame_soul", 5.0, _flame_frame(i), c + Vector2(0.0, 4.0), Color.WHITE)
	for cd in MenuBackdropData.CANDLES:
		i += 1
		if String(cd[2]) != depth:
			continue
		var tex := _tex(MenuBackdropData.ART + "candles")  # For the cluster's size.
		var corner := Vector2(roundf(float(cd[0]) - 7.5), float(cd[1]))  # Bottom-left (px).
		if tex != null:
			corner.x = roundf(float(cd[0]) - float(tex.get_width()) * 0.5)
		_draw_glow(ci, corner + MenuBackdropData.CANDLE_GLOW_OFFSET, MenuBackdropData.CANDLE_GLOW_SCALE, Color(warm, MenuBackdropData.CANDLE_GLOW_ALPHA * _flicker(i)))
		var k := 0  # Wick index.
		for wick in MenuBackdropData.CANDLE_WICKS:
			_draw_frame(ci, MenuBackdropData.ART + "candle_flame", 3.0, (_flame_frame(i) + k) % 3, corner + (wick as Vector2), Color.WHITE)
			k += 1


# ------------------------------------------------------------------ near


## The near ground (Graveyard tile under the ragged lip, its floor decals),
## near fixtures and props.
func _draw_near() -> void:
	var ci := _static["near"] as Node2D  # This layer.
	var top := MenuBackdropData.GROUND_TOP  # Ground top (design px).
	var tile := _tex(MenuBackdropData.GROUND_TILE, true)  # Floor tile (repeating), or null.
	var x0 := -_half_w - MenuBackdropData.DRIFT_PX - 8.0  # Left edge (px).
	var w := (_half_w + MenuBackdropData.DRIFT_PX + 8.0) * 2.0  # Width (px).
	var h := MenuBackdropData.DESIGN_H - top + MenuBackdropData.DRIFT_PX + 8.0  # Height to below the bottom (px).
	if tile != null:
		var tw := float(tile.get_width())  # Tile size (px).
		var tx := floorf(x0 / tw) * tw  # On the tile grid.
		ci.draw_texture_rect(tile, Rect2(tx, top, w + tw, h), true, _c("ground"))
	else:
		ci.draw_rect(Rect2(x0, top, w, h), Color("161a1c"))
	var lip := _tex(MenuBackdropData.ART + "ground_lip", true)  # Ground edge strip.
	if lip != null:
		_draw_strip(ci, MenuBackdropData.ART + "ground_lip", top + float(lip.get_height()) - 4.0, 0.0, _c("ground"))
	var ground := _c("ground")  # Floor tint (the decals lie on the floor).
	for d in MenuBackdropData.NEAR_DECALS:
		var dt := _tex(String(d[0]))  # Decal art, or null.
		if dt != null:
			var ds := Vector2(float(dt.get_width()), float(dt.get_height()))  # Decal size (px).
			ci.draw_texture_rect(dt, Rect2((Vector2(float(d[1]), float(d[2])) - ds * 0.5).round(), ds), false, ground)
	var tint := _c("near")  # Foreground (darker) tint.
	_draw_fixtures(ci, "near", _c("mid"))
	for p in MenuBackdropData.NEAR_PROPS:
		_draw_prop(ci, String(p[0]), Vector2(float(p[1]), float(p[2])), bool(p[3]), tint)


## Near wisps, flames, the walking troupes and the near fog bank.
func _draw_near_fx() -> void:
	var ci := _fx["near"] as Node2D  # This layer.
	_draw_flames(ci, "near")
	_draw_wisps(ci, "near")
	for lane in MenuBackdropData.LANES.size():
		for tr in _troupes:
			if int(tr["lane"]) == lane:
				_draw_troupe(ci, tr)
	_draw_fog(ci, "near")


# ------------------------------------------------------------------ wisps


## Spawns and ages the soul wisps.
func _update_wisps(dt: float) -> void:
	_wisp_timer -= dt
	if _wisp_timer <= 0.0:
		_wisp_timer = _rng.randf_range(MenuBackdropData.WISP_INTERVAL.x, MenuBackdropData.WISP_INTERVAL.y)
		if _wisps.size() < MenuBackdropData.WISP_MAX:
			_spawn_wisp()
	for i in range(_wisps.size() - 1, -1, -1):
		var w := _wisps[i]  # One wisp.
		w["age"] = float(w["age"]) + dt
		if float(w["age"]) >= float(w["life"]):
			_wisps.remove_at(i)


## A new wisp at a grave (WISP_SOURCES) or a random point of the near ground.
func _spawn_wisp() -> void:
	var pos: Vector2  # Start (design px).
	var depth := "near"  # Its layer.
	if _rng.randf() < MenuBackdropData.WISP_GROUND_SHARE:
		pos = Vector2(_rng.randf_range(-_half_w, _half_w), _rng.randf_range(MenuBackdropData.WISP_GROUND_Y.x, MenuBackdropData.WISP_GROUND_Y.y))
	else:
		var src: Array = MenuBackdropData.WISP_SOURCES[_rng.randi() % MenuBackdropData.WISP_SOURCES.size()]  # A grave.
		pos = Vector2(float(src[0]) + _rng.randf_range(-MenuBackdropData.WISP_SOURCE_JITTER, MenuBackdropData.WISP_SOURCE_JITTER), float(src[1]))
		depth = String(src[2])
	_wisps.append({
		"pos": pos, "depth": depth, "age": 0.0,
		"life": _rng.randf_range(MenuBackdropData.WISP_LIFE.x, MenuBackdropData.WISP_LIFE.y),
		"rise": _rng.randf_range(MenuBackdropData.WISP_RISE.x, MenuBackdropData.WISP_RISE.y),
		"sway": _rng.randf_range(MenuBackdropData.WISP_SWAY.x, MenuBackdropData.WISP_SWAY.y),
		"sway_speed": _rng.randf_range(MenuBackdropData.WISP_SWAY_SPEED.x, MenuBackdropData.WISP_SWAY_SPEED.y),
		"phase": _rng.randf() * TAU, "frame0": _rng.randi() % 4,
	})


## Draws the wisps of depth `depth`: a soft glow, then the flickering flame.
func _draw_wisps(ci: CanvasItem, depth: String) -> void:
	var soul := MenuBackdropData.SOUL_GLOW  # Glow colour.
	for w in _wisps:
		if String(w["depth"]) != depth:
			continue
		var age := float(w["age"])  # Seconds alive.
		var life := float(w["life"])  # Lifetime (s).
		var a := minf(1.0, age / MenuBackdropData.WISP_FADE_IN) * minf(1.0, (life - age) / MenuBackdropData.WISP_FADE_OUT)  # Fade.
		if depth == "mid":
			a *= MenuBackdropData.WISP_MID_ALPHA
		var p := (w["pos"] as Vector2) + Vector2(sin(age * float(w["sway_speed"]) + float(w["phase"])) * float(w["sway"]),
				-age * float(w["rise"]))  # Current position (design px).
		_draw_glow(ci, p + Vector2(0.0, -MenuBackdropData.WISP_GLOW_UP), MenuBackdropData.WISP_GLOW_SCALE, Color(soul, MenuBackdropData.WISP_GLOW_ALPHA * a))
		var f := (int(age * MenuBackdropData.WISP_FPS) + int(w["frame0"])) % 4  # Strip frame.
		_draw_frame(ci, MenuBackdropData.ART + "wisp", 9.0, f, p, Color(1.0, 1.0, 1.0, a))


# ------------------------------------------------------------------ walkers


## Moves the troupes, retires those that left the frame, and sends in new ones.
func _update_troupes(dt: float) -> void:
	for i in range(_troupes.size() - 1, -1, -1):
		var tr := _troupes[i]  # One troupe.
		var step := float(tr["speed"]) * dt  # Px this frame.
		tr["x"] = float(tr["x"]) + step * float(tr["dir"])
		tr["walked"] = float(tr["walked"]) + step
		var gaps: Array = tr["gaps"]  # Offsets behind the leader.
		var tail := float(tr["x"]) - float(tr["dir"]) * float(gaps[gaps.size() - 1])  # Last member's x.
		if tail * float(tr["dir"]) > _half_w + MenuBackdropData.DRIFT_PX + MenuBackdropData.EDGE_MARGIN * 1.5:
			_troupes.remove_at(i)
	if _troupes.size() >= MenuBackdropData.TROUPE_MAX:
		return
	_troupe_timer -= dt
	if _troupe_timer > 0.0:
		return
	_troupe_timer = _rng.randf_range(MenuBackdropData.TROUPE_INTERVAL.x, MenuBackdropData.TROUPE_INTERVAL.y)
	var free_lanes: Array[int] = []  # Lanes no troupe walks.
	for lane in MenuBackdropData.LANES.size():
		var used := false  # A troupe already walks this lane.
		for tr in _troupes:
			used = used or int(tr["lane"]) == lane
		if not used:
			free_lanes.append(lane)
	if free_lanes.is_empty():
		return
	_spawn_troupe(free_lanes[_rng.randi() % free_lanes.size()])


## Sends a random troupe (TROUPES by TROUPE_WEIGHTS) along lane `lane` from a random side.
func _spawn_troupe(lane: int) -> void:
	var total := 0.0  # Sum of weights.
	for wt in MenuBackdropData.TROUPE_WEIGHTS:
		total += float(wt)
	var roll := _rng.randf() * total  # Weighted pick.
	var pick := 0  # Picked TROUPES index.
	for i in MenuBackdropData.TROUPE_WEIGHTS.size():
		roll -= float(MenuBackdropData.TROUPE_WEIGHTS[i])
		if roll <= 0.0:
			pick = i
			break
	var keys: Array = MenuBackdropData.TROUPES[pick]  # Members, leader first.
	var hounds := String(keys[0]).ends_with("hound")  # Hounds trot faster.
	var dir := 1.0 if _rng.randf() < 0.5 else -1.0  # 1 = walks right.
	var gaps: Array = [0.0]  # Distance of each member behind the leader (px).
	for i in range(1, keys.size()):
		var ahead := _tex(String(keys[i - 1]))  # The member in front (its width keeps them apart).
		var room := float(ahead.get_width()) + MenuBackdropData.TROUPE_MIN_CLEARANCE if ahead != null else 0.0  # Never overlap (px).
		gaps.append(float(gaps[i - 1]) + maxf(room, _rng.randf_range(MenuBackdropData.TROUPE_GAP.x, MenuBackdropData.TROUPE_GAP.y)))
	_troupes.append({
		"keys": keys, "lane": lane, "dir": dir,
		"speed": MenuBackdropData.HOUND_SPEED if hounds else _rng.randf_range(MenuBackdropData.TROUPE_SPEED.x, MenuBackdropData.TROUPE_SPEED.y),
		"x": -dir * (_half_w + MenuBackdropData.DRIFT_PX + MenuBackdropData.EDGE_MARGIN * 0.6), "gaps": gaps, "walked": 0.0,
	})


## Draws one troupe's members on their walk strips (still when there is no strip).
func _draw_troupe(ci: CanvasItem, tr: Dictionary) -> void:
	var lane: Array = MenuBackdropData.LANES[int(tr["lane"])]  # [feet y, tint factor].
	var feet := float(lane[0])  # Feet line (design px).
	var shade := float(lane[1])  # Lane darkening.
	var actor := _c("actor")  # Night tint of the walkers.
	var tint := Color(actor.r * shade, actor.g * shade, actor.b * shade)  # Final tint.
	var dir := float(tr["dir"])  # Facing (1 = right).
	var keys: Array = tr["keys"]  # Member sprite keys.
	var gaps: Array = tr["gaps"]  # Offsets behind the leader.
	var sh := MenuBackdropData.WALKER_SHADOW  # Shadow width share, squash, alpha.
	for i in keys.size():
		var key := String(keys[i])  # Member sprite key.
		var still := _tex(key)  # Still art (for the size), or null.
		if still == null:
			continue
		var x := float(tr["x"]) - dir * float(gaps[i])  # Member x (design px).
		if absf(x) > _half_w + MenuBackdropData.DRIFT_PX + MenuBackdropData.EDGE_MARGIN * 1.25:
			continue
		var fw := float(still.get_width())  # Frame width (px).
		var fh := float(still.get_height())  # Frame height (px).
		var strip := _tex(key + WalkData.SUFFIX)  # Walk strip, or null.
		var frames := 1  # Frames in the strip (1 = still only).
		if strip != null and strip.get_height() == still.get_height() and strip.get_width() % still.get_width() == 0:
			frames = strip.get_width() / still.get_width()
		var walked := float(tr["walked"]) + float(gaps[i]) * MenuBackdropData.TROUPE_STEP_SHIFT  # Members out of step.
		var f := int(walked / MenuBackdropData.STRIDE_PER_FRAME) % frames  # Strip frame.
		# Shadow at the feet (the game's drop-shadow look).
		ci.draw_set_transform(Vector2(x, feet - 1.0), 0.0, Vector2(1.0, sh.y))
		ci.draw_circle(Vector2.ZERO, fh * sh.x * 0.5, Color(0.0, 0.0, 0.0, sh.z))
		ci.draw_set_transform(Vector2(roundf(x), feet), 0.0, Vector2(dir, 1.0))
		var dst := Rect2(Vector2(-roundf(fw * 0.5), -fh), Vector2(fw, fh))  # Feet on the lane.
		if frames > 1:
			ci.draw_texture_rect_region(strip, dst, Rect2(fw * float(f), 0.0, fw, fh), tint)
		else:
			ci.draw_texture_rect(still, dst, false, tint)
		ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


# ------------------------------------------------------------------ shade


## The dark band behind the menu column, the edge vignette and the dim.
func _draw_shade() -> void:
	var full := Rect2(Vector2.ZERO, size)  # The whole screen (this layer stays at the origin, in screen px).
	if _band.z > 0.0 and _band.y > 0.0:
		_shade.draw_texture_rect(_band_tex, Rect2(size.x * 0.5 + _band.x - _band.y * 0.5, 0.0, _band.y, size.y),
				false, Color(1.0, 1.0, 1.0, _band.z))
	_shade.draw_texture_rect(_vignette_tex, full, false, Color(1.0, 1.0, 1.0, MenuBackdropData.VIGNETTE_ALPHA))
	if _dim > 0.0:
		_shade.draw_rect(full, Color(MenuBackdropData.SHADE_COLOR, MenuBackdropData.DIM_ALPHA * _dim))
