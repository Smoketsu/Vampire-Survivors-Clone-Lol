## ProvinceHazards — the world hazards of the Burning Province's kinds and stage
## (Act V, Stage 13; GDD §15.0 "The Burning Province (Act V phase 2)"), owned
## by EnemyDirector (province_hazards(): created on first use on ANY stage, so
## a Province kind forced elsewhere with --spawn= brings its fire and smoke)
## and stepped by it every tick. Two kinds of ground patch, pooled:
##   FIRE  — a burning patch (Shuten-dōji's burst sake barrels, the Burning
##           Village's flares beside its houses): every `tick` s it burns each
##           necromancer inside (CombatResolver.damage_player()), each summon
##           inside (damage_unit()) and, when it has enemy damage (the village
##           fires burn every body), each enemy inside (damage_enemy()). Drawn
##           as the Hellhound fire patch textures (WarbandGlyphs, AoeArt).
##   SMOKE — a smoke cloud (a Kunoichi's smoke bomb, Kage's smoke fields): it
##           BLINDS every summon inside through THE one summon blind path
##           (CombatResolver.blind_unit()), at once (`blind_now` s) and, for a
##           field, again every `check` s (`blind` s each time). Drawn as soft
##           smoke discs above the bodies (a child layer), below the night.
## Damage is fixed when a patch is laid (the layer passes it already scaled by
## the time scaling and its own hit multiplier). Deterministic: no RNG, pooled
## records reused in order. Nothing is drawn headless. Stats: province_fires,
## province_fire_burns_player / _summon / _enemy, province_smokes,
## province_smoke_blinds, province_hazards_dropped.
class_name ProvinceHazards
extends Node2D

## One ground patch (pooled).
class Patch:
	extends RefCounted
	## True while it burns / hangs.
	var active: bool = false
	## KIND_FIRE or KIND_SMOKE.
	var kind: int = 0
	## World centre (px).
	var pos: Vector2 = Vector2.ZERO
	## Radius (px).
	var radius: float = 30.0
	## Seconds left.
	var life: float = 0.0
	## Seconds it lasts in all (its look fades with life / life_total).
	var life_total: float = 1.0
	## Seconds between two burns / blinds (0 = never again after the first).
	var tick: float = 0.5
	## Seconds until the next burn / blind.
	var tick_cd: float = 0.0
	## Damage of one burn to a necromancer.
	var dmg_player: float = 0.0
	## Damage of one burn to a summon.
	var dmg_summon: float = 0.0
	## Damage of one burn to an enemy (0 = enemies are not burned).
	var dmg_enemy: float = 0.0
	## Seconds of blind each check of a smoke field.
	var blind: float = 0.0
	## Damage / blind source tag.
	var source: String = ""

## Look of a burning patch.
const KIND_FIRE: int = 0
## Look of a smoke cloud.
const KIND_SMOKE: int = 1
## Safety cap on patches at once (beyond it a new one is dropped and counted).
const MAX_PATCHES: int = 64

## Owning run.
var game: Game
## Patch pool (active and free entries).
var _patches: Array[Patch] = []
## Fire patches burning now.
var fires: int = 0
## Smoke clouds hanging now.
var smokes: int = 0
## True if something was drawn last frame (one final redraw clears it).
var _drew: bool = false
## True when this run draws (false headless).
var _draws: bool = false
## Child layer that draws the smoke above the bodies.
var _air: Node2D = null
## Reusable query buffer.
var _tmp: Array = []
## Reusable victim list (a burn may trigger kill hooks that query again).
var _victims: Array[Enemy] = []


func _ready() -> void:
	z_index = -4  # The fire lies on the ground, under the bodies.
	_draws = DisplayServer.get_name() != "headless"
	_air = Node2D.new()
	_air.z_index = 21  # Relative (-4 + 21 = 17): above the bodies, under the night's darkness (18).
	_air.draw.connect(_draw_air)
	add_child(_air)


# =====================================================================================
# Laying patches
# =====================================================================================

## Lays a fire patch at `pos` (see the header). Returns false when the safety
## cap dropped it.
func add_fire(pos: Vector2, radius: float, life: float, tick: float, dmg_player: float, dmg_summon: float,
		dmg_enemy: float, source: String) -> bool:
	var p := _take()
	if p == null:
		return false
	p.kind = KIND_FIRE
	p.pos = pos
	p.radius = radius
	p.life = life
	p.life_total = maxf(life, 0.01)
	p.tick = tick
	p.tick_cd = tick * 0.5  # The first burn comes quickly.
	p.dmg_player = dmg_player
	p.dmg_summon = dmg_summon
	p.dmg_enemy = dmg_enemy
	p.blind = 0.0
	p.source = source
	fires += 1
	game.stat_add("province_fires", 1.0)
	return true


## Lays a smoke cloud at `pos` (see the header): every summon inside is
## blinded `blind_now` s at once; with `check` > 0 it blinds again every
## `check` s for `blind` s while it hangs. Returns how many summons the first
## blind took (or -1 when the safety cap dropped it).
func add_smoke(pos: Vector2, radius: float, life: float, blind_now: float, check: float, blind: float, source: String) -> int:
	var p := _take()
	if p == null:
		return -1
	p.kind = KIND_SMOKE
	p.pos = pos
	p.radius = radius
	p.life = life
	p.life_total = maxf(life, 0.01)
	p.tick = check
	p.tick_cd = check
	p.dmg_player = 0.0
	p.dmg_summon = 0.0
	p.dmg_enemy = 0.0
	p.blind = blind
	p.source = source
	smokes += 1
	game.stat_add("province_smokes", 1.0)
	return _blind_in(p, blind_now)


## A free pooled record marked active (null at the safety cap).
func _take() -> Patch:
	for p in _patches:
		if not p.active:
			p.active = true
			return p
	if _patches.size() >= MAX_PATCHES:
		game.stat_add("province_hazards_dropped", 1.0)
		return null
	var n := Patch.new()
	n.active = true
	_patches.append(n)
	return n


# =====================================================================================
# The step
# =====================================================================================

## Per-tick update (EnemyDirector): age every patch, burn and blind on its tick.
func step(delta: float) -> void:
	if fires + smokes == 0:
		if _drew:
			queue_redraw()
			_air.queue_redraw()
		return
	for p in _patches:
		if not p.active:
			continue
		p.life -= delta
		if p.life <= 0.0:
			p.active = false
			if p.kind == KIND_FIRE:
				fires -= 1
			else:
				smokes -= 1
			continue
		if p.tick <= 0.0:
			continue
		p.tick_cd -= delta
		if p.tick_cd > 0.0:
			continue
		p.tick_cd += p.tick
		if p.kind == KIND_FIRE:
			_burn(p)
		else:
			_blind_in(p, p.blind)
	if _draws:
		queue_redraw()
		_air.queue_redraw()


## One burn of fire patch `p` on every body inside it.
func _burn(p: Patch) -> void:
	var g := game
	for pl in g.all_players:  # (Co-op: every necromancer inside.)
		if p.dmg_player > 0.0 and not pl.dead and pl.position.distance_to(p.pos) <= p.radius + pl.radius * 0.5:
			g.combat.damage_player(p.dmg_player, p.source, pl)
			g.stat_add("province_fire_burns_player", 1.0)
	if p.dmg_summon > 0.0:
		g.ally_grid.query(p.pos, p.radius + UnitData.MAX_BLOCK_RADIUS, _tmp)
		for u: SummonedUnit in _tmp:
			if not u.active or u.airborne or u.state == SummonedUnit.State.SPAWNING or u.state == SummonedUnit.State.DEAD:
				continue
			if u.position.distance_to(p.pos) > p.radius + u.radius * 0.5:
				continue
			g.combat.damage_unit(u, p.dmg_summon, p.source)
			g.stat_add("province_fire_burns_summon", 1.0)
	if p.dmg_enemy > 0.0:
		g.enemy_grid.query(p.pos, p.radius + ProjectileManager.MAX_BODY_RADIUS, _tmp)
		_victims.clear()
		for e: Enemy in _tmp:
			if e.active and not e.is_boss and not e.floating and not e.is_structure and e.position.distance_to(p.pos) <= p.radius + e.radius * 0.5:
				_victims.append(e)
		for e in _victims:
			if e.active:
				g.combat.damage_enemy(e, p.dmg_enemy, p.source)
				g.stat_add("province_fire_burns_enemy", 1.0)


## Blinds every summon inside smoke patch `p` for `seconds` s (THE one summon
## blind path); returns how many it took.
func _blind_in(p: Patch, seconds: float) -> int:
	if seconds <= 0.0:
		return 0
	var n := 0
	game.ally_grid.query(p.pos, p.radius + UnitData.MAX_BLOCK_RADIUS, _tmp)
	for u: SummonedUnit in _tmp:
		if not u.active or u.position.distance_to(p.pos) > p.radius + u.radius * 0.5:
			continue
		if game.combat.blind_unit(u, seconds, p.source) > 0.0:
			n += 1
	game.stat_add("province_smoke_blinds", float(n))
	return n


# =====================================================================================
# Queries (autopilot)
# =====================================================================================

## Autopilot hint: a push out of the nearest fire patch at `p` (zero when none).
func danger_push(p: Vector2) -> Vector2:
	for f in _patches:
		if f.active and f.kind == KIND_FIRE:
			var away := p - f.pos
			if away.length() < f.radius + 18.0:
				return away.normalized() if away.length() > 0.1 else Vector2.RIGHT
	return Vector2.ZERO


# =====================================================================================
# Drawing (visual only)
# =====================================================================================

## Ground layer: the fire patches (the Hellhound fire textures).
func _draw() -> void:
	_drew = fires + smokes > 0
	if not _draws or fires == 0:
		return
	for p in _patches:
		if p.active and p.kind == KIND_FIRE:
			WarbandGlyphs.draw_fire_patch(self, p.pos, p.radius, clampf(p.life / p.life_total, 0.0, 1.0))


## Air layer: the smoke clouds (soft discs, a texture: no polygon per frame).
func _draw_air() -> void:
	if not _draws or smokes == 0:
		return
	for p in _patches:
		if p.active and p.kind == KIND_SMOKE:
			ProvinceGlyphs.draw_smoke(_air, p.pos, p.radius, clampf(p.life / p.life_total, 0.0, 1.0), game.elapsed)
