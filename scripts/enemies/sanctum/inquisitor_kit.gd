## InquisitorKit — the Radiant Inquisitor's two casts (GDD §7.2 "creates holy
## damage zones; may briefly suppress replacement locally, with telegraphed
## visuals"). Between casts it advances shooting radiant bolts (the shared
## "ranged" AI, SanctumEnemyData "projectile": "radiant").
##   Holy zone    — when the necromancer is within zone_range: a holy zone
##                  (StageDirector.add_zone, source "inquisitor") on his path
##                  (zone_lead s ahead). It arms for its own arm_time
##                  (telegraph), then burns and slows undead, stings him and
##                  blocks summon replacement inside it, like any holy ground.
##   Suppression  — owner-approved (GDD §15.0): a suppress_telegraph s
##                  telegraphed suppress_radius px circle centred on the
##                  nearest summon within suppress_range (only when at least
##                  suppress_min_summons summons stand inside). Once armed,
##                  for suppress_duration s no replacement spawns inside it
##                  and summons that die inside are not replaced until it
##                  ends (HordeDirector.add_suppression(), the one path).
## It stands still while casting (zone_cast s, or the suppression
## telegraph). Stats: inquisitor_zones, inquisitor_suppressions (the
## horde's suppression_* stats count the effect).
class_name InquisitorKit
extends CovenantKit

## Phase: standing still while a cast resolves.
const CAST: int = 1
## Seconds before an unsuccessful suppression search is retried (not a
## balance number: avoids searching every think tick).
const RETRY: float = 1.0

## Seconds until the next holy zone may be cast.
var zone_cd: float = 0.0
## Seconds until the next suppression may be cast.
var sup_cd: float = 0.0
## Length (s) of the current cast.
var cast_time: float = 0.0
## Where the current cast lands (drawn as the casting focus).
var cast_pos: Vector2 = Vector2.ZERO
## Reusable query buffer.
var _tmp: Array = []


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	zone_cd = first_cd(e, float(d["zone_first"]))
	sup_cd = first_cd(e, float(d["suppress_first"]))


## Suppression first (it shapes the fight), else a holy zone.
func think(e: Enemy) -> void:
	if phase != IDLE:
		return
	var g := e.game
	if sup_cd <= 0.0:
		var c := _suppress_center(e)  # Centre of the sigil (INF = no worthy spot).
		if c == Vector2.INF:
			sup_cd = RETRY
		else:
			var tele := float(d["suppress_telegraph"])  # Owner-approved 1 s telegraph.
			g.horde.add_suppression(c, float(d["suppress_radius"]), float(d["suppress_duration"]), float(d["suppress_damage_mult"]), tele, "inquisitor")
			g.stat_add("inquisitor_suppressions", 1.0)
			sup_cd = float(d["suppress_cooldown"])
			Sfx.play("deep_freeze", c, 1.4)
			_begin_cast(e, c, tele)
			return
	if zone_cd <= 0.0:
		var p := g.player
		if e.position.distance_to(p.position) > float(d["zone_range"]):
			return
		var at := p.position + p.velocity * float(d["zone_lead"])  # Zone centre on his path.
		g.enemies.stage.add_zone(at, d["zone"], "inquisitor")
		g.stat_add("inquisitor_zones", 1.0)
		zone_cd = float(d["zone_cooldown"])
		_begin_cast(e, at, float(d["zone_cast"]))


## The nearest summon within suppress_range whose surroundings hold at least
## suppress_min_summons summons (the undead frontline); Vector2.INF if none.
func _suppress_center(e: Enemy) -> Vector2:
	var g := e.game
	g.ally_grid.query(e.position, float(d["suppress_range"]), _tmp)
	var best: SummonedUnit = null  # Nearest eligible summon.
	var best_d := INF
	for u: SummonedUnit in _tmp:
		if not u.active or u.state == SummonedUnit.State.SPAWNING or u.is_temporary:
			continue
		var dist := u.position.distance_to(e.position)
		if dist < best_d and dist <= float(d["suppress_range"]):
			best_d = dist
			best = u
	if best == null:
		return Vector2.INF
	var r := float(d["suppress_radius"])  # Sigil radius (px).
	g.ally_grid.query(best.position, r, _tmp)
	var inside := 0  # Summons inside the would-be sigil.
	for u: SummonedUnit in _tmp:
		if u.active and u.position.distance_to(best.position) <= r:
			inside += 1
	return best.position if inside >= int(d["suppress_min_summons"]) else Vector2.INF


## Starts a cast of `length` s aimed at `at`.
func _begin_cast(e: Enemy, at: Vector2, length: float) -> void:
	cast_pos = at
	cast_time = length
	set_phase(e, CAST)


func physics(e: Enemy, delta: float) -> bool:
	zone_cd -= delta
	sup_cd -= delta
	if phase == IDLE:
		return false
	phase_time += delta
	hold(e)
	if phase_time >= cast_time:
		set_phase(e, IDLE)
	return true


## A raised gold sunburst while casting.
func draw_over(e: Enemy) -> void:
	if phase == CAST:
		SanctumGlyphs.draw_casting(e, Vector2(0, -e.radius * 1.9), e.radius)
