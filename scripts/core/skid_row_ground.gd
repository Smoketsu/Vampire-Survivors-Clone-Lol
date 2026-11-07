## SkidRowGround — the floor of Skid Row (Act VIII, Stage 22; GDD §15.0 "Skid
## Row (Act VIII phase 2)"): the shared CityGround (the alleys, streets,
## crossings, crosswalks, sidewalks and open lots drawn from the arena's
## CityBlocks, the same geometry the bodies walk) with the stage's four zone
## LOOKS (SkidRowStage.ZONES "ground"; MarchDirector calls set_zone() at each
## zone change, and a zone never moves a street):
##   * "docks" (the Alleys): the foundation's manholes and oil stains;
##   * "market" (the Night Market): neon spill along the streets, and the open
##     lots of style "market" filled with rows of lit market stalls
##     (decals/skid_row_stall, a stall's neon awning seen from above, tinted
##     pink or cyan by a hash; code boxes when the PNG is missing) over the
##     plaza paving, each with a soft glow;
##   * "overpass" (the Overpass): the elevated road's shadow over every other
##     horizontal street (a dark band) with the girders' shadows across it and
##     the pillars' flat concrete footings on the sidewalks
##     (decals/skid_row_footing; code squares when missing);
##   * "precinct" (the Precinct): blue kerb paint and hatched no-parking bays
##     beside the crossings.
## The precinct's roofs are the buildings' (CityGlyphs.draw_building(): roof
## style "precinct", tiles/city_roof_precinct, made by
## art_source/skid_row/skid_row_tiles.py). Purely cosmetic: nothing here
## collides, and nothing drawn here looks solid (flat paint, shadows and
## footings only: the ART_BIBLE floor rule). Drawn only on the ground's redraws
## (textures and rects; no polygon redrawn every frame).
class_name SkidRowGround
extends CityGround

## Decal key of a market stall seen from above (its awning; grey, tinted).
const STALL_DECAL: String = "decals/skid_row_stall"
## Decal key of an overpass pillar's flat footing.
const FOOTING_DECAL: String = "decals/skid_row_footing"
## px between two stalls of a market row (along x) and between two rows (y).
const STALL_STEP := Vector2(56.0, 52.0)  # TUNING (not in GDD)
## px between two of the deck's girder shadows along a street.
const GIRDER_STEP: float = 128.0  # TUNING (not in GDD)
## Half the width (px) of the overpass deck's shadow band over its street.
const DECK_HALF: float = 60.0  # TUNING (not in GDD) (the roadway is 144 px)


func _ready() -> void:
	super._ready()
	var zones: Array = game.stage_def.get("zones", []) if game != null else []
	look = (zones[0] as Dictionary).get("ground", {}) if not zones.is_empty() else game.stage_def.get("floor", {})


## Switches to zone look `look` and redraws at once.
func set_zone(p_look: Dictionary) -> void:
	look = p_look
	queue_redraw()


func _draw() -> void:
	super._draw()
	if String(look.get("style", "docks")) != "overpass":
		return
	var cb := game.arena.city_blocks if game != null and game.arena != null else null  # The geometry.
	if cb == null:
		return
	var center := Vector2(_center_cell) * REDRAW_CELL + Vector2.ONE * REDRAW_CELL * 0.5
	var rect := Rect2(center - Vector2.ONE * HALF_EXTENT, Vector2.ONE * HALF_EXTENT * 2.0)
	_draw_overpass(cb, rect)


## The overpass: the deck's shadow over every other horizontal street, the
## girders' shadows across it, the pillars' footings on its sidewalks.
func _draw_overpass(cb: CityBlocks, rect: Rect2) -> void:
	var foot := EnvironmentArt.texture(FOOTING_DECAL)  # Flat footing PNG, or null.
	var hk0 := floori(rect.position.y / (2.0 * cb.pitch.y)) - 1
	var hk1 := ceili(rect.end.y / (2.0 * cb.pitch.y)) + 1
	var x0 := _snap(rect.position.x)
	var w := rect.size.x + 128.0
	for k in range(hk0, hk1 + 1):
		if posmod(k, 2) != 0:
			continue  # Every other street runs under the overpass.
		var y := cb.h_street_y(k)
		draw_rect(Rect2(Vector2(x0, y - DECK_HALF), Vector2(w, DECK_HALF * 2.0)), Color(0.0, 0.0, 0.0, 0.26))  # The deck's shadow.
		var x := floorf(x0 / GIRDER_STEP) * GIRDER_STEP
		while x < x0 + w:
			draw_rect(Rect2(Vector2(x, y - DECK_HALF), Vector2(10.0, DECK_HALF * 2.0)), Color(0.0, 0.0, 0.0, 0.18))  # A girder's shadow.
			for sgn: float in [-1.0, 1.0]:
				var at := Vector2(x + 5.0, y + sgn * (cb.street * 0.5 - cb.sidewalk * 0.5))  # On the sidewalk.
				if foot != null:
					draw_texture(foot, (at - foot.get_size() * 0.5).round())
				else:
					draw_rect(Rect2(at - Vector2(8.0, 8.0), Vector2(16.0, 16.0)), Palette.CITY_CONCRETE_LIGHT)
					draw_rect(Rect2(at - Vector2(5.0, 5.0), Vector2(10.0, 10.0)), Palette.CITY_CONCRETE)
			x += GIRDER_STEP * 2.0


## An open lot: the market's stalls, else the shared looks.
func _open_lot(b: Rect2, style: String, h: int) -> void:
	if style != "market":
		super._open_lot(b, style, h)
		return
	super._open_lot(b, "plaza", h)  # The paving under the stalls.
	var tex := EnvironmentArt.texture(STALL_DECAL)  # Stall PNG (grey awning, tinted), or null.
	var pink: Color = look.get("accent", Palette.CITY_NEON_PINK)
	var cyan: Color = look.get("accent2", Palette.CITY_NEON_CYAN)
	var y := b.position.y + 30.0
	var row := 0
	while y < b.end.y - 20.0:
		var x := b.position.x + 28.0 + (14.0 if row % 2 == 1 else 0.0)
		while x < b.end.x - 24.0:
			var hk := absi(hash(Vector3i(int(x), int(y), h)))
			if hk % 5 != 0:  # A gap now and then (an empty pitch).
				var col := pink if hk % 2 == 0 else cyan
				var at := Vector2(x, y)
				draw_texture_rect(SpriteBank.disc(), Rect2(at - Vector2(26.0, 20.0), Vector2(52.0, 40.0)), false, Color(col, 0.16))  # The stall's lamp glow.
				if tex != null:
					draw_texture(tex, (at - tex.get_size() * 0.5).round(), col.lerp(Color.WHITE, 0.35))
				else:
					draw_rect(Rect2(at - Vector2(17.0, 12.0), Vector2(34.0, 24.0)), Palette.CITY_INK)
					draw_rect(Rect2(at - Vector2(16.0, 11.0), Vector2(32.0, 22.0)), col.darkened(0.25))
					draw_rect(Rect2(at - Vector2(16.0, 11.0), Vector2(32.0, 4.0)), col)
			x += STALL_STEP.x
		y += STALL_STEP.y
		row += 1


## A zone accent near street point `p` (street indices `i`, `k`): the market's
## neon spill, the precinct's paint, else the shared accents.
func _accent(p: Vector2, i: int, k: int) -> void:
	match String(look.get("style", "docks")):
		"market":
			var h := absi(hash(Vector3i(i, k, 2207)))
			var col: Color = look.get("accent" if h % 2 == 0 else "accent2", Palette.CITY_NEON_PINK)
			draw_texture_rect(SpriteBank.disc(), Rect2(p + Vector2(-60.0, -70.0), Vector2(120.0, 36.0)), false, Color(col, 0.12))  # Neon spill off a sign.
			draw_texture_rect(SpriteBank.disc(), Rect2(p + Vector2(-20.0, 30.0), Vector2(90.0, 28.0)), false, Color(col, 0.08))
		"precinct":
			var blue: Color = look.get("accent", Palette.CITY_POLICE_BLUE)
			draw_rect(Rect2(p + Vector2(-40.0, -72.0), Vector2(80.0, 3.0)), Color(blue, 0.7))  # Blue kerb paint.
			for s in 5:
				draw_rect(Rect2(p + Vector2(-36.0 + float(s) * 16.0, 50.0), Vector2(6.0, 18.0)), Color(Palette.CITY_HAZARD, 0.35))  # A hatched no-parking bay.
		"overpass":
			pass  # The deck's shadow is drawn over the streets (_draw_overpass()).
		_:
			super._accent(p, i, k)
