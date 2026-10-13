## Glyphs — every placeholder shape in the game, drawn with CanvasItem draw_*
## calls (no external assets). Static functions take the CanvasItem that is
## currently inside its _draw() callback, so the same shape code renders the
## in-world entity AND its UI icon (HUD, level-up cards).
##
## Readability rule (GDD §16/§17): each summon class and each enemy kind is
## distinguishable by SILHOUETTE, not only colour:
##   Warrior = square body + shield + sword     Archer  = triangle + bow
##   Mage    = diamond + floating orb           Mender  = round robe + halo
##   (Crypt Warder, Profane Bishop, Death Knight, Lich, the Lich's risen
##   skeletons, Abomination, Rogue, Gargoyle and Frost Wraith are drawn by
##   SummonGlyphs.)
##   Recruit = small round + tabard + spear     Footman = big square + kite shield
##   Zealous Archer = crimson triangle + bow    Chaplain = ivory round + gold cross
##   Purifier = hexagon + torch flame           Sir Alaric = big octagon + hammer
##   Inquisitor of the End (Reckoning) = blazing 8-point sun star + eye
## The Crimson March's soldiers, structures and Marshal Vael are drawn by
## MarchGlyphs, the Sanctum of Judgment's kinds by SanctumGlyphs
## (draw_enemy() delegates unknown kinds to them).
class_name Glyphs
extends RefCounted

## Dark outline colour used behind bodies for contrast on the dark ground.
const OUTLINE := Color(0.0, 0.0, 0.0, 0.55)
## Eye-socket colour on skulls.
const EYE := Color(0.05, 0.05, 0.08)


## Returns the flash colour when `flash` is set, else `col`.
static func _c(col: Color, flash: bool) -> Color:
	return Palette.FLASH if flash else col


## Builds a regular polygon with `sides` corners around `center`.
static func regular_polygon(center: Vector2, r: float, sides: int, rot: float = 0.0) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in sides:
		pts.append(center + Vector2.from_angle(rot + TAU * float(i) / float(sides)) * r)
	return pts


## Small skull: bone circle + two eye sockets (+ green glow for undead).
static func _skull(ci: CanvasItem, c: Vector2, r: float, flash: bool, eye_col: Color = EYE) -> void:
	ci.draw_circle(c, r, _c(Palette.BONE, flash))
	ci.draw_circle(c + Vector2(-r * 0.38, -r * 0.05), r * 0.24, eye_col)
	ci.draw_circle(c + Vector2(r * 0.38, -r * 0.05), r * 0.24, eye_col)


## Draws a horizontal health bar of width `w` centred at `c`.
static func hp_bar(ci: CanvasItem, c: Vector2, w: float, frac: float, fill: Color) -> void:
	ci.draw_rect(Rect2(c.x - w * 0.5 - 1.0, c.y - 1.0, w + 2.0, 4.0), Palette.HP_BACK)
	ci.draw_rect(Rect2(c.x - w * 0.5, c.y, w * clampf(frac, 0.0, 1.0), 2.0), fill)


# --- Necromancer ------------------------------------------------------------------

## The player: hooded purple robe (triangle), bone face, green eyes, staff
## with a necrotic green orb (GDD §17 "purple/green/black/bone").
static func draw_necromancer(ci: CanvasItem, o: Vector2, r: float, flash: bool) -> void:
	if SpriteBank.draw(ci, "player/necromancer", o, flash):
		return  # Sprite art exists (assets/sprites/player/necromancer.png).
	ci.draw_circle(o + Vector2(0, r * 0.9), r * 0.9, Color(0, 0, 0, 0.35))
	var robe := PackedVector2Array([o + Vector2(0, -r * 1.25), o + Vector2(-r, r * 1.05), o + Vector2(r, r * 1.05)])
	ci.draw_colored_polygon(robe, _c(Palette.ROBE, flash))
	ci.draw_line(o + Vector2(-r * 0.5, r * 1.0), o + Vector2(0, -r * 0.2), _c(Palette.VIOLET, flash), 1.5)
	ci.draw_circle(o + Vector2(0, -r * 0.6), r * 0.52, _c(Color(0.12, 0.05, 0.18), flash))
	ci.draw_circle(o + Vector2(0, -r * 0.52), r * 0.3, _c(Palette.BONE, flash))
	ci.draw_circle(o + Vector2(-r * 0.12, -r * 0.55), r * 0.08, Palette.NECRO_GREEN)
	ci.draw_circle(o + Vector2(r * 0.12, -r * 0.55), r * 0.08, Palette.NECRO_GREEN)
	ci.draw_line(o + Vector2(r * 0.95, r * 1.05), o + Vector2(r * 1.15, -r * 1.3), _c(Color(0.45, 0.38, 0.3), flash), 2.0)
	ci.draw_circle(o + Vector2(r * 1.17, -r * 1.42), r * 0.55, Color(Palette.NECRO_GREEN, 0.25))
	ci.draw_circle(o + Vector2(r * 1.17, -r * 1.42), r * 0.3, _c(Palette.NECRO_GREEN, flash))


# --- Summons ------------------------------------------------------------------------

## Dispatches to the shape for summon class `cls`.
static func draw_summon(ci: CanvasItem, cls: String, o: Vector2, r: float, flash: bool) -> void:
	if SpriteBank.draw(ci, "summons/" + cls, o, flash):
		return  # Sprite art exists (assets/sprites/summons/<cls>.png).
	match cls:
		"warrior":
			draw_warrior(ci, o, r, flash)
		"archer":
			draw_archer(ci, o, r, flash)
		"mage":
			draw_mage(ci, o, r, flash)
		"mender":
			draw_priest(ci, o, r, flash)
		_:
			SummonGlyphs.draw_summon(ci, cls, o, r, flash)  # Every other class / evolution.


## Skeleton Warrior: square steel body, blue shield on the left, bone sword.
static func draw_warrior(ci: CanvasItem, o: Vector2, r: float, flash: bool) -> void:
	ci.draw_rect(Rect2(o + Vector2(-r * 0.75, -r * 0.45), Vector2(r * 1.5, r * 1.4)), OUTLINE)
	ci.draw_rect(Rect2(o + Vector2(-r * 0.65, -r * 0.35), Vector2(r * 1.3, r * 1.2)), _c(Palette.UNDEAD_STEEL, flash))
	_skull(ci, o + Vector2(0, -r * 0.75), r * 0.45, flash)
	ci.draw_rect(Rect2(o + Vector2(-r * 1.2, -r * 0.4), Vector2(r * 0.6, r * 1.05)), _c(Palette.COLD_BLUE, flash))
	ci.draw_line(o + Vector2(r * 0.75, r * 0.55), o + Vector2(r * 1.0, -r * 1.15), _c(Palette.BONE, flash), 2.0)
	ci.draw_line(o + Vector2(r * 0.55, r * 0.15), o + Vector2(r * 1.15, r * 0.25), _c(Palette.BONE, flash), 1.5)


## Skeletal Archer: narrow triangle body with a green-tinted bow on the right.
static func draw_archer(ci: CanvasItem, o: Vector2, r: float, flash: bool) -> void:
	var body := PackedVector2Array([o + Vector2(0, -r * 0.55), o + Vector2(-r * 0.75, r * 1.0), o + Vector2(r * 0.75, r * 1.0)])
	ci.draw_colored_polygon(body, _c(Color(0.25, 0.4, 0.33), flash))
	_skull(ci, o + Vector2(0, -r * 0.75), r * 0.42, flash, Color(0.1, 0.4, 0.15))
	ci.draw_arc(o + Vector2(r * 0.3, r * 0.1), r * 0.95, -1.25, 1.25, 10, _c(Palette.NECRO_GREEN, flash), 2.0)
	var top := o + Vector2(r * 0.3, r * 0.1) + Vector2.from_angle(-1.25) * r * 0.95
	var bottom := o + Vector2(r * 0.3, r * 0.1) + Vector2.from_angle(1.25) * r * 0.95
	ci.draw_line(top, bottom, _c(Palette.BONE, flash), 1.0)


## Undead Mage: violet diamond robe with a floating shadow orb.
static func draw_mage(ci: CanvasItem, o: Vector2, r: float, flash: bool) -> void:
	var body := PackedVector2Array([o + Vector2(0, -r * 0.6), o + Vector2(r * 0.85, r * 0.3), o + Vector2(0, r * 1.15), o + Vector2(-r * 0.85, r * 0.3)])
	ci.draw_colored_polygon(body, _c(Color(0.32, 0.16, 0.52), flash))
	_skull(ci, o + Vector2(0, -r * 0.78), r * 0.42, flash, Color(0.4, 0.15, 0.6))
	ci.draw_circle(o + Vector2(r * 1.0, -r * 0.95), r * 0.48, Color(Palette.VIOLET, 0.3))
	ci.draw_circle(o + Vector2(r * 1.0, -r * 0.95), r * 0.3, _c(Palette.VIOLET, flash))


## Grave Mender (the GDD's Undead Priest look): round teal robe, hood, green
## halo ring and staff.
static func draw_priest(ci: CanvasItem, o: Vector2, r: float, flash: bool) -> void:
	ci.draw_circle(o + Vector2(0, r * 0.3), r * 0.85, _c(Palette.PRIEST_ROBE, flash))
	ci.draw_line(o + Vector2(0, -r * 0.2), o + Vector2(0, r * 1.05), _c(Palette.NECRO_GREEN, flash), 1.5)
	_skull(ci, o + Vector2(0, -r * 0.55), r * 0.42, flash, Color(0.1, 0.45, 0.2))
	ci.draw_arc(o + Vector2(0, -r * 1.2), r * 0.5, 0.0, TAU, 16, _c(Palette.NECRO_GREEN, flash), 1.5)
	ci.draw_line(o + Vector2(-r * 0.95, r * 1.0), o + Vector2(-r * 0.95, -r * 0.8), _c(Palette.BONE, flash), 1.5)


# --- Enemies ------------------------------------------------------------------------

## Dispatches to the shape for enemy `kind`; elites get a gold ring.
static func draw_enemy(ci: CanvasItem, kind: String, o: Vector2, r: float, flash: bool, elite: bool) -> void:
	if elite:
		ci.draw_circle(o, r * 1.45, Color(Palette.GOLD, 0.12))
		ci.draw_arc(o, r * 1.4, 0.0, TAU, 24, Palette.GOLD, 2.0)
	# Sprite art, if any: soldiers in enemies/, buildings and carts in structures/.
	if SpriteBank.draw(ci, "enemies/" + kind, o, flash) or SpriteBank.draw(ci, "structures/" + kind, o, flash):
		return
	match kind:
		"recruit":
			_draw_recruit(ci, o, r, flash)
		"footman":
			_draw_footman(ci, o, r, flash)
		"archer":
			_draw_enemy_archer(ci, o, r, flash)
		"chaplain":
			_draw_chaplain(ci, o, r, flash)
		"purifier":
			_draw_purifier(ci, o, r, flash)
		"inquisitor":
			_draw_inquisitor(ci, o, r, flash)
		"templar":
			_draw_templar(ci, o, r, flash)
		_:
			if not MarchGlyphs.draw_enemy(ci, kind, o, r, flash):  # Crimson March kinds ...
				SanctumGlyphs.draw_enemy(ci, kind, o, r, flash)  # ... else the Sanctum's.


## Covenant Recruit: small crimson round body, ivory tabard, silver helm, spear.
static func _draw_recruit(ci: CanvasItem, o: Vector2, r: float, flash: bool) -> void:
	ci.draw_circle(o, r * 0.95, OUTLINE)
	ci.draw_circle(o, r * 0.85, _c(Palette.CRIMSON, flash))
	ci.draw_rect(Rect2(o + Vector2(-r * 0.28, -r * 0.45), Vector2(r * 0.56, r * 1.2)), _c(Palette.IVORY, flash))
	ci.draw_circle(o + Vector2(0, -r * 0.8), r * 0.38, _c(Palette.SILVER, flash))
	ci.draw_line(o + Vector2(r * 0.95, r * 0.9), o + Vector2(r * 0.95, -r * 1.3), _c(Palette.SILVER, flash), 1.5)


## Crimson Footman: large silver square body with a crimson kite shield.
static func _draw_footman(ci: CanvasItem, o: Vector2, r: float, flash: bool) -> void:
	ci.draw_rect(Rect2(o + Vector2(-r * 0.9, -r * 0.8), Vector2(r * 1.8, r * 1.8)), OUTLINE)
	ci.draw_rect(Rect2(o + Vector2(-r * 0.8, -r * 0.7), Vector2(r * 1.6, r * 1.6)), _c(Palette.SILVER, flash))
	ci.draw_circle(o + Vector2(0, -r * 0.95), r * 0.38, _c(Color(0.62, 0.64, 0.7), flash))
	var shield := PackedVector2Array([
		o + Vector2(-r * 1.1, -r * 0.5), o + Vector2(-r * 0.2, -r * 0.5), o + Vector2(-r * 0.2, r * 0.35),
		o + Vector2(-r * 0.65, r * 0.9), o + Vector2(-r * 1.1, r * 0.35)])
	ci.draw_colored_polygon(shield, _c(Palette.CRIMSON, flash))
	ci.draw_line(o + Vector2(-r * 0.65, -r * 0.4), o + Vector2(-r * 0.65, r * 0.6), _c(Palette.IVORY, flash), 1.5)
	ci.draw_line(o + Vector2(-r * 0.95, -r * 0.1), o + Vector2(-r * 0.35, -r * 0.1), _c(Palette.IVORY, flash), 1.5)


## Zealous Archer: crimson triangle with an ivory hood and ivory bow.
static func _draw_enemy_archer(ci: CanvasItem, o: Vector2, r: float, flash: bool) -> void:
	var body := PackedVector2Array([o + Vector2(0, -r * 0.95), o + Vector2(r * 0.85, r * 0.95), o + Vector2(-r * 0.85, r * 0.95)])
	ci.draw_colored_polygon(body, _c(Palette.CRIMSON, flash))
	ci.draw_circle(o + Vector2(0, -r * 0.55), r * 0.36, _c(Palette.IVORY, flash))
	ci.draw_arc(o + Vector2(-r * 0.3, r * 0.1), r * 0.95, PI - 1.2, PI + 1.2, 10, _c(Palette.IVORY, flash), 2.0)


## Covenant Chaplain: ivory round robe, gold cross and gold halo.
static func _draw_chaplain(ci: CanvasItem, o: Vector2, r: float, flash: bool) -> void:
	ci.draw_circle(o, r, OUTLINE)
	ci.draw_circle(o, r * 0.92, _c(Palette.IVORY, flash))
	ci.draw_rect(Rect2(o + Vector2(-r * 0.12, -r * 0.6), Vector2(r * 0.24, r * 1.2)), _c(Palette.GOLD, flash))
	ci.draw_rect(Rect2(o + Vector2(-r * 0.45, -r * 0.25), Vector2(r * 0.9, r * 0.22)), _c(Palette.GOLD, flash))
	ci.draw_arc(o + Vector2(0, -r * 1.25), r * 0.45, 0.0, TAU, 16, _c(Palette.GOLD, flash), 2.0)
	ci.draw_line(o + Vector2(-r * 0.7, -r * 0.5), o + Vector2(-r * 0.55, r * 0.75), _c(Palette.CRIMSON, flash), 2.0)
	ci.draw_line(o + Vector2(r * 0.7, -r * 0.5), o + Vector2(r * 0.55, r * 0.75), _c(Palette.CRIMSON, flash), 2.0)


## Purifier: dark crimson hexagon with an ivory mask and a burning torch.
static func _draw_purifier(ci: CanvasItem, o: Vector2, r: float, flash: bool) -> void:
	ci.draw_colored_polygon(regular_polygon(o, r * 1.05, 6, PI / 6.0), _c(Palette.DARK_CRIMSON, flash))
	ci.draw_colored_polygon(regular_polygon(o, r * 0.62, 6, PI / 6.0), _c(Palette.CRIMSON, flash))
	ci.draw_circle(o + Vector2(0, -r * 0.2), r * 0.3, _c(Palette.IVORY, flash))
	ci.draw_line(o + Vector2(r * 0.8, r * 0.6), o + Vector2(r * 0.95, -r * 0.6), _c(Color(0.45, 0.3, 0.2), flash), 2.0)
	var flame := PackedVector2Array([o + Vector2(r * 0.95, -r * 1.45), o + Vector2(r * 0.65, -r * 0.6), o + Vector2(r * 1.25, -r * 0.6)])
	ci.draw_colored_polygon(flame, _c(Palette.FLAME, flash))
	ci.draw_circle(o + Vector2(r * 0.95, -r * 0.75), r * 0.18, _c(Palette.GOLD, flash))


## Templar Knight: broad silver heater-shield body with a crimson cross,
## gold-crested great helm and a couched lance (reads "heavy charger").
static func _draw_templar(ci: CanvasItem, o: Vector2, r: float, flash: bool) -> void:
	var shield := PackedVector2Array([
		o + Vector2(-r, -r * 0.8), o + Vector2(r, -r * 0.8), o + Vector2(r, r * 0.2),
		o + Vector2(0, r * 1.1), o + Vector2(-r, r * 0.2)])
	ci.draw_colored_polygon(shield, OUTLINE)
	ci.draw_colored_polygon(PackedVector2Array([
		o + Vector2(-r * 0.88, -r * 0.7), o + Vector2(r * 0.88, -r * 0.7), o + Vector2(r * 0.88, r * 0.15),
		o + Vector2(0, r * 0.95), o + Vector2(-r * 0.88, r * 0.15)]), _c(Palette.SILVER, flash))
	ci.draw_rect(Rect2(o + Vector2(-r * 0.14, -r * 0.6), Vector2(r * 0.28, r * 1.3)), _c(Palette.CRIMSON, flash))
	ci.draw_rect(Rect2(o + Vector2(-r * 0.6, -r * 0.3), Vector2(r * 1.2, r * 0.26)), _c(Palette.CRIMSON, flash))
	ci.draw_rect(Rect2(o + Vector2(-r * 0.32, -r * 1.35), Vector2(r * 0.64, r * 0.6)), _c(Color(0.62, 0.64, 0.7), flash))
	ci.draw_line(o + Vector2(-r * 0.22, -r * 1.05), o + Vector2(r * 0.22, -r * 1.05), _c(Color.BLACK, flash), 1.5)
	ci.draw_line(o + Vector2(0, -r * 1.35), o + Vector2(0, -r * 1.7), _c(Palette.GOLD, flash), 2.5)
	ci.draw_line(o + Vector2(r * 0.6, r * 0.5), o + Vector2(r * 1.9, -r * 0.6), _c(Color(0.5, 0.38, 0.22), flash), 2.5)
	ci.draw_circle(o + Vector2(r * 1.9, -r * 0.6), r * 0.16, _c(Palette.SILVER, flash))


## Inquisitor of the End: radiant 8-point star of gold over ivory with a
## crimson eye; a wide holy halo makes the Reckoning readable at a glance.
static func _draw_inquisitor(ci: CanvasItem, o: Vector2, r: float, flash: bool) -> void:
	ci.draw_circle(o, r * 1.7, Color(Palette.GOLD, 0.15))
	var star := PackedVector2Array()
	for i in 16:
		var rr := r * (1.25 if i % 2 == 0 else 0.6)
		star.append(o + Vector2.from_angle(TAU * float(i) / 16.0 - PI / 2.0) * rr)
	ci.draw_colored_polygon(star, _c(Palette.GOLD, flash))
	ci.draw_circle(o, r * 0.62, _c(Palette.IVORY, flash))
	ci.draw_circle(o, r * 0.3, _c(Palette.CRIMSON, flash))
	ci.draw_circle(o, r * 0.12, _c(Color.BLACK, flash))
	ci.draw_arc(o, r * 1.45, 0.0, TAU, 32, _c(Palette.IVORY, flash), 1.5)


## Sir Alaric: crimson cape, big silver octagon with gold trim, gold hammer.
## pose 0 = walking, 1 = hammer raised (Hammerfall windup),
## 2 = charging / charge windup (gold aura), 3 = recovering (dimmed).
static func draw_boss(ci: CanvasItem, o: Vector2, r: float, flash: bool, pose: int) -> void:
	if pose == 2:
		ci.draw_circle(o, r * 1.5, Color(Palette.GOLD, 0.18))
	if SpriteBank.draw_pose(ci, "bosses/alaric", pose, o, flash):
		return  # Sprite art exists (bosses/alaric.png, plus its attack poses, BossPoseData); pose glow kept.
	ci.draw_circle(o + Vector2(0, r * 0.25), r * 1.05, _c(Palette.CRIMSON, flash))
	var body := regular_polygon(o, r * 0.85, 8, PI / 8.0)
	ci.draw_colored_polygon(body, _c(Palette.SILVER if pose != 3 else Color(0.6, 0.6, 0.65), flash))
	body.append(body[0])
	ci.draw_polyline(body, _c(Palette.GOLD, flash), 2.0)
	ci.draw_rect(Rect2(o + Vector2(-r * 0.12, -r * 0.5), Vector2(r * 0.24, r * 0.9)), _c(Palette.CRIMSON, flash))
	ci.draw_rect(Rect2(o + Vector2(-r * 0.4, -r * 0.2), Vector2(r * 0.8, r * 0.2)), _c(Palette.CRIMSON, flash))
	ci.draw_circle(o + Vector2(0, -r * 0.85), r * 0.36, _c(Color(0.7, 0.72, 0.78), flash))
	ci.draw_rect(Rect2(o + Vector2(-r * 0.05, -r * 1.35), Vector2(r * 0.1, r * 0.35)), _c(Palette.GOLD, flash))
	var grip: Vector2
	var head: Vector2
	if pose == 1:
		grip = o + Vector2(r * 0.3, -r * 0.4)
		head = o + Vector2(r * 0.1, -r * 1.9)
	else:
		grip = o + Vector2(r * 0.6, r * 0.6)
		head = o + Vector2(r * 1.2, -r * 0.9)
	ci.draw_line(grip, head, _c(Color(0.5, 0.38, 0.22), flash), 3.0)
	var dir := (head - grip).normalized()
	var perp := Vector2(-dir.y, dir.x)
	var hammer := PackedVector2Array([
		head + perp * r * 0.45 + dir * r * 0.25, head - perp * r * 0.45 + dir * r * 0.25,
		head - perp * r * 0.45 - dir * r * 0.2, head + perp * r * 0.45 - dir * r * 0.2])
	ci.draw_colored_polygon(hammer, _c(Palette.GOLD, flash))


# --- UI icons -----------------------------------------------------------------------

## Draws the icon for `kind` (summon class, spell, passive, "heal") inside
## `rect` with a dark rounded backdrop. Used by HUD slots and level-up cards.
static func draw_icon(ci: CanvasItem, kind: String, rect: Rect2) -> void:
	# A pixel-art badge icon (art pass) is a complete badge: no code backdrop.
	if SpriteBank.has_grid_icon(kind) and SpriteBank.draw_icon_art(ci, kind, rect):
		return
	ci.draw_rect(rect, Color(0.07, 0.05, 0.11, 0.92))
	ci.draw_rect(rect, Color(0.4, 0.28, 0.6, 0.9), false, 1.5)
	var c := rect.get_center()
	var s := minf(rect.size.x, rect.size.y) * 0.5
	# Dedicated icon art (assets/sprites/icons/<kind>.png) wins when present.
	if SpriteBank.draw_icon_art(ci, kind, rect):
		return
	# Sprite art drawn through the world glyph functions must fit the box.
	SpriteBank.icon_cap = s * 2.0 * SpriteData.ICON_FILL
	_draw_icon_body(ci, kind, c, s)
	SpriteBank.icon_cap = 0.0


## The icon artwork for draw_icon() (split out so the sprite size cap is
## always cleared afterwards).
static func _draw_icon_body(ci: CanvasItem, kind: String, c: Vector2, s: float) -> void:
	match kind:
		"warrior", "archer", "mage", "mender":
			draw_summon(ci, kind, c + Vector2(-s * 0.08, s * 0.08), s * 0.5, false)
		"shadow_bolt":
			ci.draw_line(c + Vector2(-s * 0.6, s * 0.6), c + Vector2(s * 0.1, -s * 0.1), Color(Palette.VIOLET, 0.5), s * 0.25)
			ci.draw_circle(c + Vector2(s * 0.2, -s * 0.2), s * 0.32, Palette.VIOLET)
			ci.draw_circle(c + Vector2(s * 0.2, -s * 0.2), s * 0.15, Color(0.9, 0.8, 1.0))
		"orb_shield":
			ci.draw_arc(c, s * 0.55, 0.0, TAU, 24, Color(Palette.VIOLET, 0.5), 1.5)
			ci.draw_circle(c, s * 0.18, Palette.ROBE.lightened(0.3))
			for i in 3:
				ci.draw_circle(c + Vector2.from_angle(TAU * float(i) / 3.0 - 0.5) * s * 0.55, s * 0.17, Palette.VIOLET)
		"shadow_blast":
			ci.draw_circle(c, s * 0.7, Color(Palette.VIOLET, 0.25))
			ci.draw_arc(c, s * 0.7, 0.0, TAU, 24, Palette.VIOLET, 2.0)
			ci.draw_arc(c, s * 0.42, 0.0, TAU, 20, Color(Palette.VIOLET, 0.7), 1.5)
			ci.draw_circle(c, s * 0.15, Color(0.9, 0.8, 1.0))
		"grave_dominion":
			var stone := Rect2(c + Vector2(-s * 0.35, -s * 0.25), Vector2(s * 0.7, s * 0.85))
			ci.draw_rect(stone, Palette.STONE.lightened(0.2))
			ci.draw_circle(c + Vector2(0, -s * 0.25), s * 0.35, Palette.STONE.lightened(0.2))
			ci.draw_line(c + Vector2(0, -s * 0.35), c + Vector2(0, s * 0.25), Palette.NECRO_GREEN, 2.0)
			ci.draw_line(c + Vector2(-s * 0.2, -s * 0.05), c + Vector2(s * 0.2, -s * 0.05), Palette.NECRO_GREEN, 2.0)
		"necrotic_vigor":
			ci.draw_circle(c + Vector2(-s * 0.22, -s * 0.12), s * 0.3, Palette.NECRO_GREEN)
			ci.draw_circle(c + Vector2(s * 0.22, -s * 0.12), s * 0.3, Palette.NECRO_GREEN)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-s * 0.5, 0), c + Vector2(s * 0.5, 0), c + Vector2(0, s * 0.6)]), Palette.NECRO_GREEN)
		"dark_command":
			var crown := PackedVector2Array([
				c + Vector2(-s * 0.55, s * 0.4), c + Vector2(-s * 0.55, -s * 0.3), c + Vector2(-s * 0.25, 0),
				c + Vector2(0, -s * 0.5), c + Vector2(s * 0.25, 0), c + Vector2(s * 0.55, -s * 0.3), c + Vector2(s * 0.55, s * 0.4)])
			ci.draw_colored_polygon(crown, Palette.VIOLET)
		"soul_recycling":
			ci.draw_arc(c, s * 0.5, 0.3, PI * 1.7, 16, Palette.NECRO_GREEN, 2.5)
			var tip := c + Vector2.from_angle(0.3) * s * 0.5
			ci.draw_colored_polygon(PackedVector2Array([tip + Vector2(-s * 0.2, 0), tip + Vector2(s * 0.2, 0), tip + Vector2(0, -s * 0.25)]), Palette.NECRO_GREEN)
			_skull(ci, c, s * 0.2, false)
		"stance_escort", "stance_onslaught", "stance_spearhead", "stance_bone_ring":
			StanceGlyphs.draw_icon(ci, kind, c, s)  # Army stance icons (StanceGlyphs).
		"heal":
			ci.draw_rect(Rect2(c + Vector2(-s * 0.12, -s * 0.5), Vector2(s * 0.24, s * 1.0)), Palette.NECRO_GREEN)
			ci.draw_rect(Rect2(c + Vector2(-s * 0.5, -s * 0.12), Vector2(s * 1.0, s * 0.24)), Palette.NECRO_GREEN)
		"":
			pass  # Empty slot: backdrop only.
		_:
			# Evolutions, evolution passives, synergies, fallback cards, then
			# meta-progression icons (Soul Ash, trees, Ossuary upgrades), then
			# power-ups and the Profane Pact / Oath, then the classes, summon
			# evolutions and evolution passives drawn by SummonGlyphs, then the
			# newer spells, their evolutions and passives (SpellGlyphs), then
			# the five later spells, their evolutions and passives
			# (GraveSpellGlyphs), then the Grave Step / Dread Rally abilities
			# (AbilityGlyphs).
			if not ProgressionGlyphs.draw_icon(ci, kind, c, s) and not MetaGlyphs.draw_icon(ci, kind, c, s) \
					and not PowerupGlyphs.draw_icon(ci, kind, c, s) and not SummonGlyphs.draw_icon(ci, kind, c, s) \
					and not SpellGlyphs.draw_icon(ci, kind, c, s) and not GraveSpellGlyphs.draw_icon(ci, kind, c, s) \
					and not AbilityGlyphs.draw_icon(ci, kind, c, s):
				ci.draw_circle(c, s * 0.3, Palette.BONE)
