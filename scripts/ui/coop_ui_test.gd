## CoopUiTest: a debug walk through every co-op visual state (GDD §15.0
## "Co-op HUD and visuals"; times and texts in CoopHudData.TEST_*). CoopUi adds
## it only under the debug flags:
##   --coop-ui-test   (autotest, headless or windowed) walks the states during a
##                    normal --coop-bot run and prints one "[autotest] coop ui:"
##                    line per state; the run then goes on to its usual end.
##   --coop-shots=victory|defeat  the same walk for screenshots: at each state
##                    it prints "[coop-shot] NAME", holds the world still for a
##                    moment (Engine.time_scale 0; drawing goes on) and, with
##                    --shot-dir=DIR (a native window, e.g. under Xvfb), saves
##                    DIR/coop_NAME.png. The Web build has no file to save: the
##                    page's test script (tools/coop_hud_shots.mjs) takes the
##                    screenshot during the hold (TEST_WEB_HOLD s). At the end it
##                    ends the run as a victory or a defeat (results card shot
##                    "results"), then quits a native window.
## States, in order: "hud" (the partner plate, partner on screen), "arrow" (the
## camera at the Close zoom, a player setting and drawing only, until the
## partner is off screen: the edge arrow), "waiting" (each lockstep waiting
## text in turn, then cleared), "notice" (a notice banner), "downed" (the run's
## --coop-down= knocks a necromancer down; the shot waits until his revive ring
## is TEST_RING_SHARE filled; named "self_downed" when it is this machine's own
## necromancer, --coop-down-slot=0), then "results". Debug only: the walk
## changes no gameplay rule (the zoom is a view setting, the hold only stops
## time); ending the run early is what the shots flag is for.
class_name CoopUiTest
extends Node

## The co-op visuals under test.
var ui: CoopUi
## Index of the state being walked (see the header).
var _step: int = 0
## Game second the current state started (or its next sub-step is due).
var _due: float = -1.0
## Index into TEST_WAITING_TEXTS of the waiting text on show.
var _wait_i: int = 0
## True while a hold or a shot is in progress (the walk waits).
var _busy: bool = false
## Camera zoom before the arrow state (restored after it).
var _zoom_before: float = 1.0
## States done: name -> "shot" / "seen" / "timeout".
var results: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS  # The results shot is taken on the paused end screen.


## True for the screenshot mode (--coop-shots=).
static func shooting() -> bool:
	return GameState.autotest_coop_shots != ""


func _physics_process(_delta: float) -> void:
	if _busy or ui == null or ui.game == null or ui.game.coop == null:
		return
	var game := ui.game
	if game.run_state != Game.RunState.PLAYING:
		return
	var t := game.elapsed
	match _step:
		0:  # The HUD with the partner plate (partner on screen).
			if t >= CoopHudData.TEST_HUD_AT:
				_state("hud", "partner plate, partner on screen", 1)
		1:  # The off-screen arrow at the Close zoom.
			if t < CoopHudData.TEST_ARROW_FROM:
				return
			if _due < 0.0:
				_due = t
				_zoom_before = game.camera.zoom.x
				game.camera.zoom = Vector2.ONE * float(ViewData.ZOOM_LEVELS["close"]["zoom"])
			var off := ui.arrows.drawn > 0 if ui.arrows != null else _partner_off_logical()
			if off or t >= CoopHudData.TEST_ARROW_UNTIL:
				results["arrow_found"] = off
				_state("arrow", "partner off screen" if off else "partner never left the screen (timeout)", 2, _restore_zoom)
		2:  # The waiting panel, each text in turn.
			if t < CoopHudData.TEST_WAITING_AT:
				return
			if _wait_i < CoopHudData.TEST_WAITING_TEXTS.size():
				if _due < 0.0 or t >= _due:
					var text := CoopHudData.TEST_WAITING_TEXTS[_wait_i]
					ui.show_waiting(text)
					_wait_i += 1
					if _wait_i == 1:
						_state("waiting", "show_waiting('%s') -> '%s'" % [text, ui.waiting_text()], 2)  # Returns at its hold.
					else:
						print("[autotest] coop ui: show_waiting('%s') -> '%s'" % [text, ui.waiting_text()])
					_due = t + CoopHudData.TEST_WAITING_STEP
			elif t >= _due:
				ui.clear_waiting()
				print("[autotest] coop ui: clear_waiting() -> '%s'" % ui.waiting_text())
				_step = 3
				_due = -1.0
		3:  # A notice banner.
			if t < CoopHudData.TEST_NOTICE_AT:
				return
			if _due < 0.0:
				ui.notice(CoopHudData.TEST_NOTICE_TEXT)
				_due = t + 1.0  # Past the banner's fade-in (game time).
			elif t >= _due:
				_state("notice", "notice('%s')" % CoopHudData.TEST_NOTICE_TEXT, 4)
		4:  # A downed necromancer with his revive ring part-filled.
			var s := _downed_slot()
			if s != null and s.revive_progress >= CoopHudData.TEST_RING_SHARE * CoopData.REVIVE_TIME:
				var own := s.index == game.coop.view_slot
				_state("self_downed" if own else "downed", "slot %d downed, revive ring %d%%" % [s.index, roundi(100.0 * s.revive_progress / CoopData.REVIVE_TIME)], 5)
			elif t >= CoopHudData.TEST_DOWNED_UNTIL:
				_state("downed", "no downed necromancer with a filling ring by %s (timeout)" % Autotest._clock(t), 5)
		5:  # The end of the run (shots only): the results card.
			if not shooting():
				_step = 6
				return
			if _due < 0.0:
				_due = t + CoopHudData.TEST_END_DELAY
			elif t >= _due:
				_end_run()


## The first downed slot (null when none).
func _downed_slot() -> CoopSlot:
	for s in ui.game.coop.slots:
		if s.downed:
			return s
	return null


## Headless: true when the partner is off the logical view at the camera's zoom.
func _partner_off_logical() -> bool:
	var pt := ui.partner()
	var me := ui.local_slot()
	var view := Vector2(1280.0, 720.0)  # The design layout (px).
	return not ChestBeacon.on_screen((pt.player.position - me.player.position) * ui.game.camera.zoom.x + view * 0.5, view)


## Restores the camera zoom after the arrow state.
func _restore_zoom() -> void:
	ui.game.camera.zoom = Vector2.ONE * _zoom_before


## State `name` reached (`what` for the log): prints it, takes its shot in the
## screenshot mode, then moves to step `next` (after `then`, if valid).
func _state(name: String, what: String, next: int, then: Callable = Callable()) -> void:
	results[name] = "seen"
	print("[autotest] coop ui: %s at %s: %s" % [name, Autotest._clock(ui.game.elapsed), what])
	_step = next
	_due = -1.0
	if not shooting():
		if then.is_valid():
			then.call()
		return
	_busy = true
	await _shot(name)
	if then.is_valid():
		then.call()
	_busy = false


## Holds the world still, prints "[coop-shot] NAME" and saves the frame
## (native, --shot-dir=), then lets time run again.
func _shot(name: String) -> void:
	var scale := Engine.time_scale  # The autotest speed, restored after.
	Engine.time_scale = 0.0
	print("[coop-shot] %s" % name)
	var web := OS.has_feature("web")
	await get_tree().create_timer(CoopHudData.TEST_WEB_HOLD if web else CoopHudData.TEST_SHOT_DELAY, true, false, true).timeout
	if not web and GameState.autotest_shot_dir != "":
		await RenderingServer.frame_post_draw
		var img := get_viewport().get_texture().get_image()
		var path := GameState.autotest_shot_dir.path_join("coop_%s.png" % name)
		img.save_png(path)
		print("[coop-shot] saved %s (%dx%d)" % [path, img.get_width(), img.get_height()])
	results[name] = "shot"
	Engine.time_scale = scale


## Ends the run for the results card (shots only): the end screen opens with a
## co-op summary like Game.end_run() builds it (without the autotest's report
## and quit), then the shot, then a native window quits.
func _end_run() -> void:
	_busy = true
	var game := ui.game
	var won := GameState.autotest_coop_shots != "defeat"
	game.coop.bind(game.coop.view_slot)
	game.run_state = Game.RunState.ENDED
	game.victory = won
	game.end_reason = "run_complete" if won else "defeat"
	get_tree().paused = true
	game.level_up_panel.close()
	game.pause_menu.close()
	var summary := game.build_summary()
	summary["soul_ash"] = Meta.award_run(summary, game.meta)  # The autotest never saves it.
	game.end_screen.open(summary)
	print("[autotest] coop ui: results (%s) at %s" % ["victory" if won else "defeat", Autotest._clock(game.elapsed)])
	await get_tree().process_frame
	await get_tree().process_frame
	await _shot("results")
	print("[autotest] coop ui: %s" % summary_states())
	print("[coop-shot] done")
	if not OS.has_feature("web"):
		Engine.time_scale = 1.0
		get_tree().quit(0)


## "name=result" of every state walked.
func summary_states() -> String:
	var out := PackedStringArray()
	for k: String in results.keys():
		out.append("%s=%s" % [k, str(results[k])])
	return "states " + ", ".join(out)


## The test's part of the "coop hud" line.
func summary() -> String:
	return "ui test %s" % summary_states()
