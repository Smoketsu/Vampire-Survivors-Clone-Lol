## RavensmoorDirector — the stage systems of Ravensmoor (Stage 19; Act VII, GDD
## §15.0 "Ravensmoor (Act VII phase 2)"; owner-approved proposal
## docs/act7/PROPOSAL.md "Stage 19: Ravensmoor"), owned and stepped by
## EnemyDirector on a stage whose STAGE has a "ravensmoor" config
## (RavensmoorStage.RAVENSMOOR; null elsewhere). The zones are MarchDirector's,
## Bloodfeast, Night Wings, the Blood Moon and the Endless Feast the shared
## CourtRules'. Here:
##   * THE SLEEPING COFFINS ("coffins" waves, one per zone): sleeping_coffin
##     structures placed around the necromancer (never recycled). Broken while
##     closed, each pays coffin_bounty Soul Ash (the run stat objective_ash,
##     the end screen's objectives part). When the Blood Moon RISES (any moon:
##     the clock's, Vargr's or the Endless Feast's; BloodMoon.is_up(), THE
##     test) every standing closed one opens (CourtCoffinKit.open_coffin(), the
##     one opening path) and a Vampire Noble climbs out.
##   * COFFIN NAILS (the stage's achievement; owner-approved name and rule:
##     "break every coffin on Ravensmoor before it opens"): when every wave has
##     been placed and every coffin placed was broken while closed, the run stat
##     ravensmoor_coffin_nails is set (MetaProgress counts the runs: lifetime
##     coffin_nails_runs, MetaData "coffin_nails"; it unlocks Silver Bones).
##   * THE GHOUL PACKS ("ghoul_packs"): from `from` s, every `every` s a pack
##     of `count` ghouls comes in together on the spawn ring (under the hard cap).
##   * OLD GREYMANE ("greymane" event): the stage miniboss, spawned on the
##     spawn ring with his pack of werewolf hunters and tracked (objective,
##     kill time); his kit registers him on the HUD's miniboss bar and pays his
##     XP burst.
##   * The HUD objective while Old Greymane stands.
## Deterministic: only the seeded global RNG (where the coffins, the packs and
## Greymane come in). Stats: ravensmoor_coffins_placed, _broken, _opened,
## ravensmoor_coffin_bounty, ravensmoor_coffin_nails, ravensmoor_ghoul_packs,
## ravensmoor_greymane_spawned, ravensmoor_greymane_killed.
class_name RavensmoorDirector
extends Node2D

## Owning run.
var game: Game
## The stage's config (RavensmoorStage.RAVENSMOOR).
var config: Dictionary = {}
## Log of Ravensmoor events, "m:ss name" (autotest summary).
var fired: Array[String] = []
## Sleeping coffins placed this run.
var placed: int = 0
## Sleeping coffins broken while closed this run.
var broken: int = 0
## Sleeping coffins that opened (a noble climbed out) this run.
var opened: int = 0
## Soul Ash bounty earned by breaking coffins this run.
var bounty: int = 0
## True once Coffin Nails was earned this run.
var nails: bool = false
## "m:ss" Old Greymane fell ("" while alive / never spawned).
var greymane_time: String = ""
## Index of the next coffin wave in config "coffins".
var _wave: int = 0
## Standing sleeping coffins (stale ones dropped as they go).
var _coffins: Array[Enemy] = []
## Pool generation of each entry of `_coffins`.
var _gens: PackedInt32Array = PackedInt32Array()
## True while the moon was up at the last step (the rise edge).
var _moon_was_up: bool = false
## Game time (s) of the next ghoul pack (INF before the config is read).
var _next_pack: float = INF
## Old Greymane once spawned (null before / after; generation-checked).
var _gm: Enemy = null
## Generation of `_gm` when he spawned.
var _gm_gen: int = 0


func _ready() -> void:
	var packs: Dictionary = config.get("ghoul_packs", {})
	if not packs.is_empty():
		_next_pack = float(packs["from"])


## Per-tick update (EnemyDirector, after the MarchDirector).
func step(_delta: float) -> void:
	var now := game.elapsed
	var waves: Array = config.get("coffins", [])
	while _wave < waves.size() and now >= float((waves[_wave] as Dictionary)["time"]):
		_place_wave(waves[_wave])
		_wave += 1
	if game.court != null:
		var up := game.court.moon.is_up()
		if up and not _moon_was_up:
			_open_all()
		_moon_was_up = up
	if now >= _next_pack and not game.countdown_finished():
		var packs: Dictionary = config["ghoul_packs"]
		_next_pack = now + float(packs["every"])
		_ghoul_pack(int(packs["count"]))
	if _gm != null and not (_gm.active and _gm.generation == _gm_gen):
		_gm = null
		game.stat_add("ravensmoor_greymane_killed", 1.0)
		greymane_time = _clock()
		_log("greymane_killed")


# =====================================================================================
# The sleeping coffins and Coffin Nails
# =====================================================================================

## Places one wave of sleeping coffins around the necromancer (a fixed spread
## turned by the seeded RNG), each an objective (never recycled).
func _place_wave(w: Dictionary) -> void:
	var n := int(w["count"])
	var offset := randf() * TAU  # Angle of the first coffin.
	var pl := game.player
	var made := 0
	for k in n:
		var a := offset + TAU * float(k) / float(maxi(1, n))
		var dist := lerpf(float(config["coffin_dist_min"]), float(config["coffin_dist_max"]), float(k % 2))
		var at := game.arena.free_point(pl.position + Vector2.from_angle(a) * dist, 24.0)
		var e := game.enemies.spawn_at(RavensmoorEnemyData.SLEEPING_COFFIN, at, false)
		if e == null:
			continue
		e.is_objective = true  # It stands until broken or opened.
		_coffins.append(e)
		_gens.append(e.generation)
		made += 1
	placed += made
	game.stat_add("ravensmoor_coffins_placed", float(made))
	game.enemies.show_banner(String(w["banner"]))
	_log("coffins_%d" % made)


## The Blood Moon rose: every standing closed sleeping coffin opens.
func _open_all() -> void:
	var n := 0
	var i := _coffins.size() - 1
	while i >= 0:
		var e := _coffins[i]
		if e.active and e.generation == _gens[i] and e.kit is CourtCoffinKit and not (e.kit as CourtCoffinKit).opened:
			(e.kit as CourtCoffinKit).open_coffin(e)
			n += 1
		_coffins.remove_at(i)
		_gens.remove_at(i)
		i -= 1
	if n > 0:
		opened += n
		game.stat_add("ravensmoor_coffins_opened", float(n))
		game.enemies.show_banner(String(config["coffins_open_banner"]))
		_log("coffins_opened_%d" % n)


## A sleeping coffin fell (SleepingCoffinKit.on_killed()): still closed, it
## pays its bounty, and Coffin Nails may be earned.
func on_coffin_broken(e: Enemy, was_open: bool) -> void:
	if was_open:
		return
	broken += 1
	var ash := int(config["coffin_bounty"])
	bounty += ash
	game.stat_add("ravensmoor_coffins_broken", 1.0)
	game.stat_add("ravensmoor_coffin_bounty", float(ash))
	game.stat_add("objective_ash", float(ash))  # The end screen's objectives part (MetaProgress.compute_ash()).
	game.effects.ring(e.position, 30.0, Palette.GOLD, 0.4)
	var waves: Array = config.get("coffins", [])
	if not nails and _wave >= waves.size() and opened == 0 and broken >= placed and placed > 0:
		nails = true
		game.stats["ravensmoor_coffin_nails"] = 1.0
		game.enemies.show_banner(String(config["nails_banner"]))
		_log("coffin_nails")


# =====================================================================================
# The ghoul packs and Old Greymane
# =====================================================================================

## A pack of `n` ghouls comes in together on the spawn ring.
func _ghoul_pack(n: int) -> void:
	var a := randf() * TAU
	var c := game.enemies.ring_point(a)
	var side := Vector2.from_angle(a).orthogonal()
	var made := 0
	for k in n:
		if game.enemies.regular_alive() >= game.enemies.hard_cap():
			break
		var at := c + side * (float(k) - float(n - 1) * 0.5) * 18.0
		if game.enemies.spawn_at(CourtEnemyData.GHOUL, at, false) != null:
			made += 1
	if made > 0:
		game.stat_add("ravensmoor_ghoul_packs", 1.0)


## Runs a Ravensmoor timeline event (EnemyDirector forwards the "greymane"
## type; keys in RavensmoorStage.EVENTS).
func start_event(ev: Dictionary) -> void:
	match String(ev["type"]):
		"greymane":
			var a := randf() * TAU
			var e := game.enemies.spawn_at(String(ev.get("kind", RavensmoorEnemyData.GREYMANE)), game.enemies.ring_point(a), bool(ev.get("elite", false)))
			if e != null:
				_gm = e
				_gm_gen = e.generation
				game.stat_add("ravensmoor_greymane_spawned", 1.0)
				game.shake(5.0)
				game.court_rules().play_sound("wolf_howl", e.position)
				var side := Vector2.from_angle(a).orthogonal()
				var pack := int(ev.get("pack", 0))
				for k in pack:
					var at := e.position + side * (float(k) - float(pack - 1) * 0.5) * 34.0 - Vector2.from_angle(a) * 30.0
					game.enemies.spawn_at(CourtEnemyData.WEREWOLF, at, false)
				_log("greymane_arrived")
	game.enemies.show_banner(String(ev["banner"]))


## HUD objective for the live Ravensmoor objective ("" if none).
func objective_override() -> String:
	if _gm != null:
		return String(config["greymane_objective"])
	return ""


## One-line autotest summary.
func summary_line() -> String:
	var waves: Array = config.get("coffins", [])
	return "sleeping coffins placed %d (waves %d/%d), broken %d (bounty %d Soul Ash), opened by the moon %d | coffin nails %s | ghoul packs %d | old greymane %s | events %s" % [
		placed, _wave, waves.size(), broken, bounty, opened, "earned" if nails else "no",
		int(game.stats.get("ravensmoor_ghoul_packs", 0.0)),
		("killed at " + greymane_time) if greymane_time != "" else ("alive" if _gm != null else "not spawned"),
		", ".join(fired) if not fired.is_empty() else "-"]


## Records a Ravensmoor event for the autotest summary.
func _log(event_name: String) -> void:
	fired.append("%s %s" % [_clock(), event_name])


## Elapsed game time as "m:ss".
func _clock() -> String:
	var s := int(game.elapsed)
	return "%d:%02d" % [floori(float(s) / 60.0), s % 60]
