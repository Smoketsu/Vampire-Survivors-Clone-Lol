## VigridLight — the LOOK of Vigrid's Fading Light (the Hall of the Slain,
## temporarily Act XI; GDD §15.0 "Vigrid, the Last Field (phase 2)"; drawing
## only, never headless, no gameplay state, no RNG): the sky going out over the
## Last Field. A darkness over the view whose share rises zone by zone
## (VigridStage.VIGRID light "dark_by_zone", blended over `fade` s), with soft
## pools of light round every LIT brazier (the Long Winter's warm_radius: the
## light and the warmth are the same fires) and round each necromancer
## (`necro_light` px). In the last zone the Reckoning's dark arrives early: the
## darkness turns toward Ragnarok's red (`early_color`). As the Shogunate's
## night (SunCourse): a small darkness image (one texel per `cell` px, alpha =
## darkness, carved by the pools), stretched over the view with linear
## filtering; no shader reads the screen and no polygon is redrawn per frame.
## VigridDirector creates it and writes `zone` and `early_dark`.
class_name VigridLight
extends Node2D

## Owning run.
var game: Game
## The look's numbers (VigridStage.VIGRID "light").
var cfg: Dictionary = {}
## Zone index now (VigridDirector writes it; 0 = the Frozen Sea).
var zone: int = 0
## True once the Reckoning's dark arrives early (the last zone's vanguard).
var early_dark: bool = false
## Darkness share drawn now (0..1; eases toward the zone's).
var _dark: float = 0.0
## Share of the early dark's red drawn now (0..1).
var _red: float = 0.0
## The darkness image (one texel per cell px; alpha = darkness).
var _img: Image = null
## The darkness texture drawn over the view.
var _tex: ImageTexture = null
## Texels across the darkness image.
var _cols: int = 0
## Texels down the darkness image.
var _rows: int = 0
## World px of the image's top-left texel corner.
var _origin: Vector2 = Vector2.ZERO


## Builds the look for `p_game` with numbers `p_cfg`.
func _init(p_game: Game, p_cfg: Dictionary) -> void:
	game = p_game
	cfg = p_cfg
	name = "VigridLight"
	z_index = 17  # Over the bodies and the effects; under Ragnarok's wash (18) and the HUD.
	z_as_relative = false
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR  # Smooth pools between texels.


func _process(delta: float) -> void:
	if game == null or cfg.is_empty():
		return
	var arr: Array = cfg.get("dark_by_zone", [0.0])
	var goal := float(arr[clampi(zone, 0, arr.size() - 1)])
	var fade := maxf(float(cfg.get("fade", 20.0)), 0.01)
	var was := _dark
	_dark = move_toward(_dark, goal, delta / fade)
	_red = move_toward(_red, 1.0 if early_dark else 0.0, delta / fade)
	if _dark > 0.005:
		_update_darkness()
		queue_redraw()
	elif was > 0.005:
		queue_redraw()


## The visible world rect around the camera.
func _view() -> Rect2:
	var cam := game.camera
	var zoom := cam.zoom if cam != null else Vector2.ONE
	var sz := get_viewport_rect().size / zoom
	var c := cam.get_screen_center_position() if cam != null else game.player.position
	return Rect2(c - sz * 0.5, sz)


## Rebuilds the darkness image: every texel at the darkness share, then each
## light pool carves its soft hole (the lowest alpha wins).
func _update_darkness() -> void:
	var cell := float(cfg.get("cell", 16.0))
	var view := _view().grow(cell * 2.0)
	_origin = (view.position / cell).floor() * cell
	var cols := ceili(view.size.x / cell) + 2
	var rows := ceili(view.size.y / cell) + 2
	var night: Color = cfg.get("color", Color(0.02, 0.03, 0.06))
	var col := night.lerp(cfg.get("early_color", Color(0.16, 0.02, 0.02)), _red)
	if _img == null or cols != _cols or rows != _rows:
		_cols = cols
		_rows = rows
		_img = Image.create(_cols, _rows, false, Image.FORMAT_RGBA8)
		_img.fill(Color(col, _dark))
		_tex = ImageTexture.create_from_image(_img)
	_img.fill(Color(col, _dark))
	var nl := float(cfg.get("necro_light", 150.0))
	for pl in game.all_players:
		if not pl.dead:
			_carve(pl.position, nl, col)
	if game.norse != null:
		var w := game.norse.winter
		var wr := float(w.cfg["warm_radius"]) * float(cfg.get("brazier_light", 1.0))
		for b in w.braziers:
			if b.lit and view.grow(wr).has_point(b.pos):
				_carve(b.pos, wr, col)
	_tex.update(_img)


## Carves one light pool (centre `c`, radius `r` px) into the darkness image.
func _carve(c: Vector2, r: float, col: Color) -> void:
	var cell := float(cfg.get("cell", 16.0))
	var x0 := maxi(0, floori((c.x - r - _origin.x) / cell))
	var x1 := mini(_cols - 1, ceili((c.x + r - _origin.x) / cell))
	var y0 := maxi(0, floori((c.y - r - _origin.y) / cell))
	var y1 := mini(_rows - 1, ceili((c.y + r - _origin.y) / cell))
	for y in range(y0, y1 + 1):
		for x in range(x0, x1 + 1):
			var p := _origin + (Vector2(float(x), float(y)) + Vector2(0.5, 0.5)) * cell
			var k := clampf(p.distance_to(c) / r, 0.0, 1.0)  # 0 centre, 1 rim.
			var a := _dark * k * k  # Darkness left here: a soft pool.
			if a < _img.get_pixel(x, y).a:
				_img.set_pixel(x, y, Color(col, a))


func _draw() -> void:
	if _tex != null and _dark > 0.005:
		draw_texture_rect(_tex, Rect2(_origin, Vector2(float(_cols), float(_rows)) * float(cfg.get("cell", 16.0))), false)
