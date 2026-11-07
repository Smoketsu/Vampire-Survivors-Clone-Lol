## CorsairKit — base class of the Black Tide's kits (Act X; GDD §15.0 "Act X
## foundation: the Black Tide (phase 1)"), a CovenantKit plugged into the
## shared Enemy AI like every kit. Kits load by name from
## scripts/enemies/corsair/<id>_kit.gd (CovenantKits, after the Concord's
## folder; an id must not repeat another folder's). What every Black Tide kind
## shares:
##   * creating the shared rules on first use (Game.corsair_rules()), so a
##     Black Tide kind forced onto any stage with --spawn= runs its kit there
##     (no deck, no boats and no sea off Act X: a swimmer or a boat there is
##     an ordinary body on the ground);
##   * THE WATER STATE (`in_water`, from the row "water" on a stage with a
##     deck): a swimmer or a boat lies in the sea. The deck ignores it
##     (DeckBounds.contain_all() reads is_in_water(), the one test), its kit
##     owns every tick (physics() true: SeaStrikes / BoardingParty move it),
##     it is never recycled to the spawn ring (Enemy.is_objective) and the
##     autotest's stuck check skips it (is_busy()). A shark that lands on the
##     deck after its leap leaves the water (leave_water()) and walks like any
##     deck enemy;
##   * SURFACING (SeaStrikes): a swimmer is untargetable (Enemy.untargetable:
##     out of the enemy grid, so shots and blows pass over it) unless
##     `surfaced_until` is ahead; draw_body() draws a submerged swimmer as a
##     dark shape and a fin;
##   * the BARNACLE BONES hook in taken_mult(): a summon's hit on a boat, a
##     hook or a swimmer x CorsairRules.barnacle_mult() (exactly 1 while the
##     passive does not exist);
##   * the first-seen log (CorsairRules.note_spawn()).
## Phase 2 kinds extend this class: call super.reset() / super.on_deactivate()
## / super.physics() / super.taken_mult() when they override those.
## Determinism: no RNG, no instance ids.
class_name CorsairKit
extends CovenantKit

## True while the body lies in the sea (a swimmer, a boat; see the header).
var in_water: bool = false
## Game time (s) until which a swimmer is surfaced (hittable); 0 = submerged.
var surfaced_until: float = 0.0
## A swimmer's place along the hull (arc length px of DeckBounds' perimeter).
var swim_s: float = 0.0
## A swimmer's direction along the hull (+1 / -1, from its think slot).
var swim_dir: float = 1.0
## True while a swimmer's strike is telegraphed or holding (SeaStrikes).
var striking: bool = false
## Game time (s) of a swimmer's next strike (SeaStrikes sets it).
var next_strike: float = 0.0


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	var r := e.game.corsair_rules()  # The shared rules exist wherever a Black Tide kind walks.
	in_water = bool(d.get("water", false)) and e.game.deck != null
	surfaced_until = 0.0
	swim_s = 0.0
	swim_dir = 1.0 if e.think_slot % 2 == 0 else -1.0
	striking = false
	next_strike = 0.0
	if in_water:
		e.is_objective = true  # In the sea: never recycled to the spawn ring.
	r.note_spawn(e)


func on_deactivate(e: Enemy) -> void:
	super.on_deactivate(e)
	striking = false
	if e.game.corsair != null:
		e.game.corsair.note_gone(e)


## The shared rules (created on first use).
static func rules(e: Enemy) -> CorsairRules:
	return e.game.corsair_rules()


## THE WATER TEST (DeckBounds, BoardingParty, SeaStrikes): true when `e` lies in
## the sea (a Black Tide swimmer or boat on a deck stage).
static func is_in_water(e: Enemy) -> bool:
	return e.kit is CorsairKit and (e.kit as CorsairKit).in_water


## A swimmer comes out of the sea onto the deck (a shark's leap lands): an
## ordinary deck enemy from now on.
func leave_water(e: Enemy) -> void:
	in_water = false
	striking = false
	e.untargetable = false
	e.is_objective = false
	e.knockback = Vector2.ZERO
	e.queue_redraw()


## True for a row that is a boat (BoardingParty).
func is_boat() -> bool:
	return bool(d.get("boat", false))


## True for a row that is a grapple hook (BoardingParty).
func is_hook() -> bool:
	return bool(d.get("hook", false))


## True while a swimmer can be hit (surfaced; always for a body on the deck).
func surfaced(e: Enemy) -> bool:
	return not in_water or is_boat() or e.game.elapsed < surfaced_until


## A body in the sea is moved by its owner (SeaStrikes / BoardingParty): the
## shared AI holds it (true). On the deck the shared AI moves it (false).
func physics(e: Enemy, _delta: float) -> bool:
	if in_water:
		hold(e)
		return true
	return false


## In the sea it is always "busy" (the stuck check skips it); on the deck only
## while a special runs.
func is_busy() -> bool:
	return in_water or phase != IDLE


## BARNACLE BONES (hook): a summon's hit on a boat, a hook or a swimmer deals
## CorsairRules.barnacle_mult() (exactly 1 today); every other hit in full.
func taken_mult(e: Enemy, source: String) -> float:
	if not (in_water or is_hook()):
		return 1.0
	var g := e.game
	if g.corsair == null or not g.combat.is_minion_source(source):
		return 1.0
	return g.corsair.barnacle_mult()


## A submerged swimmer draws its own shape (a dark body and a fin); anything
## else draws its kind's sprite or glyph.
func draws_body(e: Enemy) -> bool:
	return in_water and not is_boat() and not surfaced(e)


## The submerged look: a dark shape under the waves, a fin and a foam fleck.
func draw_body(e: Enemy, ci: CanvasItem) -> void:
	var r := e.radius
	SpriteBank.draw_disc(ci, Vector2.ZERO, r * 1.2, Color(Palette.CORSAIR_INK, 0.55))
	ci.draw_rect(Rect2(Vector2(-1.5, -r * 0.9), Vector2(3.0, r * 0.8)), Palette.CORSAIR_POWDER_DARK)  # The fin.
	ci.draw_rect(Rect2(Vector2(-r * 0.6, -r * 0.15), Vector2(r * 1.2, 1.5)), Color(Palette.CORSAIR_FOAM, 0.7))  # Foam where it cuts the water.
