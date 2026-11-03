## ArkDirector — the stage mechanics of THE ARK OF THE CONCORD (Stage 27, the
## finale of Act IX; GDD §15.0 "The Ark of the Concord (Act IX phase 2)";
## owner-approved proposal docs/act9/PROPOSAL.md "Stage 27: The Ark of the
## Concord (the finale)"), owned and stepped by EnemyDirector on a stage whose
## STAGE has an "ark" config (ArkStage.ARK; null elsewhere). The four zones
## are MarchDirector's (the clock is authoritative: the Hangar, the Specimen
## Vaults, the Reactor, the Bridge of Stars); the Concord's shared rules are
## Game.concord's. This director runs:
##   * THE SPECIMEN VAULTS (config "tanks", from..until game s): `count`
##     specimen tanks (ArkEnemyData "specimen_tank", structures) stand
##     ring_min..ring_max px from the necromancer, at least `spacing` apart,
##     off the obstacles (seeded RNG). A broken tank frees its beasts
##     (SpecimenTankKit: vault beasts that attack everyone, VaultBeastKit) and
##     leaves a wreck drawn here; a new tank rises `respawn` s later, at most
##     max_total in the zone. A tank left more than `keep` px behind is
##     quietly taken off the field (EnemyDirector.despawn()) and rises again
##     nearer.
##   * THE REACTOR (config "vents"): the same for the reactor vents
##     (ArkEnemyData "reactor_vent", ReactorVentKit: each seeds live turf
##     through Terraforming.seed(), tag "vents", on a timer; breaking one stops
##     it).
##   * THE LUMINOUS ARCHON (the "luminous_archon" timeline event): the
##     miniboss lands at the spawn ring with its escort (LuminousArchonKit
##     registers it for the HUD bar; ChestManager drops its chest).
##   * THE HUD OBJECTIVE while the Archon fights or the Harvester reaps.
## Wrecked tanks and vents are drawn here (structures/<kind>_dead sprites, else
## ArkGlyphs; textures only), over the floor and under the obstacles and
## bodies. Deterministic: the seeded global RNG only (the structures' places,
## the spawn points). Stats: ark_tanks_raised, ark_tanks_left,
## ark_tanks_broken (SpecimenTankKit), ark_beasts_freed, ark_vents_raised,
## ark_vents_left, ark_vents_broken (ReactorVentKit), archon_spawned.
class_name ArkDirector
extends Node2D

## One standing structure the director keeps (a tank or a vent).
class Post:
	extends RefCounted
	## The structure.
	var e: Enemy = null
	## Its pool generation (stale guard).
	var gen: int = 0

## One wreck drawn on the floor.
class Wreck:
	extends RefCounted
	## Its centre (world px).
	var at: Vector2 = Vector2.ZERO
	## Its sprite key (structures/<kind>_dead).
	var key: String = ""
	## The kind it was (the glyph fallback).
	var kind: String = ""

## Owning run.
var game: Game
## The stage's config (ArkStage.ARK).
var config: Dictionary = {}
## Log of events, "m:ss name" (autotest summary).
var fired: Array[String] = []
## Standing specimen tanks.
var tanks: Array[Post] = []
## Standing reactor vents.
var vents: Array[Post] = []
## Wrecks on the floor (oldest first, at most config wrecks_max).
var wrecks: Array[Wreck] = []
## Tanks raised so far (the zone's max_total).
var tanks_raised: int = 0
## Vents raised so far (the zone's max_total).
var vents_raised: int = 0
## Stat prefix of a structure window ("ark_tanks" / "ark_vents") -> game time
## (s) before which no new one rises (the respawn delay).
var _wait: Dictionary = {}
## True if the last frame drew anything (one more redraw clears it).
var _drawn: bool = false


func _ready() -> void:
	z_index = -7  # Over the floor (-10) and the turf (-8), under the obstacles (-6) and the bodies.
	z_as_relative = false


## Per-tick update (EnemyDirector, after the MarchDirector).
func step(_delta: float) -> void:
	tanks_raised = _keep(tanks, config.get("tanks", {}), ArkEnemyData.TANK, tanks_raised, "ark_tanks")
	vents_raised = _keep(vents, config.get("vents", {}), ArkEnemyData.VENT, vents_raised, "ark_vents")
	var busy := not wrecks.is_empty()
	if busy or _drawn:
		queue_redraw()
	_drawn = busy


## Keeps `posts` (the standing structures of kind `kind`) as its window `cfg`
## wants: drops the fallen, takes off the ones left behind, raises new ones up
## to `count` (at most max_total in the window, one each respawn s; `stat` is
## the stat prefix and the _wait key). Returns the raised total.
func _keep(posts: Array[Post], cfg: Dictionary, kind: String, raised: int, stat: String) -> int:
	var i := posts.size() - 1
	while i >= 0:
		var p := posts[i]
		if not p.e.active or p.e.generation != p.gen:
			posts.remove_at(i)
		elif p.e.position.distance_to(game.player.position) > float(cfg.get("keep", 760.0)):
			game.enemies.despawn(p.e)
			posts.remove_at(i)
			game.stat_add(stat + "_left", 1.0)
		i -= 1
	if cfg.is_empty() or game.elapsed < float(cfg["from"]) or game.elapsed >= float(cfg["until"]):
		return raised
	if game.enemies.boss != null and game.enemies.boss.active:
		return raised  # The Harvester's fight: no new structures.
	if game.elapsed < float(_wait.get(stat, 0.0)):
		return raised
	if posts.size() >= int(cfg["count"]) or raised >= int(cfg["max_total"]):
		return raised
	var at := _point(cfg, posts)
	var e := game.enemies.spawn_at(kind, at, false)
	if e == null:
		return raised
	var p := Post.new()
	p.e = e
	p.gen = e.generation
	posts.append(p)
	_wait[stat] = game.elapsed + float(cfg["respawn"])
	game.stat_add(stat + "_raised", 1.0)
	if raised == 0:
		game.enemies.show_banner(String(cfg["banner"]))
		_log(kind)
	return raised + 1


## A free place for a structure: ring_min..ring_max px from the necromancer,
## at least `spacing` px from the others, off the obstacles (seeded RNG).
func _point(cfg: Dictionary, posts: Array[Post]) -> Vector2:
	var p := game.player.position
	var best := p + Vector2.RIGHT * float(cfg["ring_min"])
	for _try in 8:
		var at := p + Vector2.from_angle(randf() * TAU) * randf_range(float(cfg["ring_min"]), float(cfg["ring_max"]))
		at = game.arena.free_point(at, 18.0)
		best = at
		var ok := true
		for o in posts:
			if o.e.position.distance_to(at) < float(cfg["spacing"]):
				ok = false
				break
		if ok:
			break
	return best


## A tank broke (SpecimenTankKit.on_killed()): its wreck stays on the floor.
func on_tank_broken(e: Enemy) -> void:
	_add_wreck(e)


## A vent broke (ReactorVentKit.on_killed()): its wreck stays on the floor.
func on_vent_broken(e: Enemy) -> void:
	_add_wreck(e)


## Adds a wreck of structure `e` (the oldest goes past wrecks_max).
func _add_wreck(e: Enemy) -> void:
	var w := Wreck.new()
	w.at = e.position
	w.kind = e.kind
	w.key = "structures/" + e.kind + "_dead"
	wrecks.append(w)
	while wrecks.size() > int(config.get("wrecks_max", 12)):
		wrecks.pop_front()


# =====================================================================================
# Events
# =====================================================================================

## Runs an Ark timeline event (EnemyDirector forwards "luminous_archon").
func start_event(ev: Dictionary) -> void:
	match String(ev["type"]):
		"luminous_archon":
			_send_archon(ev)
	game.enemies.show_banner(String(ev["banner"]))


## Sends the miniboss from the spawn ring with its escort around it.
func _send_archon(ev: Dictionary) -> void:
	var at := game.enemies.ring_point(randf() * TAU)
	var e := game.enemies.spawn_at(String(ev["kind"]), at, false)
	if e == null:
		return
	for grp: Dictionary in ev.get("escort", []):
		for _k in int(grp["count"]):
			if game.enemies.regular_alive() >= game.enemies.hard_cap():
				break
			game.enemies.spawn_at(String(grp["kind"]), e.position + Vector2.from_angle(randf() * TAU) * (e.radius + 34.0), bool(grp["elite"]))
	_log("luminous_archon")


## HUD objective while the Archon fights or the Harvester reaps ("" = none).
func objective_override() -> String:
	var mb := game.enemies.miniboss_alive()
	if mb != null and mb.kit is LuminousArchonKit:
		return "The Luminous Archon: catch its beams on your Orb Shield and your Warders' barriers to send them back"
	var b := game.enemies.boss as BossHarvester
	if b != null and b.active and b.is_reaping():
		return "THE REAPING: destroy the emitters before your army is gone (%d left)" % b.emitters_left()
	return ""


## The wrecks: their sprites, else ArkGlyphs. Visual only.
func _draw() -> void:
	for w in wrecks:
		if not SpriteBank.draw(self, w.key, w.at, false, Color(1.0, 1.0, 1.0, 0.9)):
			ArkGlyphs.draw_wreck(self, w.at, w.kind)


## One-line autotest summary.
func summary_line() -> String:
	var st := game.stats
	return "tanks raised %d, broken %d, left behind %d | beasts freed %d, bites on the Concord %d (dmg %d, kills %d) | vents raised %d, broken %d, left behind %d, breaths %d (cells seeded %d) | archon %s" % [
		int(st.get("ark_tanks_raised", 0.0)), int(st.get("ark_tanks_broken", 0.0)), int(st.get("ark_tanks_left", 0.0)),
		int(st.get("ark_beasts_freed", 0.0)), int(st.get("ark_beast_bites", 0.0)), int(st.get("ark_beast_bite_dmg", 0.0)),
		int(st.get("ark_beast_concord_kills", 0.0)),
		int(st.get("ark_vents_raised", 0.0)), int(st.get("ark_vents_broken", 0.0)), int(st.get("ark_vents_left", 0.0)),
		int(st.get("ark_vent_breaths", 0.0)), int(st.get("terra_seeded_vents", 0.0)),
		("killed in %ds" % int(st.get("archon_kill_time", 0.0))) if st.has("archon_kill_time") else ("spawned, not killed" if float(st.get("archon_spawned", 0.0)) > 0.0 else "not met")]


## Records an event for the autotest summary.
func _log(event_name: String) -> void:
	var s := int(game.elapsed)
	fired.append("%d:%02d %s" % [floori(float(s) / 60.0), s % 60, event_name])
