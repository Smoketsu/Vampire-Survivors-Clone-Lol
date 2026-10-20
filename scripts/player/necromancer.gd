## Necromancer — the player character (GDD §4/§5). The player ONLY moves the
## necromancer (WASD / arrows / left stick via the move_* input actions);
## spells and summons are fully automatic (GDD §21).
##
## Owns HP, i-frames, pickup radius and the priest ward (damage-absorb
## shield, user brief), and the meta revival (Survival tree "Undying Will",
## GDD §9.2): lethal damage with a revival left restores part of max HP.
## Two spell passives act here: Shade Stride (+% move speed, its own
## category) and Vampiric Rite (+HP/s on top of PlayerData.HP_REGEN), both
## read from AbilityManager.passive_value(). The Grave Step dash
## (game.grave_step) runs first each tick and replaces the normal movement
## while a step is in progress; its i-frames use `iframes` like a hit.
## Movement has no physical collision with summons (GDD §26 "Player <-> friendly undead: NO physical collision")
## and the open arena has no solid geometry, so the node is moved directly
## instead of using CharacterBody2D physics.
## He is drawn as the run's playable character (CharacterGlyphs; the
## Gravecaller is the classic necromancer).
## Slowing ground (Act II: the Harbour's tide water) slows his walk through
## `terrain_slow`, set only by TerrainSlow (the one ground-slow path, where
## Brinewalker applies); it is never set in Act I, so his walk is unchanged
## there.
class_name Necromancer
extends Node2D

## Emitted once when HP reaches 0.
signal died

## Owning run.
var game: Game
## Maximum HP.
var max_hp: float = PlayerData.MAX_HP
## Current HP.
var hp: float = PlayerData.MAX_HP
## Movement speed in px/s.
var move_speed: float = PlayerData.MOVE_SPEED
## Body radius in px (enemy contact / projectile hits).
var radius: float = PlayerData.RADIUS
## Radius in px within which XP crystals get magnetised.
var pickup_radius: float = PlayerData.PICKUP_RADIUS
## Current velocity in px/s (used by aim-leading telegraphs and autopilot).
var velocity: Vector2 = Vector2.ZERO
## Remaining invulnerability time in seconds.
var iframes: float = 0.0
## Remaining hit-flash time in seconds.
var flash: float = 0.0
## True after death (stops movement / further damage).
var dead: bool = false
## Autotest: when true, damage is recorded but HP never drops below 1.
var invulnerable: bool = false
## Remaining HP of the priest ward; absorbed before real HP.
var shield_hp: float = 0.0
## Strength of the current ward when it was cast (HUD / ring opacity).
var shield_max: float = 0.0
## Seconds before the current ward expires.
var shield_time: float = 0.0
## Heals already "in flight" from priests (avoids over-healing).
var incoming_heal: float = 0.0
## Seconds since the necromancer was last hit (priests ward on recent hits).
var time_since_hit: float = 999.0
## Revivals left this run (set at run start by MetaModifiers.apply_to_player).
var revives_left: int = 0
## Fraction (0..1) of walking speed lost on slowing ground (TerrainSlow;
## the Harbour's water). Applies while terrain_slow_timer > 0.
var terrain_slow: float = 0.0
## Seconds the ground slow still applies (refreshed by TerrainSlow while he
## stands on it; 0 = none).
var terrain_slow_timer: float = 0.0
## Facing sign (+1 right, -1 left) used to mirror the sprite.
var _facing: float = 1.0
## SkinData id of the cosmetic skin worn this run ("" = the default look;
## set by Game at run start). Purely visual, never a stat.
var skin_id: String = ""
## Engine motion (UnitMotion: body / overlay layers, bob, lean, squashes,
## cast recoils); purely visual.
var motion: UnitMotion = null
## His own Grave Step (set by Game / CoopSession; MotionDirector reads it for
## the dash pose, so each co-op necromancer shows his own dash).
var dash: GraveStep = null
## CharacterData id he is drawn as ("" = the run's character, game.character;
## a co-op slot sets its own so each necromancer looks like his player's pick).
var character_id: String = ""


func _ready() -> void:
	z_index = 1
	motion = UnitMotion.new(self, _draw_body, _draw_over)
	motion.reset(UnitMotion.feet_of("player/necromancer", "", radius), radius, 1.0, false)
	queue_redraw()


## Engine motion: one of his spells is cast toward world point `at` (his own
## position = a pulse around him). Visual only.
func cast_motion(at: Vector2) -> void:
	if motion != null and game != null:
		motion.lunge(at - position, MotionData.POWER_PLAYER_CAST, game.elapsed)


## Per-physics-tick update, called by Game in a fixed order.
func step(delta: float) -> void:
	if dead:
		return
	var input := Vector2.ZERO
	if game.autotest != null:
		input = game.autotest.get_move_vector()
	elif game.coop != null:
		input = game.coop.move_input()  # Online co-op: this slot's lockstep input.
	else:
		input = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	# Grave Step (dash) moves him itself while a step runs.
	if not game.grave_step.step(delta, input):
		# Shade Stride passive: its own +% move speed category on top of move_speed.
		velocity = input * move_speed * (1.0 + game.abilities.passive_value("shade_stride", "move_speed"))
		if terrain_slow_timer > 0.0:
			velocity *= 1.0 - terrain_slow  # Slowing ground (TerrainSlow: tide water; Brinewalker already applied).
		position += velocity * delta
	if terrain_slow_timer > 0.0:
		terrain_slow_timer -= delta
	if absf(velocity.x) > 1.0:
		var f := signf(velocity.x)
		if f != _facing:
			_facing = f
			scale.x = _facing
	if iframes > 0.0:
		iframes -= delta
		# Flicker while invulnerable.
		modulate.a = 0.45 if int(iframes * 20.0) % 2 == 0 else 1.0
		if iframes <= 0.0:
			modulate.a = 1.0
	if flash > 0.0:
		flash -= delta
		if flash <= 0.0:
			queue_redraw()
	time_since_hit += delta
	# Natural regeneration (PlayerData.HP_REGEN) plus the Vampiric Rite
	# passive's HP/s, capped at max HP.
	if hp < max_hp:
		hp = minf(max_hp, hp + (PlayerData.HP_REGEN + game.abilities.passive_value("vampiric_rite", "hp_regen")) * delta)
	if shield_time > 0.0:
		shield_time -= delta
		if shield_time <= 0.0:
			shield_hp = 0.0
			queue_redraw()


## Act II ground slow from the Hollow Archive's ink pools and wells: for at
## least `duration` s he moves `fraction` (0..1) slower. It goes through
## TerrainSlow, the one ground-slow path (like the Harbour's tide), so
## Brinewalker cuts it too; the strongest slow holding wins. Grave Step ignores it.
func apply_ground_slow(fraction: float, duration: float) -> void:
	TerrainSlow.slow_player(game, clampf(fraction, 0.0, 0.9), duration)


## Applies (or refreshes) a priest ward absorbing `amount` for `duration` s.
## The stronger of the current and new ward wins.
func apply_shield(amount: float, duration: float) -> void:
	if amount >= shield_hp:
		shield_hp = amount
		shield_max = amount
	shield_time = maxf(shield_time, duration)
	queue_redraw()


## Applies damage unless in i-frames. The ward absorbs first. Returns the HP
## actually lost (0 if fully absorbed) or -1 if the hit was ignored.
func take_damage(amount: float) -> float:
	if dead:
		return -1.0
	if iframes > 0.0:
		if game != null and game.grave_step != null and game.grave_step.dodge_time > 0.0:
			game.stat_add("dash_hits_avoided", 1.0)  # Ignored during Grave Step i-frames.
		return -1.0
	time_since_hit = 0.0
	iframes = PlayerData.IFRAMES
	if shield_hp > 0.0:
		var absorbed := minf(shield_hp, amount)
		shield_hp -= absorbed
		amount -= absorbed
		if game != null:
			game.stat_add("ward_absorbed", absorbed)
		queue_redraw()
		if amount <= 0.0:
			return 0.0
	hp -= amount
	flash = 0.12
	if motion != null and game != null:
		motion.hit(game.elapsed)  # Engine motion: hit squash with the flash.
	queue_redraw()
	if hp <= 0.0:
		if invulnerable:
			hp = 1.0
		elif revives_left > 0:
			_revive()
		else:
			hp = 0.0
			dead = true
			died.emit()
	return amount


## Meta revival: uses one charge, restores MetaData.REVIVE_HP_FRACTION of max
## HP, grants REVIVE_IFRAMES of invulnerability and knocks nearby enemies back.
func _revive() -> void:
	revives_left -= 1
	hp = max_hp * MetaData.REVIVE_HP_FRACTION
	iframes = MetaData.REVIVE_IFRAMES
	if game == null:
		return
	game.stat_add("revivals", 1.0)
	var tmp: Array = []
	game.enemy_grid.query(position, MetaData.REVIVE_PUSH_RADIUS, tmp)
	for e: Enemy in tmp:
		var away := e.position - position
		if e.active and away.length() > 0.01:
			e.knockback += away.normalized() * MetaData.REVIVE_PUSH_FORCE / maxf(e.mass, 0.1)
	game.effects.ring(position, MetaData.REVIVE_PUSH_RADIUS, Palette.NECRO_GREEN, 0.6)
	game.shake(6.0)
	if game.hud != null:
		game.hud.announce("UNDYING WILL", "You rise again", "%d revival(s) left" % revives_left, Palette.NECRO_GREEN)


## Restores HP up to max. Returns the amount actually healed.
func heal(amount: float) -> float:
	if dead:
		return 0.0
	var healed := minf(amount, max_hp - hp)
	hp += healed
	return healed


## Draws in three layers (engine motion, UnitMotion): the ground ring here,
## then the body layer (the only one that moves) and the ward overlay.
func _draw() -> void:
	_draw_ground_ring()
	if motion != null:
		motion.redraw_layers()
	else:
		_draw_body(self)
		_draw_over(self)


## Body layer on `ci`: a worn skin (SkinGlyphs) draws itself, falling back
## to this character's own look; otherwise the character's look
## (CharacterGlyphs; the classic necromancer for the Gravecaller).
func _draw_body(ci: CanvasItem) -> void:
	if skin_id == "" or not SkinGlyphs.draw_skin(ci, skin_id, Vector2.ZERO, radius, flash > 0.0):
		var cid := character_id if character_id != "" else (game.character.id if game != null else CharacterData.DEFAULT_ID)  # Drawn character.
		CharacterGlyphs.draw_player(ci, cid, Vector2.ZERO, radius, flash > 0.0)


## Overlay layer on `ci`: the priest ward bubble.
func _draw_over(ci: CanvasItem) -> void:
	if shield_hp > 0.0:
		# Priest ward: translucent necrotic bubble, thicker when stronger.
		var k := clampf(shield_hp / maxf(shield_max, 1.0), 0.0, 1.0)
		ci.draw_circle(Vector2.ZERO, radius * 2.0, Color(Palette.COLD_BLUE, 0.10 + 0.10 * k))
		ci.draw_arc(Vector2.ZERO, radius * 2.0, 0.0, TAU, 32, Color(Palette.NECRO_GREEN, 0.5 + 0.4 * k), 1.0 + 2.0 * k)


## Soft ground ring under the necromancer (ViewData.PLAYER_RING_*) so the
## player stays easy to find among similar-looking summons. Drawn in the
## node's mirrored space, which is symmetric, so facing does not matter.
func _draw_ground_ring() -> void:
	var c := Vector2(0.0, ViewData.PLAYER_RING_OFFSET)  # Ring centre at the feet.
	draw_set_transform(c, 0.0, Vector2(1.0, ViewData.PLAYER_RING_SQUASH))
	draw_circle(Vector2.ZERO, ViewData.PLAYER_RING_RADIUS, ViewData.PLAYER_RING_FILL)
	draw_arc(Vector2.ZERO, ViewData.PLAYER_RING_RADIUS, 0.0, TAU, 40, ViewData.PLAYER_RING_COLOR, ViewData.PLAYER_RING_WIDTH / ViewData.PLAYER_RING_SQUASH * 0.6)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
