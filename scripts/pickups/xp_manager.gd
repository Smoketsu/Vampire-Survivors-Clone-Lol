## XpManager — spawns, magnetises, collects and pools XP crystals
## (GDD §3 loop, §5 "Pickup Radius"). Crystals inside the necromancer's pickup
## radius accelerate toward him and grant XP on contact. To bound node count
## in long fights, a drop beyond MAX_CRYSTALS merges its value into a crystal
## near the drop point, or else moves the crystal farthest from the
## necromancer to the drop point, so XP left behind in a 20-minute run keeps
## coming back into play instead of every later drop vanishing into it.
## magnetize_all() is the Soul Magnet power-up (PowerupManager).
## Co-op (CoopSession): either standing necromancer's pickup radius catches a
## crystal (slot order); it then flies to that one (XpCrystal.slot; to the
## nearest standing one if he goes down) and its XP goes into the ONE shared bar
## with that slot bound (Game.add_xp(): his Grave Tithe, the co-op x0.5).
class_name XpManager
extends Node2D

## Maximum crystals lying in the world at once.
const MAX_CRYSTALS: int = 250  # TUNING (not in GDD)
## At the cap, a drop merges into an existing crystal only within this many
## px of the drop point; otherwise the crystal farthest from the necromancer
## is moved to the drop point (with its value).
const MERGE_RADIUS: float = 60.0  # TUNING (not in GDD)

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
		var nearest := active[0]  # Crystal closest to the drop point.
		var best_d2 := INF
		var farthest := active[0]  # Crystal farthest from the necromancer.
		var far_d2 := -1.0
		var p := game.player.position
		for c in active:
			var d2 := c.position.distance_squared_to(pos)
			if d2 < best_d2:
				best_d2 = d2
				nearest = c
			var pd2 := c.position.distance_squared_to(p)
			if pd2 > far_d2:
				far_d2 = pd2
				farthest = c
		if best_d2 <= MERGE_RADIUS * MERGE_RADIUS:
			nearest.value += value
			nearest.queue_redraw()
		else:
			# No crystal nearby: the stray crystal farthest from the
			# necromancer moves here and keeps its value, so drops never
			# vanish into crystals he left far behind.
			farthest.setup(pos, farthest.value + value)
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
	if game.coop != null:
		_step_coop(delta)
		return
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


## Co-op magnet + collection (see the header).
func _step_coop(delta: float) -> void:
	var co := game.coop
	var i := 0
	while i < active.size():
		var c := active[i]
		if not c.magnet:
			for s in co.slots:
				if s.alive() and c.position.distance_squared_to(s.player.position) <= s.player.pickup_radius * s.player.pickup_radius:
					c.magnet = true
					c.slot = s.index
					break
		if c.magnet:
			if not co.slots[c.slot].alive():
				c.slot = co.nearest_slot(c.position)  # Its necromancer went down: the nearest standing one.
			var to_p := co.slots[c.slot].player.position - c.position
			var d := to_p.length()
			if d <= PlayerData.COLLECT_RADIUS:
				var prev := co.bound
				co.bind(c.slot)
				game.add_xp(c.value)
				co.bind(prev)
				c.active = false
				c.visible = false
				active[i] = active[active.size() - 1]
				active.pop_back()
				_pool.append(c)
				continue
			c.speed = minf(c.speed + PlayerData.MAGNET_ACCEL * delta, PlayerData.MAGNET_MAX_SPEED)
			c.position += to_p / d * minf(c.speed * delta, d)
		i += 1


## Soul Magnet power-up (PowerupManager): every crystal on the stage starts
## flying to the necromancer (co-op: to the one who took it). Returns how many
## were pulled.
func magnetize_all() -> int:
	var to_slot := game.coop.bound if game.coop != null else 0  # Co-op: the collector's slot.
	for c in active:
		c.magnet = true
		c.slot = to_slot
	return active.size()
