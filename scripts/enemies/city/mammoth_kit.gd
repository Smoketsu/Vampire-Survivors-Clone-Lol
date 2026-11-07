## MammothKit — MAMMOTH, Fort Kessler's miniboss (FortKesslerEnemyData
## "mammoth"; Act VIII, GDD §15.0 "Mammoth (Act VIII)"; owner-approved
## proposal: "Miniboss, Mammoth, a super-heavy tank with two turrets"). Spawned
## once by FortKesslerDirector (the "mammoth" timeline event) through the normal
## spawn path; it registers as EnemyDirector.miniboss (the HUD's miniboss bar;
## ChestManager drops the miniboss chest). A VEHICLE: the CityKit's drive (the
## street lane, the headlights, the run-over through Convoy.run_over(), the
## turn, the ram into a wreck), FRONT ARMOUR (row "armour_front", Armour's one
## front test) and FLAT ARMOUR (the existing flat_armor path). TWO TURRETS,
## each on its own cooldown, each through CityShells (the one landing-circle
## path; summons and the necromancer only, source
## FortKesslerEnemyData.MAMMOTH_SHELL_SOURCE):
##   * THE MAIN GUN — every main_every s, with a summon or the necromancer
##       within main_range px (its current target, else the nearest
##       necromancer), one heavy shell on that spot.
##   * THE TWIN GUN — every twin_every s, a line of twin_count shells walking
##       from twin_start px in front of it toward its target, twin_gap px
##       apart, each landing twin_walk s after the last.
## Dead: an XP burst (reward_xp in reward_crystals), and THE LARGEST WRECK of
## the act: the Convoy's wreck where it fell plus a second wreck in the next
## wreck cell along its street (CityBlocks.add_wreck(), the one wreck path),
## which burns and explodes too (Convoy.place_explosion()).
## No RNG (the first shots staggered by the think slot). Stats:
## mammoth_spawned, mammoth_main_shells, mammoth_twin_lines, mammoth_kills,
## mammoth_ttk, mammoth_wrecks.
class_name MammothKit
extends CityKit

## Seconds until the main gun may fire.
var _main_cd: float = 0.0
## Seconds until the twin gun may fire.
var _twin_cd: float = 0.0
## Game time it arrived (time-to-kill stat).
var _spawned_at: float = 0.0


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	_main_cd = first_cd(e, float(d.get("main_every", 6.0)) * 0.5)
	_twin_cd = first_cd(e, float(d.get("twin_every", 4.0)) * 0.75)
	_spawned_at = e.game.elapsed
	e.game.enemies.set_miniboss(e)
	e.game.stat_add("mammoth_spawned", 1.0)


func physics(e: Enemy, delta: float) -> bool:
	e.knockback = Vector2.ZERO  # Like a boss: blows do not shove it.
	var owns := super.physics(e, delta)  # The drive.
	_main_cd -= delta
	_twin_cd -= delta
	var at := _aim(e)
	if at == Vector2.INF:
		return owns
	var r := rules(e)
	if _main_cd <= 0.0 and at.distance_to(e.position) <= float(d.get("main_range", 420.0)):
		_main_cd = float(d.get("main_every", 6.0))
		r.shells.add(at, float(d.get("main_windup", 1.4)), float(d.get("main_radius", 46.0)),
				float(d.get("main_damage", 9.0)) * hit_scale(e), FortKesslerEnemyData.MAMMOTH_SHELL_SOURCE, false)
		e.game.stat_add("mammoth_main_shells", 1.0)
		r.play_sound("gun_burst", e.position, 0.3)
	if _twin_cd <= 0.0 and at.distance_to(e.position) <= float(d.get("main_range", 420.0)):
		_twin_cd = float(d.get("twin_every", 4.0))
		var to := at - e.position
		var dir := to.normalized() if to.length() > 1.0 else facing
		var n := int(d.get("twin_count", 4))
		for k in n:
			r.shells.add(e.position + dir * (float(d.get("twin_start", 70.0)) + float(d.get("twin_gap", 52.0)) * float(k)),
					float(d.get("twin_windup", 1.0)) + float(d.get("twin_walk", 0.18)) * float(k), float(d.get("twin_radius", 26.0)),
					float(d.get("twin_damage", 4.0)) * hit_scale(e), FortKesslerEnemyData.MAMMOTH_SHELL_SOURCE, false)
		e.game.stat_add("mammoth_twin_lines", 1.0)
	return owns


## Where its turrets aim: its current target's spot, else the nearest
## standing necromancer's (Vector2.INF when nobody stands).
func _aim(e: Enemy) -> Vector2:
	if e._target_valid():
		return e.target.position
	var pl := e.game.nearest_player(e.position)
	return pl.position if pl != null and not pl.dead else Vector2.INF


## The XP burst, the second wreck, the banner and the stats.
func on_killed(e: Enemy) -> void:
	var g := e.game
	super.on_killed(e)  # The Convoy's wreck where it fell, and its explosion.
	var cb := g.arena.city_blocks
	if cb != null:
		var axis_dir := drive_dir if drive_axis >= 0 else Vector2.RIGHT
		for side: float in [1.0, -1.0]:
			var o := cb.add_wreck(e.position + axis_dir * side * CityBlockData.WRECK_CELL, CityBlockData.WRECK_HALF_MAX, g.elapsed)
			if o != null:
				rules(e).convoy.place_explosion(o.center)
				g.stat_add("mammoth_wrecks", 1.0)
				g.stat_add("city_wrecks", 1.0)
				break
	var n := maxi(1, int(d.get("reward_crystals", 12)))
	var each := maxi(1, floori(float(d.get("reward_xp", 260)) / float(n)))  # XP per crystal.
	for i in n:
		g.pickups.spawn(e.position + Vector2.from_angle(TAU * float(i) / float(n)) * (28.0 + 6.0 * float(i % 3)), each)
	g.effects.impact(e.position, e.radius * 3.2, Palette.CITY_HERO_ORANGE)
	g.shake(9.0)
	g.enemies.show_banner("Mammoth burns! Its hulk blocks the street.")
	g.stat_add("mammoth_kills", 1.0)
	g.stat_add("mammoth_ttk", g.elapsed - _spawned_at)


## Releases the HUD bar.
func on_deactivate(e: Enemy) -> void:
	super.on_deactivate(e)
	e.game.enemies.clear_miniboss(e)
