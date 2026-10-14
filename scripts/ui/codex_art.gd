## CodexArt — draws one Codex entry's art in its box (CodexScreen tiles, the
## detail portrait and the achievement badges). Purely visual. Modes:
##   * a sprite (`sprite_key`, SpriteBank grid art) at the largest WHOLE
##     scale that fits the box (capped at `max_scale`), so pixel art stays
##     one colour per art px; with `crop` a sprite taller or wider than the
##     box is shown at 1x from its top centre (a bust: the tiles), else it is
##     scaled down to fit (only the detail portrait of a giant),
##   * an icon (`icon_kind`, a 32 px badge in assets/sprites/icons/, else
##     Glyphs.draw_icon()'s drawn symbol) at a whole scale,
##   * `silhouette`: the sprite as one flat dark shape with a 1 px violet rim
##     (an entry not met yet; CodexData.SILHOUETTE_SHADER draws the flat
##     colour); an icon is drawn as a dim ghost instead,
##   * `unknown`: no art at all, a "?" in a dark socket (an undiscovered
##     evolution: the owner's recipe rule gives no shape and no hint).
## Grid art is drawn through the sharp-pixel shader (SpriteBank.apply_sharp)
## on whole layout px.
class_name CodexArt
extends Control

## The shared flat-silhouette material (built on first use).
static var _silhouette_mat: ShaderMaterial = null

## SpriteBank key of the sprite ("" = draw the icon).
var sprite_key: String = ""
## Icon kind (IconGlyph / Glyphs.draw_icon) used when there is no sprite.
var icon_kind: String = ""
## Largest whole scale (px per art px).
var max_scale: int = 1
## True: show an oversized sprite as a 1x bust (top centre) instead of shrinking it.
var crop: bool = false
## True: draw the entry as a silhouette (not met yet).
var silhouette: bool = false
## True: draw only the "?" socket (an undiscovered evolution).
var unknown: bool = false


func _init(min_size: Vector2 = Vector2(64, 64)) -> void:
	custom_minimum_size = min_size
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## Sets what to draw and redraws.
func show_entry(p_sprite: String, p_icon: String, p_silhouette: bool, p_unknown: bool) -> void:
	sprite_key = p_sprite
	icon_kind = p_icon
	silhouette = p_silhouette
	unknown = p_unknown
	queue_redraw()


func _draw() -> void:
	var box := Rect2(Vector2.ZERO, size)  # The drawing box (px).
	var tex: Texture2D = SpriteBank.texture(sprite_key) if sprite_key != "" and not unknown else null  # Sprite art (null = icon).
	_use_silhouette(tex != null and silhouette)
	if unknown:
		_draw_unknown(box)
		return
	if tex != null:
		_draw_sprite(tex, box)
		return
	if icon_kind == "":
		return
	var px := float(maxi(1, mini(max_scale, floori(minf(box.size.x, box.size.y) / 32.0)))) * 32.0  # Badge size (px).
	var r := Rect2(((box.size - Vector2(px, px)) * 0.5).floor(), Vector2(px, px))  # Badge rect, whole px.
	if silhouette:
		_ghost_icon(r)
		return
	Glyphs.draw_icon(self, icon_kind, r)


## Gives this node the flat-silhouette material (`on`) or the sharp-pixel one.
func _use_silhouette(on: bool) -> void:
	if on:
		if _silhouette_mat == null:
			_silhouette_mat = ShaderMaterial.new()
			_silhouette_mat.shader = load(CodexData.SILHOUETTE_SHADER) as Shader
			_silhouette_mat.set_shader_parameter("edge_softness", SpriteData.SHARP_EDGE_SOFTNESS)
		material = _silhouette_mat
		return
	if material == _silhouette_mat:
		material = null
	SpriteBank.apply_sharp(self)


## Draws `tex` at a whole scale in `box` (see the header), as art or silhouette.
func _draw_sprite(tex: Texture2D, box: Rect2) -> void:
	var ts := tex.get_size()  # Texture size (art px).
	var fit := minf(box.size.x / ts.x, box.size.y / ts.y)  # Scale that fits the whole sprite.
	var s := float(clampi(floori(fit), 1, max_scale))  # Whole scale.
	var src := Rect2(Vector2.ZERO, ts)  # Source region (texels).
	if fit < 1.0 and not crop:
		s = fit  # A giant on the portrait: shrink to fit (the only non-whole case).
	elif fit < 1.0:
		var w := minf(ts.x, box.size.x)  # Visible width (texels, at 1x).
		var h := minf(ts.y, box.size.y)  # Visible height (texels, from the top).
		src = Rect2(Vector2(floorf((ts.x - w) * 0.5), 0.0), Vector2(w, h))
	var dst_size := src.size * s  # Drawn size (px).
	var at := ((box.size - dst_size) * 0.5).floor()  # Top-left, whole px.
	if crop and fit < 1.0 and src.size.y < ts.y:
		at.y = 0.0  # A bust hangs from the box's top.
	var dst := Rect2(at, dst_size)
	if silhouette:
		for o: Vector2 in [Vector2(-1, 0), Vector2(1, 0), Vector2(0, -1), Vector2(0, 1)]:
			draw_texture_rect_region(tex, Rect2(dst.position + o, dst.size), src, CodexData.SILHOUETTE_RIM)
		draw_texture_rect_region(tex, dst, src, CodexData.SILHOUETTE)
		return
	draw_texture_rect_region(tex, dst, src)


## A dim, cold ghost of an icon badge (an entry not met yet).
func _ghost_icon(r: Rect2) -> void:
	var tex := SpriteBank.texture("icons/" + icon_kind)  # Badge art (null = drawn symbol).
	if tex != null:
		draw_texture_rect(tex, r, false, CodexData.GHOST_TINT)
		return
	Glyphs.draw_icon(self, icon_kind, r)
	draw_rect(r, Color(0.02, 0.0, 0.04, 0.7))


## The "?" socket of an undiscovered evolution.
func _draw_unknown(box: Rect2) -> void:
	var side := floorf(minf(box.size.x, box.size.y) * 0.7)  # Socket size (px).
	var r := Rect2(((box.size - Vector2(side, side)) * 0.5).floor(), Vector2(side, side))  # Socket rect.
	draw_style_box(UiTheme.style("slot"), r)
	var font := UiTheme.font_for()
	if font == null:
		return
	var fs := UiTheme.tier_px(UiTheme.Tier.HEADER if side >= 48.0 else UiTheme.Tier.NAME)  # "?" size (px).
	var col := Color(UiTheme.TEXT_DIM, CodexData.LOCKED_ALPHA)
	var w := font.get_string_size(RecipeBookData.LOCKED_GLYPH, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x  # Glyph width (px).
	var base := r.position + Vector2(floorf((side - w) * 0.5), floorf(side * 0.5 + float(fs) * 0.32))  # Baseline.
	draw_string(font, base, RecipeBookData.LOCKED_GLYPH, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)
