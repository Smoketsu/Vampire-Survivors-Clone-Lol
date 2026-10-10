## Juice — game-feel autoload: trauma-based screen shake, hit-stop, the
## player-hurt vignette, and the world FxLayer (death pops, XP sparkles,
## damage numbers). It is also the bridge that turns run events into
## sounds and visuals, so gameplay scripts barely know it exists:
##   * Signals: when a Game node enters the tree, Juice connects to the
##     signals the run already has (HordeDirector summon_created /
##     summon_died, EnemyDirector boss_spawned / reckoning_started,
##     LevelUpPanel card_chosen, Necromancer died).
##   * Polling (like the HUD): level-ups, player HP loss, XP collected, and
##     the existing priest_wards / orb_intercepts counters in Game.stats are
##     compared once per frame.
##   * One-line calls from gameplay where no signal exists:
##     CombatResolver -> enemy_hit() / enemy_killed(),
##     EffectManager.impact() -> impact(), Game.shake() -> shake(),
##     Game._process() -> camera_offset(),
##     PowerupManager.collect() -> powerup_collected() (pickup sound, sparkle
##     burst and a full-screen colour flash).
## Screen tint: while Stasis or Hyper runs, a faint cold-blue / violet tint
## covers the world (polled from game.powerups); pickups flash it brighter.
## Screen shake: Game.shake(px) adds trauma; the camera offset is
## MAX_SHAKE_PX * trauma^2 along smooth pseudo-noise and trauma decays
## linearly in real time. Off when Settings.screen_shake is false.
## Hit-stop: Engine.time_scale drops to HITSTOP_SCALE for a few real-time
## milliseconds on boss impacts and big kills, then is restored. It is never
## used in autotest mode (the autotest owns Engine.time_scale) or while the
## tree is paused (level-up / pause menu).
## All randomness uses its own RNG, never the seeded gameplay RNG.
extends Node

## Camera offset (px) at full trauma; also the largest useful shake request.
const MAX_SHAKE_PX: float = 10.0  # TUNING (not in GDD)
## Scales how much trauma one shake request adds (0..1).
const TRAUMA_GAIN: float = 0.75  # TUNING (not in GDD)
## Trauma lost per real-time second.
const TRAUMA_DECAY: float = 1.6  # TUNING (not in GDD)
## Angular speeds (rad/s) of the two sines making the shake pseudo-noise.
const SHAKE_FREQ: Vector2 = Vector2(41.0, 67.0)  # TUNING (not in GDD)
## Engine.time_scale during a hit-stop.
const HITSTOP_SCALE: float = 0.05  # TUNING (not in GDD)
## Longest hit-stop allowed (ms), however many requests overlap.
const HITSTOP_MAX_MS: int = 140  # TUNING (not in GDD)
## Hit-stop for a boss ground impact (Hammerfall landing).
const HITSTOP_IMPACT_MS: int = 70  # TUNING (not in GDD)
## Hit-stop for killing the boss.
const HITSTOP_BOSS_KILL_MS: int = 130  # TUNING (not in GDD)
## Hit-stop for killing an elite.
const HITSTOP_ELITE_KILL_MS: int = 40  # TUNING (not in GDD)
## Seconds the hurt vignette takes to fade from full to nothing.
const VIGNETTE_FADE: float = 0.45  # TUNING (not in GDD)
## XP pickups closer together than this (s) continue the rising chain.
const XP_CHAIN_WINDOW: float = 0.45  # TUNING (not in GDD)
## Semitone steps of the XP pickup chain (natural minor, one octave).
const XP_CHAIN_STEPS: Array = [0.0, 2.0, 3.0, 5.0, 7.0, 8.0, 10.0, 12.0]  # TUNING (not in GDD)
## Damage source tag (CombatResolver) -> hit sound; others use enemy_hit.
const SOURCE_SOUNDS: Dictionary = {"bolt": "bolt_hit", "orb": "orb_hit", "bash": "warrior_bash",
	"blast": "shadow_blast", "mage": "mage_burst",
	"spear": "spear_hit", "lance": "spear_hit", "siphon": "siphon_hit", "rapture": "siphon_hit",
	"plague": "plague_tick", "pestilence": "plague_tick"}
## Damage sources drawn in the spell colour (others use bone white).
const SPELL_SOURCES: Dictionary = {"bolt": true, "orb": true, "blast": true,
	"spear": true, "lance": true, "siphon": true, "rapture": true, "rapture_burst": true, "corpse": true,
	"eruption": true, "eruption_spikes": true, "plague": true, "pestilence": true, "death_nova": true}
## Damage-number colour for the necromancer's spells.
const SPELL_NUMBER_COLOR: Color = Color(0.86, 0.74, 1.0)
## Peak alpha of the full-screen flash when a power-up is collected.
const POWERUP_FLASH_ALPHA: float = 0.28  # TUNING (not in GDD)
## Peak alpha of the much bigger Soul Nova (screen clear) flash.
const NOVA_FLASH_ALPHA: float = 0.7  # TUNING (not in GDD)
## Seconds the power-up flash takes to fade out.
const POWERUP_FLASH_FADE: float = 0.4  # TUNING (not in GDD)
## Steady screen-tint alpha while Stasis / Hyper runs.
const BUFF_TINT_ALPHA: float = 0.07  # TUNING (not in GDD)

## World-space particles and damage numbers.
var fx: FxLayer
## Current trauma (0..1).
var _trauma: float = 0.0
## Camera offset computed this frame (read by Game._process).
var _offset: Vector2 = Vector2.ZERO
## Real-time seconds accumulated for the shake pseudo-noise.
var _shake_t: float = 0.0
## Random phase offsets of the shake sines.
var _shake_phase: Vector2 = Vector2.ZERO
## True while a hit-stop holds Engine.time_scale down.
var _hitstopping: bool = false
## Engine.time_scale to restore when the hit-stop ends.
var _restore_scale: float = 1.0
## usec timestamp at which the current hit-stop ends.
var _hitstop_end_usec: int = 0
## usec timestamp of the last _process (real-time delta for shake/vignette).
var _last_usec: int = 0
## Full-screen red edge glow shown when the player is hurt.
var _vignette: TextureRect
## Current vignette strength (0..1).
var _vignette_a: float = 0.0
## The run being watched (null in the menu).
var _game: Game = null
## Player level last frame (level-up sound).
var _last_level: int = 1
## Player HP last frame (hurt detection).
var _last_hp: float = 0.0
## xp_collected stat last frame (pickup detection).
var _last_xp: float = 0.0
## priest_wards stat last frame (ward sound).
var _last_wards: float = 0.0
## orb_intercepts stat last frame (orb block sound).
var _last_intercepts: float = 0.0
## Position in XP_CHAIN_STEPS of the next pickup sound.
var _xp_chain: int = 0
## Time (ms) of the last XP pickup sound.
var _xp_last_msec: int = -100000
## Cosmetic RNG (never the global, seeded RNG).
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
## Full-screen colour overlay for power-up flashes and the Stasis / Hyper tint.
var _tint: ColorRect
## Current power-up flash strength (0..1, fades over POWERUP_FLASH_FADE).
var _flash_a: float = 0.0
## Colour of the current power-up flash.
var _flash_color: Color = Palette.VIOLET
## Peak alpha of the current power-up flash.
var _flash_peak: float = POWERUP_FLASH_ALPHA


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rng.randomize()
	_shake_phase = Vector2(_rng.randf() * TAU, _rng.randf() * TAU)
	fx = FxLayer.new()
	fx.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(fx)
	_build_vignette()
	_build_tint()
	_last_usec = Time.get_ticks_usec()
	get_tree().node_added.connect(_on_node_added)


## Builds the power-up tint overlay on its own CanvasLayer just under the
## hurt vignette (layer 9) and the HUD (layer 10).
func _build_tint() -> void:
	var layer := CanvasLayer.new()  # Holds the overlay above the world.
	layer.layer = 8
	add_child(layer)
	_tint = ColorRect.new()
	_tint.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tint.color = Color(0, 0, 0, 0)
	_tint.visible = false
	layer.add_child(_tint)


## Builds the hurt vignette: a CanvasLayer between the world and the HUD
## (Game's UI layer is 10) holding a stretched radial gradient texture.
func _build_vignette() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 9
	add_child(layer)
	var grad := Gradient.new()
	grad.set_color(0, Color(0.6, 0.0, 0.05, 0.0))
	grad.set_offset(0, 0.55)
	grad.set_color(1, Color(0.6, 0.0, 0.05, 0.85))
	grad.set_offset(1, 1.0)
	var tex := GradientTexture2D.new()
	tex.gradient = grad
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	tex.width = 128
	tex.height = 128
	_vignette = TextureRect.new()
	_vignette.texture = tex
	_vignette.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_vignette.stretch_mode = TextureRect.STRETCH_SCALE
	_vignette.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vignette.visible = false
	layer.add_child(_vignette)


func _process(_delta: float) -> void:
	var now := Time.get_ticks_usec()
	var real_dt := minf(float(now - _last_usec) / 1000000.0, 0.1)
	_last_usec = now
	if _hitstopping and now >= _hitstop_end_usec:
		_end_hitstop()
	# Screen shake (real time, so it keeps moving during a hit-stop).
	_trauma = maxf(0.0, _trauma - TRAUMA_DECAY * real_dt)
	if _trauma > 0.0 and Settings.screen_shake:
		_shake_t += real_dt
		var amp := MAX_SHAKE_PX * _trauma * _trauma
		_offset = Vector2(sin(_shake_t * SHAKE_FREQ.x + _shake_phase.x) * 0.6 + sin(_shake_t * SHAKE_FREQ.y) * 0.4,
				sin(_shake_t * SHAKE_FREQ.y + _shake_phase.y) * 0.6 + sin(_shake_t * SHAKE_FREQ.x) * 0.4) * amp
	else:
		_offset = Vector2.ZERO
	# Hurt vignette fade.
	if _vignette_a > 0.0:
		_vignette_a = maxf(0.0, _vignette_a - real_dt / VIGNETTE_FADE)
		_vignette.modulate.a = _vignette_a
		_vignette.visible = _vignette_a > 0.0
	_update_tint(real_dt)
	if _game != null:
		_poll_game()


# =====================================================================================
# Public API (one-line hooks from gameplay)
# =====================================================================================

## Adds camera shake for a request of `px` pixels (Game.shake()).
func shake(px: float) -> void:
	if px <= 0.0 or not Settings.screen_shake:
		return
	_trauma = minf(1.0, _trauma + sqrt(minf(px, MAX_SHAKE_PX) / MAX_SHAKE_PX) * TRAUMA_GAIN)


## Camera offset for this frame (Game._process applies it).
func camera_offset() -> Vector2:
	return _offset


## Freezes the simulation for `ms` real-time milliseconds (see header).
func hitstop(ms: int) -> void:
	if ms <= 0 or GameState.autotest or get_tree().paused:
		return
	var now := Time.get_ticks_usec()
	if not _hitstopping:
		_hitstopping = true
		_restore_scale = Engine.time_scale
		Engine.time_scale = HITSTOP_SCALE
		_hitstop_end_usec = now
	_hitstop_end_usec = mini(maxi(_hitstop_end_usec, now + ms * 1000), now + HITSTOP_MAX_MS * 1000)


## A power-up was collected (PowerupManager.collect): its pickup sound, a
## sparkle burst on the necromancer and a screen flash in its colour.
func powerup_collected(kind: String, pos: Vector2) -> void:
	var def: Dictionary = PowerupData.POWERUPS[kind]  # Power-up definition.
	var col: Color = def["color"]  # Accent colour of the power-up.
	Sfx.play(String(def["sound"]))
	fx.burst(pos, col, Palette.BONE, 18, 120.0, 0.6, 3.0)
	_flash_color = col
	_flash_a = 1.0
	_flash_peak = NOVA_FLASH_ALPHA if kind == "nova" else POWERUP_FLASH_ALPHA


## Fades the power-up flash and keeps the steady Stasis / Hyper tint.
func _update_tint(real_dt: float) -> void:
	if _flash_a > 0.0:
		_flash_a = maxf(0.0, _flash_a - real_dt / POWERUP_FLASH_FADE)
	var steady := Color(0, 0, 0, 0)  # Tint while a screen-wide buff runs.
	if _game != null and _game.powerups != null:
		if _game.powerups.is_active("stasis"):
			steady = Color(Palette.COLD_BLUE, BUFF_TINT_ALPHA)
		elif _game.powerups.is_active("hyper"):
			steady = Color(Palette.VIOLET, BUFF_TINT_ALPHA)
	var flash_a := _flash_a * _flash_peak  # Flash alpha this frame.
	if flash_a <= 0.0 and steady.a <= 0.0:
		_tint.visible = false
		return
	_tint.visible = true
	_tint.color = Color(_flash_color, flash_a) if flash_a > steady.a else steady


## An enemy took `dealt` damage from `source` (CombatResolver.damage_enemy).
func enemy_hit(e: Enemy, dealt: float, source: String) -> void:
	if dealt <= 0.0:
		return
	Sfx.play(SOURCE_SOUNDS.get(source, "enemy_hit"), e.position)
	if Settings.damage_numbers:
		var col := Palette.GOLD if e.is_boss else (SPELL_NUMBER_COLOR if SPELL_SOURCES.has(source) else Palette.BONE)
		fx.number(e.get_instance_id(), e.position, dealt, col, e.is_boss)


## An enemy died (CombatResolver._kill_enemy): sound, pop, hit-stop on big kills.
func enemy_killed(e: Enemy) -> void:
	if e.is_boss:
		Sfx.play("boss_impact", e.position, 0.8)
		fx.burst(e.position, Palette.GOLD, Palette.IVORY, 40, 170.0, 0.9, 4.0)
		shake(MAX_SHAKE_PX)
		hitstop(HITSTOP_BOSS_KILL_MS)
	elif e.is_elite:
		Sfx.play("enemy_death", e.position, 0.7)
		fx.burst(e.position, Palette.GOLD, Palette.CRIMSON, 14, 120.0, 0.6, 3.0)
		shake(3.0)
		hitstop(HITSTOP_ELITE_KILL_MS)
	else:
		Sfx.play("enemy_death", e.position)
		fx.burst(e.position, Palette.CRIMSON, Palette.BONE, 5, 80.0, 0.4, 2.5)


## A boss ground impact landed (EffectManager.impact): boom + hit-stop.
func impact(pos: Vector2, radius: float) -> void:
	Sfx.play("boss_impact", pos)
	fx.burst(pos, Palette.GOLD, Palette.IVORY, 16, radius * 1.6, 0.5, 3.0)
	hitstop(HITSTOP_IMPACT_MS)


# =====================================================================================
# Run bridge
# =====================================================================================

## Watches for a new run (Game) and attaches once it has built its systems.
func _on_node_added(node: Node) -> void:
	if node is Game:
		node.ready.connect(_attach.bind(node), CONNECT_ONE_SHOT)


## Connects to the run's existing signals and snapshots polled values.
func _attach(g: Game) -> void:
	_game = g
	g.tree_exiting.connect(_detach, CONNECT_ONE_SHOT)
	g.horde.summon_created.connect(_on_summon_created)
	g.horde.summon_died.connect(_on_summon_died)
	g.enemies.boss_spawned.connect(_on_boss_spawned)
	g.enemies.reckoning_started.connect(_on_reckoning_started)
	g.level_up_panel.card_chosen.connect(_on_card_chosen)
	g.player.died.connect(_on_player_died)
	_last_level = g.level
	_last_hp = g.player.hp
	_last_xp = float(g.stats.get("xp_collected", 0.0))
	_last_wards = float(g.stats.get("priest_wards", 0.0))
	_last_intercepts = float(g.stats.get("orb_intercepts", 0.0))


## The run is being freed: drop it and clear every lingering effect.
func _detach() -> void:
	_game = null
	fx.clear()
	_trauma = 0.0
	_offset = Vector2.ZERO
	_vignette_a = 0.0
	_vignette.visible = false
	_flash_a = 0.0
	_tint.visible = false
	if _hitstopping:
		_end_hitstop()


## Per-frame comparison of run values that have no signal.
func _poll_game() -> void:
	var g := _game
	if g.level > _last_level:
		_last_level = g.level
		Sfx.play("level_up")
	var hp := g.player.hp
	if hp < _last_hp - 0.01:
		_on_player_hurt((_last_hp - hp) / maxf(1.0, g.player.max_hp))
	_last_hp = hp
	var xp := float(g.stats.get("xp_collected", 0.0))
	if xp > _last_xp:
		_last_xp = xp
		_on_xp_collected(g.player.position)
	var wards := float(g.stats.get("priest_wards", 0.0))
	if wards > _last_wards:
		_last_wards = wards
		Sfx.play("priest_ward", g.player.position)
	var intercepts := float(g.stats.get("orb_intercepts", 0.0))
	if intercepts > _last_intercepts:
		_last_intercepts = intercepts
		Sfx.play("orb_block", g.player.position)


## Rising-pitch pickup chime plus a sparkle on the necromancer.
func _on_xp_collected(pos: Vector2) -> void:
	var now := Time.get_ticks_msec()
	if now - _xp_last_msec > int(XP_CHAIN_WINDOW * 1000.0):
		_xp_chain = 0
	_xp_last_msec = now
	Sfx.play("xp_pickup", Vector2.INF, pow(2.0, float(XP_CHAIN_STEPS[_xp_chain]) / 12.0))
	_xp_chain = mini(_xp_chain + 1, XP_CHAIN_STEPS.size() - 1)
	fx.sparkle(pos, Palette.XP, 3)


## Player lost `fraction` of max HP this frame.
func _on_player_hurt(fraction: float) -> void:
	Sfx.play("player_hurt")
	_vignette_a = clampf(0.4 + fraction * 4.0, 0.4, 0.9)
	_vignette.modulate.a = _vignette_a
	_vignette.visible = true


func _on_summon_created(u: SummonedUnit) -> void:
	Sfx.play("summon_rise", u.position)
	fx.sparkle(u.position, Palette.NECRO_GREEN, 4)


func _on_summon_died(u: SummonedUnit) -> void:
	Sfx.play("summon_death", u.position)
	fx.burst(u.position, Palette.COLD_BLUE, Palette.BONE, 6, 90.0, 0.45, 2.5)


func _on_boss_spawned(_boss: Enemy) -> void:
	Sfx.play("boss_arrive")
	shake(5.0)


func _on_reckoning_started() -> void:
	Sfx.play("reckoning")
	shake(8.0)


func _on_card_chosen(_offer: Dictionary) -> void:
	Sfx.play_card_select()


func _on_player_died() -> void:
	Sfx.play("player_death")
	shake(MAX_SHAKE_PX)
	_vignette_a = 1.0
	_vignette.modulate.a = 1.0
	_vignette.visible = true


## Restores Engine.time_scale after a hit-stop.
func _end_hitstop() -> void:
	_hitstopping = false
	Engine.time_scale = _restore_scale
