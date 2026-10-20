## GraveDroneBehavior — the Grave Drone's kit ("hover", UnitData "grave_drone";
## Act III, GDD §15.0 "The Assembly Halls (Act III phase 2)"; owner-approved
## proposal: "a flying swarm of skull drones, three to a card, that hover over
## the army and fire bone darts. A ranged class that cannot be body-blocked").
##   * Hovering: the class row's "flies" makes the drone pass over obstacles and
##     ride no conveyor (SummonedUnit.flies, Arena.resolve_all(),
##     TerrainSlow.push_summon()); its body is drawn hover_lift px above a
##     ground shadow. It is NOT airborne: enemies target and hit it, and an
##     Empire shot stops on it like on any summon (no act-only rule).
##   * Bone darts: its attack_profile "dart" is released here: dart_count darts
##     at the target (fanned dart_spread rad apart), each piercing the level
##     row's pierce + dart_pierce foes (Projectile.Kind.ARROW, source = the
##     unit's dmg_source: "grave_drone" / "wraith_drone"). One dart flies
##     homing at the target (fire_friendly), the others straight (fire_friendly_dir).
## Wraith Drone (summon evolution; SummonEvolutionData "special_set"): three
## piercing darts an attack and a spectral look; the base drone keeps exactly
## the behaviour above. No special to cast, so it never enters CASTING on its
## own. Stats: drone_darts.
class_name GraveDroneBehavior
extends SummonBehavior


## Releases the bone darts at the target (the "dart" profile).
func release_attack(u: SummonedUnit) -> void:
	if not u.target_alive():
		return
	var n := maxi(1, int(u.special.get("dart_count", 1)))
	var spread := float(u.special.get("dart_spread", 0.0))
	var pierce := u.pierce + int(u.special.get("dart_pierce", 0))
	var g := u.game
	var to := u.target.position - u.position
	var dir := to.normalized() if to.length() > 0.5 else Vector2.RIGHT
	var muzzle := u.position + Vector2(0, -body_lift(u))  # Darts leave the hovering body.
	for i in n:
		var off := (float(i) - float(n - 1) * 0.5) * spread
		if absf(off) < 0.001:
			g.projectiles.fire_friendly(Projectile.Kind.ARROW, muzzle, u.target, u.damage, u.projectile_speed, pierce, u.dmg_source)
		else:
			g.projectiles.fire_friendly_dir(Projectile.Kind.ARROW, muzzle, dir.rotated(off), u.damage, u.projectile_speed, pierce, u.dmg_source)
	g.stat_add("drone_darts", float(n))


## The body hovers above its shadow (drawing only).
func body_lift(u: SummonedUnit) -> float:
	return float(u.special.get("hover_lift", 15.0))


## Ground shadow under the hovering body.
func draw_under(u: SummonedUnit) -> void:
	u.draw_set_transform(Vector2(0, u.radius * 0.95), 0.0, Vector2(1.0, 0.4))
	u.draw_circle(Vector2.ZERO, u.radius * 0.9, Color(0, 0, 0, 0.28))
	body_space(u)
