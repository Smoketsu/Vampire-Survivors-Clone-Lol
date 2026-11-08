## TwoTruthsGlyphs — drawing helpers of THE HALL OF TWO TRUTHS (temporary Act XII,
## the Necropolis Dynasty's finale; GDD §15.0 "The Hall of Two Truths
## (Necropolis Dynasty phase 2)"): the stage's single-sprite obstacles (the art
## pass drew one PNG each for the brazier, the great Scales, the sphinx head and
## the broken blocks, so they are drawn from obstacles/<kind> whatever their
## size), the Weighing's Scales with the heart and the feather, the code
## fallbacks of Osiris and Ammit when their PNGs are missing, and Feather's
## Verdict's falling feather. Textures and rects only (no polygons redrawn every
## frame). Visual only: nothing here touches gameplay.
class_name TwoTruthsGlyphs
extends RefCounted

## Obstacle kind -> its one sprite key (whatever the size index).
const SINGLE_ART := {
	"dyn_brazier": "obstacles/dyn_brazier",
	"dyn_great_scales": "obstacles/dyn_great_scales",
	"dyn_sphinx_head": "obstacles/dyn_sphinx_head",
	"dyn_sandstone_blocks": "obstacles/dyn_sandstone_blocks",
}
## Sprite key of the great Scales (the Weighing beside Osiris's throne).
const SCALES_KEY: String = "obstacles/dyn_great_scales"
## Px from the Scales' foot up to its pans (the art's 75 px height).
const PAN_RISE: float = 44.0  # TUNING (not in GDD) drawing only
## Px from the Scales' centre out to each pan.
const PAN_SPREAD: float = 22.0  # TUNING (not in GDD) drawing only
## Px a pan dips at full tilt.
const PAN_DIP: float = 7.0  # TUNING (not in GDD) drawing only
## The necromancer's heart (the soul-teal of the undead when light, the
## carnelian of the Dynasty when heavy).
const HEART_LIGHT := Color(0.55, 0.92, 0.84)  # TUNING (not in GDD) soul-teal
## The feather of Ma'at, and of Feather's Verdict: true gold (the player's).
const FEATHER := Color(1.0, 0.84, 0.4)  # TUNING (not in GDD) Palette.GOLD (the feather is the player's)


## Draws obstacle `o` when it is one of the stage's single-sprite kinds (its art
## key is pointed at the one PNG, then the shared obstacle art draws it). False
## for any other kind.
static func draw_obstacle(ci: CanvasItem, o: Arena.Obstacle) -> bool:
	if not SINGLE_ART.has(o.kind):
		return false
	o.art_key = String(SINGLE_ART[o.kind])
	if EnvironmentArt.draw_obstacle(ci, o):
		return true
	var c := o.center
	var r := o.radius if o.is_circle else minf(o.half.x, o.half.y)
	SpriteBank.draw_disc(ci, c + Vector2(3, 4), r, Color(0, 0, 0, 0.35))
	SpriteBank.draw_disc(ci, c, r, Palette.DYN_INK)
	SpriteBank.draw_disc(ci, c, r - 1.5, Palette.DYN_SAND_DARK)
	if o.kind == "dyn_brazier":
		SpriteBank.draw_disc(ci, c + Vector2(0, -r * 0.4), r * 0.5, Palette.DYN_CARNELIAN_LIGHT)
	return true


## The great Scales at `at` (its foot) on `ci`, the heart on the left pan and
## the feather on the right, tipped by `tilt` (-1 toward the necromancer: the
## heart rises; +1 toward the Dynasty: the heart sinks); `t` game time (the
## heart's pulse).
static func draw_weighing(ci: CanvasItem, at: Vector2, tilt: float, t: float) -> void:
	var tex := EnvironmentArt.texture(SCALES_KEY)
	if tex != null:
		var sz := tex.get_size()
		ci.draw_texture_rect(tex, Rect2(at - Vector2(sz.x * 0.5, sz.y), sz), false)
	else:
		ci.draw_rect(Rect2(at + Vector2(-2.0, -PAN_RISE - 14.0), Vector2(4.0, PAN_RISE + 14.0)), Palette.DYN_BRONZE)
		ci.draw_rect(Rect2(at + Vector2(-PAN_SPREAD - 6.0, -PAN_RISE - 14.0), Vector2(PAN_SPREAD * 2.0 + 12.0, 3.0)), Palette.DYN_BRONZE_LIGHT)
	var k := clampf(tilt, -1.0, 1.0)
	var heart := at + Vector2(-PAN_SPREAD, -PAN_RISE + PAN_DIP * k)
	var feather := at + Vector2(PAN_SPREAD, -PAN_RISE - PAN_DIP * k)
	var pulse := 1.0 + 0.12 * sin(t * 6.0)
	var hc := HEART_LIGHT.lerp(Palette.DYN_CARNELIAN, clampf(k * 0.5 + 0.5, 0.0, 1.0))
	SpriteBank.draw_disc(ci, heart + Vector2(0, -5), 7.0 * pulse, Color(hc, 0.3))
	SpriteBank.draw_disc(ci, heart + Vector2(0, -5), 4.0 * pulse, hc)
	draw_feather(ci, feather + Vector2(0, -7), 0.8)


## A small gold feather at `c` on `ci`, `s` its scale (1 = 18 px tall).
static func draw_feather(ci: CanvasItem, c: Vector2, s: float) -> void:
	var h := 18.0 * s
	ci.draw_rect(Rect2(c + Vector2(-0.5, -h * 0.5), Vector2(1.0, h)), Palette.DYN_LINEN_LIGHT)  # The quill.
	for i in 6:
		var y := -h * 0.4 + float(i) * h * 0.13
		var w := (3.0 + float(mini(i, 5 - i)) * 1.2) * s
		ci.draw_rect(Rect2(c + Vector2(-w, y), Vector2(w * 2.0, maxf(1.0, h * 0.1))), FEATHER)


## Osiris on his throne, the code fallback (`r` his radius, `a` alpha).
static func draw_osiris(ci: CanvasItem, r: float, flash: bool, a: float) -> void:
	var body := Color(1, 1, 1, a) if flash else Color(Palette.DYN_LINEN, a)
	ci.draw_rect(Rect2(Vector2(-r, -r * 0.4), Vector2(r * 2.0, r * 1.4)), Color(Palette.DYN_LAPIS_DARK, a))  # The throne.
	ci.draw_rect(Rect2(Vector2(-r * 0.5, -r * 2.2), Vector2(r, r * 2.4)), body)  # Linen.
	SpriteBank.draw_disc(ci, Vector2(0, -r * 2.4), r * 0.4, Color(Palette.DYN_PAPYRUS, a))  # His green face.
	ci.draw_rect(Rect2(Vector2(-r * 0.25, -r * 3.3), Vector2(r * 0.5, r * 0.8)), Color(Palette.DYN_LINEN_LIGHT, a))  # The atef crown.


## Ammit, the code fallback (`r` her radius).
static func draw_ammit(ci: CanvasItem, r: float, flash: bool) -> void:
	var hide := Color.WHITE if flash else Palette.DYN_SAND_DARK
	SpriteBank.draw_disc(ci, Vector2(r * 0.4, 0), r, Palette.DYN_INK)
	SpriteBank.draw_disc(ci, Vector2(r * 0.4, 0), r - 1.5, hide)  # Lion and hippo.
	SpriteBank.draw_disc(ci, Vector2(-r * 0.9, -r * 0.2), r * 0.55, Palette.DYN_PAPYRUS_DARK)  # Crocodile jaws.
	SpriteBank.draw_disc(ci, Vector2(-r * 1.1, -r * 0.35), 2.0, Palette.DYN_CARNELIAN)  # Her eye.
