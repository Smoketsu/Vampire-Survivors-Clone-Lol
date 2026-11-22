## Sandstorm — THE SANDSTORM, the Black Land's clock (temporary Act XII, the
## Necropolis Dynasty; GDD §15.0 "The Black Land"; owner-approved proposal:
## "every 5:00, a Sandstorm blows for 40 s (shown 10 s ahead on the HUD).
## During it ranged weapons have half range for both armies (arrows, spells
## aimed by range, volleys) and enemies are partially hidden beyond 300 px.
## Melee armies prosper, and the Nile Archers fall silent. One clock path:
## Sandstorm, like Act VII's BloodMoon"), owned by Game.dynasty. THE one clock:
##   * on a Dynasty stage (STAGE "dynasty"), from `first` s, every `every` s
##     the storm blows for `duration` s (DynastyRulesData.SANDSTORM; a stage's
##     STAGE "sandstorm" overrides any key); `warn` s before each rise the
##     HUD's storm line counts down and a banner warns;
##   * is_up() is THE test, and reach_mult() THE multiplier every reader asks:
##     the enemies' ranged attack range (DynastyKit), and through
##     DynastyRules.army_reach_mult() the ranged summons' attack range
##     (HordeDirector.compute_stats()), the spells' "range"
##     (AbilityManager._apply_spell_buffs()) and the volleys' flight
##     (VolleyDirector). When it rises or falls DynastyRules.on_storm_changed()
##     recomputes every army's and every player's stats once;
##   * force(duration) raises it now for at least `duration` s (phase 2:
##     Sekhmet's Red Wind; no banner: the boss shows its own), and
##     start_endless() keeps it up for good (the Devourer's Hour at 0:00).
## Drawn (visual only, a flat rect overlay, never a screen-reading shader): a
## sand wash over the view and a VEIL around the necromancer the camera
## follows, clear within hide_radius px and thickening past it (one radial
## gradient texture made once), fading in and out over `fade` s; and the
## HUD's storm line. Nothing drawn headless.
## Determinism: game time only. Stats: sandstorms, sandstorms_forced,
## sandstorm_time, sandstorm_warnings.
class_name Sandstorm
extends Node2D

## Radius (world px) of the veil texture: past the view's corners, so its
## outer, opaque edge always covers the screen's.
const VEIL_RADIUS: float = 1400.0  # TUNING (not in GDD) drawing only
## Side (px) of the veil texture (stretched to 2 x VEIL_RADIUS).
const VEIL_TEX: int = 256  # TUNING (not in GDD) drawing only

## Owning run.
var game: Game
## True on a Dynasty stage: the clock runs (force() works anywhere).
var enabled: bool = false
## The storm's numbers (SANDSTORM with the STAGE's "sandstorm").
var cfg: Dictionary = {}
## Game time (s) of the next clock rise (INF once the Devourer's Hour holds it).
var next_rise: float = INF
## Game time (s) until which the storm blows (clock or forced).
var up_until: float = -INF
## True once the Devourer's Hour raised it for good.
var endless: bool = false
## Storms risen this run (clock, forced and the endless one).
var storms: int = 0
## Storms a boss forced this run.
var forced: int = 0
## Game time (s) each storm rose, "m:ss" (the autotest line).
var rise_times: PackedStringArray = PackedStringArray()
## True while the storm blew at the last step.
var _was_up: bool = false
## True once the coming rise was warned.
var _warned: bool = false
## True when the next rise comes quietly (a forced storm: no banner).
var _quiet: bool = false
## Strength (0..1) of the drawn storm now (follows is_up() over `fade` s).
var _tint: float = 0.0
## True when this build draws (never headless).
var _draws: bool = false
## The veil's radial texture (made on first draw).
var _veil: ImageTexture = null
## The HUD's storm line (null until the HUD exists; never headless).
var _label: Label = null


## Builds the storm for `p_game` (DynastyRules adds it as its child);
## `p_enabled`: a Dynasty stage (the clock runs).
func _init(p_game: Game, p_enabled: bool) -> void:
	game = p_game
	name = "Sandstorm"
	z_index = 18  # Over the bodies, the shots and the glyphs; under the HUD.
	z_as_relative = false
	enabled = p_enabled
	cfg = DynastyRulesData.SANDSTORM.duplicate()
	var over: Dictionary = p_game.stage_def.get("sandstorm", {})  # The stage's own overrides.
	for key: String in over:
		cfg[key] = over[key]
	if enabled:
		next_rise = float(cfg["first"])
	_draws = DisplayServer.get_name() != "headless"


# =====================================================================================
# The clock (public API)
# =====================================================================================

## THE test: true while the storm blows (clock, forced or endless).
func is_up() -> bool:
	return endless or game.elapsed < up_until


## Seconds until the next clock rise (-1 when none is coming).
func time_to_rise() -> float:
	if is_up() or next_rise == INF:
		return -1.0
	return maxf(0.0, next_rise - game.elapsed)


## THE multiplier: x every ranged reach now (reach_mult while it blows, else 1).
func reach_mult() -> float:
	return float(cfg["reach_mult"]) if is_up() else 1.0


## Raises the storm now for at least `duration` s (a boss's Red Wind; works on
## any stage the rules exist). No banner: the boss shows its own.
func force(duration: float) -> void:
	if not is_up():
		_quiet = true
		forced += 1
		game.stat_add("sandstorms_forced", 1.0)
	up_until = maxf(up_until, game.elapsed + duration)


## The Devourer's Hour (0:00): the storm rises and never falls.
func start_endless() -> void:
	endless = true
	next_rise = INF


# =====================================================================================
# Per tick
# =====================================================================================

## Per-tick update (DynastyRules.step()): the clock's rises and warnings, the
## rise / fall events (the stats recompute), the HUD line and the drawing.
func step(delta: float) -> void:
	var now := game.elapsed
	if next_rise != INF and now >= next_rise:
		up_until = maxf(up_until, next_rise + float(cfg["duration"]))
		next_rise += float(cfg["every"])
		_warned = false
		if next_rise >= WaveData.RUN_DURATION:
			next_rise = INF  # Past 0:00 only the Devourer's Hour's storm blows.
	if next_rise != INF and not _warned and not is_up() and now >= next_rise - float(cfg["warn"]):
		_warned = true
		game.enemies.show_banner(String(cfg["warn_banner"]))
		game.stat_add("sandstorm_warnings", 1.0)
		if game.dynasty != null:
			game.dynasty.play_sound("storm_warn", game.player.position)
	var up := is_up()
	if up and not _was_up:
		_rise()
	elif _was_up and not up:
		_fall()
	_was_up = up
	if up:
		game.stat_add("sandstorm_time", delta)
	if _draws:
		var goal := 1.0 if up else 0.0
		var was := _tint
		_tint = move_toward(_tint, goal, delta / maxf(float(cfg["fade"]), 0.01))
		if _tint != was or _tint > 0.0:
			queue_redraw()
		_update_label()


## The storm rises (the clock's, a boss's or the endless one).
func _rise() -> void:
	storms += 1
	rise_times.append(EmpireReport._clock(game.elapsed))
	game.stat_add("sandstorms", 1.0)
	if not _quiet:
		game.enemies.show_banner(String(cfg["rise_banner"]))
	_quiet = false
	if game.dynasty != null:
		game.dynasty.play_sound("storm_rise", game.player.position)
		game.dynasty.on_storm_changed()


## The storm falls.
func _fall() -> void:
	game.stat_add("sandstorm_falls", 1.0)
	if game.dynasty != null:
		game.dynasty.on_storm_changed()


# =====================================================================================
# Drawing (visual only; never headless)
# =====================================================================================

## The sand wash over the view and the veil around the necromancer.
func _draw() -> void:
	if _tint <= 0.0:
		return
	var view := _view()
	draw_rect(view.grow(64.0), Color(Palette.DYN_SAND, float(cfg["tint_alpha"]) * _tint))
	if _veil == null:
		_veil = _make_veil()
	var c := view.get_center()  # The veil follows the camera (the necromancer this machine shows).
	draw_texture_rect(_veil, Rect2(c - Vector2.ONE * VEIL_RADIUS, Vector2.ONE * VEIL_RADIUS * 2.0), false,
			Color(1.0, 1.0, 1.0, _tint))


## The veil texture: clear out to hide_radius, then sand thickening over
## hide_soft px to veil_alpha, out to the corners (one image made once).
func _make_veil() -> ImageTexture:
	var img := Image.create(VEIL_TEX, VEIL_TEX, false, Image.FORMAT_RGBA8)
	var inner := float(cfg["hide_radius"]) / VEIL_RADIUS  # Share of the radius where the veil starts.
	var soft := maxf(float(cfg["hide_soft"]) / VEIL_RADIUS, 0.001)  # Share over which it thickens.
	var top := float(cfg["veil_alpha"])
	var sand := Palette.DYN_SAND
	var half := float(VEIL_TEX) * 0.5
	for y in VEIL_TEX:
		for x in VEIL_TEX:
			var d := Vector2(float(x) + 0.5 - half, float(y) + 0.5 - half).length() / half  # 0 centre .. 1 edge.
			var a := clampf((d - inner) / soft, 0.0, 1.0) * top
			img.set_pixel(x, y, Color(sand, a))
	return ImageTexture.create_from_image(img)


## The visible world rect around the camera.
func _view() -> Rect2:
	var cam := game.camera
	var zoom := cam.zoom if cam != null else Vector2.ONE
	var sz := get_viewport_rect().size / zoom  # World px on screen.
	var c := cam.get_screen_center_position() if cam != null else game.player.position
	return Rect2(c - sz * 0.5, sz)


## The HUD's storm line: "Sandstorm in 0:08" while one is coming (the
## warning), "Sandstorm 0:31" while it blows, "Sandstorm" for good in the
## Devourer's Hour; hidden otherwise. Made on first use under the HUD's
## top-centre block.
func _update_label() -> void:
	if game.hud == null:
		return
	var text := ""
	if endless:
		text = "Sandstorm"
	elif is_up():
		text = "Sandstorm %s" % EmpireReport._clock(maxf(0.0, up_until - game.elapsed))
	elif _warned and next_rise != INF:
		text = "Sandstorm in %s" % EmpireReport._clock(ceilf(maxf(0.0, next_rise - game.elapsed)))
	if text == "":
		if _label != null:
			_label.visible = false
		return
	if _label == null:
		_label = UiTheme.tier_label(text, UiTheme.Tier.NAME, DynastyRulesData.STORM_HUD_COLOR)
		_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		game.hud.add_child(_label)
	_label.visible = true
	if _label.text != text:
		_label.text = text
	var w := game.hud.size.x  # HUD width (layout px).
	_label.size = Vector2(w, _label.get_minimum_size().y)
	_label.position = Vector2(0.0, game.hud.top_centre_bottom() + DynastyRulesData.STORM_HUD_GAP)
