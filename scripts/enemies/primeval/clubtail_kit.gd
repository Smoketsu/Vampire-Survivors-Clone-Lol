## ClubtailKit — the kit of the CLUBTAIL (PrimevalEnemyData "clubtail") and of
## MOTHER CLUBTAIL, the Great Plain's miniboss (GreatPlainEnemyData
## "mother_clubtail"; temporary Act XIV; GDD §15.0 "The Great Plain (Act XIV
## phase 2)"; owner-approved proposal: "Clubtail (female) | Heavy | Flat armour
## 5; a tail sweep that knocks summons back" and "Mother Clubtail (female), an
## armoured matriarch who guards a herd"). An ankylosaur under armour plates
## (a beast: no figure style). Her flat armour is the row's flat_armor (the one
## path in CombatResolver.damage_enemy()). The shared melee AI walks her in;
## then:
##   * THE TAIL SWEEP: every sweep_every s, once a summon or necromancer stands
##     within sweep_radius px, she swings for sweep_windup s (a circle shows
##     the sweep) and SWEEPS: every grounded summon within sweep_radius px
##     takes sweep_damage (x the time scaling x Thick Marrow's hook) and is
##     knocked sweep_knock px straight away from her; a necromancer in reach
##     takes sweep_player.
##   * THE MATRIARCH (rows with "herd_ward": Mother Clubtail): GreatPlainDirector
##     links the herd she came with (link_herd()); while one of its beasts
##     stands within guard_radius px of her she takes x herd_ward damage
##     (taken_mult(), the kit's one damage read): stampede the herd away or
##     bring it down. A "miniboss" row registers on the HUD's miniboss bar and
##     drops her XP burst (reward_xp in reward_crystals) when she falls;
##     ChestManager drops the miniboss chest.
## Determinism: no RNG, no instance ids. Stats: club_sweeps, club_sweep_hits,
## club_sweep_on_you, mother_warded_hits, mother_kills, mother_ttk.
class_name ClubtailKit
extends PrimevalKit

## Phase: the swing (the telegraph).
const WINDUP: int = 1

## The herd she guards (a Herds.Herd; null when none).
var herd: Herds.Herd = null
## Seconds until the next sweep may start.
var cd: float = 0.0
## Game time (s) she arrived (the miniboss's time to kill).
var spawned_at: float = 0.0
## Scratch buffer for grid queries.
var _buf: Array = []


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	herd = null
	cd = first_cd(e, float(d.get("sweep_first", 2.0)))
	spawned_at = e.game.elapsed
	if bool(d.get("miniboss", false)):
		e.game.enemies.set_miniboss(e)


## Links the herd `h` she guards (GreatPlainDirector, when it brings them).
func link_herd(h: Herds.Herd) -> void:
	herd = h


## True while a live beast of her herd stands within guard_radius px of `e`.
func guarded(e: Enemy) -> bool:
	if herd == null:
		return false
	var r := float(d.get("guard_radius", 0.0))
	for i in herd.members.size():
		var m := herd.members[i]
		if m.active and m.generation == herd.gens[i] and m.position.distance_to(e.position) <= r:
			return true
	return false


## Every tick (see the header): true while the swing owns the tick.
func physics(e: Enemy, delta: float) -> bool:
	var g := e.game
	cd -= delta
	if phase == WINDUP:
		phase_time += delta
		hold(e)
		if phase_time >= float(d.get("sweep_windup", 0.7)):
			_sweep(e)
			set_phase(e, IDLE)
		return true
	if cd <= 0.0:
		var t := e.target if e.target != null and e._target_valid() else g.nearest_player(e.position)
		if t != null and t.position.distance_to(e.position) <= float(d.get("sweep_radius", 54.0)) + body_radius(e, t):
			cd = float(d.get("sweep_every", 5.0))
			g.stat_add("club_sweeps", 1.0)
			rules(e).play_sound("club_sweep", e.position, 0.3)
			set_phase(e, WINDUP)
			hold(e)
			return true
	return false


## The sweep lands (see the header).
func _sweep(e: Enemy) -> void:
	var g := e.game
	var r := float(d.get("sweep_radius", 54.0))
	var ts := hit_scale(e)
	var marrow := g.primeval.thick_marrow_mult() if g.primeval != null else 1.0  # Thick Marrow (1 until the Last Day builds it).
	g.ally_grid.query(e.position, r + UnitData.MAX_BLOCK_RADIUS, _buf)
	for u: SummonedUnit in _buf.duplicate():
		if not u.active or u.state == SummonedUnit.State.DEAD or u.state == SummonedUnit.State.SPAWNING or u.airborne or u.flies:
			continue
		var off := u.position - e.position
		if off.length() > r + u.radius:
			continue
		g.combat.damage_unit(u, float(d.get("sweep_damage", 7.0)) * ts * marrow * e.undead_damage_mult, e.kind, e)
		u.position += (off.normalized() if off.length() > 0.5 else Vector2.RIGHT) * float(d.get("sweep_knock", 60.0))
		g.stat_add("club_sweep_hits", 1.0)
	for pl in g.all_players:
		if not pl.dead and pl.position.distance_to(e.position) <= r + pl.radius:
			g.combat.damage_player(float(d.get("sweep_player", 7.0)) * ts, e.kind, pl, e)
			g.stat_add("club_sweep_on_you", 1.0)
	g.effects.ring(e.position, r, Palette.PRIMEVAL_OCHRE, 0.3)


## THE MATRIARCH: x herd_ward while her herd grazes by her.
func taken_mult(e: Enemy, source: String) -> float:
	var m := super.taken_mult(e, source)
	if d.has("herd_ward") and guarded(e):
		e.game.stat_add("mother_warded_hits", 1.0)
		return m * float(d["herd_ward"])
	return m


## A miniboss's XP burst and the stats of her fall (the chest is ChestManager's).
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
	g.stat_add("mother_kills", 1.0)
	g.stat_add("mother_ttk", g.elapsed - spawned_at)


## Releases the HUD bar (the miniboss).
func on_deactivate(e: Enemy) -> void:
	super.on_deactivate(e)
	herd = null
	if bool(d.get("miniboss", false)):
		e.game.enemies.clear_miniboss(e)


func is_busy() -> bool:
	return phase != IDLE


## Autopilot hint: out of the sweep's circle while she swings.
func danger_push(e: Enemy, p: Vector2) -> Vector2:
	if phase != WINDUP:
		return Vector2.ZERO
	var off := p - e.position
	var reach := float(d.get("sweep_radius", 54.0)) + 20.0
	if off.length() >= reach:
		return Vector2.ZERO
	return (off.normalized() if off.length() > 0.5 else Vector2.RIGHT) * 1.5


## Overlay: the sweep's circle while she swings, and a thin bone-white
## thread to the nearest beast of her herd while it guards her (visual only).
func draw_over(e: Enemy, ci: CanvasItem) -> void:
	unmirror(e, ci)
	if phase == WINDUP:
		var k := clampf(phase_time / maxf(0.01, float(d.get("sweep_windup", 0.7))), 0.0, 1.0)
		SpriteBank.draw_disc(ci, Vector2.ZERO, float(d.get("sweep_radius", 54.0)), Color(Palette.PRIMEVAL_LAVA, 0.1 + 0.18 * k))
	if d.has("herd_ward") and herd != null:
		var r := float(d.get("guard_radius", 0.0))
		for i in herd.members.size():
			var m := herd.members[i]
			if not (m.active and m.generation == herd.gens[i]) or m.position.distance_to(e.position) > r:
				continue
			var to := m.position - e.position
			var n := int(to.length() / 14.0)
			for j in n:
				ci.draw_rect(Rect2(to * (float(j) / float(maxi(1, n))) - Vector2(1.0, 1.0), Vector2(2.0, 2.0)), Color(Palette.PRIMEVAL_BONE, 0.35))
			break
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
