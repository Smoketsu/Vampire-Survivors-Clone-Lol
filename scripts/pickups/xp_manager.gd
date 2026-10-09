## XpManager — spawns, magnetises, collects and pools XP crystals
## (GDD §3 loop, §5 "Pickup Radius"). Crystals inside the necromancer's pickup
## radius accelerate toward him and grant XP on contact. To bound node count
## in long fights, crystals beyond MAX_CRYSTALS merge their value into the
## existing crystal nearest the drop point instead of spawning a new one.
class_name XpManager
extends Node2D

## Maximum crystals lying in the world at once.
const MAX_CRYSTALS: int = 250  # TUNING (not in GDD)

## Owning run.
var game: Game
## Crystals in the world.
var active: Array[XpCrystal] = []
## Idle crystals ready for reuse.
var _pool: Array[XpCrystal] = []
## Total XpCrystal nodes ever instantiated (debug: pool health).
var created: int = 0


func _ready() -> void:
	z_index = -2


## Drops a crystal worth `value` XP at `pos`.
func spawn(pos: Vector2, value: int) -> void:
	if active.size() >= MAX_CRYSTALS:
		var nearest := active[0]
		var best_d2 := INF
		for c in active:
			var d2 := c.position.distance_squared_to(pos)
			if d2 < best_d2:
				best_d2 = d2
				nearest = c
		nearest.value += value
		nearest.queue_redraw()
		return
	var c: XpCrystal
	if _pool.is_empty():
		c = XpCrystal.new()
		add_child(c)
		created += 1
	else:
		c = _pool.pop_back()
	c.setup(pos + Vector2(randf_range(-4.0, 4.0), randf_range(-4.0, 4.0)), value)
	active.append(c)


## Magnet + collection update.
func step(delta: float) -> void:
	var player := game.player
	var p := player.position
	var pick2 := player.pickup_radius * player.pickup_radius
	var i := 0
	while i < active.size():
		var c := active[i]
		var to_p := p - c.position
		var d2 := to_p.length_squared()
		if not c.magnet and d2 <= pick2:
			c.magnet = true
		if c.magnet:
			var d := sqrt(d2)
			if d <= PlayerData.COLLECT_RADIUS:
				game.add_xp(c.value)
				c.active = false
				c.visible = false
				active[i] = active[active.size() - 1]
				active.pop_back()
				_pool.append(c)
				continue
			c.speed = minf(c.speed + PlayerData.MAGNET_ACCEL * delta, PlayerData.MAGNET_MAX_SPEED)
			c.position += to_p / d * minf(c.speed * delta, d)
		i += 1
