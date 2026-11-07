## Ragnarok — RAGNARÖK, the shared Reckoning of the Hall of the Slain (the Norse
## act, temporarily Act XI; GDD §15.0 "Ragnarök"; the act's section of
## docs/proposals/LAST_SIX_ACTS.md: "at 0:00 the wolf swallows the sun and the
## arena goes dark red; every Einherjar the run created marches at once,
## fire-giants step out of the south edge, and every valkyrie dives at the
## ring"; there is no Choosing (owner, Nov 7, 2026), so the Einherjar who march
## are the hall's own heroes), owned by Game.norse as `ragnarok`. On a stage whose RECKONING has a
## "ragnarok" dictionary (its keys override NorseRulesData.RAGNAROK; absent =
## off), from 0:00:
##   * THE SUN IS SWALLOWED: a dark red wash over the view (a BLEND_MODE_MUL
##     rect, as the Court's Blood Moon: no shader reads the screen), fading in
##     over `fade` s, drawn at z 18 over the units;
##   * THE EINHERJAR MARCH: `einherjar` heroes of the hall (elites of
##     einherjar_kinds in turn, made gold by NorseKit.make_einherjar()) march
##     at once from the spawn ring, Reckoning foes;
##   * THE FIRE-GIANTS: every giant_every s (the first at 0:00) `giants`
##     fire-giants step out of the south edge of the spawn ring, giant_spread
##     px apart, Reckoning foes; the RECKONING's own "kind" is the fire-giant
##     too (EnemyDirector spawns its waves like every Reckoning);
##   * EVERY VALKYRIE DIVES: each war-maiden on the field dives at once
##     (NorseValkyrieKit.force_dive()), and while it runs their dives come
##     dive_every_mult as often (NorseValkyrieKit reads running()).
## Determinism: no RNG (the march angles are spread evenly), only on a Norse
## stage. Stats: ragnarok_einherjar, ragnarok_giants, ragnarok_dives_forced.
class_name Ragnarok
extends Node2D

## Owning run.
var game: Game
## Ragnarök's numbers ({} = off on this stage).
var cfg: Dictionary = {}
## True once 0:00 passed and Ragnarök began.
var started: bool = false
## Game time (s) it began.
var started_at: float = 0.0
## Einherjar of the hall that marched at 0:00.
var einherjar: int = 0
## Fire-giants that stepped out of the south edge.
var giants: int = 0
## Game time (s) of the next march of the fire-giants.
var _next_giants: float = INF
## Strength of the red wash now (0..1; drawing only).
var _tint: float = 0.0
## True when this build draws (never headless).
var _draws: bool = false


## Builds Ragnarök for `p_game`; `enabled`: a Norse stage.
func _init(p_game: Game, enabled: bool) -> void:
	game = p_game
	name = "Ragnarok"
	z_index = 18  # Over the bodies, the shots and the effects; under the HUD.
	z_as_relative = false
	var r: Dictionary = p_game.stage_def.get("reckoning", {})  # The stage's Reckoning.
	if enabled and r.has("ragnarok"):
		cfg = NorseRulesData.RAGNAROK.duplicate()
		var over: Dictionary = r["ragnarok"]
		for key: String in over:
			cfg[key] = over[key]
	_draws = DisplayServer.get_name() != "headless"
	if _draws:
		var mat := CanvasItemMaterial.new()
		mat.blend_mode = CanvasItemMaterial.BLEND_MODE_MUL  # The red wash multiplies what is under it.
		material = mat


## True while Ragnarök runs (after 0:00 on a stage that has it).
func running() -> bool:
	return started


## Per-tick update (NorseRules.step()).
func step(delta: float) -> void:
	if cfg.is_empty():
		return
	if not started:
		if game.countdown_finished():
			_begin()
		return
	if game.elapsed >= _next_giants:
		_next_giants = game.elapsed + float(cfg["giant_every"])
		_march_giants()
	if _draws:
		var was := _tint
		_tint = move_toward(_tint, 1.0, delta / maxf(float(cfg["fade"]), 0.01))
		if _tint != was or _tint > 0.0:
			queue_redraw()


## 0:00: the sun goes out, the Einherjar march, every valkyrie dives.
func _begin() -> void:
	started = true
	started_at = game.elapsed
	_next_giants = game.elapsed
	var kinds: Array = cfg["einherjar_kinds"]  # The heroes' kinds, in turn.
	var n := int(cfg["einherjar"])
	for i in n:
		var at := game.enemies.ring_point(TAU * float(i) / float(maxi(1, n)))
		var e := game.enemies.spawn_at(String(kinds[i % kinds.size()]), at, true)
		if e != null:
			if e.kit is NorseKit:
				(e.kit as NorseKit).make_einherjar(e)
			e.is_reckoning = true
			einherjar += 1
	game.stat_add("ragnarok_einherjar", float(einherjar))
	for e in game.enemies.active:
		if e.active and e.kit is NorseValkyrieKit:
			(e.kit as NorseValkyrieKit).force_dive()
			game.stat_add("ragnarok_dives_forced", 1.0)
	game.norse.play_sound("ragnarok", game.player.position)
	game.norse.play_sound("einherjar_march", game.player.position)


## One march of fire-giants out of the south edge of the spawn ring.
func _march_giants() -> void:
	var n := int(cfg["giants"])
	var south := game.enemies.ring_point(PI * 0.5)  # The ring's southmost point (screen down).
	for i in n:
		var off := (float(i) - float(n - 1) * 0.5) * float(cfg["giant_spread"])
		var e := game.enemies.spawn_at(String(cfg["giant_kind"]), south + Vector2(off, 0.0), false)
		if e != null:
			e.is_reckoning = true
			giants += 1
			game.stat_add("ragnarok_giants", 1.0)


# =====================================================================================
# Drawing (visual only; never headless)
# =====================================================================================

## The dark red wash over the view (multiplied: white = no change).
func _draw() -> void:
	if _tint <= 0.0:
		return
	var tint: Color = cfg["tint"]
	var cam := game.camera
	var zoom := cam.zoom if cam != null else Vector2.ONE
	var sz := get_viewport_rect().size / zoom  # World px on screen.
	var c := cam.get_screen_center_position() if cam != null else game.player.position
	draw_rect(Rect2(c - sz * 0.5, sz).grow(64.0), Color.WHITE.lerp(tint, _tint))
