## FoxFireKit — a Kitsune's FOX-FIRE ILLUSION (SunRoadEnemyData "fox_fire";
## Act V, the Road to the Sun; GDD §15.0 "The Road to the Sun (Act V phase
## 2)"; owner-approved proposal: "Fox-fire illusions: decoy enemies your
## summons waste attacks on | Area damage reveals them", and the brief:
## "revealed in light or by area damage"). Conjured by a Kitsune (KitsuneKit).
##   * It LOOKS like her (her sprite with a flicker of blue fox-fire,
##     draws_body()) and ranks high on every summon's target list (its row's
##     target_priority), so the army spends its blows on it.
##   * WASTED BLOWS: a summon's own blow (CombatResolver.is_minion_source(),
##     not its _cleave / _aura splash) passes through it: it takes nothing
##     (taken_mult(), the one read in Enemy.damage_taken_mult()).
##   * REVEALED: any other hit (a spell, a splash, a hazard, the Soul Nova:
##     AREA damage) or LIGHT (SunCourse.light_at() at least its row's
##     reveal_light: a lantern's pool, the necromancer's own lamp, the day)
##     dispels it, as do decoy_life s of age and its Kitsune's death.
##   * It is harmless (damage 0) and is never killed: it leaves through
##     EnemyDirector.despawn() (no kill, no XP, no drop, no Dread Rally charge).
## No RNG. Stats: fox_fire_wasted_hits, fox_fire_revealed_<reason> (light,
## area, faded, caster, replaced).
class_name FoxFireKit
extends ShogunateKit

## Seconds between two light checks (5 Hz, the AI's think rate).
const LIGHT_EVERY: float = 0.2  # TUNING (not in GDD) rhythm, not balance

## Seconds since it appeared.
var age: float = 0.0
## Its Kitsune (null for one spawned alone with --spawn=).
var caster: Enemy = null
## Its Kitsune's generation when it was conjured.
var caster_gen: int = 0
## Why it is being revealed ("" = not yet): set by a hit, read by physics().
var _reveal: String = ""
## Seconds until the next light check.
var _light_cd: float = 0.0


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	age = 0.0
	caster = null
	caster_gen = 0
	_reveal = ""
	_light_cd = 0.0


## Ties the illusion `e` to its Kitsune `k` (KitsuneKit._conjure()).
func bind(_e: Enemy, k: Enemy) -> void:
	caster = k
	caster_gen = k.generation


## The illusion takes no blow: a summon's own is wasted, anything else (area
## damage) reveals it.
func taken_mult(e: Enemy, source: String) -> float:
	var g := e.game
	if g.combat.is_minion_source(source) and not source.ends_with("_cleave") and not source.ends_with("_aura"):
		g.stat_add("fox_fire_wasted_hits", 1.0)
	elif _reveal == "":
		_reveal = "area"
	return 0.0


## Ages, checks the light and its caster; dispels when revealed. Otherwise the
## shared AI walks it at the necromancer (its touch deals nothing).
func physics(e: Enemy, delta: float) -> bool:
	age += delta
	if _reveal != "":
		dispel(e, _reveal)
		return true
	if age >= float(d["decoy_life"]):
		dispel(e, "faded")
		return true
	if caster != null and (not caster.active or caster.generation != caster_gen):
		dispel(e, "caster")
		return true
	_light_cd -= delta
	if _light_cd <= 0.0:
		_light_cd = LIGHT_EVERY
		if light(e) >= float(d["reveal_light"]):
			dispel(e, "light")
			return true
	if int(age * 10.0) != int((age - delta) * 10.0):
		e.queue_redraw()  # The fox-fire flickers (visual only).
	return false


## Dispels the illusion (reason for the stats): a puff of blue fox-fire, then
## it leaves the field without a kill.
func dispel(e: Enemy, reason: String) -> void:
	if not e.active:
		return
	var g := e.game
	g.effects.pop(e.position, SunRoadGlyphs.FOX_FIRE, 12.0)
	g.stat_add("fox_fire_revealed_" + reason, 1.0)
	_reveal = ""
	caster = null
	g.enemies.despawn(e)


## Its body is her image in fox-fire (see the header).
func draws_body(_e: Enemy) -> bool:
	return true


## Her sprite with a flicker of blue fox-fire (her glyph without art). Visual only.
func draw_body(e: Enemy, ci: CanvasItem) -> void:
	var flick := 0.78 + 0.08 * float(int(age * 10.0) % 3)  # Opacity flicker.
	var tint := Color(0.86, 0.92, 1.0, flick)  # A cold fox-fire cast.
	if not SpriteBank.draw(ci, "shogunate/" + SunRoadEnemyData.KITSUNE, Vector2.ZERO, e.flash > 0.0, tint):
		SunRoadGlyphs.draw_kitsune(ci, Vector2.ZERO, e.radius, e.flash > 0.0, tint)
	SpriteBank.draw_disc(ci, Vector2(0, -e.radius * 1.6 - 2.0 * float(int(age * 10.0) % 2)), 2.5, Color(SunRoadGlyphs.FOX_FIRE, 0.7))
