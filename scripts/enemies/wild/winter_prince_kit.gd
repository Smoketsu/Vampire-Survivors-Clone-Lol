## WinterPrinceKit — the kit of THE WINTER PRINCE, the Fae Court's miniboss
## (male; FaeCourtEnemyData "winter_prince"; temporary Act XV, the Turning Year;
## GDD §15.0 "The Fae Court (Act XV phase 2)"; owner-approved proposal:
## "Miniboss, the Winter Prince, the Summer Queen's rival, who brings one minute
## of winter into her summer"). He walks at the necromancer and strikes in reach
## (the shared melee AI); this kit adds:
##   * THE FROST FAN: every volley_every s, the necromancer within volley_range
##     px, volley_bolts frost bolts fly in a fan volley_spread degrees wide at
##     him (ProjectileManager.fire_hostile(), the plain hostile shot, tagged
##     with his kind; volley_damage x the time scaling; a summon a bolt strikes
##     is chilled chill_slow for chill_time s, CombatResolver.chill_unit(), as
##     the Winter Fae's frost);
##   * a "miniboss" row registers on the HUD's miniboss bar and drops his XP
##     burst (reward_xp in reward_crystals) when he falls; ChestManager drops
##     the miniboss chest.
## The minute of winter he brings is FaeCourtDirector's (SeasonCycle.set_override()).
## Determinism: no RNG, no instance ids. Stats: prince_fans, prince_bolts,
## prince_kills, prince_ttk.
class_name WinterPrinceKit
extends WildKit

## Seconds until the next frost fan.
var cd: float = 0.0
## Game time (s) he arrived (the miniboss's time to kill).
var spawned_at: float = 0.0


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	cd = float(d.get("volley_first", 3.0))
	spawned_at = e.game.elapsed
	if bool(d.get("miniboss", false)):
		e.game.enemies.set_miniboss(e)


## The frost fan on its clock; the shared AI walks and strikes (false).
func physics(e: Enemy, delta: float) -> bool:
	cd -= delta
	if cd > 0.0:
		return false
	var g := e.game
	var pl := g.nearest_player(e.position)
	if pl == null or pl.dead or e.position.distance_to(pl.position) > float(d.get("volley_range", 360.0)):
		cd = 0.5  # Look again soon.
		return false
	cd = float(d.get("volley_every", 5.5))
	var to := pl.position - e.position
	var aim := to.normalized() if to.length() > 1.0 else Vector2.RIGHT
	var n := maxi(1, int(d.get("volley_bolts", 5)))
	var spread := deg_to_rad(float(d.get("volley_spread", 40.0)))
	var dmg := float(d.get("volley_damage", 4.0)) * hit_scale(e)
	for i in n:
		var a := 0.0 if n == 1 else spread * (float(i) / float(n - 1) - 0.5)
		g.projectiles.fire_hostile(e.position, aim.rotated(a), dmg, float(d.get("volley_speed", 290.0)), e.undead_damage_mult,
				Projectile.Kind.FROST_BOLT, e.kind, float(d.get("chill_slow", 0.0)), float(d.get("chill_time", 0.0)))
	g.stat_add("prince_fans", 1.0)
	g.stat_add("prince_bolts", float(n))
	return false


## A miniboss's XP burst and the stats of his fall (the chest is ChestManager's).
func on_killed(e: Enemy) -> void:
	super.on_killed(e)
	if not bool(d.get("miniboss", false)):
		return
	var g := e.game
	var n := maxi(1, int(d.get("reward_crystals", 10)))
	var each := maxi(1, floori(float(d.get("reward_xp", 200)) / float(n)))  # XP per crystal.
	for i in n:
		g.pickups.spawn(e.position + Vector2.from_angle(TAU * float(i) / float(n)) * (24.0 + 6.0 * float(i % 3)), each)
	g.effects.impact(e.position, e.radius * 3.0, Palette.WILD_FROST)
	g.shake(8.0)
	g.stat_add("prince_kills", 1.0)
	g.stat_add("prince_ttk", g.elapsed - spawned_at)


## Releases the HUD bar (the miniboss).
func on_deactivate(e: Enemy) -> void:
	super.on_deactivate(e)
	if bool(d.get("miniboss", false)):
		e.game.enemies.clear_miniboss(e)
