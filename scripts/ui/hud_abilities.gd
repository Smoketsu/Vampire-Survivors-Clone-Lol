## HudAbilities — the bottom-centre HUD widgets of the necromancer's manual
## abilities (GDD §10.3 "Bottom center: ... ultimate cooldown"), flanking the
## ability bar:
##   left  : Grave Step (dash) icon, darkened from the top while no charge is
##           ready (the recharge sweep), one pip per charge (filled = ready,
##           the recharging one fills up), and its key chip above it.
##   right : Dread Rally (ultimate) icon, darkened above the soul meter's
##           level, a meter bar beside it, a pulsing border and "READY"
##           under the icon (never over it) when full, and the buff's
##           remaining time while the rally runs.
## The keys are InputHints chips drawn above the icons (InputHints.draw_chip),
## so they follow rebinds and the last device used (keyboard key, or the
## pad's RB / LB). Icons go
## through Glyphs.draw_icon(), so icon art (assets/sprites/icons/grave_step
## / dread_rally.png) plugs in. Polls game.grave_step / game.dread_rally and
## redraws every frame (two small icons); purely visual. Pixel-art UI kit:
## each icon sits in the kit's slot socket and the meter in its bar frame,
## like the ability bar (_socket(), _bar_frame(); flat look without the PNGs).
class_name HudAbilities
extends Control

## Size (px) of one ability icon.
const ICON: float = 48.0
## Height (px) of the key chip row above the icons (a chip and a 2 px gap).
const KEY_ROW: float = 22.0
## Width (px) of the Dread Rally meter bar.
const BAR_W: float = 6.0
## Half-width (px) of the widget: the icons sit at its two ends, outside the
## active slot row (6 x 42 px icons + gaps = ~272 px wide).
const HALF_WIDTH: float = 236.0
## Opacity of the "not ready" darkening.
const SHADE_ALPHA: float = 0.68
## Font size (px) of the key and status labels, as the UI scripts size text
## (drawn at UiTheme.font_px() in the pixel font: the BODY tier, 19 px).
const FONT: int = 11
## Pulse speed (rad/s of game time) of the ready border.
const PULSE: float = 6.0

## Owning run.
var game: Game


func _init(p_game: Game) -> void:
	game = p_game
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	anchor_left = 0.5
	anchor_right = 0.5
	anchor_top = 1.0
	anchor_bottom = 1.0
	offset_left = -HALF_WIDTH
	offset_right = HALF_WIDTH
	offset_top = -104.0 - KEY_ROW
	offset_bottom = -36.0


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if game == null or game.grave_step == null or game.dread_rally == null:
		return
	_draw_step(Vector2(0.0, KEY_ROW))
	_draw_rally(Vector2(size.x - ICON - BAR_W - 3.0, KEY_ROW))


## Grave Step icon at `o` (top-left of the icon box).
func _draw_step(o: Vector2) -> void:
	var gs := game.grave_step
	var rect := Rect2(o, Vector2(ICON, ICON))
	_key_label(o, "dash")
	_socket(rect)
	Glyphs.draw_icon(self, "grave_step", rect)
	if gs.charges <= 0:
		var k := gs.recharge_fraction()  # Recharge progress of the first charge.
		draw_rect(Rect2(o, Vector2(ICON, ICON * (1.0 - k))), Color(0.0, 0.0, 0.0, SHADE_ALPHA))
		_status(o, "%.1f" % ((1.0 - k) * gs.cooldown))
	elif gs.is_dashing():
		draw_rect(rect, Color(Palette.VIOLET, 0.25))
	# Charge pips under the icon.
	var n := gs.max_charges
	var w := ICON / float(n)
	for i in n:
		var pip := Rect2(Vector2(o.x + float(i) * w + 1.0, o.y + ICON + 2.0), Vector2(w - 2.0, 4.0))
		draw_rect(pip, Color(0.18, 0.14, 0.24))
		if i < gs.charges:
			draw_rect(pip, Palette.VIOLET.lightened(0.2))
		elif i == gs.charges:
			draw_rect(Rect2(pip.position, Vector2(pip.size.x * gs.recharge_fraction(), pip.size.y)), Color(Palette.VIOLET, 0.55))


## Dread Rally icon at `o` with its meter bar on the right.
func _draw_rally(o: Vector2) -> void:
	var dr := game.dread_rally
	var rect := Rect2(o, Vector2(ICON, ICON))
	_key_label(o, "ultimate")
	_socket(rect)
	Glyphs.draw_icon(self, "dread_rally", rect)
	var f := dr.fraction()  # Meter fill 0..1.
	var bar := Rect2(Vector2(o.x + ICON + 3.0, o.y), Vector2(BAR_W, ICON))
	draw_rect(bar, Color(0.0, 0.0, 0.0, 0.6))
	_bar_frame(bar)
	if dr.buff_active():
		var k := dr.buff_left / PlayerAbilityData.RALLY_DURATION  # Buff time left 0..1.
		draw_rect(Rect2(Vector2(bar.position.x, bar.end.y - ICON * k), Vector2(BAR_W, ICON * k)), Palette.VIOLET)
		draw_rect(rect, Color(Palette.VIOLET, 0.22))
		_status(o, "%.1fs" % dr.buff_left)
		return
	draw_rect(Rect2(Vector2(bar.position.x, bar.end.y - ICON * f), Vector2(BAR_W, ICON * f)), Palette.NECRO_GREEN)
	if dr.is_full():
		var pulse := 0.55 + 0.45 * sin(game.elapsed * PULSE)  # Ready-border brightness.
		draw_rect(rect.grow(1.5), Color(Palette.NECRO_GREEN, pulse), false, 2.5)
		_below(o, "READY", Palette.NECRO_GREEN.lightened(0.2))
	else:
		draw_rect(Rect2(o, Vector2(ICON, ICON * (1.0 - f))), Color(0.0, 0.0, 0.0, SHADE_ALPHA))
		_status(o, "%d%%" % int(f * 100.0))


## The kit's slot socket behind the icon square `rect` (nothing without the PNG).
func _socket(rect: Rect2) -> void:
	var sb := UiTheme.style("slot")  # A StyleBoxTexture when the kit PNG exists.
	if sb is StyleBoxTexture:
		SpriteBank.apply_sharp(self)
		draw_style_box(sb, rect.grow(UiArtData.SLOT_EXPAND))


## The kit's bar frame 1 px around the meter `bar` (drawn under the fill,
## whose edge rows it frames; nothing without the PNG).
func _bar_frame(bar: Rect2) -> void:
	var sb := UiTheme.style("bar")  # A StyleBoxTexture when the kit PNG exists.
	if sb is StyleBoxTexture:
		SpriteBank.apply_sharp(self)
		draw_style_box(sb, bar.grow(1.0))


## The font of the key and status labels (the theme's pixel font).
func _font() -> Font:
	return get_theme_default_font()


## The key chip of `action` centred above the icon at `o` (InputHints:
## the current device's key or pad button; nothing when it has none).
func _key_label(o: Vector2, action: String) -> void:
	var g := InputHints.glyph(action)  # Chip glyph for the current device.
	var w := float(InputHints.chip_width(g))  # Chip width (px).
	if w <= 0.0:
		return
	SpriteBank.apply_sharp(self)  # Pixel-font text is rasterised at layout size (UiArtData).
	InputHints.draw_chip(self, Vector2(roundf(o.x + (ICON - w) * 0.5), o.y - KEY_ROW), g)


## Status text (seconds left, %) on the lower part of the icon at `o`.
func _status(o: Vector2, text: String) -> void:
	var font := _font()
	var p := Vector2(o.x, o.y + ICON - 5.0)
	draw_string(font, p + Vector2(1, 1), text, HORIZONTAL_ALIGNMENT_CENTER, ICON, UiTheme.font_px(FONT), Color(0, 0, 0, 0.85))
	draw_string(font, p, text, HORIZONTAL_ALIGNMENT_CENTER, ICON, UiTheme.font_px(FONT), Color.WHITE)


## Status text `text` in `col`, centred just under the icon at `o` (the
## Dread Rally's READY, clear of the icon art).
func _below(o: Vector2, text: String, col: Color) -> void:
	var font := _font()
	var p := Vector2(o.x - 12.0, o.y + ICON + 14.0)  # Baseline under the icon (px).
	draw_string(font, p + Vector2(1, 1), text, HORIZONTAL_ALIGNMENT_CENTER, ICON + 24.0, UiTheme.font_px(FONT), Color(0, 0, 0, 0.85))
	draw_string(font, p, text, HORIZONTAL_ALIGNMENT_CENTER, ICON + 24.0, UiTheme.font_px(FONT), col)
