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
## Fonts (GDD §15.0 "Pixel fonts"; the why is in UiArtData): Jersey 10
## everywhere by default, always drawn from its one exact raster and scaled
## to one of its clean sizes (font_for(), applied by label() and
## pixel_text()), drawn through the sharp-pixel shader (which the hook also
## puts on every Label); long descriptions use Jersey 10 too, at the BODY
## tier (body(); owner: "Jersey, let's keep it cohesive", so no smooth font is
## left); event banners use Jacquard 24 at its 43 px em (banner()).
##
## Type tiers (GDD §15.0 "Type tiers", sizes in UiArtData.TYPE_*): every
## screen sizes its text by role, not by number: Tier.TITLE (Jacquard 24,
## screen titles and banners), HERO (Jersey 57, big numbers), HEADER (38),
## NAME (28, names and buttons), BODY (19, descriptions and secondary lines)
## and LABEL (19, upper case, letter-spaced section labels). tier_label() makes a
## Label in a tier, set_tier() restyles an existing Label / Button, tier_px()
## gives the size for code-drawn text. The theme's Buttons default to NAME and
## everything else to BODY. label(text, size) still works (font_px() maps a
## legacy size), but new code should use the tiers.
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

## Text roles of the type scale (sizes in UiArtData.TYPE_*):
##   TITLE  : screen titles and banners, Jacquard 24 at its 43 px em.
##   HERO   : big numbers, Jersey 10 at 57 px.
##   HEADER : section headers and the HUD timer, Jersey 10 at 38 px.
##   NAME   : item / card / upgrade names and buttons, Jersey 10 at 28 px.
##   BODY   : descriptions and secondary lines, Jersey 10 at 19 px.
##   LABEL  : section labels, Jersey 10 at 19 px, upper case, letter-spaced.
enum Tier { TITLE, HERO, HEADER, NAME, BODY, LABEL }

## Cached theme instance.
static var _theme: Theme = null
## Jersey 10 with UiArtData.LABEL_SPACING px after each letter (the LABEL
## tier; null until first used or when the font file is missing).
static var _spaced: Font = null
## Cached Jacquard 24 banner font (null until first used or when missing).
static var _banner_font: Font = null
## Jersey 10 drawn from its fixed raster (null until first used or when the
## file is missing).
static var _pixel: Font = null
## Cached kit styles: "<kind>_<accent>_<state>" -> StyleBox.
static var _styles: Dictionary = {}
## Gives kit-framed Controls the sharp-pixel material as they enter the tree
## (installed once by get_theme()).
static var _hook: _SharpHook = null


## Sets the sharp-pixel material on each Button / panel / scroll bar / slider
## added to the tree (they draw the kit's pixel frames) and on each Label
## (pixel-font text rasterised at layout size). Visual only.
class _SharpHook:
	extends RefCounted

	## SceneTree.node_added: a node entered the tree.
	func on_node_added(n: Node) -> void:
		if n is Button or n is PanelContainer or n is Panel or n is ScrollBar or n is Label or n is Slider:
			SpriteBank.apply_sharp(n as CanvasItem)


## Returns the shared Theme, building it on first use.
static func get_theme() -> Theme:
	if _theme != null:
		return _theme
	var t := Theme.new()
	t.default_font_size = FONT_SIZE
	if font_for() != null:
		t.default_font = font_for()  # Jersey 10 everywhere by default.
		t.default_font_size = tier_px(Tier.BODY)  # Labels and the rest: BODY.
		t.set_font_size("font_size", "Button", tier_px(Tier.NAME))  # Buttons: NAME.
		t.set_font_size("font_size", "CheckButton", tier_px(Tier.BODY))  # Option rows: BODY.
		t.set_font_size("font_size", "TooltipLabel", tier_px(Tier.BODY))
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
## tooltips, scroll bars, separators, sliders and the CheckButton toggle icons.
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
	_kit_slider(t)
	var on := _texture("toggle_on")  # CheckButton icons (32 x 16, the default size).
	var off := _texture("toggle_off")
	if on != null and off != null:
		for state: String in ["", "_disabled"]:
			t.set_icon("checked" + state, "CheckButton", on)
			t.set_icon("unchecked" + state, "CheckButton", off)


## The kit frame `kind` (UiArtData.SLICE: button, panel, card, focus, slot,
## bar, tip, scroll, grab, line, and the ornamented ornate, header, ribbon,
## divider, track, fill) in `accent` (violet, gold, crimson, soul, dim, ...;
## the ornamented kinds come in violet, gold and crimson) and `state` (normal,
## hover, pressed, disabled): a 9-slice StyleBoxTexture of
## assets/ui/<kind>_<accent>_<state>.png (a KitStyleBox that also draws the
## kind's crests for ornate, header and divider), or the flat fallback when
## that PNG is missing. Content margins match the old flat boxes (buttons,
## panels, cards: 10 / 6 px; the ornamented kinds: UiArtData.CONTENT).
## Cached; do not modify the result.
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
	if tex != null and (UiArtData.CRESTS.has(kind) or kind == "divider"):
		sb = _crested(kind, accent, sb)
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
	var m := float(UiArtData.SLICE.get(kind, 4))  # 9-slice margin, left / right (texels).
	var mv := float(UiArtData.SLICE_V.get(kind, m))  # 9-slice margin, top / bottom (texels).
	sb.texture_margin_left = m
	sb.texture_margin_right = m
	sb.texture_margin_top = mv
	sb.texture_margin_bottom = mv
	# Tile (never stretch) the edges and the centre: 1 texel stays 1 layout px, so
	# the fills' dither and the edge rings repeat cleanly at any size.
	sb.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_TILE
	sb.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_TILE
	if UiArtData.CONTENT.has(kind):
		var c: Array = UiArtData.CONTENT[kind]  # [left, top, right, bottom] (layout px).
		sb.content_margin_left = float(c[0])
		sb.content_margin_top = float(c[1])
		sb.content_margin_right = float(c[2])
		sb.content_margin_bottom = float(c[3])
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
		"divider":
			sb.texture_margin_top = 0  # The strip is drawn at its own height (KitStyleBox.frame_height).
			sb.texture_margin_bottom = 0
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


## Flat style box with a border and cut (chamfered) corners, like the pixel UI
## kit frames and icon badges (owner request). It is the fallback when a UI kit PNG is missing.
static func box(bg: Color, border: Color, border_width: int = 2) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(border_width)
	sb.set_corner_radius_all(6)  # Corner cut depth, px.
	sb.corner_detail = 1  # One segment per corner: a straight 45° cut instead of a rounded arc.
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


## The Jersey 10 size (layout px) for a requested `size` (sized for a 0.70-em
## cap height): the UiArtData.PIXEL_SIZES entry nearest size x CAP_MATCH (ties
## go to the smaller one). The one path for pixel-font sizes (labels, buttons,
## HUD bars and key hints, damage numbers).
static func font_px(size: int) -> int:
	var want := float(size) * UiArtData.CAP_MATCH  # Same cap height in Jersey 10.
	var best: int = UiArtData.PIXEL_SIZES[0]
	for s: int in UiArtData.PIXEL_SIZES:
		if absf(float(s) - want) < absf(float(best) - want):
			best = s
	return best


## Jersey 10, drawn from its one exact raster (UiArtData.PIXEL_EM, through
## FontFile.fixed_size) at whatever size it is asked for (use font_px()
## sizes). Null when the font file is missing (callers then keep the theme /
## engine default).
static func font_for(_size: int = 0) -> Font:
	if _pixel == null and ResourceLoader.exists(UiArtData.FONT_PIXEL):
		var f := (load(UiArtData.FONT_PIXEL) as FontFile).duplicate(true) as FontFile  # Own glyph cache.
		f.fixed_size = UiArtData.PIXEL_EM
		f.fixed_size_scale_mode = TextServer.FIXED_SIZE_SCALE_ENABLED
		var v := FontVariation.new()  # Trims the font's empty line slack (UiArtData.LINE_TRIM).
		v.base_font = f
		v.spacing_top = -UiArtData.LINE_TRIM
		v.spacing_bottom = -UiArtData.LINE_TRIM
		_pixel = v
	return _pixel


## Gives Control `c` (a Label or a Button) the pixel font for `size` px.
static func pixel_text(c: Control, size: int) -> void:
	var f := font_for()
	if f != null:
		c.add_theme_font_override("font", f)
	c.add_theme_font_size_override("font_size", font_px(size) if f != null else size)


## Convenience: creates a Label with text, font size and colour, in the
## pixel font (font_for()).
static func label(text: String, size: int = FONT_SIZE, color: Color = TEXT) -> Label:
	var l := Label.new()
	l.text = text
	pixel_text(l, size)
	l.add_theme_color_override("font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


## Convenience: a Label for long descriptions, in Jersey 10 at the BODY tier
## (owner: "Jersey, let's keep it cohesive"; it replaced Godot's smooth
## fallback font). `_size` is ignored (kept so older calls still compile):
## descriptions are always BODY. See para() for a wrapped paragraph.
static func body(s: String, _size: int = 13, color: Color = TEXT_DIM) -> Label:
	return tier_label(s, Tier.BODY, color)


## Layout px of tier `t` (Jacquard's em for TITLE), for code-drawn text
## (draw_string) and size maths.
static func tier_px(t: Tier) -> int:
	match t:
		Tier.TITLE:
			return UiArtData.BANNER_SIZE
		Tier.HERO:
			return UiArtData.TYPE_HERO
		Tier.HEADER:
			return UiArtData.TYPE_HEADER
		Tier.NAME:
			return UiArtData.TYPE_NAME
		Tier.LABEL:
			return UiArtData.TYPE_LABEL
	return UiArtData.TYPE_BODY


## Gives Control `c` (a Label or a Button) the font and size of tier `t`:
## Jacquard 24 for TITLE (Jersey 38 when its file is missing), Jersey 10 for
## the others, the letter-spaced Jersey variant for LABEL (a Label is also
## set to upper case).
static func set_tier(c: Control, t: Tier) -> void:
	if t == Tier.TITLE:
		var f := _banner()  # Jacquard 24 (null when the file is missing).
		if f != null:
			c.add_theme_font_override("font", f)
			c.add_theme_font_size_override("font_size", UiArtData.BANNER_SIZE)
			return
		t = Tier.HEADER  # Fallback look without the banner font.
	var font := _spaced_font() if t == Tier.LABEL else font_for()  # Jersey 10 (or its spaced variant).
	if font != null:
		c.add_theme_font_override("font", font)
	c.add_theme_font_size_override("font_size", tier_px(t))
	if t == Tier.LABEL and c is Label:
		(c as Label).uppercase = true


## Convenience: a Label showing `s` in tier `t` and `color` (mouse ignored).
## LABEL text is shown in upper case; pick TEXT_DIM for it, like the old
## section labels.
static func tier_label(s: String, t: Tier, color: Color = TEXT) -> Label:
	var l := Label.new()
	l.text = s
	set_tier(l, t)
	l.add_theme_color_override("font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


## Convenience: a word-wrapped BODY paragraph `width` px wide (0 = wrap at
## whatever width its container gives it).
static func para(s: String, width: float = 0.0, color: Color = TEXT_DIM) -> Label:
	var l := tier_label(s, Tier.BODY, color)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size.x = width
	return l


## Convenience: a centred screen title in the TITLE tier (Jacquard 24; use
## title case, blackletter capitals are hard to read).
static func title(s: String, color: Color = TEXT_GOLD) -> Label:
	var l := tier_label(s, Tier.TITLE, color)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l


## Jersey 10 with UiArtData.LABEL_SPACING px of letter spacing (the LABEL
## tier), built on font_for()'s raster. Null when the font file is missing.
static func _spaced_font() -> Font:
	if _spaced == null and font_for() != null:
		var v := FontVariation.new()  # Same raster and line trim, wider tracking.
		v.base_font = font_for()
		v.spacing_glyph = UiArtData.LABEL_SPACING
		_spaced = v
	return _spaced


## Jacquard 24, loaded once (null when the file is missing).
static func _banner() -> Font:
	if _banner_font == null and ResourceLoader.exists(UiArtData.FONT_BANNER):
		_banner_font = load(UiArtData.FONT_BANNER) as Font
	return _banner_font


## Turns `l` into an event / zone banner: Jacquard 24 at its 43 px em
## (UiArtData.BANNER_SIZE), word-wrapped at `wrap` px when wrap > 0. Leaves the
## label as it is (and returns false) when the font file is missing.
static func banner(l: Label, wrap: float = 0.0) -> bool:
	if _banner() == null:
		return false
	l.add_theme_font_override("font", _banner_font)
	l.add_theme_font_size_override("font_size", UiArtData.BANNER_SIZE)
	if wrap > 0.0:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size.x = wrap
	return true


## Focuses `c` at the end of the frame, but only if it still exists and is in
## the tree then (a panel can rebuild or close in between, e.g. the autotest
## picking a level-up card at once, which would make a plain deferred
## grab_focus() print an engine ERROR).
static func focus_deferred(c: Control) -> void:
	(func() -> void:
		if is_instance_valid(c) and c.is_inside_tree() and c.is_visible_in_tree():
			c.grab_focus()).call_deferred()


## Convenience: creates a full-screen dimming backdrop.
static func backdrop(alpha: float = 0.65) -> ColorRect:
	var r := ColorRect.new()
	r.color = Color(0.02, 0.0, 0.04, alpha)
	r.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	r.mouse_filter = Control.MOUSE_FILTER_STOP
	return r


# --- Ornamented UI kit (menu modernization; GDD §15.0 "Ornamented UI kit") ---
# Helpers for the ornamented kinds drawn by tools/ui_kit.py: the ornate hero
# panel (bone filigree corners, skull keystone), the header band, the banner
# ribbon, the skull divider, and the kit slider (Theme default for HSlider).
# Accents: "violet" (default), "gold" (victory, evolution, chest, selection),
# "crimson" (danger, penalties, defeat). All visual only.

## Text colour of a header band per accent (violet: bone text; gold: gold
## text; crimson: a pale crimson that reads on the dark crimson band).
const HEADER_TEXT: Dictionary = {
	"violet": TEXT,
	"gold": TEXT_GOLD,
	"crimson": Color(1.0, 0.62, 0.55),
}


## Wraps the 9-slice `frame` of ornamented `kind` in a KitStyleBox that also
## draws the kind's crests (UiArtData.CRESTS; assets/ui/<kind>_<accent>_<crest>.png,
## skipped when missing) and, for the divider, draws the frame as a centred
## UiArtData.DIVIDER_LINE px strip. Content margins are copied from `frame`.
static func _crested(kind: String, accent: String, frame: StyleBox) -> KitStyleBox:
	var k := KitStyleBox.new()
	k.frame = frame
	for side: int in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		k.set_content_margin(side, frame.get_content_margin(side))
	if kind == "divider":
		k.frame_height = float(UiArtData.DIVIDER_LINE)
	for c: Array in UiArtData.CRESTS.get(kind, []):
		var tex := _texture("%s_%s_%s" % [kind, accent, String(c[0])])  # Crest art (null = none).
		if tex == null:
			continue
		k.crest_textures.append(tex)
		k.crest_anchors.append(Vector2(float(c[1]), float(c[2])))
		k.crest_offsets.append(Vector2(float(c[3]), float(c[4])))
	return k


## Theme defaults for HSlider from the kit: the recessed track, the violet
## fill (brighter while hovered / focused) and the bone-and-gem grabber
## (soul-teal gem while hovered / focused, dim when disabled), replacing
## Godot's white round grabber. Left at Godot's defaults when a PNG is missing.
static func _kit_slider(t: Theme) -> void:
	var grab := _texture("grabber_normal")  # Grabber icons (12 x 20 px).
	var grab_hi := _texture("grabber_hover")  # Hovered / focused grabber.
	var grab_off := _texture("grabber_disabled")  # Disabled grabber.
	if not has_kit_slider() or _texture("fill_violet_normal") == null or grab_hi == null or grab_off == null:
		return
	t.set_stylebox("slider", "HSlider", style("track"))
	t.set_stylebox("grabber_area", "HSlider", style("fill"))
	t.set_stylebox("grabber_area_highlight", "HSlider", style("fill", "violet", "hover"))
	t.set_icon("grabber", "HSlider", grab)
	t.set_icon("grabber_highlight", "HSlider", grab_hi)
	t.set_icon("grabber_disabled", "HSlider", grab_off)


## True when the kit slider's PNGs exist (so the Theme gives every HSlider
## the kit look and a screen can drop its own slider overrides).
static func has_kit_slider() -> bool:
	return _texture("track_violet_normal") != null and _texture("grabber_normal") != null


## A new PanelContainer framed as the ornate hero panel in `accent` (bone
## filigree corners, a skull keystone rising 9 px above its top edge; content
## inset UiArtData.CONTENT["ornate"]). Add the screen's content as its child.
## Usage: var p := UiTheme.ornate_panel("gold"); p.add_child(vbox)
static func ornate_panel(accent: String = "violet") -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", style("ornate", accent))
	return p


## A new header band (a PanelContainer framed as the title strip in `accent`,
## pointed end caps with gem finials 6 px outside each end) holding a centred
## pixel-font Label with `text` at `size` (UiTheme.font_px() sizes; the Label
## is the band's only child: band.get_child(0)). Ignores the mouse.
## Usage: vbox.add_child(UiTheme.header_band("Difficulty", "violet", 28))
static func header_band(text: String, accent: String = "violet", size: int = 28) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", style("header", accent))
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var l := label(text, size, HEADER_TEXT.get(accent, TEXT))
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	p.add_child(l)
	return p


## A new banner ribbon (a PanelContainer framed as a cloth band with
## swallow-tail ends in `accent`; content inset UiArtData.CONTENT["ribbon"])
## for the in-run Jacquard banners: add the banner Label as its child. Ignores
## the mouse. Usage: var r := UiTheme.ribbon("gold"); r.add_child(banner_label)
static func ribbon(accent: String = "violet") -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", style("ribbon", accent))
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return p


## A new section divider: a Panel UiArtData.DIVIDER_HEIGHT px tall filling its
## container's width, with a thin `accent` rule and a small bone skull between
## two gem studs in the middle. Ignores the mouse.
## Usage: vbox.add_child(UiTheme.divider())
static func divider(accent: String = "violet") -> Panel:
	var p := Panel.new()
	p.add_theme_stylebox_override("panel", style("divider", accent))
	p.custom_minimum_size = Vector2(0.0, UiArtData.DIVIDER_HEIGHT)
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return p
