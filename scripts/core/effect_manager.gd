## EffectManager — pools and updates Effect nodes (GDD §36 EffectManager,
## §38 "Pool common ... effects"). Cosmetic effects are dropped when the
## active count hits MAX_COSMETIC so huge fights never spike; telegraphs are
## gameplay-critical and are always shown.
## Reduced effects and the adaptive quality (AdaptiveQuality.tier(), EffectsData):
## a cosmetic effect spawned while EffectsData.TIER_VISIBLE_EFFECTS of the tier
## or more are live is still pooled, stepped and counted exactly as on Full, but
## not drawn (purely visual).
class_name EffectManager
extends Node2D

## Active cosmetic effects above which new cosmetic effects are skipped.
const MAX_COSMETIC: int = 220  # TUNING (not in GDD)

## Effects currently playing.
var active: Array[Effect] = []
## Idle effects ready for reuse.
var _pool: Array[Effect] = []
## Total Effect nodes ever created (debug: pool health).
var created: int = 0
## Art-only animations without a drawn shape (bolt hits, level-up,
## evolution): batched in one node, outside the pool and its counts (burst()).
var bursts: AnimBursts = null


func _ready() -> void:
	bursts = AnimBursts.new()
	add_child(bursts)


## Advances all effects and returns finished ones to the pool.
func step(delta: float) -> void:
	bursts.step(delta)
	var i := 0
	while i < active.size():
		var e := active[i]
		if e.step(delta):
			i += 1
		else:
			active[i] = active[active.size() - 1]
			active.pop_back()
			_pool.append(e)


## Takes an effect from the pool (or creates one) and starts it. Returns it
## (null when a cosmetic effect was skipped at MAX_COSMETIC).
func _spawn(kind: Effect.Kind, pos: Vector2, color: Color, size: float, duration: float, vec: Vector2 = Vector2.RIGHT, width: float = 2.0, critical: bool = false) -> Effect:
	if not critical and active.size() >= MAX_COSMETIC:
		return null
	var e: Effect
	if _pool.is_empty():
		e = Effect.new()
		add_child(e)
		created += 1
	else:
		e = _pool.pop_back()
	e.start(kind, pos, color, size, duration, vec, width)
	var tier := AdaptiveQuality.tier()  # Visual tier (Reduced effects or the adaptive quality).
	if not critical and tier > 0 and active.size() >= int(EffectsData.TIER_VISIBLE_EFFECTS[tier]):
		e.visible = false  # Lower visual tier: lives and counts as usual, just not drawn.
	active.append(e)
	return e


## Play time (s) of an effect that may show animation `anim`: its AnimData
## duration when the art exists, else `fallback` (the drawn shape's time).
## The AnimData durations of the hooked effects equal their code durations,
## so effect lifetimes (and the autotest's effect counts) do not depend on
## whether the art is present. Purely visual.
func _anim_time(anim: String, fallback: float) -> float:
	if anim != "" and SpriteBank.has_anim(anim):
		return float(AnimData.ANIMS.get(anim, {}).get("duration", AnimData.DEFAULT_DURATION))
	return fallback


## Tags a just-spawned effect `e` (null when skipped at MAX_COSMETIC) with
## animation `anim`: Effect._draw() plays it when its art exists, else draws
## the effect's own shape.
func _tag(e: Effect, anim: String) -> void:
	if e != null:
		e.anim_id = anim


## Death pop: expanding ring + bone shards (also stands in for a corpse).
## With `anim` (an AnimData id: "enemy_death", "undead_death") and its art
## present, the animation plays instead.
func pop(pos: Vector2, color: Color, size: float, anim: String = "") -> void:
	_tag(_spawn(Effect.Kind.POP, pos, color, size, _anim_time(anim, 0.35)), anim)


## Melee swing arc facing `dir`.
func slash(pos: Vector2, dir: Vector2, color: Color, size: float) -> void:
	_spawn(Effect.Kind.SLASH, pos, color, size, 0.15, dir)


## Expanding filled ring (Shadow Blast, mage explosions). With `anim` (an
## AnimData id) and its art present, the animation plays instead, for its own
## AnimData duration.
func ring(pos: Vector2, radius: float, color: Color, duration: float = 0.3, anim: String = "") -> void:
	_tag(_spawn(Effect.Kind.RING, pos, color, radius, _anim_time(anim, duration)), anim)


## A drawn ring that shows only while animation `cover`'s art is missing
## (the inner ring under the Abyssal burst and the Soul Nova, which their
## strips replace). It is spawned and lives exactly like ring() either way,
## so effect counts do not depend on the art; it just draws nothing.
func ring_under(pos: Vector2, radius: float, color: Color, duration: float, cover: String) -> void:
	var e := _spawn(Effect.Kind.RING, pos, color, radius, duration)
	if e != null:
		e.hide_with = cover


## Plays art-only animation `anim` once at `pos` (or on `follow` + `pos`),
## for a gameplay radius of `radius` px (AnimBursts; nothing without the art).
func burst(pos: Vector2, radius: float, anim: String, follow: Node2D = null) -> void:
	bursts.play(pos, radius, anim, follow)


## Straight beam from `a` to `b` (priest / chaplain heals).
func beam(a: Vector2, b: Vector2, color: Color) -> void:
	_spawn(Effect.Kind.BEAM, a, color, 0.0, 0.25, b - a, 2.0)


## Summon emergence / recall ring. With `anim` (an AnimData id:
## "summon_rise") and its art present, the animation plays instead.
func spawn_ring(pos: Vector2, color: Color, anim: String = "") -> void:
	_tag(_spawn(Effect.Kind.SPAWN, pos, color, 12.0, _anim_time(anim, 0.5)), anim)


## Boss ground-AoE warning circle shown for `duration` seconds. `owner`
## (optional) is the attacker: the telegraph pauses while it is frozen.
func telegraph_circle(pos: Vector2, radius: float, duration: float, owner: Enemy = null) -> void:
	_set_owner(_spawn(Effect.Kind.TELEGRAPH_CIRCLE, pos, Palette.GOLD, radius, duration, Vector2.RIGHT, 2.0, true), owner)
	Sfx.play("boss_telegraph", pos)


## Boss charge-lane warning from `from` to `to`, `lane_width` px wide.
## `owner` (optional) is the attacker: the telegraph pauses while it is frozen.
func telegraph_line(from: Vector2, to: Vector2, lane_width: float, duration: float, owner: Enemy = null) -> void:
	_set_owner(_spawn(Effect.Kind.TELEGRAPH_LINE, from, Palette.GOLD, 0.0, duration, to - from, lane_width, true), owner)
	Sfx.play("boss_telegraph", from)


## Boss sector warning at `pos` facing `dir`: `radius` px, `half_angle` rad
## each side, shown for `duration` s (Marshal Vael's Radiant Cleave).
## `owner` (optional) is the attacker: the telegraph pauses while it is frozen.
func telegraph_cone(pos: Vector2, dir: Vector2, radius: float, half_angle: float, duration: float, owner: Enemy = null) -> void:
	_set_owner(_spawn(Effect.Kind.TELEGRAPH_CONE, pos, Palette.GOLD, radius, duration, dir, half_angle, true), owner)
	Sfx.play("boss_telegraph", pos)


## Ties telegraph `e` to the enemy `owner` (Stasis pause, Effect.step()).
func _set_owner(e: Effect, owner: Enemy) -> void:
	if e == null or owner == null:
		return
	e.owner_enemy = owner
	e.owner_gen = owner.generation


## Abyssal Detonation first hit: a dark vortex collapsing toward `pos`. With
## `anim` ("abyssal_detonation") and its art present, the animation plays instead.
func abyss(pos: Vector2, radius: float, anim: String = "") -> void:
	_tag(_spawn(Effect.Kind.ABYSS, pos, Palette.VIOLET, radius, _anim_time(anim, 0.4)), anim)


## Big holy impact burst (Hammerfall landing, boss death). With `anim`
## ("holy_impact") and its art present, the animation plays instead.
func impact(pos: Vector2, radius: float, color: Color, anim: String = "") -> void:
	_tag(_spawn(Effect.Kind.IMPACT, pos, color, radius, _anim_time(anim, 0.4), Vector2.RIGHT, 2.0, true), anim)
	Juice.impact(pos, radius)
