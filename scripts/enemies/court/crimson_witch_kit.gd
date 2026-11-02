## CrimsonWitchKit — the kit of the Crimson Witch (CourtEnemyData
## "crimson_witch", the Witchwood's block; Act VII, GDD §15.0 "The Witchwood
## (Act VII phase 2)"; owner-approved proposal: "Covens of three; together they
## cast a hex circle that heals the Court inside it and drains the army ...
## Break the coven: kill one and the circle fails"). Female, in the
## figure-redesign style. A support caster:
##   * ALONE she keeps her distance and throws hex bolts (the row's "ranged"
##     behaviour: the shared hostile shot, which never feeds).
##   * IN A COVEN (WitchHexes bands free witches in threes, the one coven path):
##     while her coven's circle glows or bites she stands and chants (no bolts,
##     no steps); while it waits she fights on, but one who strays more than
##     COVEN keep_range px from her sisters' centre walks back to them.
##   * The coven breaks the moment one of its witches falls: her
##     on_deactivate() tells WitchHexes (drop_witch()), which ends its circle.
## No RNG. Stats: witch_chant_time, witch_regroup_time (and WitchHexes').
class_name CrimsonWitchKit
extends CourtKit


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	rules(e).witch_hexes().add_witch(e)


func on_deactivate(e: Enemy) -> void:
	super.on_deactivate(e)
	var court := e.game.court
	if court != null and court.hexes != null:
		court.hexes.drop_witch(e)  # Her coven breaks; its circle fails.


func physics(e: Enemy, delta: float) -> bool:
	var hx := rules(e).witch_hexes()
	var c := hx.coven_of(e)
	if c == null:
		return false
	if c.state != WitchHexes.IDLE:
		hold(e)  # She chants over the circle.
		e.game.stat_add("witch_chant_time", delta)
		return true
	var centre := hx.centre_of(c)
	var off := centre - e.position
	if off.length() <= float(hx.coven_cfg["keep_range"]):
		return false
	var spd := e.move_speed * (1.0 - e.slow_factor if e.slow_timer > 0.0 else 1.0)  # px/s after her slows.
	e.velocity = off.normalized() * spd
	e.position += e.velocity * delta  # The obstacle push-out runs after the enemies.
	e.game.stat_add("witch_regroup_time", delta)
	return true


func is_busy() -> bool:
	return false


## The chant: a faint red glow at her hands while her coven's circle runs.
func draw_over(e: Enemy, ci: CanvasItem) -> void:
	super.draw_over(e, ci)
	var court := e.game.court
	if court == null or court.hexes == null:
		return
	var c := court.hexes.coven_of(e)
	if c != null and c.state != WitchHexes.IDLE:
		SpriteBank.draw_disc(ci, Vector2(e.radius * 0.6, -e.radius * 1.2), 4.0, Color(Palette.COURT_BLOOD_LIGHT, 0.85))
