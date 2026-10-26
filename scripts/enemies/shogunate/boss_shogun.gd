## BossShogun — SHOGUN KUROGANE, the boss of Castle Kurogane (Act V, Stage 14;
## GDD §15.0 "Castle Kurogane (Act V phase 2)" and "Shogun Kurogane: his army
## is his health bar"; owner-approved proposal docs/act5/PROPOSAL.md "Stage
## 14"). Loaded by name for the boss id "shogun" (EnemyDirector
## .SHOGUNATE_BOSS_DIR + "boss_shogun.gd"); he arrives at 17:00 (3:00 left).
## Extends Boss, so summons, spells and the spatial hash treat him like any
## enemy once he fights. Numbers in ShogunData (its header tells the fight):
##   * PLATFORM — he stands on his command platform (platform_distance px from
##       the necromancer, drawn under him; it stays where it stood),
##       UNTARGETABLE (Enemy.untargetable: out of the enemy grid; and
##       damage_taken_mult() is 0), signalling with his war fan (a flourish and
##       a taiko beat every fan_every s and with every regiment). His army
##       (ShogunRegiments, the one count) marches regiment by regiment; his HP
##       IS that count: max_hp = the soldiers of all six regiments, hp = the
##       soldiers he has left (the HUD's one boss bar reads hp / max_hp).
##   * DESCEND — at descend_share of the bar the march stops; he leaps down
##       (descend_time s, invulnerable) with his honour guard (guard_count
##       samurai, guard_elites of them elite).
##   * DUEL — the points left (at least duel_min_share of the bar) become his
##       own life: every hit on him is scaled by points / his duel HP (his
##       max_hp after the boss HP scaling), so the bar runs down from where the
##       army left it. He walks at the necromancer (shared melee AI, striding
##       faster beyond advance_range) and fights with IAI CUTS through
##       DrawCuts.draw() with the boss override (the one Draw path): a line
##       from him through the necromancer and cut_length px past him, its
##       flash cut_flash_slow s while his guard stands, down to cut_flash_fast
##       as it falls; with the cut he dashes cut_dash of the line. Below
##       triple_hp of his own life his last move is the TRIPLE CUT: three lines
##       at once crossing on the necromancer, every triple_every s.
## Killing him drops the boss XP burst and the boss chest; slaying him unlocks
## Banner of the Dead and Warlord's Seal (UnlockData, boss "shogun"); slain
## after all six banners broke (every regiment's Hatamoto killed), he counts
## for the achievement Regiments Broken (stat shogun_regiments_broken_kills;
## MetaProgress keeps the lifetime count). Attack pose (BossPoseData):
## bosses/shogun_duel in the duel while he stands to cut. Determinism: only
## the seeded gameplay RNG (his regiments' kinds). Stats: boss_atk_<special>,
## shogun_descend_at, shogun_points_at_descend, shogun_guard_called,
## shogun_cuts, shogun_triples, shogun_killed, shogun_regiments_broken_kills,
## and ShogunRegiments' shogun_*.
class_name BossShogun
extends Boss

## Fight phases.
enum Phase { PLATFORM, DESCEND, DUEL }

## Current fight phase.
var phase: Phase = Phase.PLATFORM
## Seconds spent in the current phase.
var phase_time: float = 0.0
## His army: the bar while he stands on the platform.
var regiments: ShogunRegiments = null
## World point of his command platform (where he stood; the deck).
var platform_pos: Vector2 = Vector2.ZERO
## His own life in the duel (his max_hp after the boss HP scaling).
var duel_hp: float = 1.0
## Bar points per point of his own damage in the duel (points / duel_hp).
var duel_scale: float = 0.0
## Bar points left when he came down (his duel bar's full length).
var duel_points: float = 0.0
## Seconds until the next war-fan signal.
var fan_cd: float = 0.0
## Game time (s) of the last war-fan signal (the flourish's drawing).
var fan_at: float = -10.0
## Seconds until his next iai cut.
var cut_cd: float = 0.0
## Seconds until his next triple cut.
var triple_cd: float = 0.0
## Where he leaps down to (the descent's end).
var _land: Vector2 = Vector2.ZERO
## His honour guard and their generations.
var _guard: Array[Enemy] = []
## Generation of each guard when called.
var _guard_gen: PackedInt32Array = PackedInt32Array()
## Guards called in all (the "faster as his guard falls" share).
var _guard_called: int = 0
## Walking speed of his duel (px/s).
var _base_speed: float = 56.0


## Sets up the Shogun with HP scaled by `hp_mult`: his platform on screen
## toward where he arrives, his army and its bar.
func setup_boss(p_game: Game, pos: Vector2, hp_mult: float, slot: int) -> void:
	boss_def = ShogunData.BOSS
	var p := p_game.player.position
	var to := pos - p
	var dir := to.normalized() if to.length() > 1.0 else Vector2.UP
	platform_pos = p_game.arena.free_point(p + dir * float(boss_def["platform_distance"]), float(boss_def["radius"]))
	activate(p_game, "boss", boss_def, platform_pos, hp_mult, false, slot)
	is_boss = true
	untargetable = true
	z_index = 1
	p_game.shogunate_rules()  # His iai cuts go through the Shogunate's one Draw path (created here when he is forced onto another stage).
	duel_hp = max_hp
	regiments = ShogunRegiments.new(self)
	max_hp = float(regiments.total())
	hp = max_hp
	phase = Phase.PLATFORM
	phase_time = 0.0
	fan_cd = 1.0
	cut_cd = 1.5
	triple_cd = 0.0
	_guard.clear()
	_guard_gen = PackedInt32Array()
	_guard_called = 0
	_base_speed = move_speed
	p_game.stats["shogun_bar_total"] = max_hp
	p_game.effects.impact(position, radius * 3.0, Palette.GOLD)
	p_game.shake(6.0)


## His abilities in report order (Boss hook).
func special_ids() -> Array:
	return ShogunData.SPECIALS


## True while he walks at the necromancer (Boss hook, stuck check): only in the
## duel, when no cut flashes.
func is_walking() -> bool:
	return phase == Phase.DUEL and not _drawing()


## Sprite key of his art (engine-motion pivot).
func motion_sprite_key() -> String:
	return "bosses/shogun"


## No damage on the platform or in the leap; in the duel each hit is scaled
## onto the bar (see the header).
func damage_taken_mult(source: String) -> float:
	if phase != Phase.DUEL:
		return 0.0
	return super.damage_taken_mult(source) * duel_scale


## Plays the Shogunate sound of `event` at `pos` (ShogunateRules.play_sound()).
func play_sound(event: String, pos: Vector2) -> void:
	if game.shogunate != null:
		game.shogunate.play_sound(event, pos)


## A war-fan signal: the flourish and a taiko beat (ShogunRegiments calls it as
## a regiment marches).
func signal_fan() -> void:
	fan_at = game.elapsed
	fan_cd = float(boss_def["fan_every"])
	game.stat_add("boss_atk_fan", 1.0)
	play_sound("taiko_hit", position)
	queue_redraw()


## His death: the stats, and Regiments Broken when every banner fell.
func deactivate() -> void:
	if active and hp <= 0.0:
		game.stat_add("shogun_killed", 1.0)
		if regiments != null and regiments.banners_broken >= regiments.regiments.size():
			game.stat_add("shogun_regiments_broken_kills", 1.0)
	super.deactivate()


# =====================================================================================
# The fight
# =====================================================================================

## Boss physics: his phase machine (see the header).
func physics_step(delta: float) -> void:
	phase_time += delta
	knockback = Vector2.ZERO
	match phase:
		Phase.PLATFORM:
			_tick_timers(delta)
			velocity = Vector2.ZERO
			position = platform_pos
			regiments.step(delta)
			hp = maxf(float(regiments.left()), 0.5)
			fan_cd -= delta
			if fan_cd <= 0.0:
				signal_fan()
			if hp <= max_hp * float(boss_def["descend_share"]):
				_start_descend()
		Phase.DESCEND:
			_tick_timers(delta)
			velocity = Vector2.ZERO
			regiments.step(delta)
			var k := clampf(phase_time / float(boss_def["descend_time"]), 0.0, 1.0)
			position = platform_pos.lerp(_land, k)
			if k >= 1.0:
				_start_duel()
		Phase.DUEL:
			_step_duel(delta)
	_face_sprite()


## The march stops; he leaps down from the platform toward the necromancer.
func _start_descend() -> void:
	regiments.stop()
	duel_points = maxf(hp, max_hp * float(boss_def["duel_min_share"]))
	hp = duel_points
	duel_scale = duel_points / maxf(duel_hp, 1.0)
	var to := game.player.position - platform_pos
	_land = game.arena.free_point(platform_pos + to.normalized() * minf(to.length() * 0.5, 120.0) if to.length() > 1.0 else platform_pos, radius)
	game.stat_add("shogun_descend_at", game.elapsed)
	game.stats["shogun_points_at_descend"] = float(regiments.left())
	game.enemies.show_banner("Shogun Kurogane draws his blade and comes down with his honour guard!")
	play_sound("draw_flash", position)
	game.shake(5.0)
	phase = Phase.DESCEND
	phase_time = 0.0
	queue_redraw()


## He lands: targetable, his honour guard around him, the duel begins.
func _start_duel() -> void:
	untargetable = false
	phase = Phase.DUEL
	phase_time = 0.0
	cut_cd = 1.2
	game.effects.impact(position, radius * 3.5, Palette.GOLD)
	game.shake(7.0)
	var n := int(boss_def["guard_count"])
	for i in n:
		if game.enemies.regular_alive() >= game.enemies.hard_cap():
			break
		var at := position + Vector2.from_angle(TAU * float(i) / float(n)) * float(boss_def["guard_ring"])
		var e := game.enemies.spawn_at(String(boss_def["guard_kind"]), at, i < int(boss_def["guard_elites"]))
		_guard.append(e)
		_guard_gen.append(e.generation)
		_guard_called += 1
	game.stat_add("shogun_guard_called", float(_guard_called))
	queue_redraw()


## The duel: stand while his cut flashes, else the triple cut, an iai cut, or
## the shared walk and melee.
func _step_duel(delta: float) -> void:
	cut_cd -= delta
	triple_cd -= delta
	if _drawing():
		_tick_timers(delta)
		velocity = Vector2.ZERO
		return
	var p := game.player.position
	var dist := position.distance_to(p)
	if hp <= duel_points * float(boss_def["triple_hp"]) and triple_cd <= 0.0:
		_triple_cut(p)
		return
	if cut_cd <= 0.0 and dist <= float(boss_def["cut_range"]):
		_iai_cut(p, dist)
		return
	move_speed = _base_speed * (float(boss_def["advance_speed_mult"]) if dist > float(boss_def["advance_range"]) else 1.0)
	super.physics_step(delta)


## True while one of his lines flashes.
func _drawing() -> bool:
	return game.shogunate != null and game.shogunate.draws.has_line(self)


## Flash time (s) of a cut now: slower while his guard stands, faster as it falls.
func _cut_flash() -> float:
	var fallen := 1.0 - float(_guard_alive()) / float(maxi(1, _guard_called))  # 0 whole guard .. 1 all fallen.
	return lerpf(float(boss_def["cut_flash_slow"]), float(boss_def["cut_flash_fast"]), fallen)


## One iai cut: a line from him through the necromancer and past him.
func _iai_cut(p: Vector2, dist: float) -> void:
	var dir := (p - position) / maxf(dist, 0.01)
	var opts := {"boss_override": true, "flash": _cut_flash(), "length": dist + float(boss_def["cut_length"]),
		"width": float(boss_def["cut_width"]), "dmg_player": float(boss_def["cut_dmg_player"]),
		"dmg_summon": float(boss_def["cut_dmg_summon"]), "dash": float(boss_def["cut_dash"]), "tag": "shogun_iai"}
	if game.shogunate_rules().draws.draw(self, position + dir * 8.0, dir, opts):
		cut_cd = float(boss_def["cut_every"])
		game.stat_add("shogun_cuts", 1.0)
		game.stat_add("boss_atk_iai", 1.0)
		motion_lunge(-dir, MotionData.POWER_CAST)
		queue_redraw()
	else:
		cut_cd = 0.4


## The triple cut: three lines at once crossing on the necromancer (a
## six-pointed star; he does not dash).
func _triple_cut(p: Vector2) -> void:
	triple_cd = float(boss_def["triple_every"])
	cut_cd = maxf(cut_cd, 1.2)
	var base := (p - position).angle()
	var length := float(boss_def["triple_length"])
	var drawn := 0
	for k in 3:
		var dir := Vector2.from_angle(base + PI / 3.0 * float(k))
		var opts := {"boss_override": true, "flash": float(boss_def["triple_flash"]), "length": length,
			"width": float(boss_def["cut_width"]), "dmg_player": float(boss_def["cut_dmg_player"]),
			"dmg_summon": float(boss_def["triple_dmg_summon"]), "dash": 0.0, "tag": "shogun_iai"}
		if game.shogunate_rules().draws.draw(self, p - dir * length * 0.5, dir, opts):
			drawn += 1
	if drawn > 0:
		game.stat_add("shogun_triples", 1.0)
		game.stat_add("boss_atk_triple", 1.0)
		motion_lunge(Vector2.ZERO, MotionData.POWER_CAST)
		queue_redraw()


## His honour guard still standing (stale entries dropped).
func _guard_alive() -> int:
	var i := 0
	while i < _guard.size():
		if _guard[i].active and _guard[i].generation == _guard_gen[i]:
			i += 1
		else:
			_guard.remove_at(i)
			_guard_gen.remove_at(i)
	return _guard.size()


## Mirrors his sprite toward the necromancer.
func _face_sprite() -> void:
	var dx := game.player.position.x - position.x
	if absf(dx) < 4.0:
		return
	var f := signf(dx)
	if f != _facing:
		_facing = f
		scale.x = _facing
		queue_redraw()


# =====================================================================================
# Drawing, summary
# =====================================================================================

## Ground layer: his command platform where it stands (in world axes; its deck
## under his feet while he is on it). Visual only.
func _draw_under() -> void:
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(scale.x, 1.0))  # World axes (his node is mirrored).
	var off := platform_pos - position  # The platform's deck from his feet (px).
	var tex := SpriteBank.texture("shogunate/command_platform")
	if tex != null:
		SpriteBank.apply_sharp(self)
		var size := Vector2(float(tex.get_width()), float(tex.get_height()))
		var top_left := (off + Vector2(-size.x * 0.5, ShogunData.PLATFORM_DECK_RISE - size.y)).round()
		draw_texture_rect(tex, Rect2(top_left, size), false)
	else:
		KuroganeGlyphs.draw_platform(self, off)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## Body layer: the duel pose while he stands to cut, else his still / walk
## strip (the war fan raised); the glyph without art.
func _draw_body(ci: CanvasItem) -> void:
	var pose := 3 if phase == Phase.DESCEND or (phase == Phase.DUEL and (_drawing() or phase_time < 1.0)) else 0
	if SpriteBank.draw_pose(ci, "bosses/shogun", pose, Vector2.ZERO, flash > 0.0):
		return
	KuroganeGlyphs.draw_shogun(ci, Vector2.ZERO, radius, flash > 0.0, phase != Phase.PLATFORM)


## Overlay layer: the war fan's gold flourish after a signal (on the platform).
func _draw_over(ci: CanvasItem) -> void:
	var since := game.elapsed - fan_at
	if phase == Phase.PLATFORM and since >= 0.0 and since < 0.6:
		var k := since / 0.6
		ci.draw_arc(Vector2(radius * 1.2, -radius * 4.6), 10.0 + 18.0 * k, 0.0, TAU, 20, Color(Palette.GOLD, 0.8 * (1.0 - k)), 2.0)
	if frozen:
		PowerupGlyphs.draw_frozen(ci, Vector2.ZERO, radius)


## Autopilot hint: his Draw lines are ShogunateRules.danger_push()'s; nothing more.
func danger_push(_p: Vector2) -> Vector2:
	return Vector2.ZERO


## One autotest summary line of his fight.
static func summary_line(game: Game, st: Dictionary) -> String:
	var b := game.enemies.boss as BossShogun
	var d := float(st.get("shogun_descend_at", -1.0))
	return "bar %d soldiers | regiments marched %d: %s | sent %d, killed %d (ambush %d), other kills off the bar %d, fled %d, reserve lost %d | banners broken %d/6 | came down %s (points left %d) | guard %d | iai cuts %d, triple cuts %d | killed %d (regiments broken %d) | dmg to player %d, summons %d" % [
		int(st.get("shogun_bar_total", 0.0)), int(st.get("shogun_regiments_marched", 0.0)), b.regiments.summary() if b != null and b.regiments != null else "-",
		int(st.get("shogun_soldiers_sent", 0.0)), int(st.get("shogun_member_kills", 0.0)), int(st.get("shogun_ambush_kills", 0.0)),
		int(st.get("shogun_trickle_points", 0.0)), int(st.get("shogun_fled", 0.0)), int(st.get("shogun_reserve_lost", 0.0)),
		int(st.get("shogun_banners_broken", 0.0)), ("at %s" % EmpireReport._clock(d)) if d >= 0.0 else "no", int(st.get("shogun_points_at_descend", 0.0)),
		int(st.get("shogun_guard_called", 0.0)), int(st.get("shogun_cuts", 0.0)), int(st.get("shogun_triples", 0.0)),
		int(st.get("shogun_killed", 0.0)), int(st.get("shogun_regiments_broken_kills", 0.0)),
		int(st.get("player_dmg_from_shogun_iai", 0.0) + st.get("player_dmg_from_boss", 0.0)),
		int(st.get("summon_dmg_from_shogun_iai", 0.0) + st.get("summon_dmg_from_boss", 0.0))]
