## PolyphemusKit — POLYPHEMUS THE CYCLOPS, the Shores of Ilion's miniboss
## (IlionEnemyData "polyphemus"; Act IV, GDD §15.0 "The Shores of Ilion (Act IV
## phase 2)"; owner-approved proposal: "Miniboss, Polyphemus the Cyclops" with
## the Cyclops's "boulders with a landing circle; flat armour"). Spawned once
## by IlionDirector (the "polyphemus" timeline event, 9:00 left) through the
## normal spawn path; it registers as EnemyDirector.miniboss (the HUD's
## miniboss bar; ChestManager drops the miniboss chest). A CyclopsKit:
##   * Boulder volley — the cyclops throw with `boulders` boulders spread
##     boulder_spread px around the necromancer (every landing circle shown for
##     the whole flight).
##   * Stomp — a circle of stomp_radius px for stomp_telegraph s when the
##     necromancer or stomp_min_summons summons stand within stomp_range, then
##     his feet come down: summons inside take stomp_damage_summon and are
##     thrown out stomp_push px, the necromancer inside stomp_damage_player.
##   * Rage — below rage_hp of his max HP (once) he roars: throws come
##     rage_cd_mult as often with rage_boulders boulders.
## He walks at the necromancer with the shared melee AI, striding faster beyond
## advance_range (he never kites and is never left behind). Like a boss he
## shrugs off knockback. FLAT ARMOUR (row "flat_armor"). On death: an XP burst
## (reward_xp in reward_crystals) and the miniboss chest. No RNG. Stats:
## polyphemus_spawned, polyphemus_throws, polyphemus_boulders,
## polyphemus_boulder_hits_summon / _player, polyphemus_stomps,
## polyphemus_stomp_hits, polyphemus_rage_at, polyphemus_kills, polyphemus_ttk.
class_name PolyphemusKit
extends CyclopsKit

## Phase: the stomp circle is telegraphed.
const STOMP_WINDUP: int = 3

## Seconds until the next stomp may start.
var stomp_cd: float = 0.0
## True once he raged (below rage_hp).
var raged: bool = false
## Walking speed before the forced march (px/s; -1 = not read yet).
var _base_speed: float = -1.0
## Game time he arrived (time-to-kill stat).
var _spawned_at: float = 0.0


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	stomp_cd = 2.0
	raged = false
	_base_speed = -1.0
	_spawned_at = e.game.elapsed
	e.game.enemies.set_miniboss(e)
	e.game.stat_add("polyphemus_spawned", 1.0)


func stat_prefix() -> String:
	return "polyphemus"


func boulder_source() -> String:
	return IlionEnemyData.POLY_BOULDER_SOURCE


func boulders_now() -> int:
	return int(d["rage_boulders"] if raged else d["boulders"])


func throw_cooldown_now() -> float:
	return float(d["throw_cooldown"]) * (float(d["rage_cd_mult"]) if raged else 1.0)


## The cyclops's throw, plus the stomp, the rage and the forced march.
func physics(e: Enemy, delta: float) -> bool:
	e.knockback = Vector2.ZERO  # Immune to knockback, like the bosses.
	stomp_cd -= delta
	if not raged and e.hp <= e.max_hp * float(d["rage_hp"]):
		raged = true
		throw_cd = minf(throw_cd, 1.0)
		e.game.stat_add("polyphemus_rage_at", e.game.elapsed)
		e.game.enemies.show_banner("Polyphemus roars in rage: boulders rain down!")
		e.game.effects.impact(e.position, e.radius * 2.0, Palette.PANTHEON_BRONZE_LIGHT)
		e.game.shake(6.0)
	if phase == STOMP_WINDUP:
		turn_to(e, e.game.player.position, delta)
		_step_boulders(e, delta)
		phase_time += delta
		hold(e)
		if phase_time >= float(d["stomp_telegraph"]):
			_resolve_stomp(e)
			set_phase(e, RECOVER)
		return true
	if phase == IDLE and stomp_cd <= 0.0 and _stomp_wanted(e):
		stomp_cd = float(d["stomp_cooldown"])
		e.game.effects.telegraph_circle(e.position, float(d["stomp_radius"]), float(d["stomp_telegraph"]), e)
		e.motion_lunge(Vector2.ZERO, MotionData.POWER_CAST)
		e.game.stat_add("polyphemus_stomps", 1.0)
		set_phase(e, STOMP_WINDUP)
		return true
	if phase == IDLE:
		if _base_speed < 0.0:
			_base_speed = e.move_speed
		var far := e.position.distance_to(e.game.player.position) > float(d["advance_range"])  # Left behind.
		e.move_speed = _base_speed * (float(d["advance_speed_mult"]) if far else 1.0)
	return super.physics(e, delta)


## True when the necromancer or enough summons stand within stomp_range.
func _stomp_wanted(e: Enemy) -> bool:
	var g := e.game
	var r := float(d["stomp_range"])  # px.
	if e.position.distance_to(g.player.position) <= r + g.player.radius + e.radius:
		return true
	g.ally_grid.query(e.position, r + e.radius + UnitData.MAX_BLOCK_RADIUS, _tmp)
	var n := 0
	for u: SummonedUnit in _tmp:
		if u.active and u.position.distance_to(e.position) <= r + e.radius + u.radius:
			n += 1
	return n >= int(d["stomp_min_summons"])


## His feet come down: summons inside are hurt and thrown out.
func _resolve_stomp(e: Enemy) -> void:
	var g := e.game
	var r := float(d["stomp_radius"])  # px.
	var mult := CovenantKit.hit_scale(e)  # Time scaling x buffs.
	g.effects.impact(e.position, r, Palette.PANTHEON_MARBLE)
	if g.pantheon != null:
		g.pantheon.play_sound("boulder_land", e.position)
	g.shake(7.0)
	var hits := 0
	g.ally_grid.query(e.position, r + UnitData.MAX_BLOCK_RADIUS, _tmp)
	for u: SummonedUnit in _tmp:
		if not u.active or u.state == SummonedUnit.State.SPAWNING or u.position.distance_to(e.position) > r + u.radius:
			continue
		hits += 1
		var away := u.position - e.position
		u.position += (away.normalized() if away.length() > 0.5 else Vector2.UP) * float(d["stomp_push"])
		g.combat.damage_unit(u, float(d["stomp_damage_summon"]) * mult, IlionEnemyData.POLY_STOMP_SOURCE, e)
	g.stat_add("polyphemus_stomp_hits", float(hits))
	for p in g.all_players:  # (Co-op: every necromancer inside.)
		if p.position.distance_to(e.position) <= r + p.radius:
			g.combat.damage_player(float(d["stomp_damage_player"]) * mult, IlionEnemyData.POLY_STOMP_SOURCE, p)


## The XP burst, banner and stats of his fall (the chest is ChestManager's).
func on_killed(e: Enemy) -> void:
	var g := e.game
	var n := maxi(1, int(d["reward_crystals"]))
	var each := maxi(1, floori(float(d["reward_xp"]) / float(n)))  # XP per crystal.
	for i in n:
		g.pickups.spawn(e.position + Vector2.from_angle(TAU * float(i) / float(n)) * (26.0 + 6.0 * float(i % 3)), each)
	g.effects.impact(e.position, e.radius * 3.0, Palette.PANTHEON_BRONZE_LIGHT)
	g.shake(10.0)
	g.enemies.show_banner("Polyphemus falls: the shore shakes!")
	g.stat_add("polyphemus_kills", 1.0)
	g.stat_add("polyphemus_ttk", g.elapsed - _spawned_at)


## Releases the HUD bar.
func on_deactivate(e: Enemy) -> void:
	super.on_deactivate(e)
	e.game.enemies.clear_miniboss(e)


## Autopilot hint: out of the stomp circle, else out of a landing circle.
func danger_push(e: Enemy, p: Vector2) -> Vector2:
	if phase == STOMP_WINDUP:
		var away := p - e.position
		if away.length() < float(d["stomp_radius"]) + 30.0:
			return away.normalized() if away.length() > 0.1 else Vector2.RIGHT
	return super.danger_push(e, p)
