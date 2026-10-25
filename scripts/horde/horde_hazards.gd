## HordeHazards — the friendly ground and air effects of the three newest
## summon classes, owned by HordeDirector (`game.horde.hazards`) and ticked
## from HordeDirector.step():
##   * Corpse Catapult boulders (Bone Barrage, CatapultBehavior): a boulder
##     flies on a drawn arc from the catapult to a landing point fixed at
##     launch, for a flight time set by the distance (boulder_speed, clamped
##     to boulder_flight_min..max). Its landing spot is telegraphed on the
##     ground the whole flight (a filling bone-coloured circle). On landing
##     every enemy within the splash radius (body edges count half) takes the
##     boulder's damage and a small knockback; structures are hit like any
##     enemy. An Ossuary Engine's boulder then leaves a shard field.
##   * Ground patches (one pooled kind, two looks):
##       fire  — a Hellhound fire-trail patch (BoneHoundBehavior),
##       shard — an Ossuary Engine field of burning bone shards.
##     Every tick s a patch damages each enemy inside it (body edges count
##     half), then it fades after its life.
## Everything is pooled (Boulder / Patch objects reused, `generation` bumped
## on every launch) and capped by MAX_BOULDERS / MAX_PATCHES (safety caps,
## not balance numbers: a cap hit drops the new effect and counts it in
## hazards_dropped). Nothing here uses RNG, so runs stay deterministic per
## seed. Damage goes through CombatResolver.damage_enemy() with the source
## the caller gives ("corpse_catapult" / "ossuary_engine" for boulders,
## "hellhound_trail", "ossuary_shards").
## Drawing: this node draws the ground layer (patches, landing telegraphs,
## boulder shadows) under the bodies; a child node (`_air`) draws the
## boulders themselves above them.
## Stats: catapult_boulder_hits, catapult_structure_dmg, ossuary_shard_fields,
## hellhound_trail_patches, hazards_dropped.
class_name HordeHazards
extends Node2D

## One boulder in flight.
class Boulder:
	extends RefCounted
	## True while flying (false = pooled).
	var active: bool = false
	## Incremented on every launch (pooling guard for holders).
	var generation: int = 0
	## Launch point (world px).
	var from: Vector2 = Vector2.ZERO
	## Landing point (world px), fixed at launch.
	var to: Vector2 = Vector2.ZERO
	## Seconds flown so far.
	var t: float = 0.0
	## Total flight time (s).
	var flight: float = 1.0
	## Peak height of the drawn arc (px; drawing only).
	var arc: float = 40.0
	## Damage to every enemy in the splash.
	var damage: float = 0.0
	## Splash radius (px).
	var radius: float = 50.0
	## Knockback impulse (px/s, divided by enemy mass).
	var knockback: float = 0.0
	## Screen-shake request on landing (px, Juice).
	var shake: float = 0.0
	## Damage-source tag of the splash.
	var source: String = ""
	## Shard field left on landing: its radius (px; 0 = none).
	var shard_radius: float = 0.0
	## Shard field life (s).
	var shard_life: float = 0.0
	## Shard field tick (s).
	var shard_tick: float = 0.5
	## Shard field damage per tick to every enemy inside.
	var shard_damage: float = 0.0

## One damaging ground patch (fire trail or bone shards).
class Patch:
	extends RefCounted
	## True while burning (false = pooled).
	var active: bool = false
	## Patch look: KIND_FIRE or KIND_SHARD.
	var kind: int = 0
	## Centre (world px).
	var pos: Vector2 = Vector2.ZERO
	## Radius (px).
	var radius: float = 14.0
	## Seconds left.
	var life: float = 1.0
	## Total life (s, drawing only).
	var life_total: float = 1.0
	## Seconds between damage ticks.
	var tick: float = 0.5
	## Seconds to the next damage tick.
	var tick_left: float = 0.5
	## Damage per tick to every enemy inside.
	var damage: float = 0.0
	## Damage-source tag.
	var source: String = ""

## Patch look: a Hellhound fire-trail patch.
const KIND_FIRE: int = 0
## Patch look: an Ossuary Engine field of burning bone shards.
const KIND_SHARD: int = 1
## Safety cap on boulders in flight (not a balance number: 3 catapults x 3
## boulders a volley stay far below it).
const MAX_BOULDERS: int = 48
## Safety cap on burning patches (not a balance number).
const MAX_PATCHES: int = 160
## Ember colour of fire patches and shard glow.
const EMBER := Color(1.0, 0.42, 0.12)
## Hellfire colour (the hot core of a fire patch).
const HELLFIRE := Color(1.0, 0.72, 0.28)

## Owning run.
var game: Game
## Boulder pool (active and free entries).
var _boulders: Array[Boulder] = []
## Patch pool (active and free entries).
var _patches: Array[Patch] = []
## Boulders in flight right now.
var _flying: int = 0
## Patches burning right now.
var _burning: int = 0
## True if something was drawn last frame (one final redraw clears it).
var _drew: bool = false
## Child node that draws the boulders above the bodies.
var _air: Node2D = null
## Reusable enemy query buffer.
var _buf: Array = []
## Reusable victim list (damage may trigger kill hooks).
var _victims: Array[Enemy] = []


func _ready() -> void:
	z_index = -5
	_air = Node2D.new()
	_air.z_index = 8  # Relative: above the bodies and the projectiles.
	_air.draw.connect(_draw_air)
	add_child(_air)


# =====================================================================================
# Spawning
# =====================================================================================

## Launches a boulder from `from` to `to` (see the header). `shard` holds the
## Ossuary Engine shard field ({"radius", "life", "tick", "damage"}) or is
## empty. Returns false when the safety cap dropped it.
func launch_boulder(from: Vector2, to: Vector2, flight: float, arc: float, damage: float, radius: float,
		knockback: float, shake: float, source: String, shard: Dictionary) -> bool:
	var b := _free_boulder()
	if b == null:
		game.stat_add("hazards_dropped", 1.0)
		return false
	b.active = true
	b.generation += 1
	b.from = from
	b.to = to
	b.t = 0.0
	b.flight = maxf(flight, 0.05)
	b.arc = arc
	b.damage = damage
	b.radius = radius
	b.knockback = knockback
	b.shake = shake
	b.source = source
	b.shard_radius = float(shard.get("radius", 0.0))
	b.shard_life = float(shard.get("life", 0.0))
	b.shard_tick = float(shard.get("tick", 0.5))
	b.shard_damage = float(shard.get("damage", 0.0))
	_flying += 1
	queue_redraw()
	return true


## Adds a damaging ground patch of look `kind` (KIND_FIRE / KIND_SHARD).
## Returns false when the safety cap dropped it.
func add_patch(kind: int, pos: Vector2, radius: float, life: float, tick: float, damage: float, source: String) -> bool:
	var p := _free_patch()
	if p == null:
		game.stat_add("hazards_dropped", 1.0)
		return false
	p.active = true
	p.kind = kind
	p.pos = pos
	p.radius = radius
	p.life = life
	p.life_total = maxf(life, 0.01)
	p.tick = maxf(tick, 0.05)
	p.tick_left = p.tick * 0.5  # The first tick comes quickly after it lands.
	p.damage = damage
	p.source = source
	_burning += 1
	queue_redraw()
	return true


## A free pooled boulder (grown up to MAX_BOULDERS), or null at the cap.
func _free_boulder() -> Boulder:
	for b in _boulders:
		if not b.active:
			return b
	if _boulders.size() >= MAX_BOULDERS:
		return null
	var nb := Boulder.new()
	_boulders.append(nb)
	return nb


## A free pooled patch (grown up to MAX_PATCHES), or null at the cap.
func _free_patch() -> Patch:
	for p in _patches:
		if not p.active:
			return p
	if _patches.size() >= MAX_PATCHES:
		return null
	var np := Patch.new()
	_patches.append(np)
	return np


# =====================================================================================
# Per-tick update
# =====================================================================================

## Advances boulders and patches (HordeDirector.step).
func step(delta: float) -> void:
	if _flying > 0:
		for b in _boulders:
			if not b.active:
				continue
			b.t += delta
			if b.t >= b.flight:
				b.active = false
				_flying -= 1
				_land(b)
	if _burning > 0:
		for p in _patches:
			if not p.active:
				continue
			p.life -= delta
			p.tick_left -= delta
			if p.tick_left <= 0.0:
				p.tick_left += p.tick
				_burn(p)
			if p.life <= 0.0:
				p.active = false
				_burning -= 1
	if _flying > 0 or _burning > 0 or _drew:
		queue_redraw()
		_air.queue_redraw()


## Fills `_victims` with the living enemies whose body is within `r` px of
## `pos` (body edges count half).
func _collect(pos: Vector2, r: float) -> void:
	_victims.clear()
	game.enemy_grid.query(pos, r + ProjectileManager.MAX_BODY_RADIUS, _buf)
	for e: Enemy in _buf:
		if e.active and e.position.distance_to(pos) <= r + e.radius * 0.5:
			_victims.append(e)


## A boulder lands: splash damage and knockback, effects, the shard field.
func _land(b: Boulder) -> void:
	_collect(b.to, b.radius)
	var hits := 0  # Enemies hit.
	for e in _victims:
		if not e.active:
			continue
		var away := e.position - b.to  # Push direction.
		if not e.is_structure:
			e.knockback += (away / away.length() if away.length() > 0.01 else Vector2.UP) * b.knockback / maxf(e.mass, 0.1)
		var structure := e.is_structure  # Read before the hit (the enemy may be pooled by it).
		var dealt := game.combat.damage_enemy(e, b.damage, b.source, -1, CombatResolver.FROM_ABOVE)  # Act IV, the Shores of Ilion: an arcing hit from above (the Legionary's testudo; nothing changes off Act IV).
		if structure:
			game.stat_add("catapult_structure_dmg", dealt)
		hits += 1
	game.stat_add("catapult_boulder_hits", float(hits))
	# Bullet heaven pass: the boulder bursts into bone fragments (the Ossuary Engine's burn).
	game.volleys.on_special(null, b.to, b.to + Vector2.RIGHT, b.damage, "corpse_catapult", "ossuary_engine" if b.source == "ossuary_engine" else "")
	game.effects.ring(b.to, b.radius, Palette.BONE, 0.35)
	game.effects.ring(b.to, b.radius * 0.55, Palette.CORPSE_FLESH, 0.3)
	Juice.fx.burst(b.to, Palette.BONE, Palette.CORPSE_FLESH, 12, b.radius * 2.0, 0.5, 3.0)
	if b.shake > 0.0:
		game.shake(b.shake)
	Sfx.play("catapult_impact", b.to)
	if b.shard_radius > 0.0 and b.shard_life > 0.0:
		if add_patch(KIND_SHARD, b.to, b.shard_radius, b.shard_life, b.shard_tick, b.shard_damage, "ossuary_shards"):
			game.stat_add("ossuary_shard_fields", 1.0)


## One damage tick of patch `p` on every enemy inside it.
func _burn(p: Patch) -> void:
	_collect(p.pos, p.radius)
	for e in _victims:
		if not e.active:
			continue
		var structure := e.is_structure  # Read before the hit (the enemy may be pooled by it).
		var dealt := game.combat.damage_enemy(e, p.damage, p.source)
		if structure and p.kind == KIND_SHARD:
			game.stat_add("catapult_structure_dmg", dealt)


# =====================================================================================
# Drawing
# =====================================================================================

## Ground layer: patches, then each boulder's landing telegraph and shadow.
func _draw() -> void:
	_drew = _flying > 0 or _burning > 0
	if _burning > 0:
		for p in _patches:
			if p.active:
				var k := clampf(p.life / p.life_total, 0.0, 1.0)  # 1 fresh .. 0 gone.
				if p.kind == KIND_FIRE:
					WarbandGlyphs.draw_fire_patch(self, p.pos, p.radius, k)
				else:
					WarbandGlyphs.draw_shard_field(self, p.pos, p.radius, k)
	if _flying > 0:
		for b in _boulders:
			if b.active:
				var k := clampf(b.t / b.flight, 0.0, 1.0)  # Flight progress.
				draw_circle(b.to, b.radius, Color(Palette.BONE, 0.08))
				draw_circle(b.to, b.radius * k, Color(Palette.CORPSE_FLESH, 0.16))
				draw_arc(b.to, b.radius, 0.0, TAU, 32, Color(Palette.BONE, 0.7), 1.5)
				var ground := b.from.lerp(b.to, k)  # Shadow under the boulder.
				var h := 4.0 * b.arc * k * (1.0 - k)  # Height above the ground (px).
				draw_circle(ground, 6.0 - h * 0.04, Color(0, 0, 0, 0.35 - h * 0.003))


## Air layer (`_air`): the boulders on their arcs.
func _draw_air() -> void:
	if _flying <= 0:
		return
	for b in _boulders:
		if b.active:
			var k := clampf(b.t / b.flight, 0.0, 1.0)  # Flight progress.
			var ground := b.from.lerp(b.to, k)
			var h := 4.0 * b.arc * k * (1.0 - k)  # Height above the ground (px).
			WarbandGlyphs.draw_boulder(_air, ground - Vector2(0, h), 6.0 + h * 0.03, k * 9.0, b.shard_radius > 0.0)
