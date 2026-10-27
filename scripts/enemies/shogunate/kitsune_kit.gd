## KitsuneKit — the kit of the Kitsune (SunRoadEnemyData "kitsune"; Act V, the
## Road to the Sun; GDD §15.0 "The Road to the Sun (Act V phase 2)";
## owner-approved proposal: "Kitsune | Support (night, figure style) | Fox-fire
## illusions: decoy enemies your summons waste attacks on | Area damage reveals
## them"). NIGHT (the Sun's Course keeps her to the night). She advances with
## the night host like every enemy (the shared melee AI between conjurings);
## when her conjuring is ready and the necromancer is within decoy_trigger px,
## she stands decoy_windup s with fox-fire in her raised hands, then conjures
## decoy_count FOX-FIRE ILLUSIONS around her (SunRoadEnemyData "fox_fire",
## FoxFireKit): copies of her that draw the summons' blows. She keeps at most
## decoy_max of them (the oldest fades first) and they all fade when she dies.
## Every illusion goes through EnemyDirector.spawn_at() (the hard cap
## respected) and leaves through EnemyDirector.despawn() (no kill, no XP).
## No RNG: the illusions stand on a fixed ring around her, the first cooldown
## staggered by the think slot. Stats: kitsune_conjures, fox_fire_conjured.
class_name KitsuneKit
extends ShogunateKit

## Phase: her hands are raised (the windup).
const CONJURING: int = 1

## Seconds until she may conjure again.
var _cd: float = 0.0
## Her living illusions: [Enemy, generation] each, oldest first.
var decoys: Array = []


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	decoys.clear()
	_cd = first_cd(e, float(def.get("decoy_every", 7.0)) * 0.5)


func physics(e: Enemy, delta: float) -> bool:
	_cd -= delta
	if phase == CONJURING:
		phase_time += delta
		hold(e)
		if phase_time >= float(d["decoy_windup"]):
			_conjure(e)
			set_phase(e, IDLE)
		return true
	if _cd > 0.0:
		return false
	if e.position.distance_to(e.game.player.position) > float(d["decoy_trigger"]):
		return false
	_cd = float(d["decoy_every"])
	set_phase(e, CONJURING)
	hold(e)
	return true


## Conjures her illusions on a ring around her (the oldest fade past decoy_max).
func _conjure(e: Enemy) -> void:
	var g := e.game
	_prune()
	var n := int(d["decoy_count"])
	while not decoys.is_empty() and decoys.size() + n > int(d["decoy_max"]):
		var old: Enemy = decoys[0][0]
		if old.kit is FoxFireKit:
			(old.kit as FoxFireKit).dispel(old, "replaced")
		decoys.remove_at(0)
	var spread := float(d["decoy_spread"])
	var a0 := (g.player.position - e.position).angle()  # The first one stands toward the necromancer.
	var made := 0
	for i in n:
		if g.enemies.regular_alive() >= g.enemies.hard_cap():
			break
		var at := e.position + Vector2.from_angle(a0 + TAU * float(i) / float(maxi(1, n))) * spread
		var f := g.enemies.spawn_at(SunRoadEnemyData.FOX_FIRE, at, false)
		if f == null:
			continue
		if f.kit is FoxFireKit:
			(f.kit as FoxFireKit).bind(f, e)
		decoys.append([f, f.generation])
		made += 1
	g.effects.spawn_ring(e.position, Palette.SHOGUN_SAKURA_LIGHT)
	rules(e).play_sound("smoke_puff", e.position)
	g.stat_add("kitsune_conjures", 1.0)
	g.stat_add("fox_fire_conjured", float(made))


## Drops the illusions that are gone.
func _prune() -> void:
	var i := decoys.size() - 1
	while i >= 0:
		var f: Enemy = decoys[i][0]
		if not f.active or f.generation != int(decoys[i][1]):
			decoys.remove_at(i)
		i -= 1


## She is gone: her illusions fade with her.
func on_deactivate(e: Enemy) -> void:
	super.on_deactivate(e)
	_prune()
	for rec: Array in decoys:
		var f: Enemy = rec[0]
		if f.kit is FoxFireKit:
			(f.kit as FoxFireKit).dispel(f, "caster")
	decoys.clear()


func is_busy() -> bool:
	return phase == CONJURING


## Fox-fire in her raised hands while she conjures. Visual only.
func draw_over(e: Enemy, ci: CanvasItem) -> void:
	if phase != CONJURING:
		return
	unmirror(e, ci)
	var k := clampf(phase_time / maxf(0.01, float(d["decoy_windup"])), 0.0, 1.0)  # 0 .. the conjuring.
	var col := Color(SunRoadGlyphs.FOX_FIRE, 0.5 + 0.4 * k)
	SpriteBank.draw_disc(ci, Vector2(-e.radius * 0.7, -e.radius * 1.2), 2.0 + 2.5 * k, col)
	SpriteBank.draw_disc(ci, Vector2(e.radius * 0.7, -e.radius * 1.2), 2.0 + 2.5 * k, col)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
