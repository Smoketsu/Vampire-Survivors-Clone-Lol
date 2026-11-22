## OpenBarrowKit — the kit of THE OPEN BARROW (BarrowFieldsEnemyData
## "open_barrow"; the Barrow Fields, the Hall of the Slain, temporarily Act XI;
## GDD §15.0 "The Barrow Fields (the Hall of the Slain phase 2)"; the brief:
## "mounds that crack open on a 2 s telegraph and let draugr out until the mound
## is broken"). A STRUCTURE placed by BarrowFieldsDirector.open_barrow() (the
## one barrow path: the timeline's "barrow" events, the Barrow-Wight's howl,
## Hrimgar's Grave) or --spawn=open_barrow. It stands until broken
## (Enemy.is_objective: never recycled to the spawn ring):
##   * CRACKING (crack_time s from its activation): the closed barrow shakes and
##     a frost ring closes on it (the telegraph); it can already be struck.
##   * OPEN: every release_every s a draugr climbs out at its mouth (the row's
##     release_kinds in turn: male and female), while fewer than release_max of
##     its own walk and the field is under the hard cap. release_now() lets
##     some out at once (Hrimgar's "draugr from every mound").
## Broken, it pays its xp like any enemy and lets nothing out again.
## HrimgarBarrowKit extends it (the king's own barrow).
## Determinism: no RNG (the mouth turns with its count). Stats: barrows_opened,
## barrow_draugr, barrows_broken (BarrowFieldsDirector counts by tag).
class_name OpenBarrowKit
extends NorseKit

## Phase: cracking open (the telegraph).
const CRACKING: int = 1
## Phase: open, letting draugr out.
const OPEN: int = 2

## Seconds until the next draugr climbs out.
var release_cd: float = 0.0
## Draugr let out by this barrow ([Enemy, generation] pairs; stale ones dropped).
var released: Array = []
## Draugr let out this life (turns the next one's kind and mouth).
var count: int = 0


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	e.is_objective = true  # It stands until broken (never recycled).
	released.clear()
	count = 0
	release_cd = 0.0
	set_phase(e, CRACKING)
	if float(d.get("crack_time", 0.0)) > 0.0:
		e.game.effects.telegraph_circle(e.position, e.radius * 2.2, float(d["crack_time"]))


## Every tick: the crack's countdown, then a draugr on its cooldown.
func physics(e: Enemy, delta: float) -> bool:
	hold(e)
	phase_time += delta
	if phase == CRACKING:
		if phase_time >= float(d.get("crack_time", 0.0)):
			set_phase(e, OPEN)
			release_cd = 0.4
			e.game.stat_add("barrows_opened", 1.0)
			e.game.effects.ring(e.position, e.radius * 2.0, Palette.NORSE_RUNE, 0.5)
			e.game.shake(2.0)
		return true
	release_cd -= delta
	if release_cd <= 0.0:
		release_cd = float(d.get("release_every", 5.0))
		release(e, 1, false)
	return true


## Lets up to `n` draugr out at once (`forced`: past release_max, still under
## the hard cap: Hrimgar's call). Returns how many came out.
func release(e: Enemy, n: int, forced: bool) -> int:
	if phase != OPEN:
		return 0
	_prune()
	var g := e.game
	var kinds: Array = d.get("release_kinds", ["draugr"])
	var made := 0
	for k in n:
		if not forced and released.size() >= int(d.get("release_max", 3)):
			break
		if g.enemies.regular_alive() >= g.enemies.hard_cap():
			g.stat_add("barrow_draugr_capped", 1.0)
			break
		var a := float(count) * 2.1 + float(e.think_slot)  # Its mouth turns each time (no RNG).
		var at := e.position + Vector2.from_angle(a) * float(d.get("release_dist", 26.0))
		var u := g.enemies.spawn_at(String(kinds[count % kinds.size()]), at, false)
		count += 1
		if u == null:
			continue
		released.append([u, u.generation])
		made += 1
		g.stat_add("barrow_draugr", 1.0)
	if made > 0:
		e.queue_redraw()
	return made


## True once it stands open.
func is_open() -> bool:
	return phase == OPEN


## Drops the draugr that left the field.
func _prune() -> void:
	var i := released.size() - 1
	while i >= 0:
		var pair: Array = released[i]
		var u: Enemy = pair[0]
		if not u.active or u.generation != int(pair[1]):
			released.remove_at(i)
		i -= 1


func on_killed(e: Enemy) -> void:
	super.on_killed(e)
	e.game.stat_add("barrows_broken", 1.0)
	e.game.effects.impact(e.position, e.radius * 1.6, Palette.NORSE_FROST)


func on_deactivate(e: Enemy) -> void:
	released.clear()
	super.on_deactivate(e)


func is_busy() -> bool:
	return true  # A mound never walks (the stuck check).


func draws_body(_e: Enemy) -> bool:
	return true


## The barrow: closed and shaking while it cracks (a frost ring closing on
## it), open with its ice-blue glow after; its sprite (obstacles/barrow_closed
## / barrow_open), else a code mound. Visual only.
func draw_body(e: Enemy, ci: CanvasItem) -> void:
	var t := e.game.elapsed
	var shake := Vector2(roundf(sin(t * 40.0)), 0.0) if phase == CRACKING else Vector2.ZERO
	var key := "obstacles/barrow_open" if phase == OPEN else "obstacles/barrow_closed"
	unmirror(e, ci)
	draw_mound(ci, key, shake, e.radius, e.flash > 0.0)
	if phase == OPEN:
		var a := 0.25 + 0.15 * sin(t * 3.0)
		SpriteBank.draw_disc(ci, Vector2(0.0, -e.radius * 0.2), e.radius * 0.45, Color(Palette.NORSE_RUNE, a))
	else:
		var k := clampf(phase_time / maxf(float(d.get("crack_time", 0.0)), 0.01), 0.0, 1.0)
		var rr := e.radius * (2.2 - 1.0 * k)  # The frost ring closes on it.
		for i in 16:
			SpriteBank.draw_disc(ci, Vector2.from_angle(TAU * float(i) / 16.0) * rr, 1.6, Color(Palette.NORSE_RUNE, 0.4 + 0.5 * k))
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## Draws mound sprite `key` with its base on the body's feet line (offset
## `o`), else a code mound of radius `r`. Shared with HrimgarBarrowKit.
static func draw_mound(ci: CanvasItem, key: String, o: Vector2, r: float, flash: bool) -> void:
	var tex := EnvironmentArt.texture(key) if key.begins_with("obstacles/") else SpriteBank.texture(key)
	var mod := SpriteData.FLASH_MODULATE if flash else Color.WHITE
	if tex != null:
		SpriteBank.apply_sharp(ci)
		var size := Vector2(float(tex.get_width()), float(tex.get_height()))
		var tl := (o + Vector2(-size.x * 0.5, r * 0.8 - size.y)).round()
		SpriteBank.draw_disc(ci, o + Vector2(0.0, r * 0.6), size.x * 0.45, Color(0.0, 0.0, 0.0, 0.25))
		ci.draw_texture_rect(tex, Rect2(tl, size), false, mod)
		return
	SpriteBank.draw_disc(ci, o, r * 1.05, Palette.NORSE_INK)
	SpriteBank.draw_disc(ci, o, r, Palette.NORSE_FROST_SHADE if not flash else Color.WHITE)
	SpriteBank.draw_disc(ci, o + Vector2(0.0, -r * 0.2), r * 0.35, Palette.NORSE_INK)
