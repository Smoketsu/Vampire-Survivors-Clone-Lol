## UltimateOverlay — the screen overlays of the new ultimates (content wave 2,
## UltimateSystem; numbers in UltimateData). Game adds it above the units only
## when the run's ultimate is not Dread Rally, and it draws while one runs:
##   * Sovereign's Decree — a pulsing violet ring under every grounded summon
##     (the taunt) and a violet veil around the untargetable necromancer,
##   * Eclipse            — the darkness: a deep blue-black veil over the view
##     (fades in and out) and a black sun with a pale lilac corona above the
##     necromancer,
##   * Grave Tide         — a soul-green mist along the view's edges.
## Drawn in world space around the camera; real look only, it reads the run
## and never changes it (no RNG, no gameplay state). Effects set to Reduced
## (Settings.reduced_effects()) keep the veils but drop the per-summon rings.
class_name UltimateOverlay
extends Node2D

## Seconds of fade at each end of an overlay (cosmetic).
const FADE: float = 0.35
## Depth of the Tide's edge mist, as a fraction (0..1) of the view's short side (cosmetic).
const MIST_WIDTH: float = 0.16
## Bands the Tide's edge mist is stepped into (a pixel-style gradient; cosmetic).
const MIST_BANDS: int = 4

## Owning run.
var game: Game


func _init(p_game: Game) -> void:
	game = p_game
	z_index = 40  # Above the units, effects and projectiles; under the HUD layer.


func _process(_delta: float) -> void:
	if game != null and game.ultimates != null and game.ultimates.active():
		queue_redraw()
	elif visible:
		queue_redraw()  # One more frame clears the last overlay.


## The visible world rect around the camera.
func _view() -> Rect2:
	var cam := game.camera
	var zoom := cam.zoom if cam != null else Vector2.ONE
	var sz := get_viewport_rect().size / zoom  # World px on screen.
	var c := cam.get_screen_center_position() if cam != null else game.player.position
	return Rect2(c - sz * 0.5, sz).grow(8.0)


## Fade factor 0..1 of an effect with `left` of `total` seconds left.
static func _fade(left: float, total: float) -> float:
	if left <= 0.0:
		return 0.0
	return clampf(minf(left / FADE, (total - left) / FADE + 0.25), 0.0, 1.0)


func _draw() -> void:
	if game == null or game.ultimates == null:
		return
	var ul := game.ultimates
	if ul.decree_left > 0.0:
		_draw_decree(_fade(ul.decree_left, UltimateData.DECREE_DURATION))
	if ul.eclipse_left > 0.0:
		_draw_eclipse(_fade(ul.eclipse_left, UltimateData.ECLIPSE_DARK_DURATION))
	if ul.tide_left > 0.0:
		_draw_tide(_fade(ul.tide_left, UltimateData.TIDE_DURATION))


## Decree: gold taunt rings under the summons, a gold veil on the necromancer.
## With the art (AoeArt, GDD §15.0 "Player AoE art"): a crown-point halo sprite
## sized to each summon and a larger one on the necromancer.
func _draw_decree(k: float) -> void:
	var gold: Color = UltimateData.ULTIMATES["sovereigns_decree"]["color"]
	var pulse := 0.6 + 0.4 * sin(game.elapsed * 6.0)  # Ring brightness.
	if AoeArt.has_ultimates():
		if not Settings.reduced_effects():
			for u in game.horde.units:
				if not u.active or u.airborne or u.state == SummonedUnit.State.DEAD:
					continue
				AoeArt.piece(self, AoeArt.halo_for((u.radius + 5.0) * 2.0), 1, 0, u.position, 0.0, 0.7 * k * pulse)
		var pl := game.player.position  # The veiled necromancer.
		SpriteBank.draw_disc(self, pl, 26.0, Color(gold, 0.12 * k))
		AoeArt.piece(self, AoeArtData.HALOS[AoeArtData.HALOS.size() - 1], 1, 0, pl, 0.0, 0.85 * k * pulse)
		return
	if not Settings.reduced_effects():
		for u in game.horde.units:
			if not u.active or u.airborne or u.state == SummonedUnit.State.DEAD:
				continue
			draw_arc(u.position, u.radius + 5.0, 0.0, TAU, 18, Color(gold, 0.55 * k * pulse), 2.0)
	var p := game.player.position
	draw_circle(p, 26.0, Color(gold, 0.16 * k))
	draw_arc(p, 26.0, 0.0, TAU, 28, Color(gold.lightened(0.3), 0.7 * k * pulse), 2.0)
	draw_arc(p, UltimateData.DECREE_TAUNT_RADIUS, 0.0, TAU, 48, Color(gold, 0.18 * k), 1.0)


## Eclipse: the darkness veil and the eclipsed disc over the necromancer.
func _draw_eclipse(k: float) -> void:
	var view := _view()
	draw_rect(view, Color(0.02, 0.02, 0.07, UltimateData.ECLIPSE_OVERLAY_ALPHA * k))
	var blue: Color = UltimateData.ULTIMATES["eclipse"]["color"]
	var c := game.player.position + Vector2(0.0, -70.0)  # The black sun above him.
	if AoeArt.has_ultimates():
		AoeArt.piece(self, AoeArtData.BLACK_SUN, 1, 0, c, 0.0, k)  # Pixel-art black sun (AoeArt).
		return
	draw_circle(c, 20.0, Color(blue.lightened(0.5), 0.35 * k))
	draw_circle(c, 17.0, Color(0.01, 0.01, 0.03, 0.95 * k))
	draw_arc(c, 21.0, 0.0, TAU, 32, Color(blue.lightened(0.6), 0.8 * k), 2.0)


## Grave Tide: soul-green mist stepped along the view's edges.
func _draw_tide(k: float) -> void:
	var view := _view()
	var green: Color = UltimateData.ULTIMATES["grave_tide"]["color"]
	if AoeArt.has_ultimates():
		AoeArt.tide_edges(self, view, AoeArtData.TIDE_ALPHA * k, game.elapsed)  # Pixel-art edge mist (AoeArt).
		return
	var w := minf(view.size.x, view.size.y) * MIST_WIDTH  # Mist depth (px).
	var band := w / float(MIST_BANDS)  # One step (px).
	for i in MIST_BANDS:
		var a := UltimateData.TIDE_OVERLAY_ALPHA * k * (1.0 - float(i) / float(MIST_BANDS))  # Outer bands are thicker.
		var col := Color(green, a * 0.5)
		var o := band * float(i)  # Inset of this band (px).
		draw_rect(Rect2(view.position + Vector2(o, o), Vector2(view.size.x - 2.0 * o, band)), col)
		draw_rect(Rect2(Vector2(view.position.x + o, view.end.y - o - band), Vector2(view.size.x - 2.0 * o, band)), col)
		draw_rect(Rect2(view.position + Vector2(o, o + band), Vector2(band, view.size.y - 2.0 * o - 2.0 * band)), col)
		draw_rect(Rect2(Vector2(view.end.x - o - band, view.position.y + o + band), Vector2(band, view.size.y - 2.0 * o - 2.0 * band)), col)
