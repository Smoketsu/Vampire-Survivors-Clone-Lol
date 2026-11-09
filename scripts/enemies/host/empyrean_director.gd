## EmpyreanDirector — the stage systems of THE EMPYREAN (temporary Act XIII stage
## 39, final stage 30, the Celestial Host's finale and the end of Part One; GDD
## §15.0 "The Empyrean (Act XIII phase 2)"; owner-approved proposal
## docs/proposals/LAST_SIX_ACTS.md section X, "Stage 30: The Empyrean"), owned
## and stepped by EnemyDirector on a stage whose STAGE has an "empyrean" config
## (EmpyreanStage.EMPYREAN; `game.enemies.empyrean`, null elsewhere). The
## zones' floors and obstacles are MarchDirector's; Judgment, Hallowed Light,
## Grace and the Last Trumpet the shared HostRules'. Here:
##   * THE CHOIR (the stage mechanic, "the hymn of the whole Host can be heard;
##     every Choir Angel alive adds to the light's width"): every tick the Light's
##     width_mult carries a factor 1 + per_angel x min(live Choir Angels,
##     max_angels) (HostRules.choir: the one count, read once here), applied
##     RELATIVELY (the old factor divided out, the new one multiplied in) so the
##     Last Trumpet's widening still multiplies on top. A shaft takes its width
##     when it opens (HallowedLight.add_shaft()).
##   * THE HERALD OF THE SEVENTH TRUMPET ("seventh_herald" event): the stage
##     miniboss, spawned on the spawn ring with an escort and tracked
##     (objective, kill time); his kit calls the earlier zones' squads, registers
##     the HUD bar and pays his XP.
##   * THE LAST WORD (the stage's achievement): when the stage boss (the Voice)
##     falls on the Empyrean, the run stat LAST_WORD_STAT is set (MetaProgress
##     counts the runs, lifetime last_word_runs, MetaData "the_last_word").
## Deterministic: only the seeded global RNG (where the Herald comes in). Stats:
## empyrean_zones, choir_peak, choir_seconds (s with at least one Choir Angel
## alive), choir_width_peak (the factor's highest, x100), seventh_herald_spawned,
## seventh_herald_killed, LAST_WORD_STAT.
class_name EmpyreanDirector
extends Node

## Run stat set when The Last Word is earned (MetaProgress reads it).
const LAST_WORD_STAT: String = "empyrean_last_word"

## Owning run.
var game: Game
## The stage's config (EmpyreanStage.EMPYREAN).
var config: Dictionary = {}
## Log of the stage's events, "m:ss name" (autotest summary).
var fired: Array[String] = []
## Index of the current zone (-1 before the first).
var zone_index: int = -1
## The Choir's factor now on the Light's width_mult (1 = none).
var choir_factor: float = 1.0
## Most Choir Angels alive at once this run.
var choir_peak: int = 0
## True once the stage boss fell this run.
var boss_down: bool = false
## True once The Last Word was earned this run.
var last_word: bool = false
## "m:ss" the Herald of the Seventh Trumpet fell ("" while alive / never spawned).
var herald_time: String = ""
## True once the boss signal is connected.
var _hooked: bool = false
## The Herald of the Seventh Trumpet once spawned (null before / after; generation-checked).
var _herald: Enemy = null
## Generation of `_herald` when he spawned.
var _herald_gen: int = 0


## Per-tick update (EnemyDirector, after the MarchDirector).
func step(delta: float) -> void:
	var now := game.elapsed
	if not _hooked:
		_hooked = true
		game.enemies.boss_defeated.connect(_on_boss_defeated)
	var zones: Array = config.get("zones", [])
	while zone_index + 1 < zones.size() and now >= float(zones[zone_index + 1]):
		zone_index += 1
		game.stat_add("empyrean_zones", 1.0)
		_log("zone_%d" % (zone_index + 1))
	_choir(delta)
	if _herald != null and not (_herald.active and _herald.generation == _herald_gen):
		_herald = null
		game.stat_add("seventh_herald_killed", 1.0)
		herald_time = _clock()
		_log("herald_killed")


# =====================================================================================
# The Choir
# =====================================================================================

## THE CHOIR: the Light's width carries 1 + per_angel x the live Choir Angels
## (at most max_angels), applied relatively.
func _choir(delta: float) -> void:
	var host := game.host
	if host == null or not host.enabled:
		return
	var n := host.choir.size()  # The one count (HostRules.note_spawn() / note_gone()).
	if n > choir_peak:
		choir_peak = n
		game.stats["choir_peak"] = float(n)
	if n > 0:
		game.stat_add("choir_seconds", delta)
	var f := 1.0 + float(config.get("per_angel", 0.0)) * float(mini(n, int(config.get("max_angels", 0))))
	if not is_equal_approx(f, choir_factor):
		host.light.width_mult *= f / choir_factor
		choir_factor = f
		game.stats["choir_width_peak"] = maxf(float(game.stats.get("choir_width_peak", 100.0)), roundf(100.0 * f))


# =====================================================================================
# The Herald of the Seventh Trumpet
# =====================================================================================

## Runs an Empyrean timeline event (EnemyDirector forwards the
## "seventh_herald" type; keys in EmpyreanStage.EVENTS).
func start_event(ev: Dictionary) -> void:
	if String(ev["type"]) != "seventh_herald":
		return
	var a := randf() * TAU
	var e := game.enemies.spawn_at(String(ev.get("kind", EmpyreanEnemyData.HERALD_OF_THE_SEVENTH_TRUMPET)), game.enemies.ring_point(a), bool(ev.get("elite", false)))
	if e == null:
		return
	_herald = e
	_herald_gen = e.generation
	game.stat_add("seventh_herald_spawned", 1.0)
	game.shake(6.0)
	Sfx.play("boss_impact", e.position, 0.5)
	var side := Vector2.from_angle(a).orthogonal()
	var escort: Array = ev.get("escort", [])
	var k := 0
	for grp: Dictionary in escort:
		for j in int(grp.get("count", 0)):
			var at := e.position + side * (float(k % 6) - 2.5) * 26.0 - Vector2.from_angle(a) * (40.0 + 18.0 * float(k / 6))
			game.enemies.spawn_at(String(grp["kind"]), at, false)
			k += 1
	if ev.has("banner"):
		game.enemies.show_banner(String(ev["banner"]))
	_log("seventh_herald")


## The HUD objective while the Herald of the Seventh Trumpet stands ("" otherwise).
func objective_override() -> String:
	if _herald != null and _herald.active and _herald.generation == _herald_gen:
		return String(config.get("herald_objective", ""))
	return ""


# =====================================================================================
# The Last Word
# =====================================================================================

## The stage boss fell (EnemyDirector.boss_defeated): The Last Word when it is
## the Voice, on the Empyrean.
func _on_boss_defeated() -> void:
	if boss_down:
		return
	boss_down = true
	_log("boss_down")
	if not (game.enemies.boss is BossVoice) or String(game.stage_def.get("id", "")) != EmpyreanStage.ID:
		return
	last_word = true
	game.stats[LAST_WORD_STAT] = 1.0
	game.enemies.show_banner(String(config.get("last_word_banner", "THE LAST WORD")))
	_log("last_word")


# =====================================================================================
# Report
# =====================================================================================

## One autotest summary line of the stage's systems.
func summary_line() -> String:
	var st := game.stats
	return "zones %d | the choir: peak %d angels, %.0f s sung, widest x%.2f | herald of the seventh trumpet spawned %d, killed %d%s | the last word %s | events: %s" % [
		zone_index + 1, choir_peak, float(st.get("choir_seconds", 0.0)), float(st.get("choir_width_peak", 100.0)) / 100.0,
		int(st.get("seventh_herald_spawned", 0.0)), int(st.get("seventh_herald_killed", 0.0)),
		(" at " + herald_time) if herald_time != "" else "",
		"EARNED" if last_word else ("lost" if boss_down else "open"), ", ".join(fired)]


## Appends "m:ss name" to the event log.
func _log(what: String) -> void:
	fired.append("%s %s" % [_clock(), what])


## The current game clock as "m:ss".
func _clock() -> String:
	var t := int(game.elapsed)
	return "%d:%02d" % [t / 60, t % 60]
