## VigridDirector — the stage mechanics of VIGRID, THE LAST FIELD (Stage 18 in
## the final order, the finale of the Hall of the Slain; temporarily Act XI;
## GDD §15.0 "Vigrid, the Last Field (phase 2)"; owner-approved proposal "Stage
## 18: Vigrid, the Last Field": "The plain where the last battle is fought,
## under a sky going out ... the light fades zone by zone, and the Reckoning's
## dark arrives early in the last zone"), owned and stepped by EnemyDirector on
## a stage whose STAGE has a "vigrid" config (VigridStage.VIGRID; null
## elsewhere). The four zones are MarchDirector's (the clock is authoritative:
## the Frozen Sea, the Ash Plain, the Giants' March, the Field of Vigrid); the
## act's shared rules (the Long Winter, Berserkergang, the Rune-Stones,
## Ragnarok) are Game.norse's. This director runs:
##   * THE FADING LIGHT: at every zone change from the second zone on, the dark
##     takes the lit brazier FARTHEST from the necromancer (LongWinter.put_out(),
##     the one douse path: relit as any brazier), so the warmth left is the
##     warmth fought over; the look (VigridLight: the sky going out, a darkness
##     with pools of light round the lit braziers and the necromancer, its
##     share light["dark_by_zone"] per zone) is drawing only, never headless.
##   * THE EARLY DARK (the Reckoning's dark arrives early in the last zone):
##     from vanguard["from"] the darkness turns Ragnarok's red (drawing) and a
##     VANGUARD of fire-giants steps out of the south edge of the spawn ring
##     every vanguard["every"] s until the boss comes (the shared fire-giant,
##     as Ragnarok's own march; under the hard cap).
##   * THE MINIBOSS: the "muspel_giant" timeline event sends the Fire-Giant of
##     the south from the south edge with his escort (MuspelGiantKit registers
##     him for the HUD bar; ChestManager drops his chest).
##   * THE HUD OBJECTIVE while the miniboss fights and through Odin's phases.
##   * The army bot's push out of the burning ground (danger_push(): the
##     pooled enemy fire patches of the miniboss and Ragnarok).
## Deterministic: no RNG (the farthest brazier, the south edge). Stats:
## vigrid_dark_took, vigrid_vanguard, muspel_sent.
class_name VigridDirector
extends Node2D

## Owning run.
var game: Game
## The stage's config (VigridStage.VIGRID).
var config: Dictionary = {}
## Log of events, "m:ss name" (autotest summary).
var fired: Array[String] = []
## Zone index the Fading Light last saw (MarchDirector.zone_index).
var _zone: int = 0
## Game time (s) of the vanguard's next march (INF = none left).
var _next_vanguard: float = INF
## Report only: px from the nearest brazier beyond which the necromancer
## counts as far from every fire (the army bot's warmth reach).
const FIRELESS_PX: float = 900.0
## The darkness layer (null headless).
var light: VigridLight = null


func _ready() -> void:
	name = "VigridDirector"
	var v: Dictionary = config.get("vanguard", {})
	_next_vanguard = float(v.get("from", INF))
	if DisplayServer.get_name() != "headless":
		light = VigridLight.new(game, config.get("light", {}))
		add_child(light)


## Per-tick update (EnemyDirector.step()): the zone changes, the vanguard.
func step(delta: float) -> void:
	var march := game.enemies.march
	var z := march.zone_index if march != null else 0
	while _zone < z:
		_zone += 1
		_move_camp()
		_dark_takes()
	_sample_warmth(delta)
	if light != null:
		light.zone = _zone
		light.early_dark = game.elapsed >= float((config.get("vanguard", {}) as Dictionary).get("from", INF))
	if game.elapsed >= _next_vanguard:
		var v: Dictionary = config["vanguard"]
		if game.elapsed >= float(v.get("until", INF)):
			_next_vanguard = INF
		else:
			_next_vanguard = game.elapsed + float(v["every"])
			_march_vanguard(v)


## The war-camp moves with the battle: every brazier is set up again at its
## map point (the STAGE long_winter "points") round the necromancer where the
## new zone begins, burning or out as it was (LongWinter.move_to()).
func _move_camp() -> void:
	if game.norse == null or not game.norse.winter.enabled:
		return
	var w := game.norse.winter
	var pts: Array = w.cfg.get("points", [])
	var p := game.player.position
	for i in mini(pts.size(), w.braziers.size()):
		w.move_to(i, p + (pts[i] as Vector2))
	_log("camp_moves")


## Report only: how far the necromancer stands from the nearest brazier
## (vigrid_fire_px_s: px x s, for the average) and the seconds he is beyond
## the army bot's warmth reach from every one (vigrid_fireless_s).
func _sample_warmth(delta: float) -> void:
	if game.norse == null or game.norse.winter.braziers.is_empty():
		return
	var best := INF
	for b in game.norse.winter.braziers:
		best = minf(best, b.pos.distance_to(game.player.position))
	game.stat_add("vigrid_fire_px_s", best * delta)
	if best > FIRELESS_PX:
		game.stat_add("vigrid_fireless_s", delta)


## The dark takes the lit brazier farthest from the necromancer.
func _dark_takes() -> void:
	if game.norse == null:
		return
	var w := game.norse.winter
	var p := game.player.position
	var best := -1
	var best_d := -1.0
	for i in w.braziers.size():
		var b := w.braziers[i]
		if not b.lit:
			continue
		var dsq := b.pos.distance_squared_to(p)
		if dsq > best_d:
			best_d = dsq
			best = i
	if best >= 0 and w.lit_count() > int(config.get("keep_lit", 1)) and w.put_out(best, "the_dark"):
		game.stat_add("vigrid_dark_took", 1.0)
		game.enemies.show_banner("The light fades over Vigrid: the dark takes a brazier. Relight it, or hold the fires you have")
		_log("dark_takes")


## The vanguard of the south: fire-giants out of the south edge of the ring.
func _march_vanguard(v: Dictionary) -> void:
	var n := int(v.get("giants", 1))
	var south := game.enemies.ring_point(PI * 0.5)  # The ring's southmost point (screen down).
	var sent := 0
	for i in n:
		if game.enemies.regular_alive() >= game.enemies.hard_cap():
			break
		var off := (float(i) - float(n - 1) * 0.5) * 90.0
		if game.enemies.spawn_at(String(v.get("kind", NorseEnemyData.FIRE_GIANT)), south + Vector2(off, 0.0), false) != null:
			sent += 1
	if sent > 0:
		game.stat_add("vigrid_vanguard", float(sent))
		game.enemies.show_banner(String(v.get("banner", "The fire-giants of the south march early!")))
		_log("vanguard")


## A timeline event of this stage (EnemyDirector._run_event()).
func start_event(ev: Dictionary) -> void:
	match String(ev["type"]):
		"muspel_giant":
			_send_muspel(ev)
	game.enemies.show_banner(String(ev["banner"]))


## Sends the Fire-Giant of the south from the south edge with his escort.
func _send_muspel(ev: Dictionary) -> void:
	var at := game.enemies.ring_point(PI * 0.5)
	var e := game.enemies.spawn_at(String(ev["kind"]), at, false)
	if e == null:
		return
	game.stat_add("muspel_sent", 1.0)
	var k := 0
	for grp: Dictionary in ev.get("escort", []):
		for _n in int(grp["count"]):
			if game.enemies.regular_alive() >= game.enemies.hard_cap():
				break
			k += 1
			game.enemies.spawn_at(String(grp["kind"]), e.position + Vector2.from_angle(TAU * float(k) / 7.0) * (e.radius + 40.0), bool(grp["elite"]))
	_log("muspel_giant")


## HUD objective while the miniboss fights or Odin's phases run ("" = none).
func objective_override() -> String:
	var mb := game.enemies.miniboss_alive()
	if mb != null and mb.kit is MuspelGiantKit:
		return "The Fire-Giant of the South: keep your ring out of his burning tracks"
	var b := game.enemies.boss as BossOdin
	if b != null and b.active:
		match b.phase:
			BossOdin.Phase.WOLF:
				return "THE WOLF: wound Fenrir before he swallows your army"
			BossOdin.Phase.ALLFATHER:
				return "THE ALL-FATHER: kill his ravens; Grave Step or a Bone Wall turns Gungnir"
			BossOdin.Phase.RAGNAROK:
				return "RAGNAROK: bring one of them down, and the other follows"
	return ""


## Autopilot hint: out of the burning ground (the pooled enemy fire patches).
func danger_push(p: Vector2) -> Vector2:
	if game.enemies.province_haz == null:
		return Vector2.ZERO
	return game.enemies.province_haz.danger_push(p)


## One-line autotest summary.
func summary_line() -> String:
	var st := game.stats
	var lw := game.norse.winter if game.norse != null else null
	return "the dark took %d braziers (lit at the end %d/%d), camp moves %d | nearest fire avg %d px, beyond reach %ds | vanguard fire-giants %d | miniboss %s, burning footprints %d, burning stomps %d, burns on you %d / on summons %d" % [
		int(st.get("vigrid_dark_took", 0.0)), lw.lit_count() if lw != null else 0, lw.braziers.size() if lw != null else 0,
		int(st.get("braziers_moved", 0.0)), int(float(st.get("vigrid_fire_px_s", 0.0)) / maxf(game.elapsed, 1.0)), int(st.get("vigrid_fireless_s", 0.0)),
		int(st.get("vigrid_vanguard", 0.0)),
		("killed in %ds" % int(st.get("muspel_kill_time", 0.0))) if st.has("muspel_kill_time") else ("spawned, not killed" if float(st.get("muspel_spawned", 0.0)) > 0.0 else "not met"),
		int(st.get("muspel_tracks", 0.0)), int(st.get("muspel_stomp_fires", 0.0)),
		int(st.get("player_dmg_from_" + VigridEnemyData.TRACK_SOURCE, 0.0)), int(st.get("summon_dmg_from_" + VigridEnemyData.TRACK_SOURCE, 0.0))]


## Records an event for the autotest summary.
func _log(event_name: String) -> void:
	var s := int(game.elapsed)
	fired.append("%d:%02d %s" % [floori(float(s) / 60.0), s % 60, event_name])
