## BoatswainKit — the kit of the Boatswain (CorsairEnemyData "boatswain"; Act
## X, the Black Tide; GDD §15.0 "The Smuggler's Cutter (Act X phase 2)";
## owner-approved proposal: "Bellow: +20% move speed and a short shield to crew
## within 200 px | Priority target"). A male support boarder: the shared melee
## AI drives him. Every bellow "every" s (the first after half of it) he stops
## and whistles (windup s), then BELLOWS: every OTHER living, non-structure
## enemy within radius px moves speed x faster for time s (Enemy.apply_buff(),
## the one aura buff path) and gains a shield of shield x its max HP for time s
## (Enemy.holy_shield / holy_shield_time, the one enemy shield path: a larger
## shield already on it is kept). Also used by Bosun Gorran's bellow
## (bellow_at(), the one bellow).
## Determinism: no RNG. Stats: boatswain_bellows, boatswain_buffed.
class_name BoatswainKit
extends CorsairKit

## Phase: he whistles before the bellow.
const WINDUP: int = 1

## Seconds until his next bellow.
var bellow_cd: float = 0.0


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	bellow_cd = first_cd(e, float((d.get("bellow", {}) as Dictionary).get("every", 8.0)) * 0.5)


func physics(e: Enemy, delta: float) -> bool:
	if super.physics(e, delta):
		return true
	var b: Dictionary = d.get("bellow", {})
	bellow_cd -= delta
	if phase == WINDUP:
		phase_time += delta
		hold(e)
		if phase_time >= float(b.get("windup", 0.5)):
			bellow_at(e, b)
			set_phase(e, IDLE)
		return true
	if bellow_cd <= 0.0:
		bellow_cd = float(b.get("every", 8.0))
		set_phase(e, WINDUP)
		rules(e).play_sound("bosun_whistle", e.position, 0.6)
		return true
	return false


## THE BELLOW of `e` with numbers `b` ({radius, speed, shield, time}; shield 0
## = speed only): every other living crewman in reach is hastened and shielded.
static func bellow_at(e: Enemy, b: Dictionary) -> void:
	var g := e.game
	var r := float(b.get("radius", 200.0))
	var spd := float(b.get("speed", 1.2))
	var share := float(b.get("shield", 0.0))
	var t := float(b.get("time", 4.0))
	var tmp: Array = []
	var n := 0
	g.enemy_grid.query(e.position, r + ProjectileManager.MAX_BODY_RADIUS, tmp)
	for o: Enemy in tmp:
		if o == e or not o.active or o.is_structure or o.is_boss or o.position.distance_to(e.position) > r:
			continue
		o.apply_buff(1.0, spd, 1.0, t)
		if share > 0.0 and o.holy_shield < o.max_hp * share:
			o.holy_shield = o.max_hp * share
			o.holy_shield_time = t
		n += 1
	g.stat_add("boatswain_bellows", 1.0)
	g.stat_add("boatswain_buffed", float(n))
	g.effects.ring(e.position, r, Palette.CORSAIR_BRASS_LIGHT, 0.35)


func is_busy() -> bool:
	return in_water or phase != IDLE


## The whistle: a small brass glint at his mouth while he winds up. Visual only.
func draw_over(e: Enemy, ci: CanvasItem) -> void:
	if phase != WINDUP:
		return
	SpriteBank.draw_disc(ci, Vector2(e.radius * 0.5, -e.radius * 1.1), 2.0 + 2.0 * phase_time, Color(Palette.CORSAIR_BRASS_LIGHT, 0.8))
