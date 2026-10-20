## TideCallerKit — the Tide Caller's water line (Act II, Gullhaven Harbour;
## HarbourEnemyData "tide_caller", GDD §15.0 "Gullhaven Harbour (Act II phase
## 2)"; owner-approved roster "raises a line of water that knocks summons
## back"). Her body is the shared "melee" AI: she always advances on her
## target and strikes with her conch staff in contact. On top of that:
##   * Water line: when the cooldown is up and a summon (or the necromancer) is
##     within wall_trigger px, she stops and raises her staff: a line
##     wall_length px long and wall_width px wide is telegraphed across the
##     way to the necromancer, its centre wall_distance px in front of her
##     (locked), for wall_telegraph s. Then the water rises: summons in the
##     line are thrown wall_push px back (away from her) and take
##     wall_damage_summon; the necromancer in it takes wall_damage_player
##     (time-scaled, through CombatResolver, source "tide_wall"). She stands
##     wall_recover s while the crest falls, then walks on.
## The line is drawn on her overlay layer (HarbourGlyphs.draw_water_line;
## world-axis offsets from her centre, unmirror()); it pauses with her while
## she is frozen, like every kit windup.
## Determinism (CLAUDE.md): no RNG; the first line is staggered by the think
## slot. Stats: tide_caller_walls, tide_caller_wall_summon_hits,
## tide_caller_wall_player_hits.
class_name TideCallerKit
extends CovenantKit

## Phase: the line is telegraphed.
const WINDUP: int = 1
## Phase: the crest falls after the water rose.
const RECOVER: int = 2
## Damage source tag of the water line (an area hit for Unholy Resilience).
const SOURCE: String = "tide_wall"

## Seconds until the next line may start (counts down while walking).
var cd: float = 0.0
## Unit direction from her toward the necromancer (locked at the windup).
var dir: Vector2 = Vector2.RIGHT
## Line centre (world px, locked at the windup).
var center: Vector2 = Vector2.ZERO
## Reusable query buffer.
var _tmp: Array = []


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	cd = first_cd(e, float(d["wall_first"]))


## Raises a line when the army (or the necromancer) is close.
func think(e: Enemy) -> void:
	if phase != IDLE or cd > 0.0:
		return
	var g := e.game
	var reach := float(d["wall_trigger"])
	var near := e.position.distance_to(g.player.position) <= reach
	if not near:
		g.ally_grid.query(e.position, reach, _tmp)
		for u: SummonedUnit in _tmp:
			if u.active and u.state != SummonedUnit.State.SPAWNING and u.position.distance_to(e.position) <= reach:
				near = true
				break
	if not near:
		return
	var to_p := g.player.position - e.position
	dir = to_p.normalized() if to_p.length() > 1.0 else Vector2.RIGHT
	center = e.position + dir * float(d["wall_distance"])
	var half := Vector2(-dir.y, dir.x) * float(d["wall_length"]) * 0.5  # Half the line.
	g.effects.telegraph_line(center - half, center + half, float(d["wall_width"]), float(d["wall_telegraph"]), e)
	e.motion_lunge(dir, MotionData.POWER_CAST)  # Engine motion: the staff raised (visual only).
	g.stat_add("tide_caller_walls", 1.0)
	set_phase(e, WINDUP)


func physics(e: Enemy, delta: float) -> bool:
	if phase == IDLE:
		cd -= delta
		return false
	phase_time += delta
	hold(e)
	e.queue_redraw()  # The line on her overlay grows / falls.
	match phase:
		WINDUP:
			if phase_time >= float(d["wall_telegraph"]):
				_rise(e)
				set_phase(e, RECOVER)
		RECOVER:
			if phase_time >= float(d["wall_recover"]):
				cd = float(d["wall_cooldown"])
				set_phase(e, IDLE)
	return true


## True if a body of radius `r` at `p` stands in the line.
func _in_line(p: Vector2, r: float) -> bool:
	var rel := p - center
	return absf(rel.dot(dir)) <= float(d["wall_width"]) * 0.5 + r \
			and absf(rel.dot(Vector2(-dir.y, dir.x))) <= float(d["wall_length"]) * 0.5 + r


## The water rises: summons in the line are thrown back and hurt; the
## necromancer in it is hit.
func _rise(e: Enemy) -> void:
	var g := e.game
	var mult := hit_scale(e)  # Time scaling x aura buff x Dirge.
	Sfx.play("plague_cast", center, 0.6)
	var hits := 0  # Summons thrown back.
	g.ally_grid.query(center, float(d["wall_length"]) * 0.5 + UnitData.MAX_BLOCK_RADIUS, _tmp)
	for u: SummonedUnit in _tmp:
		if not u.active or u.state == SummonedUnit.State.SPAWNING or not _in_line(u.position, u.radius):
			continue
		hits += 1
		u.position += dir * float(d["wall_push"])
		g.combat.damage_unit(u, float(d["wall_damage_summon"]) * mult, SOURCE)
	g.stat_add("tide_caller_wall_summon_hits", float(hits))
	for p in g.all_players:  # (Co-op: every necromancer in the line.)
		if _in_line(p.position, p.radius):
			g.stat_add("tide_caller_wall_player_hits", 1.0)
			g.combat.damage_player(float(d["wall_damage_player"]) * mult, SOURCE, p)


## Autopilot hint: out of the line, toward the necromancer's side.
func danger_push(_e: Enemy, p: Vector2) -> Vector2:
	if phase != WINDUP or not _in_line(p, 20.0):
		return Vector2.ZERO
	return dir


## The line on her overlay: rising during the windup, its crest falling after.
func draw_over(e: Enemy, ci: CanvasItem) -> void:
	if phase == IDLE:
		return
	var half := Vector2(-dir.y, dir.x) * float(d["wall_length"]) * 0.5
	var c := center - e.position  # Line centre relative to her (world axes).
	var k := 0.0  # Crest height 0..1.
	if phase == WINDUP:
		k = 0.25 * clampf(phase_time / maxf(0.01, float(d["wall_telegraph"])), 0.0, 1.0)
	else:
		k = 1.0 - clampf(phase_time / maxf(0.01, float(d["wall_recover"])), 0.0, 1.0)
	unmirror(e, ci)
	HarbourGlyphs.draw_water_line(ci, c - half, c + half, float(d["wall_width"]), k)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
