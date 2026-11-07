## DemoMode — the ONE path of the demo switch (owner request "let's do a demo
## mode switch", Nov 2026; GDD §15.0 "Demo mode (owner request, Nov 2026)").
## on() is true only in a build exported with DemoData.FEATURE_TAG (the "Web
## Demo" preset) or with the test flag --demo (GameState.demo_flag); in every
## other build each helper below answers "allowed" / unchanged, so the full
## game stays bit for bit as before (same-seed autotest summaries).
## The rules it serves, each asked from one place:
##   allows_stage(id)     — Meta.is_stage_unlocked() (stage select, co-op
##                          lobby, the victory card's Next, award_run()'s
##                          "stage opened"): a stage of an act outside
##                          DemoData.ACTS is locked; lock_line() is its text.
##   allows_item(id)      — Unlocks.is_open() / offerable_with() /
##                          newly_unlocked() / lock_text(): a lockable item
##                          not in DemoData.OPEN_ITEMS is never offered, never
##                          unlocked by a demo run and reads "Full game".
##   allows_character(id) — Meta.is_character_unlocked() and
##                          CharacterModifiers.unlock_text(): a character whose
##                          starting spell is full game stays locked.
##   save_path(path)      — Meta's save file name (DemoData.SAVE_SUFFIX).
##   coop_version(v)      — CoopNet.game_version() (DemoData.COOP_VERSION_SUFFIX).
## The gates hold even when a full-game save backup code is restored into the
## demo: they are rules of the build, not of the save. The UI (the title
## screen's badge, the stage select's call to action and Wishlist button) asks
## on() and reads DemoData's words. Nothing here touches gameplay state or RNG.
class_name DemoMode
extends RefCounted


## True when this build / run is the demo (see the header).
static func on() -> bool:
	return OS.has_feature(DemoData.FEATURE_TAG) or GameState.demo_flag


# =====================================================================================
# Content
# =====================================================================================

## True when stage `id` belongs to the demo (its act is in DemoData.ACTS),
## whether or not demo mode is on (the autotest's demo line counts with it).
static func stage_in_demo(id: String) -> bool:
	return StageRegistry.STAGES.has(id) and DemoData.ACTS.has(StageRegistry.act_of(id))


## True when stage `id` may be played in this build: always in the full game,
## only the demo's acts in the demo.
static func allows_stage(id: String) -> bool:
	return not on() or stage_in_demo(id)


## Stage ids the demo allows, in campaign order.
static func demo_stages() -> PackedStringArray:
	var out := PackedStringArray()
	for id: String in StageRegistry.ORDER:
		if stage_in_demo(id):
			out.append(id)
	return out


## Number of acts with stages that the demo leaves out (the call to action).
static func acts_left_out() -> int:
	var n := 0  # Acts not in DemoData.ACTS that hold stages.
	for a: int in StageRegistry.ACTS:
		if not DemoData.ACTS.has(a) and not StageRegistry.stages_of_act(a).is_empty():
			n += 1
	return n


## True when item `id` (a card, ultimate, title or skin family) belongs to the
## demo: not lockable at all (UnlockData), or listed in DemoData.OPEN_ITEMS.
## Independent of on() (the autotest's demo line counts with it).
static func item_in_demo(id: String) -> bool:
	return not UnlockData.UNLOCKS.has(id) or DemoData.OPEN_ITEMS.has(id)


## True when item `id` may be offered / unlocked in this build.
static func allows_item(id: String) -> bool:
	return not on() or item_in_demo(id)


## True when character `id` may be unlocked in this build: its starting spell
## is a demo item (always in the full game).
static func allows_character(id: String) -> bool:
	if not on() or not CharacterData.CHARACTERS.has(id):
		return true
	return item_in_demo(String(CharacterData.CHARACTERS[id]["spell"]))


## The demo's lock line for full-game content (DemoData.LOCK_LINE).
static func lock_line() -> String:
	return DemoData.LOCK_LINE


# =====================================================================================
# Saves and co-op
# =====================================================================================

## Meta's save file for `path`: unchanged in the full game; in the demo the
## DemoData.SAVE_SUFFIX goes before the extension (user://save.cfg ->
## user://save_demo.cfg).
static func save_path(path: String) -> String:
	if not on():
		return path
	return "%s%s.%s" % [path.get_basename(), DemoData.SAVE_SUFFIX, path.get_extension()]


## The co-op game version `v` (CoopNet.game_version()): unchanged in the full
## game, DemoData.COOP_VERSION_SUFFIX appended in the demo.
static func coop_version(v: String) -> String:
	return v + DemoData.COOP_VERSION_SUFFIX if on() else v


# =====================================================================================
# The store link (stage select's Wishlist button)
# =====================================================================================

## True when the Wishlist button is shown: demo on and DemoData.STORE_URL set.
static func store_enabled() -> bool:
	return on() and DemoData.STORE_URL != ""


## The Wishlist button: one word, its tooltip; press-down arms the link on the
## Web build and the press opens it (FeedbackReport.arm_link() / open_link(),
## the shared browser-link path). Never opens under the autotest or headless.
static func store_button() -> Button:
	var b := Button.new()
	b.text = DemoData.CTA_BUTTON
	b.tooltip_text = DemoData.CTA_TOOLTIP
	b.custom_minimum_size = DemoData.CTA_BUTTON_SIZE
	FeedbackReport.web_prepare()  # Web: the page listener knows this press's position.
	b.button_down.connect(func() -> void: FeedbackReport.arm_link(DemoData.STORE_URL))
	b.pressed.connect(func() -> void: FeedbackReport.open_link(DemoData.STORE_URL))
	return b


# =====================================================================================
# UI pieces
# =====================================================================================

## The title screen's small Demo badge: a chamfered soul-teal frame holding
## DemoData.BADGE_TEXT (BODY tier). It ignores the mouse.
static func badge() -> Control:
	var p := PanelContainer.new()
	var sb := UiTheme.box(UiTheme.BG, UiTheme.BORDER_FOCUS, 2)  # Soul-teal border, chamfered corners.
	sb.content_margin_top = 2
	sb.content_margin_bottom = 2
	p.add_theme_stylebox_override("panel", sb)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(UiTheme.tier_label(DemoData.BADGE_TEXT, UiTheme.Tier.BODY, UiTheme.TEXT_GOOD))
	return p


## The stage select's call to action: "N more acts in the full game" in
## soul-teal (BODY), centred.
static func cta_line() -> Control:
	var l := UiTheme.tier_label(DemoData.CTA_TEXT % acts_left_out(), UiTheme.Tier.BODY, UiTheme.TEXT_GOOD)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


# =====================================================================================
# Autotest
# =====================================================================================

## The autotest's demo line: on / off, the acts and stages the demo allows,
## the save file, and `blocked_offers` (NEW cards offered this run that are
## not demo items; must be 0 in a demo run).
static func summary_line(blocked_offers: int) -> String:
	return "on=%s | acts=%s | stages=%s | save=%s | full_game_offers=%d" % [
		str(on()), ",".join(PackedStringArray(DemoData.ACTS.map(func(a: int) -> String: return str(a)))),
		",".join(demo_stages()), save_path(Meta.DEFAULT_PATH), blocked_offers]
