## CerberusKit — CERBERUS, the hound of the gates, the Asphodel Underworld's
## miniboss (UnderworldEnemyData "cerberus"; Act IV, Stage 12; GDD §15.0 "The
## Asphodel Underworld (Act IV phase 2)"; owner-approved proposal: "Cerberus:
## three heads, three attacks, and each head must be killed on its own").
## UnderworldDirector sends him (the "cerberus" timeline event). He registers
## for the HUD's one miniboss bar (EnemyDirector.set_miniboss()), and the
## ChestManager drops his chest when he dies.
##   * THE BODY cannot be struck: it is untargetable (out of the enemy spatial
##     hash, so no summon, spell or volley finds it). Its HP is the sum of its
##     living heads' HP each tick (the HUD bar shows all three together).
##   * THREE HEADS (UnderworldEnemyData "cerberus_head", CerberusHeadKit):
##     structures that ride on the body at its row's head_offsets, each with
##     head_hp x the time scaling (x the stage HP multiplier), struck and killed
##     on its own. When the last falls, the body dies (the XP burst, the Soul
##     Ash bounty, the chest).
##   * THREE ATTACKS, one per head, taken in turn (a dead head's attack is
##     gone): head 0 FIRE BREATH (a telegraphed cone of Hades' fire that burns
##     every body in it each breath_tick s for breath_time s), head 1 the
##     POUNCE (a telegraphed landing circle on the necromancer's spot; he leaps
##     there and bites everything inside), head 2 the HOWL (shades of the dead
##     rise around him, howl_shades of them, and the summons within howl_reach
##     falter for howl_slow_time s through the summons' ground-slow fields,
##     TerrainSlow.slow_summon(), the one summon slow path).
## Every blow uses CovenantKit.hit_scale() (the enemies' time scaling x his
## buffs). Deterministic: the seeded global RNG only (none used here: the heads
## take their turns in order). Stats: cerberus_spawned, cerberus_heads_killed,
## cerberus_breaths, cerberus_pounces, cerberus_howls, cerberus_player_hits,
## cerberus_summon_hits, cerberus_kills, cerberus_ttk, cerberus_shades.
class_name CerberusKit
extends CovenantKit

## Phase: the fire breath's telegraph.
const BREATH_WINDUP: int = 1
## Phase: the fire breath burning.
const BREATH: int = 2
## Phase: the pounce's crouch (landing circle shown).
const POUNCE_WINDUP: int = 3
## Phase: in the air.
const POUNCE: int = 4
## Phase: the howl's breath in.
const HOWL_WINDUP: int = 5
## Phase: he stands after an attack.
const RECOVER: int = 6
## Damage source tag of the fire breath.
const SRC_BREATH: String = "cerberus_breath"
## Damage source tag of the pounce.
const SRC_POUNCE: String = "cerberus_pounce"

## The heads: [Enemy, generation] per head index (null entry = never raised).
var heads: Array = []
## True once the heads were raised (his first tick).
var _raised: bool = false
## Seconds until the next attack may start.
var special_cd: float = 0.0
## Head index whose attack comes next (in turn, skipping dead heads).
var _next: int = 0
## Unit direction of the current breath / pounce (locked at its windup).
var dir: Vector2 = Vector2.RIGHT
## Where the pounce lands (world px).
var _land: Vector2 = Vector2.ZERO
## Where the pounce started (world px).
var _from: Vector2 = Vector2.ZERO
## Seconds until the breath's next burn.
var _tick: float = 0.0
## Move speed of his walk (px/s; -1 until his first tick).
var _base_speed: float = -1.0
## Game time he arrived (time-to-kill stat).
var _spawned_at: float = 0.0
## Head index whose attack runs now (-1 = none).
var _attacking: int = -1
## True once the dying rule fired (his last head fell).
var _dying: bool = false
## Reusable query buffer.
var _buf: Array = []


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	heads.clear()
	_raised = false
	_dying = false
	special_cd = float(d["first_attack"])
	_next = 0
	_attacking = -1
	_base_speed = -1.0
	_spawned_at = e.game.elapsed
	e.untargetable = true  # The body cannot be struck: the heads can.
	e.game.enemies.set_miniboss(e)
	e.game.stat_add("cerberus_spawned", 1.0)


## Raises the three heads on his first tick (the director has set his HP
## scaling by then), then keeps his HP the sum of theirs.
func think(e: Enemy) -> void:
	if phase != IDLE or special_cd > 0.0 or _dying:
		return
	var g := e.game
	var dist := e.position.distance_to(g.player.position)  # To the necromancer (px).
	for k in 3:
		var h := (_next + k) % 3  # Head whose turn it would be.
		if not _head_alive(h):
			continue
		var ok := false
		match h:
			0:
				ok = dist <= float(d["breath_range"]) * 1.2 or _summons_near(g, e.position, float(d["breath_range"])) >= 3
			1:
				ok = dist >= float(d["pounce_range_min"]) and dist <= float(d["pounce_range_max"]) and not g.ultimates.player_untargetable()
			2:
				ok = true
		if ok:
			_next = (h + 1) % 3
			_start(e, h)
			return


func physics(e: Enemy, delta: float) -> bool:
	var g := e.game
	e.knockback = Vector2.ZERO  # Immune to knockback, like the bosses.
	if not _raised:
		_raise_heads(e)
	_sync_hp(e)
	if _dying:
		hold(e)
		return true
	if phase == IDLE:
		special_cd -= delta
		if _base_speed < 0.0:
			_base_speed = e.move_speed
		var far := e.position.distance_to(g.player.position) > float(d["advance_range"])  # Left behind.
		e.move_speed = _base_speed * (float(d["advance_speed_mult"]) if far else 1.0)
		return false
	phase_time += delta
	match phase:
		BREATH_WINDUP:
			hold(e)
			if phase_time >= float(d["breath_telegraph"]):
				_tick = 0.0
				Sfx.play("fire_breath", e.position)
				set_phase(e, BREATH)
		BREATH:
			hold(e)
			_breath(e, delta)
			if phase_time >= float(d["breath_time"]):
				set_phase(e, RECOVER)
		POUNCE_WINDUP:
			hold(e)
			if phase_time >= float(d["pounce_telegraph"]):
				_from = e.position
				Sfx.play("hound_pounce", e.position)
				set_phase(e, POUNCE)
		POUNCE:
			var k := clampf(phase_time / maxf(0.01, float(d["pounce_time"])), 0.0, 1.0)  # 0 -> 1 through the leap.
			e.position = _from.lerp(_land, k)
			e.velocity = (_land - _from) / maxf(0.01, float(d["pounce_time"]))
			if k >= 1.0:
				_bite(e)
				set_phase(e, RECOVER)
		HOWL_WINDUP:
			hold(e)
			if phase_time >= float(d["howl_telegraph"]):
				_howl(e)
				set_phase(e, RECOVER)
		RECOVER:
			hold(e)
			if phase_time >= float(d["recover_time"]):
				special_cd = float(d["attack_gap"])
				_attacking = -1
				set_phase(e, IDLE)
	return true


## Raises the three heads (HP head_hp x his own HP scaling: the time scaling
## and the stage multiplier the director applied to him, read as max_hp /
## the row's max_hp).
func _raise_heads(e: Enemy) -> void:
	_raised = true
	var g := e.game
	var hp_scale := e.max_hp / maxf(1.0, float(d["max_hp"]))  # His HP scaling.
	heads.clear()
	for i in 3:
		var h := g.enemies.spawn_at(UnderworldEnemyData.CERBERUS_HEAD, e.position, false)
		if h == null:
			heads.append(null)
			continue
		h.max_hp = float(d["head_hp"]) * hp_scale
		h.hp = h.max_hp
		h.display_name = "Head of Cerberus"
		if h.kit is CerberusHeadKit:
			(h.kit as CerberusHeadKit).attach(h, e, i)
		heads.append([h, h.generation])
	var total := 0.0
	for rec: Variant in heads:
		if rec != null:
			total += ((rec as Array)[0] as Enemy).max_hp
	e.max_hp = maxf(1.0, total)
	e.hp = e.max_hp


## His HP is the sum of the living heads'; with none left he dies.
func _sync_hp(e: Enemy) -> void:
	if not _raised or _dying:
		return
	var total := 0.0
	var alive := 0
	for i in heads.size():
		if _head_alive(i):
			var h: Enemy = (heads[i] as Array)[0]
			total += h.hp
			alive += 1
		elif heads[i] != null:
			heads[i] = null
			_on_head_killed(e, i)
	e.hp = maxf(1.0, total)
	if alive == 0:
		_die(e)


## True while head `i` stands.
func _head_alive(i: int) -> bool:
	if i < 0 or i >= heads.size() or heads[i] == null:
		return false
	var rec: Array = heads[i]
	var h: Enemy = rec[0]
	return h.active and h.generation == int(rec[1])


## Head `i` fell: smoke, a howl of pain, the banner.
func _on_head_killed(e: Enemy, i: int) -> void:
	var g := e.game
	g.stat_add("cerberus_heads_killed", 1.0)
	g.effects.impact(head_point(e, i), 26.0, Palette.FLAME)
	g.shake(5.0)
	Sfx.play("hound_howl", e.position, 0.7)
	var left := 0
	for k in heads.size():
		if _head_alive(k):
			left += 1
	if left > 0:
		g.enemies.show_banner("A head of Cerberus falls! (%d left)" % left)
	if _attacking == i and phase != RECOVER:
		set_phase(e, RECOVER)  # Its attack dies with it.


## The last head fell: the body dies through the one kill path (his XP burst,
## the chest, the miniboss bar released).
func _die(e: Enemy) -> void:
	_dying = true
	e.untargetable = false
	e.hp = 1.0
	e.game.combat.damage_enemy(e, 1.0e6, "cerberus_heads")


## Starts head `h`'s attack: its telegraph and stat.
func _start(e: Enemy, h: int) -> void:
	var g := e.game
	_attacking = h
	var to_p := g.player.position - e.position
	dir = to_p.normalized() if to_p.length() > 1.0 else Vector2.RIGHT
	match h:
		0:
			g.effects.telegraph_cone(e.position, dir, float(d["breath_range"]), float(d["breath_half_arc"]), float(d["breath_telegraph"]), e)
			g.stat_add("cerberus_breaths", 1.0)
			e.motion_lunge(dir, MotionData.POWER_CAST)
			set_phase(e, BREATH_WINDUP)
		1:
			_land = g.arena.free_point(g.player.position, e.radius)
			g.effects.telegraph_circle(_land, float(d["pounce_radius"]), float(d["pounce_telegraph"]) + float(d["pounce_time"]), e)
			g.stat_add("cerberus_pounces", 1.0)
			e.motion_lunge(-dir, MotionData.POWER_CAST)
			set_phase(e, POUNCE_WINDUP)
		_:
			g.effects.telegraph_circle(e.position, float(d["howl_reach"]), float(d["howl_telegraph"]), e)
			g.stat_add("cerberus_howls", 1.0)
			set_phase(e, HOWL_WINDUP)


## One tick of the fire breath: every body in the cone burns each breath_tick s.
func _breath(e: Enemy, delta: float) -> void:
	if not _head_alive(0):
		set_phase(e, RECOVER)
		return
	_tick -= delta
	if _tick > 0.0:
		return
	_tick += float(d["breath_tick"])
	var g := e.game
	var reach := float(d["breath_range"])
	var half := float(d["breath_half_arc"])
	var mult := hit_scale(e)
	for pl in g.all_players:  # (Co-op: every necromancer inside.)
		if in_sector(e.position, dir, reach, half, e.radius, pl.position, pl.radius):
			g.combat.damage_player(float(d["breath_damage_player"]) * mult, SRC_BREATH, pl)
			g.stat_add("cerberus_player_hits", 1.0)
	g.ally_grid.query(e.position, reach + UnitData.MAX_BLOCK_RADIUS, _buf)
	for u: SummonedUnit in _buf:
		if not u.active or u.airborne or u.state == SummonedUnit.State.SPAWNING:
			continue
		if in_sector(e.position, dir, reach, half, e.radius, u.position, u.radius):
			g.combat.damage_unit(u, float(d["breath_damage_summon"]) * mult, SRC_BREATH, e)
			g.stat_add("cerberus_summon_hits", 1.0)
	for i in 3:
		var q := e.position + dir.rotated(half * (float(i) - 1.0) * 0.6) * reach * (0.45 + 0.2 * float(i % 2))
		g.effects.pop(q, Palette.FLAME, 16.0)


## The pounce lands: everything inside the circle is bitten.
func _bite(e: Enemy) -> void:
	var g := e.game
	e.position = _land
	e.velocity = Vector2.ZERO
	var r := float(d["pounce_radius"])
	var mult := hit_scale(e)
	g.effects.impact(_land, r, Palette.CRIMSON)
	g.shake(6.0)
	Sfx.play("hound_bite", _land)
	for pl in g.all_players:
		if pl.position.distance_to(_land) <= r + pl.radius:
			g.combat.damage_player(float(d["pounce_damage_player"]) * mult, SRC_POUNCE, pl)
			g.stat_add("cerberus_player_hits", 1.0)
	g.ally_grid.query(_land, r + UnitData.MAX_BLOCK_RADIUS, _buf)
	for u: SummonedUnit in _buf:
		if u.active and not u.airborne and u.position.distance_to(_land) <= r + u.radius:
			g.combat.damage_unit(u, float(d["pounce_damage_summon"]) * mult, SRC_POUNCE, e)
			g.stat_add("cerberus_summon_hits", 1.0)


## The howl: shades rise around him and the summons near him falter (the one
## summon ground-slow path, TerrainSlow.slow_summon()).
func _howl(e: Enemy) -> void:
	var g := e.game
	g.effects.ring(e.position, float(d["howl_reach"]), Palette.PANTHEON_MARBLE_LIGHT, 0.6)
	Sfx.play("hound_howl", e.position)
	var n := int(d["howl_shades"])
	for i in n:
		if g.enemies.regular_alive() >= g.enemies.hard_cap():
			break
		var at := e.position + Vector2.from_angle(TAU * (float(i) + 0.5) / float(n)) * float(d["howl_rise_radius"])
		g.enemies.spawn_at(PantheonEnemyData.SHADE, at, false)
		g.stat_add("cerberus_shades", 1.0)
	g.ally_grid.query(e.position, float(d["howl_reach"]) + UnitData.MAX_BLOCK_RADIUS, _buf)
	for u: SummonedUnit in _buf:
		if u.active and not u.airborne and u.position.distance_to(e.position) <= float(d["howl_reach"]) + u.radius:
			TerrainSlow.slow_summon(g, u, float(d["howl_slow"]), float(d["howl_slow_time"]))


## Living summons on the ground within `r` px of `pos` (body edges included).
func _summons_near(g: Game, pos: Vector2, r: float) -> int:
	g.ally_grid.query(pos, r + UnitData.MAX_BLOCK_RADIUS, _buf)
	var n := 0  # Summons inside.
	for u: SummonedUnit in _buf:
		if u.active and not u.airborne and u.position.distance_to(pos) <= r + u.radius:
			n += 1
	return n


## World point of head `i` on the body (where its hit body rides).
func head_point(e: Enemy, i: int) -> Vector2:
	var offs: Array = d["head_offsets"]
	var o: Vector2 = offs[i % offs.size()]
	var face := signf(e.scale.x) if e.scale.x != 0.0 else 1.0
	return e.position + Vector2(o.x * face, o.y)


## True when head `i` is gone (the drawing greys it out).
func head_dead(i: int) -> bool:
	return _raised and not _head_alive(i)


# =====================================================================================
# Death, hints, drawing
# =====================================================================================

## XP burst and Soul Ash bounty on death (the chest comes from ChestManager's
## miniboss rule); any head still riding is taken off the field.
func on_killed(e: Enemy) -> void:
	var g := e.game
	var n := maxi(1, int(d["reward_crystals"]))
	var each := maxi(1, floori(float(d["reward_xp"]) / float(n)))  # XP per crystal.
	for i in n:
		g.pickups.spawn(e.position + Vector2.from_angle(TAU * float(i) / float(n)) * (26.0 + 6.0 * float(i % 3)), each)
	g.effects.impact(e.position, e.radius * 3.0, Palette.FLAME)
	g.shake(10.0)
	g.enemies.show_banner("Cerberus falls: the gates of the dead stand open!")
	g.stat_add("objective_ash", float(d["reward_ash"]))
	g.stat_add("cerberus_kills", 1.0)
	g.stat_add("cerberus_ttk", g.elapsed - _spawned_at)
	_drop_heads(e)


## Releases the HUD bar and the heads.
func on_deactivate(e: Enemy) -> void:
	super.on_deactivate(e)
	_drop_heads(e)
	e.game.enemies.clear_miniboss(e)


## Takes every head still riding off the field.
func _drop_heads(e: Enemy) -> void:
	for i in heads.size():
		if _head_alive(i):
			e.game.enemies.despawn((heads[i] as Array)[0])
	heads.clear()


## Autopilot hint: out of the breath cone and the pounce circle.
func danger_push(e: Enemy, p: Vector2) -> Vector2:
	var away := p - e.position
	var n := away.normalized() if away.length() > 0.1 else Vector2.RIGHT
	match phase:
		BREATH_WINDUP, BREATH:
			if in_sector(e.position, dir, float(d["breath_range"]) + 24.0, float(d["breath_half_arc"]) + 0.25, e.radius, p, 12.0):
				return n.orthogonal() * (1.0 if n.cross(dir) < 0.0 else -1.0)
		POUNCE_WINDUP, POUNCE:
			var off := p - _land
			if off.length() < float(d["pounce_radius"]) + 30.0:
				return off.normalized() if off.length() > 0.1 else Vector2.RIGHT
	return Vector2.ZERO


## True while a special runs (the shared AI leaves him alone).
func is_busy() -> bool:
	return phase != IDLE


## His body: the cerberus sprite (with the three heads; a dead head greyed and
## smoking), else the code hound. The heads' HP bars are their own.
func draws_body(_e: Enemy) -> bool:
	return true


## Draws the hound (UnderworldGlyphs).
func draw_body(e: Enemy, ci: CanvasItem) -> void:
	var dead: Array[bool] = [head_dead(0), head_dead(1), head_dead(2)]
	UnderworldGlyphs.draw_cerberus(ci, e, dead, phase == BREATH, e.flash > 0.0)
