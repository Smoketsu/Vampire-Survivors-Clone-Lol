## EinherjarChampionKit — THE EINHERJAR CHAMPION, Valgard's miniboss
## (ValgardEnemyData "einherjar_champion"; the Hall of the Slain, temporarily
## Act XI; GDD §15.0 "The Einherjar Champion (Valgard)"; owner-approved
## proposal: "Miniboss, the Einherjar Champion, a gold-lit hero who fought in
## the hall for a thousand years"). Spawned once by ValgardDirector (the
## "einherjar_champion" timeline event) through the normal spawn path; it
## registers as EnemyDirector.miniboss (the HUD's miniboss bar; ChestManager
## drops the miniboss chest). A gold-lit hero (NorseKit.einherjar set for the
## look; his row's numbers are already his own) and a WARRIOR of the hall (own
## decision: below 40% he goes berserk, his second wind). The shared walk and
## war-axe, plus:
##   * THE HERO'S SWEEP — every sweep_every s, when his target is within
##     sweep_trigger px of his edge, he winds up for sweep_windup s over a
##     telegraph circle of sweep_radius px around himself
##     (EffectManager.telegraph_circle(), which the autotest bot steps out of),
##     then sweeps: every necromancer and summon in it takes sweep_damage_*
##     (OlympusHits.circle(), source ValgardEnemyData.SWEEP_SOURCE) and the
##     summons are thrown sweep_push px out.
##   * THE CHAMPION'S HORN — horn_first s after he arrives, then every
##     horn_every s, he blows his horn: on Valgard it WAKES THE FEAST (up to
##     horn_wake seated Einherjar near the necromancer,
##     ValgardDirector.wake_feast()); on any other stage (no tables) horn_escort
##     Einherjar rise beside him instead. The hard cap is respected.
##   * Blows do not shove him (knockback cleared each tick, as every miniboss).
## Dead: an XP burst (reward_xp in reward_crystals), the banner and the stats.
## No RNG (the first sweep staggered by the think slot). Stats:
## champion_spawned, champion_sweeps, champion_sweep_hits, champion_horns,
## champion_horn_woken, champion_kills, champion_ttk.
class_name EinherjarChampionKit
extends NorseKit

## Phase: the sweep's windup (its circle shows).
const WINDUP: int = 1
## px the autotest bot keeps from the sweep circle beyond its radius.
const DANGER_REACH: float = 20.0  # TUNING (not in GDD) autotest hint only

## Seconds until the next sweep may start.
var _sweep_cd: float = 0.0
## Seconds until the next horn.
var _horn_cd: float = 0.0
## Game time he arrived (time-to-kill stat).
var _spawned_at: float = 0.0
## Reusable query buffer.
var _buf: Array = []


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	einherjar = true  # The gold light of the hall (his row's numbers are his own: no make_einherjar()).
	_sweep_cd = first_cd(e, 2.0)
	_horn_cd = float(d.get("horn_first", 6.0))
	_spawned_at = e.game.elapsed
	e.game.enemies.set_miniboss(e)
	e.game.stat_add("champion_spawned", 1.0)


func physics(e: Enemy, delta: float) -> bool:
	e.knockback = Vector2.ZERO  # A miniboss: blows do not shove him.
	super.physics(e, delta)
	_sweep_cd -= delta
	_horn_cd -= delta
	if _horn_cd <= 0.0:
		_horn_cd = float(d.get("horn_every", 24.0))
		_horn(e)
	if phase == WINDUP:
		phase_time += delta
		hold(e)
		if phase_time >= float(d.get("sweep_windup", 0.75)):
			_sweep(e)
			set_phase(e, IDLE)
		return true
	if _sweep_cd > 0.0 or not e._target_valid():
		return false
	var t := e.target
	var edge := t.position.distance_to(e.position) - e.radius - body_radius(e, t)
	if edge > float(d.get("sweep_trigger", 70.0)):
		return false
	if t is Necromancer and e.game.ultimates.player_untargetable():
		return false
	_sweep_cd = float(d.get("sweep_every", 5.5))
	e.game.effects.telegraph_circle(e.position, float(d.get("sweep_radius", 64.0)), float(d.get("sweep_windup", 0.75)), e)
	e.motion_lunge(Vector2.ZERO, MotionData.POWER_CAST)
	e.game.stat_add("champion_sweeps", 1.0)
	set_phase(e, WINDUP)
	hold(e)
	return true


## The sweep: everything in the circle around him is cut and the summons thrown out.
func _sweep(e: Enemy) -> void:
	var g := e.game
	var s := hit_scale(e)
	var r := float(d.get("sweep_radius", 64.0))
	g.stat_add("champion_sweep_hits", float(OlympusHits.circle(g, e.position, r,
			float(d.get("sweep_damage_player", 8.0)) * s, float(d.get("sweep_damage_summon", 11.0)) * s * e.undead_damage_mult,
			ValgardEnemyData.SWEEP_SOURCE, e, float(d.get("sweep_push", 24.0)), _buf)))
	g.effects.impact(e.position, r, Palette.NORSE_VALKYRIE_GOLD)
	g.shake(3.0)


## The Champion's Horn: the Feast wakes (Valgard), else Einherjar rise beside him.
func _horn(e: Enemy) -> void:
	var g := e.game
	g.stat_add("champion_horns", 1.0)
	if g.norse != null:
		g.norse.play_sound("horn", e.position, 2.0)
	var woken := 0
	if g.enemies.valgard != null:
		woken = g.enemies.valgard.wake_feast(g.player.position, int(d.get("horn_wake", 3)), "champion")
	else:
		var n := int(d.get("horn_escort", 2))
		for i in n:
			if g.enemies.regular_alive() >= g.enemies.hard_cap():
				break
			var at := e.position + Vector2.from_angle(TAU * float(i) / float(maxi(1, n))) * (e.radius + 26.0)
			if g.enemies.spawn_at(ValgardEnemyData.EINHERJAR, at, false) != null:
				woken += 1
	g.stat_add("champion_horn_woken", float(woken))
	g.effects.ring(e.position, 90.0, Palette.NORSE_VALKYRIE_GOLD, 0.5)


func is_busy() -> bool:
	return phase != IDLE


## Autopilot hint: out of the sweep circle while he winds up.
func danger_push(e: Enemy, p: Vector2) -> Vector2:
	if phase != WINDUP:
		return Vector2.ZERO
	var reach := float(d.get("sweep_radius", 64.0)) + DANGER_REACH
	var off := p - e.position
	var dist := off.length()
	if dist >= reach:
		return Vector2.ZERO
	return (off / dist if dist > 0.01 else Vector2.RIGHT) * (1.0 - dist / reach) * 2.5


## The XP burst, the banner and the stats.
func on_killed(e: Enemy) -> void:
	var g := e.game
	super.on_killed(e)
	var n := maxi(1, int(d.get("reward_crystals", 12)))
	var each := maxi(1, floori(float(d.get("reward_xp", 260)) / float(n)))  # XP per crystal.
	for i in n:
		g.pickups.spawn(e.position + Vector2.from_angle(TAU * float(i) / float(n)) * (28.0 + 6.0 * float(i % 3)), each)
	g.effects.impact(e.position, e.radius * 3.0, Palette.NORSE_VALKYRIE_GOLD)
	g.shake(7.0)
	g.enemies.show_banner("The Einherjar Champion falls! A thousand years of feasting end.")
	g.stat_add("champion_kills", 1.0)
	g.stat_add("champion_ttk", g.elapsed - _spawned_at)


## Releases the HUD bar.
func on_deactivate(e: Enemy) -> void:
	super.on_deactivate(e)
	e.game.enemies.clear_miniboss(e)
