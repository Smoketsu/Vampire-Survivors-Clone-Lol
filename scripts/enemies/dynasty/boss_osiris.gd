## BossOsiris — OSIRIS, LORD OF THE DEAD, AND AMMIT THE DEVOURER, the boss of the
## Hall of Two Truths and the finale of the Necropolis Dynasty (temporary Act
## XII; GDD §15.0 "Osiris and Ammit (the Hall of Two Truths)"; the phases and
## every number are OsirisData's). Loaded by name for the boss id "osiris"
## (EnemyDirector.DYNASTY_BOSS_DIR + "boss_osiris.gd"); he arrives at 17:00
## (3:00 left). ONE body and ONE health bar for the pair: Osiris (male, seated on
## his throne) judges and weighs, then gives the throne to Ammit (a monster) for
## the last share. Extends Boss, so summons, spells and the spatial hash treat
## it like any enemy. Every attack goes through the act's one paths: the glyphs
## through Heka.write(), "Rebirth at speed" through Rebirth.set_duration_bonus(),
## the Weighing through the stage's TruthScales (TwoTruthsDirector), Ammit's
## feasts and lanes through Rebirth.eat(); summons are struck through
## CombatResolver.damage_unit() and eaten through HordeDirector.on_unit_died().
## The shared rules are created on first use (Game.dynasty_rules()), so
## --boss=osiris works on any stage (there the Weighing has no Scales and ends
## level). Killing it drops a big XP burst and the boss chest; slaying it
## unlocks Feather's Verdict and Heavy Heart, the Ushabti Sentinel and Answering
## Words (UnlockData, boss "osiris"); a Weighing won toward the necromancer
## counts A Light Heart (MetaData, OsirisData.LIGHT_HEART_STAT).
## Determinism: no RNG (the strongest summons, fixed turns); game time only.
## Stats: boss_atk_<special>, osiris_weighing_at, osiris_weighing_result,
## osiris_devoured, osiris_shield_broken, osiris_devourer_at, osiris_kill_time,
## osiris_glyphs, osiris_court, osiris_judgment_hits, ammit_charge_hits,
## ammit_eaten, light_heart_wins.
class_name BossOsiris
extends Boss

## Its phases.
enum Phase { ARRIVING, JUDGE, WEIGHING, DEVOURER }
## Ammit's charge states.
enum Charge { NONE, WARN, RUN }

## Current phase.
var phase: Phase = Phase.ARRIVING
## Seconds in the current phase.
var phase_time: float = 0.0
## Seconds until his next glyphs.
var glyph_cd: float = 0.0
## Seconds until his next court.
var court_cd: float = 0.0
## Courts called so far (picks the next OsirisData.COURT group, in turn).
var courts: int = 0
## Seconds until his next Judgment.
var judgment_cd: float = 0.0
## Judgments telegraphed and waiting to strike: [at (Vector2), game time it strikes].
var judgments: Array = []
## The side the Weighing ended on (+1 the Dynasty, -1 the necromancer, 0 level; 9 = not yet).
var weighing_result: int = 9
## Seconds until Ammit's next feast.
var feast_cd: float = 0.0
## Seconds until Ammit's next charge.
var charge_cd: float = 0.0
## Ammit's charge state.
var charge: Charge = Charge.NONE
## The charge lane's start and end (world px).
var _lane_from: Vector2 = Vector2.ZERO
## The charge lane's end.
var _lane_to: Vector2 = Vector2.ZERO
## Seconds into the current charge state.
var _charge_t: float = 0.0
## Bodies struck by the current charge (Node -> true).
var _struck: Dictionary = {}
## Its walking speed (px/s) of the current phase.
var _base_speed: float = 30.0
## Game time (s) it arrived (kill time).
var _spawn_time: float = 0.0
## Ally query buffer.
var _q: Array = []


## Sets up Osiris at `pos` with HP scaled by `hp_mult`.
func setup_boss(p_game: Game, pos: Vector2, hp_mult: float, slot: int) -> void:
	boss_def = OsirisData.BOSS
	activate(p_game, "boss", boss_def, p_game.arena.free_point(pos, float(boss_def["radius"])), hp_mult, false, slot)
	is_boss = true
	z_index = 1
	phase = Phase.ARRIVING
	phase_time = 0.0
	glyph_cd = float(boss_def["glyph_first"])
	court_cd = float(boss_def["court_first"])
	courts = 0
	judgment_cd = float(boss_def["judgment_first"])
	judgments.clear()
	weighing_result = 9
	feast_cd = 0.0
	charge_cd = INF
	charge = Charge.NONE
	_struck.clear()
	_base_speed = move_speed
	_spawn_time = p_game.elapsed
	var dy := game.dynasty_rules()  # The shared rules exist wherever he judges.
	dy.rebirth.set_duration_bonus("osiris", float(boss_def["rebirth_bonus"]))
	dy.heka.set_jump_speed(float(boss_def["heka_jump_speed"]))
	dy.play_sound("osiris_rise", position)
	game.enemies.boss_defeated.connect(_on_defeated)


## Its abilities in report order (Boss hook).
func special_ids() -> Array:
	return OsirisData.SPECIALS


## True while it walks at the necromancer (Boss hook, the stuck check).
func is_walking() -> bool:
	return (phase == Phase.JUDGE) or (phase == Phase.DEVOURER and charge == Charge.NONE)


## True while the necromancer's heart is weighed.
func is_weighing() -> bool:
	return phase == Phase.WEIGHING


## True once Ammit holds the throne.
func is_devourer() -> bool:
	return phase == Phase.DEVOURER


## Ammit's art in the Devourer, else Osiris's (the motion pivot).
func motion_sprite_key() -> String:
	return OsirisData.AMMIT_SPRITE if phase == Phase.DEVOURER else OsirisData.SPRITE


## Its fall (or any removal) gives Rebirth and Heka their own speeds back.
func deactivate() -> void:
	_release_rules()
	super.deactivate()


## Rebirth's and Heka's speeds back to the rule's.
func _release_rules() -> void:
	if game != null and game.dynasty != null:
		game.dynasty.rebirth.set_duration_bonus("osiris", 0.0)
		game.dynasty.heka.set_jump_speed(1.0)


## Immune while he rises and while the heart is weighed; his health never
## falls past the Weighing's threshold before the Weighing begins.
func damage_taken_mult(source: String) -> float:
	match phase:
		Phase.ARRIVING, Phase.WEIGHING:
			return 0.0
		Phase.JUDGE:
			if hp <= max_hp * float(boss_def["weighing_hp"]) + 1.0:
				return 0.0
	return super.damage_taken_mult(source)


# =====================================================================================
# Physics
# =====================================================================================

func physics_step(delta: float) -> void:
	phase_time += delta
	knockback = Vector2.ZERO
	_step_judgments()
	match phase:
		Phase.ARRIVING:
			_tick_timers(delta)
			velocity = Vector2.ZERO
			if phase_time >= float(boss_def["arrive_time"]):
				_enter(Phase.JUDGE)
				game.enemies.show_banner("THE JUDGE: Osiris writes his glyphs on your dead, and their Names return faster")
		Phase.JUDGE:
			_step_judge(delta)
			if hp <= max_hp * float(boss_def["weighing_hp"]) + 1.0:
				_begin_weighing()
		Phase.WEIGHING:
			_step_weighing(delta)
		Phase.DEVOURER:
			_step_devourer(delta)


## Starts phase `p`.
func _enter(p: Phase) -> void:
	phase = p
	phase_time = 0.0
	queue_redraw()


## Walks at the necromancer (the shared walk and touch; faster from afar).
func _walk(delta: float) -> void:
	var dist := position.distance_to(game.player.position)  # To the necromancer (px).
	var spd := _base_speed
	if dist > float(boss_def["advance_range"]):
		spd *= float(boss_def["advance_speed_mult"])
		game.stat_add("boss_advance_time", delta)
	move_speed = spd
	super.physics_step(delta)


# =====================================================================================
# The Judge
# =====================================================================================

## The Judge: he glides at the necromancer; glyphs, court and Judgments.
func _step_judge(delta: float) -> void:
	_walk(delta)
	_step_court_and_glyphs(delta, float(boss_def["court_every"]))
	judgment_cd -= delta
	if judgment_cd <= 0.0 and not game.ultimates.player_untargetable():
		judgment_cd = float(boss_def["judgment_every"])
		_judgment()


## The glyphs and the court on their clocks (`court_every` s between courts).
func _step_court_and_glyphs(delta: float, court_every: float) -> void:
	glyph_cd -= delta
	court_cd -= delta
	if glyph_cd <= 0.0:
		glyph_cd = float(boss_def["glyph_every"])
		_write_glyphs()
	if court_cd <= 0.0:
		court_cd = court_every
		_call_court()


## Heka glyphs at speed: glyph_count summons near him, the nearest first
## (Heka.write(), THE one call; he is the glyphs' priest).
func _write_glyphs() -> void:
	var heka := game.dynasty_rules().heka
	var reach := float(boss_def["glyph_range"])
	game.ally_grid.query(position, reach + UnitData.MAX_BLOCK_RADIUS, _q)
	var taken: Array[SummonedUnit] = []
	for _k in int(boss_def["glyph_count"]):
		var best: SummonedUnit = null
		var best_d := reach
		for u: SummonedUnit in _q:
			if taken.has(u) or not Heka.can_take(game, u):
				continue
			var dd := u.position.distance_to(position)
			if dd <= best_d:
				best_d = dd
				best = u
		if best == null:
			break
		taken.append(best)
		if heka.write(self, best):
			game.stat_add("osiris_glyphs", 1.0)
	game.stat_add("boss_atk_judge_glyphs", 1.0)
	motion_lunge(Vector2.UP, MotionData.POWER_CAST)


## His court comes round him (OsirisData.COURT, in turn).
func _call_court() -> void:
	var grp: Array = OsirisData.COURT[courts % OsirisData.COURT.size()]
	courts += 1
	var n := 0
	for g: Dictionary in grp:
		for _k in int(g["count"]):
			if game.enemies.regular_alive() >= game.enemies.hard_cap():
				break
			var at := position + Vector2.from_angle(TAU * float(n) / 9.0 + float(courts) * 0.7) * (radius + 46.0 + float(n % 3) * 18.0)
			if game.enemies.spawn_at(String(g["kind"]), game.arena.free_point(at, 12.0), bool(g["elite"])) != null:
				n += 1
	game.stat_add("boss_atk_judge_court", 1.0)
	game.stat_add("osiris_court", float(n))
	game.effects.ring(position, radius + 60.0, Palette.DYN_BRONZE, 0.5)
	game.dynasty_rules().play_sound("osiris_court", position, 1.0)


## A Judgment circle under the necromancer (it strikes after judgment_warn s).
func _judgment() -> void:
	var at := game.player.position
	var warn := float(boss_def["judgment_warn"])
	judgments.append([at, game.elapsed + warn])
	game.effects.telegraph_circle(at, float(boss_def["judgment_radius"]), warn, self)
	game.stat_add("boss_atk_judgment", 1.0)


## Strikes every Judgment whose time has come (any phase but the Devourer
## still lands what Osiris called).
func _step_judgments() -> void:
	var i := judgments.size() - 1
	while i >= 0:
		var j: Array = judgments[i]
		if game.elapsed >= float(j[1]):
			_strike_judgment(j[0])
			judgments.remove_at(i)
		i -= 1


## The Judgment at `at`: every summon in it and the necromancer are struck.
func _strike_judgment(at: Vector2) -> void:
	var r := float(boss_def["judgment_radius"])
	var ts := game.enemies.damage_mult * hit_mult()
	var hits := 0
	game.ally_grid.query(at, r + UnitData.MAX_BLOCK_RADIUS, _q)
	for u: SummonedUnit in _q:
		if u.active and u.state != SummonedUnit.State.SPAWNING and u.position.distance_to(at) <= r + u.radius:
			game.combat.damage_unit(u, float(boss_def["judgment_summon_damage"]) * ts, OsirisData.SRC_JUDGMENT, self)
			hits += 1
	for pl in game.all_players:
		if not pl.dead and pl.position.distance_to(at) <= r + pl.radius:
			game.combat.damage_player(float(boss_def["judgment_damage"]) * ts, OsirisData.SRC_JUDGMENT, pl, self)
			hits += 1
	game.stat_add("osiris_judgment_hits", float(hits))
	game.effects.impact(at, r, Palette.DYN_BRONZE_LIGHT)
	game.dynasty_rules().play_sound("osiris_judgment", at, 0.3)


# =====================================================================================
# The Weighing
# =====================================================================================

## The Weighing: the heart goes on the Scales for weighing_time s; he sits
## immune on his throne.
func _begin_weighing() -> void:
	_enter(Phase.WEIGHING)
	velocity = Vector2.ZERO
	game.stat_add("boss_atk_weighing", 1.0)
	game.stats["osiris_weighing_at"] = game.elapsed
	var tt := game.enemies.two_truths
	if tt != null:
		tt.scales.begin_weighing()
		tt.weigh_left = float(boss_def["weighing_time"])
	game.enemies.show_banner("THE WEIGHING: your heart lies on the Scales! Raise the dead to tip them your way")
	game.effects.ring(position, 140.0, Palette.DYN_BRONZE_LIGHT, 0.8)
	game.shake(4.0)
	game.dynasty_rules().play_sound("osiris_weighing", position)


## The Weighing: his court and his glyphs go on; the Scales decide at the end.
func _step_weighing(delta: float) -> void:
	_tick_timers(delta)
	velocity = Vector2.ZERO
	_step_court_and_glyphs(delta, float(boss_def["weighing_court_every"]))
	judgment_cd -= delta
	if judgment_cd <= 0.0 and not game.ultimates.player_untargetable():
		judgment_cd = float(boss_def["judgment_every"])
		_judgment()
	var left := float(boss_def["weighing_time"]) - phase_time
	var tt := game.enemies.two_truths
	if tt != null:
		tt.weigh_left = maxf(0.0, left)
	if left <= 0.0:
		_end_weighing()


## The Scales' verdict, then the Devourer.
func _end_weighing() -> void:
	var tt := game.enemies.two_truths
	weighing_result = 0
	if tt != null:
		weighing_result = tt.scales.end_weighing()
		tt.weigh_left = -1.0
	game.stats["osiris_weighing_result"] = float(weighing_result)
	match weighing_result:
		1:
			_devour_summons()
		-1:
			_break_shield()
		_:
			game.enemies.show_banner("The Scales hang level: neither heart is found wanting")
	_begin_devourer()


## Toward the Dynasty: Ammit eats devour_share of every army (the strongest
## first; each a real death, so its class queue replaces it).
func _devour_summons() -> void:
	var eaten := 0
	for h: HordeDirector in game.all_hordes:
		var pool: Array[SummonedUnit] = []
		for u in h.units:
			if u.active and u.state != SummonedUnit.State.SPAWNING and u.state != SummonedUnit.State.DEAD:
				pool.append(u)
		var n := int(roundf(float(pool.size()) * float(boss_def["devour_share"])))
		for _k in n:
			var best: SummonedUnit = null
			for u in pool:
				if best == null or u.hp > best.hp:
					best = u
			if best == null:
				break
			pool.erase(best)
			game.effects.pop(best.position, Palette.DYN_CARNELIAN, 14.0)
			h.on_unit_died(best)
			eaten += 1
	game.stat_add("osiris_devoured", float(eaten))
	game.enemies.show_banner("Your heart is heavy: Ammit devours %d of your dead!" % eaten)
	game.shake(6.0)
	game.dynasty_rules().play_sound("ammit_feast", game.player.position)


## Toward the necromancer: his shield breaks (shield_break of his max HP).
func _break_shield() -> void:
	var lost := minf(max_hp * float(boss_def["shield_break"]), hp - 1.0)
	hp -= maxf(0.0, lost)
	game.stats["osiris_shield_broken"] = lost
	game.stat_add(OsirisData.LIGHT_HEART_STAT, 1.0)  # A Light Heart (MetaData; MetaProgress counts it).
	game.enemies.show_banner("Your heart is light as the feather: Osiris's shield breaks!")
	game.effects.ring(position, 180.0, Palette.NECRO_GREEN, 0.8)
	game.effects.impact(position, radius * 4.0, Palette.DYN_LINEN_LIGHT)
	game.shake(6.0)
	queue_redraw()


# =====================================================================================
# The Devourer
# =====================================================================================

## Osiris gives the throne to Ammit: the body becomes hers; he watches.
func _begin_devourer() -> void:
	_enter(Phase.DEVOURER)
	_release_rules()
	game.stats["osiris_devourer_at"] = game.elapsed
	var tt := game.enemies.two_truths
	if tt != null:
		tt.set_throne(position)
	radius = float(boss_def["ammit_radius"])
	_base_speed = float(boss_def["ammit_speed"])
	damage = float(boss_def["ammit_damage"])
	position += (game.player.position - position).normalized() * 30.0  # She steps down from the throne.
	feast_cd = 0.0
	charge_cd = float(boss_def["charge_first"])
	charge = Charge.NONE
	judgments.clear()
	game.enemies.show_banner("THE DEVOURER: Osiris gives his throne to Ammit! She eats every Name on the field")
	game.effects.impact(position, radius * 4.0, Palette.DYN_CARNELIAN)
	game.shake(8.0)
	game.dynasty_rules().play_sound("ammit_roar", position)


## The Devourer: feasts on every corpse, charges in lanes, bites between.
func _step_devourer(delta: float) -> void:
	feast_cd -= delta
	if feast_cd <= 0.0:
		feast_cd = float(boss_def["feast_every"])
		_feast()
	game.stat_add("ammit_time_" + String(Charge.keys()[charge]).to_lower(), delta)  # Seconds in each charge state (the report).
	match charge:
		Charge.NONE:
			_walk(delta)
			charge_cd -= delta
			if charge_cd <= 0.0 and not game.ultimates.player_untargetable():
				_open_lane()
		Charge.WARN:
			_tick_timers(delta)
			velocity = Vector2.ZERO
			_charge_t += delta
			if _charge_t >= float(boss_def["charge_warn"]):
				charge = Charge.RUN
				_charge_t = 0.0
				_struck.clear()
		Charge.RUN:
			_tick_timers(delta)
			_run(delta)


## Eats every cartouche on the map (Rebirth.eat(): no Name returns).
func _feast() -> void:
	var rb := game.dynasty_rules().rebirth
	var n := 0
	var i := rb.cartouches.size() - 1
	while i >= 0:
		var c := rb.cartouches[i]
		if c.active:
			game.effects.pop(c.position, Palette.DYN_CARNELIAN, 10.0)
			rb.eat(c)
			n += 1
		i -= 1
	if n > 0:
		game.stat_add("boss_atk_ammit_feast", 1.0)
		game.stat_add("ammit_eaten", float(n))
		game.dynasty_rules().play_sound("ammit_feast", position, 1.0)


## A charge lane from her through the necromancer, telegraphed.
func _open_lane() -> void:
	var dir := (game.player.position - position)
	dir = dir.normalized() if dir.length() > 1.0 else Vector2.RIGHT
	_lane_from = position
	_lane_to = position + dir * float(boss_def["charge_length"])
	charge = Charge.WARN
	_charge_t = 0.0
	game.effects.telegraph_line(_lane_from, _lane_to, float(boss_def["charge_width"]), float(boss_def["charge_warn"]), self)
	game.stat_add("boss_atk_ammit_charge", 1.0)
	game.dynasty_rules().play_sound("devourer_lane", position, 0.5)


## Runs along the lane: whatever she passes is struck once, Names eaten; an
## obstacle or the lane's end stops her.
func _run(delta: float) -> void:
	var dir := (_lane_to - _lane_from).normalized()
	var left := position.distance_to(_lane_to)
	var step := minf(float(boss_def["charge_speed"]) * delta, left)
	var free := game.arena.clear_length(position, dir, step, radius * 0.6)
	position += dir * free
	velocity = dir * float(boss_def["charge_speed"])
	_update_facing()
	_strike_along()
	if free < step - 0.5 or left - free <= 1.0:
		if free < step - 0.5:
			game.stat_add("ammit_charge_blocked", 1.0)
		charge = Charge.NONE
		charge_cd = float(boss_def["charge_every"])
		velocity = Vector2.ZERO


## Strikes every summon and necromancer within half the lane of her, once.
func _strike_along() -> void:
	var half := float(boss_def["charge_width"]) * 0.5
	var ts := game.enemies.damage_mult * hit_mult()
	game.ally_grid.query(position, half + radius + UnitData.MAX_BLOCK_RADIUS, _q)
	for u: SummonedUnit in _q:
		if not u.active or u.state == SummonedUnit.State.SPAWNING or _struck.has(u):
			continue
		if u.position.distance_to(position) <= half + u.radius:
			_struck[u] = true
			game.combat.damage_unit(u, float(boss_def["charge_summon_damage"]) * ts, OsirisData.SRC_CHARGE, self)
			game.stat_add("ammit_charge_hits", 1.0)
	for pl in game.all_players:
		if pl.dead or _struck.has(pl):
			continue
		if pl.position.distance_to(position) <= half + pl.radius:
			_struck[pl] = true
			game.combat.damage_player(float(boss_def["charge_damage"]) * ts, OsirisData.SRC_CHARGE, pl, self)
			game.stat_add("ammit_charge_hits", 1.0)
	var rb := game.dynasty_rules().rebirth
	var i := rb.cartouches.size() - 1
	while i >= 0:
		var c := rb.cartouches[i]
		if c.active and c.position.distance_to(position) <= half + c.radius:
			rb.eat(c)
			game.stat_add("ammit_eaten", 1.0)
		i -= 1


## The autotest autopilot's push out of a waiting Judgment and Ammit's lane.
func danger_push(p: Vector2) -> Vector2:
	var push := Vector2.ZERO
	var jr := float(boss_def["judgment_radius"]) + 16.0
	for j in judgments:
		var off: Vector2 = p - j[0]
		var dd := off.length()
		if dd < jr:
			push += (off / dd if dd > 0.01 else Vector2.RIGHT) * (1.0 - dd / jr)
	if charge != Charge.NONE:
		var half := float(boss_def["charge_width"]) * 0.5 + 20.0
		var q := Geometry2D.get_closest_point_to_segment(p, position if charge == Charge.RUN else _lane_from, _lane_to)
		var off := p - q
		var dd := off.length()
		if dd < half:
			push += (off / dd if dd > 0.01 else (_lane_to - _lane_from).normalized().orthogonal()) * (1.0 - dd / half)
	return push


# =====================================================================================
# Death, drawing, report
# =====================================================================================

## Its defeat (EnemyDirector.boss_defeated, after the reward burst): the
## ending text (no old master has a claim on the dead), the throne empties.
func _on_defeated() -> void:
	var pos := position
	_release_rules()
	game.effects.ring(pos, 240.0, Palette.DYN_LINEN_LIGHT, 1.0)
	game.effects.ring(pos, 140.0, Palette.DYN_BRONZE_LIGHT, 0.8)
	Juice.fx.burst(pos, Palette.DYN_BRONZE_LIGHT, Palette.DYN_LINEN, 24, 300.0, 1.0, 3.5)
	game.shake(12.0)
	Sfx.play("boss_impact", pos, 0.6)
	var tt := game.enemies.two_truths
	if tt != null:
		tt.clear_throne()
	var late := game.countdown_finished()  # She fell during the Devourer's Hour.
	game.enemies.show_banner(String(OsirisData.ARRIVAL["defeat_banner"]))
	game.enemies.banner_until = game.elapsed + OsirisData.ENDING_BANNER_TIME
	if game.hud != null:
		var txt: Array = OsirisData.LATE_ANNOUNCE if late else OsirisData.ENDING_ANNOUNCE
		game.hud.announce(String(txt[0]), String(txt[1]), String(txt[2]), Palette.DYN_LINEN_LIGHT)
	game.stats[OsirisData.KILL_TIME_STAT] = game.elapsed - _spawn_time


## Body layer on `ci`: Osiris on his throne (rising as he arrives), or Ammit.
func _draw_body(ci: CanvasItem) -> void:
	if phase == Phase.DEVOURER:
		if not SpriteBank.draw(ci, OsirisData.AMMIT_SPRITE, Vector2.ZERO, flash > 0.0):
			TwoTruthsGlyphs.draw_ammit(ci, radius, flash > 0.0)
		return
	var a := 1.0
	if phase == Phase.ARRIVING:
		a = clampf(phase_time / maxf(float(boss_def["arrive_time"]), 0.01), 0.15, 1.0)
	var tint := Color(1.0, 1.0, 1.0, a)
	if phase == Phase.WEIGHING:
		tint = Color(0.85, 0.95, 1.1, a)  # Pale while he weighs (immune).
	if not SpriteBank.draw(ci, OsirisData.SPRITE, Vector2.ZERO, flash > 0.0, tint):
		TwoTruthsGlyphs.draw_osiris(ci, radius, flash > 0.0, a)


## Overlay layer on `ci`: the frozen look.
func _draw_over(ci: CanvasItem) -> void:
	if frozen:
		PowerupGlyphs.draw_frozen(ci, Vector2.ZERO, radius)


## Under layer: its shadow; during the Weighing the great Scales beside his
## throne with the necromancer's heart on one pan, tipped by the balance.
func _draw_under() -> void:
	super._draw_under()
	if phase == Phase.WEIGHING and game != null:
		var xf := CourtGlyphs.unmirror_xf(self)
		draw_set_transform_matrix(xf)
		var tt := game.enemies.two_truths
		var tilt := tt.scales.share() if tt != null else 0.0
		TwoTruthsGlyphs.draw_weighing(self, Vector2(radius + 44.0, 6.0), tilt, game.elapsed)
		draw_set_transform_matrix(Transform2D.IDENTITY)


## One autotest summary line of its fight.
static func summary_line(st: Dictionary) -> String:
	var weigh := float(st.get("osiris_weighing_at", -1.0))
	var dev := float(st.get("osiris_devourer_at", -1.0))
	var res := int(st.get("osiris_weighing_result", 9.0))
	var verdict := "not reached"
	match res:
		1:
			verdict = "toward the Dynasty (Ammit ate %d summons)" % int(st.get("osiris_devoured", 0.0))
		-1:
			verdict = "toward you (shield broke for %d HP; a light heart)" % int(st.get("osiris_shield_broken", 0.0))
		0:
			verdict = "level"
	return "judge: glyphs %d (written %d), courts %d (bodies %d), judgments %d (hits %d) | weighing %s: %s | devourer %s (feasts %d, names eaten %d, charges %d, charge hits %d) | killed in %ds | dmg to you %d (judgment %d, charge %d, touch %d), to summons %d" % [
		int(st.get("boss_atk_judge_glyphs", 0.0)), int(st.get("osiris_glyphs", 0.0)),
		int(st.get("boss_atk_judge_court", 0.0)), int(st.get("osiris_court", 0.0)),
		int(st.get("boss_atk_judgment", 0.0)), int(st.get("osiris_judgment_hits", 0.0)),
		EmpireReport._clock(weigh) if weigh >= 0.0 else "not reached", verdict,
		EmpireReport._clock(dev) if dev >= 0.0 else "not reached",
		int(st.get("boss_atk_ammit_feast", 0.0)), int(st.get("ammit_eaten", 0.0)),
		int(st.get("boss_atk_ammit_charge", 0.0)), int(st.get("ammit_charge_hits", 0.0)),
		int(st.get(OsirisData.KILL_TIME_STAT, 0.0)),
		int(st.get("player_dmg_from_" + OsirisData.SRC_JUDGMENT, 0.0)) + int(st.get("player_dmg_from_" + OsirisData.SRC_CHARGE, 0.0)) + int(st.get("player_dmg_from_boss", 0.0)),
		int(st.get("player_dmg_from_" + OsirisData.SRC_JUDGMENT, 0.0)), int(st.get("player_dmg_from_" + OsirisData.SRC_CHARGE, 0.0)),
		int(st.get("player_dmg_from_boss", 0.0)),
		int(st.get("summon_dmg_from_" + OsirisData.SRC_JUDGMENT, 0.0)) + int(st.get("summon_dmg_from_" + OsirisData.SRC_CHARGE, 0.0)) + int(st.get("summon_dmg_from_boss", 0.0))]
