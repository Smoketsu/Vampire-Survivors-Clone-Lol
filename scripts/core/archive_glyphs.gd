## ArchiveGlyphs — the drawing of the Hollow Archive (Act II, Stage 5; GDD
## §15.0 "Act II: the Hollow Archive"): its kinds, the Librarian, the
## Archivist and her copies, the obstacles (shelves, desks, book piles, the
## orrery's globes and tables), the hazards (ink pools and wells, spore clouds,
## pages, curse sigils, rifts), the orrery, the tomes, the Erasure, the
## Reckoning's ink and the Forbidden Verse spell and icons. Each function draws
## the pixel-art sprite when its PNG exists (SpriteBank; keys in the ART_BIBLE
## manifest) and a code-drawn fallback otherwise, so art lands piece by piece.
## Purely visual: nothing here can change a run.
class_name ArchiveGlyphs
extends RefCounted

## Brass of the orrery (look only).
const BRASS: Color = Color(0.78, 0.60, 0.28)
## Dark brass (shadows, the hub's rim).
const BRASS_DARK: Color = Color(0.40, 0.29, 0.12)
## Old shelf wood.
const WOOD: Color = Color(0.30, 0.19, 0.12)
## Dark shelf wood.
const WOOD_DARK: Color = Color(0.16, 0.10, 0.07)
## Book spine colours (the code shelves).
const SPINES := [Color(0.42, 0.14, 0.16), Color(0.18, 0.26, 0.36), Color(0.36, 0.33, 0.20), Color(0.24, 0.30, 0.20)]
## Length (px) of one tile of the orrery-arm sprite (it is repeated along an arm).
const ARM_TILE: float = 64.0
## Long side (px) the ink pool / well decal is drawn at for a 1.0 scale (its FLAT_SIZES entry).
const POOL_ART: float = 64.0


# =====================================================================================
# Kinds (fallback glyphs; Glyphs.draw_enemy() draws eye/<kind> art first)
# =====================================================================================

## Draws Archive kind `kind`; false when it is not one (EyeGlyphs draws the rest).
static func draw_enemy(ci: CanvasItem, kind: String, o: Vector2, r: float, flash: bool) -> bool:
	match kind:
		"scribe":
			EyeGlyphs._cultist(ci, o, r, flash)
			# An open book in one hand, a quill in the other.
			ci.draw_rect(Rect2(o + Vector2(-r * 1.15, -r * 0.05), Vector2(r * 0.7, r * 0.5)), Glyphs._c(Palette.BONE, flash))
			ci.draw_line(o + Vector2(-r * 0.8, -r * 0.05), o + Vector2(-r * 0.8, r * 0.45), Glyphs.OUTLINE, 1.0)
			ci.draw_line(o + Vector2(r * 0.7, r * 0.2), o + Vector2(r * 1.2, -r * 0.9), Glyphs._c(ArchiveEnemyData.INK_SHEEN.lightened(0.3), flash), 2.0)
		"ink_wraith":
			var body := PackedVector2Array([o + Vector2(0, -r * 1.3), o + Vector2(r * 0.9, -r * 0.2), o + Vector2(r * 0.7, r * 0.9),
				o + Vector2(r * 0.2, r * 0.5), o + Vector2(-r * 0.2, r * 1.0), o + Vector2(-r * 0.7, r * 0.5), o + Vector2(-r * 0.9, -r * 0.2)])
			ci.draw_colored_polygon(body, Glyphs._c(ArchiveEnemyData.INK_COLOR.lightened(0.12), flash))
			ci.draw_polyline(body + PackedVector2Array([body[0]]), Glyphs._c(ArchiveEnemyData.INK_SHEEN, flash), 1.0)
			ci.draw_circle(o + Vector2(-r * 0.25, -r * 0.5), r * 0.13, Glyphs._c(Palette.EYE_BIOLUME_GLOW, flash))
			ci.draw_circle(o + Vector2(r * 0.25, -r * 0.5), r * 0.13, Glyphs._c(Palette.EYE_BIOLUME_GLOW, flash))
		"spore_pilgrim":
			EyeGlyphs._cultist(ci, o, r, flash)
			for i in 4:
				var p := o + Vector2(-r * 0.7 + float(i) * r * 0.45, r * 0.1 + float(i % 2) * r * 0.3)
				ci.draw_circle(p, r * 0.24, Glyphs._c(ArchiveEnemyData.SPORE_COLOR, flash))
			ci.draw_line(o + Vector2(r * 1.0, r * 0.95), o + Vector2(r * 1.0, -r * 1.3), Glyphs._c(Palette.BONE.darkened(0.3), flash), 2.0)
		"gibbering_mass", "gibbering_lesser", "gibbering_least":
			_draw_mass(ci, o, r, flash)
		"librarian":
			_draw_librarian(ci, o, r, flash)
		"unwritten_one":
			var robe := PackedVector2Array([o + Vector2(-r, r), o + Vector2(r, r), o + Vector2(r * 0.6, -r * 0.6), o + Vector2(0, -r * 1.3), o + Vector2(-r * 0.6, -r * 0.6)])
			ci.draw_colored_polygon(robe, Glyphs._c(ArchivistData.PAGE_COLOR, flash))
			for i in 4:
				var y := -r * 0.6 + float(i) * r * 0.4
				ci.draw_line(o + Vector2(-r * 0.6, y), o + Vector2(r * 0.6, y + r * 0.1), Glyphs._c(ArchiveEnemyData.INK_COLOR, flash), 1.0)
			ci.draw_circle(o + Vector2(0, -r * 0.7), r * 0.2, Glyphs._c(Palette.EYE_BIOLUME_GLOW, flash))
		"archive_rift":
			_draw_rift_slit(ci, o, r, flash)
		_:
			return false
	return true


## A Gibbering Mass: a lumpy blob covered in eyes and mouths.
static func _draw_mass(ci: CanvasItem, o: Vector2, r: float, flash: bool) -> void:
	var flesh := Glyphs._c(Palette.EYE_DROWNED.lerp(ArchiveEnemyData.SPORE_COLOR, 0.35), flash)
	ci.draw_circle(o + Vector2(0, r * 0.1), r * 1.02, Glyphs.OUTLINE)
	ci.draw_circle(o + Vector2(0, r * 0.1), r * 0.95, flesh)
	ci.draw_circle(o + Vector2(-r * 0.45, -r * 0.35), r * 0.5, flesh.lightened(0.08))
	ci.draw_circle(o + Vector2(r * 0.5, -r * 0.25), r * 0.42, flesh.darkened(0.08))
	for i in 5:
		var p := o + Vector2.from_angle(float(i) * 1.37) * r * 0.55
		ci.draw_circle(p, r * 0.16, Glyphs._c(Palette.BONE, flash))
		ci.draw_circle(p, r * 0.07, Glyphs._c(Palette.EYE_BIOLUME, flash))
	ci.draw_arc(o + Vector2(0, r * 0.45), r * 0.35, 0.3, PI - 0.3, 8, Glyphs.OUTLINE, 2.0)


## The Librarian: a floating eye wrapped in tendrils.
static func _draw_librarian(ci: CanvasItem, o: Vector2, r: float, flash: bool) -> void:
	for i in 7:
		var a := PI * 0.15 + float(i) * PI * 0.7 / 6.0
		var base := o + Vector2.from_angle(a) * r * 0.8
		ci.draw_polyline(PackedVector2Array([base, base + Vector2.from_angle(a - 0.4) * r * 0.6, base + Vector2.from_angle(a + 0.3) * r * 1.2]),
				Glyphs._c(Palette.EYE_DROWNED_DARK.lightened(0.15), flash), 3.0)
	ci.draw_circle(o, r * 0.95, Glyphs.OUTLINE)
	ci.draw_circle(o, r * 0.88, Glyphs._c(Palette.BONE.darkened(0.08), flash))
	ci.draw_circle(o, r * 0.5, Glyphs._c(Palette.EYE_BIOLUME, flash))
	ci.draw_circle(o, r * 0.24, Glyphs._c(ArchiveEnemyData.INK_COLOR, flash))
	ci.draw_circle(o + Vector2(-r * 0.15, -r * 0.18), r * 0.08, Glyphs._c(Palette.EYE_BIOLUME_GLOW, flash))
	ci.draw_arc(o, r * 0.92, PI + 0.4, TAU - 0.4, 16, Glyphs._c(Palette.EYE_DROWNED_DARK, flash), r * 0.25)


## A rift's tear (code look): a vertical slit of light.
static func _draw_rift_slit(ci: CanvasItem, o: Vector2, r: float, flash: bool) -> void:
	var slit := PackedVector2Array([o + Vector2(0, -r * 1.6), o + Vector2(r * 0.45, 0), o + Vector2(0, r * 1.6), o + Vector2(-r * 0.45, 0)])
	ci.draw_colored_polygon(slit, Glyphs._c(Palette.EYE_BIOLUME, flash))
	var core := PackedVector2Array([o + Vector2(0, -r * 1.2), o + Vector2(r * 0.18, 0), o + Vector2(0, r * 1.2), o + Vector2(-r * 0.18, 0)])
	ci.draw_colored_polygon(core, Glyphs._c(Palette.EYE_BIOLUME_GLOW, flash))


# =====================================================================================
# The Archivist and her copies
# =====================================================================================

## The Archivist (code look): a tall robe and a face that is an open book;
## `pose` as BossPoseData (1 reading, 2 splitting, 3 recover). `shadow` draws
## her drop shadow (only the real one casts one).
static func draw_archivist(ci: CanvasItem, o: Vector2, r: float, flash: bool, pose: int, shadow: bool) -> void:
	if shadow:
		ci.draw_set_transform(o + Vector2(0, r * 1.05), 0.0, Vector2(1.0, 0.35))
		ci.draw_circle(Vector2.ZERO, r * 1.1, Color(0, 0, 0, 0.4))
		ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var robe := PackedVector2Array([o + Vector2(-r * 1.0, r * 1.05), o + Vector2(r * 1.0, r * 1.05), o + Vector2(r * 0.55, -r * 0.7), o + Vector2(-r * 0.55, -r * 0.7)])
	ci.draw_colored_polygon(robe, Glyphs._c(Palette.EYE_DROWNED_DARK, flash))
	ci.draw_polyline(robe + PackedVector2Array([robe[0]]), Glyphs.OUTLINE, 1.5)
	# The open book of her face.
	var hy := -r * 1.15
	ci.draw_rect(Rect2(o + Vector2(-r * 0.55, hy - r * 0.35), Vector2(r * 1.1, r * 0.7)), Glyphs._c(ArchivistData.PAGE_COLOR, flash))
	ci.draw_line(o + Vector2(0, hy - r * 0.35), o + Vector2(0, hy + r * 0.35), Glyphs.OUTLINE, 1.5)
	for i in 3:
		var y := hy - r * 0.2 + float(i) * r * 0.16
		ci.draw_line(o + Vector2(-r * 0.45, y), o + Vector2(-r * 0.08, y), Glyphs._c(ArchiveEnemyData.INK_COLOR, flash), 1.0)
		ci.draw_line(o + Vector2(r * 0.08, y), o + Vector2(r * 0.45, y), Glyphs._c(ArchiveEnemyData.INK_COLOR, flash), 1.0)
	if pose == 1 or pose == 2:
		draw_reading_glow(ci, o + Vector2(0, hy - r * 0.6), r)


## The reading glow over her book while she casts.
static func draw_reading_glow(ci: CanvasItem, o: Vector2, r: float) -> void:
	ci.draw_circle(o, r * 0.5, Color(Palette.EYE_BIOLUME_GLOW, 0.25))
	ci.draw_arc(o, r * 0.55, 0.0, TAU, 16, Color(Palette.EYE_BIOLUME_GLOW, 0.7), 1.5)


## Draws sprite `key` like SpriteBank.draw() but WITHOUT its drop shadow (a
## Footnote copy casts none): grid art at its texel size, centred as
## SpriteBank does, tinted `tint`. False when there is no art.
static func draw_sprite_unshadowed(ci: CanvasItem, key: String, o: Vector2, flash: bool, tint: Color) -> bool:
	var tex := SpriteBank.texture(key)
	if tex == null or not SpriteBank.is_grid(key):
		return false
	var size := Vector2(tex.get_size()) * float(SpriteData.ART_SCALE)
	var centre := o + Vector2(0.0, size.y * SpriteData.CENTER_OFFSET)
	var top_left := ((centre - size * 0.5) / float(SpriteData.ART_SCALE)).round() * float(SpriteData.ART_SCALE)
	SpriteBank.apply_sharp(ci)
	ci.draw_texture_rect(tex, Rect2(top_left, size), false, SpriteData.FLASH_MODULATE if flash else tint)
	return true


# =====================================================================================
# Kit overlays
# =====================================================================================

## A Scribe's raised quill while it writes a curse (`k` 0..1 progress).
static func draw_quill_cast(ci: CanvasItem, o: Vector2, r: float, k: float) -> void:
	ci.draw_line(o + Vector2(-r * 0.3, r * 0.3), o + Vector2(r * 0.4, -r * 0.5), Color(ArchivistData.PAGE_COLOR, 0.9), 2.0)
	ci.draw_arc(o, r * (0.5 + 0.3 * k), 0.0, TAU * k, 16, Color(ArchiveEnemyData.INK_SHEEN, 0.9), 1.5)


## The ink sigil over a cursed cultist (`left` s of curse remain).
static func draw_curse_sigil(ci: CanvasItem, o: Vector2, now: float, left: float) -> void:
	if SpriteBank.draw_flat(ci, "markers/scribe_curse", o, 0.0, Color(1, 1, 1, clampf(left, 0.3, 1.0))):
		return
	var a := clampf(left, 0.3, 1.0)
	ci.draw_circle(o, 4.5, Color(ArchiveEnemyData.CURSE_COLOR, a))
	ci.draw_arc(o, 5.5, now * 2.0, now * 2.0 + PI * 1.4, 10, Color(ArchiveEnemyData.INK_SHEEN.lightened(0.3), a), 1.0)
	ci.draw_circle(o, 1.5, Color(Palette.EYE_BIOLUME_GLOW, a))


## An ink ripple at an Ink Wraith's feet while it sinks or rises.
static func draw_ink_ripple(ci: CanvasItem, r: float, t: float) -> void:
	ci.draw_set_transform(Vector2(0, r * 0.6), 0.0, Vector2(1.0, 0.45))
	ci.draw_circle(Vector2.ZERO, r * 1.4, Color(ArchiveEnemyData.INK_COLOR, 0.85))
	ci.draw_arc(Vector2.ZERO, r * (1.0 + 0.6 * fmod(t * 2.0, 1.0)), 0.0, TAU, 16, Color(ArchiveEnemyData.INK_SHEEN, 0.6), 1.5)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## The Librarian's eye charging its beam (`k` 0..1).
static func draw_eye_charge(ci: CanvasItem, o: Vector2, r: float, k: float) -> void:
	ci.draw_circle(o, r * (0.3 + 0.3 * k), Color(Palette.EYE_BIOLUME_GLOW, 0.25 + 0.35 * k))
	ci.draw_arc(o, r * (0.7 - 0.3 * k), 0.0, TAU, 20, Color(Palette.EYE_BIOLUME_GLOW, 0.8), 1.5)


## The Index beam from the Librarian's eye to `to` (local, unmirrored).
static func draw_index_beam(ci: CanvasItem, to: Vector2, width: float, now: float) -> void:
	var pulse := 0.5 + 0.5 * sin(now * 30.0)
	ci.draw_line(Vector2.ZERO, to, Color(Palette.EYE_BIOLUME, 0.35), width)
	ci.draw_line(Vector2.ZERO, to, Color(Palette.EYE_BIOLUME_GLOW, 0.6 + 0.3 * pulse), width * 0.35)
	ci.draw_line(Vector2.ZERO, to, Color(1, 1, 1, 0.8), 2.0)


## The Librarian's tendrils raised for the lash.
static func draw_tendrils_raised(ci: CanvasItem, r: float) -> void:
	for i in 6:
		var a := -PI * 0.9 + float(i) * PI * 0.8 / 5.0
		ci.draw_line(Vector2.from_angle(a) * r * 0.8, Vector2.from_angle(a) * r * 1.8, Color(Palette.EYE_DROWNED.lightened(0.2), 0.9), 3.0)


## The glow under an open rift.
static func draw_rift_glow(ci: CanvasItem, r: float, now: float) -> void:
	var pulse := 0.5 + 0.5 * sin(now * 4.0)
	ci.draw_set_transform(Vector2(0, r * 0.9), 0.0, Vector2(1.0, 0.4))
	ci.draw_circle(Vector2.ZERO, r * (1.6 + 0.2 * pulse), Color(Palette.EYE_BIOLUME, 0.25))
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## A rift being telegraphed at `pos`: a tear growing in the air (`k` 0..1).
static func draw_rift_telegraph(ci: CanvasItem, pos: Vector2, k: float, now: float, col: Color) -> void:
	var h := 8.0 + 34.0 * k
	var w := 2.0 + 8.0 * k
	ci.draw_circle(pos, 30.0 + 10.0 * k, Color(col, 0.10 + 0.12 * k))
	ci.draw_arc(pos, 34.0, now * 3.0, now * 3.0 + TAU * k, 24, Color(col, 0.8), 2.0)
	var slit := PackedVector2Array([pos + Vector2(0, -h), pos + Vector2(w, 0), pos + Vector2(0, h), pos + Vector2(-w, 0)])
	ci.draw_colored_polygon(slit, Color(Palette.EYE_BIOLUME_GLOW, 0.5 + 0.5 * k))


# =====================================================================================
# Hazards (ArchiveHazards, ArchiveHazardOverlay)
# =====================================================================================

## An ink pool of radius `r` at `pos`, alpha `a`.
static func draw_ink_pool(ci: CanvasItem, pos: Vector2, r: float, a: float, now: float) -> void:
	if SpriteBank.draw_flat(ci, "decals/ink_pool", pos, 0.0, Color(1, 1, 1, a), r * 2.0 / POOL_ART):
		return
	_ink_blot(ci, pos, r, a, now)


## An Ink Wells well of radius `r` at `pos` (`fill` 0..1).
static func draw_ink_well(ci: CanvasItem, pos: Vector2, r: float, fill: float, now: float) -> void:
	if SpriteBank.draw_flat(ci, "decals/ink_well", pos, 0.0, Color(1, 1, 1, fill), r * 2.0 / POOL_ART):
		return
	_ink_blot(ci, pos, r, fill, now)
	ci.draw_arc(pos, r + 2.0, 0.0, TAU, 28, Color(ArchiveEnemyData.INK_SHEEN, 0.35 * fill), 1.5)


## The code look of ink: a flattened black blot with a slow sheen.
static func _ink_blot(ci: CanvasItem, pos: Vector2, r: float, a: float, now: float) -> void:
	ci.draw_circle(pos, r, Color(ArchiveEnemyData.INK_COLOR, 0.9 * a))
	ci.draw_circle(pos + Vector2(r * 0.35, r * 0.2), r * 0.5, Color(ArchiveEnemyData.INK_COLOR, 0.9 * a))
	ci.draw_arc(pos, r * 0.7, now * 0.5, now * 0.5 + 1.2, 10, Color(ArchiveEnemyData.INK_SHEEN, 0.5 * a), 1.5)


## A spore cloud of radius `r` at `pos`, alpha `a` (`age` s old).
static func draw_spore_cloud(ci: CanvasItem, pos: Vector2, r: float, a: float, now: float, age: float) -> void:
	if SpriteBank.draw_anim(ci, "spore_cloud", pos, r * 2.2, fmod(age * 0.6, 1.0), a * 0.85):
		return
	for i in 5:
		var off := Vector2.from_angle(float(i) * 1.26 + now * 0.3) * r * 0.45
		ci.draw_circle(pos + off, r * 0.55, Color(ArchiveEnemyData.SPORE_COLOR, 0.12 * a))
	ci.draw_arc(pos, r, 0.0, TAU, 24, Color(ArchiveEnemyData.SPORE_COLOR, 0.35 * a), 1.0)


## One Recitation page (hovering pages flutter in place).
static func draw_page(ci: CanvasItem, pos: Vector2, angle: float, t: float, hovering: bool) -> void:
	var flutter := sin(t * 14.0) * 0.4
	if SpriteBank.draw_flat(ci, "projectiles/archive_page", pos, angle + flutter):
		return
	ci.draw_set_transform(pos, angle + flutter, Vector2(1.0, 0.7 + 0.3 * absf(sin(t * 9.0))))
	ci.draw_rect(Rect2(-6, -4, 12, 8), ArchivistData.PAGE_COLOR)
	ci.draw_line(Vector2(-4, -1), Vector2(4, -1), ArchiveEnemyData.INK_COLOR, 1.0)
	ci.draw_line(Vector2(-4, 2), Vector2(3, 2), ArchiveEnemyData.INK_COLOR, 1.0)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if hovering:
		ci.draw_arc(pos, 9.0, 0.0, TAU, 12, Color(Palette.EYE_BIOLUME_GLOW, 0.6), 1.0)


# =====================================================================================
# The Archive's director (tomes, orrery, Reckoning) and the Erasure
# =====================================================================================

## A forbidden tome on its lectern (`burn` 0..1 channel, `life` s left).
static func draw_tome(ci: CanvasItem, pos: Vector2, now: float, burn: float, life: float) -> void:
	var pulse := 0.5 + 0.5 * sin(now * 3.0)
	ci.draw_circle(pos, 30.0, Color(Palette.EYE_BIOLUME, 0.06 + 0.05 * pulse))
	ci.draw_arc(pos, 30.0, 0.0, TAU, 32, Color(Palette.EYE_BIOLUME_GLOW, 0.45), 1.5)
	if not SpriteBank.draw(ci, "structures/forbidden_lectern", pos, false):
		ci.draw_rect(Rect2(pos + Vector2(-3, -4), Vector2(6, 16)), WOOD)
		ci.draw_colored_polygon(PackedVector2Array([pos + Vector2(-12, -6), pos + Vector2(12, -6), pos + Vector2(9, -12), pos + Vector2(-9, -12)]), WOOD_DARK)
		ci.draw_rect(Rect2(pos + Vector2(-10, -16), Vector2(20, 7)), ArchivistData.PAGE_COLOR)
		ci.draw_line(pos + Vector2(0, -16), pos + Vector2(0, -9), ArchiveEnemyData.INK_COLOR, 1.0)
		ci.draw_circle(pos + Vector2(0, -20), 3.0 + pulse, Color(Palette.EYE_BIOLUME_GLOW, 0.7))
	if burn > 0.0:
		ci.draw_arc(pos, 22.0, -PI * 0.5, -PI * 0.5 + TAU * clampf(burn, 0.0, 1.0), 32, Palette.FLAME, 3.0)
	if life < 10.0:
		ci.draw_arc(pos, 34.0, 0.0, TAU * clampf(life / 10.0, 0.0, 1.0), 32, Color(ArchiveEnemyData.INK_SHEEN, 0.8), 1.0)


## The Reckoning's ink darkness pooled around the necromancer.
static func draw_ink_darkness(ci: CanvasItem, c: Vector2, now: float, col: Color) -> void:
	var pulse := 0.5 + 0.5 * sin(now * 1.2)
	for i in 4:
		ci.draw_arc(c, 640.0 - 90.0 * float(i), 0.0, TAU, 48, Color(col, 0.10 + 0.03 * pulse), 90.0)


## The swept sector of one orrery arm in the coming turn (`k` 0..1 telegraph).
static func draw_orrery_sweep(ci: CanvasItem, hub: Vector2, a0: float, turn: float, length: float, k: float, now: float) -> void:
	var steps := 10
	var pts := PackedVector2Array([hub])
	for j in steps + 1:
		pts.append(hub + Vector2.from_angle(a0 + turn * float(j) / float(steps)) * length)
	ci.draw_colored_polygon(pts, Color(BRASS, 0.08 + 0.12 * k * (0.6 + 0.4 * sin(now * 10.0))))
	ci.draw_line(hub, hub + Vector2.from_angle(a0 + turn) * length, Color(BRASS, 0.35 + 0.4 * k), 2.0)


## The orrery: its arms (tiled arm sprite or a code beam) and the hub.
static func draw_orrery(ci: CanvasItem, hub: Vector2, angle: float, n: int, length: float, width: float, hub_r: float, solid: bool, now: float) -> void:
	var a := 1.0 if solid else 0.55
	for i in n:
		var ang := angle + TAU * float(i) / float(n)
		var dir := Vector2.from_angle(ang)
		var drawn := false
		if SpriteBank.has("obstacles/orrery_arm"):
			var t := hub_r * 0.6
			while t < length:
				drawn = SpriteBank.draw_flat(ci, "obstacles/orrery_arm", hub + dir * (t + ARM_TILE * 0.5), ang, Color(1, 1, 1, a))
				t += ARM_TILE
		if not drawn:
			ci.draw_line(hub + Vector2(3, 4), hub + dir * length + Vector2(3, 4), Color(0, 0, 0, 0.3 * a), width)
			ci.draw_line(hub, hub + dir * length, Color(BRASS_DARK, a), width)
			ci.draw_line(hub, hub + dir * length, Color(BRASS, a), width - 5.0)
		# The planet at the arm's tip.
		var tip := hub + dir * length
		if not SpriteBank.draw_flat(ci, "obstacles/orrery_planet", tip, 0.0, Color(1, 1, 1, a)):
			ci.draw_circle(tip, width * 0.95, Color(BRASS_DARK, a))
			ci.draw_circle(tip, width * 0.75, Color(Palette.EYE_DROWNED.lightened(0.1 * float(i)), a))
	if not SpriteBank.draw_flat(ci, "structures/orrery_hub", hub, now * 0.05):
		ci.draw_circle(hub, hub_r, BRASS_DARK)
		ci.draw_circle(hub, hub_r - 4.0, BRASS)
		ci.draw_arc(hub, hub_r * 0.6, now * 0.2, now * 0.2 + TAU * 0.8, 20, BRASS_DARK, 2.0)
		ci.draw_circle(hub, hub_r * 0.25, Palette.EYE_BIOLUME)


## The Erasure: the erased, blank margin beyond `radius` around `center`, the
## inked edge, and the next edge glowing while `warning` (0..1) rises.
static func draw_erasure(ci: CanvasItem, center: Vector2, radius: float, next_radius: float, warning: float, now: float) -> void:
	var segs := 72
	var outer := radius + 1500.0
	for i in segs:
		var a0 := TAU * float(i) / float(segs)
		var a1 := TAU * float(i + 1) / float(segs)
		var quad := PackedVector2Array([center + Vector2.from_angle(a0) * radius, center + Vector2.from_angle(a1) * radius,
			center + Vector2.from_angle(a1) * outer, center + Vector2.from_angle(a0) * outer])
		ci.draw_colored_polygon(quad, Color(ArchivistData.ERASE_COLOR, 0.82))
	# Torn page edge.
	var edge := PackedVector2Array()
	for i in segs + 1:
		var a := TAU * float(i) / float(segs)
		edge.append(center + Vector2.from_angle(a) * (radius + 4.0 * sin(float(i) * 2.7 + now)))
	ci.draw_polyline(edge, ArchivistData.ERASE_EDGE, 3.0)
	if warning > 0.0:
		ci.draw_arc(center, next_radius, 0.0, TAU, segs, Color(ArchivistData.ERASE_EDGE.lightened(0.4), 0.3 + 0.6 * warning * (0.6 + 0.4 * sin(now * 12.0))), 2.0)


# =====================================================================================
# Obstacles (Arena: drawn when an obstacle kind has no sprite)
# =====================================================================================

## Draws an Archive obstacle kind; false when `o` is not one.
static func draw_obstacle(ci: CanvasItem, o: Arena.Obstacle) -> bool:
	var c := o.center
	match o.kind:
		"bookshelf", "toppled_shelf", "blank_shelf":
			var rect := Rect2(c - o.half, o.half * 2.0)
			ci.draw_rect(Rect2(rect.position + Vector2(4, 5), rect.size), Color(0, 0, 0, 0.35))
			ci.draw_rect(rect, WOOD_DARK)
			ci.draw_rect(rect.grow(-2.0), WOOD)
			var horizontal := o.half.x > o.half.y
			var long_len := (o.half.x if horizontal else o.half.y) * 2.0
			var k := 4.0
			var i := 0
			while k < long_len - 4.0:
				var col: Color = SPINES[(i + o.variant) % SPINES.size()]
				if o.kind == "blank_shelf":
					col = ArchivistData.PAGE_COLOR.darkened(0.15 * float(i % 2))
				var w := 3.0 + float((i * 7 + o.variant) % 3)
				if horizontal:
					ci.draw_rect(Rect2(Vector2(rect.position.x + k, rect.position.y + 3), Vector2(w - 1.0, rect.size.y - 6)), col)
				else:
					ci.draw_rect(Rect2(Vector2(rect.position.x + 3, rect.position.y + k), Vector2(rect.size.x - 6, w - 1.0)), col)
				k += w
				i += 1
		"reading_desk", "chart_table":
			var rect := Rect2(c - o.half, o.half * 2.0)
			ci.draw_rect(Rect2(rect.position + Vector2(3, 4), rect.size), Color(0, 0, 0, 0.35))
			ci.draw_rect(rect, WOOD_DARK)
			ci.draw_rect(rect.grow(-2.0), WOOD.lightened(0.1) if o.kind == "reading_desk" else BRASS_DARK)
			ci.draw_rect(Rect2(c - Vector2(8, 5), Vector2(16, 10)), ArchivistData.PAGE_COLOR)
		"book_pile", "page_heap":
			var r := o.radius
			ci.draw_circle(c + Vector2(3, 4), r, Color(0, 0, 0, 0.35))
			ci.draw_circle(c, r, WOOD_DARK)
			for j in 4:
				var col: Color = ArchivistData.PAGE_COLOR if o.kind == "page_heap" else SPINES[(j + o.variant) % SPINES.size()]
				ci.draw_rect(Rect2(c + Vector2(-r * 0.7, -r * 0.6 + float(j) * r * 0.32), Vector2(r * 1.4, r * 0.28)), col)
		"brass_globe":
			var r := o.radius
			ci.draw_circle(c + Vector2(3, 4), r, Color(0, 0, 0, 0.35))
			ci.draw_circle(c, r, BRASS_DARK)
			ci.draw_circle(c, r - 2.0, Palette.EYE_DROWNED_DARK)
			ci.draw_arc(c, r - 1.0, 0.0, TAU, 20, BRASS, 2.0)
			ci.draw_line(c + Vector2(-r, 0), c + Vector2(r, 0), BRASS, 1.5)
		_:
			return false
	return true


# =====================================================================================
# Forbidden Verse (the spell) and the icons
# =====================================================================================

## One orbiting Forbidden Verse page at `pos` (art pointing right).
static func draw_verse_page(ci: CanvasItem, pos: Vector2, angle: float, evolved: bool) -> void:
	var key := "projectiles/unwritten_page" if evolved else "projectiles/verse_page"
	if SpriteBank.draw_flat(ci, key, pos, angle):
		return
	ci.draw_set_transform(pos, angle, Vector2.ONE)
	ci.draw_rect(Rect2(-7, -5, 14, 10), Color(VerseData.INK_COLOR, 0.35))
	ci.draw_rect(Rect2(-6, -4, 12, 8), VerseData.PAGE_COLOR)
	ci.draw_line(Vector2(-4, -1), Vector2(4, -1), VerseData.INK_COLOR, 1.0)
	ci.draw_line(Vector2(-4, 2), Vector2(2, 2), VerseData.INK_COLOR, 1.0)
	if evolved:
		ci.draw_rect(Rect2(-6, -4, 12, 8), Palette.GOLD, false, 1.0)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## The inscription on an enemy (a violet glyph over it).
static func draw_inscription(ci: CanvasItem, pos: Vector2, phase: float) -> void:
	if SpriteBank.draw_flat(ci, "markers/inscription", pos, 0.0):
		return
	ci.draw_arc(pos, 5.0, phase, phase + PI * 1.5, 10, VerseData.INK_COLOR, 1.5)
	ci.draw_line(pos + Vector2(-3, 0), pos + Vector2(3, 0), VerseData.INK_COLOR.lightened(0.3), 1.0)


## Code icon of an Archive item (`kind`); false when it is not one.
static func draw_icon(ci: CanvasItem, kind: String, c: Vector2, s: float) -> bool:
	match kind:
		"forbidden_verse", "unwritten_word":
			var n := 6 if kind == "unwritten_word" else 3
			ci.draw_arc(c, s * 0.55, 0.0, TAU, 24, Color(VerseData.INK_COLOR, 0.6), 1.5)
			for i in n:
				var p := c + Vector2.from_angle(TAU * float(i) / float(n) - 0.6) * s * 0.55
				ci.draw_rect(Rect2(p - Vector2(s * 0.13, s * 0.09), Vector2(s * 0.26, s * 0.18)), VerseData.PAGE_COLOR)
			ci.draw_circle(c, s * 0.16, VerseData.INK_COLOR)
			if kind == "unwritten_word":
				ci.draw_arc(c, s * 0.72, 0.0, TAU, 24, Palette.GOLD, 1.5)
		"marginalia":
			ci.draw_rect(Rect2(c - Vector2(s * 0.45, s * 0.55), Vector2(s * 0.9, s * 1.1)), VerseData.PAGE_COLOR)
			for i in 4:
				ci.draw_line(c + Vector2(-s * 0.15, -s * 0.35 + float(i) * s * 0.22), c + Vector2(s * 0.35, -s * 0.35 + float(i) * s * 0.22), Color(0.2, 0.2, 0.25), 1.0)
			ci.draw_circle(c + Vector2(-s * 0.3, s * 0.1), s * 0.14, VerseData.INK_COLOR)
		"iron_mind":
			ci.draw_circle(c, s * 0.55, Palette.UNDEAD_STEEL)
			ci.draw_arc(c, s * 0.55, 0.0, TAU, 20, Palette.SILVER, 2.0)
			ci.draw_circle(c, s * 0.22, Palette.EYE_BIOLUME)
			ci.draw_line(c + Vector2(-s * 0.55, 0), c + Vector2(s * 0.55, 0), Palette.SILVER, 1.5)
		_:
			return false
	return true
