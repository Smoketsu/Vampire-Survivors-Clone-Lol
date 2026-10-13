## UiTheme — builds the shared dark-gothic UI Theme in code (no .tres assets):
## violet-bordered panels and buttons on near-black purple, bone-white text.
## Built once and cached; every UI root assigns it so children inherit it.
##
## Pixel-art UI kit (art pass, docs/art/ART_BIBLE.md "UI kit and title logo"):
## when the kit PNGs exist (res://assets/ui/, drawn by tools/ui_kit.py), every
## frame is a 9-slice StyleBoxTexture (style(): kind, accent, state) with the
## SAME content margins as the old flat boxes, so layouts, sizes and focus
## paths do not move; a missing PNG falls back to the old StyleBoxFlat (box()).
## Kit frames are pixel art at 1 texel = 1 layout px: Buttons, panels and
## scroll bars get the shared sharp-pixel material (SpriteBank.apply_sharp())
## as they enter the tree (_SharpHook), so the frame pixels stay crisp and even
## when the 1280x720 layout is stretched (x1.5 in a 1080p window); text drawn
## by the same nodes is unaffected (the shader is identity at 1:1).
##
## Fonts (GDD §15.0 "Pixel fonts"; the why is in UiArtData): Pixelify Sans
## Bold everywhere by default, always rasterised at one of its clean pixel
## ems and scaled to the asked size (font_for(), applied by label() and
## pixel_text()), drawn through the sharp-pixel shader (which the hook also
## puts on every Label); long descriptions use the clean body font (body(),
## Godot's default font); event banners use Jacquard 24 at its 43 px em
## (banner()).
class_name UiTheme
extends RefCounted

## Default font size for all controls (px).
const FONT_SIZE: int = 16
## Panel / button background.
const BG := Color(0.08, 0.05, 0.12, 0.94)
## Hovered / focused button background.
const BG_HOVER := Color(0.2, 0.11, 0.3, 0.97)
## Pressed button background.
const BG_PRESSED := Color(0.3, 0.16, 0.42, 1.0)
## Border colour of panels and buttons.
const BORDER := Color(0.45, 0.3, 0.7)
## Border colour for focused controls (controller / keyboard navigation).
const BORDER_FOCUS := Color(0.55, 1.0, 0.65)
## Main text colour.
const TEXT := Color(0.92, 0.9, 0.84)
## Dim secondary text colour.
const TEXT_DIM := Color(0.68, 0.64, 0.74)
## Highlight text for stat deltas.
const TEXT_GOOD := Color(0.55, 1.0, 0.65)
## Gold text for banners / titles.
const TEXT_GOLD := Color(1.0, 0.84, 0.4)

## Fallback look per kit accent when its PNG is missing: accent -> [normal
## background, hover background, border colour, border width px] (today's
## flat colours; "violet" is the theme default).
const FALLBACK: Dictionary = {
	"violet": [BG, BG_HOVER, BORDER, 2],
	"gold": [Color(0.24, 0.15, 0.08, 0.97), Color(0.3, 0.19, 0.1, 0.97), Color(1.0, 0.84, 0.4), 3],
	"crimson": [Color(0.26, 0.05, 0.08, 0.97), Color(0.34, 0.09, 0.12, 0.97), Color(0.95, 0.35, 0.35), 3],
	"soul": [BG, BG_HOVER, Color(0.22, 0.75, 0.37), 2],
	"dim": [BG, BG_HOVER, Color(0.2, 0.135, 0.315), 2],
}

## Cached theme instance.
static var _theme: Theme = null
## Cached Jacquard 24 banner font (null until first used or when missing).
static var _banner_font: Font = null
## Pixelify Sans Bold per clean raster size: UiArtData.PIXEL_EMS entry ->
## FontFile drawn from that fixed raster (filled on first use; empty when the
## file is missing).
static var _pixel: Dictionary = {}
## Cached kit styles: "<kind>_<accent>_<state>" -> StyleBox.
static var _styles: Dictionary = {}
## Gives kit-framed Controls the sharp-pixel material as they enter the tree
## (installed once by get_theme()).
static var _hook: _SharpHook = null


## Sets the sharp-pixel material on each Button / panel / scroll bar added to
## the tree (they draw the kit's pixel frames) and on each Label (pixel-font
## text rasterised at layout size). Visual only.
class _SharpHook:
	extends RefCounted

	## SceneTree.node_added: a node entered the tree.
	func on_node_added(n: Node) -> void:
		if n is Button or n is PanelContainer or n is Panel or n is ScrollBar or n is Label:
			SpriteBank.apply_sharp(n as CanvasItem)


## Returns the shared Theme, building it on first use.
static func get_theme() -> Theme:
	if _theme != null:
		return _theme
	var t := Theme.new()
	t.default_font_size = FONT_SIZE
	if font_for(FONT_SIZE) != null:
		t.default_font = font_for(FONT_SIZE)  # Pixelify Sans Bold everywhere by default.
	t.set_stylebox("normal", "Button", style("button", "violet", "normal"))
	t.set_stylebox("hover", "Button", style("button", "violet", "hover"))
	t.set_stylebox("pressed", "Button", style("button", "violet", "pressed"))
	t.set_stylebox("hover_pressed", "Button", style("button", "violet", "hover"))
	t.set_stylebox("focus", "Button", style("focus"))
	t.set_stylebox("disabled", "Button", style("button", "violet", "disabled"))
	t.set_color("font_color", "Button", TEXT)
	t.set_color("font_hover_color", "Button", Color.WHITE)
	t.set_color("font_focus_color", "Button", Color.WHITE)
	t.set_color("font_pressed_color", "Button", TEXT_GOOD)
	t.set_stylebox("panel", "Panel", style("panel"))
	t.set_stylebox("panel", "PanelContainer", style("panel"))
	t.set_color("font_color", "Label", TEXT)
	t.set_color("font_shadow_color", "Label", Color(0, 0, 0, 0.8))
	t.set_constant("shadow_offset_x", "Label", 1)
	t.set_constant("shadow_offset_y", "Label", 1)
	_kit_extras(t)
	_theme = t
	if _hook == null:
		_hook = _SharpHook.new()
		(Engine.get_main_loop() as SceneTree).node_added.connect(_hook.on_node_added)
	return t


## Kit-only theme entries (left at Godot's defaults when the PNGs are missing):
## tooltips, scroll bars, separators and the CheckButton toggle icons.
static func _kit_extras(t: Theme) -> void:
	if _texture("tip_bone_normal") != null:
		t.set_stylebox("panel", "TooltipPanel", style("tip", "bone"))
		t.set_color("font_color", "TooltipLabel", TEXT)
	if _texture("scroll_violet_normal") != null and _texture("grab_violet_normal") != null:
		for sb: String in ["VScrollBar", "HScrollBar"]:
			t.set_stylebox("scroll", sb, style("scroll"))
			t.set_stylebox("scroll_focus", sb, style("scroll"))
			t.set_stylebox("grabber", sb, style("grab"))
			t.set_stylebox("grabber_highlight", sb, style("grab", "violet", "hover"))
			t.set_stylebox("grabber_pressed", sb, style("grab", "violet", "pressed"))
	if _texture("line_violet_normal") != null:
		t.set_stylebox("separator", "HSeparator", style("line"))
	var on := _texture("toggle_on")  # CheckButton icons (32 x 16, the default size).
	var off := _texture("toggle_off")
	if on != null and off != null:
		for state: String in ["", "_disabled"]:
			t.set_icon("checked" + state, "CheckButton", on)
			t.set_icon("unchecked" + state, "CheckButton", off)


## The kit frame `kind` (UiArtData.SLICE: button, panel, card, focus, slot,
## bar, tip, scroll, grab, line) in `accent` (violet, gold, crimson, soul,
## dim, ...) and `state` (normal, hover, pressed, disabled): a 9-slice
## StyleBoxTexture of assets/ui/<kind>_<accent>_<state>.png, or the flat
## fallback when that PNG is missing. Content margins match the old flat
## boxes (buttons, panels, cards: 10 / 6 px). Cached; do not modify the result.
static func style(kind: String, accent: String = "violet", state: String = "normal") -> StyleBox:
	if kind == "focus":
		accent = "soul"
	elif kind == "slot":
		accent = "grey"
	var key := "%s_%s_%s" % [kind, accent, state]  # File stem and cache key.
	if _styles.has(key):
		return _styles[key]
	var tex := _texture(key)  # Kit PNG (null = fallback).
	var sb: StyleBox = _flat(kind, accent, state) if tex == null else _textured(kind, tex)
	_styles[key] = sb
	return sb


## Loads assets/ui/<stem>.png, or null when it does not exist.
static func _texture(stem: String) -> Texture2D:
	var path := UiArtData.ROOT + stem + ".png"  # Expected file.
	return load(path) as Texture2D if ResourceLoader.exists(path) else null


## The 9-slice StyleBoxTexture of kit frame `kind` from `tex`.
static func _textured(kind: String, tex: Texture2D) -> StyleBoxTexture:
	var sb := StyleBoxTexture.new()
	sb.texture = tex
	var m := float(UiArtData.SLICE.get(kind, 4))  # 9-slice margin (texels).
	sb.set_texture_margin_all(m)
	match kind:
		"button", "panel", "card":
			sb.content_margin_left = 10
			sb.content_margin_right = 10
			sb.content_margin_top = 6
			sb.content_margin_bottom = 6
		"focus":
			sb.set_expand_margin_all(UiArtData.FOCUS_EXPAND)
		"tip":
			sb.content_margin_left = 8
			sb.content_margin_right = 8
			sb.content_margin_top = 2
			sb.content_margin_bottom = 2
		"scroll":
			sb.content_margin_left = 4
			sb.content_margin_right = 4
			sb.content_margin_top = 0
			sb.content_margin_bottom = 0
		"grab":
			sb.set_content_margin_all(4)
		"line":
			sb.texture_margin_top = 0
			sb.texture_margin_bottom = 0
			sb.content_margin_top = 1.5
			sb.content_margin_bottom = 1.5
	return sb


## The old flat look of kit frame `kind` (used when its PNG is missing).
static func _flat(kind: String, accent: String, state: String) -> StyleBox:
	var f: Array = FALLBACK.get(accent, FALLBACK["violet"])  # [bg, bg hover, border, width].
	match kind:
		"focus":
			return box(Color(0, 0, 0, 0), BORDER_FOCUS, 3)
		"slot", "bar":
			return box(Color(0.07, 0.05, 0.11, 0.92), BORDER, 1)
	match state:
		"hover":
			return box(f[1], f[2], f[3])
		"pressed":
			return box(BG_PRESSED if accent == "violet" else (f[1] as Color).lightened(0.08), f[2], f[3])
		"disabled":
			return box(BG, BORDER.darkened(0.5))
	return box(f[0], f[2], f[3])


## Flat style box with a border and rounded corners.
static func box(bg: Color, border: Color, border_width: int = 2) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(border_width)
	sb.set_corner_radius_all(6)
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
	return sb


## Applies kit frame `kind` / `accent` to a Button's normal and hover states
## (and, for cards, pressed: a card button replaces the whole button look),
## as the old per-screen box() overrides did: selected tiles, evolution cards,
## Ossuary states. `accent` "" removes the overrides so the theme look returns.
static func style_button(b: Button, kind: String, accent: String) -> void:
	if accent == "":
		for s: String in ["normal", "hover", "pressed"]:
			b.remove_theme_stylebox_override(s)
		return
	b.add_theme_stylebox_override("normal", style(kind, accent, "normal"))
	b.add_theme_stylebox_override("hover", style(kind, accent, "hover"))
	if kind == "card":
		b.add_theme_stylebox_override("pressed", style(kind, accent, "pressed"))


## Pixelify Sans Bold for text drawn at `size` px: a copy of the font whose
## glyphs are always rasterised at a clean pixel em (UiArtData.PIXEL_EMS, the
## largest one not above `size`, else the smallest) and scaled to `size`
## (FontFile.fixed_size), so every glyph keeps its true shape. Null when the
## font file is missing (callers then keep the theme / engine default).
static func font_for(size: int) -> Font:
	if not ResourceLoader.exists(UiArtData.FONT_PIXEL):
		return null
	var em: int = UiArtData.PIXEL_EMS[0]  # Raster size to use.
	for e: int in UiArtData.PIXEL_EMS:
		if e <= size:
			em = e
	if not _pixel.has(em):
		var f := (load(UiArtData.FONT_PIXEL) as FontFile).duplicate(true) as FontFile  # Own glyph cache.
		f.fixed_size = em
		f.fixed_size_scale_mode = TextServer.FIXED_SIZE_SCALE_ENABLED
		_pixel[em] = f
	return _pixel[em]


## Gives Control `c` (a Label or a Button) the pixel font for `size` px.
static func pixel_text(c: Control, size: int) -> void:
	var f := font_for(size)
	if f != null:
		c.add_theme_font_override("font", f)
	c.add_theme_font_size_override("font_size", size)


## Convenience: creates a Label with text, font size and colour, in the
## pixel font (font_for()).
static func label(text: String, size: int = FONT_SIZE, color: Color = TEXT) -> Label:
	var l := Label.new()
	l.text = text
	pixel_text(l, size)
	l.add_theme_color_override("font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


## Convenience: a Label for long descriptions in the clean body font (Godot's
## default font, smooth at any window scale; owner rule: long card
## descriptions keep a body font). `size` is used as given.
static func body(text: String, size: int = 13, color: Color = TEXT_DIM) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", ThemeDB.fallback_font)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


## Turns `l` into an event / zone banner: Jacquard 24 at its 43 px em
## (UiArtData.BANNER_SIZE), word-wrapped at `wrap` px when wrap > 0. Leaves the
## label as it is (and returns false) when the font file is missing.
static func banner(l: Label, wrap: float = 0.0) -> bool:
	if _banner_font == null and ResourceLoader.exists(UiArtData.FONT_BANNER):
		_banner_font = load(UiArtData.FONT_BANNER) as Font
	if _banner_font == null:
		return false
	l.add_theme_font_override("font", _banner_font)
	l.add_theme_font_size_override("font_size", UiArtData.BANNER_SIZE)
	if wrap > 0.0:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size.x = wrap
	return true


## Convenience: creates a full-screen dimming backdrop.
static func backdrop(alpha: float = 0.65) -> ColorRect:
	var r := ColorRect.new()
	r.color = Color(0.02, 0.0, 0.04, alpha)
	r.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	r.mouse_filter = Control.MOUSE_FILTER_STOP
	return r
