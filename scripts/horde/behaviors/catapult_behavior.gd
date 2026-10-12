## CatapultBehavior — the Corpse Catapult's Bone Barrage ("barrage",
## UnitData). The catapult is ordinary siege artillery in the shared AI: it
## posts BEHIND the necromancer (formation "back"), holds its ground while
## firing like the Archers (w_threat 0.1, no kiting) and winds its arm for
## `windup` s (the shared CASTING windup). Its attack_profile "boulder" is
## released here:
##   * a bone boulder is lobbed at the target's position led by boulder_lead
##     x its velocity x the flight time (enemies always advance, so the lead
##     keeps boulders landing on the advancing crowd); the flight time is the
##     distance / boulder_speed, clamped to boulder_flight_min..max. The
##     boulder flies on an arc and its landing spot is telegraphed on the
##     ground the whole way (HordeHazards). On landing it deals the unit's
##     damage to every enemy within its splash_radius (structures included)
##     with a small knockback.
##   * Target preference ("siege" weights: the densest pack inside the
##     splash, via the shared cluster value): score_bonus() adds
##     structure_bonus for a structure (outposts, ward generators, supply
##     carts, ward crystals, altars) and elite_bonus for an elite, a miniboss
##     or the boss.
## Ossuary Engine (summon evolution; keys from SummonEvolutionData
## "special_set", absent / 0 on the base catapult, which keeps exactly the
## behaviour above): `volley` boulders per volley (one on the aim point, the
## others volley_spread px to its sides across the line of fire, every one
## at full damage), and each leaves a field of burning bone shards
## (shard_radius px, shard_life s, shard_fraction x the boulder damage every
## shard_tick s to every enemy inside; source "ossuary_shards").
## Stats: catapult_volleys, catapult_boulders, catapult_boulder_hits /
## catapult_structure_dmg / ossuary_shard_fields (HordeHazards).
class_name CatapultBehavior
extends SummonBehavior


## "boulder" attack profile: one volley at the target (see the header).
func release_attack(u: SummonedUnit) -> void:
	if not u.target_alive():
		return
	var s := u.special  # Special numbers.
	var t := u.target
	var dist := u.position.distance_to(t.position)  # Range to the target (px).
	var flight := clampf(dist / maxf(float(s["boulder_speed"]), 1.0), float(s["boulder_flight_min"]), float(s["boulder_flight_max"]))  # s
	var aim := t.position
	if not t.is_structure:
		aim += t.velocity * flight * float(s["boulder_lead"])  # Lead the advancing foe.
	var n := maxi(1, int(s.get("volley", 1)))  # Boulders in this volley.
	var shard := {}  # Ossuary Engine shard field ({} = none).
	if float(s.get("shard_life", 0.0)) > 0.0:
		shard = {"radius": float(s["shard_radius"]), "life": float(s["shard_life"]), "tick": float(s["shard_tick"]),
			"damage": u.damage * float(s["shard_fraction"])}
	var dir := (aim - u.position).normalized() if aim.distance_to(u.position) > 0.01 else Vector2.RIGHT  # Line of fire.
	var side := Vector2(-dir.y, dir.x) * float(s.get("volley_spread", 0.0))  # Offset between boulders.
	for i in n:
		var k := float(i) - float(n - 1) * 0.5  # -1, 0, +1 for a volley of three.
		var to := aim + side * k  # This boulder's landing point.
		var launched := u.director.hazards.launch_boulder(u.position + Vector2(0, -u.radius), to,
				flight + 0.06 * absf(k), float(s["boulder_arc"]), u.damage, u.splash_radius,
				float(s["boulder_knockback"]), float(s["boulder_shake"]), u.dmg_source, shard)
		if launched:
			u.game.stat_add("catapult_boulders", 1.0)
	u.game.stat_add("catapult_volleys", 1.0)
	u.game.effects.slash(u.position + dir * u.radius, dir, Palette.BONE, u.radius * 1.6)
	Sfx.play("catapult_launch", u.position)


## Siege preference: structures first, then elites / minibosses / the boss.
func score_bonus(u: SummonedUnit, e: Enemy, _dp: float) -> float:
	if e.is_structure:
		return float(u.special["structure_bonus"])
	if e.is_elite or e.is_miniboss or e.is_boss:
		return float(u.special["elite_bonus"])
	return 0.0


## Redraws every tick of the windup so the winding arm animates.
func physics(u: SummonedUnit, delta: float) -> bool:
	if u.state == SummonedUnit.State.CASTING:
		u.queue_redraw()
	return super(u, delta)


## The arm winds back while the shared windup runs (a bone-coloured arc).
func draw_under(u: SummonedUnit) -> void:
	if u.state != SummonedUnit.State.CASTING or u.cast_time <= 0.0:
		return
	var k := 1.0 - clampf(u.cast_time / maxf(u.windup, 0.01), 0.0, 1.0)  # Windup progress.
	u.draw_arc(Vector2(0, -u.radius * 0.4), u.radius * 1.5, -PI * 0.5, -PI * 0.5 - PI * 0.8 * k, 12, Color(Palette.BONE, 0.6), 2.0)
