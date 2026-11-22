## NorseGlyphs — code-drawn fallback shapes for THE HALL OF THE SLAIN (the Norse
## act, temporarily Act XI; GDD §15.0 "The Hall of the Slain foundation (phase
## 1)"), drawn when a kind has no sprite art (assets/sprites/norse/<kind>.png):
## frost white, iron grey, pine green-black and hearth amber, with valkyrie gold
## and the ice-blue rune glow (never the undead's soul-teal, never the
## necromancer's violet and bone). Also:
##   * a Rune-Stone when its sprite is missing (draw_stone(): RuneStones) and a
##     brazier (draw_brazier(): LongWinter);
##   * the Norse stubs' placeholder obstacles (barrow mounds, snowy pines and
##     boulders, the hall's long tables and pillars, ash rocks).
## Every Norse kind without a shape of its own gets the raider. Purely visual;
## the kinds' glyphs are drawn only when their art is missing.
class_name NorseGlyphs
extends RefCounted

## Outline ink.
const INK := Palette.NORSE_INK


# =====================================================================================
# Kinds
# =====================================================================================

## Draws Norse kind `kind`. Returns false when `kind` is not a Norse kind
## (Glyphs.draw_enemy() then asks the next faction's glyphs).
static func draw_enemy(ci: CanvasItem, kind: String, o: Vector2, r: float, flash: bool) -> bool:
	var row := EnemyDirector.norse_def(kind)  # Its design row ({} = not a Norse kind).
	if row.is_empty():
		return false
	# Phase 2: each Norse stage's own fallbacks go here, before the shared kinds'.
	match kind:
		"shield_maiden":
			_maiden(ci, o, r, flash)
		"berserker":
			_berserker(ci, o, r, flash)
		"skald":
			_skald(ci, o, r, flash)
		"valkyrie":
			_valkyrie(ci, o, r, flash)
		"seer":
			_seer(ci, o, r, flash)
		"draugr", "draugr_female", "barrow_wight":  # Act XI (temporary), the Barrow Fields: the barrow-dead share the draugr's shape.
			_draugr(ci, o, r, flash)
		"wolf_of_the_wastes":
			_wolf(ci, o, r, flash)
		"frost_giant", "fire_giant":
			_giant(ci, o, r, flash, kind == "fire_giant")
		"rune_stone":
			draw_stone(ci, o, r, true)
		"brazier":
			draw_brazier(ci, o, r, true)
		_:
			_raider(ci, o, r, flash)
	return true


## Raider: iron helm, pine cloak, a round shield of hearth wood, an axe.
static func _raider(ci: CanvasItem, o: Vector2, r: float, flash: bool) -> void:
	var body := Rect2(o + Vector2(-r * 0.55, -r * 0.6), Vector2(r * 1.1, r * 1.5))
	ci.draw_rect(body.grow(1.0), INK)
	ci.draw_rect(body, Glyphs._c(Palette.NORSE_PINE_LIGHT, flash))  # Cloak and tunic.
	SpriteBank.draw_disc(ci, o + Vector2(0.0, -r * 0.95), r * 0.45, Glyphs._c(Palette.NORSE_IRON, flash))  # Helm.
	SpriteBank.draw_disc(ci, o + Vector2(-r * 0.7, 0.0), r * 0.55, Glyphs._c(INK, flash))
	SpriteBank.draw_disc(ci, o + Vector2(-r * 0.7, 0.0), r * 0.48, Glyphs._c(Palette.NORSE_HEARTH_DARK, flash))  # Round shield.
	SpriteBank.draw_disc(ci, o + Vector2(-r * 0.7, 0.0), r * 0.16, Glyphs._c(Palette.NORSE_IRON, flash))  # Boss.
	ci.draw_line(o + Vector2(r * 0.7, r * 0.6), o + Vector2(r * 0.7, -r * 0.8), Glyphs._c(Palette.NORSE_HEARTH_DARK, flash), 2.0)  # Axe haft.
	ci.draw_rect(Rect2(o + Vector2(r * 0.7, -r * 0.9), Vector2(r * 0.4, r * 0.35)), Glyphs._c(Palette.NORSE_FROST_SHADE, flash))  # Axe head.


## Shield-Maiden: a figure in mail with a long braid, a kite of a round
## shield and a spear (fully clothed).
static func _maiden(ci: CanvasItem, o: Vector2, r: float, flash: bool) -> void:
	var skirt := Rect2(o + Vector2(-r * 0.6, 0.0), Vector2(r * 1.2, r * 0.9))
	ci.draw_rect(skirt.grow(1.0), INK)
	ci.draw_rect(skirt, Glyphs._c(Palette.NORSE_PINE_LIGHT, flash))
	ci.draw_rect(Rect2(o + Vector2(-r * 0.4, -r * 0.75), Vector2(r * 0.8, r * 0.8)), Glyphs._c(Palette.NORSE_IRON, flash))  # Mail.
	SpriteBank.draw_disc(ci, o + Vector2(0.0, -r * 1.05), r * 0.35, Glyphs._c(Palette.NORSE_FROST_SHADE, flash))  # Face.
	ci.draw_rect(Rect2(o + Vector2(r * 0.2, -r * 1.2), Vector2(r * 0.18, r * 0.9)), Glyphs._c(Palette.NORSE_HEARTH, flash))  # Braid.
	SpriteBank.draw_disc(ci, o + Vector2(-r * 0.75, -r * 0.1), r * 0.6, Glyphs._c(INK, flash))
	SpriteBank.draw_disc(ci, o + Vector2(-r * 0.75, -r * 0.1), r * 0.52, Glyphs._c(Palette.NORSE_FROST, flash))  # White shield.
	ci.draw_line(o + Vector2(r * 0.8, r * 0.9), o + Vector2(r * 0.8, -r * 1.6), Glyphs._c(Palette.NORSE_HEARTH_DARK, flash), 1.5)  # Spear.
	SpriteBank.draw_disc(ci, o + Vector2(r * 0.8, -r * 1.65), 2.0, Glyphs._c(Palette.NORSE_FROST_SHADE, flash))


## Berserker: a broad body in a bear pelt, two axes.
static func _berserker(ci: CanvasItem, o: Vector2, r: float, flash: bool) -> void:
	SpriteBank.draw_disc(ci, o, r * 1.0, Glyphs._c(INK, flash))
	SpriteBank.draw_disc(ci, o, r * 0.9, Glyphs._c(Color(0.32, 0.22, 0.14), flash))  # Bear pelt.
	SpriteBank.draw_disc(ci, o + Vector2(0.0, -r * 0.55), r * 0.45, Glyphs._c(Color(0.25, 0.17, 0.11), flash))  # Bear head over his own.
	for s in [-1.0, 1.0]:
		ci.draw_line(o + Vector2(r * 0.9 * s, r * 0.5), o + Vector2(r * 1.1 * s, -r * 0.6), Glyphs._c(Palette.NORSE_HEARTH_DARK, flash), 2.0)
		ci.draw_rect(Rect2(o + Vector2(r * 1.1 * s - r * 0.2, -r * 0.8), Vector2(r * 0.4, r * 0.3)), Glyphs._c(Palette.NORSE_FROST_SHADE, flash))


## Skald: a cloaked singer with a horn at his hip and a lyre.
static func _skald(ci: CanvasItem, o: Vector2, r: float, flash: bool) -> void:
	_raider(ci, o, r, flash)
	ci.draw_rect(Rect2(o + Vector2(-r * 0.3, -r * 0.1), Vector2(r * 0.6, r * 0.5)), Glyphs._c(Palette.NORSE_HEARTH, flash))  # Lyre.
	ci.draw_line(o + Vector2(r * 0.2, r * 0.6), o + Vector2(r * 0.7, r * 0.3), Glyphs._c(Palette.NORSE_FROST, flash), 2.0)  # Horn.


## Valkyrie: a figure in silver mail with gold wings and a spear (fully clothed).
static func _valkyrie(ci: CanvasItem, o: Vector2, r: float, flash: bool) -> void:
	for s in [-1.0, 1.0]:
		SpriteBank.draw_disc(ci, o + Vector2(r * 0.95 * s, -r * 0.5), r * 0.7, Glyphs._c(Palette.NORSE_VALKYRIE_GOLD, flash))  # Wings.
	var skirt := Rect2(o + Vector2(-r * 0.55, 0.0), Vector2(r * 1.1, r * 0.9))
	ci.draw_rect(skirt.grow(1.0), INK)
	ci.draw_rect(skirt, Glyphs._c(Palette.NORSE_FROST_SHADE, flash))
	ci.draw_rect(Rect2(o + Vector2(-r * 0.4, -r * 0.75), Vector2(r * 0.8, r * 0.8)), Glyphs._c(Palette.NORSE_FROST, flash))  # Silver mail.
	SpriteBank.draw_disc(ci, o + Vector2(0.0, -r * 1.05), r * 0.35, Glyphs._c(Palette.NORSE_VALKYRIE_GOLD, flash))  # Winged helm.
	ci.draw_line(o + Vector2(r * 0.8, r * 0.9), o + Vector2(r * 0.8, -r * 1.6), Glyphs._c(Palette.NORSE_FROST, flash), 1.5)  # Spear.


## Seer: a hooded figure in a long pine robe with a rune-staff (fully clothed).
static func _seer(ci: CanvasItem, o: Vector2, r: float, flash: bool) -> void:
	var robe := Rect2(o + Vector2(-r * 0.6, -r * 0.6), Vector2(r * 1.2, r * 1.6))
	ci.draw_rect(robe.grow(1.0), INK)
	ci.draw_rect(robe, Glyphs._c(Palette.NORSE_PINE, flash))
	SpriteBank.draw_disc(ci, o + Vector2(0.0, -r * 0.95), r * 0.42, Glyphs._c(Palette.NORSE_PINE_LIGHT, flash))  # Hood.
	SpriteBank.draw_disc(ci, o + Vector2(0.0, -r * 0.9), r * 0.22, Glyphs._c(Palette.NORSE_FROST_SHADE, flash))  # Face.
	ci.draw_line(o + Vector2(r * 0.8, r * 0.9), o + Vector2(r * 0.8, -r * 1.4), Glyphs._c(Palette.NORSE_HEARTH_DARK, flash), 1.5)  # Staff.
	SpriteBank.draw_disc(ci, o + Vector2(r * 0.8, -r * 1.45), 2.5, Palette.NORSE_RUNE)


## Draugr: a grey-blue corpse in rusted mail, cold eyes.
static func _draugr(ci: CanvasItem, o: Vector2, r: float, flash: bool) -> void:
	var body := Rect2(o + Vector2(-r * 0.55, -r * 0.6), Vector2(r * 1.1, r * 1.5))
	ci.draw_rect(body.grow(1.0), INK)
	ci.draw_rect(body, Glyphs._c(Palette.NORSE_IRON_DARK, flash))  # Rusted mail.
	ci.draw_rect(Rect2(o + Vector2(-r * 0.4, -r * 0.2), Vector2(r * 0.8, r * 0.25)), Glyphs._c(Color(0.45, 0.25, 0.14), flash))  # Rust.
	SpriteBank.draw_disc(ci, o + Vector2(0.0, -r * 0.95), r * 0.42, Glyphs._c(Color(0.52, 0.60, 0.64), flash))  # Grey-blue head.
	ci.draw_rect(Rect2(o + Vector2(-r * 0.22, -r * 1.05), Vector2(2, 2)), Palette.NORSE_RUNE)  # Cold eyes.
	ci.draw_rect(Rect2(o + Vector2(r * 0.1, -r * 1.05), Vector2(2, 2)), Palette.NORSE_RUNE)


## Wolf of the Wastes: a grey wolf seen from above, a pale muzzle.
static func _wolf(ci: CanvasItem, o: Vector2, r: float, flash: bool) -> void:
	var body := Rect2(o + Vector2(-r * 1.0, -r * 0.45), Vector2(r * 1.8, r * 0.9))
	ci.draw_rect(body.grow(1.0), INK)
	ci.draw_rect(body, Glyphs._c(Palette.NORSE_IRON, flash))
	SpriteBank.draw_disc(ci, o + Vector2(r * 0.9, -r * 0.1), r * 0.45, Glyphs._c(Palette.NORSE_FROST_SHADE, flash))  # Head.
	ci.draw_rect(Rect2(o + Vector2(r * 1.05, -r * 0.25), Vector2(2, 2)), Palette.NORSE_HEARTH)  # Eye.


## A giant: a huge body (frost-blue with a white beard, or burning for the
## fire-giant of the south).
static func _giant(ci: CanvasItem, o: Vector2, r: float, flash: bool, fire: bool) -> void:
	var skin := Color(0.55, 0.68, 0.78) if not fire else Color(0.45, 0.18, 0.10)  # Frost-blue / charred.
	SpriteBank.draw_disc(ci, o, r * 1.0, Glyphs._c(INK, flash))
	SpriteBank.draw_disc(ci, o, r * 0.9, Glyphs._c(skin, flash))
	SpriteBank.draw_disc(ci, o + Vector2(0.0, -r * 0.65), r * 0.38, Glyphs._c(skin.lightened(0.15), flash))  # Head.
	SpriteBank.draw_disc(ci, o + Vector2(0.0, -r * 0.4), r * 0.3, Glyphs._c(Palette.NORSE_FROST if not fire else Palette.NORSE_FIRE, flash))  # Beard / flames.
	ci.draw_rect(Rect2(o + Vector2(-r * 0.6, r * 0.1), Vector2(r * 1.2, r * 0.25)), Glyphs._c(Palette.NORSE_HEARTH_DARK, flash))  # Belt.


# =====================================================================================
# The Rune-Stone and the placeholder obstacles
# =====================================================================================

## A Rune-Stone when its sprite is missing (RuneStones): a tall carved stone
## with glowing ice-blue runes while the hall holds it, dark and cracked once
## taken. Textures and rects only.
static func draw_stone(ci: CanvasItem, o: Vector2, r: float, held: bool) -> void:
	SpriteBank.draw_disc(ci, o + Vector2(0.0, r * 0.9), r * 0.9, Color(0.0, 0.0, 0.0, 0.3))  # Shadow.
	var stone := Rect2(o + Vector2(-r * 0.6, -r * 1.6), Vector2(r * 1.2, r * 2.4))
	ci.draw_rect(stone.grow(1.0), INK)
	ci.draw_rect(stone, Palette.NORSE_IRON if held else Palette.NORSE_IRON_DARK)
	ci.draw_rect(Rect2(stone.position, Vector2(stone.size.x, r * 0.3)), Palette.NORSE_FROST)  # Snow on top.
	var rune := Palette.NORSE_RUNE if held else Color(0.2, 0.22, 0.25)  # Glowing / dead runes.
	for i in 4:
		ci.draw_rect(Rect2(o + Vector2(-r * 0.2, -r * 1.1 + float(i) * r * 0.5), Vector2(r * 0.4, 2.0)), rune)
		ci.draw_rect(Rect2(o + Vector2(-1.0, -r * 1.2 + float(i) * r * 0.5), Vector2(2.0, r * 0.35)), rune)


## A brazier when its sprite is missing (LongWinter): an iron fire-basket on a
## stone foot, burning amber while lit, cold ash once doused. Textures and
## rects only.
static func draw_brazier(ci: CanvasItem, o: Vector2, r: float, lit: bool) -> void:
	SpriteBank.draw_disc(ci, o + Vector2(0.0, r * 0.8), r * 0.9, Color(0.0, 0.0, 0.0, 0.3))  # Shadow.
	ci.draw_rect(Rect2(o + Vector2(-r * 0.25, -r * 0.2), Vector2(r * 0.5, r * 1.0)), INK)  # Stand.
	ci.draw_rect(Rect2(o + Vector2(-r * 0.8, -r * 0.7), Vector2(r * 1.6, r * 0.6)).grow(1.0), INK)
	ci.draw_rect(Rect2(o + Vector2(-r * 0.8, -r * 0.7), Vector2(r * 1.6, r * 0.6)), Palette.NORSE_IRON)  # Basket.
	if lit:
		SpriteBank.draw_disc(ci, o + Vector2(0.0, -r * 1.0), r * 0.7, Palette.NORSE_HEARTH)  # Flames.
		SpriteBank.draw_disc(ci, o + Vector2(0.0, -r * 1.2), r * 0.4, Palette.NORSE_VALKYRIE_GOLD)
	else:
		SpriteBank.draw_disc(ci, o + Vector2(0.0, -r * 0.8), r * 0.5, Palette.NORSE_FROST_SHADE)  # Cold ash, snow.


## Draws a Norse stub's placeholder obstacle. False when `o` is none of them.
static func draw_obstacle(ci: CanvasItem, o: Arena.Obstacle) -> bool:
	var c := o.center
	match o.kind:
		"norse_barrow":
			var r := o.radius
			SpriteBank.draw_disc(ci, c + Vector2(4, 5), r * 1.05, Color(0, 0, 0, 0.35))
			SpriteBank.draw_disc(ci, c, r, INK)
			SpriteBank.draw_disc(ci, c, r - 1.5, Palette.NORSE_PINE_LIGHT)  # A grassy mound.
			SpriteBank.draw_disc(ci, c + Vector2(-r * 0.2, -r * 0.25), r * 0.55, Palette.NORSE_FROST)  # Snow cap.
			ci.draw_rect(Rect2(c + Vector2(-3.0, r * 0.3), Vector2(6.0, r * 0.5)), Palette.NORSE_INK)  # The barrow's door.
		"norse_pine":
			var r := o.radius
			SpriteBank.draw_disc(ci, c + Vector2(4, 5), r * 1.1, Color(0, 0, 0, 0.35))
			SpriteBank.draw_disc(ci, c, r, INK)
			SpriteBank.draw_disc(ci, c, r - 1.5, Palette.NORSE_PINE)
			SpriteBank.draw_disc(ci, c + Vector2(-r * 0.25, -r * 0.3), r * 0.5, Palette.NORSE_FROST_SHADE)  # Snow on the boughs.
		"norse_boulder", "norse_ash_rock":
			var r := o.radius
			var ash := o.kind == "norse_ash_rock"
			SpriteBank.draw_disc(ci, c + Vector2(3, 4), r, Color(0, 0, 0, 0.35))
			SpriteBank.draw_disc(ci, c, r, INK)
			SpriteBank.draw_disc(ci, c, r - 1.5, Palette.NORSE_IRON_DARK if ash else Palette.NORSE_IRON)
			SpriteBank.draw_disc(ci, c + Vector2(-r * 0.25, -r * 0.3), r * 0.45, Palette.NORSE_FIRE.darkened(0.5) if ash else Palette.NORSE_FROST)
		"norse_pillar":
			var r := o.radius
			SpriteBank.draw_disc(ci, c + Vector2(3, 4), r, Color(0, 0, 0, 0.35))
			SpriteBank.draw_disc(ci, c, r, INK)
			SpriteBank.draw_disc(ci, c, r - 1.5, Palette.NORSE_HEARTH_DARK)  # A carved wooden pillar.
			SpriteBank.draw_disc(ci, c, r * 0.5, Palette.NORSE_HEARTH)
		"norse_long_table":
			var rect := Rect2(c - o.half, o.half * 2.0)
			ci.draw_rect(Rect2(rect.position + Vector2(4, 5), rect.size), Color(0, 0, 0, 0.35))
			ci.draw_rect(rect.grow(1.0), INK)
			ci.draw_rect(rect, Palette.NORSE_HEARTH_DARK)  # A feast table.
			ci.draw_rect(rect.grow(-3.0), Palette.NORSE_HEARTH.darkened(0.3))
		_:
			return false
	return true
