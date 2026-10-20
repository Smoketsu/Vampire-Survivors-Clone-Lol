## HudBanners — the HUD's one banner slot (menu modernization wave 2,
## numbers in InRunUiData): every in-run banner shows here, ONE at a time,
## from a short queue, on a UiTheme.ribbon() plate whose accent carries its
## meaning:
##   * gold    : an evolution or a synergy (Hud.announce() titles with
##               GOLD_TITLE_WORDS);
##   * crimson : a Covenant / boss event (EnemyDirector.show_banner(), polled
##               from banner_text / banner_until);
##   * violet  : anything else (zones, revives, and event banners that are
##               good news for the player: CALM_EVENT_WORDS).
## A banner is a small LABEL kicker (the announcement's title), a one-line
## headline (Jacquard 24, the TITLE tier) on the ribbon, and an optional
## one-line BODY sub-line (the announcement's description). A headline too
## wide for BANNER_MAX_WIDTH is split at its first colon (the rest becomes
## the sub-line), then drawn in a smaller tier (HEADER, then NAME), then
## trimmed with an ellipsis, so it never wraps.
## Each banner fades and rises in, holds (event banners until their
## banner_until, announcements ANNOUNCE_HOLD s), and fades while rising out;
## a queued banner cuts the current one short once it has been seen for
## BANNER_MIN_SHOW s. Timing is GAME time (game.elapsed), so a banner raised
## while a panel pauses the run waits, and the whole slot is hidden whenever
## the run is not PLAYING (level-up, chest, pause, end): nothing shows
## through those panels. The slot sits just under the top-centre HUD block
## (timer, zone, objective, boss bars). Read-only: it never changes the run.
class_name HudBanners
extends Control

## Owning run (read: elapsed, run_state, the enemy director's banner).
var game: Game
## The top-centre HUD block the slot sits under (its bottom edge is read).
var anchor_box: Control
## Banners waiting: [{kicker, headline, sub, accent, color, hold}].
var _queue: Array[Dictionary] = []
## The banner on show ({} = none).
var _cur: Dictionary = {}
## Game time the current banner started showing.
var _shown_at: float = 0.0
## Game time the current banner's hold ends (its fade-out starts then).
var _end_at: float = 0.0
## Game time the current banner's fade-out started (-1 = still holding).
var _closing_at: float = -1.0
## Top (px) of the slot for the current banner (fixed while it shows).
var _top: float = 0.0
## Last event banner text seen on the enemy director.
var _last_event_text: String = ""
## Last event banner end time seen on the enemy director (game s).
var _last_event_until: float = -1.0
## The banner's whole column (kicker, ribbon, sub-line); moved and faded.
var _stack: VBoxContainer
## Small LABEL-tier kicker above the ribbon ("EVOLUTION").
var _kicker: Label
## The ribbon plate.
var _ribbon: PanelContainer
## The one-line headline on the ribbon.
var _headline: Label
## The one-line sub-line under the ribbon.
var _sub: Label


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stack = VBoxContainer.new()
	_stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stack.add_theme_constant_override("separation", 2)
	_stack.anchor_left = 0.5
	_stack.anchor_right = 0.5
	var half := InRunUiData.BANNER_MAX_WIDTH * 0.5 + 80.0  # Half the column's width (px).
	_stack.offset_left = -half
	_stack.offset_right = half
	_stack.grow_horizontal = Control.GROW_DIRECTION_BOTH  # Stays centred if it ever outgrows its width.
	_stack.visible = false
	add_child(_stack)
	_kicker = UiTheme.tier_label("", UiTheme.Tier.LABEL, UiTheme.TEXT_DIM)
	_kicker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_stack.add_child(_kicker)
	_ribbon = UiTheme.ribbon("violet")
	_ribbon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_stack.add_child(_ribbon)
	_headline = UiTheme.title("")
	_ribbon.add_child(_headline)
	_sub = UiTheme.tier_label("", UiTheme.Tier.BODY, UiTheme.TEXT)
	_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_sub.clip_text = true
	_sub.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_stack.add_child(_sub)


## Queues an announcement (a synergy awakening, an evolution, a battle
## zone, a revive): `title` is the kicker, `item_name` the headline in
## `color`, `desc` the sub-line.
func push_announce(title: String, item_name: String, desc: String, color: Color) -> void:
	var gold := false  # Evolution / synergy: the gold ribbon.
	for w: String in InRunUiData.GOLD_TITLE_WORDS:
		gold = gold or title.to_upper().contains(w)
	_enqueue({"kicker": title, "headline": item_name, "sub": desc, "accent": "gold" if gold else "violet",
		"color": UiTheme.TEXT_GOLD if gold else color.lightened(0.25), "hold": InRunUiData.ANNOUNCE_HOLD})


## Queues a notice (co-op, CoopUi.notice()): kicker `kicker`, headline
## `headline`, sub-line `sub`, on the `accent` ribbon ("violet" or
## "crimson"; the headline in that accent's text colour), held `hold` game s.
func push_notice(kicker: String, headline: String, sub: String, accent: String, hold: float) -> void:
	_enqueue({"kicker": kicker, "headline": headline, "sub": sub, "accent": accent,
		"color": UiTheme.HEADER_TEXT.get(accent, UiTheme.TEXT), "hold": hold})


## Queues an event banner `text` for `hold` game seconds (crimson unless
## it is good news for the player).
func push_event(text: String, hold: float) -> void:
	var calm := false  # Good news: the violet ribbon.
	var low := text.to_lower()
	for w: String in InRunUiData.CALM_EVENT_WORDS:
		calm = calm or low.contains(w)
	_enqueue({"kicker": "", "headline": text, "sub": "", "accent": "violet" if calm else "crimson",
		"color": UiTheme.TEXT if calm else UiTheme.HEADER_TEXT["crimson"], "hold": hold})


## Adds `e` to the queue, or extends the banner on show when it repeats it.
func _enqueue(e: Dictionary) -> void:
	if not _cur.is_empty() and String(_cur["headline"]) == String(e["headline"]) and _closing_at < 0.0:
		_end_at = maxf(_end_at, game.elapsed + float(e["hold"]))
		return
	_queue.append(e)
	while _queue.size() > InRunUiData.BANNER_QUEUE_MAX:
		_queue.pop_front()


## Picks up a new (or extended) event banner from the enemy director.
func _poll_event() -> void:
	var ed := game.enemies
	if ed == null:
		return
	var text := ed.banner_text
	var until := ed.banner_until
	if text == _last_event_text and is_equal_approx(until, _last_event_until):
		return
	_last_event_text = text
	_last_event_until = until
	if text != "" and until > game.elapsed:
		push_event(text, until - game.elapsed)


func _process(_delta: float) -> void:
	if game == null:
		return
	_poll_event()
	visible = game.run_state == Game.RunState.PLAYING  # Hidden under every panel.
	var now := game.elapsed
	if _cur.is_empty():
		if _queue.is_empty():
			_stack.visible = false
			return
		_start(_queue.pop_front(), now)
	if _closing_at < 0.0 and (now >= _end_at or (not _queue.is_empty() and now - _shown_at >= InRunUiData.BANNER_MIN_SHOW)):
		_closing_at = now
	var a := 1.0  # Opacity.
	var dy := 0.0  # Offset from the rest position (px; + = lower).
	var k_in := clampf((now - _shown_at) / InRunUiData.BANNER_IN, 0.0, 1.0)  # 0..1 into the entrance.
	a = k_in
	dy = InRunUiData.BANNER_RISE * (1.0 - k_in) * (1.0 - k_in)  # Ease out.
	if _closing_at >= 0.0:
		var k_out := (now - _closing_at) / InRunUiData.BANNER_OUT  # 0..1 into the exit.
		if k_out >= 1.0:
			_cur = {}
			_stack.visible = false
			return
		a *= 1.0 - k_out
		dy -= InRunUiData.BANNER_RISE_OUT * k_out * k_out
	_stack.modulate.a = a
	_stack.position.y = roundf(_top + dy)


## Shows banner `e` from game time `now`: fills and fits its lines, picks
## its ribbon accent and fixes the slot's top under the HUD block.
func _start(e: Dictionary, now: float) -> void:
	_cur = e
	_shown_at = now
	_end_at = now + float(e["hold"])
	_closing_at = -1.0
	_kicker.text = String(e["kicker"])
	_kicker.visible = _kicker.text != ""
	_kicker.add_theme_color_override("font_color", UiTheme.TEXT_GOLD if String(e["accent"]) == "gold" else UiTheme.TEXT_DIM)
	_ribbon.add_theme_stylebox_override("panel", UiTheme.style("ribbon", String(e["accent"])))
	var fit := _fit(String(e["headline"]))  # [headline, rest, tier].
	var tier: UiTheme.Tier = fit[2]  # The tier the headline fits in.
	UiTheme.set_tier(_headline, tier)
	_headline.text = String(fit[0])
	_headline.add_theme_color_override("font_color", e["color"] as Color)
	var sub := String(e["sub"])
	if String(fit[1]) != "":
		sub = String(fit[1]) if sub == "" else String(fit[1]) + "  " + sub
	_sub.text = sub
	_sub.visible = sub != ""
	_sub.custom_minimum_size = Vector2(InRunUiData.BANNER_MAX_WIDTH + 120.0, 0)
	_top = InRunUiData.BANNER_TOP
	if anchor_box != null and anchor_box.is_visible_in_tree():
		_top = maxf(_top, anchor_box.position.y + anchor_box.get_combined_minimum_size().y + 6.0)
	_stack.position.y = _top
	_stack.modulate.a = 0.0
	_stack.visible = true


## Fits `text` on one line of at most BANNER_MAX_WIDTH px: returns
## [headline, rest moved to the sub-line ("" = none), UiTheme.Tier].
func _fit(text: String) -> Array:
	var head := text
	var rest := ""
	if _width(head, UiTheme.Tier.TITLE) > InRunUiData.BANNER_MAX_WIDTH and text.contains(": "):
		var at := text.find(": ")
		head = text.substr(0, at)
		rest = text.substr(at + 2).strip_edges()
		if rest != "":
			rest = rest.substr(0, 1).to_upper() + rest.substr(1)
	for t: UiTheme.Tier in [UiTheme.Tier.TITLE, UiTheme.Tier.HEADER, UiTheme.Tier.NAME]:
		if _width(head, t) <= InRunUiData.BANNER_MAX_WIDTH:
			return [head, rest, t]
	while head.length() > 4 and _width(head + "…", UiTheme.Tier.NAME) > InRunUiData.BANNER_MAX_WIDTH:
		head = head.substr(0, head.length() - 1)
	return [head.strip_edges() + "…", rest, UiTheme.Tier.NAME]


## Width (px) of `s` drawn in tier `t` (measured with the headline's font).
func _width(s: String, t: UiTheme.Tier) -> float:
	UiTheme.set_tier(_headline, t)
	var f := _headline.get_theme_font("font")
	var fs := _headline.get_theme_font_size("font_size")
	return f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x if f != null else 0.0
