## ColossusKit — the Bone Colossus's taunt and death burst (summon evolution
## of the Corpse Abomination + Bone Plating, SummonEvolutionData
## "bone_colossus"). Owned by HordeDirector (`colossi`). The Colossus is still
## the Abomination underneath: the same melee guard AI, blocker and Stomp
## (AbominationBehavior), with the evolution's bigger numbers (+60% HP, a
## wider / heavier blocking ring, +40% stomp radius). This kit adds:
##   * Taunt: enemies whose centre is within taunt_radius of a living
##     Colossus pick it as their target before the necromancer or any other
##     summon (Enemy._pick_target() asks taunt_target()). It changes the
##     target CHOICE only: melee enemies walk at their target as always,
##     ranged ones keep advancing on the player and shoot the Colossus
##     (enemies always advance, GDD §15.0). Bosses, Reckoning enemies and
##     structures ignore the taunt, and an enemy already held by a blocker
##     keeps fighting that blocker (Enemy.think()).
##     The taunter list is rebuilt at the formation rate (4 Hz) from the
##     living units whose special has taunt_radius, stored as [unit,
##     generation] pairs and re-checked on use (pooling guard).
##   * Bone shrapnel: when a Colossus is killed (CombatResolver.damage_unit),
##     every enemy within shrapnel_radius takes shrapnel_damage_mult x its
##     stomp damage (source "colossus_shrapnel") and is knocked outward.
## Stats: colossus_taunts (enemies redirected onto a Colossus),
## colossus_shrapnel_bursts / _hits, dmg_colossus_shrapnel.
class_name ColossusKit
extends RefCounted

## Owning horde director.
var director: HordeDirector
## Living taunters as [SummonedUnit, generation, taunt radius (px)] entries,
## rebuilt by refresh().
var _taunters: Array = []
## Reusable enemy query buffer.
var _buf: Array = []


func _init(p_director: HordeDirector) -> void:
	director = p_director


## Rebuilds the taunter list (HordeDirector.step, formation tick). Costs one
## pass over the living units; nothing at all until a class has evolved.
func refresh() -> void:
	_taunters.clear()
	if director.evolutions.evolved.is_empty():
		return
	for u in director.units:
		if not u.active or u.state == SummonedUnit.State.SPAWNING:
			continue
		var r := float(u.special.get("taunt_radius", 0.0))  # Taunt reach (px; 0 = none).
		if r > 0.0:
			_taunters.append([u, u.generation, r])


## The Colossus enemy `e` must target (the nearest living taunter within its
## taunt radius of e's centre), or null when none applies.
func taunt_target(e: Enemy) -> SummonedUnit:
	if _taunters.is_empty() or e.is_boss or e.is_reckoning or e.is_structure:
		return null
	var best: SummonedUnit = null  # Nearest taunter in reach.
	var best_d := INF  # Its distance (px).
	for entry: Array in _taunters:
		var u: SummonedUnit = entry[0]
		if not u.active or u.generation != int(entry[1]) or u.airborne:
			continue
		var d := e.position.distance_to(u.position)  # Centre distance (px).
		if d <= float(entry[2]) and d < best_d:
			best_d = d
			best = u
	return best


## Death hook (CombatResolver.damage_unit, just before the unit is pooled):
## a dying Colossus bursts into bone shrapnel.
func on_unit_killed(u: SummonedUnit) -> void:
	if not u.special.has("shrapnel_radius"):
		return
	var game := director.game
	var pos := u.position  # Burst centre.
	var r := float(u.special["shrapnel_radius"])  # Burst radius (px).
	var dmg := float(u.special["stomp_damage"]) * float(u.special["shrapnel_damage_mult"])  # Damage per enemy.
	var kb := float(u.special["shrapnel_knockback"])  # Knockback impulse (px/s).
	game.enemy_grid.query(pos, r + ProjectileManager.MAX_BODY_RADIUS, _buf)
	var hits := 0  # Enemies hit.
	for e: Enemy in _buf:
		if not e.active or e.position.distance_to(pos) > r + e.radius:
			continue
		var away := e.position - pos  # Push direction.
		var dir := away / away.length() if away.length() > 0.01 else Vector2.RIGHT
		if not e.is_structure:
			e.knockback += dir * kb / maxf(e.mass, 0.1)
		hits += 1
		game.combat.damage_enemy(e, dmg, "colossus_shrapnel")
	game.effects.ring(pos, r, Palette.BONE, 0.4)
	game.effects.ring(pos, r * 0.55, Palette.IVORY, 0.3)
	Juice.fx.burst(pos, Palette.BONE, Palette.IVORY, 22, r * 2.2, 0.6, 3.0)
	game.shake(float(u.special["shrapnel_shake"]))
	Sfx.play("abom_stomp", pos)
	game.stat_add("colossus_shrapnel_bursts", 1.0)
	game.stat_add("colossus_shrapnel_hits", float(hits))


## Evolution card lines for the Bone Colossus (`cur` / `nxt`: effective
## stats before / after; empty unless `nxt` carries the Colossus keys).
static func offer_lines(cur: Dictionary, nxt: Dictionary) -> PackedStringArray:
	var out := PackedStringArray()  # Card lines.
	var sp: Dictionary = nxt.get("special", {})  # Evolved special numbers.
	if not sp.has("taunt_radius"):
		return out
	var a: Dictionary = cur.get("special", {})  # Current special numbers.
	SummonEvolutions._delta(out, "Block radius", cur["block_radius"], nxt["block_radius"])
	SummonEvolutions._delta(out, "Stomp radius", a.get("stomp_radius", 0.0), sp["stomp_radius"])
	out.append("NEW  Taunt: foes within %s px attack it first" % AbilityManager._fmt(sp["taunt_radius"]))
	out.append("NEW  Death burst: %s dmg to foes in %s px" % [
			AbilityManager._fmt(float(sp["stomp_damage"]) * float(sp["shrapnel_damage_mult"])), AbilityManager._fmt(sp["shrapnel_radius"])])
	return out


## Autotest summary of the Bone Colossus.
static func summary_line(st: Dictionary) -> String:
	return "colossus dmg %d, stomps %d | taunted enemies %d | shrapnel bursts %d, hits %d, dmg %d" % [
		int(st.get("dmg_bone_colossus", 0.0)), int(st.get("abom_stomps", 0.0)), int(st.get("colossus_taunts", 0.0)),
		int(st.get("colossus_shrapnel_bursts", 0.0)), int(st.get("colossus_shrapnel_hits", 0.0)),
		int(st.get("dmg_colossus_shrapnel", 0.0))]
