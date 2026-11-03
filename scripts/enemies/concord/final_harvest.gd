## FinalHarvest — THE FINAL HARVEST, the shared Act IX Reckoning (GDD §15.0
## "The Final Harvest"; owner-approved proposal: "Reckoning, the Final
## Harvest: at 0:00 the mothership opens its eye over the arena: its main beam
## sweeps the whole map, saucers fill the sky, and the abduction cap is gone"),
## owned by Game.concord as `harvest`. On a stage whose RECKONING has a
## "final_harvest" dictionary (its keys override ConcordRulesData
## .FINAL_HARVEST; absent = off), from 0:00:
##   * THE EYE OPENS: a sky overlay (the `concord/mothership_eye` texture when
##     present, else a code glyph made of textures) fades in over the view,
##     drawn in world space at z 17 over the units (no screen read);
##   * THE EYE BEAM: every eye_every s (shorter each minute, down to
##     eye_every_min) an "eye" beam through THE beam path,
##     ConcordBeams.fire(null, ..., boss_override = true): its muzzle hangs
##     eye_offset px from a standing necromancer at a seeded angle, it aims at
##     him and, long enough to cross the view, sweeps across him;
##   * SAUCERS FILL THE SKY: the RECKONING's "kind" is the saucer (spawned by
##     EnemyDirector like every Reckoning; ConcordRules counts them), with the
##     shared kinds as companions;
##   * THE CAP IS GONE: Abduction.uncapped;
##   * the pods keep falling (Terraforming runs on).
## Determinism: the seeded gameplay RNG only (which necromancer, the angle,
## the sweep side), and only on an Act IX stage. Stats: harvest_eye_beams,
## harvest_eye_refused.
class_name FinalHarvest
extends Node2D

## Owning run.
var game: Game
## The Final Harvest's numbers ({} = off on this stage).
var cfg: Dictionary = {}
## True once 0:00 passed and the Final Harvest began.
var started: bool = false
## Game time (s) it began.
var started_at: float = 0.0
## Eye beams fired.
var eye_beams: int = 0
## Game time (s) of the next eye beam.
var _next_eye: float = INF
## True when this build draws (never headless).
var _draws: bool = false


## Builds the Final Harvest for `p_game`; `enabled`: an Act IX stage.
func _init(p_game: Game, enabled: bool) -> void:
	game = p_game
	name = "FinalHarvest"
	z_index = 17  # Over the units and the effects; under the Sun's darkness slot and the HUD.
	z_as_relative = false
	var r: Dictionary = p_game.stage_def.get("reckoning", {})  # The stage's Reckoning.
	if enabled and r.has("final_harvest"):
		cfg = ConcordRulesData.FINAL_HARVEST.duplicate()
		var over: Dictionary = r["final_harvest"]
		for key: String in over:
			cfg[key] = over[key]
	_draws = DisplayServer.get_name() != "headless"


## True while the Final Harvest runs (after 0:00 on a stage that has it).
func running() -> bool:
	return started


## Per-tick update (ConcordRules.step()).
func step(_delta: float) -> void:
	if cfg.is_empty():
		return
	if not started:
		if game.countdown_finished():
			started = true
			started_at = game.elapsed
			_next_eye = game.elapsed + float(cfg["eye_first"])
			game.concord.abduction.uncapped = true
			game.concord.play_sound("harvest_eye", game.player.position)
		return
	if game.elapsed >= _next_eye:
		_next_eye = game.elapsed + _eye_interval()
		_eye_beam()
	if _draws:
		queue_redraw()


## Seconds until the next eye beam: eye_every, shorter each minute past 0:00,
## down to eye_every_min.
func _eye_interval() -> float:
	var mins := (game.elapsed - started_at) / 60.0
	return maxf(float(cfg["eye_every_min"]), float(cfg["eye_every"]) - float(cfg["eye_every_step"]) * mins)


## One eye beam at a standing necromancer, from eye_offset px away at a seeded
## angle, through ConcordBeams.fire() with the boss override.
func _eye_beam() -> void:
	var standing: Array[Necromancer] = []
	for pl in game.all_players:
		if not pl.dead:
			standing.append(pl)
	if standing.is_empty():
		return
	var pl: Necromancer = standing[randi() % standing.size()]
	var a := randf() * TAU
	var side := 1 if randf() < 0.5 else -1
	var from := pl.position + Vector2.from_angle(a) * float(cfg["eye_offset"])
	var dmg := pow(float((game.stage_def["reckoning"] as Dictionary).get("damage_growth", 1.0)), float(game.enemies.reckoning_wave))
	var ok := game.concord.beams.fire(null, pl.position - from, "eye",
			{"origin": from, "target": pl, "source": ConcordRulesData.EYE_SOURCE, "side": side,
			"scale": game.enemies.damage_mult * dmg}, true)
	if ok:
		eye_beams += 1
		game.stat_add("harvest_eye_beams", 1.0)
	else:
		game.stat_add("harvest_eye_refused", 1.0)


# =====================================================================================
# Drawing (visual only; never headless)
# =====================================================================================

## The mothership's eye over the view: the `concord/mothership_eye` texture
## fading in (else a code glyph of textures), above the camera's centre.
func _draw() -> void:
	if not started:
		return
	var k := clampf((game.elapsed - started_at) / maxf(float(cfg["fade_in"]), 0.01), 0.0, 1.0)
	var alpha := float(cfg["overlay_alpha"]) * k
	var centre := game.camera.get_screen_center_position()
	var view := game.view_size() / game.camera.zoom  # World px across the view.
	var w := float(cfg["overlay_px"])
	var at := centre + Vector2(0.0, -view.y * 0.5 + w * 0.12)  # Hanging from the top of the view.
	var tex := SpriteBank.texture("concord/mothership_eye")
	if tex != null:
		var h := w * float(tex.get_height()) / maxf(float(tex.get_width()), 1.0)
		draw_texture_rect(tex, Rect2(at - Vector2(w, h) * 0.5, Vector2(w, h)), false, Color(1, 1, 1, alpha))
		return
	ConcordGlyphs.draw_eye(self, at, w, k, alpha, game.elapsed)
