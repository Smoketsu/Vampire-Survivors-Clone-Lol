## MenuLogo — the title screen's NECROPATHY logo, alive (GDD §15.0 "Front door
## screens"; numbers in FrontDoorData "logo"). The logo PNG (UiArtData.LOGO)
## is split once into its letters and its five soul flames (the pixels of
## FrontDoorData.LOGO_FLAME_COLORS); the flames are rebuilt as a short loop of
## frames in which each art row of a flame shifts sideways by whole art px,
## more toward the tip, along a wave that climbs it, so the fire sways as true
## pixel art. Behind each flame a stepped soul glow breathes, and small soul
## embers drift up from the tips. Everything is drawn at UiArtData.LOGO_SCALE
## (a whole number) through the sharp-pixel shader, so it stays crisp at any
## window scale. With motion off (UiMotion.enabled(): the autotest, Reduce
## motion) it is the still logo with a steady glow. Purely cosmetic: real
## time, a private RNG, no gameplay state. Falls back to the TITLE-tier word
## when the PNG is missing (MainMenu checks has_art()).
class_name MenuLogo
extends Control

## The letters (the logo without its flame pixels), or null without art.
var _letters: Texture2D = null
## The flame loop's frames (FrontDoorData.LOGO_FLAME_FRAMES textures).
var _frames: Array[Texture2D] = []
## Each flame's tip (art px from the logo's top-left: x centre, top row).
var _tips: Array[Vector2] = []
## Logo size (art px).
var _art_size: Vector2 = Vector2.ZERO
## Layout px per art px.
var _scale: int = UiArtData.LOGO_SCALE
## Real seconds since the logo appeared (drives the loop, glow and embers).
var _t: float = 0.0
## Rising embers. Each: {pos: Vector2 art px, rise: art px/s, drift: art px/s,
## age: s, life: s, col: Color}.
var _embers: Array[Dictionary] = []
## Seconds until the next ember.
var _ember_timer: float = 0.4
## Private RNG for the embers (never the gameplay RNG).
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rng.randomize()
	_build()
	custom_minimum_size = _art_size * float(_scale)


func _ready() -> void:
	SpriteBank.apply_sharp(self)


## True when the logo art exists (else the menu shows the word instead).
func has_art() -> bool:
	return _letters != null


func _process(delta: float) -> void:
	if _letters == null or not UiMotion.enabled():
		return
	var dt := delta / Engine.time_scale if Engine.time_scale > 0.0 else delta  # Real seconds.
	_t += dt
	_update_embers(dt)
	queue_redraw()


func _draw() -> void:
	if _letters == null:
		return
	var o := (((size - _art_size * float(_scale)) * 0.5) / float(_scale)).floor() * float(_scale)  # Top-left (px, on the art grid).
	var k := float(_scale)  # Layout px per art px.
	var moving := UiMotion.enabled()  # The loop runs.
	var glow := EnvironmentArt.texture(MenuBackdropData.ART + "glow")  # Stepped glow disc, or null.
	if glow != null:
		var gs := Vector2(float(glow.get_width()), float(glow.get_height())) * FrontDoorData.LOGO_GLOW_SCALE * k  # Glow size (px).
		for i in _tips.size():
			var pulse := 1.0 + (FrontDoorData.LOGO_GLOW_PULSE * sin(TAU * _t / FrontDoorData.LOGO_GLOW_PERIOD + float(i) * 1.3) if moving else 0.0)  # Breath.
			var c := o + (_tips[i] + Vector2(0.0, 9.0)) * k  # Glow centre (px): the flame's middle.
			draw_texture_rect(glow, Rect2((c - gs * 0.5).round(), gs), false, Color(FrontDoorData.LOGO_EMBER_COLORS[1], FrontDoorData.LOGO_GLOW_ALPHA * pulse))
	var sz := _art_size * k  # Drawn logo size (px).
	draw_texture_rect(_letters, Rect2(o, sz), false)
	if not _frames.is_empty():
		var f := int(_t * FrontDoorData.LOGO_FLAME_FPS) % _frames.size() if moving else 0  # Loop frame.
		draw_texture_rect(_frames[f], Rect2(o, sz), false)
	for e in _embers:
		var a := minf(1.0, float(e["age"]) * 4.0) * clampf((float(e["life"]) - float(e["age"])) / (float(e["life"]) * 0.5), 0.0, 1.0)  # Fade in / out.
		var p := ((e["pos"] as Vector2)).floor() * k + o  # Whole art px (px).
		draw_rect(Rect2(p, Vector2(k, k)), Color(e["col"] as Color, a))


## Splits the logo into letters and flame frames.
func _build() -> void:
	if not ResourceLoader.exists(UiArtData.LOGO):
		return
	var tex := load(UiArtData.LOGO) as Texture2D  # The wordmark.
	if tex == null:
		return
	var img := tex.get_image()  # Its pixels.
	if img == null:
		return
	if img.is_compressed():
		img.decompress()
	img.convert(Image.FORMAT_RGBA8)
	var w := img.get_width()
	var h := img.get_height()
	_art_size = Vector2(float(w), float(h))
	var flame := {}  # Vector2i -> Color: the flame pixels.
	var letters := img.duplicate() as Image  # The logo minus its flames.
	for y in h:
		for x in w:
			var c := img.get_pixel(x, y)  # This pixel.
			if c.a > 0.5 and _is_flame(c):
				flame[Vector2i(x, y)] = c
				letters.set_pixel(x, y, Color(0, 0, 0, 0))
	_letters = _wrap(letters)
	var comps := _components(flame)  # Each flame: Array of Vector2i.
	for ci in comps.size():
		var comp: Array = comps[ci]
		var top := h  # Tip row.
		var base := 0  # Base row.
		var xsum := 0.0  # For the tip's centre.
		var xn := 0  # Pixels in the tip row.
		for p: Vector2i in comp:
			top = mini(top, p.y)
			base = maxi(base, p.y)
		for p: Vector2i in comp:
			if p.y == top:
				xsum += float(p.x)
				xn += 1
		_tips.append(Vector2(xsum / float(maxi(1, xn)) + 0.5, float(top)))
	for f in FrontDoorData.LOGO_FLAME_FRAMES:
		var frame := Image.create(w, h, false, Image.FORMAT_RGBA8)  # This frame's flames.
		frame.fill(Color(0, 0, 0, 0))
		var phase := TAU * float(f) / float(FrontDoorData.LOGO_FLAME_FRAMES)  # Loop phase (rad).
		for ci in comps.size():
			var comp: Array = comps[ci]
			var top := h
			var base := 0
			for p: Vector2i in comp:
				top = mini(top, p.y)
				base = maxi(base, p.y)
			var span := float(maxi(1, base - top))  # Flame height (art px).
			for p: Vector2i in comp:
				var up := float(base - p.y)  # Height above the base (art px).
				var k := pow(up / span, 1.5)  # More sway toward the tip.
				var dx := roundi(FrontDoorData.LOGO_FLAME_SWAY * k * sin(phase + float(ci) * 1.7 - up * FrontDoorData.LOGO_FLAME_WAVE))  # Whole art px.
				var x := clampi(p.x + dx, 0, w - 1)
				frame.set_pixel(x, p.y, flame[p])
		_frames.append(_wrap(frame))


## True when `c` is one of the flame colours.
static func _is_flame(c: Color) -> bool:
	for fc: Color in FrontDoorData.LOGO_FLAME_COLORS:
		if absf(c.r - fc.r) < 0.02 and absf(c.g - fc.g) < 0.02 and absf(c.b - fc.b) < 0.02:
			return true
	return false


## The 8-connected groups of the flame pixels (one per flame).
static func _components(px: Dictionary) -> Array:
	var seen := {}  # Visited pixels.
	var out: Array = []  # Groups.
	for start: Vector2i in px:
		if seen.has(start):
			continue
		var comp: Array = []  # This group.
		var stack: Array[Vector2i] = [start]
		seen[start] = true
		while not stack.is_empty():
			var p: Vector2i = stack.pop_back()
			comp.append(p)
			for dy in range(-1, 2):
				for dx in range(-1, 2):
					var q := p + Vector2i(dx, dy)  # Neighbour.
					if px.has(q) and not seen.has(q):
						seen[q] = true
						stack.append(q)
		out.append(comp)
	return out


## `img` as a linear-sampled texture for the sharp-pixel shader.
static func _wrap(img: Image) -> Texture2D:
	var ct := CanvasTexture.new()
	ct.diffuse_texture = ImageTexture.create_from_image(img)
	ct.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	return ct


## Spawns and ages the embers.
func _update_embers(dt: float) -> void:
	for i in range(_embers.size() - 1, -1, -1):
		var e := _embers[i]  # One ember.
		e["age"] = float(e["age"]) + dt
		e["pos"] = (e["pos"] as Vector2) + Vector2(float(e["drift"]), -float(e["rise"])) * dt
		if float(e["age"]) >= float(e["life"]):
			_embers.remove_at(i)
	_ember_timer -= dt
	if _ember_timer > 0.0 or _tips.is_empty():
		return
	_ember_timer = _rng.randf_range(FrontDoorData.LOGO_EMBER_INTERVAL.x, FrontDoorData.LOGO_EMBER_INTERVAL.y)
	if _embers.size() >= FrontDoorData.LOGO_EMBER_MAX:
		return
	var tip := _tips[_rng.randi() % _tips.size()]  # Source flame.
	_embers.append({
		"pos": tip + Vector2(_rng.randf_range(-1.5, 1.5), 1.0),
		"rise": _rng.randf_range(FrontDoorData.LOGO_EMBER_RISE.x, FrontDoorData.LOGO_EMBER_RISE.y),
		"drift": _rng.randf_range(-FrontDoorData.LOGO_EMBER_DRIFT, FrontDoorData.LOGO_EMBER_DRIFT),
		"age": 0.0, "life": _rng.randf_range(FrontDoorData.LOGO_EMBER_LIFE.x, FrontDoorData.LOGO_EMBER_LIFE.y),
		"col": FrontDoorData.LOGO_EMBER_COLORS[_rng.randi() % FrontDoorData.LOGO_EMBER_COLORS.size()],
	})
