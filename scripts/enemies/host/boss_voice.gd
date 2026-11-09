## BossVoice — THE VOICE, the boss of the Empyrean and the Celestial Host's
## finale (temporary Act XIII; GDD §15.0 "The Voice (Act XIII phase 2)";
## owner-approved proposal: the Holy, Be Not Afraid, the Last Word). Loaded by
## name for the boss id "voice" (EnemyDirector.HOST_BOSS_DIR + "boss_voice.gd");
## it arrives at 17:00 (3:00 left). Extends Boss, so summons, spells and the
## spatial hash treat it like any enemy (no halo: Grace is a HostKit's).
## Numbers in VoiceData.BOSS.
##   * IT NEVER MOVES: it comes down arrive_distance px from the nearest
##     necromancer (on a free point) and holds that spot every tick (no walk,
##     no knockback); the army goes to it.
##   * THE HOLY: while it stands the Light's max_live is raised by holy_live;
##     every holy_every s (holy_every_p2 once the Last Word began) it opens
##     holy_shafts shafts round each standing necromancer, evenly turned,
##     sweeping across him (HallowedLight.add_shaft(), the Light's one path).
##   * BE NOT AFRAID: every unveil_every s, its face wings lower for
##     unveil_windup s, then the screen whitens (ParagonSky: one additive rect,
##     no screen read, never headless) and every summon in the open stops
##     unveil_stun s (CombatResolver.stun_unit()); a summon in shade
##     (HallowedLight.shaded()) or with a barrier is spared.
##   * THE LAST WORD (once, below last_word_hp): the run's sins (Judgment.raised
##     + replaced) x judges_per_sin Judges (clamped to last_word_min ..
##     last_word_cap) return in waves of wave_size every wave_every s
##     (Judgment.send_wave()), until they are all sent or it falls.
## The rules exist wherever it fights (Game.host_rules()); off a Host stage
## the Holy's shafts still burn. When it falls, a short ending text (no
## epilogue part). Slaying it unlocks Revelation, Seventh Seal, the Bound Ophan
## and Turning Bones (UnlockData, boss "voice").
## Determinism: no RNG of its own (the Holy's turn follows game time; the
## Judges' angles are Judgment's seeded ones). Stats: boss_atk_<special>,
## voice_holy_shafts, voice_holy_refused, voice_unveil_stopped,
## voice_unveil_spared_shade, voice_unveil_spared_barrier, voice_judges_owed,
## voice_judges_sent, voice_waves, voice_last_word_at, voice_kill_time.
class_name BossVoice
extends Boss

## Its two looks: the face hidden, or the face wings lowered.
enum Act { VEILED, UNVEILING }

## Current action.
var act: Act = Act.VEILED
## Seconds spent in the current action.
var act_time: float = 0.0
## The one spot it holds (world px).
var home: Vector2 = Vector2.ZERO
## Game time (s) of the next Holy cast.
var _next_holy: float = INF
## Game time (s) the next unveiling begins.
var _next_unveil: float = INF
## True once the Last Word began.
var last_word: bool = false
## Judges per necromancer still owed by the Last Word.
var _owed: int = 0
## Game time (s) of the next wave of Judges.
var _next_wave: float = INF
## Light slots added for the Holy now.
var _holy_slots: int = 0
## Game time (s) it arrived (kill time).
var _spawn_time: float = 0.0
## The current whitening (null when none; freed by itself).
var _white: ParagonSky = null


## Sets up the Voice near the necromancer, HP scaled by `hp_mult`.
func setup_boss(p_game: Game, pos: Vector2, hp_mult: float, slot: int) -> void:
	boss_def = VoiceData.BOSS
	var pl := p_game.nearest_player(pos)
	var dir := (pos - pl.position).normalized() if pos.distance_to(pl.position) > 1.0 else Vector2.UP
	var at := p_game.arena.free_point(pl.position + dir * float(boss_def["arrive_distance"]), float(boss_def["radius"]))
	activate(p_game, "boss", boss_def, at, hp_mult, false, slot)
	is_boss = true
	z_index = 1
	home = position
	act = Act.VEILED
	act_time = 0.0
	last_word = false
	_owed = 0
	_next_wave = INF
	_spawn_time = p_game.elapsed
	_next_holy = p_game.elapsed + float(boss_def["holy_first"])
	_next_unveil = p_game.elapsed + float(boss_def["unveil_first"])
	var light := p_game.host_rules().light  # Its Holy goes through the Light (created on another stage too).
	_holy_slots = int(boss_def["holy_live"])
	light.max_live += _holy_slots
	game.enemies.boss_defeated.connect(_on_defeated)
	game.enemies.show_banner(String(boss_def["phase1_banner"]))


## Its abilities in report order (Boss hook).
func special_ids() -> Array:
	return VoiceData.SPECIALS


## It never walks (Boss hook, the stuck check).
func is_walking() -> bool:
	return false


## Sprite key of its art (engine-motion pivot).
func motion_sprite_key() -> String:
	return VoiceData.SPRITE


## Any removal ends the Holy's extra Light slots (the pool reuses the node).
func deactivate() -> void:
	_end_holy()
	super.deactivate()


## The autotest bot's goal while it stands: the Voice itself (the army must
## go to it); INF once the bot is close enough.
func approach_point(p: Vector2) -> Vector2:
	return home if p.distance_to(home) > VoiceData.APPROACH else Vector2.INF


# =====================================================================================
# Physics
# =====================================================================================

## Boss physics: it holds its spot; the Holy, Be Not Afraid and the Last Word
## run on their clocks.
func physics_step(delta: float) -> void:
	position = home
	velocity = Vector2.ZERO
	knockback = Vector2.ZERO
	act_time += delta
	_tick_timers(delta)
	var now := game.elapsed
	if not last_word and hp <= max_hp * float(boss_def["last_word_hp"]):
		_begin_last_word()
	if now >= _next_holy:
		_next_holy = now + float(boss_def["holy_every_p2" if last_word else "holy_every"])
		_holy()
	match act:
		Act.VEILED:
			if now >= _next_unveil:
				game.stat_add("boss_atk_unveil", 1.0)
				game.enemies.show_banner(String(boss_def["unveil_banner"]))
				game.host_rules().play_sound("voice_unveil", position, 0.5)
				_set_act(Act.UNVEILING)
		Act.UNVEILING:
			if act_time >= float(boss_def["unveil_windup"]):
				_unveil()
				_next_unveil = now + float(boss_def["unveil_every"])
				_set_act(Act.VEILED)
	if last_word and _owed > 0 and now >= _next_wave:
		_next_wave = now + float(boss_def["wave_every"])
		var n := mini(_owed, int(boss_def["wave_size"]))
		_owed -= n
		var sent := game.host_rules().judgment.send_wave(n)
		game.stat_add("voice_judges_sent", float(sent))
		game.stat_add("voice_waves", 1.0)
		game.host_rules().play_sound("last_word", game.player.position, 0.5)


## THE HOLY: holy_shafts shafts round every standing necromancer, evenly
## turned (the turn follows game time), each sweeping across him.
func _holy() -> void:
	var light := game.host_rules().light
	game.stat_add("boss_atk_holy", 1.0)
	game.host_rules().play_sound("voice_holy", position, 0.5)
	var n := maxi(1, int(boss_def["holy_shafts"]))
	var off := float(light.cfg["start_offset"])
	var a0 := game.elapsed * 0.7  # A turn that follows the clock (no RNG).
	for pl in game.all_players:
		if pl.dead:
			continue
		for i in n:
			var nrm := Vector2.from_angle(a0 + PI * float(i) / float(n))  # Spread over half a turn: the shafts cross.
			if light.add_shaft(pl.position - nrm * off, nrm, float(boss_def["holy_width"]), off * 2.0):
				game.stat_add("voice_holy_shafts", 1.0)
			else:
				game.stat_add("voice_holy_refused", 1.0)


## BE NOT AFRAID: the screen whitens and every summon in the open stops.
func _unveil() -> void:
	var light := game.host_rules().light
	var stun := float(boss_def["unveil_stun"])
	var stopped := 0
	for h in game.all_hordes:
		for u in h.units:
			if not u.active or u.state == SummonedUnit.State.SPAWNING or u.state == SummonedUnit.State.DEAD:
				continue
			if light.shaded(u.position, u.radius):
				game.stat_add("voice_unveil_spared_shade", 1.0)
			elif u.barrier_hp > 0.0:
				game.stat_add("voice_unveil_spared_barrier", 1.0)
			elif game.combat.stun_unit(u, stun, VoiceData.UNVEIL_SOURCE) > 0.0:
				stopped += 1
	game.stat_add("voice_unveil_stopped", float(stopped))
	game.shake(5.0)
	game.effects.ring(position, 300.0, Palette.HOST_STARLIGHT, 0.6)
	if DisplayServer.get_name() != "headless":
		if is_instance_valid(_white):
			_white.queue_free()
		_white = ParagonSky.new(game, self, VoiceData.WHITE_FADE, VoiceData.WHITE_ALPHA)
		game.add_child(_white)
		_white.release()  # A flash: it turns white, then fades out at once.


## THE LAST WORD begins: the run's sins become the Judges owed.
func _begin_last_word() -> void:
	last_word = true
	var j := game.host_rules().judgment
	var sins := float(j.raised + j.replaced)
	_owed = clampi(roundi(sins * float(boss_def["judges_per_sin"])), int(boss_def["last_word_min"]), int(boss_def["last_word_cap"]))
	_next_wave = game.elapsed
	game.stat_add("boss_atk_last_word", 1.0)
	game.stat_add("voice_judges_owed", float(_owed))
	game.stats["voice_last_word_at"] = game.elapsed
	game.enemies.show_banner(String(boss_def["last_word_banner"]))
	game.shake(4.0)


## The Holy's extra Light slots end.
func _end_holy() -> void:
	if _holy_slots > 0 and game != null and game.host != null:
		game.host.light.max_live = maxi(1, game.host.light.max_live - _holy_slots)
	_holy_slots = 0


## Changes action, resets its timer and redraws.
func _set_act(a: Act) -> void:
	act = a
	act_time = 0.0
	queue_redraw()


# =====================================================================================
# Death, autopilot hint, drawing
# =====================================================================================

## Its defeat (EnemyDirector.boss_defeated, after the reward burst): the Holy
## ends, no more Judges, the short ending text (no epilogue).
func _on_defeated() -> void:
	_end_holy()
	_owed = 0
	var pos := position
	game.effects.ring(pos, 260.0, Palette.HOST_STARLIGHT, 1.2)
	game.effects.ring(pos, 150.0, Palette.HOST_ROSE, 0.9)
	Juice.fx.burst(pos, Palette.HOST_STARLIGHT, Palette.HOST_ROSE, 30, 340.0, 1.1, 3.5)
	game.shake(12.0)
	Sfx.play("boss_impact", pos, 0.6)
	game.enemies.show_banner(String(game.enemies.boss_info.get("defeat_banner", "")))
	game.enemies.banner_until = game.elapsed + VoiceData.ENDING_BANNER_TIME
	if game.hud != null:
		var txt: Array = VoiceData.LATE_ANNOUNCE if game.countdown_finished() else VoiceData.ENDING_ANNOUNCE
		game.hud.announce(String(txt[0]), String(txt[1]), String(txt[2]), Palette.HOST_STARLIGHT)
	game.stats["voice_kill_time"] = game.elapsed - _spawn_time


## Body layer on `ci`: its sprite (the unveiled art while the face wings are
## lowered); a code shape without the art.
func _draw_body(ci: CanvasItem) -> void:
	var key := VoiceData.UNVEILED_SPRITE if act == Act.UNVEILING else VoiceData.SPRITE
	if not SpriteBank.draw(ci, key, Vector2.ZERO, flash > 0.0):
		_glyph(ci)


## Its code shape without the art: a white rose of light, two spread wings,
## two over the feet, two over the face (lowered while it unveils; the face is
## pure light, never features). Disc textures only.
func _glyph(ci: CanvasItem) -> void:
	var r := radius
	var fl := flash > 0.0
	SpriteBank.draw_disc(ci, Vector2(0.0, r * 0.7), r * 1.3, Glyphs._c(Color(Palette.HOST_ROSE, 0.35), fl))  # The white rose under it.
	for s: float in [-1.0, 1.0]:
		SpriteBank.draw_disc(ci, Vector2(s * r * 0.95, -r * 0.2), r * 0.62, Glyphs._c(HostGlyphs.INK, fl))
		SpriteBank.draw_disc(ci, Vector2(s * r * 0.95, -r * 0.2), r * 0.56, Glyphs._c(Palette.HOST_STARLIGHT, fl))  # The spread wings.
		SpriteBank.draw_disc(ci, Vector2(s * r * 0.3, r * 0.55), r * 0.36, Glyphs._c(Palette.HOST_SILVER, fl))  # The wings over the feet.
	SpriteBank.draw_disc(ci, Vector2.ZERO, r * 0.5, Glyphs._c(Palette.HOST_CLOUD, fl))
	if act == Act.UNVEILING:
		var k := clampf(act_time / maxf(0.01, float(boss_def["unveil_windup"])), 0.0, 1.0)
		SpriteBank.draw_disc(ci, Vector2(0.0, -r * 0.55), r * (0.3 + 0.25 * k), Glyphs._c(Palette.HOST_STARLIGHT, fl))  # The face: pure light.
	else:
		for s2: float in [-1.0, 1.0]:
			SpriteBank.draw_disc(ci, Vector2(s2 * r * 0.2, -r * 0.6), r * 0.32, Glyphs._c(Palette.HOST_SILVER, fl))  # The wings over the face.


## Overlay layer on `ci`: a widening ring of light while it unveils (the
## telegraph). Visual only: rects.
func _draw_over(ci: CanvasItem) -> void:
	CovenantKit.unmirror(self, ci)
	if act == Act.UNVEILING:
		var k := clampf(act_time / maxf(0.01, float(boss_def["unveil_windup"])), 0.0, 1.0)
		var rr := radius * (1.4 + 1.6 * k)
		for i in 16:
			var p := Vector2.from_angle(TAU * float(i) / 16.0) * rr
			ci.draw_rect(Rect2(p - Vector2(1.5, 1.5), Vector2(3.0, 3.0)), Color(Palette.HOST_STARLIGHT, 0.3 + 0.7 * k))
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if frozen:
		PowerupGlyphs.draw_frozen(ci, Vector2.ZERO, radius)


## One autotest summary line of its fight.
static func summary_line(st: Dictionary) -> String:
	var lw := float(st.get("voice_last_word_at", -1.0))
	var kt := float(st.get("voice_kill_time", -1.0))
	return "the Holy: casts %d, shafts %d (refused %d) | be not afraid: %d, summons stopped %d, spared by shade %d / barrier %d | the last word: %s, judges owed %d, sent %d in %d waves | killed %s | dmg to you %d, to summons %d" % [
		int(st.get("boss_atk_holy", 0.0)), int(st.get("voice_holy_shafts", 0.0)), int(st.get("voice_holy_refused", 0.0)),
		int(st.get("boss_atk_unveil", 0.0)), int(st.get("voice_unveil_stopped", 0.0)),
		int(st.get("voice_unveil_spared_shade", 0.0)), int(st.get("voice_unveil_spared_barrier", 0.0)),
		EmpireReport._clock(lw) if lw >= 0.0 else "not reached", int(st.get("voice_judges_owed", 0.0)),
		int(st.get("voice_judges_sent", 0.0)), int(st.get("voice_waves", 0.0)),
		("%.0f s after it arrived" % kt) if kt >= 0.0 else "no",
		int(st.get("player_dmg_from_" + HostRulesData.LIGHT_SOURCE, 0.0)) + int(st.get("player_dmg_from_" + HostRulesData.VERDICT_SOURCE, 0.0)),
		int(st.get("summon_dmg_from_" + HostRulesData.LIGHT_SOURCE, 0.0))]
