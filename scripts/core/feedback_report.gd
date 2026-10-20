## FeedbackReport — the Feedback buttons' report and link (owner request "Can
## we add a feedback button to the game?", GDD §15.0 "Feedback button (owner
## request, Oct 2026)"; texts and the destination in FeedbackData).
##
## build(context) writes a short plain-text report from data the game already
## shows (no personal data, no save contents, no RNG), three lines:
##   Necropathy v<version> | <platform> | <browser user agent, Web only> | screen <w>x<h> | touch yes/no
##   Where: main menu / pause (stage, elapsed, character, difficulty, Hyper,
##          modifiers) / results (victory or defeat and why, stage, time, the
##          time past 0:00 or left on the countdown, kills, level, the boss,
##          character, difficulty, Hyper, modifiers)
##   Settings: effects Full/Reduced | reduce motion on/off | volleys on/off
## cut to FeedbackData.REPORT_MAX_CHARS. The contexts come from menu_context(),
## pause_context(game) and results_context(summary), which only read.
##
## url_for(report) is FeedbackData.FORM_URL (or the --feedback-url= debug
## override) + "?usp=pp_url&" + DETAILS_ENTRY + "=" + the URL-encoded report;
## enabled() is false while no form URL is set, and every Feedback button is
## then left out. open(context) opens it in the browser (OS.shell_open; on the
## Web build a new tab, the game keeps its state) and NEVER under the autotest
## or headless.
##
## Web build and pop-up blockers: Godot handles a press a frame after the
## browser's event, outside the gesture, which Safari treats as a pop-up. So on
## the Web the button's press-down arms the link (arm()) and a small page
## listener (web_prepare(), installed once) opens the tab inside the browser's
## own release event (pointerup / touchend / mouseup / keyup; a release far
## from the press is a drag off the button and drops it). open() then only
## falls back to OS.shell_open() when the listener could not run (a controller
## press: browsers never count a pad button as a gesture, so that tab may be
## blocked).
## Read-only: nothing here changes gameplay state, the run, Meta or Settings.
class_name FeedbackReport
extends RefCounted


# =====================================================================================
# Destination
# =====================================================================================

## The form's link: the --feedback-url= debug override, else FeedbackData.FORM_URL
## ("" = not set up).
static func form_url() -> String:
	return GameState.feedback_url if GameState.feedback_url != "" else FeedbackData.FORM_URL


## The prefill field id of the form's details question (--feedback-entry=
## override, else FeedbackData.DETAILS_ENTRY; "" = open the form unfilled).
static func details_entry() -> String:
	return GameState.feedback_entry if GameState.feedback_entry != "" else FeedbackData.DETAILS_ENTRY


## True when a form link is set: the Feedback buttons are shown.
static func enabled() -> bool:
	return form_url() != ""


## The link that opens the form with `report` prefilled ("" when not set up).
static func url_for(report: String) -> String:
	var base := form_url()  # The form's .../viewform link.
	if base == "":
		return ""
	var entry := details_entry()  # "entry.N" of the details question.
	if entry == "":
		return base
	return base + FeedbackData.PREFILL_QUERY + entry + "=" + report.uri_encode()


## True when a link may be opened now: set up, a real window, not the autotest.
static func can_open() -> bool:
	return enabled() and not GameState.autotest and DisplayServer.get_name() != "headless"


# =====================================================================================
# Contexts (read-only snapshots of where the button was pressed)
# =====================================================================================

## The main menu's context.
static func menu_context() -> Dictionary:
	return {"where": "menu"}


## The pause menu's context: the run in progress (`game`; null = the place only).
static func pause_context(game: Game) -> Dictionary:
	if game == null:
		return {"where": "pause"}
	var dif := game.difficulty  # The one difficulty path.
	return {
		"where": "pause",
		"stage": String(game.stage_def.get("display_name", "")),
		"time": game.elapsed,
		"character": game.character.display_name(),
		"difficulty": dif.difficulty_name(),
		"hyper": dif.is_hyper(),
		"modifiers": dif.modifier_names(),
		"volleys": game.volleys_on,
	}


## The results card's context from the finished run's `summary`
## (Game.build_summary()).
static func results_context(summary: Dictionary) -> Dictionary:
	var boss_state := "never came"  # The stage boss: slain / alive / never came.
	if bool(summary.get("boss_defeated", false)):
		boss_state = "slain"
	elif bool(summary.get("boss_spawned", false)):
		boss_state = "alive"
	return {
		"where": "results",
		"victory": bool(summary.get("victory", false)),
		"reason": String(summary.get("reason", "")),
		"stage": String(summary.get("stage_name", "")),
		"time": float(summary.get("time", 0.0)),
		"past_zero": float(summary.get("time_past_zero", 0.0)),
		"left": float(summary.get("time_remaining", 0.0)),
		"kills": int(summary.get("kills", 0)),
		"level": int(summary.get("level", 1)),
		"boss": String(summary.get("boss_name", "")),
		"boss_state": boss_state,
		"character": String(summary.get("character_name", "")),
		"difficulty": String(summary.get("difficulty_name", "")),
		"hyper": bool(summary.get("hyper", false)),
		"modifiers": summary.get("modifier_names", PackedStringArray()),
	}


# =====================================================================================
# The report
# =====================================================================================

## The report for `context` (one of the *_context() dictionaries): three plain
## lines, at most FeedbackData.REPORT_MAX_CHARS characters.
static func build(context: Dictionary) -> String:
	var text := "\n".join(PackedStringArray([_device_line(), _where_line(context), _settings_line(context)]))
	if text.length() > FeedbackData.REPORT_MAX_CHARS:
		text = text.left(FeedbackData.REPORT_MAX_CHARS - FeedbackData.CUT_MARK.length()) + FeedbackData.CUT_MARK
	return text


## First line: game version, platform, the browser (Web only), window size, touch.
static func _device_line() -> String:
	var parts := PackedStringArray()  # The line's parts.
	parts.append("%s v%s" % [FeedbackData.GAME_NAME, str(ProjectSettings.get_setting("application/config/version", "dev"))])
	parts.append(OS.get_name())
	var ua := _user_agent()  # "" off the Web.
	if ua != "":
		parts.append(ua)
	var win := DisplayServer.window_get_size()  # Window size (px).
	parts.append("screen %dx%d" % [win.x, win.y])
	parts.append("touch %s" % ("yes" if TouchSupport.is_mobile() else "no"))
	return FeedbackData.SEP.join(parts)


## Web build: the browser's user agent (cut to USER_AGENT_MAX_CHARS); "" elsewhere.
static func _user_agent() -> String:
	if not OS.has_feature("web") or DisplayServer.get_name() == "headless":
		return ""
	var v: Variant = JavaScriptBridge.eval("(typeof navigator !== 'undefined' && navigator.userAgent) || ''", true)
	var ua := String(v) if typeof(v) == TYPE_STRING else ""  # The answer (a string, or nothing).
	return ua.strip_edges().left(FeedbackData.USER_AGENT_MAX_CHARS)


## Second line: where the button was pressed and the run's facts there.
static func _where_line(c: Dictionary) -> String:
	var where := String(c.get("where", "menu"))  # "menu" / "pause" / "results".
	var parts := PackedStringArray(["Where: " + String(FeedbackData.WHERE_NAMES.get(where, where))])
	if where == "pause" and c.has("stage"):
		parts.append(String(c["stage"]))
		parts.append("%s elapsed" % _clock(float(c["time"])))
		_run_setup(parts, c)
	elif where == "results" and c.has("stage"):
		var reason := String(c["reason"])  # Game.end_run() reason.
		parts.append("%s (%s)" % ["Victory" if bool(c["victory"]) else "Defeat", String(FeedbackData.REASON_NAMES.get(reason, reason))])
		parts.append(String(c["stage"]))
		parts.append("time %s" % _clock(float(c["time"])))
		if bool(c["victory"]):
			parts.append("+%s past 0:00" % _clock(float(c["past_zero"])))
		else:
			parts.append("%s left" % _clock(ceilf(float(c["left"]))))
		parts.append("kills %d" % int(c["kills"]))
		parts.append("level %d" % int(c["level"]))
		parts.append("%s %s" % [String(c["boss"]) if String(c["boss"]) != "" else "boss", String(c["boss_state"])])
		_run_setup(parts, c)
	return FeedbackData.SEP.join(parts)


## Appends the run's character, difficulty, Hyper and modifiers to `parts`.
static func _run_setup(parts: PackedStringArray, c: Dictionary) -> void:
	parts.append(String(c.get("character", "")))
	parts.append(String(c.get("difficulty", "")))
	parts.append("Hyper %s" % ("on" if bool(c.get("hyper", false)) else "off"))
	var mods: PackedStringArray = c.get("modifiers", PackedStringArray())  # Run modifier names.
	parts.append("modifiers: %s" % (", ".join(mods) if not mods.is_empty() else "none"))


## Third line: the settings that change what the player sees.
static func _settings_line(c: Dictionary) -> String:
	var volleys := bool(c.get("volleys", Settings.volleys))  # The run's own value when known.
	return "Settings: " + FeedbackData.SEP.join(PackedStringArray([
		"effects %s" % ("Reduced" if Settings.reduced_effects() else "Full"),
		"reduce motion %s" % ("on" if Settings.reduce_motion else "off"),
		"volleys %s" % ("on" if volleys else "off"),
	]))


## `t` seconds as m:ss.
static func _clock(t: float) -> String:
	var s := maxi(0, int(t))  # Whole seconds.
	return "%d:%02d" % [floori(float(s) / 60.0), s % 60]


# =====================================================================================
# Opening the form
# =====================================================================================

## A Feedback button went down: on the Web build, arms the link for `context`
## so the browser's release event opens it (see the header). Elsewhere nothing.
static func arm(context: Dictionary) -> void:
	if not can_open() or not OS.has_feature("web"):
		return
	web_prepare()
	JavaScriptBridge.eval("window.__necroFb = {url: %s, until: Date.now() + %d, state: 'armed'};" % [
		JSON.stringify(url_for(build(context))), int(FeedbackData.WEB_ARM_SECONDS * 1000.0)], true)


## A Feedback button was pressed: opens the form for `context` (desktop:
## OS.shell_open; Web: the armed tab opens on the release, or OS.shell_open
## when nothing could arm it). Returns true when a link was (or will be)
## opened; false while not set up, under the autotest and headless.
static func open(context: Dictionary) -> bool:
	if not can_open():
		return false
	if OS.has_feature("web"):
		var state: Variant = JavaScriptBridge.eval("(window.__necroFb && Date.now() <= window.__necroFb.until && window.__necroFb.state) || ''", true)
		var st := String(state) if typeof(state) == TYPE_STRING else ""  # "armed" / "opened" / "cancelled" / "".
		if st == "opened":
			JavaScriptBridge.eval("window.__necroFb = null;", true)
			return true
		if st == "armed" and InputHints.device() != InputHints.Device.PAD:
			return true  # A key press: its key-up opens the tab.
		JavaScriptBridge.eval("window.__necroFb = null;", true)
	OS.shell_open(url_for(build(context)))
	return true


## Web build: installs the page listener that opens an armed link inside the
## browser's release event (once per page; called when a Feedback button is
## made, so the press-down position is known). No-op elsewhere.
static func web_prepare() -> void:
	if not OS.has_feature("web") or DisplayServer.get_name() == "headless":
		return
	var slop := FeedbackData.WEB_TAP_SLOP_PX  # Drag-off distance (CSS px).
	JavaScriptBridge.eval("""(function () {
	var w = window;
	if (w.__necroFbHooked) { return; }
	w.__necroFbHooked = true;
	w.__necroFb = null;
	w.__necroFbDown = null;
	w.addEventListener('pointerdown', function (e) { w.__necroFbDown = [e.clientX, e.clientY]; }, true);
	var fire = function (e) {
		var f = w.__necroFb;
		if (!f || f.state !== 'armed') { return; }
		if (Date.now() > f.until) { w.__necroFb = null; return; }
		if (e.type === 'pointerup' && w.__necroFbDown) {
			var dx = e.clientX - w.__necroFbDown[0], dy = e.clientY - w.__necroFbDown[1];
			if (dx * dx + dy * dy > %f) { f.state = 'cancelled'; return; }
		}
		var tab = w.open(f.url, '_blank');
		if (tab) { try { tab.opener = null; } catch (err) {} f.state = 'opened'; }
	};
	['pointerup', 'touchend', 'mouseup', 'keyup'].forEach(function (t) { w.addEventListener(t, fire, true); });
})();""" % (slop * slop), true)


# =====================================================================================
# Autotest
# =====================================================================================

## The autotest's feedback line: whether a form link is set, and the length
## of the three sample reports (main menu, pause with `game`, results with
## `summary`), built headless. Nothing is ever opened under the autotest.
static func summary_line(game: Game, summary: Dictionary) -> String:
	var menu := build(menu_context()).length()  # Characters of each sample.
	var pause := build(pause_context(game)).length()
	var results := build(results_context(summary)).length()
	return "url_set=%s | report_chars=%d/%d/%d (main menu / pause / results samples built, max %d) | url_chars=%d | opened=%s" % [
		str(enabled()), menu, pause, results, FeedbackData.REPORT_MAX_CHARS,
		url_for(build(results_context(summary))).length(), "yes" if can_open() else "never (autotest)"]
