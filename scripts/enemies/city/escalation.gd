## Escalation — THE ESCALATION of the Last Line (Act VIII; GDD §15.0 "The
## escalation"; owner: "the escalation is a plain clock, not the Wanted Level.
## The run climbs from gangs to police to the army to the heroes on fixed
## times, like the other acts. There is no 'cut the comms'"), owned by
## Game.city as `escalation`. THE one clock path:
##   * on an Act VIII stage (STAGE "city"), each tier of `order` (gangs,
##     police, swat, army, heroes, up to the stage's `last`) begins at its
##     `times` entry (elapsed s); tier() / reached() are THE tests every reader
##     asks (the civilians' evacuation, the report, phase 2's stage directors);
##   * `warn` s before each tier a banner warns ("The police are coming") with
##     the tier_alarm sound;
##   * from the "heroes" tier, a Super arrives every `super_every` s, at most
##     `super_max` alive (SuperRoster.call_next()), until 0:00 (then Martial Law
##     brings back the Supers met);
##   * the timeline itself spawns each tier's kinds, as on every stage: this
##     only holds the tier for the HUD badge, the report and the Supers.
## A stage's STAGE "escalation" dictionary overrides any key of
## CityRulesData.ESCALATION (phase 2: each stage's ladder from the proposal's
## caps). Drawn: the HUD badge (a label under the HUD's top-centre block, in the
## tier's colour). Nothing drawn headless.
## Determinism: game time only. Stats: city_tier_<id>, city_tier_warnings.
class_name Escalation
extends RefCounted

## Owning run.
var game: Game
## True on an Act VIII stage: the clock runs.
var enabled: bool = false
## The stage's escalation numbers (ESCALATION with the STAGE's "escalation").
var cfg: Dictionary = {}
## The tier ids this stage climbs, in order (up to cfg "last").
var order: Array[String] = []
## Index into `order` of the current tier (-1 before the first began).
var index: int = -1
## Tier id -> game time (s) it began this run (the report).
var began: Dictionary = {}
## Index of the next tier already warned (-1 = none).
var _warned: int = -1
## Game time (s) of the next Super from the heroes tier (INF until then).
var _next_super: float = INF
## Supers the escalation sent this run.
var supers_sent: int = 0
## True when this build draws (never headless).
var _draws: bool = false
## The HUD's tier badge (null until the HUD exists; never headless).
var _label: Label = null


## Builds the escalation for `p_game`; `p_enabled`: an Act VIII stage.
func _init(p_game: Game, p_enabled: bool) -> void:
	game = p_game
	enabled = p_enabled
	cfg = CityRulesData.ESCALATION.duplicate()
	var over: Dictionary = p_game.stage_def.get("escalation", {})  # The stage's own overrides.
	for key: String in over:
		cfg[key] = over[key]
	var last := String(cfg["last"])
	var times: Dictionary = cfg["times"]
	for t: String in CityRulesData.TIERS:
		if times.has(t):
			order.append(t)
		if t == last:
			break
	_draws = DisplayServer.get_name() != "headless"


# =====================================================================================
# The clock (public API)
# =====================================================================================

## THE test: the current tier id ("" before the first, or off Act VIII).
func tier() -> String:
	return order[index] if index >= 0 else ""


## True once tier `id` has begun this run (false for a tier past the stage's
## last, and off Act VIII).
func reached(id: String) -> bool:
	return began.has(id)


## Game time (s) tier `id` begins on this stage (INF when the stage never
## climbs to it).
func time_of(id: String) -> float:
	return float((cfg["times"] as Dictionary)[id]) if order.has(id) else INF


# =====================================================================================
# Per tick
# =====================================================================================

## Per-tick update (CityRules.step()): the tiers' starts and warnings, the
## heroes' Supers, the HUD badge.
func step(_delta: float) -> void:
	if not enabled:
		return
	var now := game.elapsed
	while index + 1 < order.size() and now >= time_of(order[index + 1]):
		index += 1
		_begin(order[index])
	var nxt := index + 1  # The next tier's index.
	if nxt < order.size() and _warned < nxt and now >= time_of(order[nxt]) - float(cfg["warn"]):
		_warned = nxt
		var banners: Dictionary = cfg["warn_banners"]
		if banners.has(order[nxt]):
			game.enemies.show_banner(String(banners[order[nxt]]))
		game.stat_add("city_tier_warnings", 1.0)
		if game.city != null:
			game.city.play_sound("tier_alarm", game.player.position)
	if now >= _next_super and not game.countdown_finished():
		if game.city.supers.alive_count() < int(cfg["super_max"]):
			game.city.supers.call_next()
			supers_sent += 1
			_next_super = now + float(cfg["super_every"])
		else:
			_next_super = now + 5.0  # A Super still stands: look again shortly.
	if _draws:
		_update_label()


## Tier `id` begins.
func _begin(id: String) -> void:
	began[id] = game.elapsed
	game.stat_add("city_tier_" + id, 1.0)
	if id == "heroes":
		_next_super = game.elapsed  # The first Super arrives with the tier.


# =====================================================================================
# Drawing (visual only; never headless)
# =====================================================================================

## The HUD's tier badge ("Police", in the tier's colour) under the HUD's
## top-centre block; made on first use.
func _update_label() -> void:
	if game.hud == null:
		return
	var id := tier()
	if id == "":
		return
	var text := String((cfg["names"] as Dictionary).get(id, id))
	if _label == null:
		_label = UiTheme.tier_label(text, UiTheme.Tier.NAME, UiTheme.TEXT)
		_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		game.hud.add_child(_label)
		_label.text = ""  # Forces the colour below on first use.
	if _label.text != text:
		_label.text = text
		_label.add_theme_color_override("font_color", (cfg["colors"] as Dictionary).get(id, UiTheme.TEXT))
	var w := game.hud.size.x  # HUD width (layout px).
	_label.size = Vector2(w, _label.get_minimum_size().y)
	_label.position = Vector2(0.0, game.hud.top_centre_bottom() + CityRulesData.BADGE_HUD_GAP)
