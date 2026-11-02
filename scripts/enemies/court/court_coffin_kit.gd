## CourtCoffinKit — the kit of the Court's coffin (CourtEnemyData
## "court_coffin"; Act VII, GDD §15.0 "Act VII foundation (phase 1)"): a
## PLACEHOLDER structure (the art pass's structures/court_coffin, closed, and
## structures/court_coffin_open). It stands CLOSED until open_coffin() (the
## Endless Feast opens its coffins at once; phase 2's Ravensmoor can place
## sleeping coffins and open them when the moon turns); OPEN, it releases its
## row's release_kind (a vampire noble) release_first s later, then one every
## release_every s while a necromancer is within release_reach px and the hard
## cap leaves room, at most release_max. Broken by damage like any structure
## (its XP). No RNG. Stats: coffins_opened, coffin_nobles, coffin_capped.
class_name CourtCoffinKit
extends CourtKit

## True once it opened.
var opened: bool = false
## Nobles it released.
var released: int = 0
## Game time (s) of its next release (INF while closed).
var _next: float = INF


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	opened = false
	released = 0
	_next = INF


## THE call that opens coffin `e` (the Endless Feast, phase 2's sleeping
## coffins): it creaks open and starts releasing.
func open_coffin(e: Enemy) -> void:
	if opened:
		return
	opened = true
	_next = e.game.elapsed + float(d.get("release_first", 1.5))
	e.game.stat_add("coffins_opened", 1.0)
	rules(e).play_sound("coffin_creak", e.position, 0.3)
	e.queue_redraw()


func physics(e: Enemy, _delta: float) -> bool:
	if not opened or released >= int(d.get("release_max", 3)):
		return false
	var g := e.game
	if g.elapsed < _next:
		return false
	_next = g.elapsed + float(d.get("release_every", 24.0))
	var near := false  # A necromancer within release_reach.
	for pl in g.all_players:
		if not pl.dead and pl.position.distance_to(e.position) <= float(d.get("release_reach", 900.0)):
			near = true
	if not near:
		return false
	if g.enemies.regular_alive() + 1 > g.enemies.hard_cap():
		g.stat_add("coffin_capped", 1.0)
		return false
	var at := g.arena.free_point(e.position + Vector2(0.0, e.radius + 14.0), 12.0)
	if g.enemies.spawn_at(String(d.get("release_kind", CourtEnemyData.VAMPIRE_NOBLE)), at, false) != null:
		released += 1
		g.stat_add("coffin_nobles", 1.0)
		g.effects.spawn_ring(at, Palette.COURT_BLOOD)
	return false


## An opened coffin draws its open sprite (or CourtGlyphs' open coffin).
func draws_body(_e: Enemy) -> bool:
	return opened


func draw_body(e: Enemy, ci: CanvasItem) -> void:
	if not SpriteBank.draw(ci, CourtEnemyData.COFFIN_OPEN_SPRITE, Vector2.ZERO, e.flash > 0.0):
		CourtGlyphs.draw_coffin(ci, Vector2.ZERO, e.radius, e.flash > 0.0, true)
