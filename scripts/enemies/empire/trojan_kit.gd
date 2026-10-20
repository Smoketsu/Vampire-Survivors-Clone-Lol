## TrojanKit — the Trojan Horse, the Scrap Wastes' miniboss (WastesEnemyData
## "trojan_horse"; Act III, GDD §15.0 "The Scrap Wastes (Act III phase 2)";
## owner-approved proposal: "a four-legged drone tank with missile pods that
## fire volleys of slow homing rockets your summons can intercept. Badly
## damaged, its hull splits open and a swarm of Scout Drones pours out"). Spawned
## once by WastesDirector (the "trojan" timeline event) through the normal
## spawn path; it registers as EnemyDirector.miniboss (the HUD's miniboss bar;
## ChestManager drops the miniboss chest). It walks at the necromancer with the
## shared melee AI (striding faster beyond advance_range: it never kites and is
## never left behind), kicks what it reaches, and between attack_gap pauses
## uses one of two telegraphed specials, alternating when both are usable:
##   Rocket volley — its pods glow for volley_telegraph s, then volley_rockets
##                   Swarm Rockets launch fanned over volley_spread rad around
##                   the necromancer's direction (RocketKit: they curve onto
##                   him; a summon in a rocket's path intercepts it, and the
##                   army can shoot them down).
##   Stomp         — a circle of stomp_radius px for stomp_telegraph s (when the
##                   necromancer or stomp_min_summons summons stand within
##                   stomp_range), then its hooves come down: summons inside take
##                   stomp_damage_summon and are thrown out stomp_push px, the
##                   necromancer inside takes stomp_damage_player.
## Hull split (once, below split_hp of its max HP): it stands for SPLIT_TIME s
## while its hull cracks open, split_drones Scout Drones pour out around it, and
## from then on its volleys come split_volley_mult faster with split_rockets
## rockets. Like a boss it shrugs off knockback; freeze / stun durations use
## the caller's boss share (Enemy.is_miniboss). On death: an XP burst
## (reward_xp in reward_crystals) and the miniboss chest (ChestManager). Stats:
## trojan_volleys, trojan_stomps, trojan_stomp_hits, trojan_split_at,
## trojan_kills, trojan_ttk, wastes_rockets_launched. No RNG.
class_name TrojanKit
extends CovenantKit

## Phase: the pods glow before a rocket volley.
const VOLLEY_WINDUP: int = 1
## Phase: the stomp circle is telegraphed.
const STOMP_WINDUP: int = 2
## Phase: the hull splits open (it stands).
const SPLITTING: int = 3
## Phase: standing after a special.
const RECOVER: int = 4
## Seconds the hull takes to split open (it stands meanwhile).
const SPLIT_TIME: float = 1.2  # TUNING (not in GDD)
## Special ids in alternation order.
const SPECIALS := ["volley", "stomp"]
## Damage source tag of the stomp (an area hit for Unholy Resilience's list
## would need its row; it is a plain hit here).
const STOMP_SOURCE: String = "trojan_stomp"

## Seconds until the next special may start (counts down while walking).
var special_cd: float = 0.0
## Special id -> seconds until it may be chosen again.
var cds: Dictionary = {}
## The special used last (the other one goes next when both are usable).
var last_special: String = ""
## True once the hull split open.
var split: bool = false
## Walking speed before the forced march (px/s; read on the first tick so the
## difficulty's speed multiplier is included; -1 = not read yet).
var _base_speed: float = -1.0
## Game time it spawned (time-to-kill stat).
var _spawned_at: float = 0.0
## Reusable query buffer.
var _tmp: Array = []


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	special_cd = float(d["first_special"])
	for id: String in SPECIALS:
		cds[id] = 0.0
	last_special = ""
	split = false
	_base_speed = -1.0
	_spawned_at = e.game.elapsed
	e.game.enemies.set_miniboss(e)
	e.game.stat_add("trojan_spawned", 1.0)


## Picks the next special when ready.
func think(e: Enemy) -> void:
	if phase != IDLE or special_cd > 0.0:
		return
	var g := e.game
	var dist := e.position.distance_to(g.player.position)  # To the necromancer (px).
	var volley_ok := float(cds["volley"]) <= 0.0 and dist <= float(d["volley_range"])
	var stomp_ok := float(cds["stomp"]) <= 0.0 and (dist <= float(d["stomp_range"]) + g.player.radius or _summons_near(e) >= int(d["stomp_min_summons"]))
	if volley_ok and stomp_ok:
		if last_special == "volley":
			volley_ok = false
		else:
			stomp_ok = false
	if volley_ok:
		e.motion_lunge(Vector2.ZERO, MotionData.POWER_CAST)  # Engine motion: the pods rise (visual only).
		Sfx.play("lock_on", e.position, 0.8)
		_begin(e, "volley", VOLLEY_WINDUP)
	elif stomp_ok:
		g.effects.telegraph_circle(e.position, float(d["stomp_radius"]), float(d["stomp_telegraph"]), e)
		e.motion_lunge(Vector2.ZERO, MotionData.POWER_CAST)
		_begin(e, "stomp", STOMP_WINDUP)


## Summons within stomp_range of it.
func _summons_near(e: Enemy) -> int:
	var r := float(d["stomp_range"])  # Reach (px).
	e.game.ally_grid.query(e.position, r + UnitData.MAX_BLOCK_RADIUS, _tmp)
	var n := 0
	for u: SummonedUnit in _tmp:
		if u.active and u.position.distance_to(e.position) <= r + u.radius:
			n += 1
	return n


## Starts special `id`: cooldown, stat, phase.
func _begin(e: Enemy, id: String, p: int) -> void:
	last_special = id
	var cd := float(d[id + "_cooldown"])  # Its cooldown (s).
	if id == "volley" and split:
		cd *= float(d["split_volley_mult"])
	cds[id] = cd
	e.game.stat_add("trojan_%ss" % id, 1.0)
	set_phase(e, p)


func physics(e: Enemy, delta: float) -> bool:
	e.knockback = Vector2.ZERO  # Immune to knockback, like the bosses.
	for id: String in SPECIALS:
		cds[id] = float(cds[id]) - delta
	if not split and phase != SPLITTING and e.hp <= e.max_hp * float(d["split_hp"]):
		_start_split(e)
	if phase == IDLE:
		special_cd -= delta
		if _base_speed < 0.0:
			_base_speed = e.move_speed
		var far := e.position.distance_to(e.game.player.position) > float(d["advance_range"])  # Left behind.
		e.move_speed = _base_speed * (float(d["advance_speed_mult"]) if far else 1.0)
		return false
	phase_time += delta
	hold(e)
	match phase:
		VOLLEY_WINDUP:
			if int(phase_time * 10.0) != int((phase_time - delta) * 10.0):
				e.queue_redraw()  # The pods' glow pulses (visual only).
			if phase_time >= float(d["volley_telegraph"]):
				_fire_volley(e)
				set_phase(e, RECOVER)
		STOMP_WINDUP:
			if phase_time >= float(d["stomp_telegraph"]):
				_resolve_stomp(e)
				set_phase(e, RECOVER)
		SPLITTING:
			if phase_time >= SPLIT_TIME:
				_finish_split(e)
				special_cd = 0.5
				set_phase(e, IDLE)
		RECOVER:
			if phase_time >= float(d["recover_time"]):
				special_cd = float(d["attack_gap"])
				set_phase(e, IDLE)
	return true


## The volley: rockets launch from the pods, fanned around the necromancer's
## direction (each a pooled Swarm Rocket, RocketKit).
func _fire_volley(e: Enemy) -> void:
	var g := e.game
	var n := int(d["split_rockets"] if split else d["volley_rockets"])  # Rockets this volley.
	var to := g.player.position - e.position  # Toward the necromancer.
	var base := to.angle() if to.length_squared() > 1.0 else 0.0  # Fan centre (rad).
	var spread := float(d["volley_spread"])  # Fan width (rad).
	var launched := 0
	for i in n:
		if g.enemies.regular_alive() >= WaveData.HARD_CAP:
			break
		var a := base + (float(i) / maxf(1.0, float(n - 1)) - 0.5) * spread  # This rocket's launch heading.
		var dir := Vector2.from_angle(a)
		var r := g.enemies.spawn_at(WastesEnemyData.ROCKET, e.position + dir * (e.radius + 6.0) + Vector2(0, -e.radius * 0.6), false)
		if r.kit is RocketKit:
			(r.kit as RocketKit).launch(r, dir)
		launched += 1
	g.stat_add("wastes_rockets_launched", float(launched))
	Sfx.play("rocket_launch", e.position)
	e.motion_lunge(to, MotionData.POWER_SHOT)


## The hooves come down: summons inside are hurt and thrown out.
func _resolve_stomp(e: Enemy) -> void:
	var g := e.game
	var r := float(d["stomp_radius"])  # Reach (px).
	var mult := CovenantKit.hit_scale(e)  # Time scaling x buffs.
	g.effects.impact(e.position, r, Palette.EMPIRE_CHROME_LIGHT, "wastes_blast")
	Sfx.play("abom_stomp", e.position, 0.8)
	g.shake(6.0)
	var hits := 0
	g.ally_grid.query(e.position, r + UnitData.MAX_BLOCK_RADIUS, _tmp)
	for u: SummonedUnit in _tmp:
		if not u.active or u.state == SummonedUnit.State.SPAWNING or u.position.distance_to(e.position) > r + u.radius:
			continue
		hits += 1
		var away := u.position - e.position
		u.position += (away.normalized() if away.length() > 0.5 else Vector2.UP) * float(d["stomp_push"])
		g.combat.damage_unit(u, float(d["stomp_damage_summon"]) * mult, STOMP_SOURCE)
	g.stat_add("trojan_stomp_hits", float(hits))
	var p := g.player
	if p.position.distance_to(e.position) <= r + p.radius:
		g.combat.damage_player(float(d["stomp_damage_player"]) * mult, STOMP_SOURCE)


## The hull starts to split (it stands for SPLIT_TIME s).
func _start_split(e: Enemy) -> void:
	e.game.enemies.show_banner("The Trojan Horse's hull splits open: drones pour out!")
	e.game.effects.impact(e.position, e.radius * 2.0, Palette.EMPIRE_SIGNAL_RED)
	Sfx.play("shield_break", e.position, 0.6)
	e.game.stat_add("trojan_split_at", e.game.elapsed)
	set_phase(e, SPLITTING)


## The hull is open: the Scout Drones pour out, its volleys speed up.
func _finish_split(e: Enemy) -> void:
	var g := e.game
	split = true
	var n := int(d["split_drones"])  # Drones released.
	for i in n:
		if g.enemies.regular_alive() >= WaveData.HARD_CAP:
			break
		var at := e.position + Vector2.from_angle(TAU * float(i) / float(n)) * (e.radius + 18.0)
		g.enemies.spawn_at("scout_drone", at, false)
	g.effects.ring(e.position, e.radius * 3.0, Palette.EMPIRE_SIGNAL_AMBER, 0.5)
	g.stat_add("trojan_split_drones", float(n))
	if e.motion != null:
		e.motion.reset(UnitMotion.feet_of(_body_key(), "", e.radius), e.radius, MotionData.MINIBOSS_SCALE, false)
	e.queue_redraw()


## The XP burst, banner and stats of its fall (the chest is ChestManager's).
func on_killed(e: Enemy) -> void:
	var g := e.game
	var n := maxi(1, int(d["reward_crystals"]))
	var each := maxi(1, floori(float(d["reward_xp"]) / float(n)))  # XP per crystal.
	for i in n:
		g.pickups.spawn(e.position + Vector2.from_angle(TAU * float(i) / float(n)) * (26.0 + 6.0 * float(i % 3)), each)
	g.effects.impact(e.position, e.radius * 3.0, Palette.EMPIRE_SIGNAL_AMBER, "wastes_blast")
	g.shake(10.0)
	g.enemies.show_banner("The Trojan Horse is scrap!")
	g.stat_add("trojan_kills", 1.0)
	g.stat_add("trojan_ttk", g.elapsed - _spawned_at)


## Releases the HUD bar.
func on_deactivate(e: Enemy) -> void:
	super.on_deactivate(e)
	e.game.enemies.clear_miniboss(e)


## Autopilot hint: out of the stomp circle.
func danger_push(e: Enemy, p: Vector2) -> Vector2:
	if phase == STOMP_WINDUP:
		var away := p - e.position
		if away.length() < float(d["stomp_radius"]) + 30.0:
			return away.normalized() if away.length() > 0.1 else Vector2.RIGHT
	return Vector2.ZERO


## Sprite key of its current hull (the split one once it opened, when that art exists).
func _body_key() -> String:
	if split and SpriteBank.has("empire/trojan_horse_split"):
		return "empire/trojan_horse_split"
	return "empire/trojan_horse"


## The kit draws the hull: closed, or split open (see _body_key()).
func draws_body(_e: Enemy) -> bool:
	return true


## The body: the hull sprite (closed or split), the code glyph without art.
func draw_body(e: Enemy, ci: CanvasItem) -> void:
	if e.is_elite:
		ci.draw_circle(Vector2.ZERO, e.radius * 1.45, Color(Palette.GOLD, 0.12))
	if not SpriteBank.draw(ci, _body_key(), Vector2.ZERO, e.flash > 0.0):
		WastesGlyphs.draw_trojan(ci, Vector2.ZERO, e.radius, e.flash > 0.0, split)


## The pods' warning glow while a volley winds up. Visual only.
func draw_over(e: Enemy, ci: CanvasItem) -> void:
	if phase == VOLLEY_WINDUP:
		var k := clampf(phase_time / maxf(0.01, float(d["volley_telegraph"])), 0.0, 1.0)  # 0 -> 1 as it fires.
		var on := int(phase_time * 10.0) % 2 == 0  # Blink.
		for sx: float in [-0.45, 0.15]:
			var pod := Vector2(e.radius * sx, -e.radius * 1.1)  # A pod on its back (px).
			ci.draw_circle(pod, 4.0 + 4.0 * k, Color(Palette.EMPIRE_SIGNAL_RED, 0.25 + 0.3 * k))
			if on:
				ci.draw_circle(pod, 2.0, Palette.EMPIRE_SIGNAL_GLOW)
