## CartoucheKit — the kit of the CARTOUCHE (DynastyEnemyData "cartouche"; a
## 1-hit structure; temporary Act XII, the Necropolis Dynasty; GDD §15.0
## "Rebirth"). Rebirth lays one over every fallen mummy or guardian
## (Rebirth.on_death(), the one path) and calls setup(): the dead kind, its
## elite flag, its returns so far and the jar that seals it (null = none).
##   * its HP is set to DynastyRulesData.CARTOUCHE_HP at activation, whatever
##     the HP scalings, so every hit that reaches it smashes it
##     (Rebirth.smash(), before the kill path: no kill, no XP);
##   * SEALED (a live Canopic Jar held the Name when it was laid): untargetable
##     (Enemy.untargetable: out of the enemy grid, nothing hits it), drawn in
##     lapis; only a raise (Rebirth.on_raise()) or the jar's fall stops it;
##   * THE TIMER: REBIRTH duration s, run x DynastyRules.embalm_rate() (an
##     Embalmer near it: x2); a Stasis or a freeze holds it, as every kit's
##     physics. Then Rebirth.return_body(): the body stands again.
## Drawn LIGHT (proposal risks: "show one gold cartouche per corpse, hide the
## timer text and shrink the icon with the count"): the wrapped body lying on
## the ground and one small cartouche above it, in the dull bronze-gold (lapis
## when sealed), filling from the bottom as its time runs (no text); the icon
## shrinks once REBIRTH icon_shrink_from cartouches lie at once. Art
## `dynasty/cartouche` replaces the icon when it exists. Determinism: game time
## only. Stats: rebirth_embalmed (cartouches an Embalmer hastened at least once).
class_name CartoucheKit
extends DynastyKit

## Sprite key of the cartouche icon (the art pass's marker
## assets/sprites/markers/dyn_cartouche.png; wired at the wave 1 integration).
const SPRITE: String = "markers/dyn_cartouche"
## Steps the icon's fill is drawn in (a redraw only when it changes step).
const FILL_STEPS: int = 12  # TUNING (not in GDD) drawing only

## The kind of the body that fell here (it returns as this kind).
var dead_kind: String = ""
## The body's elite flag (kept on its return).
var elite: bool = false
## The jar that seals this Name (null = none).
var jar: Enemy = null
## That jar's generation when it sealed the Name (a pooled jar is another).
var jar_gen: int = 0
## Seconds of the timer run so far (x the Embalmers' haste).
var progress: float = 0.0
## True once an Embalmer hastened it (counted once).
var embalmed: bool = false
## The fill step drawn last (a redraw when it changes).
var _drawn_step: int = -1


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	e.max_hp = DynastyRulesData.CARTOUCHE_HP
	e.hp = DynastyRulesData.CARTOUCHE_HP
	e.is_objective = true  # It stands until smashed, stolen or returned (never recycled).
	dead_kind = ""
	elite = false
	jar = null
	jar_gen = 0
	progress = 0.0
	embalmed = false
	_drawn_step = -1


## Rebirth.on_death(): the Name of a fallen `kind` (elite `p_elite`, returned
## `p_returns` times) under jar `p_jar` (null = none).
func setup(e: Enemy, kind: String, p_elite: bool, p_returns: int, p_jar: Enemy) -> void:
	dead_kind = kind
	elite = p_elite
	returns = p_returns
	jar = p_jar
	jar_gen = p_jar.generation if p_jar != null else 0
	e.untargetable = p_jar != null  # Sealed: nothing can hit it.
	e.queue_redraw()


## True when jar `j` seals this Name.
func sealed_by(j: Enemy) -> bool:
	return jar != null and jar == j and jar.generation == jar_gen


func on_deactivate(e: Enemy) -> void:
	super.on_deactivate(e)
	jar = null
	if e.game.dynasty != null:
		e.game.dynasty.rebirth.forget(e)


## Every tick: it holds still and its timer runs; the body returns when it is up.
func physics(e: Enemy, delta: float) -> bool:
	hold(e)
	var g := e.game
	if g.dynasty == null:
		return true
	var rate := g.dynasty.embalm_rate(e.position)  # x the timer here.
	if rate > 1.0 and not embalmed:
		embalmed = true
		g.stat_add("rebirth_embalmed", 1.0)
	progress += delta * rate
	var dur := g.dynasty.rebirth.duration()  # Rebirth's one duration path (the Hall's Scales, Osiris).
	if progress >= dur:
		g.dynasty.rebirth.return_body(e)
		return true
	var step := int(progress / dur * float(FILL_STEPS))
	if step != _drawn_step:
		_drawn_step = step
		e.queue_redraw()
	return true


func is_busy() -> bool:
	return true  # It never moves (the stuck check skips it).


func draws_body(_e: Enemy) -> bool:
	return true


## The wrapped body lying on the ground and the small cartouche over it (see
## the header). Textures and rects only.
func draw_body(e: Enemy, ci: CanvasItem) -> void:
	var g := e.game
	var r := e.radius
	# The wrapped body (two linen discs, lying).
	ci.draw_texture_rect(SpriteBank.disc(), Rect2(Vector2(-r * 1.4, -r * 0.3), Vector2(r * 2.8, r * 1.1)), false, Color(Palette.DYN_INK, 0.55))
	ci.draw_texture_rect(SpriteBank.disc(), Rect2(Vector2(-r * 1.25, -r * 0.2), Vector2(r * 2.5, r * 0.8)), false, Palette.DYN_LINEN_DARK)
	var sealed := jar != null
	var rim := Palette.DYN_LAPIS if sealed else Palette.DYN_BRONZE  # Sealed by a jar: lapis.
	var count := g.dynasty.rebirth.alive_count() if g.dynasty != null else 1
	var cfg: Dictionary = g.dynasty.rebirth.cfg if g.dynasty != null else DynastyRulesData.REBIRTH
	var from := int(cfg["icon_shrink_from"])
	var sc := 1.0 if count <= from else maxf(float(cfg["icon_min_scale"]), float(from) / float(count))  # Icon scale.
	var dur := g.dynasty.rebirth.duration() if g.dynasty != null else float(cfg["duration"])
	var k := clampf(progress / dur, 0.0, 1.0)  # Share of its time run.
	var w := 6.0 * sc  # Icon half-width (px).
	var h := 9.0 * sc  # Icon half-height (px).
	var c := Vector2(0.0, -r - 6.0 - h)  # Icon centre (over the body).
	if SpriteBank.draw(ci, SPRITE, c, false, Color(0.6, 0.75, 1.3) if sealed else Color.WHITE):
		return
	ci.draw_rect(Rect2(c - Vector2(w + 1.0, h + 1.0), Vector2(w + 1.0, h + 1.0) * 2.0), Palette.DYN_INK)
	ci.draw_rect(Rect2(c - Vector2(w, h), Vector2(w, h) * 2.0), rim)
	ci.draw_rect(Rect2(c - Vector2(w - 1.5, h - 1.5), Vector2(w - 1.5, h - 1.5) * 2.0), Palette.DYN_INK)
	var fill := (h - 1.5) * 2.0 * k  # Filled height (px), from the bottom.
	if fill > 0.0:
		ci.draw_rect(Rect2(Vector2(c.x - w + 1.5, c.y + h - 1.5 - fill), Vector2((w - 1.5) * 2.0, fill)), Color(rim, 0.85))
	ci.draw_rect(Rect2(Vector2(c.x - w * 0.5, c.y - h * 0.45), Vector2(w, 1.0)), Palette.DYN_BRONZE_LIGHT if not sealed else Palette.DYN_LINEN)  # A glyph line.
