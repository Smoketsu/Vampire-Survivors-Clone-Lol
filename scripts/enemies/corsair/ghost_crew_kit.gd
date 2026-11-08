## GhostCrewKit — the shared base of the Hollow Queen's GHOST CREW (Act X, the
## Maelstrom; MaelstromEnemyData rows with "ghost": the Ghost Deckhand and the
## Ghost Gunner; GDD §15.0 "The Maelstrom (Act X phase 2)"; owner-approved
## proposal: "Ghost crews do leave corpses (they are the dead of the sea), so the
## necromancer raises the Brotherhood's own dead here"). A deck body like any
## boarder (it comes by boat, the deck clamps it, a knock past the rail drowns
## it); what the ghost crew adds:
##   * THE LOOK: it wears its roster kind's sprite (row "wears",
##     Enemy.wears) with the spectre tint (MaelstromEnemyData.GHOST_TINT): no
##     ghost-crew art was drawn (docs/tide/ART_MANIFEST.md);
##   * THE RAISE: its death on the deck tells the stage
##     (MaelstromDirector.on_ghost_died(), the one raise of the Brotherhood's
##     own dead, through HordeDirector.raise_corpse()); a ghost that drowned or
##     died off a Maelstrom deck (no director) leaves nothing to raise.
## Subclasses (ghost_deckhand_kit.gd, ghost_gunner_kit.gd) only name the kit.
## Determinism: no RNG.
class_name GhostCrewKit
extends CorsairKit


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	var key := String(d.get("wears", ""))
	if key != "" and SpriteBank.has(key):
		e.wears = key  # The roster sprite, spectre-tinted (no ghost-crew art).
		e.wear_tint = MaelstromEnemyData.GHOST_TINT


func on_killed(e: Enemy) -> void:
	super.on_killed(e)
	var md := e.game.enemies.maelstrom
	if md != null:
		md.on_ghost_died(e)


## A pale glow under the drowned (visual only).
func draw_under(e: Enemy) -> void:
	SpriteBank.draw_disc(e, Vector2.ZERO, e.radius * 1.3, Color(Palette.CORSAIR_SPECTRE, 0.16))
