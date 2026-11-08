## GunneryMateKit — the kit of the Gunnery Mate (CorsairEnemyData
## "gunnery_mate"; Act X, the Black Tide, the Treasure Galleon's block; a woman
## in the figure-redesign style; GDD §15.0 "The Treasure Galleon (Act X phase
## 2)"; brief: "arcing grenadoes on a landing circle that ignore the ring").
## A "ranged" walker (the shared AI keeps her at her attack range); when her
## attack is due (fire_ranged()) she LOBS a grenado instead of a shot: its
## landing point is the nearest standing necromancer within grenado "reach"
## px (over the Bone Ring, which never blocks an arc), else her target; a
## landing circle (EffectManager.telegraph_circle(), owned by her) shows for
## grenado "flight" s, then it bursts there through THE POWDER BLAST
## (CorsairRules.powder_blast(): both sides, everyone knocked grenado "push"
## px; her own crew at the rail drowns). On a deck stage the grenado is
## handed to CorsairRules.lob() at once, so it lands even if she falls (a
## thrown grenado is out of her hands); off Act X (no deck: the rules do not
## step) the kit lands it itself, one at a time, and it fizzles if she falls.
## Determinism: no RNG (targets in the players' order).
## Stats: gunnery_lobs, gunnery_grenadoes (burst), gunnery_fizzled (off Act X).
class_name GunneryMateKit
extends CorsairKit

## px the autotest bot keeps from a live landing circle beyond its radius.
const DANGER_REACH: float = 18.0  # TUNING (not in GDD) autotest hint only

## True while a grenado is in the air.
var _flying: bool = false
## Where it lands (world px).
var _at: Vector2 = Vector2.ZERO
## Game time (s) it lands.
var _land_t: float = 0.0


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	_flying = false
	_land_t = 0.0


func on_deactivate(e: Enemy) -> void:
	if _flying:
		e.game.stat_add("gunnery_fizzled", 1.0)
	_flying = false
	super.on_deactivate(e)


## Her attack is a lob (see the header): true (the kit fired it).
func fire_ranged(e: Enemy, t: Node2D, _dir: Vector2, _dmg: float) -> bool:
	if _flying:
		return true  # One grenado at a time: the attack is spent waiting.
	var g: Dictionary = d.get("grenado", {})
	var at := t.position
	var best := INF
	for pl in e.game.all_players:
		var dist := pl.position.distance_to(e.position)
		if not pl.dead and dist <= float(g.get("reach", 260.0)) and dist < best:
			best = dist
			at = pl.position
	if best < INF and e.game.ultimates.player_untargetable():
		at = t.position
	var r := rules(e)
	if r.enabled:
		r.lob(at, float(g.get("flight", 1.1)), g)  # Lands whatever becomes of her.
		_at = at
		_land_t = e.game.elapsed + float(g.get("flight", 1.1))
	else:
		_at = at
		_land_t = e.game.elapsed + float(g.get("flight", 1.1))
		_flying = true
		e.game.effects.telegraph_circle(_at, float(g.get("radius", 46.0)), float(g.get("flight", 1.1)), e)
	e.motion_lunge(Vector2.ZERO, MotionData.POWER_CAST)
	e.game.stat_add("gunnery_lobs", 1.0)
	rules(e).play_sound("fuse_hiss", e.position, 0.3)
	return true


func physics(e: Enemy, delta: float) -> bool:
	if _flying and e.game.elapsed >= _land_t:
		_flying = false
		var g: Dictionary = d.get("grenado", {})
		rules(e).powder_blast(_at, g, null)
		e.game.stat_add("gunnery_grenadoes", 1.0)
	return super.physics(e, delta)


## The landing circle's danger (autotest hint): out of it while it falls
## (off Act X; on a deck CorsairRules.lob_danger() has every grenado).
func danger_push(_e: Enemy, p: Vector2) -> Vector2:
	if not _flying:
		return Vector2.ZERO
	var reach := float((d.get("grenado", {}) as Dictionary).get("radius", 46.0)) + DANGER_REACH
	var off := p - _at
	var dist := off.length()
	if dist >= reach:
		return Vector2.ZERO
	return (off / dist if dist > 0.01 else Vector2.RIGHT) * (1.0 - dist / reach) * 2.0


## The grenado arcing to its mark while it is in the air (a dark ball with a
## lit fuse; visual only).
func draw_over(e: Enemy, ci: CanvasItem) -> void:
	if e.game.elapsed >= _land_t:
		return
	var g: Dictionary = d.get("grenado", {})
	var span := maxf(0.01, float(g.get("flight", 1.1)))
	var k := clampf(1.0 - (_land_t - e.game.elapsed) / span, 0.0, 1.0)
	var to := _at - e.position
	unmirror(e, ci)
	var p := to * k + Vector2(0.0, -60.0 * 4.0 * k * (1.0 - k))
	SpriteBank.draw_disc(ci, p, 4.0, Palette.CORSAIR_INK)
	SpriteBank.draw_disc(ci, p + Vector2(1.5, -3.0), 1.8, Palette.CORSAIR_LANTERN_LIGHT)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
