## NorseValkyrieKit — the kit of the Valkyrie (NorseEnemyData "valkyrie", kit
## "norse_valkyrie": the Empire owns the kit id "valkyrie"; the Hall of the
## Slain, temporarily Act XI; GDD §15.0 "The Hall of the Slain foundation (phase
## 1)"; owner-approved proposal: "Valkyrie (female, figure style) | Flying
## elite | a spear dive at the ring | Archers, Gargoyles, spells"; the owner
## dropped the Choosing on Nov 7, 2026: she carries no bodies off). A FLIER
## (over the ring and the obstacles): aloft, a grounded melee summon's blow
## finds only air (NorseKit.taken_mult(): flight_melee_taken); the Gargoyles,
## every ranged and caster class, the spells and the volleys land in full.
## THE SPEAR DIVE, as the Fallen Angel's: when it is ready and her target is
## within dive_trigger px she RISES for dive_rise s over a telegraph circle (the
## shared one, which the autotest bot steps out of), streaks down onto the mark
## in dive_fall s and LANDS: every summon in dive_radius takes dive_damage and
## is thrown dive_push px back, a necromancer in it takes the blow; then she
## stands LANDED (every blow lands) for landed_time s. While Ragnarök runs her
## dive comes dive_every_mult as often ("every valkyrie dives at the ring";
## force_dive() sends her at once).
## No RNG. Stats: valkyrie_dives, valkyrie_dive_hits, valkyrie_dive_player_hits.
class_name NorseValkyrieKit
extends NorseKit

## Phase: she climbs while the landing ring is marked.
const RISE: int = 1
## Phase: the dive onto the mark.
const FALL: int = 2
## Phase: on the ground after the landing (open to every blow).
const LANDED: int = 3

## Seconds until the next dive may start.
var _cd: float = 0.0
## Where she will land (world px; locked when she rises).
var _at: Vector2 = Vector2.ZERO
## Where the dive started (world px).
var _from: Vector2 = Vector2.ZERO
## Bodies in the landing (scratch).
var _tmp: Array = []


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	_cd = first_cd(e, float(def.get("dive_every", 7.0)) * 0.5)


## Ragnarök: she dives as soon as she can.
func force_dive() -> void:
	_cd = 0.0


## True while she stands on the ground after a dive (every blow lands).
func landed() -> bool:
	return phase == LANDED


func physics(e: Enemy, delta: float) -> bool:
	super.physics(e, delta)
	var g := e.game
	_cd -= delta
	match phase:
		RISE:
			phase_time += delta
			hold(e)
			if phase_time >= float(d.get("dive_rise", 0.8)):
				_from = e.position
				set_phase(e, FALL)
			return true
		FALL:
			phase_time += delta
			var k := clampf(phase_time / maxf(0.01, float(d.get("dive_fall", 0.25))), 0.0, 1.0)  # 0 -> 1 down to the mark.
			e.position = _from.lerp(_at, k)
			e.velocity = Vector2.ZERO
			if k >= 1.0:
				_land(e)
				set_phase(e, LANDED)
			return true
		LANDED:
			phase_time += delta
			hold(e)
			if phase_time >= float(d.get("landed_time", 1.3)):
				set_phase(e, IDLE)
			return true
	if _cd > 0.0:
		return false
	var t: Node2D = e.target if e.target != null and is_instance_valid(e.target) else g.player
	if e.position.distance_to(t.position) > float(d.get("dive_trigger", 240.0)):
		return false
	if t == g.player and g.ultimates.player_untargetable():
		return false
	var every := float(d.get("dive_every", 7.0))
	if g.norse != null and g.norse.ragnarok.running():
		every *= float(g.norse.ragnarok.cfg["dive_every_mult"])
	_cd = every
	_at = t.position
	g.effects.telegraph_circle(_at, float(d.get("dive_radius", 36.0)), float(d.get("dive_rise", 0.8)) + float(d.get("dive_fall", 0.25)), e)
	g.stat_add("valkyrie_dives", 1.0)
	if g.norse != null:
		g.norse.play_sound("valkyrie_dive", e.position, 0.8)
	set_phase(e, RISE)
	hold(e)
	return true


## The landing: the spear strikes every body in the circle and throws the
## summons back.
func _land(e: Enemy) -> void:
	var g := e.game
	var r := float(d.get("dive_radius", 36.0))
	var dmg := float(d.get("dive_damage", 9.0)) * hit_scale(e)
	var push := float(d.get("dive_push", 24.0))
	g.effects.impact(_at, r, Palette.NORSE_VALKYRIE_GOLD)
	g.shake(2.0)
	for pl in g.all_players:
		if not pl.dead and pl.position.distance_to(_at) <= r + pl.radius:
			g.combat.damage_player(dmg, NorseRulesData.DIVE_SOURCE, pl, e)
			g.stat_add("valkyrie_dive_player_hits", 1.0)
	g.ally_grid.query(_at, r + UnitData.MAX_BLOCK_RADIUS, _tmp)
	for u: SummonedUnit in _tmp:
		if not u.active or u.state == SummonedUnit.State.DEAD or u.state == SummonedUnit.State.SPAWNING:
			continue
		if u.position.distance_to(_at) > r + u.radius:
			continue
		g.combat.damage_unit(u, dmg * e.undead_damage_mult, NorseRulesData.DIVE_SOURCE, e)
		g.stat_add("valkyrie_dive_hits", 1.0)
		if u.active and u.state != SummonedUnit.State.DEAD and push > 0.0 and not u.airborne:
			var away := (u.position - _at).normalized() if u.position.distance_squared_to(_at) > 1.0 else Vector2.RIGHT
			u.position += away * g.arena.clear_length(u.position, away, push, u.radius)


## Autopilot hint: out of the marked landing ring while she rises and dives.
func danger_push(_e: Enemy, p: Vector2) -> Vector2:
	if phase != RISE and phase != FALL:
		return Vector2.ZERO
	var reach := float(d.get("dive_radius", 36.0)) + 16.0
	var off := p - _at
	var dist := off.length()
	if dist >= reach:
		return Vector2.ZERO
	return (off / dist if dist > 0.01 else Vector2.RIGHT) * (1.0 - dist / reach) * 2.0
