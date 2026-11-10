## StormwingKit — the kit of the STORMWING (female; PrimevalEnemyData
## "stormwing") and of THUNDERWING, THE SKY KING, the Last Day's miniboss
## (male; LastDayEnemyData "thunderwing"; temporary Act XIV; GDD §15.0 "The
## Last Day (Act XIV phase 2)"; owner-approved proposal: "Stormwing (female) |
## Flier elite | Wing gust that pushes the ring 100 px; lands to peck | Hit her
## at the landing circle" and "Thunderwing, the Sky King (male), a giant
## pterosaur whose wing gusts clear the ring"). A great pterosaur (a beast: no
## figure style):
##   IDLE   — she circles hover_radius px from the nearest standing
##            necromancer (row "flies": over the Bone Ring, no blocker holds
##            her);
##   WINDUP — every gust_every s she beats her wings for gust_windup s (a
##            circle shows the gust round the necromancer);
##            then THE GUST: every grounded summon within gust_radius px of
##            that necromancer takes gust_damage (x the time scaling x Thick
##            Marrow's hook) and is pushed gust_push px straight away from him
##            (the ring is blown open);
##   SWOOP  — she swoops at land_speed to the LANDING CIRCLE at the ring's edge
##            on her side;
##   LANDED — grounded for land_time s (Enemy.flies false: blockers hold her,
##            every blow lands) she pecks with the shared melee AI, then takes
##            off again.
## A "miniboss" row (Thunderwing) registers on the HUD's miniboss bar and drops
## its XP burst (reward_xp in reward_crystals) when it falls; ChestManager
## drops the miniboss chest. Determinism: no RNG, no instance ids. Stats:
## gusts_<kind>, gust_pushed_<kind>, landings_<kind>, thunderwing_kills,
## thunderwing_ttk.
class_name StormwingKit
extends PrimevalKit

## Phase: beating the wings (the gust's telegraph).
const WINDUP: int = 1
## Phase: swooping down to the landing circle.
const SWOOP: int = 2
## Phase: grounded, pecking.
const LANDED: int = 3
## px from the necromancer of the landing circle (the Bone Ring's outer edge).
const LAND_DIST: float = 130.0  # TUNING (not in GDD)
## Most seconds of a swoop (it lands where it is after this).
const SWOOP_MAX: float = 2.0  # TUNING (not in GDD)

## Seconds until the next gust may start.
var cd: float = 0.0
## The landing circle's centre (world px).
var land_at: Vector2 = Vector2.ZERO
## Game time (s) it arrived (the miniboss's time to kill).
var spawned_at: float = 0.0
## Scratch buffer for grid queries.
var _buf: Array = []


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	cd = first_cd(e, float(d.get("gust_first", 4.0)))
	e.flies = bool(d.get("flies", true))  # The pooled body flies again as its row says.
	spawned_at = e.game.elapsed
	if bool(d.get("miniboss", false)):
		e.game.enemies.set_miniboss(e)


## Every tick (see the header): true while it owns the tick (the air).
func physics(e: Enemy, delta: float) -> bool:
	var g := e.game
	cd -= delta
	phase_time += delta
	var pl := g.nearest_player(e.position)
	match phase:
		WINDUP:
			_circle(e, pl, delta)
			if phase_time >= float(d.get("gust_windup", 1.0)):
				if pl != null:
					_gust(e, pl.position)
					var side := e.position - pl.position
					land_at = g.arena.free_point(pl.position + (side.normalized() if side.length() > 1.0 else Vector2.RIGHT) * LAND_DIST, e.radius)
				else:
					land_at = e.position
				set_phase(e, SWOOP)
			return true
		SWOOP:
			var to := land_at - e.position
			if to.length() > 6.0 and phase_time < SWOOP_MAX:
				PrimevalKit.move(e, to.normalized(), float(d.get("land_speed", 220.0)), delta)
				return true
			e.flies = false  # Grounded: blockers hold her, every blow lands.
			g.stat_add("landings_" + e.kind, 1.0)
			set_phase(e, LANDED)
			return false
		LANDED:
			if phase_time >= float(d.get("land_time", 3.0)):
				e.flies = true
				cd = float(d.get("gust_every", 10.0))
				set_phase(e, IDLE)
				return true
			return false  # The shared melee AI pecks.
	if cd <= 0.0 and pl != null and pl.position.distance_to(e.position) <= float(d.get("hover_radius", 190.0)) * 1.6:
		g.stat_add("gusts_" + e.kind, 1.0)
		rules(e).play_sound("wing_gust", e.position, 0.4)
		set_phase(e, WINDUP)
	_circle(e, pl, delta)
	return true


## Circles hover_radius px round `pl` (a little ahead on the circle).
func _circle(e: Enemy, pl: Necromancer, delta: float) -> void:
	if pl == null:
		e.velocity = Vector2.ZERO
		return
	var rel := e.position - pl.position
	var ang := (rel.angle() if rel.length() > 0.5 else 0.0) + float(d.get("hover_orbit", 0.8)) * delta * 4.0
	var post := pl.position + Vector2.from_angle(ang) * float(d.get("hover_radius", 190.0))
	var to := post - e.position
	if to.length() > 2.0:
		PrimevalKit.move(e, to.normalized(), minf(e.move_speed, to.length() / maxf(delta, 0.001)), delta)


## THE GUST round the necromancer at `c` (see the header).
func _gust(e: Enemy, c: Vector2) -> void:
	var g := e.game
	var r := float(d.get("gust_radius", 160.0))
	var push := float(d.get("gust_push", 100.0))
	var dmg := float(d.get("gust_damage", 3.0)) * hit_scale(e) * e.undead_damage_mult
	var marrow := g.primeval.thick_marrow_mult() if g.primeval != null else 1.0  # Thick Marrow.
	g.ally_grid.query(c, r + UnitData.MAX_BLOCK_RADIUS, _buf)
	var n := 0
	for u: SummonedUnit in _buf.duplicate():
		if not u.active or u.state == SummonedUnit.State.DEAD or u.state == SummonedUnit.State.SPAWNING or u.airborne or u.flies:
			continue
		var off := u.position - c
		if off.length() > r + u.radius:
			continue
		g.combat.damage_unit(u, dmg * marrow, e.kind, e)
		u.position += (off.normalized() if off.length() > 0.5 else Vector2.RIGHT) * push
		n += 1
	g.stat_add("gust_pushed_" + e.kind, float(n))
	g.effects.ring(c, r, Palette.PRIMEVAL_BONE, 0.35)


## A miniboss's XP burst and the stats of its fall (the chest is ChestManager's).
func on_killed(e: Enemy) -> void:
	super.on_killed(e)
	if not bool(d.get("miniboss", false)):
		return
	var g := e.game
	var n := maxi(1, int(d.get("reward_crystals", 10)))
	var each := maxi(1, floori(float(d.get("reward_xp", 200)) / float(n)))  # XP per crystal.
	for i in n:
		g.pickups.spawn(e.position + Vector2.from_angle(TAU * float(i) / float(n)) * (24.0 + 6.0 * float(i % 3)), each)
	g.effects.impact(e.position, e.radius * 3.0, Palette.PRIMEVAL_BONE)
	g.shake(8.0)
	g.stat_add("thunderwing_kills", 1.0)
	g.stat_add("thunderwing_ttk", g.elapsed - spawned_at)


## Releases the HUD bar (the miniboss).
func on_deactivate(e: Enemy) -> void:
	super.on_deactivate(e)
	if bool(d.get("miniboss", false)):
		e.game.enemies.clear_miniboss(e)


func is_busy() -> bool:
	return phase == WINDUP or phase == SWOOP


## Overlay: the gust's circle round the necromancer while she beats her wings,
## the landing circle while she swoops (visual only, disc textures).
func draw_over(e: Enemy, ci: CanvasItem) -> void:
	if phase != WINDUP and phase != SWOOP:
		return
	unmirror(e, ci)
	if phase == WINDUP:
		var pl := e.game.nearest_player(e.position)
		if pl != null:
			var k := clampf(phase_time / maxf(0.01, float(d.get("gust_windup", 1.0))), 0.0, 1.0)
			SpriteBank.draw_disc(ci, pl.position - e.position, float(d.get("gust_radius", 160.0)), Color(Palette.PRIMEVAL_BONE, 0.06 + 0.12 * k))
	else:
		SpriteBank.draw_disc(ci, land_at - e.position, e.radius * 1.6, Color(Palette.PRIMEVAL_OCHRE, 0.3))
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
