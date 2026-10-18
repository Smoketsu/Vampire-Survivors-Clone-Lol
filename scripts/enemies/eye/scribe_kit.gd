## ScribeKit — the Scribe of the Unwritten (ArchiveEnemyData "scribe"; Act II,
## GDD §15.0 "Act II: the Hollow Archive"): a support that inks a curse on the
## cultists around it. Every curse_cooldown s, when at least one living
## cultist (any other non-structure enemy; the boss and minibosses excepted)
## stands within curse_range px without a curse, it stops and writes for
## curse_cast s (the telegraph: a raised quill and a ring), then marks the
## curse_count nearest uncursed ones: each is a CLAIMER for curse_duration s
## (Enemy.claimer_until, the foundation's Claims rule: a summon dying within
## EyeEnemyData.CLAIM.curse_radius of it rises as a Drowned Thrall; EyeClaims).
## The sigil over a cursed cultist is drawn by ArchiveHazardOverlay.
## Stats: scribe_curses (casts), scribe_cursed (cultists marked).
## Determinism: no RNG; the nearest-first order comes from the distances.
class_name ScribeKit
extends CovenantKit

## Phase: writing the curse (standing still).
const WRITE: int = 1

## Seconds until the next curse may be written.
var curse_cd: float = 0.0
## Reusable query buffer.
var _tmp: Array = []
## Candidate [distance, enemy] pairs of a curse.
var _cands: Array = []


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	curse_cd = first_cd(e, float(d["curse_first"]))


## Starts writing when a cultist in reach has no curse.
func think(e: Enemy) -> void:
	if phase != IDLE or curse_cd > 0.0:
		return
	if _gather(e) == 0:
		curse_cd = 1.0  # Nobody to curse: look again in a second (not a balance number).
		return
	set_phase(e, WRITE)
	e.game.effects.ring(e.position, float(d["curse_range"]), ArchiveEnemyData.CURSE_COLOR, float(d["curse_cast"]))
	e.motion_lunge(Vector2.ZERO, MotionData.POWER_CAST)  # Engine motion: the quill raised (visual only).


func physics(e: Enemy, delta: float) -> bool:
	curse_cd -= delta
	if phase == IDLE:
		return false
	phase_time += delta
	hold(e)
	if phase_time >= float(d["curse_cast"]):
		_curse(e)
		curse_cd = float(d["curse_cooldown"])
		set_phase(e, IDLE)
	return true


## Fills _cands with the uncursed cultists in reach, nearest first; returns
## how many there are.
func _gather(e: Enemy) -> int:
	var g := e.game
	var reach := float(d["curse_range"])
	g.enemy_grid.query(e.position, reach, _tmp)
	_cands.clear()
	for o: Enemy in _tmp:
		if o == e or not o.active or o.is_structure or o.is_boss or o.is_miniboss or o.is_reckoning:
			continue
		if o.claimer_until > g.elapsed or o.claim_radius > 0.0:
			continue  # Already a claimer.
		var dist := o.position.distance_to(e.position)
		if dist <= reach:
			_cands.append([dist, o])
	_cands.sort_custom(func(a: Array, b: Array) -> bool: return float(a[0]) < float(b[0]))
	return _cands.size()


## Marks the curse_count nearest uncursed cultists as claimers.
func _curse(e: Enemy) -> void:
	var g := e.game
	_gather(e)
	var n := mini(int(d["curse_count"]), _cands.size())
	for k in n:
		var o: Enemy = _cands[k][1]
		o.claimer_until = g.elapsed + float(d["curse_duration"])
		g.effects.beam(e.position, o.position, ArchiveEnemyData.INK_SHEEN)
	if n > 0:
		g.stat_add("scribe_curses", 1.0)
		g.stat_add("scribe_cursed", float(n))
		Sfx.play("plague_cast", e.position, 0.8)


## A quill raised while writing.
func draw_over(e: Enemy, ci: CanvasItem) -> void:
	if phase == WRITE:
		ArchiveGlyphs.draw_quill_cast(ci, Vector2(0, -e.radius * 1.9), e.radius, phase_time / maxf(0.05, float(d["curse_cast"])))
