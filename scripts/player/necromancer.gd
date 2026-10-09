## Necromancer — the player character (GDD §4/§5). The player ONLY moves the
## necromancer (WASD / arrows / left stick via the move_* input actions);
## spells and summons are fully automatic (GDD §21).
##
## Owns HP, i-frames and pickup radius. Movement has no physical collision
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


## Applies damage unless invulnerable. Returns true if damage was taken.
func take_damage(amount: float) -> bool:
	if dead or iframes > 0.0:
		return false
	hp -= amount
	iframes = PlayerData.IFRAMES
	flash = 0.12
	queue_redraw()
	if hp <= 0.0:
		if invulnerable:
			hp = 1.0
		else:
			hp = 0.0
			dead = true
			died.emit()
	return true


## Restores HP up to max. Returns the amount actually healed.
func heal(amount: float) -> float:
	if dead:
		return 0.0
	var healed := minf(amount, max_hp - hp)
	hp += healed
	return healed


func _draw() -> void:
	Glyphs.draw_necromancer(self, Vector2.ZERO, radius, flash > 0.0)
