## BossCarmilla — QUEEN CARMILLA AND THE ELDER, the boss of Castle Sanguis and
## the finale of Act VII (the Sanguine Court; GDD §15.0 "Queen Carmilla and
## the Elder (Act VII phase 2)"; owner-approved proposal docs/act7/PROPOSAL.md
## "Stage 21: Castle Sanguis"). Loaded by name for the boss id "carmilla"
## (EnemyDirector.COURT_BOSS_DIR + "boss_carmilla.gd"); she descends from the
## Throne of Blood at 17:00 (3:00 left). Extends Boss, so summons, spells and the
## spatial hash treat her like any enemy. ONE body, three phases (numbers and
## the whole fight in CarmillaData's header):
##   * THE COURT: the Queen (female, the figure style at its limit) walks at
##     the necromancer through the shared walk and claws (enemies always
##     advance), and takes turns between the MIST DANCE (immune mist along a
##     telegraphed line through the ring, draining every body on it) and the
##     DRAIN BEAM (a telegraphed blood beam sweeping across the army, every
##     tick a feeding drain); her NOBLES step out beside her and feed. Every
##     drain names her as the attacker, so Bloodfeast feeds her (boss_def
##     "feeds" 0.5, Bloodfeast.share_of()): THE one heal path.
##   * THE WAKING (at waking_hp of her health): she flies in mist to the
##     ELDER'S COFFIN (it rises beside the fight) and kneels there, immune.
##     The boss bar becomes the Elder's: it starts at elder_floor and FILLS
##     with every heal she lands on him (CombatResolver.heal_enemy() on this
##     body, she the healer: the existing enemy heal path) and every BLOOD
##     BEARER that reaches her (BloodBearerKit -> pour()). A stun or a Deep
##     Freeze on her (step_frozen()) or a Soul Chains hit
##     (CarmillaData.INTERRUPT_SOURCES, read in damage_taken_mult()) stops her
##     feeding for interrupt_time s.
##   * THE ELDER (after rise_time s, invulnerable, climbing out): his health is
##     what she gave him, split between TWO FORMS (owner request, Act VII art
##     review; the Morning Star's Angel / Beast pattern):
##       - THE VAMPIRE LORD (first form, until horror_at of the health he rose
##         with): a fast, regal duelist; telegraphed BLOOD-BLADE LUNGES through
##         the ring (every body on the line cut once, feeding him) and a short
##         MIST STEP (immune) when the necromancer is far.
##       - THE TRANSFORMATION (change_time s, invulnerable: a blood burst, the
##         Court's blood-burst sound, a banner; the sprite flickers between
##         the forms).
##       - THE BAT-WINGED HORROR (second form, the rest): he commands every
##         flier on the map (a frenzy on the necromancer, more bats from his
##         wings), drains every body touching him and beats his wings (a
##         telegraphed circle).
##     His blows feed him in both forms (Bloodfeast, the one heal path).
## Beaten, the Elder turns to ash: the defeat banner and a short
## announcement (CarmillaData.ENDING_ANNOUNCE), no epilogue (owner decision
## Oct 31, 2026). Determinism: no RNG (the coffin rises on her side of the
## necromancer, the bearers come from evenly turned ring points, the specials
## take turns). Stats: boss_atk_<special>, carmilla_spawn_time,
## carmilla_waking_at, carmilla_elder_at, carmilla_kill_time,
## carmilla_player_hits, carmilla_summon_hits, carmilla_fed (Elder HP from her
## feeding), carmilla_fed_bearers (from the bearers), carmilla_interrupts
## (and _stun / _chains), carmilla_bearers (sent), carmilla_bearers_poured,
## carmilla_elder_hp (his health when he rose), carmilla_elder_share,
## carmilla_commanded (fliers frenzied), carmilla_transform_at (the lord's
## transformation began), carmilla_horror_at (the horror walks),
## carmilla_lord_hits (lunge cuts on bodies).
class_name BossCarmilla
extends Boss

## Her phases.
## LORD is the Elder's first form, CHANGING his transformation, ELDER his
## second form (the bat-winged horror).
enum Phase { ARRIVING, COURT, TO_COFFIN, WAKING, RISING, LORD, CHANGING, ELDER }
## Her actions (inside a phase); LUNGE_* and STEP are the vampire lord's.
enum Act { NONE, MIST_WINDUP, MIST, BEAM_WINDUP, BEAM, BUFFET_WINDUP, LUNGE_WINDUP, LUNGE, STEP, RECOVER }

## Current phase.
var phase: Phase = Phase.ARRIVING
## Seconds into the current phase.
var phase_time: float = 0.0
## Current action.
var act: Act = Act.NONE
## Seconds into the current action.
var act_time: float = 0.0
## Seconds until her next special (the Court) / the Elder's next buffet.
var special_cd: float = 0.0
## True when her next special is the mist dance (the dance and the beam take turns).
var _mist_next: bool = true
## Seconds until her next nobles.
var _noble_cd: float = 0.0
## The mist dance's line: start and end (world px).
var _mist_from: Vector2 = Vector2.ZERO
## End of the mist dance's line (world px).
var _mist_to: Vector2 = Vector2.ZERO
## Bodies the current mist dance (or the lord's lunge) already struck (each once).
var _mist_hit: Dictionary = {}
## The vampire lord's lunge line: start (world px).
var _lunge_from: Vector2 = Vector2.ZERO
## End of the lunge line (world px).
var _lunge_to: Vector2 = Vector2.ZERO
## Where the mist step began (world px).
var _step_from: Vector2 = Vector2.ZERO
## Where the mist step reforms him (world px).
var _step_to: Vector2 = Vector2.ZERO
## Health (HP) at which the vampire lord transforms: horror_at of what he rose with.
var _horror_hp: float = 0.0
## Unit direction at the middle of the drain beam's sweep.
var _beam_mid: Vector2 = Vector2.RIGHT
## Seconds until the beam's next tick.
var _beam_tick: float = 0.0
## Where the Elder's coffin stands (world px; valid from the Waking on).
var coffin_at: Vector2 = Vector2.ZERO
## True once the coffin stands (drawn by her from the Waking on).
var has_coffin: bool = false
## True once the coffin is open (the Elder has risen).
var coffin_open: bool = false
## Seconds she still cannot feed (an interrupt; 0 = she feeds).
var interrupt_left: float = 0.0
## Seconds until her next feeding heal (the Waking).
var _feed_cd: float = 0.0
## Seconds until the next pair of blood bearers.
var _bearer_cd: float = 0.0
## Bearer waves sent this Waking (turns their ring angle).
var _bearer_waves: int = 0
## Her stage / co-op HP multiplier (the Elder's health is scaled by it too).
var _hp_mult: float = 1.0
## Seconds until the Elder's next bat command.
var _command_cd: float = 0.0
## Seconds until the Elder's next touch drain.
var _touch_cd: float = 0.0
## Move speed of her walk (px/s).
var _base_speed: float = 52.0
## Game time she arrived.
var _spawn_time: float = 0.0
## Reusable query buffer.
var _buf: Array = []


## Sets up Queen Carmilla at `pos` with HP scaled by `hp_mult`: she descends.
func setup_boss(p_game: Game, pos: Vector2, hp_mult: float, slot: int) -> void:
	boss_def = CarmillaData.BOSS
	activate(p_game, "boss", boss_def, p_game.arena.free_point(pos, float(boss_def["radius"])), hp_mult, false, slot)
	is_boss = true
	z_index = 1
	_hp_mult = hp_mult
	phase = Phase.ARRIVING
	phase_time = 0.0
	act = Act.NONE
	_mist_next = true
	has_coffin = false
	coffin_open = false
	interrupt_left = 0.0
	_bearer_waves = 0
	_base_speed = move_speed
	_spawn_time = game.elapsed
	game.stats["carmilla_spawn_time"] = game.elapsed
	game.enemies.boss_defeated.connect(_on_defeated)
	game.effects.impact(position, radius * 3.0, Palette.COURT_BLOOD)
	game.effects.ring(position, radius * 4.0, Palette.COURT_BLOOD_LIGHT, 0.8)
	game.shake(6.0)
	Sfx.play("boss_impact", position)


## Her abilities in report order (Boss hook).
func special_ids() -> Array:
	return CarmillaData.SPECIALS


## True while she (or the Elder, either form) walks at the necromancer (Boss hook, the stuck check).
func is_walking() -> bool:
	return (phase == Phase.COURT or phase == Phase.LORD or phase == Phase.ELDER) and act == Act.NONE


## Sprite key of the art (engine-motion pivot): the Queen, the vampire lord
## (rising, walking and transforming), then the horror.
func motion_sprite_key() -> String:
	match phase:
		Phase.RISING, Phase.LORD, Phase.CHANGING:
			return CarmillaData.SPRITE_ELDER_LORD
		Phase.ELDER:
			return CarmillaData.SPRITE_ELDER
	return CarmillaData.SPRITE_QUEEN


## Immune while she descends, dances in mist, flies to the coffin, kneels and
## while the Elder rises, mist-steps and transforms; the Queen never falls
## below waking_hp (the Waking takes over) and the lord never below his
## transformation health (the horror takes the rest). A Soul Chains hit during
## the Waking interrupts her feeding.
func damage_taken_mult(source: String) -> float:
	match phase:
		Phase.ARRIVING, Phase.TO_COFFIN, Phase.RISING, Phase.CHANGING:
			return 0.0
		Phase.LORD:
			if act == Act.STEP or hp <= _horror_hp + 1.0:
				return 0.0
		Phase.WAKING:
			if CarmillaData.INTERRUPT_SOURCES.has(source):
				_interrupt("chains")
			return 0.0
		Phase.COURT:
			if act == Act.MIST or hp <= max_hp * float(boss_def["waking_hp"]) + 1.0:
				return 0.0
	return super.damage_taken_mult(source)


## A stun or a Deep Freeze holds her (EnemyDirector calls this instead of
## physics_step()); during the Waking it interrupts her feeding.
func step_frozen(delta: float) -> void:
	super.step_frozen(delta)
	if phase == Phase.WAKING:
		_interrupt("stun")


# =====================================================================================
# Physics: phases and actions
# =====================================================================================

func physics_step(delta: float) -> void:
	phase_time += delta
	knockback = Vector2.ZERO
	match phase:
		Phase.ARRIVING:
			_hold(delta)
			if phase_time >= float(boss_def["arrive_time"]):
				_enter(Phase.COURT)
		Phase.COURT:
			_step_court(delta)
			if hp <= max_hp * float(boss_def["waking_hp"]) + 1.0 and (act == Act.NONE or act == Act.RECOVER):
				_go_to_coffin()
		Phase.TO_COFFIN:
			_step_to_coffin(delta)
		Phase.WAKING:
			_step_waking(delta)
		Phase.RISING:
			_hold(delta)
			if phase_time >= float(boss_def["rise_time"]):
				_enter(Phase.LORD)
		Phase.LORD:
			_step_lord(delta)
			if hp <= _horror_hp + 1.0 and (act == Act.NONE or act == Act.RECOVER):
				_transform()
		Phase.CHANGING:
			_hold(delta)
			if phase_time >= float(boss_def["change_time"]):
				_enter(Phase.ELDER)
		Phase.ELDER:
			_step_elder(delta)


## Starts phase `p` (its banner and opening timers).
func _enter(p: Phase) -> void:
	phase = p
	phase_time = 0.0
	act = Act.NONE
	act_time = 0.0
	match p:
		Phase.COURT:
			special_cd = float(boss_def["special_first"])
			_noble_cd = 0.0  # Her nobles step out at once.
		Phase.LORD:
			special_cd = float(boss_def["lunge_first"])
			attack_interval = float(boss_def["attack_interval"]) * float(boss_def["lord_attack_mult"])
			game.stats["carmilla_elder_at"] = game.elapsed
			game.enemies.show_banner("THE ELDER: the first vampire walks, a lord of the old night! His blood-blade cuts through your ring, and every cut feeds him!")
			game.effects.impact(position, radius * 3.0, Palette.COURT_BLOOD)
			game.shake(8.0)
			Sfx.play("boss_impact", position, 0.9)
		Phase.ELDER:
			radius = float(boss_def["elder_radius"])  # The horror is huge.
			position = game.arena.free_point(position, radius)
			attack_interval = float(boss_def["attack_interval"])
			special_cd = float(boss_def["buffet_first"])
			_command_cd = 0.0  # He commands the bats as he unfolds.
			_touch_cd = float(boss_def["touch_tick"])
			_reset_motion()
			game.stats["carmilla_horror_at"] = game.elapsed
			game.enemies.show_banner("THE ELDER'S TRUE FORM: every bat answers him, and he feeds on all he touches!")
			game.effects.impact(position, radius * 3.0, Palette.COURT_BLOOD)
			game.shake(10.0)
			Sfx.play("boss_impact", position, 0.7)
	queue_redraw()


## Standing still (timers keep running).
func _hold(delta: float) -> void:
	_tick_timers(delta)
	velocity = Vector2.ZERO


## Walks at the necromancer through the shared walk and melee, striding faster
## when far; `mult` scales the pace.
func _walk(delta: float, mult: float) -> void:
	var spd := _base_speed * mult
	if position.distance_to(game.player.position) > float(boss_def["advance_range"]):
		spd *= float(boss_def["advance_speed_mult"])
	move_speed = spd
	super.physics_step(delta)


## Ends an attack: a short recovery.
func _recover() -> void:
	act = Act.RECOVER
	act_time = 0.0
	queue_redraw()


# =====================================================================================
# Phase 1: the Court
# =====================================================================================

## The Court: her nobles on their clock, the mist dance and the beam taking
## turns, else she walks.
func _step_court(delta: float) -> void:
	_noble_cd -= delta
	if _noble_cd <= 0.0:
		_noble_cd = float(boss_def["noble_every"])
		_call_nobles()
	if act != Act.NONE:
		act_time += delta
		match act:
			Act.MIST_WINDUP:
				_hold(delta)
				if act_time >= float(boss_def["mist_telegraph"]):
					_begin_mist()
			Act.MIST:
				_hold(delta)
				_step_mist()
			Act.BEAM_WINDUP:
				_hold(delta)
				if act_time >= float(boss_def["beam_telegraph"]):
					act = Act.BEAM
					act_time = 0.0
					_beam_tick = 0.0
					game.stat_add("boss_atk_drain_beam", 1.0)
					game.court_rules().play_sound("bite_feed", position)
			Act.BEAM:
				_hold(delta)
				_step_beam(delta)
			Act.RECOVER:
				_hold(delta)
				if act_time >= 0.5:
					act = Act.NONE
					act_time = 0.0
		return
	special_cd -= delta
	if special_cd <= 0.0 and not game.ultimates.player_untargetable():
		special_cd = float(boss_def["special_gap"])
		if _mist_next:
			_start_mist()
		else:
			_start_beam()
		_mist_next = not _mist_next
		return
	_walk(delta, 1.0)


## Her nobles step out beside her (at most noble_max alive).
func _call_nobles() -> void:
	var alive := 0
	for e in game.enemies.active:
		if e.active and e.kind == CourtEnemyData.VAMPIRE_NOBLE:
			alive += 1
	var n := mini(int(boss_def["noble_count"]), int(boss_def["noble_max"]) - alive)
	var made := 0
	for i in n:
		if game.enemies.regular_alive() >= game.enemies.hard_cap():
			break
		var at := game.arena.free_point(position + Vector2.from_angle(PI * float(i) + phase_time) * float(boss_def["noble_dist"]), 10.0)
		if game.enemies.spawn_at(CourtEnemyData.VAMPIRE_NOBLE, at, false) != null:
			made += 1
			game.effects.ring(at, 24.0, Palette.COURT_BLOOD_LIGHT, 0.4)
	if made > 0:
		game.stat_add("boss_atk_nobles", float(made))


## Telegraphs the mist dance: a line from her through the necromancer.
func _start_mist() -> void:
	var to := game.player.position - position
	var dir := to.normalized() if to.length() > 1.0 else Vector2.RIGHT
	_mist_from = position
	_mist_to = game.player.position + dir * float(boss_def["mist_overshoot"])
	game.effects.telegraph_line(_mist_from, _mist_to, float(boss_def["mist_width"]), float(boss_def["mist_telegraph"]), self)
	motion_lunge(dir, MotionData.POWER_CAST)
	act = Act.MIST_WINDUP
	act_time = 0.0
	queue_redraw()


## She turns to mist and dances along the line.
func _begin_mist() -> void:
	act = Act.MIST
	act_time = 0.0
	_mist_hit.clear()
	untargetable = true
	flies = true  # In mist the ring cannot body-block her.
	game.stat_add("boss_atk_mist_dance", 1.0)
	game.effects.ring(position, radius * 2.0, Palette.COURT_MOON_LIGHT, 0.35)
	game.court_rules().play_sound("mist_form", position)
	queue_redraw()


## The dance: she drifts along the line; every body she passes is drained once.
func _step_mist() -> void:
	var t := clampf(act_time / maxf(float(boss_def["mist_time"]), 0.01), 0.0, 1.0)
	position = _mist_from.lerp(_mist_to, t)
	var half := float(boss_def["mist_width"]) * 0.5 + radius * 0.5
	var mult := game.enemies.damage_mult * hit_mult()
	for pl in game.all_players:
		if not pl.dead and not _mist_hit.has(pl) and pl.position.distance_to(position) <= half + pl.radius:
			_mist_hit[pl] = true
			game.combat.damage_player(float(boss_def["mist_damage_player"]) * mult, CarmillaData.SRC_MIST, pl, self)
			game.stat_add("carmilla_player_hits", 1.0)
	game.ally_grid.query(position, half + UnitData.MAX_BLOCK_RADIUS, _buf)
	for u: SummonedUnit in _buf:
		if _mist_hit.has(u) or not u.active or u.state == SummonedUnit.State.SPAWNING or u.state == SummonedUnit.State.DEAD:
			continue
		if u.position.distance_to(position) <= half + u.radius:
			_mist_hit[u] = true
			game.combat.damage_unit(u, float(boss_def["mist_damage_summon"]) * mult, CarmillaData.SRC_MIST, self)
			game.stat_add("carmilla_summon_hits", 1.0)
	queue_redraw()
	if t >= 1.0:
		position = game.arena.free_point(position, radius)
		untargetable = false
		flies = false
		_mist_hit.clear()
		game.effects.ring(position, radius * 2.0, Palette.COURT_BLOOD_LIGHT, 0.35)
		_recover()


## Telegraphs the drain beam's sweep (centred on the necromancer).
func _start_beam() -> void:
	var to := game.player.position - position
	_beam_mid = to.normalized() if to.length() > 1.0 else Vector2.RIGHT
	var half := deg_to_rad(float(boss_def["beam_arc"])) * 0.5
	game.effects.telegraph_cone(position, _beam_mid, float(boss_def["beam_length"]), half, float(boss_def["beam_telegraph"]), self)
	motion_lunge(_beam_mid, MotionData.POWER_CAST)
	act = Act.BEAM_WINDUP
	act_time = 0.0
	queue_redraw()


## Unit direction of the drain beam now (it sweeps from one edge of the arc to the other).
func _beam_dir() -> Vector2:
	var half := deg_to_rad(float(boss_def["beam_arc"])) * 0.5
	var t := clampf(act_time / maxf(float(boss_def["beam_time"]), 0.01), 0.0, 1.0)
	return _beam_mid.rotated(lerpf(-half, half, t))


## The beam sweeps: every beam_tick s every body on it is drained (a feeding hit).
func _step_beam(delta: float) -> void:
	_beam_tick -= delta
	queue_redraw()
	if _beam_tick <= 0.0:
		_beam_tick += float(boss_def["beam_tick"])
		var a := position
		var b := position + _beam_dir() * float(boss_def["beam_length"])
		var half := float(boss_def["beam_width"]) * 0.5
		var mult := game.enemies.damage_mult * hit_mult()
		for pl in game.all_players:
			if not pl.dead and DivineWrath._seg_dist(pl.position, a, b) <= half + pl.radius:
				game.combat.damage_player(float(boss_def["beam_damage_player"]) * mult, CarmillaData.SRC_BEAM, pl, self)
				game.stat_add("carmilla_player_hits", 1.0)
		game.ally_grid.query(a.lerp(b, 0.5), a.distance_to(b) * 0.5 + half + UnitData.MAX_BLOCK_RADIUS, _buf)
		for u: SummonedUnit in _buf:
			if not u.active or u.state == SummonedUnit.State.SPAWNING or u.state == SummonedUnit.State.DEAD:
				continue
			if DivineWrath._seg_dist(u.position, a, b) <= half + u.radius:
				game.combat.damage_unit(u, float(boss_def["beam_damage_summon"]) * mult, CarmillaData.SRC_BEAM, self)
				game.stat_add("carmilla_summon_hits", 1.0)
	if act_time >= float(boss_def["beam_time"]):
		_recover()


# =====================================================================================
# Phase 2: the Waking
# =====================================================================================

## She breaks off: the coffin rises on her side of the necromancer and she
## flies to it in mist.
func _go_to_coffin() -> void:
	untargetable = true
	flies = true
	var away := position - game.player.position
	var dir := away.normalized() if away.length() > 1.0 else Vector2.UP
	coffin_at = game.arena.free_point(game.player.position + dir * float(boss_def["coffin_dist"]), 18.0)
	has_coffin = true
	coffin_open = false
	phase = Phase.TO_COFFIN
	phase_time = 0.0
	act = Act.NONE
	game.stats["carmilla_waking_at"] = game.elapsed
	game.stat_add("boss_atk_waking", 1.0)
	game.enemies.show_banner("THE WAKING: Carmilla kneels at the Elder's coffin to feed him! Stun her, chain her, kill her blood bearers!")
	game.effects.impact(coffin_at, 40.0, Palette.COURT_BLOOD)
	game.court_rules().play_sound("coffin_creak", coffin_at)
	game.shake(5.0)
	queue_redraw()


## Her flight to the coffin (at most kneel_travel s).
func _step_to_coffin(delta: float) -> void:
	_hold(delta)
	var kneel := coffin_at + Vector2(0.0, 26.0)  # She kneels before it.
	var to := kneel - position
	var left := maxf(0.01, float(boss_def["kneel_travel"]) - phase_time + delta)
	var step := minf(to.length(), maxf(to.length() / left * delta, 160.0 * delta))
	if to.length() > 0.5:
		position += to.normalized() * step
	queue_redraw()
	if position.distance_to(kneel) <= 1.0 or phase_time >= float(boss_def["kneel_travel"]):
		position = kneel
		_begin_waking()


## She kneels: the bar becomes the Elder's, starting at elder_floor.
func _begin_waking() -> void:
	phase = Phase.WAKING
	phase_time = 0.0
	untargetable = false
	flies = false
	var full := float(boss_def["elder_hp"]) * _hp_mult  # The Elder's full health.
	max_hp = full
	hp = full * float(boss_def["elder_floor"])
	_feed_cd = float(boss_def["feed_tick"])
	_bearer_cd = 0.5
	interrupt_left = 0.0
	queue_redraw()


## The Waking: she feeds the Elder (unless interrupted), the bearers come; it
## ends when the time is up or he is full.
func _step_waking(delta: float) -> void:
	_hold(delta)
	interrupt_left = maxf(0.0, interrupt_left - delta)
	_feed_cd -= delta
	if _feed_cd <= 0.0:
		_feed_cd += float(boss_def["feed_tick"])
		if interrupt_left <= 0.0:
			var got := game.combat.heal_enemy(self, max_hp * float(boss_def["feed_rate"]) * float(boss_def["feed_tick"]), self)
			game.stat_add("carmilla_fed", got)
	_bearer_cd -= delta
	if _bearer_cd <= 0.0:
		_bearer_cd = float(boss_def["bearer_every"])
		_send_bearers()
	queue_redraw()
	if phase_time >= float(boss_def["waking_time"]) or hp >= max_hp - 0.5:
		_rise()


## A pair of blood bearers from the spawn ring (evenly turned; the hard cap respected).
func _send_bearers() -> void:
	var n := int(boss_def["bearer_count"])
	for i in n:
		if game.enemies.regular_alive() >= game.enemies.hard_cap():
			break
		var ang := (TAU / float(maxi(1, n))) * float(i) + float(_bearer_waves) * 2.4
		if game.enemies.spawn_at(CastleSanguisEnemyData.BEARER, game.enemies.ring_point(ang), false) != null:
			game.stat_add("carmilla_bearers", 1.0)
	_bearer_waves += 1


## A bearer reached her (BloodBearerKit): its chalice feeds the Elder. False
## outside the Waking (the bearer then keeps walking).
func pour(bearer: Enemy) -> bool:
	if phase != Phase.WAKING:
		return false
	var got := game.combat.heal_enemy(self, max_hp * float(boss_def["bearer_heal"]), self)
	game.stat_add("carmilla_fed_bearers", got)
	game.stat_add("boss_atk_bearers_poured", 1.0)
	game.stat_add("carmilla_bearers_poured", 1.0)
	game.effects.ring(bearer.position, 18.0, Palette.COURT_BLOOD_LIGHT, 0.3)
	return true


## True while she kneels and feeds (the bearers walk to her only then).
func is_kneeling() -> bool:
	return phase == Phase.WAKING


## Her feeding is interrupted (a stun, a freeze, a Soul Chains hit): no heal
## for interrupt_time s (a new interrupt restarts the time; counted once per
## pause).
func _interrupt(why: String) -> void:
	if interrupt_left <= 0.0:
		game.stat_add("carmilla_interrupts", 1.0)
		game.stat_add("carmilla_interrupts_" + why, 1.0)
		game.stat_add("boss_atk_interrupted", 1.0)
		game.effects.ring(position, radius * 1.8, Palette.COURT_MOON_LIGHT, 0.3)
	interrupt_left = float(boss_def["interrupt_time"])


## The Waking ends: the coffin opens and the Elder climbs out (invulnerable),
## with the health she gave him.
func _rise() -> void:
	phase = Phase.RISING
	phase_time = 0.0
	act = Act.NONE
	coffin_open = true
	position = game.arena.free_point(coffin_at, float(boss_def["lord_radius"]))
	radius = float(boss_def["lord_radius"])  # The vampire lord first (the horror grows to elder_radius).
	display_name = "The Elder"
	_horror_hp = hp * float(boss_def["horror_at"])
	_reset_motion()
	game.stats["carmilla_elder_hp"] = hp
	game.stats["carmilla_elder_share"] = hp / maxf(max_hp, 1.0)
	game.stat_add("boss_atk_elder_rises", 1.0)
	game.enemies.show_banner("The coffin opens... Carmilla gives the last of her blood, and the Elder climbs out!")
	game.effects.ring(coffin_at, 160.0, Palette.COURT_BLOOD, 1.0)
	Juice.fx.burst(coffin_at, Palette.COURT_BLOOD_LIGHT, Palette.COURT_VELVET_LIGHT, 22, 240.0, 1.0, 3.0)
	game.court_rules().play_sound("coffin_creak", coffin_at)
	game.shake(8.0)
	queue_redraw()


## Re-seats the engine motion on the current form's art and radius (as
## BossMerrow's change). Visual only.
func _reset_motion() -> void:
	if motion != null:
		motion.reset(UnitMotion.feet_of(motion_sprite_key(), "", radius), radius, MotionData.BOSS_SCALE, false)


# =====================================================================================
# Phase 3a: the Elder's first form, the vampire lord
# =====================================================================================

## The vampire lord: the lunge and the mist step on one clock, else he walks
## (fast) at the necromancer with his claws.
func _step_lord(delta: float) -> void:
	if act != Act.NONE:
		act_time += delta
		_hold(delta)
		match act:
			Act.LUNGE_WINDUP:
				if act_time >= float(boss_def["lunge_telegraph"]):
					act = Act.LUNGE
					act_time = 0.0
					_mist_hit.clear()
					game.stat_add("boss_atk_blood_lunge", 1.0)
					game.court_rules().play_sound("bite_feed", position)
			Act.LUNGE:
				_step_lunge()
			Act.STEP:
				_step_mist_step()
			Act.RECOVER:
				if act_time >= 0.35:
					act = Act.NONE
					act_time = 0.0
		return
	special_cd -= delta
	if special_cd <= 0.0 and not game.ultimates.player_untargetable():
		var dist := position.distance_to(game.player.position)
		if dist > float(boss_def["step_trigger"]):
			_start_mist_step()
			return
		if dist <= float(boss_def["lunge_range"]):
			_start_lunge()
			return
	_walk(delta, float(boss_def["lord_speed_mult"]))


## Telegraphs the blood-blade lunge: a line from him through the necromancer.
func _start_lunge() -> void:
	var to := game.player.position - position
	var dir := to.normalized() if to.length() > 1.0 else Vector2.RIGHT
	_lunge_from = position
	_lunge_to = position + dir * game.arena.clear_length(position, dir, float(boss_def["lunge_length"]), radius)
	game.effects.telegraph_line(_lunge_from, _lunge_to, float(boss_def["lunge_width"]), float(boss_def["lunge_telegraph"]), self)
	motion_lunge(dir, MotionData.POWER_CAST)
	special_cd = float(boss_def["lunge_cooldown"])
	act = Act.LUNGE_WINDUP
	act_time = 0.0
	queue_redraw()


## The cut: he darts along the line; every body he passes is cut once (a feeding hit).
func _step_lunge() -> void:
	var t := clampf(act_time / maxf(float(boss_def["lunge_time"]), 0.01), 0.0, 1.0)
	position = _lunge_from.lerp(_lunge_to, t)
	var half := float(boss_def["lunge_width"]) * 0.5 + radius * 0.5
	var mult := game.enemies.damage_mult * hit_mult()
	for pl in game.all_players:
		if not pl.dead and not _mist_hit.has(pl) and pl.position.distance_to(position) <= half + pl.radius:
			_mist_hit[pl] = true
			game.combat.damage_player(float(boss_def["lunge_damage_player"]) * mult, CarmillaData.SRC_LUNGE, pl, self)
			game.stat_add("carmilla_player_hits", 1.0)
	var hits: Array = []  # Own buffer: a death hook may query the grid again.
	game.ally_grid.query(position, half + UnitData.MAX_BLOCK_RADIUS, hits)
	for u: SummonedUnit in hits:
		if _mist_hit.has(u) or not u.active or u.state == SummonedUnit.State.SPAWNING or u.state == SummonedUnit.State.DEAD:
			continue
		if u.position.distance_to(position) <= half + u.radius:
			_mist_hit[u] = true
			game.combat.damage_unit(u, float(boss_def["lunge_damage_summon"]) * mult, CarmillaData.SRC_LUNGE, self)
			game.stat_add("carmilla_summon_hits", 1.0)
			game.stat_add("carmilla_lord_hits", 1.0)
	queue_redraw()
	if t >= 1.0:
		position = game.arena.free_point(position, radius)
		_mist_hit.clear()
		game.effects.ring(position, radius * 1.6, Palette.COURT_BLOOD_LIGHT, 0.3)
		_recover()


## The mist step: he dissolves (untargetable, immune) toward the necromancer.
func _start_mist_step() -> void:
	var to := game.player.position - position
	var dir := to.normalized() if to.length() > 1.0 else Vector2.RIGHT
	_step_from = position
	_step_to = game.player.position - dir * float(boss_def["step_land"])
	special_cd = float(boss_def["step_followup"])
	untargetable = true
	flies = true  # In mist the ring cannot body-block him.
	act = Act.STEP
	act_time = 0.0
	game.stat_add("boss_atk_mist_step", 1.0)
	game.effects.ring(position, radius * 2.0, Palette.COURT_MOON_LIGHT, 0.35)
	game.court_rules().play_sound("mist_form", position)
	queue_redraw()


## The step: he drifts to the landing point and reforms there.
func _step_mist_step() -> void:
	var t := clampf(act_time / maxf(float(boss_def["step_time"]), 0.01), 0.0, 1.0)
	position = _step_from.lerp(_step_to, t)
	queue_redraw()
	if t >= 1.0:
		position = game.arena.free_point(position, radius)
		untargetable = false
		flies = false
		game.effects.ring(position, radius * 2.0, Palette.COURT_BLOOD_LIGHT, 0.35)
		act = Act.NONE
		act_time = 0.0


## The transformation (invulnerable): the lord's skin splits and his wings
## unfold (a burst of blood, the Court's blood-burst sound, a banner; no
## damage: the horror's first buffet comes buffet_first s after).
func _transform() -> void:
	phase = Phase.CHANGING
	phase_time = 0.0
	act = Act.NONE
	act_time = 0.0
	untargetable = false
	flies = false
	game.stats["carmilla_transform_at"] = game.elapsed
	game.stat_add("boss_atk_transform", 1.0)
	game.enemies.show_banner("The Elder's skin splits... the first vampire unfolds his wings!")
	game.effects.ring(position, 180.0, Palette.COURT_BLOOD, 1.0)
	game.effects.ring(position, 110.0, Palette.COURT_VELVET_LIGHT, 0.8)
	Juice.fx.burst(position, Palette.COURT_BLOOD_LIGHT, Palette.COURT_VELVET_LIGHT, 22, 260.0, 1.0, 3.0)
	game.court_rules().play_sound("blood_burst", position)
	game.shake(8.0)
	Sfx.play("boss_impact", position, 0.8)
	queue_redraw()


# =====================================================================================
# Phase 3b: the Elder's second form, the bat-winged horror
# =====================================================================================

## The Elder: his bats, his touch, his wings; he lumbers between.
func _step_elder(delta: float) -> void:
	_command_cd -= delta
	if _command_cd <= 0.0:
		_command_cd = float(boss_def["command_every"])
		_command_bats()
	_touch_cd -= delta
	if _touch_cd <= 0.0:
		_touch_cd += float(boss_def["touch_tick"])
		_touch()
	if act != Act.NONE:
		act_time += delta
		_hold(delta)
		match act:
			Act.BUFFET_WINDUP:
				if act_time >= float(boss_def["buffet_telegraph"]):
					_buffet()
					_recover()
			Act.RECOVER:
				if act_time >= 0.45:
					act = Act.NONE
					act_time = 0.0
		return
	special_cd -= delta
	if special_cd <= 0.0 and _body_near(float(boss_def["buffet_trigger"])):
		special_cd = float(boss_def["buffet_cooldown"])
		game.effects.telegraph_circle(position, float(boss_def["buffet_radius"]), float(boss_def["buffet_telegraph"]), self)
		motion_lunge(Vector2.ZERO, MotionData.POWER_CAST)
		game.stat_add("boss_atk_wing_buffet", 1.0)
		act = Act.BUFFET_WINDUP
		act_time = 0.0
		queue_redraw()
		return
	_walk(delta, float(boss_def["elder_speed_mult"]))


## True when a necromancer or a summon stands within `reach` px of his edge.
func _body_near(reach: float) -> bool:
	for pl in game.all_players:
		if not pl.dead and pl.position.distance_to(position) - pl.radius - radius <= reach:
			return true
	game.ally_grid.query(position, radius + reach + UnitData.MAX_BLOCK_RADIUS, _buf)
	for u: SummonedUnit in _buf:
		if u.active and u.state != SummonedUnit.State.DEAD and u.position.distance_to(position) - u.radius - radius <= reach:
			return true
	return false


## He commands every bat on the map: every flier alive turns on the necromancer
## in a frenzy, and more bats burst from his wings.
func _command_bats() -> void:
	var n := 0
	for e in game.enemies.active:
		if not e.active or e == self or not e.flies or e.is_miniboss:
			continue
		e.apply_buff(float(boss_def["command_damage"]), float(boss_def["command_speed"]), 1.0, float(boss_def["command_time"]))
		e._set_target(game.player)
		n += 1
	var made := 0
	var k := int(boss_def["command_bats"])
	for i in k:
		if game.enemies.regular_alive() >= game.enemies.hard_cap():
			break
		var at := position + Vector2.from_angle(TAU * float(i) / float(maxi(1, k)) + phase_time) * (radius + 20.0)
		var bat := game.enemies.spawn_at(CourtEnemyData.VAMPIRE_BAT, at, false)
		if bat != null:
			bat.apply_buff(float(boss_def["command_damage"]), float(boss_def["command_speed"]), 1.0, float(boss_def["command_time"]))
			made += 1
	game.stat_add("carmilla_commanded", float(n + made))
	game.stat_add("boss_atk_bat_command", 1.0)
	game.effects.ring(position, 200.0, Palette.COURT_VELVET_LIGHT, 0.6)
	game.court_rules().play_sound("bat_screech", position)


## He feeds on everything he touches: every body touching him is drained.
func _touch() -> void:
	var reach := float(boss_def["touch_reach"])
	var mult := game.enemies.damage_mult * hit_mult()
	for pl in game.all_players:
		if not pl.dead and pl.position.distance_to(position) - pl.radius - radius <= reach:
			game.combat.damage_player(float(boss_def["touch_damage_player"]) * mult, CarmillaData.SRC_TOUCH, pl, self)
			game.stat_add("carmilla_player_hits", 1.0)
	game.ally_grid.query(position, radius + reach + UnitData.MAX_BLOCK_RADIUS, _buf)
	for u: SummonedUnit in _buf:
		if not u.active or u.state == SummonedUnit.State.SPAWNING or u.state == SummonedUnit.State.DEAD:
			continue
		if u.position.distance_to(position) - u.radius - radius <= reach:
			game.combat.damage_unit(u, float(boss_def["touch_damage_summon"]) * mult, CarmillaData.SRC_TOUCH, self)
			game.stat_add("carmilla_summon_hits", 1.0)


## His wings beat: every body in the circle is struck, the summons thrown back.
func _buffet() -> void:
	var r := float(boss_def["buffet_radius"])
	var mult := game.enemies.damage_mult * hit_mult()
	game.effects.impact(position, r, Palette.COURT_VELVET_LIGHT)
	game.shake(5.0)
	Sfx.play("boss_impact", position, 1.1)
	for pl in game.all_players:
		if not pl.dead and pl.position.distance_to(position) <= r + pl.radius:
			game.combat.damage_player(float(boss_def["buffet_damage_player"]) * mult, CarmillaData.SRC_BUFFET, pl, self)
			game.stat_add("carmilla_player_hits", 1.0)
	var hits: Array = []  # Own buffer: a death hook may query the grid again.
	game.ally_grid.query(position, r + UnitData.MAX_BLOCK_RADIUS, hits)
	for u: SummonedUnit in hits:
		if not u.active or u.airborne or u.state == SummonedUnit.State.SPAWNING or u.state == SummonedUnit.State.DEAD:
			continue
		if u.position.distance_to(position) > r + u.radius:
			continue
		game.combat.damage_unit(u, float(boss_def["buffet_damage_summon"]) * mult, CarmillaData.SRC_BUFFET, self)
		game.stat_add("carmilla_summon_hits", 1.0)
		if u.active and u.state != SummonedUnit.State.DEAD:
			var away := (u.position - position).normalized() if u.position.distance_squared_to(position) > 1.0 else Vector2.RIGHT
			u.position += away * game.arena.clear_length(u.position, away, float(boss_def["buffet_push"]), u.radius)


# =====================================================================================
# Death, autopilot hint, drawing
# =====================================================================================

## The Elder's defeat (EnemyDirector.boss_defeated, after the reward burst): he
## turns to ash and the Court's veil tears.
func _on_defeated() -> void:
	var pos := position
	game.effects.ring(pos, 220.0, Palette.COURT_MOON_LIGHT, 1.0)
	game.effects.ring(pos, 130.0, Palette.COURT_BLOOD_LIGHT, 0.8)
	Juice.fx.burst(pos, Palette.COURT_MOON, Palette.COURT_BLOOD_DARK, 26, 320.0, 1.0, 3.5)
	game.shake(12.0)
	Sfx.play("boss_impact", pos, 0.6)
	var late := game.countdown_finished()  # He fell during the Endless Feast.
	game.enemies.show_banner(String(CarmillaData.ARRIVAL["defeat_banner"]))
	game.enemies.banner_until = game.elapsed + CarmillaData.ENDING_BANNER_TIME
	if game.hud != null:
		var txt: Array = CarmillaData.LATE_ANNOUNCE if late else CarmillaData.ENDING_ANNOUNCE
		game.hud.announce(String(txt[0]), String(txt[1]), String(txt[2]), Palette.COURT_BLOOD_LIGHT)
	game.stats["carmilla_kill_time"] = game.elapsed - _spawn_time


## Danger hint for the autotest autopilot: off the mist line and the beam's arc
## while they are telegraphed, out of the wing buffet.
func danger_push(p: Vector2) -> Vector2:
	match act:
		Act.MIST_WINDUP, Act.MIST:
			return KirinKit._off_line(p, _mist_from, _mist_to, float(boss_def["mist_width"]) * 0.5 + 18.0)
		Act.BEAM_WINDUP, Act.BEAM:
			var half := deg_to_rad(float(boss_def["beam_arc"])) * 0.5 + 0.2
			if CovenantKit.in_sector(position, _beam_mid, float(boss_def["beam_length"]) + 20.0, half, radius, p, 12.0):
				var away := p - position
				return away.normalized() * 1.5 if away.length() > 0.1 else Vector2.RIGHT
		Act.LUNGE_WINDUP, Act.LUNGE:
			return KirinKit._off_line(p, _lunge_from, _lunge_to, float(boss_def["lunge_width"]) * 0.5 + 18.0)
		Act.BUFFET_WINDUP:
			var reach := float(boss_def["buffet_radius"]) + 20.0
			var off := p - position
			if off.length() < reach:
				return (off.normalized() if off.length() > 0.1 else Vector2.RIGHT) * (1.0 - off.length() / reach) * 2.5
	return Vector2.ZERO


## Under the body: the Elder's coffin (from the Waking on) and a pool of blood
## under her. Visual only.
func _draw_under() -> void:
	if has_coffin and phase != Phase.LORD and phase != Phase.CHANGING and phase != Phase.ELDER:
		var c := (coffin_at - position) * Vector2(scale.x, 1.0)  # The coffin in her (mirrored) frame.
		var key := CarmillaData.SPRITE_COFFIN_OPEN if coffin_open else CarmillaData.SPRITE_COFFIN
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(scale.x, 1.0))
		if not SpriteBank.draw(self, key, c, false):
			CourtGlyphs.draw_coffin(self, c, 16.0, false, coffin_open)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var col := Palette.COURT_VELVET_LIGHT if phase == Phase.ELDER or phase == Phase.CHANGING else Palette.COURT_BLOOD
	var a := 0.18
	if phase == Phase.ARRIVING:
		a *= clampf(phase_time / maxf(0.1, float(boss_def["arrive_time"])), 0.0, 1.0)
	var r := radius * 2.4
	draw_texture_rect(SpriteBank.disc(), Rect2(Vector2(-r, -r * 0.5), Vector2(r * 2.0, r)), false, Color(col, a))


## Body layer on `ci`: the Queen (in mist: drifting mist), then the Elder's
## vampire lord (in his mist step: mist), flickering into the horror while he
## transforms (as Lilith's demon form), then the horror; the glyphs without art.
func _draw_body(ci: CanvasItem) -> void:
	if (phase == Phase.COURT and act == Act.MIST) or phase == Phase.TO_COFFIN or (phase == Phase.LORD and act == Act.STEP):
		CourtGlyphs.draw_mist(ci, radius * 1.4, game.elapsed)
		return
	var alpha := 1.0
	if phase == Phase.ARRIVING:
		alpha = clampf(phase_time / maxf(0.1, float(boss_def["arrive_time"])), 0.15, 1.0)
	elif phase == Phase.RISING:
		alpha = clampf(phase_time / maxf(0.1, float(boss_def["rise_time"])), 0.2, 1.0)
	var tint := Color(1.0, 1.0, 1.0, alpha)
	if phase == Phase.WAKING and interrupt_left > 0.0:
		tint = Color(0.75, 0.8, 0.95, 1.0)  # Interrupted: she pales.
	var horror := phase == Phase.ELDER
	if phase == Phase.CHANGING:
		var rate := 4.0 + 12.0 * phase_time / maxf(0.1, float(boss_def["change_time"]))  # Flickers faster as he changes.
		horror = int(phase_time * rate) % 2 == 1
	if horror:
		if SpriteBank.draw(ci, CarmillaData.SPRITE_ELDER, Vector2.ZERO, flash > 0.0, tint):
			return
		CastleSanguisGlyphs.draw_elder(ci, Vector2.ZERO, float(boss_def["elder_radius"]), flash > 0.0, tint.a)
		return
	if phase == Phase.RISING or phase == Phase.LORD or phase == Phase.CHANGING:
		if SpriteBank.draw(ci, CarmillaData.SPRITE_ELDER_LORD, Vector2.ZERO, flash > 0.0, tint):
			return
		CastleSanguisGlyphs.draw_elder_lord(ci, Vector2.ZERO, radius, flash > 0.0, tint.a)
		return
	if SpriteBank.draw(ci, CarmillaData.SPRITE_QUEEN, Vector2.ZERO, flash > 0.0, tint):
		return
	CastleSanguisGlyphs.draw_carmilla(ci, Vector2.ZERO, radius, flash > 0.0, tint.a)


## Overlay layer on `ci`: the drain beam (a texture thread), her feeding thread
## to the coffin during the Waking, ice. Visual only.
func _draw_over(ci: CanvasItem) -> void:
	if act == Act.BEAM:
		var xf := CourtGlyphs.unmirror_xf(self)
		var v := _beam_dir() * float(boss_def["beam_length"])
		var pulse := 0.6 + 0.4 * sin(game.elapsed * 18.0)
		CourtGlyphs.draw_thread(ci, Vector2.ZERO, v, float(boss_def["beam_width"]), Color(Palette.COURT_BLOOD, 0.55 * pulse), xf)
		CourtGlyphs.draw_thread(ci, Vector2.ZERO, v, 4.0, Color(Palette.COURT_BLOOD_LIGHT, 0.95), xf)
		ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	elif phase == Phase.WAKING and interrupt_left <= 0.0:
		var xf2 := CourtGlyphs.unmirror_xf(self)
		CourtGlyphs.draw_thread(ci, Vector2.ZERO, coffin_at - position, 4.0, Color(Palette.COURT_BLOOD_LIGHT, 0.6 + 0.3 * sin(game.elapsed * 10.0)), xf2)
		ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if frozen:
		PowerupGlyphs.draw_frozen(ci, Vector2.ZERO, radius)


## One-line autotest summary of the fight (phase times relative to her arrival).
static func summary_line(st: Dictionary) -> String:
	var t0 := float(st.get("carmilla_spawn_time", -1.0))
	var waking := "%.1fs" % (float(st["carmilla_waking_at"]) - t0) if st.has("carmilla_waking_at") else "-"
	var elder := "%.1fs" % (float(st["carmilla_elder_at"]) - t0) if st.has("carmilla_elder_at") else "-"
	var change := "%.1fs" % (float(st["carmilla_transform_at"]) - t0) if st.has("carmilla_transform_at") else "-"
	var kill := "%.1fs" % float(st["carmilla_kill_time"]) if st.has("carmilla_kill_time") else "-"
	return "phases: the waking %s, the elder %s, he transforms %s, he falls %s | court: mist dances %d, drain beams %d, nobles %d | waking: fed %d (bearers %d of %d sent poured %d HP), interrupts %d (stun %d, chains %d), elder rose with %d HP (%.0f%%) | lord: lunges %d (cuts on summons %d), mist steps %d | horror: bat commands %d (fliers %d), wing buffets %d | you hit %d, summon hits %d | dmg to you: mist %d, beam %d, lunge %d, touch %d, buffet %d, claws %d | dmg to summons: mist %d, beam %d, lunge %d, touch %d, buffet %d" % [
		waking, elder, change, kill, int(st.get("boss_atk_mist_dance", 0.0)), int(st.get("boss_atk_drain_beam", 0.0)), int(st.get("boss_atk_nobles", 0.0)),
		int(st.get("carmilla_fed", 0.0)), int(st.get("carmilla_bearers_poured", 0.0)), int(st.get("carmilla_bearers", 0.0)), int(st.get("carmilla_fed_bearers", 0.0)),
		int(st.get("carmilla_interrupts", 0.0)), int(st.get("carmilla_interrupts_stun", 0.0)), int(st.get("carmilla_interrupts_chains", 0.0)),
		int(st.get("carmilla_elder_hp", 0.0)), float(st.get("carmilla_elder_share", 0.0)) * 100.0,
		int(st.get("boss_atk_blood_lunge", 0.0)), int(st.get("carmilla_lord_hits", 0.0)), int(st.get("boss_atk_mist_step", 0.0)),
		int(st.get("boss_atk_bat_command", 0.0)), int(st.get("carmilla_commanded", 0.0)), int(st.get("boss_atk_wing_buffet", 0.0)),
		int(st.get("carmilla_player_hits", 0.0)), int(st.get("carmilla_summon_hits", 0.0)),
		int(st.get("player_dmg_from_" + CarmillaData.SRC_MIST, 0.0)), int(st.get("player_dmg_from_" + CarmillaData.SRC_BEAM, 0.0)),
		int(st.get("player_dmg_from_" + CarmillaData.SRC_LUNGE, 0.0)),
		int(st.get("player_dmg_from_" + CarmillaData.SRC_TOUCH, 0.0)), int(st.get("player_dmg_from_" + CarmillaData.SRC_BUFFET, 0.0)),
		int(st.get("player_dmg_from_boss", 0.0)),
		int(st.get("summon_dmg_from_" + CarmillaData.SRC_MIST, 0.0)), int(st.get("summon_dmg_from_" + CarmillaData.SRC_BEAM, 0.0)),
		int(st.get("summon_dmg_from_" + CarmillaData.SRC_LUNGE, 0.0)),
		int(st.get("summon_dmg_from_" + CarmillaData.SRC_TOUCH, 0.0)), int(st.get("summon_dmg_from_" + CarmillaData.SRC_BUFFET, 0.0))]
