## SuperKit — base class of the Last Line's SUPERS (Act VIII; GDD §15.0
## "Supers"; owner-approved proposal: "Named superheroes, each with one power
## and one weakness, both shown on their plate ('Fast. Can't turn.'). They are
## the act's elites and its bosses' allies, and they reward reading the
## weakness more than raw damage"; owner: "open nods", parody-style, no
## trademarked names), a CityKit. What every Super shares:
##   * GUARDED AND EXPOSED: until its weakness is triggered a Super takes
##     guarded_mult (x0.6) of every friendly hit (taken_mult(), the kit's one
##     read in Enemy.damage_taken_mult()); expose(e, by) is THE one path when
##     the weakness is read: stunned `stun` s (CombatResolver.stun_enemy()),
##     then exposed_mult (x1.5) damage taken for exposed_time s, the
##     weakness_crack sound and a crack mark. Reading the weakness beats raw
##     damage. The row's "super" dictionary may override stun / exposed_time;
##   * THE PLATE: its name, then its power and weakness, drawn over its head
##     (CityGlyphs.draw_plate(): cyan while guarded, hazard yellow while
##     exposed), and the HUD's miniboss bar (SuperRoster.note_arrival() ->
##     EnemyDirector.set_miniboss() when no miniboss stands);
##   * the met list and the counters (SuperRoster: arrived, exposed by what,
##     damage taken exposed and guarded).
## Phase 2 adds Atlas, Aurora and Nightjar on this base: a kit's weakness
## calls expose(e, "<what>") from its own special.
## Determinism: no RNG.
class_name SuperKit
extends CityKit

## Game time (s) until which the Super is exposed (0 = guarded).
var exposed_until: float = 0.0
## Game time (s) it was last exposed (the crack mark's fade).
var exposed_at: float = -INF
## Its HP at the last tick (the damage it took, guarded or exposed).
var _last_hp: float = 0.0


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	exposed_until = 0.0
	exposed_at = -INF
	_last_hp = e.max_hp
	rules(e).supers.note_arrival(e)


func on_deactivate(e: Enemy) -> void:
	super.on_deactivate(e)
	_tally(e)
	e.game.enemies.clear_miniboss(e)


## True while the Super is exposed (its weakness was read).
func is_exposed(e: Enemy) -> bool:
	return e.game.elapsed < exposed_until


## THE EXPOSE PATH: the Super's weakness was triggered by `by` (a short tag:
## "building", "wreck", "bone_wall", "blocker", ... for the report): stunned
## `stun` s, then exposed for exposed_time s (x exposed_mult damage taken). A
## Super already exposed is not stunned again (its window is renewed).
func expose(e: Enemy, by: String) -> void:
	var g := e.game
	var sup := super_def()
	var stun := float(sup.get("stun", CityRulesData.SUPERS["stun"]))
	var window := float(sup.get("exposed_time", CityRulesData.SUPERS["exposed_time"]))
	if not is_exposed(e):
		g.combat.stun_enemy(e, stun, 1.0, 1.0)
	exposed_until = g.elapsed + stun + window
	exposed_at = g.elapsed
	rules(e).supers.note_exposed(by)
	g.stat_add("city_supers_exposed", 1.0)
	g.stat_add("city_supers_exposed_" + by, 1.0)
	g.effects.ring(e.position, e.radius * 2.4, CityRulesData.PLATE_EXPOSED, 0.4)
	rules(e).play_sound("weakness_crack", e.position, 0.3)
	e.queue_redraw()


## Guarded x guarded_mult, exposed x exposed_mult, of every friendly hit
## (Enemy.damage_taken_mult(), the one read).
func taken_mult(e: Enemy, _source: String) -> float:
	return float(CityRulesData.SUPERS["exposed_mult"] if is_exposed(e) else CityRulesData.SUPERS["guarded_mult"])


## Keeps the facing and books the HP lost since the last tick as exposed or
## guarded damage (SuperRoster's counters). Subclasses call it first.
func physics(e: Enemy, delta: float) -> bool:
	_tally(e)
	return super.physics(e, delta)


## Books the HP `e` lost since the last look (exposed or guarded).
func _tally(e: Enemy) -> void:
	var lost := _last_hp - e.hp
	if lost > 0.0:
		var ros := rules(e).supers
		if is_exposed(e):
			ros.dmg_exposed += lost
		else:
			ros.dmg_guarded += lost
	_last_hp = e.hp


## The plate over its head and, while exposed, the crack mark.
func draw_over(e: Enemy, ci: CanvasItem) -> void:
	super.draw_over(e, ci)
	var sup := super_def()
	var exposed := is_exposed(e)
	CovenantKit.unmirror(e, ci)
	CityGlyphs.draw_plate(ci, Vector2(0.0, -e.radius * 2.0 - CityRulesData.PLATE_LIFT), e.display_name,
			"%s %s" % [String(sup.get("power", "")), String(sup.get("weakness", ""))],
			CityRulesData.PLATE_EXPOSED if exposed else CityRulesData.PLATE_GUARDED)
	if exposed:
		var k := clampf((exposed_until - e.game.elapsed) / maxf(exposed_until - exposed_at, 0.01), 0.0, 1.0)
		CityGlyphs.draw_crack(ci, e.radius, k)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


# --- Act VIII: Liberty Heights ---
## A Super falls (killed, not despawned): the roster's `fallen` list
## (SuperRoster.note_fallen(); Paragon's Hope calls only the roster Supers not
## in it).
func on_killed(e: Enemy) -> void:
	super.on_killed(e)
	rules(e).supers.note_fallen(e)
