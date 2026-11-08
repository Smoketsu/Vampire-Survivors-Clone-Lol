## WokenColossusKit — the kit of the WOKEN COLOSSUS (LionessTempleEnemyData
## "woken_colossus"; temporary Act XII, the Temple of the Lioness; GDD §15.0
## "The Temple of the Lioness (Dynasty phase 2)"; proposal: "each becomes an
## Ushabti or a Sand Colossus enemy, leaving a gap in the layout"). A huge
## sandstone statue that steps out of a long statue row when the Awakening
## Statues wake it (LionessTempleDirector). It wears the Sand Colossus's art
## (its row's "wears": dynasty/sand_colossus) but is the Temple's own kind: a
## regular heavy elite, never a miniboss (several may walk at once, and the
## HUD shows one miniboss bar: the Lion Warden's). A slow walker with:
##   * THE GROUND SLAM — every slam "every" s, once a summon or a standing
##     necromancer is within its radius, it raises its fists for "windup" s (a
##     telegraph circle), then SLAMS: every summon and necromancer in the
##     circle takes the slam's damage (x the time scaling and its hit
##     multiplier) through OlympusHits.circle() (CombatResolver's one hit
##     paths) and the summons are thrown "push" px out. The autotest bot steps
##     out of the circle (danger_push()).
##   * Flat armour (row "flat_armor", the existing path) and no Rebirth (stone).
## Burst it, stay at range (the proposal's counter). Determinism: the first
## slam is staggered by the think slot (no RNG). Stats: colossus_slams,
## colossus_slam_hits.
class_name WokenColossusKit
extends DynastyKit

## Phase: the fists raised before the slam.
const WINDUP: int = 1
## px the autotest bot keeps from the slam beyond its radius.
const DANGER_REACH: float = 18.0  # TUNING (not in GDD) autotest hint only

## Seconds until the next slam may start.
var _cd: float = 0.0
## Ally query buffer.
var _tmp: Array = []


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	e.wears = String(def.get("wears", ""))  # The Sand Colossus's art (visual only).
	_cd = first_cd(e, float((d["slam"] as Dictionary)["every"]) * 0.5)


func physics(e: Enemy, delta: float) -> bool:
	super.physics(e, delta)
	e.knockback = Vector2.ZERO  # A colossus: blows do not shove it.
	var s: Dictionary = d["slam"]
	if phase == WINDUP:
		hold(e)
		phase_time += delta
		if phase_time >= float(s["windup"]):
			_slam(e, s)
			set_phase(e, IDLE)
			_cd = float(s["every"])
		return true
	_cd -= delta
	if _cd <= 0.0 and OlympusHits.summons_near(e.game, e.position, float(s["radius"]), _tmp) + _players_near(e, float(s["radius"])) > 0:
		set_phase(e, WINDUP)
		e.game.effects.telegraph_circle(e.position, float(s["radius"]), float(s["windup"]), e)
		e.motion_lunge(Vector2.ZERO, MotionData.POWER_CAST)
		return true
	return false


## Standing necromancers within `r` px of it (bodies count).
func _players_near(e: Enemy, r: float) -> int:
	var n := 0
	for pl in e.game.all_players:
		if not pl.dead and pl.position.distance_to(e.position) <= r + pl.radius:
			n += 1
	return n


## The slam: everything in the circle is struck and the summons thrown out.
func _slam(e: Enemy, s: Dictionary) -> void:
	var g := e.game
	var sc := hit_scale(e)
	var hits := OlympusHits.circle(g, e.position, float(s["radius"]), float(s["damage_player"]) * sc,
			float(s["damage"]) * sc * e.undead_damage_mult, LionessTempleEnemyData.COLOSSUS_SLAM_SOURCE, e, float(s["push"]), _tmp)
	g.stat_add("colossus_slams", 1.0)
	g.stat_add("colossus_slam_hits", float(hits))
	g.effects.impact(e.position, float(s["radius"]), Palette.DYN_SAND)
	g.shake(2.5)
	if g.dynasty != null:
		g.dynasty.play_sound("colossus_slam", e.position, 0.3)


func is_busy() -> bool:
	return phase != IDLE


## Autopilot hint: out of the slam's circle while its fists are raised.
func danger_push(e: Enemy, p: Vector2) -> Vector2:
	if phase != WINDUP:
		return Vector2.ZERO
	var r := float((d["slam"] as Dictionary)["radius"]) + DANGER_REACH
	var off := p - e.position
	if off.length() >= r or off.length() < 0.01:
		return Vector2.ZERO
	return off.normalized() * (1.0 - off.length() / r) * 2.0
