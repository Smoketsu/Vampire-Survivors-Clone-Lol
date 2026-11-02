## ChiropteranKingKit — THE CHIROPTERAN KING, Castle Sanguis's MINIBOSS
## (CastleSanguisEnemyData "chiropteran_king"; Act VII, Stage 21; GDD §15.0
## "Castle Sanguis (Act VII phase 2)"; owner-approved proposal: "Miniboss, the
## Chiropteran King, a giant bat-man who carries summons off over the ring and
## drops them outside it"). Male: leathery black-violet wings, grey-brown fur,
## a crown of bone. CastleSanguisDirector sends him (the "chiropteran_king"
## timeline event); he registers for the HUD's one miniboss bar
## (EnemyDirector.set_miniboss()) and the ChestManager drops his chest when he
## dies. A FLIER (row "flies"): CourtKit's Night Wings carry him over the ring
## and his claw blow is its swoop and bite (it feeds him: Bloodfeast). In
## flight a grounded melee summon's blow deals aloft_melee_taken of itself
## (taken_mult(); a miniboss stays within the army's reach). Between two
## attacks (attack_gap s apart) he chooses:
##   * THE CARRY-OFF (a summon within grab_range px): a dark circle marks the
##     summon nearest to him for grab_telegraph s while he dives at it; then
##     he seizes up to grab_count summons inside grab_radius px of the mark
##     and FLIES carry_time s straight away from the necromancer, toward
##     carry_out px beyond the Bone Ring's outer edge (StanceData.RING_MAX +
##     RING_LAYER), and DROPS them there: drop_damage each (time-scaled) and
##     held drop_daze s more. THE CARRY is an enemy effect on units through the
##     existing HELD HOOK (SummonedUnit.held_until, the Netcaster's net: a held
##     summon cannot walk but still strikes): every tick a carried summon is
##     held a moment longer and set under his claws (carry(), the one place
##     that moves it). Airborne, spawning, dead, charmed or already compelled
##     summons are never seized. If he dies (or the carry is cut short) they
##     drop where they are.
##   * THE GREAT SHRIEK (no summon in reach): a cone of shriek_range px,
##     shriek_arc degrees each side, at the necromancer, telegraphed
##     shriek_telegraph s: every summon in it stunned shriek_stun s through
##     THE summon stun path (CombatResolver.stun_unit()), a necromancer in it
##     struck for shriek_damage.
##   * THE COLONY (once, the first time he drops below swarm_hp of his
##     health): swarm_count Vampire Bats burst from his wings around him.
## On death: an XP burst (reward_xp in reward_crystals), the Soul Ash bounty
## (objective_ash) and the banner. No RNG (the first summon in the spatial
## hash's order; the bats on a fixed ring). Stats: king_spawned, king_grabs,
## king_carried, king_dropped, king_drop_px, king_shrieks, king_stuns,
## king_player_hits, king_aloft_grazed, king_swarm, king_kills, king_ttk.
class_name ChiropteranKingKit
extends CourtKit

## Phase: the carry-off's mark is shown while he dives at it.
const GRAB_WINDUP: int = 1
## Phase: he flies off with the seized summons.
const CARRY: int = 2
## Phase: the great shriek's cone is marked.
const SHRIEK_WINDUP: int = 3
## Phase: he hovers after an attack.
const RECOVER: int = 4
## Seconds he hovers after an attack.
const RECOVER_TIME: float = 0.5  # TUNING (not in GDD)
## Seconds a carried summon's hold is renewed each tick (it lapses on its own
## if the King stops renewing it).
const CARRY_HOLD: float = 0.2  # TUNING (not in GDD)

## Seconds until the next attack may start.
var special_cd: float = 0.0
## Unit direction of the shriek's cone / of the flight away.
var dir: Vector2 = Vector2.RIGHT
## Where the carry-off strikes (world px).
var mark: Vector2 = Vector2.ZERO
## Seized summons: [unit, generation, offset under his claws].
var carried: Array = []
## Where the flight ends (world px).
var _carry_to: Vector2 = Vector2.ZERO
## Where the flight began (drop distance stat).
var _carry_from: Vector2 = Vector2.ZERO
## True once the colony has been called.
var _swarm_called: bool = false
## Move speed of his flight (px/s; -1 until his first tick).
var _base_speed: float = -1.0
## Game time he arrived (time-to-kill stat).
var _spawned_at: float = 0.0
## Reusable query buffer.
var _buf: Array = []


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	special_cd = float(d["first_attack"])
	carried.clear()
	_swarm_called = false
	_base_speed = -1.0
	_spawned_at = e.game.elapsed
	e.game.enemies.set_miniboss(e)
	e.game.stat_add("king_spawned", 1.0)


func on_deactivate(e: Enemy) -> void:
	_drop_all(e, false)
	super.on_deactivate(e)


func physics(e: Enemy, delta: float) -> bool:
	var g := e.game
	e.knockback = Vector2.ZERO  # Immune to knockback, like the bosses.
	if not _swarm_called and e.hp <= e.max_hp * float(d["swarm_hp"]):
		_swarm_called = true
		_call_swarm(e)
	if phase == IDLE:
		if _base_speed < 0.0:
			_base_speed = e.move_speed
		var dist := e.position.distance_to(g.player.position)  # To the necromancer (px).
		e.move_speed = _base_speed * (float(d["advance_speed_mult"]) if dist > float(d["advance_range"]) else 1.0)
		special_cd -= delta
		if special_cd <= 0.0 and wing_phase == NightWings.AIR and _start(e):
			return true
		return super.physics(e, delta)  # Night Wings: his swoop and bite.
	phase_time += delta
	hold(e)
	match phase:
		GRAB_WINDUP:
			var to := mark - e.position
			if to.length() > 1.0:
				e.position += to.normalized() * minf(to.length(), float(d["carry_speed"]) * delta)  # He dives at the mark.
			if phase_time >= float(d["grab_telegraph"]):
				_seize(e)
		CARRY:
			_fly(e, delta)
			if phase_time >= float(d["carry_time"]) or e.position.distance_to(_carry_to) <= 2.0:
				_drop_all(e, true)
				set_phase(e, RECOVER)
		SHRIEK_WINDUP:
			if phase_time >= float(d["shriek_telegraph"]):
				_shriek(e)
				set_phase(e, RECOVER)
		RECOVER:
			if phase_time >= RECOVER_TIME:
				special_cd = float(d["attack_gap"])
				set_phase(e, IDLE)
	return true


## Starts the next attack: the carry-off on a summon in reach, else the great
## shriek at the necromancer (when he is in range). False when neither.
func _start(e: Enemy) -> bool:
	var g := e.game
	var reach := float(d["grab_range"])
	g.ally_grid.query(e.position, reach + UnitData.MAX_BLOCK_RADIUS, _buf)
	var pick: SummonedUnit = null
	var best := INF
	for u: SummonedUnit in _buf:
		if not _seizable(u):
			continue
		var dd := u.position.distance_to(e.position)
		if dd <= reach + u.radius and dd < best:
			best = dd
			pick = u
	if pick != null:
		mark = pick.position
		g.effects.telegraph_circle(mark, float(d["grab_radius"]), float(d["grab_telegraph"]), e)
		g.stat_add("king_grabs", 1.0)
		rules(e).play_sound("bat_screech", e.position, 0.3)
		set_phase(e, GRAB_WINDUP)
		hold(e)
		return true
	var to := g.player.position - e.position
	if to.length() > float(d["shriek_range"]) * 0.9 or g.ultimates.player_untargetable():
		return false
	dir = to.normalized() if to.length() > 0.5 else Vector2.RIGHT
	g.effects.telegraph_cone(e.position, dir, float(d["shriek_range"]), deg_to_rad(float(d["shriek_arc"])), float(d["shriek_telegraph"]), e)
	g.stat_add("king_shrieks", 1.0)
	set_phase(e, SHRIEK_WINDUP)
	hold(e)
	return true


## True when summon `u` can be seized (on the ground, alive, its own).
static func _seizable(u: SummonedUnit) -> bool:
	return u.active and not u.airborne and not u.charmed and not u.is_compelled() \
			and u.state != SummonedUnit.State.SPAWNING and u.state != SummonedUnit.State.DEAD


## He seizes up to grab_count summons around the mark and takes off away from
## the necromancer.
func _seize(e: Enemy) -> void:
	var g := e.game
	carried.clear()
	var r := float(d["grab_radius"])
	g.ally_grid.query(mark, r + UnitData.MAX_BLOCK_RADIUS, _buf)
	for u: SummonedUnit in _buf:
		if carried.size() >= int(d["grab_count"]):
			break
		if not _seizable(u) or u.position.distance_to(mark) > r + u.radius:
			continue
		var off := Vector2(-10.0 + 20.0 * float(carried.size()), e.radius * 0.6)  # Under his claws.
		carried.append([u, u.generation, off])
		u.held_until = maxf(u.held_until, g.elapsed + CARRY_HOLD)
		g.stat_add("king_carried", 1.0)
	if carried.is_empty():
		set_phase(e, RECOVER)  # They got away: he hovers and tries again.
		return
	var away := e.position - g.player.position
	dir = away.normalized() if away.length() > 1.0 else Vector2.RIGHT
	_carry_from = e.position
	_carry_to = g.player.position + dir * (StanceData.RING_MAX + StanceData.RING_LAYER + float(d["carry_out"]))
	g.effects.ring(e.position, 30.0, Palette.COURT_VELVET_LIGHT, 0.3)
	set_phase(e, CARRY)


## The flight: he flies toward the drop point; the seized summons go with him.
func _fly(e: Enemy, delta: float) -> void:
	var to := _carry_to - e.position
	var left := maxf(0.05, float(d["carry_time"]) - phase_time + delta)
	var step := minf(to.length(), minf(float(d["carry_speed"]) * delta, maxf(to.length() / left * delta, 0.0)))
	if to.length() > 0.5:
		e.position += to.normalized() * step
	carry(e)


## THE one place that moves a carried summon: each is held a moment longer and
## set under his claws (a summon that died or was recycled is let go).
func carry(e: Enemy) -> void:
	var g := e.game
	var i := carried.size() - 1
	while i >= 0:
		var rec: Array = carried[i]
		var u: SummonedUnit = rec[0]
		if not u.active or u.generation != int(rec[1]) or u.state == SummonedUnit.State.DEAD:
			carried.remove_at(i)
		else:
			u.held_until = maxf(u.held_until, g.elapsed + CARRY_HOLD)
			u.position = e.position + Vector2(rec[2])
			u.velocity = Vector2.ZERO
		i -= 1


## Drops every carried summon where it is (`hurt`: the fall's damage and daze;
## false when he dies or is pooled mid-flight: they are only let go).
func _drop_all(e: Enemy, hurt: bool) -> void:
	if carried.is_empty():
		return
	var g := e.game
	for rec: Array in carried:
		var u: SummonedUnit = rec[0]
		if not u.active or u.generation != int(rec[1]) or u.state == SummonedUnit.State.DEAD:
			continue
		u.position = g.arena.free_point(u.position, u.radius)
		g.stat_add("king_dropped", 1.0)
		g.stat_add("king_drop_px", _carry_from.distance_to(u.position))
		if hurt:
			u.held_until = maxf(u.held_until, g.elapsed + float(d["drop_daze"]))
			g.combat.damage_unit(u, float(d["drop_damage"]) * hit_scale(e) * e.undead_damage_mult, CastleSanguisEnemyData.DROP_SOURCE, e)
		else:
			u.held_until = minf(u.held_until, g.elapsed)
		g.effects.ring(u.position, u.radius * 1.6, Palette.COURT_VELVET_LIGHT, 0.25)
	carried.clear()


## The great shriek: every summon in the cone stunned, a necromancer struck.
func _shriek(e: Enemy) -> void:
	var g := e.game
	var reach := float(d["shriek_range"])
	var half := deg_to_rad(float(d["shriek_arc"]))
	g.effects.ring(e.position, reach * 0.6, Palette.COURT_MOON_LIGHT, 0.4)
	rules(e).play_sound("bat_screech", e.position)
	g.shake(3.0)
	for p in g.all_players:
		if not p.dead and in_sector(e.position, dir, reach, half, e.radius, p.position, p.radius):
			g.combat.damage_player(float(d["shriek_damage"]) * hit_scale(e), CastleSanguisEnemyData.KING_SHRIEK_SOURCE, p)
			g.stat_add("king_player_hits", 1.0)
	g.ally_grid.query(e.position, reach + UnitData.MAX_BLOCK_RADIUS, _buf)
	for u: SummonedUnit in _buf:
		if not u.active or u.state == SummonedUnit.State.DEAD:
			continue
		if in_sector(e.position, dir, reach, half, e.radius, u.position, u.radius) \
				and g.combat.stun_unit(u, float(d["shriek_stun"]), CastleSanguisEnemyData.KING_STUN) > 0.0:
			g.stat_add("king_stuns", 1.0)


## The colony: Vampire Bats burst from his wings on a ring around him.
func _call_swarm(e: Enemy) -> void:
	var g := e.game
	var n := int(d["swarm_count"])
	var made := 0
	for i in n:
		if g.enemies.regular_alive() >= g.enemies.hard_cap():
			break
		var at := e.position + Vector2.from_angle(TAU * float(i) / float(maxi(1, n))) * (e.radius + 24.0)
		if g.enemies.spawn_at(CourtEnemyData.VAMPIRE_BAT, at, false) != null:
			made += 1
	g.stat_add("king_swarm", float(made))
	g.effects.ring(e.position, 90.0, Palette.COURT_VELVET_LIGHT, 0.5)
	g.enemies.show_banner("The Chiropteran King's wings split open: a swarm of bats pours out!")


## In flight a grounded melee summon's blow deals aloft_melee_taken of itself;
## every other hit (airborne, ranged, spells, hazards) and every hit on the
## ground lands in full.
func taken_mult(e: Enemy, source: String) -> float:
	if in_flight() and FallenAngelKit.grounded_melee(source):
		e.game.stat_add("king_aloft_grazed", 1.0)
		return float(d["aloft_melee_taken"])
	return 1.0


func is_busy() -> bool:
	return phase != IDLE or super.is_busy()


## Autopilot hint: out of the shriek's cone while it is marked.
func danger_push(e: Enemy, p: Vector2) -> Vector2:
	if phase == SHRIEK_WINDUP and in_sector(e.position, dir, float(d["shriek_range"]) + 24.0, deg_to_rad(float(d["shriek_arc"])) + 0.2, e.radius, p, 12.0):
		var side := dir.orthogonal()
		var s := 1.0 if side.dot(p - e.position) >= 0.0 else -1.0
		return side * s * 1.8
	return Vector2.ZERO


## His shadow on the ground (his wingspan), over CourtKit's flier shadow.
## Visual only.
func draw_under(e: Enemy) -> void:
	super.draw_under(e)
	var r := e.radius * 2.2
	e.draw_set_transform(Vector2.ZERO, 0.0, Vector2(e.scale.x, 1.0))
	e.draw_texture_rect(SpriteBank.disc(), Rect2(-Vector2(r, r * 0.45) + Vector2(0.0, 16.0), Vector2(r, r * 0.45) * 2.0), false, Color(0.0, 0.0, 0.0, 0.18))
	e.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## The XP burst, Soul Ash bounty, banner and stats of his fall (the chest is
## ChestManager's).
func on_killed(e: Enemy) -> void:
	_drop_all(e, false)
	super.on_killed(e)
	var g := e.game
	var n := maxi(1, int(d["reward_crystals"]))
	var each := maxi(1, floori(float(d["reward_xp"]) / float(n)))  # XP per crystal.
	for i in n:
		g.pickups.spawn(e.position + Vector2.from_angle(TAU * float(i) / float(n)) * (26.0 + 6.0 * float(i % 3)), each)
	g.stat_add("objective_ash", float(d["reward_ash"]))
	g.effects.impact(e.position, e.radius * 3.0, Palette.COURT_BLOOD)
	g.shake(10.0)
	g.enemies.show_banner("The Chiropteran King falls from the sky!")
	g.stat_add("king_kills", 1.0)
	g.stat_add("king_ttk", g.elapsed - _spawned_at)
