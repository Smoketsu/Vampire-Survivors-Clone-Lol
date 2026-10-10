## Necromancer — the player character (GDD §4/§5). The player ONLY moves the
## necromancer (WASD / arrows / left stick via the move_* input actions);
## spells and summons are fully automatic (GDD §21).
##
## Owns HP, i-frames, pickup radius and the priest ward (damage-absorb
## shield, user brief), and the meta revival (Survival tree "Undying Will",
## GDD §9.2): lethal damage with a revival left restores part of max HP. Movement has no physical collision
## with summons (GDD §26 "Player <-> friendly undead: NO physical collision")
## and the open arena has no solid geometry, so the node is moved directly
## instead of using CharacterBody2D physics.
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
## Facing sign (+1 right, -1 left) used to mirror the sprite.
var _facing: float = 1.0


func _ready() -> void:
	z_index = 1
	queue_redraw()


## Per-physics-tick update, called by Game in a fixed order.
func step(delta: float) -> void:
	if dead:
		return
	var input := Vector2.ZERO
	if game.autotest != null:
		input = game.autotest.get_move_vector()
	else:
		input = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = input * move_speed
	position += velocity * delta
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
	# Natural regeneration (PlayerData.HP_REGEN), capped at max HP.
	if hp < max_hp:
		hp = minf(max_hp, hp + PlayerData.HP_REGEN * delta)
	if shield_time > 0.0:
		shield_time -= delta
		if shield_time <= 0.0:
			shield_hp = 0.0
			queue_redraw()


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
	if dead or iframes > 0.0:
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


func _draw() -> void:
	Glyphs.draw_necromancer(self, Vector2.ZERO, radius, flash > 0.0)
	if shield_hp > 0.0:
		# Priest ward: translucent necrotic bubble, thicker when stronger.
		var k := clampf(shield_hp / maxf(shield_max, 1.0), 0.0, 1.0)
		draw_circle(Vector2.ZERO, radius * 2.0, Color(Palette.COLD_BLUE, 0.10 + 0.10 * k))
		draw_arc(Vector2.ZERO, radius * 2.0, 0.0, TAU, 32, Color(Palette.NECRO_GREEN, 0.5 + 0.4 * k), 1.0 + 2.0 * k)
