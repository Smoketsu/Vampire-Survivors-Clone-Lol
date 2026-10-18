## HierophantKit — the Hierophant of the Eye's ASCENSION (SpireEnemyData
## "eye_hierophant", kit "hierophant"; GDD §15.0 "Ul-Thalos, the Risen
## Spire", the act's time pressure). Its body is the shared "banner" walk (it
## advances on the necromancer and buffs the cultists around it through the
## shared aura) and it claims the dead like a Chanter (EyeClaims). Then:
##   * Ascension: ascend_first s after it arrives it stops and channels for
##     ascend_channel s inside a biolume pillar (the Eye's bioluminescence:
##     never gold, which stays for chests and evolutions, and magenta-leaning,
##     never the player's violet). If it survives, it tears itself open and
##     rises as a Spawn of the Deep (SpireEnemyData.SPAWN, elite when
##     ascend_elite): the Hierophant leaves the field without a kill and the
##     Spawn takes its place.
##   * Interruptible, like the High Confessor's revival: killing it during the
##     channel ends the ritual; so does dealing ascend_break of its max HP
##     during it (a stagger: it walks again and retries after ascend_retry s).
##     A build without burst gets punished, but never instantly.
## Determinism (CLAUDE.md): no RNG; the first ritual is staggered by the
## think slot (CovenantKit.first_cd()).
## Stats: ascensions_started, ascensions_finished, ascensions_interrupted
## (killed in the pillar), ascensions_broken (staggered by damage).
class_name HierophantKit
extends CovenantKit

## Phase: the Ascension channel.
const CHANNEL: int = 1

## Seconds until the next ritual may start.
var cd: float = 0.0
## Its HP when the current channel began (the break threshold).
var _hp_at_start: float = 0.0


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	cd = first_cd(e, float(d["ascend_first"]))
	_hp_at_start = 0.0


## Killed in the pillar: the ritual is interrupted.
func on_killed(e: Enemy) -> void:
	if phase == CHANNEL:
		e.game.stat_add("ascensions_interrupted", 1.0)
		e.game.effects.ring(e.position, 46.0, Palette.EYE_BIOLUME_GLOW, 0.4)


func physics(e: Enemy, delta: float) -> bool:
	cd -= delta
	if phase == CHANNEL:
		phase_time += delta
		hold(e)
		if int(phase_time * 4.0) != int((phase_time - delta) * 4.0):
			e.queue_redraw()  # The pillar pulses (a few redraws a second).
		if _hp_at_start - e.hp >= e.max_hp * float(d["ascend_break"]):
			# Burst broke the ritual: a stagger, then it tries again later.
			e.game.stat_add("ascensions_broken", 1.0)
			e.game.effects.ring(e.position, 40.0, Palette.EYE_BIOLUME, 0.3)
			set_phase(e, IDLE)
			cd = float(d["ascend_retry"])
			return false
		if phase_time >= float(d["ascend_channel"]):
			_ascend(e)
		return true
	if cd > 0.0 or e.engaged_timer > 0.0:
		return false
	set_phase(e, CHANNEL)
	_hp_at_start = e.hp
	e.motion_lunge(Vector2.ZERO, MotionData.POWER_CAST)  # Engine motion: the rite begins (visual only).
	e.game.stat_add("ascensions_started", 1.0)
	e.game.enemies.show_banner("A Hierophant begins the Ascension: break it before it rises!")
	Sfx.play("boss_telegraph", e.position, 0.8)
	return true


## The ritual is complete: the Hierophant leaves and a Spawn of the Deep
## rises where it stood.
func _ascend(e: Enemy) -> void:
	var g := e.game
	var pos := e.position
	set_phase(e, IDLE)
	g.stat_add("ascensions_finished", 1.0)
	g.effects.impact(pos, 60.0, Palette.EYE_BIOLUME)
	g.effects.ring(pos, 90.0, Palette.EYE_DROWNED, 0.5)
	g.shake(3.0)
	g.enemies.despawn(e)
	var s := g.enemies.spawn_at(SpireEnemyData.SPAWN, pos, bool(d["ascend_elite"]))
	s.is_objective = false
	g.enemies.show_banner("The Ascension is complete: a Spawn of the Deep rises!")


## True while the channel runs (the autotest's stuck check skips it).
func is_busy() -> bool:
	return phase != IDLE


## The biolume pillar of the Ascension (under it), filling as it channels.
func draw_under(e: Enemy) -> void:
	if phase != CHANNEL:
		return
	unmirror(e)
	var k := clampf(phase_time / maxf(0.05, float(d["ascend_channel"])), 0.0, 1.0)
	SpireGlyphs.draw_ascension(e, Vector2.ZERO, e.radius, k, e.game.elapsed if e.game != null else 0.0)
	e.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
