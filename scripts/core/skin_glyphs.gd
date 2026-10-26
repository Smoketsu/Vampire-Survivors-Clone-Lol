## SkinGlyphs — draws the necromancer in a cosmetic SKIN (SkinData; purely
## visual, it never touches gameplay state, so determinism is unaffected).
## Necromancer._draw() calls draw_skin() when a non-default skin is worn and
## the setup screen's skin cards (PreRunHyperSkins) call it for previews.
## Order of preference, so skins are visible before their art exists:
##   1. the skin's own sprite ("player/<character>_<skin>.png"),
##   2. the character's sprite drawn with the skin's palette `tint`, plus a
##      faint `accent` aura ring at the feet and the skin's `emblem` (crown,
##      halo, broken halo, sun corona, plague mask) over the head,
##   3. a character without its own art: THAT character's look
##      (CharacterGlyphs.draw_player(): the school-tinted necromancer art or
##      its glyph variant) times the skin's `tint`, with the same aura and
##      emblem,
##   4. the Gravecaller without any art: the code-drawn necromancer
##      silhouette (Glyphs.draw_necromancer's shape) recoloured by the palette.
## The node's mirroring (scale.x = -1) flips everything with the facing.
class_name SkinGlyphs
extends RefCounted


## Draws skin `id` centred near `o` on `ci` (body radius `r`, white while
## `flash`), palette-swapped by `recolour` (RecolourData id, "" = the skin's own
## colours; sprite art only, a code-drawn glyph keeps its palette). Returns
## false (drawing nothing) for an unknown id.
static func draw_skin(ci: CanvasItem, id: String, o: Vector2, r: float, flash: bool, recolour: String = "") -> bool:
	var row := SkinData.skin(id)  # Skin data ({} if unknown).
	if row.is_empty():
		return false
	if SpriteBank.draw(ci, String(row["sprite"]), o, flash, Color.WHITE, recolour):
		return true  # The skin's own art exists.
	var accent: Color = row["accent"]  # Emblem / aura colour (alpha 0 = none).
	var emblem := String(row["emblem"])  # Emblem shape id.
	var icon := SpriteBank.icon_cap > 0.0  # Drawing a UI preview, not the world.
	if accent.a > 0.0 and not icon:
		_aura(ci, o, accent)
	var ch := String(row["character"])  # The owning character.
	var base := SkinData.base_sprite(ch)  # The character's own sprite key.
	var has_art := SpriteBank.has(base)  # The character has sprite art.
	var own_look := not has_art and ch != CharacterData.DEFAULT_ID  # Fall back to that character's look (CharacterGlyphs).
	var drawn := base if has_art else (CharacterGlyphs.drawn_sprite_key(ch) if own_look else "")  # Art key drawn ("" = a glyph).
	var top := o + SkinData.GLYPH_HEAD_TOP * r  # Top of the head (px).
	var unit := r * SkinData.GLYPH_HEAD_UNIT  # Emblem size unit (px).
	if drawn != "":
		var h := SpriteBank.drawn_height(drawn)  # Drawn height (px; grid art in icons uses a whole-number scale).
		var centre := o + Vector2(0.0, 0.0 if icon else h * SpriteData.CENTER_OFFSET)  # Sprite centre (px).
		top = centre + SkinData.SPRITE_HEAD_TOP * h
		unit = h * SkinData.SPRITE_HEAD_UNIT
	var behind := emblem == "corona"  # The sun corona blazes behind the head.
	if accent.a > 0.0 and behind:
		_emblem(ci, emblem, top, unit, accent, row["glow"])
	if has_art:
		SpriteBank.draw(ci, base, o, flash, row["tint"], recolour)
	elif own_look:
		CharacterGlyphs.draw_player(ci, ch, o, r, flash, row["tint"], recolour)
	else:
		_glyph(ci, o, r, flash, row)
	if accent.a > 0.0 and not behind:
		_emblem(ci, emblem, top, unit, accent, row["glow"])
	return true


## Builds the recoloured art of the sprite skin `id` ("" = the character's
## default look) of `character` draws, for recolour `recolour`, ahead of the
## first frame (SpriteBank.warm_recolour()). Does nothing without a recolour.
static func warm(id: String, character: String, recolour: String) -> void:
	if recolour == "":
		return
	var key := SkinData.base_sprite(character)  # The character's own sprite.
	var row := SkinData.skin(id)  # The skin ({} for the default look).
	if not row.is_empty() and SpriteBank.has(String(row["sprite"])):
		key = String(row["sprite"])  # The skin's own art.
	SpriteBank.warm_recolour(key, recolour)


## Faint accent ellipse under the feet (on top of the player's ground ring).
static func _aura(ci: CanvasItem, o: Vector2, accent: Color) -> void:
	ci.draw_set_transform(o + Vector2(0.0, SkinData.AURA_OFFSET), 0.0, Vector2(1.0, SkinData.AURA_SQUASH))
	ci.draw_arc(Vector2.ZERO, SkinData.AURA_RADIUS, 0.0, TAU, 40, Color(accent, SkinData.AURA_ALPHA), SkinData.AURA_WIDTH / SkinData.AURA_SQUASH * 0.6)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## The necromancer glyph (same silhouette as Glyphs.draw_necromancer)
## recoloured by the skin palette: robe and hood times `tint`, eyes and the
## staff orb in `glow`, the robe seam in `accent` (violet when none).
static func _glyph(ci: CanvasItem, o: Vector2, r: float, flash: bool, row: Dictionary) -> void:
	var tint: Color = row["tint"]  # Robe / hood multiplier.
	var glow: Color = row["glow"]  # Eyes and orb.
	var accent: Color = row["accent"]  # Seam colour (alpha 0 = default violet).
	ci.draw_circle(o + Vector2(0, r * 0.9), r * 0.9, Color(0, 0, 0, 0.35))
	var robe := PackedVector2Array([o + Vector2(0, -r * 1.25), o + Vector2(-r, r * 1.05), o + Vector2(r, r * 1.05)])
	ci.draw_colored_polygon(robe, _fc(flash, Palette.ROBE * tint))
	ci.draw_line(o + Vector2(-r * 0.5, r * 1.0), o + Vector2(0, -r * 0.2), _fc(flash, accent if accent.a > 0.0 else Palette.VIOLET), 1.5)
	ci.draw_circle(o + Vector2(0, -r * 0.6), r * 0.52, _fc(flash, Color(0.12, 0.05, 0.18) * tint))
	ci.draw_circle(o + Vector2(0, -r * 0.52), r * 0.3, _fc(flash, Palette.BONE * Color(minf(tint.r, 1.0), minf(tint.g, 1.0), minf(tint.b, 1.0))))
	ci.draw_circle(o + Vector2(-r * 0.12, -r * 0.55), r * 0.08, glow)
	ci.draw_circle(o + Vector2(r * 0.12, -r * 0.55), r * 0.08, glow)
	ci.draw_line(o + Vector2(r * 0.95, r * 1.05), o + Vector2(r * 1.15, -r * 1.3), _fc(flash, Color(0.45, 0.38, 0.3) * tint), 2.0)
	ci.draw_circle(o + Vector2(r * 1.17, -r * 1.42), r * 0.55, Color(glow, 0.25))
	ci.draw_circle(o + Vector2(r * 1.17, -r * 1.42), r * 0.3, _fc(flash, glow))


## Returns the hit-flash colour while `flash`, else `col`.
static func _fc(flash: bool, col: Color) -> Color:
	return Palette.FLASH if flash else col


## Draws emblem `kind` sitting on the head top `top` (size unit `u` px).
static func _emblem(ci: CanvasItem, kind: String, top: Vector2, u: float, accent: Color, glow: Color) -> void:
	var w := maxf(1.0, u * 0.18)  # Line width (px).
	match kind:
		"crown":
			var b := top.y + u * 0.2  # Crown base line.
			var pts := PackedVector2Array([
				Vector2(top.x - u * 0.75, b), Vector2(top.x - u * 0.75, b - u * 0.55), Vector2(top.x - u * 0.38, b - u * 0.25),
				Vector2(top.x, b - u * 0.8), Vector2(top.x + u * 0.38, b - u * 0.25), Vector2(top.x + u * 0.75, b - u * 0.55),
				Vector2(top.x + u * 0.75, b)])
			ci.draw_colored_polygon(pts, accent)
			ci.draw_polyline(pts + PackedVector2Array([pts[0]]), accent.darkened(0.45), maxf(1.0, w * 0.6))
			ci.draw_circle(Vector2(top.x, b - u * 0.3), u * 0.13, Palette.CRIMSON)
		"halo", "broken_halo":
			var c := top + Vector2(0.0, -u * 0.35)  # Halo centre.
			ci.draw_set_transform(c, 0.0, Vector2(1.0, 0.38))
			if kind == "halo":
				ci.draw_arc(Vector2.ZERO, u * 0.95, 0.0, TAU, 28, Color(accent, 0.95), w / 0.38 * 0.5)
			else:  # Cracked: two arcs with gaps, the Heretic Saint.
				ci.draw_arc(Vector2.ZERO, u * 0.95, 0.25, 2.6, 18, Color(accent, 0.95), w / 0.38 * 0.5)
				ci.draw_arc(Vector2.ZERO, u * 0.95, 2.95, 5.6, 18, Color(accent, 0.95), w / 0.38 * 0.5)
			ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		"corona":
			var c := top + Vector2(0.0, u * 0.65)  # Head centre.
			ci.draw_arc(c, u * 1.05, 0.0, TAU, 28, Color(accent, 0.55), maxf(1.0, w * 0.7))
			for i in 10:
				var d := Vector2.from_angle(TAU * float(i) / 10.0 - PI * 0.5)  # Ray direction.
				ci.draw_line(c + d * u * 1.15, c + d * u * (1.5 if i % 2 == 0 else 1.35), Color(accent, 0.9), w)
		"mask":
			var face := top + Vector2(0.0, u * 0.75)  # Face centre.
			ci.draw_line(Vector2(top.x - u * 1.1, top.y + u * 0.15), Vector2(top.x + u * 1.1, top.y + u * 0.15), Color(0.2, 0.15, 0.1), w * 1.6)  # Hat brim.
			ci.draw_colored_polygon(PackedVector2Array([face + Vector2(0.0, -u * 0.22), face + Vector2(u * 1.05, u * 0.12), face + Vector2(0.0, u * 0.3)]), Color(0.32, 0.25, 0.18))  # Beak.
			ci.draw_polyline(PackedVector2Array([face + Vector2(0.0, -u * 0.22), face + Vector2(u * 1.05, u * 0.12), face + Vector2(0.0, u * 0.3)]), accent, maxf(1.0, w * 0.6))
			ci.draw_circle(face + Vector2(-u * 0.15, -u * 0.08), u * 0.14, glow)  # Lens.
