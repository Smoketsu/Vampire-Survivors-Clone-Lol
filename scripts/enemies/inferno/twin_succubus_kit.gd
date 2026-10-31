## TwinSuccubusKit — THE TWIN SUCCUBI, the miniboss of the Palace of Silk and Ash
## (SilkPalaceEnemyData "twin_naamah" / "twin_agrat", one kit for both sisters;
## Act VI, Stage 17; GDD §15.0 "The Palace of Silk and Ash (Act VI phase 2)";
## owner-approved proposal: "Miniboss, the Twin Succubi: two sisters who charm in
## turns; kill one and the other rages"). Female, in the approved Act VI figure
## style; DEMONS, FLIERS (over the pits and obstacles) and CHARMERS.
## SilkPalaceDirector sends them together (the "twins" timeline event) and binds
## them (bind_sister()). Each walks (flies) at the necromancer with the shared
## melee AI, faster when left behind, shrugs off knockback like a boss, and:
##   * CHARMS IN TURN: the elder from first_charm s, the younger half a turn
##     later (her row's first_charm), then each every charm_every s, so the pair
##     kisses in turns. On her turn, while Temptation has room, she hovers and
##     blows kiss_targets kisses (one more in rage) at the summons nearest her
##     within kiss_range px (a pink line of hearts for kiss_windup s); each kiss
##     that lands charms its summon for kiss_duration s through the one charm
##     path (InfernoKit.try_charm() -> HordeDirector.charm(); Faithless shortens
##     it there; killing her breaks her charms, InfernoKit.on_killed()).
##   * THE KISS OF PAIN: every pain_every s, with a necromancer within
##     pain_reach px, a pink circle of pain_radius px is telegraphed on him for
##     pain_windup s (EffectManager.telegraph_circle(); the autotest bot steps
##     out), then pain_damage_player to every necromancer and pain_damage_summon
##     to every summon inside (x CovenantKit.hit_scale()).
##   * THE RAGE: when her sister falls she rages: rage_heal of her max HP back,
##     move speed x rage_speed, blows x rage_damage (her hits through
##     Enemy.damage, her specials through _mult()), cooldowns x rage_cd, one
##     more kiss a turn; a banner and a crimson aura.
## THE MINIBOSS BAR AND THE CHEST: both sisters register with the HUD's one
## miniboss bar as they arrive (EnemyDirector.set_miniboss(); co-op HP once each)
## and stand as objectives (never recycled) with Enemy.is_miniboss off, so the
## first to fall drops no chest; when one falls the bar passes to the survivor
## (_hand_bar(), the bar's two fields, without a second co-op HP step) and she
## becomes the miniboss (is_miniboss on): her death drops the chest
## (ChestManager) and pays the pair's reward (XP burst, Soul Ash bounty,
## banner). A twin forced alone (--spawn=) fights alone and pays it herself.
## Determinism: no RNG; targets by distance, ties in the ally grid's order.
## Stats: twins_spawned, twin_kisses, twin_kiss_missed, twin_pains,
## twin_pain_hits, twin_rages, twins_killed, twins_ttk.
class_name TwinSuccubusKit
extends InfernoKit

## Phase: her kisses are blown (the windup).
const KISS: int = 1
## Phase: the kiss of pain is telegraphed.
const PAIN: int = 2
## A kiss lands only if its summon is still within this x kiss_range.
const KISS_HOLD: float = 1.4  # TUNING (not in GDD) as the shared succubus
## px beyond the pain circle the autotest bot keeps away (hint only).
const DANGER_REACH: float = 18.0  # TUNING (not in GDD) autotest hint only

## Seconds until her next turn to charm.
var _charm_cd: float = 0.0
## Seconds until her next kiss of pain.
var _pain_cd: float = 0.0
## Her sister (null when forced alone or not bound yet).
var sister: Enemy = null
## Generation of `sister` when bound (stale guard).
var _sister_gen: int = 0
## True once her sister fell and she rages.
var raging: bool = false
## Summons her kisses are blown at, and their generations.
var _targets: Array[SummonedUnit] = []
## Generation of each `_targets` member when the kiss began.
var _target_gen: PackedInt32Array = PackedInt32Array()
## World px of the kiss of pain's circle.
var _pain_at: Vector2 = Vector2.ZERO
## Move speed of her flight before the rage (px/s; -1 until her first tick).
var _base_speed: float = -1.0
## Game time she arrived (time-to-kill stat).
var _spawned_at: float = 0.0
## Summons near her (scratch).
var _tmp: Array = []


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	_charm_cd = float(def.get("first_charm", 3.0))
	_pain_cd = first_cd(e, float(def.get("pain_every", 6.0)) * 0.5)
	sister = null
	raging = false
	_targets.clear()
	_target_gen = PackedInt32Array()
	_base_speed = -1.0
	_spawned_at = e.game.elapsed
	e.game.enemies.set_miniboss(e)  # The HUD bar (the last sister to arrive holds it; co-op HP once each).
	e.is_miniboss = false  # Not a chest until she is the last (see the header).
	e.is_objective = true  # Never recycled.
	e.game.stat_add("twins_spawned", 1.0)


## Binds sister `other` (SilkPalaceDirector, after both arrived).
func bind_sister(other: Enemy) -> void:
	sister = other
	_sister_gen = other.generation if other != null else 0


## True while her bound sister still stands.
func sister_alive() -> bool:
	return sister != null and sister.active and sister.generation == _sister_gen


## x on her specials (the rage).
func _mult(e: Enemy) -> float:
	return hit_scale(e) * (float(d["rage_damage"]) if raging else 1.0)


func physics(e: Enemy, delta: float) -> bool:
	var g := e.game
	e.knockback = Vector2.ZERO  # Immune to knockback, like the bosses.
	var cd_rate := 1.0 / float(d["rage_cd"]) if raging else 1.0  # Cooldowns run faster in rage.
	_charm_cd -= delta * cd_rate
	_pain_cd -= delta * cd_rate
	if _base_speed < 0.0:
		_base_speed = e.move_speed
	match phase:
		KISS:
			phase_time += delta
			hold(e)
			if phase_time >= float(d["kiss_windup"]):
				_land(e)
				set_phase(e, IDLE)
			elif int(phase_time * 20.0) != int((phase_time - delta) * 20.0):
				e.queue_redraw()  # The hearts travel along the kisses.
			return true
		PAIN:
			phase_time += delta
			hold(e)
			if phase_time >= float(d["pain_windup"]):
				_pain(e)
				set_phase(e, IDLE)
			return true
	var dist := e.position.distance_to(g.player.position)  # To the necromancer (px).
	var spd := _base_speed * (float(d["rage_speed"]) if raging else 1.0)
	e.move_speed = spd * (float(d["advance_speed_mult"]) if dist > float(d["advance_range"]) else 1.0)
	if _charm_cd <= 0.0:
		if _start_kiss(e):
			return true
	if _pain_cd <= 0.0 and dist <= float(d["pain_reach"]) and not g.ultimates.player_untargetable():
		_pain_cd = float(d["pain_every"])
		_pain_at = g.player.position
		g.effects.telegraph_circle(_pain_at, float(d["pain_radius"]), float(d["pain_windup"]), e)
		g.stat_add("twin_pains", 1.0)
		set_phase(e, PAIN)
		hold(e)
		return true
	return false


## Her turn to charm: kisses at the nearest summons while Temptation has room.
## False (retried shortly) when nobody is in reach or the charms are full.
func _start_kiss(e: Enemy) -> bool:
	var g := e.game
	if g.inferno != null and g.inferno.temptation.charmed_now() >= int(InfernoRulesData.TEMPTATION["max_charmed"]):
		_charm_cd = 1.0  # Temptation is full: her turn waits a second.
		return false
	var reach := float(d["kiss_range"])
	g.ally_grid.query(e.position, reach, _tmp)
	_tmp.sort_custom(func(a: SummonedUnit, b: SummonedUnit) -> bool: return a.position.distance_squared_to(e.position) < b.position.distance_squared_to(e.position))
	_targets.clear()
	_target_gen = PackedInt32Array()
	var n := int(d["kiss_targets"]) + (1 if raging else 0)
	for u: SummonedUnit in _tmp:
		if _targets.size() >= n:
			break
		if not u.active or u.charmed or u.airborne or u.state == SummonedUnit.State.DEAD or u.state == SummonedUnit.State.SPAWNING:
			continue
		if u.position.distance_to(e.position) > reach:
			continue
		_targets.append(u)
		_target_gen.append(u.generation)
	if _targets.is_empty():
		_charm_cd = 0.5
		return false
	_charm_cd = float(d["charm_every"])
	g.stat_add("twin_kisses", float(_targets.size()))
	set_phase(e, KISS)
	hold(e)
	return true


## The kisses land: each summon still there and in reach is charmed.
func _land(e: Enemy) -> void:
	var g := e.game
	var reach := float(d["kiss_range"]) * KISS_HOLD
	for i in _targets.size():
		var u := _targets[i]
		if u == null or not u.active or u.generation != _target_gen[i] or u.charmed or e.position.distance_to(u.position) > reach \
				or not try_charm(e, u, float(d["kiss_duration"])):
			g.stat_add("twin_kiss_missed", 1.0)
	_targets.clear()


## The kiss of pain strikes everything in its circle.
func _pain(e: Enemy) -> void:
	var g := e.game
	var r := float(d["pain_radius"])
	var m := _mult(e)
	g.effects.impact(_pain_at, r, Palette.INFERNO_CHARM)
	rules(e).play_sound("charm_break", _pain_at)
	for pl in g.all_players:
		if not pl.dead and pl.position.distance_to(_pain_at) <= r + pl.radius:
			g.combat.damage_player(float(d["pain_damage_player"]) * m, SilkPalaceEnemyData.HEARTBREAK_SOURCE, pl)
	g.ally_grid.query(_pain_at, r + PantheonRulesData.SUMMON_SLACK, _tmp)
	for u: SummonedUnit in _tmp:
		if not u.active or u.airborne or u.state == SummonedUnit.State.DEAD or u.position.distance_to(_pain_at) > r + u.radius:
			continue
		g.combat.damage_unit(u, float(d["pain_damage_summon"]) * m * e.undead_damage_mult, SilkPalaceEnemyData.HEARTBREAK_SOURCE, e)
		g.stat_add("twin_pain_hits", 1.0)


## Her sister fell: she rages (see the header).
func rage(e: Enemy) -> void:
	if raging or not e.active:
		return
	raging = true
	var g := e.game
	g.combat.heal_enemy(e, e.max_hp * float(d["rage_heal"]))
	e.damage *= float(d["rage_damage"])
	_charm_cd = minf(_charm_cd, 1.5)
	g.effects.impact(e.position, e.radius * 3.0, Palette.CRIMSON)
	g.shake(5.0)
	g.enemies.show_banner("%s RAGES for her sister!" % e.display_name.get_slice(",", 0))
	g.stat_add("twin_rages", 1.0)
	rules(e).play_sound("twin_rage", e.position)
	e.queue_redraw()


## Passes the HUD's miniboss bar to her (the survivor) and makes her the one
## chest-bearing miniboss. Writes the bar's two fields directly: set_miniboss()
## would give her the co-op HP step a second time.
func _hand_bar(e: Enemy) -> void:
	e.is_miniboss = true
	e.game.enemies.miniboss = e
	e.game.enemies.miniboss_gen = e.generation


## A sister's death: the survivor rages and takes the bar; the last one pays
## the pair's reward. Her charms break (InfernoKit).
func on_killed(e: Enemy) -> void:
	super.on_killed(e)
	var g := e.game
	if sister_alive():
		var sk := sister.kit as TwinSuccubusKit
		if sk != null:
			sk._hand_bar(sister)
			sk.rage(sister)
		g.enemies.show_banner("%s falls! Her sister is enraged!" % e.display_name.get_slice(",", 0))
		g.stat_add("twins_killed", 1.0)
		return
	var n := maxi(1, int(d["reward_crystals"]))
	var each := maxi(1, floori(float(d["reward_xp"]) / float(n)))  # XP per crystal.
	for i in n:
		g.pickups.spawn(e.position + Vector2.from_angle(TAU * float(i) / float(n)) * (26.0 + 6.0 * float(i % 3)), each)
	g.stat_add("objective_ash", float(d["reward_ash"]))
	g.effects.impact(e.position, e.radius * 3.0, Palette.INFERNO_CHARM)
	g.shake(8.0)
	g.enemies.show_banner("The Twin Succubi fall: their last kiss goes cold!")
	g.stat_add("twins_killed", 1.0)
	g.stat_add("twins_ttk", g.elapsed - _spawned_at)


func is_busy() -> bool:
	return phase != IDLE


## Autopilot hint: out of the kiss of pain's circle while it is telegraphed.
func danger_push(_e: Enemy, p: Vector2) -> Vector2:
	if phase != PAIN:
		return Vector2.ZERO
	var reach := float(d["pain_radius"]) + DANGER_REACH
	var off := p - _pain_at
	var dist := off.length()
	if dist >= reach:
		return Vector2.ZERO
	return (off / dist if dist > 0.01 else Vector2.RIGHT) * (1.0 - dist / reach) * 2.0


## Her rage aura on the ground. Visual only.
func draw_under(e: Enemy) -> void:
	if not raging:
		return
	var r := e.radius * 2.2
	e.draw_set_transform(Vector2.ZERO, 0.0, Vector2(e.scale.x, 1.0))
	e.draw_texture_rect(SpriteBank.disc(), Rect2(-Vector2(r, r * 0.5), Vector2(r, r * 0.5) * 2.0), false, Color(Palette.CRIMSON, 0.22))
	e.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## Her blown kisses: pink lines to the summons with hearts travelling along
## them. Visual only.
func draw_over(e: Enemy, ci: CanvasItem) -> void:
	if phase != KISS or _targets.is_empty():
		return
	unmirror(e, ci)
	var k := clampf(phase_time / maxf(float(d["kiss_windup"]), 0.01), 0.0, 1.0)
	for u in _targets:
		if u == null or not u.active:
			continue
		var to := u.position - e.position  # The summon, from her centre (px).
		ci.draw_line(Vector2.ZERO, to, Color(Palette.INFERNO_CHARM, 0.25 + 0.35 * k), 1.0)
		for i in 3:
			var f := fmod(k + float(i) / 3.0, 1.0)  # Position of this heart along the kiss.
			InfernoGlyphs.draw_heart(ci, to * f + Vector2(0.0, -4.0), 4.0 + 2.0 * k, Color(Palette.INFERNO_CHARM, 0.9))
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
