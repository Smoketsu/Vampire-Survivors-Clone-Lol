## MyrmidonBehavior — the Myrmidon Shades' SHIELD WALL ("shieldwall", UnitData
## "myrmidon_shade"; Act IV, the Asphodel Underworld; GDD §15.0 "Myrmidon
## Shades, Legion of Tartarus and Myrmidon Oath"; owner-approved proposal: "the
## finale's reward: undead hoplites that fight as a three-shield phalanx on the
## ring"). Unlocked by defeating Hades, offered on every stage; no act-specific
## rule (owner rule: summons work the same everywhere). In the shared AI they
## are blockers (formation "front": they hold the Bone Ring's outer posts and
## block like Warriors). Their own rules:
##   * THE WALL (think(), 5 Hz): Myrmidons of the same army standing in a chain,
##     each within wall_range px of the next, make one wall; a wall of
##     wall_size or more LOCKS SHIELDS, and every Myrmidon in it takes wall_cut
##     less from every hit (damage_taken_mult(), read once in
##     CombatResolver.damage_unit()). A lone or paired Myrmidon fights unshielded.
##   * THE SPEAR (on_melee_hit()): every thrust runs on through `pierce_count`
##     more foes (1 for the base class) standing within pierce_reach px behind
##     the one struck, each taking pierce_fraction x the thrust (source
##     "myrmidon_pierce", a minion special source).
## Legion of Tartarus (summon evolution; keys from SummonEvolutionData
## "special_set"): a harder wall cut, the spear through two more foes, and the
## grip of Tartarus: every foe the spear strikes is slowed grip_slow for
## grip_time s (CombatResolver.slow_enemy(): Spirit Binding and Mournsong apply).
## Determinism: no RNG (the chain search is the army's unit order; the pierce
## takes the foes in distance order, ties in the spatial hash's order).
## Stats: myrmidon_walls_locked (unit-thinks inside a locked wall),
## myrmidon_pierces, myrmidon_grips, behavior_dmg_prevented_myrmidon_shade
## (CombatResolver).
class_name MyrmidonBehavior
extends SummonBehavior

## Damage-source tag of the spear running through a second foe.
const PIERCE_SOURCE: String = "myrmidon_pierce"

## True while the unit stands in a locked shield wall (set at 5 Hz).
var locked: bool = false
## Size of the unit's wall at the last check (drawing, stats).
var wall: int = 1
## Reusable query buffer.
var _buf: Array = []
## Chain search scratch: Myrmidons of the army this check.
var _mates: Array[SummonedUnit] = []


func reset(u: SummonedUnit) -> void:
	super.reset(u)
	locked = false
	wall = 1


## Recounts the wall the unit stands in (never starts a special).
func think(u: SummonedUnit) -> bool:
	var s := u.special
	var reach := float(s["wall_range"])
	_mates.clear()
	for m in u.director.units:
		if m.active and m.unit_class == u.unit_class and m.state != SummonedUnit.State.DEAD:
			_mates.append(m)
	# The chain from `u`: a breadth-first walk over mates within reach of each other.
	var seen: Array[SummonedUnit] = [u]
	var i := 0
	while i < seen.size():
		var a := seen[i]
		for m in _mates:
			if not seen.has(m) and a.position.distance_to(m.position) <= reach:
				seen.append(m)
		i += 1
	wall = seen.size()
	var was := locked
	locked = wall >= int(s["wall_size"])
	if locked:
		u.game.stat_add("myrmidon_walls_locked", 1.0)
	if locked != was:
		u.queue_redraw()
	return false


## The locked wall's cut on every hit.
func damage_taken_mult(u: SummonedUnit, _source: String) -> float:
	if not locked:
		return 1.0
	return 1.0 - float(u.special["wall_cut"])


## The spear runs on through the foes behind the one struck (and, Legion of
## Tartarus, grips every foe it strikes).
func on_melee_hit(u: SummonedUnit, e: Enemy, _dealt: float) -> void:
	var s := u.special
	var grip := float(s.get("grip_slow", 0.0))  # Legion of Tartarus (0 on the base class).
	if grip > 0.0 and e.active:
		u.game.combat.slow_enemy(e, grip, float(s["grip_time"]))
		u.game.stat_add("myrmidon_grips", 1.0)
	var n := int(s.get("pierce_count", 1))  # Foes behind it the spear runs through.
	if n <= 0:
		return
	var dir := e.position - u.position
	dir = dir.normalized() if dir.length() > 0.5 else Vector2.RIGHT
	var reach := float(s["pierce_reach"])
	var start := e.position
	var cands: Array = []  # [distance along the spear, enemy]
	u.game.enemy_grid.query(start + dir * reach * 0.5, reach + ProjectileManager.MAX_BODY_RADIUS, _buf)
	for f: Enemy in _buf:
		if f == e or not f.active:
			continue
		var rel := f.position - start
		var along := rel.dot(dir)
		if along <= 0.0 or along > reach + f.radius:
			continue
		if absf(rel.cross(dir)) > f.radius + 6.0:
			continue
		cands.append([along, f])
	if cands.is_empty():
		return
	cands.sort_custom(func(a: Array, b: Array) -> bool: return float(a[0]) < float(b[0]))
	var dmg := u.damage * float(s["pierce_fraction"])
	for k in mini(n, cands.size()):
		var f: Enemy = cands[k][1]
		u.game.combat.damage_enemy(f, dmg, PIERCE_SOURCE, -1, u.position)
		if grip > 0.0 and f.active:
			u.game.combat.slow_enemy(f, grip, float(s["grip_time"]))
		u.game.stat_add("myrmidon_pierces", 1.0)


## A locked wall's shield glint at the unit's feet (visual only).
func draw_under(u: SummonedUnit) -> void:
	if locked:
		u.draw_arc(Vector2(0, 3), u.radius * 1.15, 0.0, TAU, 16, Color(Palette.NECRO_GREEN, 0.5), 1.5)
