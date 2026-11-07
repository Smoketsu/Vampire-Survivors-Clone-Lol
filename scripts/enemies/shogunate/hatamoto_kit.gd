## HatamotoKit — the kit of the Hatamoto (KuroganeEnemyData "hatamoto"; Act V,
## Castle Kurogane, GDD §15.0 "Castle Kurogane (Act V phase 2)"; owner-approved
## proposal: "Hatamoto: elite banner guard; nearby soldiers fight harder while
## he stands. Kill the banner"). His aura is the row's aura_* keys, pulsed by
## Enemy.think() through the one enemy-buff path (Enemy._pulse_aura() ->
## Enemy.apply_buff(), the Banner Bearer's); he walks with the shared melee AI.
## What the kit adds:
##   * his banner's COLOUR: in Shogun Kurogane's fight each regiment marches
##     under its own (BossShogun sets it through set_regiment(); ShogunData
##     REGIMENTS "color"); outside it the row's banner_color. The kit draws his
##     body itself (draws_body()) as his sprite multiplied by that colour: the
##     white sashimono takes it, the dark lacquer barely changes (SpriteBank's
##     one tint parameter; visual only);
##   * the regiment index (`regiment`, -1 outside the fight) the Shogun reads
##     when he falls: his regiment BREAKS (BossShogun polls him).
## No RNG. Stats: hatamoto_spawned (and the shared kill_hatamoto).
class_name HatamotoKit
extends ShogunateKit

## Colour multiplied over his sprite (his banner's colour).
var banner: Color = Color.WHITE
## Index of his regiment in ShogunData.REGIMENTS (-1: not one of the Shogun's).
var regiment: int = -1


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	banner = def.get("banner_color", Color.WHITE)
	regiment = -1
	e.game.stat_add("hatamoto_spawned", 1.0)


## Puts him at the head of regiment `index` with banner colour `color`
## (BossShogun, right after the spawn).
func set_regiment(e: Enemy, index: int, color: Color) -> void:
	regiment = index
	banner = color
	e.queue_redraw()


## He draws his own body (his sprite in his banner's colour).
func draws_body(_e: Enemy) -> bool:
	return true


## His sprite multiplied by his banner colour; the kind's glyph without art.
func draw_body(e: Enemy, ci: CanvasItem) -> void:
	if not SpriteBank.draw(ci, "shogunate/" + e.kind, Vector2.ZERO, e.flash > 0.0, banner):
		Glyphs.draw_enemy(ci, e.kind, Vector2.ZERO, e.radius, e.flash > 0.0, e.is_elite)
