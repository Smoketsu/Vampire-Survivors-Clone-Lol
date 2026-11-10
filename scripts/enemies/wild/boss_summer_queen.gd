## BossSummerQueen — THE SUMMER QUEEN OF THE FAE, the boss of the Fae Court
## (temporary Act XV, the Turning Year; GDD §15.0 "The Summer Queen (Act XV phase
## 2)"; owner-approved proposal: the Masque, the Bargain, the Court in Bloom).
## Loaded by name for the boss id "summer_queen" (EnemyDirector.WILD_BOSS_DIR +
## "boss_summer_queen.gd"); she arrives at 17:00 (3:00 left, in her own endless
## summer) and glides at the nearest necromancer (enemies always advance),
## striking in reach. Extends Boss, so summons, spells and the spatial hash
## treat her like any enemy. Numbers in SummerQueenData.BOSS (its header tells
## the fight):
##   * PETALS: fans of petal bolts (the plain hostile shot).
##   * THE MASQUE: she hides among masked courtiers (FaeCourtEnemyData
##     "masked_courtier", MaskedCourtierKit) on a ring round the necromancer,
##     every face hers; a hit unmasks a courtier, a hit on her unmasks them all.
##   * THE BARGAIN: at set shares of her HP a real choice on screen (two
##     buttons on the shared ConfirmDialog): accept a boon at a price
##     (WildRules.take_bargain(), the one bargain path: army damage, no army
##     healing, a life cost) or refuse and she strikes harder (her scorn). Solo:
##     the run pauses as for a level-up (Game.RunState.LEVEL_UP); online co-op:
##     the answer is a lockstep command (CoopLockstep.Cmd.BARGAIN ->
##     answer_bargain()), the first answer counts and none within offer_time s
##     refuses; the one-process --coop-bot and the autotest answer at once
##     (the naive bot refuses, every other bot accepts).
##   * THE COURT IN BLOOM: telegraphed blossoms round the necromancer burst
##     into thorns (WildKit.trample(), the one Wild trample, without a stun or
##     a throw) and leave thicket seeds (Thickets.plant()), faster as she falls.
## The Wild's rules exist wherever she fights (Game.wild_rules()). When she
## falls the short ending text (no epilogue part). Slaying her unlocks Glamour
## with Changeling (UnlockData, boss "summer_queen"). Determinism: the seeded
## gameplay RNG (her place in the Masque, the ring's turn, the blossoms'
## spots), the courtiers through the seeded spawn path.
## Stats: boss_atk_<special>, queen_petal_bolts, masque_faces, masque_found,
## bargains_offered, bargains_accepted, bargains_refused, queen_bloom_blossoms,
## queen_bloom_hits, queen_bloom_on_you, queen_bloom_seeds, queen_kill_time.
class_name BossSummerQueen
extends Boss

## Seconds until the next petal fan.
var _petal_cd: float = 0.0
## Seconds until the next Masque.
var _masque_cd: float = 0.0
## Seconds until the next sowing of the Court in Bloom.
var _bloom_cd: float = 0.0
## True while she wears her mask among her court.
var _masked: bool = false
## Game time (s) the current Masque ends at the latest.
var _masque_until: float = 0.0
## The current Masque's courtiers (Enemy) and their generations.
var _faces: Array[Enemy] = []
## Generations of `_faces`, index for index.
var _face_gens: Array[int] = []
## Bargains offered so far (index into bargain_at and SummerQueenData.BARGAINS).
var _bargains: int = 0
## The bargain waiting for an answer (index into BARGAINS; -1 = none).
var _offer: int = -1
## Game time (s) an online co-op offer is refused unanswered.
var _offer_until: float = 0.0
## The open bargain dialog (null when none shows on this machine).
var _dialog: ConfirmDialog = null
## Bargains refused (each makes her specials stronger and quicker).
var _scorn: int = 0
## Blossoms waiting to burst: {at (Vector2), t (game s it bursts), seed (bool)} each.
var _blossoms: Array[Dictionary] = []
## Blossoms sown so far (every bloom_seed_every-th leaves a seed).
var _sown: int = 0
## Her gliding speed (px/s, before the advance stride).
var _base_speed: float = 46.0
## Game time (s) she arrived (kill time).
var _spawn_time: float = 0.0
## Reusable query buffer.
var _buf: Array = []


## Sets up the Summer Queen at `pos` with HP scaled by `hp_mult`.
func setup_boss(p_game: Game, pos: Vector2, hp_mult: float, slot: int) -> void:
	boss_def = SummerQueenData.BOSS
	activate(p_game, "boss", boss_def, p_game.arena.free_point(pos, float(boss_def["radius"])), hp_mult, false, slot)
	is_boss = true
	z_index = 1
	_petal_cd = float(boss_def["petal_first"])
	_masque_cd = float(boss_def["masque_first"])
	_bloom_cd = float(boss_def["bloom_first"])
	_masked = false
	_faces.clear()
	_face_gens.clear()
	_bargains = 0
	_offer = -1
	_scorn = 0
	_blossoms.clear()
	_sown = 0
	_base_speed = move_speed
	_spawn_time = p_game.elapsed
	p_game.wild_rules()  # Her thickets are Overgrowth's and her bargains WildRules' (created on another stage too).
	game.enemies.boss_defeated.connect(_on_defeated)
	game.enemies.show_banner(String(boss_def["arrive_banner"]))


## Her abilities in report order (Boss hook).
func special_ids() -> Array:
	return SummerQueenData.SPECIALS


## True while she glides at the necromancer (Boss hook, the stuck check).
func is_walking() -> bool:
	return true


## Sprite key of her art (engine-motion pivot).
func motion_sprite_key() -> String:
	return SummerQueenData.SPRITE


## THE MASQUE: a hit on her finds her (every face drops its mask).
func damage_taken_mult(source: String) -> float:
	if _masked:
		_reveal(true)
	return super.damage_taken_mult(source)


## Damage multiplier of her specials: the time scaling, her buffs, her scorn.
func _scale() -> float:
	return game.enemies.damage_mult * hit_mult() * (1.0 + float(boss_def["scorn_damage"]) * float(_scorn))


## Multiplier on her specials' waits (her scorn makes them sooner; at most half off).
func _haste() -> float:
	return 1.0 - minf(0.5, float(boss_def["scorn_haste"]) * float(_scorn))


# =====================================================================================
# Physics
# =====================================================================================

## Boss physics: the Bargain's thresholds, the Masque, the Court in Bloom and
## her petals, then her glide.
func physics_step(delta: float) -> void:
	knockback = Vector2.ZERO
	_petal_cd -= delta
	_masque_cd -= delta
	_bloom_cd -= delta
	_step_bargain()
	_step_masque()
	_step_bloom()
	_step_petals()
	var pl := game.nearest_player(position)
	move_speed = _base_speed * (float(boss_def["advance_speed_mult"]) if pl != null and position.distance_to(pl.position) > float(boss_def["advance_range"]) else 1.0)
	super.physics_step(delta)


# =====================================================================================
# Petals
# =====================================================================================

## A fan of petal bolts at the nearest necromancer (one bolt while masked, as
## her courtiers throw: the fan would give her away).
func _step_petals() -> void:
	if _petal_cd > 0.0:
		return
	var pl := game.nearest_player(position)
	if pl == null or pl.dead or position.distance_to(pl.position) > float(boss_def["petal_range"]):
		_petal_cd = 0.5
		return
	_petal_cd = float(boss_def["petal_every"]) * _haste()
	var to := pl.position - position
	var aim := to.normalized() if to.length() > 1.0 else Vector2.RIGHT
	var n := 1 if _masked else maxi(1, int(boss_def["petal_bolts"]))
	var spread := deg_to_rad(float(boss_def["petal_spread"]))
	var dmg := float(boss_def["petal_damage"]) * _scale()
	for i in n:
		var a := 0.0 if n == 1 else spread * (float(i) / float(n - 1) - 0.5)
		game.projectiles.fire_hostile(position, aim.rotated(a), dmg, float(boss_def["petal_speed"]), undead_damage_mult,
				Projectile.Kind.RADIANT_BOLT, SummerQueenData.PETAL_SOURCE)
	game.stat_add("boss_atk_petals", 1.0)
	game.stat_add("queen_petal_bolts", float(n))


# =====================================================================================
# The Masque
# =====================================================================================

## Starts a Masque on its clock; ends it when its time is up.
func _step_masque() -> void:
	if _masked:
		if game.elapsed >= _masque_until:
			_reveal(false)
		return
	if _masque_cd > 0.0:
		return
	var pl := game.nearest_player(position)
	if pl == null or pl.dead:
		return
	_masque_cd = float(boss_def["masque_every"]) * _haste()
	var n := int(boss_def["masque_faces"]) + 1  # Places on the ring: her court and her.
	var mine := randi() % n  # Her place (seeded).
	var a0 := randf() * TAU  # The ring's turn (seeded).
	var ring := float(boss_def["masque_ring"])
	_faces.clear()
	_face_gens.clear()
	game.effects.ring(position, radius * 2.5, SummerQueenData.PETAL, 0.5)
	for k in n:
		var p := game.arena.free_point(pl.position + Vector2.from_angle(a0 + TAU * float(k) / float(n)) * ring, radius)
		if k == mine:
			position = p
			continue
		var f := game.enemies.spawn_at(FaeCourtEnemyData.MASKED_COURTIER, p, false)
		if f != null:
			_faces.append(f)
			_face_gens.append(f.generation)
			game.stat_add("masque_faces", 1.0)
		game.effects.ring(p, 30.0, SummerQueenData.PETAL, 0.4)
	_masked = true
	_masque_until = game.elapsed + float(boss_def["masque_time"])
	game.stat_add("boss_atk_masque", 1.0)
	game.enemies.show_banner(String(boss_def["masque_banner"]))
	queue_redraw()


## Ends the Masque: she and every face still masked drop their masks.
## `found`: a hit on her ended it (else its time ran out).
func _reveal(found: bool) -> void:
	_masked = false
	for i in _faces.size():
		var f := _faces[i]
		if f.active and f.generation == _face_gens[i] and f.kit is MaskedCourtierKit:
			(f.kit as MaskedCourtierKit).unmask(f)
	_faces.clear()
	_face_gens.clear()
	if found:
		game.stat_add("masque_found", 1.0)
		game.enemies.show_banner(String(boss_def["reveal_banner"]))
		game.effects.ring(position, radius * 2.0, SummerQueenData.PETAL, 0.4)
	queue_redraw()


# =====================================================================================
# The Bargain
# =====================================================================================

## Offers the next bargain at its HP share; refuses an online offer left
## unanswered too long.
func _step_bargain() -> void:
	if _offer >= 0:
		if game.coop != null and game.elapsed >= _offer_until:
			answer_bargain(false)
		return
	var at: Array = boss_def["bargain_at"]
	if _bargains < at.size() and _bargains < SummerQueenData.BARGAINS.size() and hp <= max_hp * float(at[_bargains]):
		_open_offer(_bargains)
		_bargains += 1


## True while a bargain waits for its answer.
func offer_open() -> bool:
	return _offer >= 0


## Offers bargain `i` (see the header for who answers it and how).
func _open_offer(i: int) -> void:
	_offer = i
	_offer_until = game.elapsed + float(boss_def["offer_time"])
	game.stat_add("bargains_offered", 1.0)
	game.stat_add("boss_atk_bargain", 1.0)
	game.enemies.show_banner(String(boss_def["bargain_banner"]))
	queue_redraw()
	var bot := _bot_accepts()
	if game.coop == null:
		if GameState.autotest:
			answer_bargain(bot)
			return
		game.run_state = Game.RunState.LEVEL_UP  # The level-up pause: nothing else opens over it.
		get_tree().paused = true
		_ask()
		return
	if game.coop.lockstep == null:
		answer_bargain(bot)  # The one-process --coop-bot: both slots are bots.
		return
	if GameState.autotest:
		game.coop.lockstep.command(CoopLockstep.Cmd.BARGAIN, 1 if bot else 2)
	else:
		_ask()


## The autotest's answer: every bot accepts but the naive one.
func _bot_accepts() -> bool:
	var pol := GameState.autotest_policy
	if game.coop != null and game.coop.slots[0].bot != null:
		pol = game.coop.slots[0].bot.policy()
	return pol != "naive"


## Shows the offer on this machine: the shared confirm dialog, Refuse focused.
func _ask() -> void:
	var row: Dictionary = SummerQueenData.BARGAINS[_offer]
	var host := game.level_up_panel.get_parent() as Control  # The run's UI root.
	_dialog = ConfirmDialog.ask(host, String(row["title"]), String(row["text"]), SummerQueenData.ACCEPT_WORD, Callable(), false, SummerQueenData.REFUSE_WORD)
	_dialog.closed.connect(_on_dialog_closed)


## The local player answered the dialog (Esc / pad B refuse).
func _on_dialog_closed(confirmed: bool) -> void:
	_dialog = null
	if _offer < 0:
		return
	if game.coop == null:
		game.run_state = Game.RunState.PLAYING
		get_tree().paused = false
		answer_bargain(confirmed)
	elif game.coop.lockstep != null:
		game.coop.lockstep.command(CoopLockstep.Cmd.BARGAIN, 1 if confirmed else 2)


## THE answer to the waiting bargain (the dialog in solo, the lockstep command
## in co-op, the bots): accept takes the boon and pays the price, refuse
## scorns her. A no-op when no bargain waits (a late second answer).
func answer_bargain(accept: bool) -> void:
	if _offer < 0:
		return
	var row: Dictionary = SummerQueenData.BARGAINS[_offer]
	_offer = -1
	if _dialog != null and is_instance_valid(_dialog):
		var d := _dialog
		_dialog = null
		d.closed.disconnect(_on_dialog_closed)
		d.cancel()
	if accept:
		game.stat_add("bargains_accepted", 1.0)
		game.wild_rules().take_bargain(float(row["damage"]), float(row["time"]), bool(row["no_heal"]))
		var cost := float(row["life_cost"])
		if cost > 0.0:
			for pl in game.all_players:
				if not pl.dead:
					game.combat.damage_player(pl.hp * cost, SummerQueenData.BARGAIN_SOURCE, pl, self)
		game.effects.ring(position, 120.0, SummerQueenData.PETAL, 0.6)
		game.enemies.show_banner(String(boss_def["accept_banner"]))
	else:
		_scorn += 1
		game.stat_add("bargains_refused", 1.0)
		game.effects.ring(position, 120.0, Palette.WILD_BLOSSOM, 0.6)
		game.enemies.show_banner(String(boss_def["refuse_banner"]))
	queue_redraw()


# =====================================================================================
# The Court in Bloom
# =====================================================================================

## Sows blossoms on her clock (faster as she falls); bursts those whose time came.
func _step_bloom() -> void:
	var i := 0
	while i < _blossoms.size():
		if game.elapsed >= float(_blossoms[i]["t"]):
			_burst(_blossoms[i])
			_blossoms.remove_at(i)
		else:
			i += 1
	if _bloom_cd > 0.0:
		return
	var pl := game.nearest_player(position)
	if pl == null or pl.dead:
		return
	var share := clampf(hp / maxf(1.0, max_hp), 0.0, 1.0)
	_bloom_cd = lerpf(float(boss_def["bloom_min_every"]), float(boss_def["bloom_every"]), share) * _haste()
	var lead := float(boss_def["bloom_lead"])
	var r := float(boss_def["bloom_radius"])
	for k in int(boss_def["bloom_count"]):
		var at := pl.position if k == 0 else pl.position + Vector2.from_angle(randf() * TAU) * randf() * float(boss_def["bloom_spread"])
		_sown += 1
		_blossoms.append({"at": at, "t": game.elapsed + lead, "seed": _sown % maxi(1, int(boss_def["bloom_seed_every"])) == 0})
		game.effects.telegraph_circle(at, r, lead, self)
		game.stat_add("queen_bloom_blossoms", 1.0)
	game.stat_add("boss_atk_bloom", 1.0)


## A blossom bursts into thorns (see the header).
func _burst(b: Dictionary) -> void:
	var at: Vector2 = b["at"]
	var r := float(boss_def["bloom_radius"])
	var s := _scale()
	var hit: Array = []
	var n := WildKit.trample(game, at, r, hit, float(boss_def["bloom_damage_summon"]) * s * undead_damage_mult,
			float(boss_def["bloom_damage"]) * s, 0.0, 0.0, Vector2.RIGHT, SummerQueenData.BLOOM_SOURCE, self, _buf)
	if n > 0:
		game.stat_add("queen_bloom_hits", float(n))
		for h in hit:
			if h is Necromancer:
				game.stat_add("queen_bloom_on_you", 1.0)
	if bool(b["seed"]):
		game.wild_rules().thickets.plant(at, float(boss_def["bloom_grow"]), "summer_queen")
		game.stat_add("queen_bloom_seeds", 1.0)
	game.effects.ring(at, r, SummerQueenData.PETAL, 0.35)


# =====================================================================================
# Death, autopilot hint, drawing
# =====================================================================================

## Her defeat (EnemyDirector.boss_defeated, after the reward burst): the short
## ending text (no epilogue); her blossoms wilt, her court drops its masks, an
## unanswered offer lapses.
func _on_defeated() -> void:
	var pos := position
	_blossoms.clear()
	if _masked:
		_reveal(false)
	if _offer >= 0:
		_offer = -1
		if _dialog != null and is_instance_valid(_dialog):
			var d := _dialog
			_dialog = null
			d.closed.disconnect(_on_dialog_closed)
			d.cancel()
	game.effects.ring(pos, 240.0, SummerQueenData.PETAL, 1.0)
	game.effects.ring(pos, 140.0, Palette.WILD_GOLD_LEAF, 0.8)
	Juice.fx.burst(pos, SummerQueenData.PETAL, Palette.WILD_MOSS, 26, 320.0, 1.0, 3.5)
	game.shake(12.0)
	Sfx.play("boss_impact", pos, 0.6)
	game.enemies.show_banner(String(game.enemies.boss_info.get("defeat_banner", "")))
	game.enemies.banner_until = game.elapsed + SummerQueenData.ENDING_BANNER_TIME
	if game.hud != null:
		var txt: Array = SummerQueenData.LATE_ANNOUNCE if game.countdown_finished() else SummerQueenData.ENDING_ANNOUNCE
		game.hud.announce(String(txt[0]), String(txt[1]), String(txt[2]), SummerQueenData.PETAL)
	game.stats["queen_kill_time"] = game.elapsed - _spawn_time


## Danger hint for the autotest autopilot: out of every blossom about to burst.
func danger_push(p: Vector2) -> Vector2:
	var push := Vector2.ZERO
	var r := float(boss_def["bloom_radius"]) + 24.0
	for b: Dictionary in _blossoms:
		var rel := p - (b["at"] as Vector2)
		if rel.length() < r:
			push += (rel.normalized() if rel.length() > 1.0 else Vector2.UP) * 1.5
	return push


## The masked face she and her court wear (her `_mask` art, else a code shape
## of her gown, wings and a white mask). Shared with MaskedCourtierKit, so the
## faces are alike whatever their own size.
static func draw_masked(ci: CanvasItem, f: bool) -> void:
	if SpriteBank.draw(ci, SummerQueenData.MASK_SPRITE, Vector2.ZERO, f):
		return
	_draw_shape(ci, float(SummerQueenData.BOSS["radius"]), f)
	SpriteBank.draw_disc(ci, Vector2(0.0, -float(SummerQueenData.BOSS["radius"]) * 0.95), 6.0, Glyphs._c(Palette.WILD_BONE, f))  # The mask.


## Her code shape at body radius `r`: wings, a gown of roses, a crown of blossoms.
static func _draw_shape(ci: CanvasItem, r: float, f: bool) -> void:
	for s: float in [-1.0, 1.0]:
		SpriteBank.draw_disc(ci, Vector2(s * r * 0.9, -r * 0.5), r * 0.6, Glyphs._c(Color(SummerQueenData.PETAL, 0.55), f))  # A butterfly wing.
	SpriteBank.draw_disc(ci, Vector2.ZERO, r, Glyphs._c(Palette.WILD_INK, f))
	SpriteBank.draw_disc(ci, Vector2.ZERO, r - 2.0, Glyphs._c(Palette.WILD_BLOSSOM, f))  # The gown of roses.
	SpriteBank.draw_disc(ci, Vector2(0.0, -r * 0.95), r * 0.4, Glyphs._c(Palette.WILD_INK, f))
	SpriteBank.draw_disc(ci, Vector2(0.0, -r * 0.95), r * 0.32, Glyphs._c(Color(0.95, 0.85, 0.80), f))  # Her face.
	ci.draw_rect(Rect2(Vector2(-r * 0.4, -r * 1.4), Vector2(r * 0.8, 3.0)), Glyphs._c(Palette.WILD_GOLD_LEAF, f))  # The crown of blossoms.


## Body layer on `ci`: masked, the court's face; else her still / glide frame
## (pose 1, the bargain held out, while an offer waits); a code shape without the art.
func _draw_body(ci: CanvasItem) -> void:
	var f := flash > 0.0
	if _masked:
		draw_masked(ci, f)
		return
	if not SpriteBank.draw_pose(ci, SummerQueenData.SPRITE, 1 if _offer >= 0 else 0, Vector2.ZERO, f):
		_draw_shape(ci, radius, f)


## One autotest summary line of her fight.
static func summary_line(st: Dictionary) -> String:
	var kt := float(st.get("queen_kill_time", -1.0))
	return "petals: %d fans (%d bolts) | the Masque: %d (faces %d, unmasked %d, found %d, courtier bolts %d) | the Bargain: offered %d, accepted %d, refused %d | the Court in Bloom: %d (blossoms %d, hit %d, you %d, seeds %d) | killed %s | dmg to you %d, to summons %d" % [
		int(st.get("boss_atk_petals", 0.0)), int(st.get("queen_petal_bolts", 0.0)),
		int(st.get("boss_atk_masque", 0.0)), int(st.get("masque_faces", 0.0)), int(st.get("masque_unmasked", 0.0)), int(st.get("masque_found", 0.0)),
		int(st.get("masque_bolts", 0.0)),
		int(st.get("bargains_offered", 0.0)), int(st.get("bargains_accepted", 0.0)), int(st.get("bargains_refused", 0.0)),
		int(st.get("boss_atk_bloom", 0.0)), int(st.get("queen_bloom_blossoms", 0.0)), int(st.get("queen_bloom_hits", 0.0)),
		int(st.get("queen_bloom_on_you", 0.0)), int(st.get("queen_bloom_seeds", 0.0)),
		("%.0f s after she arrived" % kt) if kt >= 0.0 else "no",
		int(st.get("player_dmg_from_" + SummerQueenData.PETAL_SOURCE, 0.0)) + int(st.get("player_dmg_from_" + SummerQueenData.BLOOM_SOURCE, 0.0)) + int(st.get("player_dmg_from_boss", 0.0)),
		int(st.get("summon_dmg_from_" + SummerQueenData.PETAL_SOURCE, 0.0)) + int(st.get("summon_dmg_from_" + SummerQueenData.BLOOM_SOURCE, 0.0)) + int(st.get("summon_dmg_from_boss", 0.0))]
