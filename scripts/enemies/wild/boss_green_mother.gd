## BossGreenMother — THE GREEN MOTHER, the boss of the World-Tree and the
## campaign's last boss (temporary Act XV, the Turning Year's finale; GDD §15.0
## "The Green Mother (Act XV phase 2)" and "The Last Claim"; owner-approved
## proposal: the Turning, the Burial, the Last Claim, and the ending). Loaded by
## name for the boss id "green_mother" (EnemyDirector.WILD_BOSS_DIR +
## "boss_green_mother.gd"); she arrives at 17:00 (3:00 left) and walks slowly
## at the nearest necromancer (enemies always advance), striking in reach.
## Extends Boss, so summons, spells and the spatial hash treat her like any
## enemy. Numbers in GreenMotherData (its header tells the fight):
##   * THE TURNING: every turn_every s she casts the next season through
##     SeasonCycle.set_override() (the one season path: the arena's roots,
##     fires, rot and snow follow) and that season's attack, telegraphed
##     circles bursting through WildKit.trample() with the season's effect
##     (spring roots: SummonedUnit.held_until / WildRules.slow_player(); summer
##     fire: more damage, Thickets.burn_at(); autumn rot: more damage on the
##     dead, a thicket seed through Thickets.plant(); winter frost:
##     CombatResolver.chill_unit() / WildRules.slow_player()).
##   * THE BURIAL (from burial_from of her HP): every burial_every s one seeded
##     summon near a necromancer is pulled into the earth: a burial thicket
##     (WorldTreeEnemyData "burial_thicket", BurialThicketKit) grows over it and
##     holds it until the ring cuts it down or burial_time s x Deadwood pass.
##   * THE LAST CLAIM (from a third of her HP, once): LastClaim (`claim`)
##     replays seven of the fourteen other acts' rules, 8 s each; while a slot
##     runs her Turning and Burial rest (her melee stays) and the claimed power
##     wards her (damage_taken_mult(): slot_ward).
## The Wild's rules exist wherever she fights (Game.wild_rules()). Beaten, she
## does not die (the ending text: she sinks into the roots and plants the dead);
## beaten before 0:00 she sets GreenMotherData.BEATEN_STAT, and at 0:00 the
## First Spring (WildRules.first_spring) ends the campaign. Slaying her unlocks
## Root and Rot with Compost Heart and the Ossuary Oak with Heartwood
## (UnlockData, boss "green_mother"). Determinism: the seeded gameplay RNG (the
## circles' spots, the buried summon, the Last Claim's pick), game time.
## Stats: boss_atk_<special>, mother_turns, mother_turn_<season>,
## mother_bursts, mother_burst_hits, mother_burst_on_you, mother_burials,
## mother_kill_time.
class_name BossGreenMother
extends Boss

## Seconds until the next season she casts.
var _turn_cd: float = 0.0
## Season she casts next (WildRulesData.SPRING..WINTER).
var _next_season: int = WildRulesData.SPRING
## Seconds until the next burial.
var _burial_cd: float = 0.0
## Circles waiting to burst: {at (Vector2), t (game s it bursts), season (int)} each.
var _bursts: Array[Dictionary] = []
## The burial thickets she grew (Enemy) and their generations.
var _buried: Array[Enemy] = []
## Generations of `_buried`, index for index.
var _buried_gens: Array[int] = []
## THE LAST CLAIM (null before her first tick).
var claim: LastClaim = null
## Game time (s) of her last cast (the cast pose shows for a moment).
var _cast_at: float = -INF
## Game time (s) of her last burial (the burial pose shows for a moment).
var _bury_at: float = -INF
## Her walking speed (px/s, before the advance stride).
var _base_speed: float = 30.0
## Game time (s) she arrived (kill time).
var _spawn_time: float = 0.0
## Reusable query buffer.
var _buf: Array = []


## Sets up the Green Mother at `pos` with HP scaled by `hp_mult`.
func setup_boss(p_game: Game, pos: Vector2, hp_mult: float, slot: int) -> void:
	boss_def = GreenMotherData.BOSS
	activate(p_game, "boss", boss_def, p_game.arena.free_point(pos, float(boss_def["radius"])), hp_mult, false, slot)
	is_boss = true
	z_index = 1
	_turn_cd = float(boss_def["turn_first"])
	_burial_cd = float(boss_def["burial_every"])
	_bursts.clear()
	_buried.clear()
	_buried_gens.clear()
	_base_speed = move_speed
	_spawn_time = p_game.elapsed
	claim = LastClaim.new(self)
	var w := p_game.wild_rules()  # Her seasons, thickets and burials are the Wild's (created on another stage too).
	_next_season = (w.seasons.season() + 1) % 4 if w.seasons.season() >= 0 and w.seasons.season() < 4 else WildRulesData.SPRING
	game.enemies.boss_defeated.connect(_on_defeated)
	game.enemies.show_banner(String(boss_def["arrive_banner"]))
	if GameState.autotest and not GameState.autotest_last_claim.is_empty():
		claim.begin()  # --last-claim=: the forced slots run from her arrival (the autotest's slot check).


## Her abilities in report order (Boss hook).
func special_ids() -> Array:
	return GreenMotherData.SPECIALS


## True while she walks at the necromancer (Boss hook, the stuck check).
func is_walking() -> bool:
	return true


## Sprite key of her art (engine-motion pivot).
func motion_sprite_key() -> String:
	return GreenMotherData.SPRITE


## THE LAST CLAIM's ward: while a slot runs she takes slot_ward of every hit.
func damage_taken_mult(source: String) -> float:
	var m := super.damage_taken_mult(source)
	if claim != null and claim.in_slot():
		m *= float(GreenMotherData.LAST_CLAIM["slot_ward"])
	return m


## Damage multiplier of her specials: the time scaling and her buffs.
func _scale() -> float:
	return game.enemies.damage_mult * hit_mult()


# =====================================================================================
# Physics
# =====================================================================================

## Boss physics: the Last Claim (from a third of her HP), else the Turning and
## the Burial; the bursts on their clocks; then her walk.
func physics_step(delta: float) -> void:
	knockback = Vector2.ZERO
	if not claim.started and hp <= max_hp * float(GreenMotherData.LAST_CLAIM["claim_from"]):
		claim.begin()
	claim.step()
	if not claim.in_slot():
		_turn_cd -= delta
		_step_turning()
		if hp <= max_hp * float(boss_def["burial_from"]):
			_burial_cd -= delta
			_step_burial()
	_step_bursts()
	var pl := game.nearest_player(position)
	move_speed = _base_speed * (float(boss_def["advance_speed_mult"]) if pl != null and position.distance_to(pl.position) > float(boss_def["advance_range"]) else 1.0)
	super.physics_step(delta)


# =====================================================================================
# The Turning
# =====================================================================================

## Casts the next season on her clock (see the header).
func _step_turning() -> void:
	if _turn_cd > 0.0:
		return
	var pl := game.nearest_player(position)
	if pl == null or pl.dead:
		return
	_turn_cd = float(boss_def["turn_every"])
	var s := _next_season
	_next_season = (s + 1) % 4
	game.wild_rules().seasons.set_override(s, game.elapsed + float(boss_def["turn_time"]))
	var lead := float(boss_def["turn_lead"])
	var r := float(boss_def["turn_radius"])
	for k in int(boss_def["turn_count"]):
		var at := pl.position if k == 0 else pl.position + Vector2.from_angle(randf() * TAU) * randf() * float(boss_def["turn_spread"])
		_bursts.append({"at": at, "t": game.elapsed + lead, "season": s})
		game.effects.telegraph_circle(at, r, lead, self)
	_cast_at = game.elapsed
	game.stat_add("boss_atk_turning", 1.0)
	game.stat_add("mother_turns", 1.0)
	game.stat_add("mother_turn_" + WildRulesData.SEASON_IDS[s], 1.0)
	game.enemies.show_banner(String((boss_def["turn_banners"] as Array)[s]))
	game.effects.ring(position, radius * 2.5, GreenMotherData.SEASON_COLORS[s], 0.5)
	queue_redraw()


## Bursts the circles whose time came.
func _step_bursts() -> void:
	var i := 0
	while i < _bursts.size():
		if game.elapsed >= float(_bursts[i]["t"]):
			_burst(_bursts[i])
			_bursts.remove_at(i)
		else:
			i += 1


## One season burst (see the header).
func _burst(b: Dictionary) -> void:
	var at: Vector2 = b["at"]
	var s := int(b["season"])
	var r := float(boss_def["turn_radius"])
	var sc := _scale()
	var dmg_s := float(boss_def["turn_damage_summon"]) * sc * undead_damage_mult
	var dmg_p := float(boss_def["turn_damage"]) * sc
	match s:
		WildRulesData.SUMMER:
			dmg_s *= float(boss_def["summer_mult"])
			dmg_p *= float(boss_def["summer_mult"])
		WildRulesData.AUTUMN:
			dmg_s *= float(boss_def["autumn_summon_mult"])
	var w := game.wild_rules()
	var hit: Array = []
	var n := WildKit.trample(game, at, r, hit, dmg_s, dmg_p, 0.0, 0.0, Vector2.RIGHT, GreenMotherData.TURNING_SOURCE, self, _buf)
	game.stat_add("mother_bursts", 1.0)
	game.stat_add("mother_burst_hits", float(n))
	for h in hit:
		if h is Necromancer:
			game.stat_add("mother_burst_on_you", 1.0)
			match s:
				WildRulesData.SPRING:
					w.slow_player(h as Necromancer, float(boss_def["spring_slow"]), float(boss_def["spring_hold"]))
				WildRulesData.WINTER:
					w.slow_player(h as Necromancer, float(boss_def["winter_slow"]), float(boss_def["winter_time"]))
		elif h is SummonedUnit:
			var u := h as SummonedUnit
			if not u.active:
				continue
			match s:
				WildRulesData.SPRING:
					u.held_until = maxf(u.held_until, game.elapsed + float(boss_def["spring_hold"]) * w.deadwood_mult())
				WildRulesData.WINTER:
					game.combat.chill_unit(u, float(boss_def["winter_slow"]), float(boss_def["winter_time"]), GreenMotherData.TURNING_SOURCE)
	match s:
		WildRulesData.SUMMER:
			w.thickets.burn_at(at, r)
		WildRulesData.AUTUMN:
			w.thickets.plant(at, float(boss_def["autumn_grow"]), "green_mother")
	game.effects.ring(at, r, GreenMotherData.SEASON_COLORS[s], 0.35)


# =====================================================================================
# The Burial
# =====================================================================================

## Buries one seeded summon on her clock (see the header).
func _step_burial() -> void:
	if _burial_cd > 0.0:
		return
	_burial_cd = float(boss_def["burial_every"])
	var standing := 0
	for i in range(_buried.size() - 1, -1, -1):
		if _buried[i].active and _buried[i].generation == _buried_gens[i]:
			standing += 1
		else:
			_buried.remove_at(i)
			_buried_gens.remove_at(i)
	if standing >= int(boss_def["burial_max"]):
		return
	var pool: Array[SummonedUnit] = []
	var reach := float(boss_def["burial_reach"])
	for hd in game.all_hordes:
		for u in hd.units:
			if not u.active or u.state == SummonedUnit.State.SPAWNING or u.state == SummonedUnit.State.DEAD or u.airborne or u.flies \
					or u.held_until > game.elapsed:
				continue
			var near := game.nearest_player(u.position)
			if near != null and near.position.distance_to(u.position) <= reach:
				pool.append(u)
	if pool.is_empty():
		return
	var v: SummonedUnit = pool[randi() % pool.size()]
	var t := game.enemies.spawn_at(GreenMotherData.BURIAL_KIND, v.position, false)
	if t == null or not (t.kit is BurialThicketKit):
		return
	(t.kit as BurialThicketKit).bind(v, game.elapsed + float(boss_def["burial_time"]) * game.wild_rules().deadwood_mult())
	_buried.append(t)
	_buried_gens.append(t.generation)
	_bury_at = game.elapsed
	game.stat_add("boss_atk_burial", 1.0)
	game.stat_add("mother_burials", 1.0)
	if standing == 0:
		game.enemies.show_banner(String(boss_def["burial_banner"]))
	game.wild_rules().play_sound("bury", v.position, 0.3)
	game.effects.ring(v.position, v.radius * 2.0, Palette.WILD_BARK, 0.4)
	queue_redraw()


# =====================================================================================
# Death, autopilot hint, drawing
# =====================================================================================

## Her defeat (EnemyDirector.boss_defeated, after the reward burst): the claim
## stops, her circles fade, and the ending text (she sinks into the roots; the
## First Spring waits for 0:00 when she fell before it).
func _on_defeated() -> void:
	var pos := position
	_bursts.clear()
	claim.stop()
	if not game.countdown_finished():
		game.stats[GreenMotherData.BEATEN_STAT] = 1.0
	game.effects.ring(pos, 260.0, GreenMotherData.BLOOM, 1.0)
	game.effects.ring(pos, 160.0, GreenMotherData.FROST, 0.8)
	Juice.fx.burst(pos, GreenMotherData.BLOOM, Palette.WILD_GOLD_LEAF, 28, 320.0, 1.0, 3.5)
	game.shake(14.0)
	Sfx.play("boss_impact", pos, 0.5)
	game.enemies.show_banner(String(game.enemies.boss_info.get("defeat_banner", "")))
	game.enemies.banner_until = game.elapsed + GreenMotherData.ENDING_BANNER_TIME
	if game.hud != null:
		var txt: Array = GreenMotherData.LATE_ANNOUNCE if game.countdown_finished() else GreenMotherData.ENDING_ANNOUNCE
		game.hud.announce(String(txt[0]), String(txt[1]), String(txt[2]), GreenMotherData.BLOOM)
	game.stats["mother_kill_time"] = game.elapsed - _spawn_time


## Danger hint for the autotest autopilot: out of every circle about to burst.
func danger_push(p: Vector2) -> Vector2:
	var push := Vector2.ZERO
	var r := float(boss_def["turn_radius"]) + 24.0
	for b: Dictionary in _bursts:
		var rel := p - (b["at"] as Vector2)
		if rel.length() < r:
			push += (rel.normalized() if rel.length() > 1.0 else Vector2.UP) * 1.5
	return push


## Her code shape at body radius `r`: a trunk-gown half in bloom, half in
## frost, a crown of branches (disc textures and rects).
static func _draw_shape(ci: CanvasItem, r: float, f: bool) -> void:
	SpriteBank.draw_disc(ci, Vector2.ZERO, r, Glyphs._c(Palette.WILD_INK, f))
	SpriteBank.draw_disc(ci, Vector2(-r * 0.3, 0.0), r * 0.75, Glyphs._c(GreenMotherData.BLOOM, f))  # The bloom half.
	SpriteBank.draw_disc(ci, Vector2(r * 0.3, 0.0), r * 0.75, Glyphs._c(GreenMotherData.FROST, f))  # The frost half.
	ci.draw_rect(Rect2(Vector2(-r * 0.15, -r * 0.6), Vector2(r * 0.3, r * 1.4)), Glyphs._c(Palette.WILD_BARK, f))  # Her trunk.
	SpriteBank.draw_disc(ci, Vector2(0.0, -r * 0.95), r * 0.38, Glyphs._c(Palette.WILD_INK, f))
	SpriteBank.draw_disc(ci, Vector2(0.0, -r * 0.95), r * 0.3, Glyphs._c(Color(0.86, 0.78, 0.62), f))  # Her face.
	for k in 5:
		var a := -PI * 0.5 + (float(k) - 2.0) * 0.4
		ci.draw_rect(Rect2(Vector2(cos(a), sin(a)) * r * 1.2 - Vector2(1.5, 1.5), Vector2(3.0, r * 0.4)), Glyphs._c(Palette.WILD_BARK, f))  # A branch of her crown.


## Body layer on `ci`: her still frame (pose 1 just after a cast, pose 2 just
## after a burial); a code shape without the art.
func _draw_body(ci: CanvasItem) -> void:
	var f := flash > 0.0
	var pose := 0
	if game.elapsed - _bury_at < 0.8:
		pose = 2
	elif game.elapsed - _cast_at < 0.8:
		pose = 1
	if not SpriteBank.draw_pose(ci, GreenMotherData.SPRITE, pose, Vector2.ZERO, f):
		_draw_shape(ci, radius, f)


## One autotest summary line of her fight (the Last Claim has its own line).
static func summary_line(st: Dictionary) -> String:
	var kt := float(st.get("mother_kill_time", -1.0))
	var seasons := PackedStringArray()
	for id in ["spring", "summer", "autumn", "winter"]:
		seasons.append("%s %d" % [id, int(st.get("mother_turn_" + id, 0.0))])
	return "the Turning: %d (%s; bursts %d, hit %d, you %d) | the Burial: %d (freed %d, withered %d) | killed %s | dmg to you %d, to summons %d" % [
		int(st.get("mother_turns", 0.0)), ", ".join(seasons), int(st.get("mother_bursts", 0.0)), int(st.get("mother_burst_hits", 0.0)),
		int(st.get("mother_burst_on_you", 0.0)), int(st.get("mother_burials", 0.0)), int(st.get("burial_freed", 0.0)), int(st.get("burial_withered", 0.0)),
		("%.0f s after she arrived" % kt) if kt >= 0.0 else "no",
		int(st.get("player_dmg_from_" + GreenMotherData.TURNING_SOURCE, 0.0)) + int(st.get("player_dmg_from_boss", 0.0)),
		int(st.get("summon_dmg_from_" + GreenMotherData.TURNING_SOURCE, 0.0)) + int(st.get("summon_dmg_from_boss", 0.0))]
