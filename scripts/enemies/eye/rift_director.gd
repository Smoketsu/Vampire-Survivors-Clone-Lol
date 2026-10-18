## RiftDirector — the Hollow Archive's RIFTS (Act II; GDD §15.0 "Act II: the
## Hollow Archive", owner-approved proposal "Rifts fold the map and open doors
## behind you"), owned and stepped by ArchiveDirector. Numbers:
## ArchiveStage.ARCHIVE["rifts"] (`config`), the "rift" timeline events and
## the rift structure row (ArchiveEnemyData "archive_rift").
##   * A rift is TELEGRAPHED for `telegraph` s: a tear grows in the air
##     `behind_min`..`behind_max` px from the necromancer, BEHIND the army (on
##     the side away from the threat the horde senses, else away from where
##     he walks, else at a seeded angle).
##   * Then it OPENS: a rift structure (RiftKit) stands there and spits the
##     event's squad out around it (HARD_CAP respected), then
##     `spit_groups` more every `spit_interval` s while it stays open. The
##     Eye's soldiers still walk straight at the necromancer (enemies always
##     advance); they just start close, often behind the army.
##   * It CLOSES by itself after `life` s (taken off the field without a
##     kill), or sooner when the army breaks it: the structure is killed
##     (an XP crystal, a little Soul Ash: ARCHIVE rift_ash).
##   * Zone IV, the Unwritten Stacks: a rift every `periodic_interval` s from
##     `periodic_from` to `periodic_until` (squad `periodic_groups`); earlier
##     zones see single "rift" events as a preview.
## Deterministic: the seeded global RNG only (a rift without a direction to
## go by picks its angle with randf()). Drawn here in world space under the
## bodies (the open tear itself is the structure's sprite / kit).
class_name RiftDirector
extends Node2D

## Phase of a rift: telegraphed.
const TELEGRAPH: int = 0
## Phase of a rift: open (its structure stands).
const OPEN: int = 1

## One rift.
class Rift:
	extends RefCounted
	## World position.
	var pos: Vector2 = Vector2.ZERO
	## TELEGRAPH or OPEN.
	var phase: int = 0
	## Seconds spent in the phase.
	var t: float = 0.0
	## The squad it spits when it opens ({kind, count, elite} groups).
	var groups: Array = []
	## The open rift's structure (null while telegraphed).
	var enemy: Enemy = null
	## Generation of `enemy` when placed (stale / death guard).
	var gen: int = 0
	## Seconds until it spits its next cultists.
	var spit_cd: float = 0.0

## Owning run.
var game: Game
## The stage's rift config (ArchiveStage.ARCHIVE["rifts"]).
var config: Dictionary = {}
## Live rifts (telegraphed or open).
var rifts: Array[Rift] = []
## Game time of the next periodic rift (INF once past periodic_until).
var _next_periodic: float = INF
## Rifts that opened this run.
var opened: int = 0
## Rifts the army broke before they closed by themselves.
var closed_early: int = 0
## Rifts that closed by themselves.
var expired: int = 0
## Cultists that came out of rifts.
var spat: int = 0
## Game times rifts opened, "m:ss" (summary).
var open_times: PackedStringArray = PackedStringArray()
## True if a rift was drawn last frame (one more redraw clears it).
var _drew: bool = false


func _ready() -> void:
	z_index = -6  # On the ground, under bodies.
	_next_periodic = float(config.get("periodic_from", INF))


## Per-tick update, called by ArchiveDirector.
func step(delta: float) -> void:
	if game.elapsed >= _next_periodic:
		_next_periodic += float(config["periodic_interval"])
		if _next_periodic > float(config["periodic_until"]):
			_next_periodic = INF
		if game.enemies.reckoning_wave == 0:
			start_rift(config["periodic_groups"])
	var i := rifts.size() - 1
	while i >= 0:
		if not _step_rift(rifts[i], delta):
			rifts.remove_at(i)
		i -= 1
	if not rifts.is_empty() or _drew:
		queue_redraw()
	_drew = not rifts.is_empty()


## Telegraphs a new rift whose squad is `groups`, behind the army.
func start_rift(groups: Array) -> void:
	var r := Rift.new()
	r.groups = groups
	r.pos = _behind_point()
	rifts.append(r)
	game.effects.telegraph_circle(r.pos, float(game.enemies.enemy_def(ArchiveEnemyData.RIFT)["radius"]) * 2.2, float(config["telegraph"]))
	game.stat_add("rifts_telegraphed", 1.0)


## A free point behind the army: away from the horde's sensed threat, else
## away from where the necromancer walks, else at a seeded angle.
func _behind_point() -> Vector2:
	var p := game.player.position
	var dir := Vector2.ZERO
	if game.horde.threat_level > 0.0:
		dir = -game.horde.threat_dir
	elif game.player.velocity.length() > 5.0:
		dir = -game.player.velocity.normalized()
	else:
		dir = Vector2.from_angle(randf() * TAU)
	var at := p + dir.normalized() * randf_range(float(config["behind_min"]), float(config["behind_max"]))
	return game.arena.free_point(at, float(game.enemies.enemy_def(ArchiveEnemyData.RIFT)["radius"]) + 4.0)


## Advances one rift; false once it is gone.
func _step_rift(r: Rift, delta: float) -> bool:
	r.t += delta
	if r.phase == TELEGRAPH:
		if r.t >= float(config["telegraph"]):
			_open(r)
		return true
	var e := r.enemy
	if not e.active or e.generation != r.gen:
		closed_early += 1
		game.stat_add("rifts_closed_early", 1.0)
		game.stat_add("objective_ash", float(game.enemies.archive.config["rift_ash"]))
		game.effects.impact(r.pos, 40.0, config["color"])
		game.enemies.show_banner("The army seals the rift!")
		return false
	if r.t >= float(config["life"]):
		expired += 1
		game.stat_add("rifts_expired", 1.0)
		game.enemies.despawn(e)
		game.effects.pop(r.pos, config["color"], 26.0)
		return false
	r.spit_cd -= delta
	if r.spit_cd <= 0.0:
		r.spit_cd = float(config["spit_interval"])
		_spit(r, config["spit_groups"], WaveData.HARD_CAP - 10)
	return true


## The rift opens: its structure and the squad.
func _open(r: Rift) -> void:
	r.phase = OPEN
	r.t = 0.0
	r.spit_cd = float(config["spit_interval"])
	var e := game.enemies.spawn_at(ArchiveEnemyData.RIFT, r.pos, false)
	e.is_objective = true
	r.enemy = e
	r.gen = e.generation
	r.pos = e.position
	opened += 1
	var s := int(game.elapsed)
	open_times.append("%d:%02d" % [floori(float(s) / 60.0), s % 60])
	game.stat_add("rifts_opened", 1.0)
	game.effects.ring(r.pos, 60.0, config["color"], 0.6)
	game.shake(3.0)
	Sfx.play("deep_freeze", r.pos, 0.7)
	_spit(r, r.groups, WaveData.HARD_CAP)


## Spits `groups` out around the rift (up to `cap` living enemies).
func _spit(r: Rift, groups: Array, cap: int) -> void:
	var n := 0  # Spat this time.
	var total := 0
	for grp: Dictionary in groups:
		total += int(grp["count"])
	var k := 0
	for grp: Dictionary in groups:
		for _i in int(grp["count"]):
			if game.enemies.regular_alive() >= cap:
				break
			var a := TAU * float(k) / float(maxi(1, total)) + float(opened) * 0.7  # Spread evenly (no RNG).
			var at := r.pos + Vector2.from_angle(a) * float(config["spit_radius"])
			game.enemies.spawn_at(String(grp["kind"]), at, bool(grp["elite"]))
			n += 1
			k += 1
	spat += n
	game.stat_add("rift_spawned", float(n))


## Live rifts (telegraphed or open).
func live_count() -> int:
	return rifts.size()


## One-line autotest summary.
func summary_line() -> String:
	return "rifts opened %d (%s) | closed early by the army %d | closed by themselves %d | cultists spat out %d" % [
		opened, ", ".join(open_times) if not open_times.is_empty() else "-", closed_early, expired, spat]


# =====================================================================================
# Drawing (the telegraphed tear, under bodies)
# =====================================================================================

func _draw() -> void:
	var now := game.elapsed
	for r in rifts:
		if r.phase == TELEGRAPH:
			ArchiveGlyphs.draw_rift_telegraph(self, r.pos, clampf(r.t / maxf(0.05, float(config["telegraph"])), 0.0, 1.0), now, config["color"])
