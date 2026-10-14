## StageVignette — the small composed pixel scene at the top of a stage card
## (StageSelect; GDD §15.0 "Front door screens"; the scene is data:
## FrontDoorData.VIGNETTES). The stage's own floor tile, a few of its
## obstacles, structures and decals, a handful of undead on the left and the
## stage boss in an attack pose facing them, each unit on a soft drop shadow,
## everything 1 art px = 1 layout px through the sharp-pixel shader (the
## game's grid-art rule). Ambient motes drift up (soul wisps in the Graveyard,
## embers on the March, holy light in the Sanctum), stepped edge shading
## frames it, and it brightens while its card is focused (set_focused()).
## A LOCKED stage draws the same scene as a dark silhouette under a padlock.
## Motion is off with UiMotion.enabled() false (no motes, instant focus).
## Purely cosmetic: real time and a private RNG, no gameplay state.
class_name StageVignette
extends Control

## StageRegistry id depicted.
var stage_id: String = ""
## True while the stage is locked (silhouette and padlock).
var locked: bool = false
## Current brightness (FrontDoorData.VIGNETTE_IDLE_BRIGHT .. 1).
var _bright: float = FrontDoorData.VIGNETTE_IDLE_BRIGHT
## Target brightness (follows the card's focus).
var _bright_target: float = FrontDoorData.VIGNETTE_IDLE_BRIGHT
## Ambient motes. Each: {pos: Vector2 px, age: s, life: s, rise: px/s, phase: rad}.
var _motes: Array[Dictionary] = []
## Seconds until the next mote.
var _mote_timer: float = 0.0
## Private RNG for the motes (never the gameplay RNG).
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _init(p_stage: String, p_locked: bool) -> void:
	stage_id = p_stage
	locked = p_locked
	custom_minimum_size = FrontDoorData.VIGNETTE_SIZE
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_ALWAYS
	clip_contents = true
	_rng.randomize()


func _ready() -> void:
	SpriteBank.apply_sharp(self)


## Brightens the scene while its card is focused / hovered (`on`).
func set_focused(on: bool) -> void:
	_bright_target = 1.0 if on else FrontDoorData.VIGNETTE_IDLE_BRIGHT
	if not UiMotion.enabled():
		_bright = _bright_target
	queue_redraw()


func _process(delta: float) -> void:
	if not UiMotion.enabled() or locked:
		return
	var dt := delta / Engine.time_scale if Engine.time_scale > 0.0 else delta  # Real seconds.
	_bright = move_toward(_bright, _bright_target, dt * (1.0 - FrontDoorData.VIGNETTE_IDLE_BRIGHT) / FrontDoorData.VIGNETTE_FOCUS_TIME)
	_update_motes(dt)
	queue_redraw()


func _draw() -> void:
	var def: Dictionary = FrontDoorData.VIGNETTES.get(stage_id, {})
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.02, 0.01, 0.03))
	if def.is_empty():
		return
	var k := 1.0 if locked else _bright  # Scene brightness.
	var floor_tint := FrontDoorData.LOCK_FLOOR if locked else Color(k, k, k)  # Floor colour.
	var tile := EnvironmentArt.texture(String(def["tile"]), true)  # Repeating floor tile, or null.
	if tile != null:
		draw_texture_rect(tile, Rect2(Vector2.ZERO, size), true, floor_tint)
	var unit_tint := FrontDoorData.LOCK_SILHOUETTE if locked else Color(k, k, k)  # Sprite colour.
	for it: Array in def["items"]:
		_draw_item(String(it[0]), Vector2(float(it[1]), float(it[2])), bool(it[3]), unit_tint)
	if not locked:
		_draw_motes(Color(def["fx_color"] as Color, k))
	_draw_edges()
	if locked:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.0, 0.0, 0.0, 0.12))
		var s := MaskIcon.art_size("padlock") * float(FrontDoorData.LOCK_ICON_SCALE)  # Padlock size (px).
		MaskIcon.paint(self, "padlock", ((size - s) * 0.5).round(), FrontDoorData.LOCK_ICON_SCALE)


## Draws one scene item: a decal centred on `p`, else a sprite standing with
## its feet on `p` over a drop shadow (units, props), mirrored when `flip`.
func _draw_item(key: String, p: Vector2, flip: bool, tint: Color) -> void:
	var tex := EnvironmentArt.texture(key)  # The art, or null (skipped).
	if tex == null:
		return
	var s := Vector2(float(tex.get_width()), float(tex.get_height()))  # Size (px).
	if key.begins_with("decals/"):
		if not locked:
			draw_texture_rect(tex, Rect2((p - s * 0.5).round(), s), false, tint)
		return
	var sh := FrontDoorData.VIGNETTE_SHADOW  # Width share, squash, alpha.
	draw_set_transform(p + Vector2(0.0, -1.0), 0.0, Vector2(1.0, sh.y))
	draw_circle(Vector2.ZERO, s.x * sh.x * 0.5, Color(0.0, 0.0, 0.0, sh.z))
	var tl := Vector2(roundf(p.x - s.x * 0.5), roundf(p.y - s.y))  # Top-left (whole px).
	if flip:
		draw_set_transform(Vector2(tl.x + s.x, tl.y), 0.0, Vector2(-1.0, 1.0))
		draw_texture_rect(tex, Rect2(Vector2.ZERO, s), false, tint)
	else:
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		draw_texture_rect(tex, Rect2(tl, s), false, tint)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## Stepped dark bands along the edges (pixel-art vignette, no gradient).
func _draw_edges() -> void:
	var a := FrontDoorData.VIGNETTE_EDGE_ALPHA / float(FrontDoorData.VIGNETTE_EDGE_STEPS.size())  # Alpha per step.
	for w: float in FrontDoorData.VIGNETTE_EDGE_STEPS:
		var c := Color(0.02, 0.01, 0.04, a)  # One band.
		draw_rect(Rect2(0.0, 0.0, size.x, w), c)
		draw_rect(Rect2(0.0, size.y - w, size.x, w), c)
		draw_rect(Rect2(0.0, w, w, size.y - 2.0 * w), c)
		draw_rect(Rect2(size.x - w, w, w, size.y - 2.0 * w), c)


## Spawns and ages the ambient motes.
func _update_motes(dt: float) -> void:
	for i in range(_motes.size() - 1, -1, -1):
		var m := _motes[i]  # One mote.
		m["age"] = float(m["age"]) + dt
		if float(m["age"]) >= float(m["life"]):
			_motes.remove_at(i)
	_mote_timer -= dt
	if _mote_timer > 0.0:
		return
	_mote_timer = _rng.randf_range(FrontDoorData.VIGNETTE_FX_INTERVAL.x, FrontDoorData.VIGNETTE_FX_INTERVAL.y)
	if _motes.size() >= FrontDoorData.VIGNETTE_FX_MAX:
		return
	_motes.append({
		"pos": Vector2(_rng.randf_range(8.0, size.x - 8.0), _rng.randf_range(size.y * 0.45, size.y - 6.0)),
		"age": 0.0, "life": _rng.randf_range(FrontDoorData.VIGNETTE_FX_LIFE.x, FrontDoorData.VIGNETTE_FX_LIFE.y),
		"rise": _rng.randf_range(FrontDoorData.VIGNETTE_FX_RISE.x, FrontDoorData.VIGNETTE_FX_RISE.y),
		"phase": _rng.randf() * TAU,
	})


## Draws the motes: whole-px squares (2 px with a 1 px core for wisps and
## motes, 1 px sparks for embers), fading in and out.
func _draw_motes(col: Color) -> void:
	var kind := String(FrontDoorData.VIGNETTES[stage_id].get("fx", ""))  # Mote style.
	for m in _motes:
		var age := float(m["age"])
		var life := float(m["life"])
		var a := minf(1.0, age * 3.0) * minf(1.0, (life - age) * 1.5)  # Fade.
		var p := (m["pos"] as Vector2) + Vector2(sin(age * 2.2 + float(m["phase"])) * FrontDoorData.VIGNETTE_FX_SWAY, -age * float(m["rise"]))
		p = p.round()
		if kind == "embers":
			draw_rect(Rect2(p, Vector2(1.0, 1.0)), Color(col, a))
			draw_rect(Rect2(p + Vector2(0.0, 1.0), Vector2(1.0, 1.0)), Color(col.darkened(0.4), a * 0.6))
		else:
			draw_rect(Rect2(p - Vector2(1.0, 1.0), Vector2(2.0, 2.0)), Color(col, a * 0.45))
			draw_rect(Rect2(p - Vector2(0.0, 1.0), Vector2(1.0, 1.0)), Color(col.lightened(0.5), a))
