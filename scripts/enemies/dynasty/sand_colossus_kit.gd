## SandColossusKit — THE SAND COLOSSUS, the Necropolis of Sand's miniboss
## (NecropolisEnemyData "sand_colossus"; temporary Act XII, the Necropolis
## Dynasty; GDD §15.0 "The Necropolis of Sand (Act XII phase 2)";
## owner-approved proposal: "A huge statue; ground slam | Burst; stay at
## range"). A walking sandstone king spawned by NecropolisDirector's
## "colossus" event; he registers as EnemyDirector.miniboss (the HUD's
## miniboss bar; ChestManager drops the miniboss chest on his fall: the row's
## "miniboss"). The shared melee AI walks him in; his stone fists strike in
## reach. His special, THE GROUND SLAM: every slam_every s (the first
## slam_first s after he arrives) once a summon or a standing necromancer is
## within slam_radius px, he raises both fists for slam_windup s (a telegraph
## circle round him; the autotest bot steps out) and slams: every summon and
## necromancer within slam_radius takes slam_damage_summon / slam_damage (x
## the time scaling and his own hit multiplier) through damage_unit() /
## damage_player(), each summon hit is stunned slam_stun s
## (CombatResolver.stun_unit(), the one summon stun path), and the broken
## ground turns to quicksand (Quicksand.add_patch(), THE public call; on the
## Dynasty only). A statue: no Rebirth (group "stone"). On death: an XP burst
## (reward_xp in reward_crystals). Determinism: no RNG. Stats: colossus_slams,
## colossus_slam_hits, colossus_slam_on_you, colossus_kills, colossus_ttk.
class_name SandColossusKit
extends DynastyKit

## Phase: both fists raised before the slam.
const WINDUP: int = 1
## px the autotest bot keeps beyond the slam's edge (autotest hint only).
const DANGER_MARGIN: float = 22.0  # TUNING (not in GDD) autotest hint only

## Seconds until the next slam may start.
var _cd: float = 0.0
## Game time (s) he arrived (his time to kill).
var spawned_at: float = 0.0
## Ally query buffer.
var _tmp: Array = []


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	_cd = first_cd(e, float(d.get("slam_first", 3.0)))
	spawned_at = e.game.elapsed
	e.game.enemies.set_miniboss(e)


func physics(e: Enemy, delta: float) -> bool:
	super.physics(e, delta)
	if phase == WINDUP:
		hold(e)
		phase_time += delta
		if phase_time >= float(d["slam_windup"]):
			_slam(e)
			set_phase(e, IDLE)
			_cd = float(d["slam_every"])
		return true
	_cd -= delta
	if _cd <= 0.0 and _body_near(e, float(d["slam_radius"])):
		set_phase(e, WINDUP)
		e.game.effects.telegraph_circle(e.position, float(d["slam_radius"]), float(d["slam_windup"]), e)
		hold(e)
		return true
	return false


## True when a summon or a standing necromancer is within `r` px of him.
func _body_near(e: Enemy, r: float) -> bool:
	var g := e.game
	for pl in g.all_players:
		if not pl.dead and pl.position.distance_to(e.position) <= r + pl.radius:
			return true
	g.ally_grid.query(e.position, r + UnitData.MAX_BLOCK_RADIUS, _tmp)
	for u: SummonedUnit in _tmp:
		if u.active and u.state != SummonedUnit.State.SPAWNING and u.position.distance_to(e.position) <= r + u.radius:
			return true
	return false


## The slam: every body within the radius takes it; summons are stunned; the
## ground turns to quicksand.
func _slam(e: Enemy) -> void:
	var g := e.game
	var r := float(d["slam_radius"])
	var mult := hit_scale(e)
	var hits := 0
	g.ally_grid.query(e.position, r + UnitData.MAX_BLOCK_RADIUS, _tmp)
	for u: SummonedUnit in _tmp.duplicate():
		if not u.active or u.state == SummonedUnit.State.SPAWNING or u.state == SummonedUnit.State.DEAD or u.airborne:
			continue
		if u.position.distance_to(e.position) > r + u.radius:
			continue
		g.combat.damage_unit(u, float(d["slam_damage_summon"]) * mult * e.undead_damage_mult, NecropolisEnemyData.SLAM_SOURCE, e)
		if u.active:
			g.combat.stun_unit(u, float(d["slam_stun"]), NecropolisEnemyData.SLAM_SOURCE)
		hits += 1
	for pl in g.all_players:
		if not pl.dead and pl.position.distance_to(e.position) <= r + pl.radius:
			g.combat.damage_player(float(d["slam_damage"]) * mult, NecropolisEnemyData.SLAM_SOURCE, pl, e)
			g.stat_add("colossus_slam_on_you", 1.0)
	if g.dynasty != null and g.dynasty.enabled:
		g.dynasty.quicksand.add_patch(e.position, float(d["slam_sand"]), float(d["slam_sand_life"]))
	g.stat_add("colossus_slams", 1.0)
	g.stat_add("colossus_slam_hits", float(hits))
	g.effects.impact(e.position, r, Palette.DYN_SAND)
	g.shake(5.0)
	Sfx.play("boss_impact", e.position, 0.5)


## The XP burst and the stats of his fall (the chest is ChestManager's).
func on_killed(e: Enemy) -> void:
	super.on_killed(e)
	var g := e.game
	var n := maxi(1, int(d.get("reward_crystals", 10)))
	var each := maxi(1, floori(float(d.get("reward_xp", 200)) / float(n)))  # XP per crystal.
	for i in n:
		g.pickups.spawn(e.position + Vector2.from_angle(TAU * float(i) / float(n)) * (24.0 + 6.0 * float(i % 3)), each)
	g.effects.impact(e.position, e.radius * 3.0, Palette.DYN_SAND_LIGHT)
	g.shake(8.0)
	g.stat_add("colossus_kills", 1.0)
	g.stat_add("colossus_ttk", g.elapsed - spawned_at)


## Releases the HUD bar.
func on_deactivate(e: Enemy) -> void:
	super.on_deactivate(e)
	e.game.enemies.clear_miniboss(e)


func is_busy() -> bool:
	return phase != IDLE


## Autopilot hint: out of the slam's circle while his fists are raised.
func danger_push(e: Enemy, p: Vector2) -> Vector2:
	if phase != WINDUP:
		return Vector2.ZERO
	var reach := float(d["slam_radius"]) + DANGER_MARGIN
	var off := p - e.position
	var dist := off.length()
	if dist >= reach:
		return Vector2.ZERO
	return (off / dist if dist > 0.01 else Vector2.RIGHT) * (1.0 - dist / reach) * 3.0
