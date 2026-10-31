## SeraphGeneralKit — THE FALLEN SERAPH GENERAL, Pandemonium's MINIBOSS
## (PandemoniumEnemyData "seraph_general"; Act VI, Stage 18; GDD §15.0
## "Pandemonium (Act VI phase 2)"; owner-approved proposal: "Miniboss, the
## Fallen Seraph General"). A male fallen archangel warlord: four burnt wings,
## a broken halo crown, black and gold plate, a burning greatsword. A DEMON
## (the pits spare him). PandemoniumDirector sends him (the "seraph_general"
## timeline event); he registers for the HUD's one miniboss bar
## (EnemyDirector.set_miniboss()) and the ChestManager drops his chest when he
## dies. He walks at the necromancer with the shared melee AI (enemies always
## advance), striding faster when left behind, shrugs off knockback like a
## boss, and takes turns between two attacks (attack_gap s apart):
##   * JUDGMENT CLEAVE (a body within cleave_trigger px): a cone of
##     cleave_range px and cleave_arc degrees each side toward the necromancer
##     (or his target), telegraphed cleave_telegraph s
##     (EffectManager.telegraph_cone); every body in it is struck
##     (cleave_damage_player / _summon, HOLY), summons thrown cleave_push px
##     back (never into an obstacle); on an Act VI stage the blade's tip cracks
##     the ground into a Hell Pit (HellPits.open_pit(), tag "seraph_general").
##   * WINGS OF RUIN: feather_rays lines of burnt feathers feather_length px
##     long around him, the first at the necromancer, telegraphed
##     feather_telegraph s; then they fly: every body on a line is struck once
##     (feather_damage_*).
##   * THE FALLEN HOST (once, the first time he drops below host_hp of his
##     health): host_count Fallen Angels land on a ring host_distance px
##     around the necromancer (the hard cap respected).
## Every blow is x CovenantKit.hit_scale() (the time scaling x his buffs) and
## goes through CombatResolver. On death: an XP burst (reward_xp in
## reward_crystals), the Soul Ash bounty (objective_ash) and the banner. No
## RNG (the host's ring starts at a fixed angle). Stats: seraph_general_spawned,
## seraph_general_cleaves, seraph_general_feathers, seraph_general_player_hits,
## seraph_general_summon_hits, seraph_general_pits, seraph_general_host,
## seraph_general_kills, seraph_general_ttk.
class_name SeraphGeneralKit
extends InfernoKit

## Phase: the cleave's cone is telegraphed.
const CLEAVE_WINDUP: int = 1
## Phase: the feathers' lines are telegraphed.
const FEATHER_WINDUP: int = 2
## Phase: he stands after an attack.
const RECOVER: int = 3

## Seconds until the next attack may start.
var special_cd: float = 0.0
## Unit direction of the current cleave / the first feather line.
var dir: Vector2 = Vector2.RIGHT
## True once the Fallen Host has been called.
var _host_called: bool = false
## Move speed of his walk (px/s; -1 until his first tick).
var _base_speed: float = -1.0
## Game time he arrived (time-to-kill stat).
var _spawned_at: float = 0.0
## Reusable query buffer.
var _buf: Array = []


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	special_cd = float(d["first_attack"])
	_host_called = false
	_base_speed = -1.0
	_spawned_at = e.game.elapsed
	e.game.enemies.set_miniboss(e)
	e.game.stat_add("seraph_general_spawned", 1.0)


func physics(e: Enemy, delta: float) -> bool:
	var g := e.game
	e.knockback = Vector2.ZERO  # Immune to knockback, like the bosses.
	if not _host_called and e.hp <= e.max_hp * float(d["host_hp"]):
		_host_called = true
		_call_host(e)
	if phase == IDLE:
		special_cd -= delta
		if _base_speed < 0.0:
			_base_speed = e.move_speed
		var dist := e.position.distance_to(g.player.position)  # To the necromancer (px).
		e.move_speed = _base_speed * (float(d["advance_speed_mult"]) if dist > float(d["advance_range"]) else 1.0)
		if special_cd <= 0.0:
			_start(e)
		return phase != IDLE
	phase_time += delta
	hold(e)
	match phase:
		CLEAVE_WINDUP:
			if phase_time >= float(d["cleave_telegraph"]):
				_cleave(e)
				set_phase(e, RECOVER)
		FEATHER_WINDUP:
			if phase_time >= float(d["feather_telegraph"]):
				_feathers(e)
				set_phase(e, RECOVER)
		RECOVER:
			if phase_time >= float(d["recover_time"]):
				special_cd = float(d["attack_gap"])
				set_phase(e, IDLE)
	return true


## Starts the next attack: the cleave at a body in reach, else the feathers.
func _start(e: Enemy) -> void:
	var g := e.game
	var t: Node2D = e.target if e.target != null and is_instance_valid(e.target) else g.player
	var to := t.position - e.position
	var near := to.length() <= float(d["cleave_trigger"]) + e.radius
	if not near:
		to = g.player.position - e.position
	dir = to.normalized() if to.length() > 1.0 else Vector2.RIGHT
	if near:
		g.effects.telegraph_cone(e.position, dir, float(d["cleave_range"]), deg_to_rad(float(d["cleave_arc"])), float(d["cleave_telegraph"]), e)
		g.stat_add("seraph_general_cleaves", 1.0)
		set_phase(e, CLEAVE_WINDUP)
	else:
		var n := int(d["feather_rays"])
		for i in n:
			var a := dir.rotated(TAU * float(i) / float(maxi(1, n)))
			g.effects.telegraph_line(e.position, e.position + a * float(d["feather_length"]), float(d["feather_width"]), float(d["feather_telegraph"]), e)
		g.stat_add("seraph_general_feathers", 1.0)
		set_phase(e, FEATHER_WINDUP)
	e.motion_lunge(dir, MotionData.POWER_CAST)
	hold(e)


## The Judgment Cleave lands: every body in the cone is struck; the summons
## are thrown back; the blade's tip cracks the ground (Act VI).
func _cleave(e: Enemy) -> void:
	var g := e.game
	var reach := float(d["cleave_range"])
	var half := deg_to_rad(float(d["cleave_arc"]))
	var mult := hit_scale(e)
	g.effects.slash(e.position + dir * reach * 0.5, dir, Palette.INFERNO_LAVA, reach)
	rules(e).play_sound("brute_slam", e.position)
	g.shake(4.0)
	for p in g.all_players:
		if not p.dead and in_sector(e.position, dir, reach, half, e.radius, p.position, p.radius):
			g.combat.damage_player(float(d["cleave_damage_player"]) * mult, PandemoniumEnemyData.CLEAVE_SOURCE, p)
			g.stat_add("seraph_general_player_hits", 1.0)
	g.ally_grid.query(e.position, reach + UnitData.MAX_BLOCK_RADIUS, _buf)
	for u: SummonedUnit in _buf:
		if not u.active or u.airborne or u.state == SummonedUnit.State.SPAWNING or u.state == SummonedUnit.State.DEAD:
			continue
		if not in_sector(e.position, dir, reach, half, e.radius, u.position, u.radius):
			continue
		g.combat.damage_unit(u, float(d["cleave_damage_summon"]) * mult, PandemoniumEnemyData.CLEAVE_SOURCE, e)
		g.stat_add("seraph_general_summon_hits", 1.0)
		if u.active and u.state != SummonedUnit.State.DEAD:
			var away := (u.position - e.position).normalized() if u.position.distance_squared_to(e.position) > 1.0 else dir
			u.position += away * g.arena.clear_length(u.position, away, float(d["cleave_push"]), u.radius)
	var inf := g.inferno
	if inf != null and inf.enabled and float(d["cleave_pit_radius"]) > 0.0:
		var tip := e.position + dir * g.arena.clear_length(e.position, dir, reach, 4.0)  # The blade's tip, short of any obstacle.
		if inf.pits.open_pit(tip, float(d["cleave_pit_radius"]), float(d["cleave_pit_life"]), {"tag": "seraph_general"}):
			g.stat_add("seraph_general_pits", 1.0)


## The Wings of Ruin fly: every body on a feather line is struck once.
func _feathers(e: Enemy) -> void:
	var g := e.game
	var n := int(d["feather_rays"])
	var length := float(d["feather_length"])
	var half := float(d["feather_width"]) * 0.5
	var mult := hit_scale(e)
	g.effects.ring(e.position, e.radius * 2.2, Palette.INFERNO_LAVA, 0.4)
	rules(e).play_sound("portal_open", e.position)
	var hit_p: Dictionary = {}  # Necromancers already struck (one line each).
	var hit_u: Dictionary = {}  # Summons already struck.
	g.ally_grid.query(e.position, length + UnitData.MAX_BLOCK_RADIUS, _buf)
	for i in n:
		var a := dir.rotated(TAU * float(i) / float(maxi(1, n)))
		var b := e.position + a * length
		g.effects.beam(e.position, b, Palette.INFERNO_OBSIDIAN_LIGHT)
		for p in g.all_players:
			if not p.dead and not hit_p.has(p) and DivineWrath._seg_dist(p.position, e.position, b) <= half + p.radius:
				hit_p[p] = true
				g.combat.damage_player(float(d["feather_damage_player"]) * mult, PandemoniumEnemyData.FEATHER_SOURCE, p)
				g.stat_add("seraph_general_player_hits", 1.0)
		for u: SummonedUnit in _buf:
			if hit_u.has(u) or not u.active or u.state == SummonedUnit.State.SPAWNING or u.state == SummonedUnit.State.DEAD:
				continue
			if DivineWrath._seg_dist(u.position, e.position, b) <= half + u.radius:
				hit_u[u] = true
				g.combat.damage_unit(u, float(d["feather_damage_summon"]) * mult, PandemoniumEnemyData.FEATHER_SOURCE, e)
				g.stat_add("seraph_general_summon_hits", 1.0)


## The Fallen Host: Fallen Angels land on a ring around the necromancer.
func _call_host(e: Enemy) -> void:
	var g := e.game
	var n := int(d["host_count"])
	var p := g.player.position
	var dist := float(d["host_distance"])
	var called := 0
	for i in n:
		if g.enemies.regular_alive() >= g.enemies.hard_cap():
			break
		var at := g.arena.free_point(p + Vector2.from_angle(TAU * float(i) / float(maxi(1, n)) - PI * 0.5) * dist, 10.0)
		if g.enemies.spawn_at(PandemoniumEnemyData.FALLEN_ANGEL, at, false) != null:
			called += 1
			g.effects.ring(at, 30.0, Palette.GOLD, 0.5)
	g.stat_add("seraph_general_host", float(called))
	g.enemies.show_banner("The General calls the Fallen Host: angels dive from the burning sky!")


func is_busy() -> bool:
	return phase != IDLE


## Autopilot hint: out of the cleave's cone and off the feather lines while
## they are telegraphed.
func danger_push(e: Enemy, p: Vector2) -> Vector2:
	match phase:
		CLEAVE_WINDUP:
			if in_sector(e.position, dir, float(d["cleave_range"]) + 24.0, deg_to_rad(float(d["cleave_arc"])) + 0.2, e.radius, p, 12.0):
				var away := p - e.position
				return away.normalized() * 1.5 if away.length() > 0.1 else Vector2.RIGHT
		FEATHER_WINDUP:
			var push := Vector2.ZERO
			var n := int(d["feather_rays"])
			for i in n:
				var a := dir.rotated(TAU * float(i) / float(maxi(1, n)))
				push += KirinKit._off_line(p, e.position, e.position + a * float(d["feather_length"]), float(d["feather_width"]) * 0.5 + 18.0)
			return push
	return Vector2.ZERO


## His burning shadow on the ground (the wings' reach). Visual only.
func draw_under(e: Enemy) -> void:
	var r := e.radius * 2.4
	e.draw_set_transform(Vector2.ZERO, 0.0, Vector2(e.scale.x, 1.0))
	e.draw_texture_rect(SpriteBank.disc(), Rect2(-Vector2(r, r * 0.5), Vector2(r, r * 0.5) * 2.0), false, Color(Palette.INFERNO_LAVA, 0.10))
	e.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## The XP burst, Soul Ash bounty, banner and stats of his fall (the chest is
## ChestManager's).
func on_killed(e: Enemy) -> void:
	super.on_killed(e)
	var g := e.game
	var n := maxi(1, int(d["reward_crystals"]))
	var each := maxi(1, floori(float(d["reward_xp"]) / float(n)))  # XP per crystal.
	for i in n:
		g.pickups.spawn(e.position + Vector2.from_angle(TAU * float(i) / float(n)) * (26.0 + 6.0 * float(i % 3)), each)
	g.stat_add("objective_ash", float(d["reward_ash"]))
	g.effects.impact(e.position, e.radius * 3.0, Palette.INFERNO_LAVA)
	g.shake(10.0)
	g.enemies.show_banner("The Fallen Seraph General falls: his wings burn out!")
	g.stat_add("seraph_general_kills", 1.0)
	g.stat_add("seraph_general_ttk", g.elapsed - _spawned_at)
