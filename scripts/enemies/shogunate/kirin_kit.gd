## KirinKit — THE KIRIN, a holy beast of light, the Road to the Sun's MINIBOSS
## (SunRoadEnemyData "kirin"; Act V, Stage 15; GDD §15.0 "The Road to the Sun
## (Act V phase 2)"; owner-approved proposal: "Miniboss, the Kirin (a holy
## beast of light)"). SunRoadDirector sends it (the "kirin" timeline event); it
## registers for the HUD's one miniboss bar (EnemyDirector.set_miniboss()) and
## the ChestManager drops its chest when it dies. It walks at the necromancer
## with the shared melee AI (enemies always advance), striding faster when
## left behind, shrugs off knockback like a boss, and takes turns between two
## attacks (attack_gap s apart):
##   * THE GOLDEN GALLOP (when the necromancer is at least gallop_min px away):
##     a lane gallop_length px long and gallop_width wide from it through him,
##     telegraphed gallop_telegraph s (EffectManager.telegraph_line), then it
##     gallops down the lane in gallop_time s (never through an obstacle:
##     Arena.clear_length()); every body in the lane when it sets off is struck
##     once (gallop_damage_player / _summon) and summons are thrown gallop_push
##     px aside.
##   * THE HORN OF HEAVEN: horn_rays rays of light horn_length px long around
##     it, the first aimed at the necromancer, telegraphed horn_telegraph s;
##     then they flash: every body on a ray is struck (horn_damage_*, HOLY).
##   * ITS HALO: every halo_tick s each summon within halo_radius px of it takes
##     halo_damage (HOLY: Unholy Resilience applies).
## Every blow is x CovenantKit.hit_scale() (the enemies' time scaling x its
## buffs) and goes through CombatResolver. On death: an XP burst (reward_xp in
## reward_crystals), the Soul Ash bounty (objective_ash) and the banner. No
## RNG. Stats: kirin_spawned, kirin_gallops, kirin_horns, kirin_player_hits,
## kirin_summon_hits, kirin_halo_ticks, kirin_kills, kirin_ttk.
class_name KirinKit
extends ShogunateKit

## Phase: the gallop's lane is telegraphed.
const GALLOP_WINDUP: int = 1
## Phase: it gallops down the lane.
const GALLOP: int = 2
## Phase: the horn's rays are telegraphed.
const HORN_WINDUP: int = 3
## Phase: it stands after an attack.
const RECOVER: int = 4

## Seconds until the next attack may start.
var special_cd: float = 0.0
## True when the gallop comes next (the two attacks take turns).
var _gallop_next: bool = true
## Unit direction of the current gallop / the first ray.
var dir: Vector2 = Vector2.RIGHT
## Where the gallop starts and ends (world px).
var _from: Vector2 = Vector2.ZERO
## Where the gallop ends (world px).
var _to: Vector2 = Vector2.ZERO
## Seconds until the next halo burn.
var _halo_cd: float = 0.0
## Move speed of its walk (px/s; -1 until its first tick).
var _base_speed: float = -1.0
## Game time it arrived (time-to-kill stat).
var _spawned_at: float = 0.0
## Reusable query buffer.
var _buf: Array = []


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	special_cd = float(d["first_attack"])
	_gallop_next = true
	_halo_cd = float(d["halo_tick"])
	_base_speed = -1.0
	_spawned_at = e.game.elapsed
	e.game.enemies.set_miniboss(e)
	e.game.stat_add("kirin_spawned", 1.0)


func physics(e: Enemy, delta: float) -> bool:
	var g := e.game
	e.knockback = Vector2.ZERO  # Immune to knockback, like the bosses.
	_halo_cd -= delta
	if _halo_cd <= 0.0:
		_halo_cd += float(d["halo_tick"])
		_halo(e)
	if phase == IDLE:
		special_cd -= delta
		if _base_speed < 0.0:
			_base_speed = e.move_speed
		var dist := e.position.distance_to(g.player.position)  # To the necromancer (px).
		e.move_speed = _base_speed * (float(d["advance_speed_mult"]) if dist > float(d["advance_range"]) else 1.0)
		if special_cd <= 0.0:
			_start(e, dist)
		return phase != IDLE
	phase_time += delta
	match phase:
		GALLOP_WINDUP:
			hold(e)
			if phase_time >= float(d["gallop_telegraph"]):
				_launch(e)
				set_phase(e, GALLOP)
		GALLOP:
			var k := clampf(phase_time / maxf(0.01, float(d["gallop_time"])), 0.0, 1.0)  # 0 -> 1 down the lane.
			e.position = _from.lerp(_to, k)
			e.velocity = (_to - _from) / maxf(0.01, float(d["gallop_time"]))
			if k >= 1.0:
				e.velocity = Vector2.ZERO
				set_phase(e, RECOVER)
		HORN_WINDUP:
			hold(e)
			if phase_time >= float(d["horn_telegraph"]):
				_rays(e)
				set_phase(e, RECOVER)
		RECOVER:
			hold(e)
			if phase_time >= float(d["recover_time"]):
				special_cd = float(d["attack_gap"])
				set_phase(e, IDLE)
	return true


## Starts the next attack (the gallop and the horn take turns; the gallop
## needs the necromancer at least gallop_min px away, else the horn comes).
func _start(e: Enemy, dist: float) -> void:
	var g := e.game
	var to := g.player.position - e.position
	dir = to.normalized() if to.length() > 1.0 else Vector2.RIGHT
	if _gallop_next and dist >= float(d["gallop_min"]) and not g.ultimates.player_untargetable():
		_gallop_next = false
		var length := g.arena.clear_length(e.position, dir, float(d["gallop_length"]), e.radius)  # Never through an obstacle.
		_from = e.position
		_to = e.position + dir * length
		g.effects.telegraph_line(_from, _to, float(d["gallop_width"]), float(d["gallop_telegraph"]), e)
		g.stat_add("kirin_gallops", 1.0)
		set_phase(e, GALLOP_WINDUP)
	else:
		_gallop_next = true
		var n := int(d["horn_rays"])
		for i in n:
			var a := dir.rotated(TAU * float(i) / float(maxi(1, n)))
			g.effects.telegraph_line(e.position, e.position + a * float(d["horn_length"]), float(d["horn_width"]), float(d["horn_telegraph"]), e)
		g.stat_add("kirin_horns", 1.0)
		set_phase(e, HORN_WINDUP)
	e.motion_lunge(dir, MotionData.POWER_CAST)
	hold(e)


## The gallop sets off: every body in the lane now is struck once, summons are
## thrown aside.
func _launch(e: Enemy) -> void:
	var g := e.game
	var half := float(d["gallop_width"]) * 0.5  # Lane half-width (px).
	var mult := hit_scale(e)
	Sfx.play("kirin_gallop", e.position)
	g.effects.beam(_from, _to, Palette.GOLD)
	g.shake(4.0)
	for p in g.all_players:
		if DivineWrath._seg_dist(p.position, _from, _to) <= half + p.radius:
			g.combat.damage_player(float(d["gallop_damage_player"]) * mult, SunRoadEnemyData.KIRIN_GALLOP_SOURCE, p)
			g.stat_add("kirin_player_hits", 1.0)
	g.ally_grid.query(_from.lerp(_to, 0.5), _from.distance_to(_to) * 0.5 + half + UnitData.MAX_BLOCK_RADIUS, _buf)
	var side := dir.orthogonal()
	for u: SummonedUnit in _buf:
		if not u.active or u.airborne or u.state == SummonedUnit.State.SPAWNING:
			continue
		if DivineWrath._seg_dist(u.position, _from, _to) > half + u.radius:
			continue
		var s := 1.0 if (u.position - _from).dot(side) >= 0.0 else -1.0  # Thrown to its own side of the lane.
		u.position += side * s * float(d["gallop_push"])
		g.combat.damage_unit(u, float(d["gallop_damage_summon"]) * mult, SunRoadEnemyData.KIRIN_GALLOP_SOURCE, e)
		g.stat_add("kirin_summon_hits", 1.0)


## The Horn of Heaven's rays flash: every body on one is struck.
func _rays(e: Enemy) -> void:
	var g := e.game
	var n := int(d["horn_rays"])
	var length := float(d["horn_length"])
	var half := float(d["horn_width"]) * 0.5
	var mult := hit_scale(e)
	Sfx.play("kirin_horn", e.position)
	g.effects.ring(e.position, e.radius * 2.2, Palette.GOLD, 0.4)
	var hit_p: Dictionary = {}  # Necromancers already struck (one ray each).
	var hit_u: Dictionary = {}  # Summons already struck.
	g.ally_grid.query(e.position, length + UnitData.MAX_BLOCK_RADIUS, _buf)
	for i in n:
		var a := dir.rotated(TAU * float(i) / float(maxi(1, n)))
		var b := e.position + a * length
		g.effects.beam(e.position, b, Palette.GOLD)
		for p in g.all_players:
			if not hit_p.has(p) and DivineWrath._seg_dist(p.position, e.position, b) <= half + p.radius:
				hit_p[p] = true
				g.combat.damage_player(float(d["horn_damage_player"]) * mult, SunRoadEnemyData.KIRIN_HORN_SOURCE, p)
				g.stat_add("kirin_player_hits", 1.0)
		for u: SummonedUnit in _buf:
			if hit_u.has(u) or not u.active or u.airborne or u.state == SummonedUnit.State.SPAWNING:
				continue
			if DivineWrath._seg_dist(u.position, e.position, b) <= half + u.radius:
				hit_u[u] = true
				g.combat.damage_unit(u, float(d["horn_damage_summon"]) * mult, SunRoadEnemyData.KIRIN_HORN_SOURCE, e)
				g.stat_add("kirin_summon_hits", 1.0)


## Its halo burns the summons near it (holy).
func _halo(e: Enemy) -> void:
	var g := e.game
	var r := float(d["halo_radius"])
	var dmg := float(d["halo_damage"]) * hit_scale(e)
	g.ally_grid.query(e.position, r + UnitData.MAX_BLOCK_RADIUS, _buf)
	var n := 0
	for u: SummonedUnit in _buf:
		if not u.active or u.state == SummonedUnit.State.SPAWNING or u.state == SummonedUnit.State.DEAD:
			continue
		if u.position.distance_to(e.position) > r + u.radius:
			continue
		g.combat.damage_unit(u, dmg, SunRoadEnemyData.KIRIN_HALO_SOURCE, e)
		n += 1
	if n > 0:
		g.stat_add("kirin_halo_ticks", float(n))


func is_busy() -> bool:
	return phase != IDLE


## Autopilot hint: out of the gallop's lane and off the horn's rays while they
## are telegraphed.
func danger_push(e: Enemy, p: Vector2) -> Vector2:
	match phase:
		GALLOP_WINDUP:
			return _off_line(p, _from, _to, float(d["gallop_width"]) * 0.5 + 18.0)
		HORN_WINDUP:
			var push := Vector2.ZERO
			var n := int(d["horn_rays"])
			for i in n:
				var a := dir.rotated(TAU * float(i) / float(maxi(1, n)))
				push += _off_line(p, e.position, e.position + a * float(d["horn_length"]), float(d["horn_width"]) * 0.5 + 18.0)
			return push
	return Vector2.ZERO


## A push sideways off the segment a-b when `p` is within `reach` px of it.
static func _off_line(p: Vector2, a: Vector2, b: Vector2, reach: float) -> Vector2:
	var ab := b - a
	var t := clampf((p - a).dot(ab) / maxf(ab.length_squared(), 0.01), 0.0, 1.0)
	var off := p - (a + ab * t)
	var dist := off.length()
	if dist >= reach:
		return Vector2.ZERO
	var n := off / dist if dist > 0.01 else ab.normalized().orthogonal()
	return n * (1.0 - dist / reach) * 1.5


## Its halo of light on the ground. Visual only.
func draw_under(e: Enemy) -> void:
	var r := float(d["halo_radius"])
	e.draw_set_transform(Vector2.ZERO, 0.0, Vector2(e.scale.x, 1.0))
	e.draw_texture_rect(SpriteBank.disc(), Rect2(-Vector2(r, r), Vector2(r, r) * 2.0), false, Color(Palette.GOLD, 0.10))
	e.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## The XP burst, Soul Ash bounty, banner and stats of its fall (the chest is
## ChestManager's).
func on_killed(e: Enemy) -> void:
	var g := e.game
	var n := maxi(1, int(d["reward_crystals"]))
	var each := maxi(1, floori(float(d["reward_xp"]) / float(n)))  # XP per crystal.
	for i in n:
		g.pickups.spawn(e.position + Vector2.from_angle(TAU * float(i) / float(n)) * (26.0 + 6.0 * float(i % 3)), each)
	g.stat_add("objective_ash", float(d["reward_ash"]))
	g.effects.impact(e.position, e.radius * 3.0, Palette.GOLD)
	g.shake(10.0)
	g.enemies.show_banner("The Kirin falls: its light goes out!")
	g.stat_add("kirin_kills", 1.0)
	g.stat_add("kirin_ttk", g.elapsed - _spawned_at)
