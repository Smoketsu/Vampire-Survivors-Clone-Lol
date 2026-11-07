## CityLamps — the slow red pulse of the rooftop antenna lamps of the Last Line
## (Act VIII; GDD §15.0 "City blocks" and "Act VIII foundation integration").
## The art pass draws the antenna decal (decals/city_antenna) with its lamp
## unlit and leaves the pulse to code. Buildings are drawn only on Arena's
## redraws, so this small node, a child of Game.city (CityRules), redraws every
## frame and draws one soft red glow texture over each antenna lamp in view, at
## CityRulesData.ANTENNA_PULSE_HZ (a slow soft fade, never a strobe: the owner's
## photosensitivity rule for the police lights applies to every city light).
## Positions come from CityGlyphs.antenna_lamps(), the same hash the roof
## drawing uses. Purely visual: never created headless, never touches gameplay
## state (co-op reads the lots without filling the cache, as Arena does).
class_name CityLamps
extends Node2D

## Owning run.
var game: Game
## Scratch list of the lamps in view this frame (world px).
var _lamps: PackedVector2Array = PackedVector2Array()


## Builds the lamps for `p_game` (CityRules adds it as its child when it draws).
func _init(p_game: Game) -> void:
	game = p_game
	name = "CityLamps"
	z_index = -4  # Over the floor and the roofs, under the bodies (as CityShells).


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if game == null or game.arena == null or game.arena.city_blocks == null:
		return
	var cb := game.arena.city_blocks
	var view := get_canvas_transform().affine_inverse() * get_viewport_rect()  # The world rect on screen.
	view = view.grow(32.0)
	var coop := game.coop != null
	_lamps.clear()
	var r := cb.lot_range(view)  # [first lot, last lot].
	for iy in range(r[0].y, r[1].y + 1):
		for ix in range(r[0].x, r[1].x + 1):
			var o := cb.building_of(Vector2i(ix, iy), not coop)
			if o != null:
				CityGlyphs.antenna_lamps(o, _lamps)
	if _lamps.is_empty():
		return
	var hz := minf(CityRulesData.ANTENNA_PULSE_HZ, 1.0)  # Never faster than 1 Hz.
	var k := 0.5 + 0.5 * sin(TAU * hz * game.elapsed)  # 0..1, a soft fade.
	var glow := Color(Palette.CITY_SIREN_RED, CityRulesData.ANTENNA_GLOW_ALPHA * k)
	var core := Color(Palette.CITY_SIREN_RED.lightened(0.35), 0.25 + 0.75 * k)
	for p in _lamps:
		SpriteBank.draw_disc(self, p, CityRulesData.ANTENNA_GLOW_RADIUS, glow)
		SpriteBank.draw_disc(self, p, 1.5, core)
