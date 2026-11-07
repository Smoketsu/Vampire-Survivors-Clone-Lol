## ShutenDojiKit — SHUTEN-DŌJI, THE ONI KING, the Burning Province's miniboss
## (ProvinceEnemyData "shuten_doji"; Act V, GDD §15.0 "The Burning Province
## (Act V phase 2)"; owner-approved proposal: "Miniboss, Shuten-dōji, the Oni
## King (night only): drunk, enormous, throws sake barrels that burst into
## fire"). Spawned once by ProvinceDirector (the "shuten_doji" timeline event,
## which waits for the night) through the normal spawn path; it registers as
## EnemyDirector.miniboss (the HUD's miniboss bar; ChestManager drops the
## miniboss chest). An OniKit (the kanabō smash: a telegraphed slam that hits
## and stuns summons through CombatResolver.stun_unit()), plus:
##   * SAKE BARRELS — within throw_range px of the necromancer and off cooldown
##     he heaves a barrel over his head for throw_windup s, then hurls
##     `barrels` of them (rage_barrels in his rage): the first lands on the
##     necromancer's position led by barrel_lead of the flight, the others
##     barrel_spread px around it (fixed angles, no RNG); each landing point
##     shows a red circle of barrel_radius px for the whole flight
##     (barrel_flight s). A barrel BURSTS: barrel_damage_player to the
##     necromancer inside, barrel_damage_summon to each summon inside, and
##     leaves a SAKE FIRE (ProvinceHazards: fire_radius px for fire_life s,
##     burning the necromancer and summons every fire_tick s). Barrels in
##     flight hang while he is frozen or stunned and shatter if he dies first.
##   * DRUNK — his gait sways sideways (a deterministic sine, sway px/s at
##     sway_rate rad/s); far from the necromancer (advance_range) he lurches
##     faster (advance_speed_mult); like a boss he shrugs off knockback.
##   * RAGE — below rage_hp of his max HP (once) he drains his gourd: throws
##     come rage_cd_mult as often with rage_barrels barrels.
## On death: an XP burst (reward_xp in reward_crystals) and the miniboss
## chest. FLAT ARMOUR is the row's "flat_armor". NIGHT kind. Determinism: no
## RNG. Stats: shuten_throws, shuten_barrels, shuten_barrel_hits_summon,
## shuten_barrel_hits_player, shuten_rage_at, shuten_kills, shuten_ttk (and
## the oni's oni_smashes / oni_stuns).
class_name ShutenDojiKit
extends OniKit

## Phase: the barrel raised before the throw.
const THROW_WINDUP: int = 2
## Phase: standing after a throw.
const RECOVER: int = 3
## Height (px) the drawn barrel's arc rises at its top (visual only).
const ARC_HEIGHT: float = 70.0  # TUNING (not in GDD)

## Seconds until the next barrel volley may start.
var throw_cd: float = 0.0
## True once he raged (below rage_hp).
var raged: bool = false
## Landing points of the barrels in flight (world px; empty = none).
var _landing: PackedVector2Array = PackedVector2Array()
## Where the barrels in flight left his hands (world px).
var _from: Vector2 = Vector2.ZERO
## Seconds the barrels in flight have flown.
var _flown: float = 0.0
## Walking speed before the forced march (px/s; -1 = not read yet).
var _base_speed: float = -1.0
## Game time he arrived (time-to-kill stat; the sway's phase).
var _spawned_at: float = 0.0
## Reusable query buffer.
var _btmp: Array = []


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	throw_cd = first_cd(e, float(def["first_throw"]))
	raged = false
	_landing.clear()
	_flown = 0.0
	_base_speed = -1.0
	_spawned_at = e.game.elapsed
	e.game.enemies.set_miniboss(e)
	e.game.stat_add("shuten_spawned_kit", 1.0)


func on_deactivate(e: Enemy) -> void:
	super.on_deactivate(e)
	_landing.clear()  # The barrels in flight shatter with him.
	e.game.enemies.clear_miniboss(e)


## Barrels, the smash, the rage, the sway and the forced march (see the header).
func physics(e: Enemy, delta: float) -> bool:
	e.knockback = Vector2.ZERO  # Immune to knockback, like the bosses.
	_step_barrels(e, delta)
	throw_cd -= delta
	if not raged and e.hp <= e.max_hp * float(d["rage_hp"]):
		raged = true
		throw_cd = minf(throw_cd, 1.0)
		e.game.stat_add("shuten_rage_at", e.game.elapsed)
		e.game.enemies.show_banner("Shuten-dōji drains his gourd: the barrels rain down!")
		e.game.effects.impact(e.position, e.radius * 2.0, Palette.SHOGUN_LACQUER_LIGHT)
		e.game.shake(6.0)
	match phase:
		THROW_WINDUP:
			phase_time += delta
			hold(e)
			if phase_time >= float(d["throw_windup"]):
				_throw(e)
				set_phase(e, RECOVER)
			return true
		RECOVER:
			phase_time += delta
			hold(e)
			if phase_time >= float(d["recover_time"]):
				set_phase(e, IDLE)
			return true
	if phase == IDLE and throw_cd <= 0.0 and _landing.is_empty():
		var dist := e.position.distance_to(e.game.player.position)  # To the necromancer (px).
		if dist <= float(d["throw_range"]):
			throw_cd = float(d["throw_cooldown"]) * (float(d["rage_cd_mult"]) if raged else 1.0)
			e.motion_lunge(Vector2.ZERO, MotionData.POWER_CAST)  # The barrel heaved up (visual only).
			set_phase(e, THROW_WINDUP)
			hold(e)
			return true
	if super.physics(e, delta):
		return true  # The kanabō smash (OniKit).
	_stagger(e, delta)
	return false


## His drunken gait and the forced march (only while he walks).
func _stagger(e: Enemy, delta: float) -> void:
	if _base_speed < 0.0:
		_base_speed = e.move_speed
	var to := e.game.player.position - e.position
	var far := to.length() > float(d["advance_range"])  # Left behind.
	e.move_speed = _base_speed * (float(d["advance_speed_mult"]) if far else 1.0)
	if to.length() > 1.0:
		var side := Vector2(-to.y, to.x).normalized()  # Across his way.
		var t := e.game.elapsed - _spawned_at
		e.position += side * float(d["sway"]) * sin(t * float(d["sway_rate"])) * delta


## Hurls the barrels (see the header): landing points and their telegraphs.
func _throw(e: Enemy) -> void:
	var g := e.game
	var p := g.player
	var flight := float(d["barrel_flight"])  # s.
	var aim := p.position + p.velocity * flight * float(d["barrel_lead"])  # Led aim point.
	var n := int(d["rage_barrels"] if raged else d["barrels"])
	var spread := float(d["barrel_spread"])  # px.
	var base := (aim - e.position).angle()  # Ring offset of the extra barrels (rad).
	_landing.clear()
	_landing.append(aim)
	for i in n - 1:
		_landing.append(aim + Vector2.from_angle(base + TAU * float(i) / float(maxi(1, n - 1)) + 0.4) * spread)
	for q in _landing:
		g.effects.telegraph_circle(q, float(d["barrel_radius"]), flight, e)
	_from = e.position + Vector2(0.0, -e.radius * 2.0)
	_flown = 0.0
	g.stat_add("shuten_throws", 1.0)
	g.stat_add("shuten_barrels", float(n))
	Sfx.play("abom_stomp", e.position, 0.7)
	e.motion_lunge(aim - e.position, MotionData.POWER_SHOT)


## Flies the barrels; when their flight ends they burst into sake fire.
func _step_barrels(e: Enemy, delta: float) -> void:
	if _landing.is_empty():
		return
	_flown += delta
	e.queue_redraw()  # The arcing barrels (visual only).
	if _flown < float(d["barrel_flight"]):
		return
	var g := e.game
	var r := float(d["barrel_radius"])  # px.
	var mult := hit_scale(e)  # Time scaling x buffs.
	var hits_u := 0
	var hits_p := 0
	var haz := g.enemies.province_hazards()
	for q in _landing:
		g.effects.impact(q, r, Palette.SHOGUN_LACQUER_LIGHT)
		g.ally_grid.query(q, r + UnitData.MAX_BLOCK_RADIUS, _btmp)
		for u: SummonedUnit in _btmp:
			if u.active and not u.airborne and u.state != SummonedUnit.State.SPAWNING and u.position.distance_to(q) <= r + u.radius:
				g.combat.damage_unit(u, float(d["barrel_damage_summon"]) * mult * e.undead_damage_mult, ProvinceEnemyData.BARREL_SOURCE, e)
				hits_u += 1
		for pl in g.all_players:  # (Co-op: every necromancer under it.)
			if pl.position.distance_to(q) <= r + pl.radius:
				g.combat.damage_player(float(d["barrel_damage_player"]) * mult, ProvinceEnemyData.BARREL_SOURCE, pl)
				hits_p += 1
		haz.add_fire(q, float(d["fire_radius"]), float(d["fire_life"]), float(d["fire_tick"]),
				float(d["fire_damage_player"]) * mult, float(d["fire_damage_summon"]) * mult * e.undead_damage_mult, 0.0,
				ProvinceEnemyData.SAKE_FIRE_SOURCE)
	g.stat_add("shuten_barrel_hits_summon", float(hits_u))
	g.stat_add("shuten_barrel_hits_player", float(hits_p))
	rules(e).play_sound("sake_burst", _landing[0])
	g.shake(3.0 + 1.0 * float(_landing.size()))
	_landing.clear()
	e.queue_redraw()


## The XP burst, banner and stats of his fall (the chest is ChestManager's).
func on_killed(e: Enemy) -> void:
	var g := e.game
	var n := maxi(1, int(d["reward_crystals"]))
	var each := maxi(1, floori(float(d["reward_xp"]) / float(n)))  # XP per crystal.
	for i in n:
		g.pickups.spawn(e.position + Vector2.from_angle(TAU * float(i) / float(n)) * (26.0 + 6.0 * float(i % 3)), each)
	g.effects.impact(e.position, e.radius * 3.0, Palette.SHOGUN_LACQUER_LIGHT)
	g.shake(10.0)
	g.enemies.show_banner("Shuten-dōji falls: the Oni King's gourd runs dry!")
	g.stat_add("shuten_kills", 1.0)
	g.stat_add("shuten_ttk", g.elapsed - _spawned_at)


func is_busy() -> bool:
	return phase != IDLE


## Autopilot hint: out of the smash's circle, else out of a landing circle.
func danger_push(e: Enemy, p: Vector2) -> Vector2:
	var push := super.danger_push(e, p)
	if push != Vector2.ZERO:
		return push
	var reach := float(d["barrel_radius"]) + 26.0  # px.
	for q in _landing:
		var away := p - q
		if away.length() < reach:
			return away.normalized() if away.length() > 0.1 else Vector2.RIGHT
	return Vector2.ZERO


## The barrels in flight, arcing from his hands to their landing points (drawn
## in world-axis offsets), and the barrel heaved up during the windup. Visual only.
func draw_over(e: Enemy, ci: CanvasItem) -> void:
	if _landing.is_empty() and phase != THROW_WINDUP:
		return
	unmirror(e, ci)
	if phase == THROW_WINDUP:
		ProvinceGlyphs.draw_barrel(ci, Vector2(0.0, -e.radius * 2.4), 8.0)
	var k := clampf(_flown / maxf(0.01, float(d["barrel_flight"])), 0.0, 1.0)  # 0 -> 1 through the flight.
	for q in _landing:
		var at := _from.lerp(q, k) + Vector2(0.0, -4.0 * k * (1.0 - k) * ARC_HEIGHT)
		ProvinceGlyphs.draw_barrel(ci, at - e.position, 7.0)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
