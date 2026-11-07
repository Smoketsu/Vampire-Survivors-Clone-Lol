## BloodMoon — THE BLOOD MOON, the third Sanguine Court rule (Act VII; GDD §15.0
## "The Blood Moon"; owner-approved proposal: "Every 4:00 the moon turns red for
## 45 s (shown 10 s ahead on the HUD). Under it, werewolves transform, every
## Court enemy feeds twice as hard, and witch covens can cast ... One clock
## path, BloodMoon, like the Act II tide surges"), owned by Game.court.
## THE one clock:
##   * on an Act VII stage (STAGE "court"), from `first` s, every `every` s the
##     moon is up for `duration` s (CourtRulesData.BLOOD_MOON; a stage's STAGE
##     "moon" overrides any key); `warn` s before each rise the HUD's moon line
##     counts down and a banner warns;
##   * is_up() is THE test every reader asks: Bloodfeast (feed_mult(): x
##     feed_mult under it, through CourtRules.feed_mult()), the werebeasts
##     (WerewolfKit turns when it is up), phase 2's witch covens;
##   * force(duration) raises it now for at least `duration` s, whatever the
##     clock says (the bosses' own moons: Vargr, Isolde; no banner: the boss
##     shows its own), and start_endless() keeps it up for good (the Endless
##     Feast at 0:00).
## Drawn: the world multiplied by the moon's red tint (one view-sized rect with
## a BLEND_MODE_MUL material: no shader reads the screen), fading in and out
## over `fade` s, and the HUD's moon line (a label under the HUD's top-centre
## block: the countdown before a rise, the time left while it is up). Nothing
## drawn headless.
## Determinism: game time only. Stats: blood_moons, blood_moons_forced,
## blood_moon_time, werebeast_moon_turns (counted by WerewolfKit).
class_name BloodMoon
extends Node2D

## Owning run.
var game: Game
## True on an Act VII stage: the clock runs (force() works anywhere).
var enabled: bool = false
## The stage's Blood Moon numbers (BLOOD_MOON with the STAGE's "moon").
var cfg: Dictionary = {}
## Game time (s) of the next clock rise (INF once the Endless Feast holds it).
var next_rise: float = INF
## Game time (s) until which the moon is up (clock or forced).
var up_until: float = -INF
## True once the Endless Feast raised it for good.
var endless: bool = false
## Moons risen this run (clock, forced and the endless one).
var moons: int = 0
## Moons a boss forced this run.
var forced: int = 0
## Game time (s) each moon rose, "m:ss" (the autotest line).
var rise_times: PackedStringArray = PackedStringArray()
## Werebeasts that turned under the moon this run (WerewolfKit).
var transforms: int = 0
## True while the moon was up at the last step.
var _was_up: bool = false
## True once the coming rise was warned.
var _warned: bool = false
## True when the next rise comes quietly (a forced moon: no banner).
var _quiet: bool = false
## Strength (0..1) of the drawn tint now (follows is_up() over `fade` s).
var _tint: float = 0.0
## True when this build draws (never headless).
var _draws: bool = false
## The HUD's moon line (null until the HUD exists; never headless).
var _label: Label = null


## Builds the moon for `p_game` (CourtRules adds it as its child); `p_enabled`:
## an Act VII stage (the clock runs).
func _init(p_game: Game, p_enabled: bool) -> void:
	game = p_game
	name = "BloodMoon"
	z_index = 18  # Over the bodies, the shots and the threads; under the HUD.
	z_as_relative = false
	enabled = p_enabled
	cfg = CourtRulesData.BLOOD_MOON.duplicate()
	var over: Dictionary = p_game.stage_def.get("moon", {})  # The stage's own overrides.
	for key: String in over:
		cfg[key] = over[key]
	if enabled:
		next_rise = float(cfg["first"])
	_draws = DisplayServer.get_name() != "headless"
	if _draws:
		var mat := CanvasItemMaterial.new()
		mat.blend_mode = CanvasItemMaterial.BLEND_MODE_MUL  # The red wash multiplies what is under it.
		material = mat


# =====================================================================================
# The clock (public API)
# =====================================================================================

## THE test: true while the Blood Moon is up (clock, forced or endless).
func is_up() -> bool:
	return endless or game.elapsed < up_until


## Seconds until the next clock rise (-1 when none is coming: the moon is up,
## the clock is off, or the Endless Feast holds it).
func time_to_rise() -> float:
	if is_up() or next_rise == INF:
		return -1.0
	return maxf(0.0, next_rise - game.elapsed)


## x on every Court enemy's feeding now (CourtRules.feed_mult()): feed_mult
## while the moon is up, else 1.
func feed_mult() -> float:
	return float(cfg["feed_mult"]) if is_up() else 1.0


## Raises the moon now for at least `duration` s (the bosses' own moons; it
## works on any stage the Court's rules exist). No banner: the boss shows its own.
func force(duration: float) -> void:
	if not is_up():
		_quiet = true
		forced += 1
		game.stat_add("blood_moons_forced", 1.0)
	up_until = maxf(up_until, game.elapsed + duration)


## The Endless Feast (0:00): the moon rises and never sets.
func start_endless() -> void:
	endless = true
	next_rise = INF


# =====================================================================================
# Per tick
# =====================================================================================

## Per-tick update (CourtRules.step()): the clock's rises and warnings, the
## rise / set events, the HUD line and the tint.
func step(delta: float) -> void:
	var now := game.elapsed
	if next_rise != INF and now >= next_rise:
		up_until = maxf(up_until, next_rise + float(cfg["duration"]))
		next_rise += float(cfg["every"])
		_warned = false
		if next_rise >= WaveData.RUN_DURATION:
			next_rise = INF  # Past 0:00 only the Endless Feast's moon rises.
	if next_rise != INF and not _warned and not is_up() and now >= next_rise - float(cfg["warn"]):
		_warned = true
		game.enemies.show_banner(String(cfg["warn_banner"]))
		game.stat_add("blood_moon_warnings", 1.0)
	var up := is_up()
	if up and not _was_up:
		_rise()
	elif _was_up and not up:
		_moon_set()
	_was_up = up
	if up:
		game.stat_add("blood_moon_time", delta)
	if _draws:
		var goal := 1.0 if up else 0.0
		var was := _tint
		_tint = move_toward(_tint, goal, delta / maxf(float(cfg["fade"]), 0.01))
		if _tint != was or _tint > 0.0:
			queue_redraw()
		_update_label()


## The moon rises (the clock's, a boss's or the endless one).
func _rise() -> void:
	moons += 1
	rise_times.append(EmpireReport._clock(game.elapsed))
	game.stat_add("blood_moons", 1.0)
	if not _quiet:
		game.enemies.show_banner(String(cfg["rise_banner"]))
	_quiet = false
	if game.court != null:
		game.court.play_sound("moon_rise", game.player.position)


## The moon sets.
func _moon_set() -> void:
	game.stat_add("blood_moon_sets", 1.0)
	if game.court != null:
		game.court.play_sound("moon_set", game.player.position)


# =====================================================================================
# Drawing (visual only; never headless)
# =====================================================================================

## The red wash over the view (multiplied: white = no change).
func _draw() -> void:
	if _tint <= 0.0:
		return
	var tint: Color = cfg["tint"]
	draw_rect(_view().grow(64.0), Color.WHITE.lerp(tint, _tint))


## The visible world rect around the camera.
func _view() -> Rect2:
	var cam := game.camera
	var zoom := cam.zoom if cam != null else Vector2.ONE
	var sz := get_viewport_rect().size / zoom  # World px on screen.
	var c := cam.get_screen_center_position() if cam != null else game.player.position
	return Rect2(c - sz * 0.5, sz)


## The HUD's moon line: "Blood Moon in 0:08" while one is coming (the warning),
## "Blood Moon 0:31" while it is up, "Blood Moon" for good in the Endless
## Feast; hidden otherwise. Made on first use under the HUD's top-centre block.
func _update_label() -> void:
	if game.hud == null:
		return
	var text := ""
	if endless:
		text = "Blood Moon"
	elif is_up():
		text = "Blood Moon %s" % EmpireReport._clock(maxf(0.0, up_until - game.elapsed))
	elif _warned and next_rise != INF:
		text = "Blood Moon in %s" % EmpireReport._clock(ceilf(maxf(0.0, next_rise - game.elapsed)))
	if text == "":
		if _label != null:
			_label.visible = false
		return
	if _label == null:
		_label = UiTheme.tier_label(text, UiTheme.Tier.NAME, CourtRulesData.MOON_HUD_COLOR)
		_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		game.hud.add_child(_label)
	_label.visible = true
	if _label.text != text:
		_label.text = text
	var w := game.hud.size.x  # HUD width (layout px).
	_label.size = Vector2(w, _label.get_minimum_size().y)
	_label.position = Vector2(0.0, game.hud.top_centre_bottom() + CourtRulesData.MOON_HUD_GAP)
