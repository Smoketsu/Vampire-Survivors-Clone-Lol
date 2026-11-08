## LionWardenKit — THE LION WARDEN, the Temple of the Lioness's miniboss
## (LionessTempleEnemyData "lion_warden"; temporary Act XII; GDD §15.0 "The
## Lion Warden (Dynasty phase 2)"; proposal: "The Lion Warden (male), a huge
## statue-warrior that stands in a doorway and must be killed to pass").
## Brought in once by LionessTempleDirector (the "lion_warden" timeline event),
## which seals the hall around the necromancer and stands the Warden in its
## one DOORWAY: while the Warden stands, the necromancer cannot leave the hall
## (the director's seal); his death opens the way. He registers as
## EnemyDirector.miniboss (the HUD's miniboss bar; ChestManager drops the
## miniboss chest). While he HOLDS the doorway he never steps out of it
## (move_speed 0: the shared AI still swings his slab shield at whatever comes
## within reach) and:
##   * THE SLAM — every slam "every" s, once a summon or a necromancer is
##     within its radius, he raises the slab for "windup" s (a telegraph
##     circle) and brings it down: everything in the circle is struck
##     (OlympusHits.circle(), CombatResolver's one hit paths) and the summons
##     are thrown "push" px out.
##   * THE ROAR — every roar "every" s, while the necromancer stands within
##     "length" px plus roar_slack, a telegraphed lane runs from the doorway at
##     him for "windup" s, then the roar strikes along it
##     (OlympusHits.lane()); and every roar wakes statue rows of the hall
##     (LionessTempleDirector.wake_rows(), the Awakening Statues' one path).
## When the seal times out (the director's seal_time: the boss must find the
## way open) he is RELEASED: he steps out of the doorway and walks like any
## heavy (walk_speed). Blows never shove him. Dead: an XP burst, the banner and
## the director's note (the seal breaks). Determinism: no RNG (the first slam
## and roar staggered by the think slot). Stats: warden_slams,
## warden_slam_hits, warden_roars, warden_roar_hits, warden_kills, warden_ttk.
class_name LionWardenKit
extends DynastyKit

## Phase: the slab raised before the slam.
const SLAM_WINDUP: int = 1
## Phase: the roar drawn in (its lane shows).
const ROAR_WINDUP: int = 2
## px the autotest bot keeps from his telegraphs beyond their size.
const DANGER_REACH: float = 20.0  # TUNING (not in GDD) autotest hint only

## True while he holds his doorway (the director releases him).
var holding: bool = true
## Seconds until the next slam may start.
var _slam_cd: float = 0.0
## Seconds until the next roar may start.
var _roar_cd: float = 0.0
## The roar's lane direction (unit; locked at its windup).
var _roar_dir: Vector2 = Vector2.RIGHT
## Game time he arrived (time-to-kill stat).
var _spawned_at: float = 0.0
## Ally query buffer.
var _tmp: Array = []


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	holding = true
	e.move_speed = 0.0  # He holds his doorway.
	e.is_objective = true  # Never recycled to the spawn ring while he holds it.
	_slam_cd = first_cd(e, float((d["slam"] as Dictionary)["every"]) * 0.5)
	_roar_cd = first_cd(e, float((d["roar"] as Dictionary)["first"]))
	_spawned_at = e.game.elapsed
	e.game.enemies.set_miniboss(e)
	e.game.stat_add("warden_spawned", 1.0)


## The seal timed out: he steps out of the doorway and walks.
func release(e: Enemy) -> void:
	if not holding:
		return
	holding = false
	e.move_speed = float(d.get("walk_speed", 34.0))
	e.is_objective = false
	e.game.stat_add("warden_released", 1.0)


func physics(e: Enemy, delta: float) -> bool:
	super.physics(e, delta)
	e.knockback = Vector2.ZERO  # A miniboss of stone: blows do not shove him.
	match phase:
		SLAM_WINDUP:
			hold(e)
			phase_time += delta
			if phase_time >= float((d["slam"] as Dictionary)["windup"]):
				_slam(e)
				set_phase(e, IDLE)
			return true
		ROAR_WINDUP:
			hold(e)
			phase_time += delta
			if phase_time >= float((d["roar"] as Dictionary)["windup"]):
				_roar(e)
				set_phase(e, IDLE)
			return true
	_slam_cd -= delta
	_roar_cd -= delta
	var s: Dictionary = d["slam"]
	if _slam_cd <= 0.0 and OlympusHits.summons_near(e.game, e.position, float(s["radius"]), _tmp) + _players_near(e, float(s["radius"])) > 0:
		_slam_cd = float(s["every"])
		set_phase(e, SLAM_WINDUP)
		e.game.effects.telegraph_circle(e.position, float(s["radius"]), float(s["windup"]), e)
		e.motion_lunge(Vector2.ZERO, MotionData.POWER_CAST)
		return true
	var r: Dictionary = d["roar"]
	var pl := e.game.player
	if _roar_cd <= 0.0 and not pl.dead and pl.position.distance_to(e.position) <= float(r["length"]) + float(r["slack"]) \
			and not e.game.ultimates.player_untargetable():
		_roar_cd = float(r["every"])
		var to := pl.position - e.position
		_roar_dir = to.normalized() if to.length() > 0.5 else Vector2.RIGHT
		set_phase(e, ROAR_WINDUP)
		e.game.effects.telegraph_line(e.position, e.position + _roar_dir * float(r["length"]), float(r["width"]), float(r["windup"]), e)
		e.motion_lunge(-_roar_dir, MotionData.POWER_CAST)
		return true
	return false


## Standing necromancers within `r` px of him (bodies count).
func _players_near(e: Enemy, r: float) -> int:
	var n := 0
	for pl in e.game.all_players:
		if not pl.dead and pl.position.distance_to(e.position) <= r + pl.radius:
			n += 1
	return n


## The slam: everything in the circle is struck and the summons thrown out.
func _slam(e: Enemy) -> void:
	var g := e.game
	var s: Dictionary = d["slam"]
	var sc := hit_scale(e)
	var hits := OlympusHits.circle(g, e.position, float(s["radius"]), float(s["damage_player"]) * sc,
			float(s["damage"]) * sc * e.undead_damage_mult, LionessTempleEnemyData.WARDEN_SLAM_SOURCE, e, float(s["push"]), _tmp)
	g.stat_add("warden_slams", 1.0)
	g.stat_add("warden_slam_hits", float(hits))
	g.effects.impact(e.position, float(s["radius"]), Palette.DYN_SAND)
	g.shake(4.0)
	if g.dynasty != null:
		g.dynasty.play_sound("colossus_slam", e.position, 0.3)


## The roar: the lane strikes, and statue rows of the hall wake.
func _roar(e: Enemy) -> void:
	var g := e.game
	var r: Dictionary = d["roar"]
	var sc := hit_scale(e)
	var hits := OlympusHits.lane(g, e.position, _roar_dir, float(r["length"]), float(r["width"]), float(r["damage_player"]) * sc,
			float(r["damage"]) * sc * e.undead_damage_mult, LionessTempleEnemyData.WARDEN_ROAR_SOURCE, e, {}, _tmp)
	g.stat_add("warden_roars", 1.0)
	g.stat_add("warden_roar_hits", float(hits))
	g.effects.ring(e.position, float(r["width"]) * 1.5, Palette.DYN_CARNELIAN_LIGHT, 0.4)
	if g.dynasty != null:
		g.dynasty.play_sound("warden_roar", e.position, 0.5)
	if holding and g.enemies.lioness_temple != null:
		g.enemies.lioness_temple.wake_rows(int(r["wakes"]), "warden")  # Only the hall he holds wakes.


func is_busy() -> bool:
	return holding or phase != IDLE  # He never walks while he holds the doorway (the stuck check skips him).


## Autopilot hint: out of the slam's circle and off the roar's lane.
func danger_push(e: Enemy, p: Vector2) -> Vector2:
	match phase:
		SLAM_WINDUP:
			var rr := float((d["slam"] as Dictionary)["radius"]) + DANGER_REACH
			var off := p - e.position
			if off.length() < rr and off.length() > 0.01:
				return off.normalized() * (1.0 - off.length() / rr) * 2.0
		ROAR_WINDUP:
			var r: Dictionary = d["roar"]
			var rel := p - e.position
			var along := rel.dot(_roar_dir)
			var side := rel.dot(_roar_dir.orthogonal())
			var half := float(r["width"]) * 0.5 + DANGER_REACH
			if along > 0.0 and along < float(r["length"]) and absf(side) < half:
				return _roar_dir.orthogonal() * (signf(side) if side != 0.0 else 1.0) * (1.0 - absf(side) / half) * 2.0
	return Vector2.ZERO


## The XP burst, the banner, the stats and the director's note (the seal breaks).
func on_killed(e: Enemy) -> void:
	var g := e.game
	super.on_killed(e)
	var n := maxi(1, int(d.get("reward_crystals", 12)))
	var each := maxi(1, floori(float(d.get("reward_xp", 260)) / float(n)))  # XP per crystal.
	for i in n:
		g.pickups.spawn(e.position + Vector2.from_angle(TAU * float(i) / float(n)) * (30.0 + 6.0 * float(i % 3)), each)
	g.effects.impact(e.position, e.radius * 3.0, Palette.DYN_SAND_LIGHT)
	g.shake(7.0)
	g.stat_add("warden_kills", 1.0)
	g.stat_add("warden_ttk", g.elapsed - _spawned_at)
	if g.enemies.lioness_temple != null:
		g.enemies.lioness_temple.on_warden_down(e)


## Releases the HUD bar.
func on_deactivate(e: Enemy) -> void:
	super.on_deactivate(e)
	e.game.enemies.clear_miniboss(e)
