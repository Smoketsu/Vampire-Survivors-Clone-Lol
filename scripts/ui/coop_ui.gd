## CoopUi: the co-op visuals of one run and the small API the lockstep driver
## calls (GDD §15.0 "Co-op HUD and visuals"; docs/coop/DESIGN.md "Camera, HUD
## and input"; numbers and texts in CoopHudData). Hud creates ONE when the run
## is co-op (`game.coop` set) and exposes it as `game.hud.coop_ui`; a solo run
## never creates it (`game.hud.coop_ui` stays null), so nothing of it exists or
## draws there.
##
## API (for the lockstep driver; safe to call at any time, also while the
## tree is paused and headless):
##   show_waiting(text: String)  shows the non-blocking "Waiting for partner"
##                               panel with `text` under its headline ("Your
##                               partner is choosing a card", "Paused by your
##                               partner", "Connection is slow"); calling it
##                               again just replaces the line. It never takes
##                               input and never pauses anything.
##   clear_waiting()             hides that panel (no-op when hidden).
##   notice(text: String, danger: bool = false)
##                               a banner through the HUD's one banner queue
##                               (HudBanners), kicker "Co-op": the first
##                               sentence of `text` is the headline, the rest
##                               the sub-line ("Your partner left. A bot took
##                               over."); violet, or crimson with `danger`. It
##                               shows while the run plays (banners hide under
##                               the panels and wait for game time).
##   waiting_text() -> String    the line on show ("" when hidden; tests).
##
## What it shows by itself (it reads `game.coop`, never writes it):
##   * the partner's plate in the HUD's top-right block (CoopPartnerBar: bust,
##     name, HP bar; downed in crimson with the revive progress);
##   * the edge arrow toward an off-screen partner (CoopArrows, its own
##     CanvasLayer like the chest arrows; not headless);
##   * the downed marker, revive ring and revive-radius circle over every
##     downed necromancer in the world (CoopMarkers, a child of Game; not
##     headless);
##   * while this machine's own necromancer lies downed, a crimson plate over
##     the middle of the screen: "Downed" / "Your partner can raise you" with
##     the revive progress bar ("Your partner is raising you" while he stands
##     in reach);
##   * the waiting panel (CoopWaiting, its own CanvasLayer over the panels).
## The debug flags --coop-ui-test / --coop-shots= add a CoopUiTest that walks
## through every state (and, with --coop-shots, takes the screenshots).
## Counters for the autotest's "coop hud" line (summary_line()) count, from
## the logical view (the 1280 x 720 design layout headless, like the chest
## beacon's count), the ticks the partner was off screen (an arrow), the ticks
## a downed marker showed and the waiting / notice calls; they are never read
## by gameplay. Purely visual: no gameplay state, no RNG.
class_name CoopUi
extends Control

## Owning run.
var game: Game
## The partner's plate (Hud adds it to its top-right block).
var partner_bar: CoopPartnerBar = null
## The off-screen arrow overlay (null headless).
var arrows: CoopArrows = null
## The world markers (null headless).
var markers: CoopMarkers = null
## The waiting panel (on its own CanvasLayer).
var waiting: CoopWaiting = null
## The "your partner can raise you" plate (the local player downed).
var _self_plate: PanelContainer = null
## Its line under the "Downed" kicker.
var _self_line: Label = null
## Its revive progress bar.
var _self_bar: HudBar = null
## Debug sequence (--coop-ui-test / --coop-shots; null otherwise).
var test: CoopUiTest = null
## Time accumulated toward the next plate refresh (s, real).
var _accum: float = 0.0

# --- Counters (the autotest's "coop hud" line; never read by gameplay) -------------------

## Physics ticks the partner was off the logical view (an edge arrow showed).
var arrow_ticks: int = 0
## Physics ticks some necromancer lay downed (his marker and ring showed).
var downed_ticks: int = 0
## Physics ticks this machine's own necromancer lay downed (the self plate showed).
var self_downed_ticks: int = 0
## Physics ticks a revive ring was part-filled (a partner standing in reach).
var ring_ticks: int = 0
## show_waiting() calls with a new text, clear_waiting() calls, notice() calls.
var waiting_calls: int = 0
var clear_calls: int = 0
var notices: int = 0


func _init(p_game: Game) -> void:
	game = p_game
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	partner_bar = CoopPartnerBar.new()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS  # The waiting panel and the plate refresh under a pause.
	_build_self_plate()
	var wl := CanvasLayer.new()  # Waiting panel layer: over the HUD and the run's panels.
	wl.layer = CoopHudData.WAITING_LAYER
	wl.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(wl)
	var wroot := Control.new()  # Themed full-rect root (the UI theme, like the run's UI root).
	wroot.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	wroot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wroot.theme = UiTheme.get_theme()
	wl.add_child(wroot)
	waiting = CoopWaiting.new()
	wroot.add_child(waiting)
	if DisplayServer.get_name() != "headless":
		var al := CanvasLayer.new()  # Edge arrow layer: the chest arrows' (over the world, under the HUD).
		al.layer = ChestBeaconData.ARROW_LAYER
		add_child(al)
		arrows = CoopArrows.new()
		arrows.game = game
		al.add_child(arrows)
		markers = CoopMarkers.new()
		markers.game = game
		game.add_child.call_deferred(markers)  # World space; freed with the run (deferred: Game is still building its UI).
	if GameState.autotest_coop_ui_test or GameState.autotest_coop_shots != "":
		test = CoopUiTest.new()
		test.ui = self
		add_child(test)
	_refresh()


## The centred plate shown while this machine's necromancer lies downed.
func _build_self_plate() -> void:
	var holder := VBoxContainer.new()  # Centred over the middle of the screen.
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.anchor_left = 0.5
	holder.anchor_right = 0.5
	holder.anchor_top = 0.5
	holder.anchor_bottom = 0.5
	holder.offset_left = -CoopHudData.SELF_BAR_WIDTH
	holder.offset_right = CoopHudData.SELF_BAR_WIDTH
	holder.offset_top = -CoopHudData.SELF_PLATE_RISE
	holder.offset_bottom = -CoopHudData.SELF_PLATE_RISE
	holder.grow_horizontal = Control.GROW_DIRECTION_BOTH
	holder.grow_vertical = Control.GROW_DIRECTION_BOTH
	add_child(holder)
	_self_plate = PanelContainer.new()
	_self_plate.add_theme_stylebox_override("panel", UiTheme.style("panel", "dim"))
	_self_plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_self_plate.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_self_plate.visible = false
	holder.add_child(_self_plate)
	var vb := VBoxContainer.new()
	vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.add_theme_constant_override("separation", 2)
	_self_plate.add_child(vb)
	var kick := UiTheme.tier_label(CoopHudData.SELF_DOWNED_TITLE, UiTheme.Tier.LABEL, CoopHudData.DOWNED_LIGHT)
	kick.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(kick)
	_self_line = UiTheme.tier_label(CoopHudData.SELF_DOWNED_TEXT, UiTheme.Tier.NAME, UiTheme.TEXT)
	_self_line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(_self_line)
	_self_bar = HudBar.new(CoopHudData.REVIVE, Vector2(CoopHudData.SELF_BAR_WIDTH, 8.0))
	_self_bar.back_color = Color(CoopHudData.DOWNED, 0.5)
	_self_bar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vb.add_child(_self_bar)


func _process(delta: float) -> void:
	_accum += delta
	if _accum >= Hud.REFRESH or _downed_any():
		_accum = 0.0
		_refresh()


## True while some slot lies downed (the plates then refresh every frame, for
## the smooth ring and pulse).
func _downed_any() -> bool:
	if game == null or game.coop == null:
		return false
	for s in game.coop.slots:
		if s.downed:
			return true
	return false


## The partner slot of this machine's view (the first slot that is not the
## viewed one; null without a session).
func partner() -> CoopSlot:
	if game == null or game.coop == null:
		return null
	for s in game.coop.slots:
		if s.index != game.coop.view_slot:
			return s
	return null


## This machine's own slot (null without a session).
func local_slot() -> CoopSlot:
	if game == null or game.coop == null or game.coop.view_slot >= game.coop.slots.size():
		return null
	return game.coop.slots[game.coop.view_slot]


## Pulls the partner's state into the plate and the self plate.
func _refresh() -> void:
	var pt := partner()
	var me := local_slot()
	if pt == null or me == null:
		return
	partner_bar.refresh(pt, pt.downed and me.alive() and CoopMarkers.helper_in_reach(game.coop, pt))
	var show := me.downed and game.run_state == Game.RunState.PLAYING
	_self_plate.visible = show
	if show:
		var near := CoopMarkers.helper_in_reach(game.coop, me)  # The partner stands in reach.
		_self_line.text = CoopHudData.SELF_RAISING_TEXT if near else (CoopHudData.SELF_ALONE_TEXT if not pt.alive() else CoopHudData.SELF_DOWNED_TEXT)
		_self_line.add_theme_color_override("font_color", CoopHudData.REVIVE if near else UiTheme.TEXT)
		_self_bar.set_values(clampf(me.revive_progress / CoopData.REVIVE_TIME, 0.0, 1.0))


## Counts what the co-op visuals show this tick, from the logical view
## (headless too; see the header).
func _physics_process(_delta: float) -> void:
	if game == null or game.coop == null or game.run_state != Game.RunState.PLAYING or get_tree().paused:
		return
	var pt := partner()
	var me := local_slot()
	if pt == null or me == null:
		return
	var view := Vector2(float(ProjectSettings.get_setting("display/window/size/viewport_width", 1280)),
		float(ProjectSettings.get_setting("display/window/size/viewport_height", 720)))  # Design layout (px).
	if DisplayServer.get_name() != "headless":
		view = get_viewport_rect().size
	var z := maxf(game.camera.zoom.x, 0.01) if game.camera != null else 1.0  # Screen px per world px.
	if not ChestBeacon.on_screen((pt.player.position - me.player.position) * z + view * 0.5, view):
		arrow_ticks += 1
	for s in game.coop.slots:
		if s.downed:
			downed_ticks += 1
			if s.revive_progress > 0.0:
				ring_ticks += 1
	if me.downed:
		self_downed_ticks += 1


# =====================================================================================
# API (the lockstep driver)
# =====================================================================================

## Shows the non-blocking waiting panel with line `text` (see the header).
func show_waiting(text: String) -> void:
	if waiting == null:
		return
	if waiting.text() != text:
		waiting_calls += 1
	waiting.show_text(text)


## Hides the waiting panel (no-op when hidden).
func clear_waiting() -> void:
	if waiting == null:
		return
	if waiting.showing():
		clear_calls += 1
	waiting.clear()


## The waiting panel's line on show ("" when hidden).
func waiting_text() -> String:
	return waiting.text() if waiting != null else ""


## A co-op banner through the HUD banner queue: the first sentence of `text`
## is the headline, the rest the sub-line; crimson with `danger`, else violet.
func notice(text: String, danger: bool = false) -> void:
	if game == null or game.hud == null:
		return
	notices += 1
	var head := text.strip_edges()
	var rest := ""
	var at := head.find(". ")
	if at > 0:
		rest = head.substr(at + 2).strip_edges()
		head = head.substr(0, at + 1)
	game.hud.notice(CoopHudData.NOTICE_KICKER, head, rest, "crimson" if danger else "violet", CoopHudData.NOTICE_HOLD)


## The autotest's "coop hud" line.
func summary_line() -> String:
	return "coop hud: partner plate on | partner off screen %d ticks (edge arrow) | downed marker %d ticks, revive ring filling %d ticks, own downed plate %d ticks | waiting panel %d texts, %d clears | notices %d%s" % [
		arrow_ticks, downed_ticks, ring_ticks, self_downed_ticks, waiting_calls, clear_calls, notices,
		(" | " + test.summary()) if test != null else ""]
