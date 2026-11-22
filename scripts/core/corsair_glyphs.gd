## CorsairGlyphs — code-drawn fallback shapes for THE BLACK TIDE (Act X; GDD
## §15.0 "Act X foundation: the Black Tide (phase 1)"), drawn when a kind has
## no sprite art (assets/sprites/corsair/<kind>.png, the parallel art pass's):
## tarred oak, sailcloth cream, brass, powder-smoke grey and sash red with a
## navy-black outline; the sea's beasts in powder grey (the shark) and kraken
## purple. Also the Act X stubs' placeholder deck furniture (masts, hatches,
## barrels, cannons, the Hollow Queen's wheel) until each stage brings its own
## obstacle art. Shapes are discs (SpriteBank's texture) and rects: no
## polygon is redrawn every frame (the Web GL rule in CLAUDE.md). Every Black
## Tide kind without a shape of its own gets the deckhand. The Smuggler's
## Cutter's block draws its powder barrel with the deck furniture's barrel art
## and Crow's sloop with the raider ship's; the deck_ furniture kinds (the art
## pass's obstacles) fall back to the stub shapes here. Purely visual.
class_name CorsairGlyphs
extends RefCounted

## Outline ink of the act (navy-black).
const INK := Palette.CORSAIR_INK


# =====================================================================================
# Kinds
# =====================================================================================

## Draws Black Tide kind `kind`. Returns false when `kind` is not a Black Tide
## kind (Glyphs.draw_enemy() then asks the next faction's glyphs).
static func draw_enemy(ci: CanvasItem, kind: String, o: Vector2, r: float, flash: bool) -> bool:
	if EnemyDirector.corsair_def(kind).is_empty():
		return false
	# Phase 2: each Act X stage's own fallbacks go here, before the shared kinds'.
	# --- Act X: the Smuggler's Cutter ---
	match kind:
		"powder_barrel":
			if SpriteBank.draw(ci, CutterEnemyData.BARREL_SPRITE, o, flash):
				return true  # The deck furniture's barrel art.
			SpriteBank.draw_disc(ci, o, r, Glyphs._c(INK, flash))
			SpriteBank.draw_disc(ci, o, r - 1.5, Glyphs._c(Palette.CORSAIR_OAK_DARK, flash))
			ci.draw_rect(Rect2(o + Vector2(-r + 2.0, -1.0), Vector2((r - 2.0) * 2.0, 2.0)), Palette.CORSAIR_POWDER_LIGHT)  # An iron hoop.
			return true
		"crow_sloop":
			if SpriteBank.draw(ci, CutterEnemyData.SLOOP_SPRITE, o, flash):
				return true  # The raider ship's art (Crow's sloop has none of its own).
			_boat(ci, o, r, flash, true)
			return true
		"bosun_gorran":
			_crewman(ci, o, r, flash, Palette.CORSAIR_SEA_DARK, false)
			return true
	# --- Act X: the Treasure Galleon --- (its kinds all have art; these are the fallbacks)
		"gunnery_mate", "voodoo_navigator":
			_swashbuckler(ci, o, r, flash)
			return true
		"gunboat":
			_boat(ci, o, r, flash, true)
			return true
		"hull_crab":
			SpriteBank.draw_disc(ci, o, r, Glyphs._c(INK, flash))
			SpriteBank.draw_disc(ci, o, r * 0.85, Glyphs._c(Palette.CORSAIR_SASH, flash))  # The shell.
			SpriteBank.draw_disc(ci, o + Vector2(-r * 0.9, -r * 0.6), r * 0.35, Glyphs._c(Palette.CORSAIR_SASH_LIGHT, flash))  # Claws.
			SpriteBank.draw_disc(ci, o + Vector2(r * 0.9, -r * 0.6), r * 0.35, Glyphs._c(Palette.CORSAIR_SASH_LIGHT, flash))
			return true
		"old_hollow_eye":
			_kraken_arm(ci, o, r, flash)
			SpriteBank.draw_disc(ci, o + Vector2(0.0, -r * 0.2), r * 0.22, Palette.CORSAIR_FOAM_LIGHT)  # The hollow eye.
			return true
	match kind:
		"musketeer":
			_crewman(ci, o, r, flash, Palette.CORSAIR_SEA, true)
		"powder_runner":
			_crewman(ci, o, r, flash, Palette.CORSAIR_SAIL_SHADE, false)
			SpriteBank.draw_disc(ci, o + Vector2(r * 0.7, -r * 0.1), r * 0.55, Glyphs._c(Palette.CORSAIR_OAK_DARK, flash))  # The keg.
			ci.draw_rect(Rect2(o + Vector2(r * 0.65, -r * 0.75), Vector2(2, 2)), Palette.CORSAIR_LANTERN_LIGHT)  # Its fuse.
		"swashbuckler":
			_swashbuckler(ci, o, r, flash)
		"boarding_bruiser":
			_crewman(ci, o, r, flash, Palette.CORSAIR_SASH_DARK, false)
			ci.draw_rect(Rect2(o + Vector2(r * 0.8, -r * 1.1), Vector2(3, r * 1.6)), Glyphs._c(Palette.CORSAIR_OAK_LIGHT, flash))  # The axe haft.
			ci.draw_rect(Rect2(o + Vector2(r * 0.6, -r * 1.2), Vector2(r * 0.6, r * 0.45)), Glyphs._c(Palette.CORSAIR_POWDER_LIGHT, flash))  # Its head.
		"reef_shark":
			_shark(ci, o, r, flash)
		"kraken_arm":
			_kraken_arm(ci, o, r, flash)
		"skiff", "longboat", "raider_ship":
			_boat(ci, o, r, flash, kind == "raider_ship")
		"boarding_hook":
			if SpriteBank.draw(ci, "corsair/grapple_hook", o, flash):
				return true  # The art pass names the hook's sprite grapple_hook (wired at the wave 1 integration).
			SpriteBank.draw_disc(ci, o, r, Glyphs._c(INK, flash))
			SpriteBank.draw_disc(ci, o, r * 0.75, Glyphs._c(Palette.CORSAIR_POWDER_LIGHT, flash))  # Iron.
			ci.draw_rect(Rect2(o + Vector2(-r * 0.15, -r * 0.9), Vector2(r * 0.3, r * 0.9)), Glyphs._c(Palette.CORSAIR_POWDER_DARK, flash))
		_:
			_crewman(ci, o, r, flash, Palette.CORSAIR_SASH, false)
	return true


## A pirate crewman: a sash-coloured shirt over sailcloth, a bandana, a cutlass
## (or a musket when `musket`).
static func _crewman(ci: CanvasItem, o: Vector2, r: float, flash: bool, coat: Color, musket: bool) -> void:
	var body := Rect2(o + Vector2(-r * 0.5, -r * 0.6), Vector2(r * 1.0, r * 1.5))
	ci.draw_rect(body.grow(1.0), INK)
	ci.draw_rect(body, Glyphs._c(Palette.CORSAIR_SAIL, flash))  # Shirt.
	ci.draw_rect(Rect2(body.position + Vector2(0.0, r * 0.55), Vector2(body.size.x, r * 0.3)), Glyphs._c(coat, flash))  # Sash.
	SpriteBank.draw_disc(ci, o + Vector2(0.0, -r * 0.9), r * 0.45, Glyphs._c(INK, flash))
	SpriteBank.draw_disc(ci, o + Vector2(0.0, -r * 0.9), r * 0.38, Glyphs._c(Palette.CORSAIR_TAN, flash))  # Head.
	ci.draw_rect(Rect2(o + Vector2(-r * 0.4, -r * 1.25), Vector2(r * 0.8, r * 0.25)), Glyphs._c(Palette.CORSAIR_SASH, flash))  # Bandana.
	if musket:
		ci.draw_rect(Rect2(o + Vector2(r * 0.5, -r * 0.2), Vector2(r * 1.2, 2.0)), Glyphs._c(Palette.CORSAIR_OAK_DARK, flash))
	else:
		ci.draw_line(o + Vector2(r * 0.6, r * 0.4), o + Vector2(r * 1.2, -r * 0.6), Glyphs._c(Palette.CORSAIR_POWDER_LIGHT, flash), 1.5)  # Cutlass.


## The Swashbuckler: a figure-style duellist in a long sash-red coat, a brass
## hilted rapier, a plumed hat.
static func _swashbuckler(ci: CanvasItem, o: Vector2, r: float, flash: bool) -> void:
	var coat := Rect2(o + Vector2(-r * 0.55, -r * 0.6), Vector2(r * 1.1, r * 1.6))
	ci.draw_rect(coat.grow(1.0), INK)
	ci.draw_rect(coat, Glyphs._c(Palette.CORSAIR_SASH, flash))
	ci.draw_rect(Rect2(o + Vector2(-r * 0.3, -r * 0.55), Vector2(r * 0.6, r * 0.5)), Glyphs._c(Palette.CORSAIR_SAIL_LIGHT, flash))  # Blouse.
	SpriteBank.draw_disc(ci, o + Vector2(0.0, -r * 0.95), r * 0.38, Glyphs._c(Palette.CORSAIR_TAN_LIGHT, flash))
	ci.draw_rect(Rect2(o + Vector2(-r * 0.6, -r * 1.35), Vector2(r * 1.2, r * 0.22)), Glyphs._c(Palette.CORSAIR_OAK_DARK, flash))  # Hat brim.
	ci.draw_rect(Rect2(o + Vector2(r * 0.2, -r * 1.6), Vector2(r * 0.25, r * 0.3)), Glyphs._c(Palette.CORSAIR_FOAM, flash))  # Plume.
	ci.draw_line(o + Vector2(r * 0.5, r * 0.1), o + Vector2(r * 1.6, -r * 0.5), Glyphs._c(Palette.CORSAIR_POWDER_LIGHT, flash), 1.0)  # Rapier.
	SpriteBank.draw_disc(ci, o + Vector2(r * 0.5, r * 0.1), 1.8, Palette.CORSAIR_BRASS)  # Its hilt.


## The Reef Shark: a grey torpedo body, a pale belly, a dorsal fin.
static func _shark(ci: CanvasItem, o: Vector2, r: float, flash: bool) -> void:
	var body := Rect2(o + Vector2(-r * 1.1, -r * 0.45), Vector2(r * 2.2, r * 0.9))
	ci.draw_rect(body.grow(1.0), INK)
	ci.draw_rect(body, Glyphs._c(Palette.CORSAIR_POWDER, flash))
	ci.draw_rect(Rect2(body.position + Vector2(0.0, r * 0.5), Vector2(body.size.x, r * 0.35)), Glyphs._c(Palette.CORSAIR_FOAM_SHADE, flash))  # Belly.
	ci.draw_rect(Rect2(o + Vector2(-r * 0.15, -r * 0.95), Vector2(r * 0.35, r * 0.5)), Glyphs._c(Palette.CORSAIR_POWDER_DARK, flash))  # Fin.
	ci.draw_rect(Rect2(o + Vector2(r * 0.75, -r * 0.2), Vector2(2, 2)), INK)  # Eye.


## The Kraken Arm: a purple tentacle rising from the water, pale suckers.
static func _kraken_arm(ci: CanvasItem, o: Vector2, r: float, flash: bool) -> void:
	SpriteBank.draw_disc(ci, o + Vector2(0.0, r * 0.4), r * 0.95, Glyphs._c(INK, flash))
	SpriteBank.draw_disc(ci, o + Vector2(0.0, r * 0.4), r * 0.85, Glyphs._c(Palette.CORSAIR_KRAKEN_DARK, flash))
	SpriteBank.draw_disc(ci, o + Vector2(r * 0.1, -r * 0.1), r * 0.65, Glyphs._c(Palette.CORSAIR_KRAKEN, flash))
	SpriteBank.draw_disc(ci, o + Vector2(r * 0.2, -r * 0.6), r * 0.4, Glyphs._c(Palette.CORSAIR_KRAKEN, flash))
	for k in 3:
		SpriteBank.draw_disc(ci, o + Vector2(-r * 0.15, r * 0.3 - float(k) * r * 0.35), r * 0.12, Palette.CORSAIR_KRAKEN_LIGHT)  # Suckers.


## A boat seen from above: a tarred hull, oars or a mast, a sailcloth thwart.
static func _boat(ci: CanvasItem, o: Vector2, r: float, flash: bool, ship: bool) -> void:
	var hull := Rect2(o + Vector2(-r * 1.2, -r * 0.55), Vector2(r * 2.4, r * 1.1))
	ci.draw_rect(hull.grow(1.5), INK)
	ci.draw_rect(hull, Glyphs._c(Palette.CORSAIR_OAK, flash))
	ci.draw_rect(hull.grow(-3.0), Glyphs._c(Palette.CORSAIR_OAK_DARK, flash))
	ci.draw_rect(Rect2(o + Vector2(-r * 0.1, -r * 0.5), Vector2(r * 0.2, r * 1.0)), Glyphs._c(Palette.CORSAIR_SAIL_SHADE, flash))  # A thwart.
	if ship:
		SpriteBank.draw_disc(ci, o, r * 0.25, Glyphs._c(Palette.CORSAIR_OAK_LIGHT, flash))  # The mast.
		ci.draw_rect(Rect2(o + Vector2(-r * 0.7, -r * 0.08), Vector2(r * 1.4, r * 0.16)), Glyphs._c(Palette.CORSAIR_SAIL, flash))  # The furled sail.
	ci.draw_rect(Rect2(o + Vector2(r * 1.05, -2.0), Vector2(r * 0.3, 4.0)), Glyphs._c(Palette.CORSAIR_BRASS_DARK, flash))  # The bow's brass.


# =====================================================================================
# The deck's furniture (placeholder obstacles of the Act X stubs)
# =====================================================================================

## Draws an Act X stub's furniture obstacle `o`. False when it is not one.
static func draw_obstacle(ci: CanvasItem, o: Arena.Obstacle) -> bool:
	var c := o.center
	var kind := o.kind
	if not (kind.begins_with("cutter_") or kind.begins_with("galleon_") or kind.begins_with("maelstrom_") or kind.begins_with("deck_")):
		return false
	if kind == "galleon_steps":
		_steps(ci, o)  # Act X, the Treasure Galleon: the quarterdeck stair.
		return true
	var ghost := kind.begins_with("maelstrom_")  # The Hollow Queen: rotten, green-washed.
	var wood := Palette.CORSAIR_OAK_LIGHT if not ghost else Palette.CORSAIR_SPECTRE_DARK
	var dark := Palette.CORSAIR_OAK_DARK
	if kind.ends_with("_mast") or kind.ends_with("_wheel") or kind.ends_with("_barrel") or kind.ends_with("_barrels"):
		var r := o.radius
		SpriteBank.draw_disc(ci, c + Vector2(3, 4), r, Color(0, 0, 0, 0.35))
		SpriteBank.draw_disc(ci, c, r, INK)
		SpriteBank.draw_disc(ci, c, r - 1.5, dark if kind.ends_with("_barrel") or kind.ends_with("_barrels") else wood)
		if kind.ends_with("_barrel") or kind.ends_with("_barrels"):
			ci.draw_rect(Rect2(c + Vector2(-r + 2.0, -1.0), Vector2((r - 2.0) * 2.0, 2.0)), Palette.CORSAIR_POWDER_LIGHT)  # An iron hoop.
			SpriteBank.draw_disc(ci, c, r * 0.3, Palette.CORSAIR_LANTERN_DARK)  # Powder marks.
		elif kind.ends_with("_wheel"):
			for k in 4:
				var a := TAU * float(k) / 8.0
				ci.draw_line(c - Vector2.from_angle(a) * r, c + Vector2.from_angle(a) * r, Palette.CORSAIR_BRASS_DARK, 1.5)  # Spokes.
		else:
			SpriteBank.draw_disc(ci, c + Vector2(-r * 0.3, -r * 0.3), r * 0.35, Palette.CORSAIR_OAK_LIGHT)  # The mast's top.
		return true
	var rect := Rect2(c - o.half, o.half * 2.0)
	ci.draw_rect(Rect2(rect.position + Vector2(3, 4), rect.size), Color(0, 0, 0, 0.35))
	ci.draw_rect(rect, INK)
	if kind.ends_with("_cannon"):
		ci.draw_rect(rect.grow(-1.5), Palette.CORSAIR_POWDER_DARK)
		ci.draw_rect(Rect2(rect.position + Vector2(2.0, rect.size.y * 0.3), Vector2(rect.size.x - 4.0, rect.size.y * 0.4)), Palette.CORSAIR_POWDER)
	else:
		ci.draw_rect(rect.grow(-1.5), dark)  # A hatch: a grating.
		var x := rect.position.x + 4.0
		while x < rect.end.x - 2.0:
			ci.draw_line(Vector2(x, rect.position.y + 2.0), Vector2(x, rect.end.y - 2.0), wood, 1.0)
			x += 5.0
	return true


# --- Act X: the Treasure Galleon ---
## The quarterdeck stair (obstacle "galleon_steps", the Galleon's fixed
## layout; no sprite: code-drawn): oak treads rising toward the stern with a
## rope rail along each side.
static func _steps(ci: CanvasItem, o: Arena.Obstacle) -> void:
	var rect := Rect2(o.center - o.half, o.half * 2.0)
	ci.draw_rect(Rect2(rect.position + Vector2(3, 4), rect.size), Color(0, 0, 0, 0.35))
	ci.draw_rect(rect, INK)
	ci.draw_rect(rect.grow(-1.5), Palette.CORSAIR_OAK)
	var vertical := o.half.y > o.half.x
	var n := 7
	for i in n:
		var k := (float(i) + 0.5) / float(n)
		if vertical:
			var y := rect.position.y + rect.size.y * k
			ci.draw_line(Vector2(rect.position.x + 2.0, y), Vector2(rect.end.x - 2.0, y), Palette.CORSAIR_OAK_LIGHT, 2.0)
		else:
			var x := rect.position.x + rect.size.x * k
			ci.draw_line(Vector2(x, rect.position.y + 2.0), Vector2(x, rect.end.y - 2.0), Palette.CORSAIR_OAK_LIGHT, 2.0)
	ci.draw_rect(rect, Palette.CORSAIR_SAIL_SHADE, false, 1.0)  # The rope rails.
