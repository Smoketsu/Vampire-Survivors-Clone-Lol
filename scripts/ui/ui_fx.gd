## UiFx — plays one effect animation strip (assets/sprites/effects/<id>.png:
## square frames side by side, the same art as AnimData's world effects)
## inside a UI screen: the level-up pillars, the evolution burst on a gold
## card or chest reward, the chest bursting open. The frames are drawn at a
## whole-number scale through the sharp-pixel shader (crisp at any window
## scale), centred on this Control's centre (`pivot` picks which point of the
## frame sits there: its centre, or its bottom centre for a light column).
## It plays on unscaled real time (the UI runs while the tree is paused and
## the autotest owns Engine.time_scale), once per play(), and draws nothing
## when motion is off (the autotest, "Reduce motion": UiMotion.enabled()) or
## the art is missing. Purely visual; it reads no gameplay state.
class_name UiFx
extends Control

## Effect strip id (assets/sprites/effects/<id>.png).
var anim: String = ""
## Whole-number scale (layout px per art px) the frames are drawn at (>= 1).
var art_scale: int = 1
## Real seconds one play-through takes (InRunUiData.FX_TIME by default).
var duration: float = 0.6
## Point of the frame placed on this Control's centre, as a fraction of the
## frame: (0.5, 0.5) = the frame's centre, (0.5, 1.0) = its bottom centre.
var pivot: Vector2 = Vector2(0.5, 0.5)
## Opacity multiplier of every frame (0..1).
var alpha: float = 1.0
## Real time (usec, Time.get_ticks_usec) the current play starts at; -1 = idle.
var _start_usec: int = -1

## Strip textures: id -> linear-filtered CanvasTexture (the sharp-pixel
## shader needs linear samples), or null when the PNG is missing.
static var _strips: Dictionary = {}


func _init(p_anim: String = "", p_scale: int = 1, p_pivot: Vector2 = Vector2(0.5, 0.5)) -> void:
	anim = p_anim
	art_scale = maxi(1, p_scale)
	pivot = p_pivot
	duration = float(InRunUiData.FX_TIME.get(p_anim, 0.6))
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(false)


func _ready() -> void:
	SpriteBank.apply_sharp(self)


## Starts one play-through after `delay` real seconds (restarts a running
## one). Does nothing when motion is off or the strip has no art.
func play(delay: float = 0.0) -> void:
	if not UiMotion.enabled() or strip(anim) == null:
		stop()
		return
	_start_usec = Time.get_ticks_usec() + int(delay * 1000000.0)
	set_process(true)
	queue_redraw()


## Stops the animation (nothing is drawn).
func stop() -> void:
	_start_usec = -1
	set_process(false)
	queue_redraw()


## True while a play-through is waiting or running.
func playing() -> bool:
	return _start_usec >= 0


## Progress of the current play-through: < 0 while waiting, 0..1 while
## running, >= 1 once done.
func _progress() -> float:
	return float(Time.get_ticks_usec() - _start_usec) / 1000000.0 / maxf(0.01, duration)


func _process(_delta: float) -> void:
	if _start_usec >= 0 and _progress() >= 1.0:
		_start_usec = -1
		set_process(false)
	queue_redraw()


func _draw() -> void:
	if _start_usec < 0:
		return
	var p := _progress()  # 0..1 through the strip.
	var tex := strip(anim)
	if p < 0.0 or p >= 1.0 or tex == null:
		return
	var fh := float(tex.get_height())  # Frame side (art px).
	var frames := maxi(1, roundi(float(tex.get_width()) / fh))  # Frames in the strip.
	var f := mini(int(p * float(frames)), frames - 1)  # Current frame.
	var side := fh * float(art_scale)  # Drawn frame side (layout px).
	var top_left := (size * 0.5 - Vector2(side, side) * pivot).round()  # Whole px: crisp.
	draw_texture_rect_region(tex, Rect2(top_left, Vector2(side, side)), Rect2(fh * float(f), 0.0, fh, fh), Color(1, 1, 1, alpha))


## The strip texture of effect `id`, or null when its PNG is missing.
static func strip(id: String) -> Texture2D:
	if not _strips.has(id):
		_strips[id] = sharp_texture("res://assets/sprites/effects/%s.png" % id)
	return _strips[id]


## The PNG at `path` wrapped for the sharp-pixel shader (a linear-filtered
## CanvasTexture, like SpriteBank's grid art), or null when it is missing.
## Not cached here (callers cache).
static func sharp_texture(path: String) -> Texture2D:
	if not ResourceLoader.exists(path):
		return null
	var ct := CanvasTexture.new()
	ct.diffuse_texture = load(path) as Texture2D
	ct.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	return ct
