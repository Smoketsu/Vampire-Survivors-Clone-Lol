## ArchiveHazardOverlay — the part of ArchiveHazards drawn ABOVE the bodies:
## the Archivist's flying pages and the Scribes' ink sigil over every cursed
## cultist (Enemy.claimer_until; a cursed cultist claims the dead around it).
## A child of ArchiveHazards with an absolute z_index; redrawn every frame
## while anything is shown. Purely visual: it only reads.
class_name ArchiveHazardOverlay
extends Node2D

## The hazards it draws for.
var hazards: ArchiveHazards
## True if anything was drawn last frame (one more redraw clears it).
var _drew: bool = false


## Called by ArchiveHazards.step(): redraws while pages fly or curses hold.
func step() -> void:
	var busy := not hazards.pages.is_empty() or _any_cursed()
	if busy or _drew:
		queue_redraw()
	_drew = busy


## True if a living enemy carries a Scribe's curse.
func _any_cursed() -> bool:
	var now := hazards.game.elapsed
	for e in hazards.game.enemies.active:
		if e.active and e.claimer_until > now:
			return true
	return false


func _draw() -> void:
	var g := hazards.game
	var now := g.elapsed
	for e in g.enemies.active:
		if e.active and e.claimer_until > now:
			ArchiveGlyphs.draw_curse_sigil(self, e.position + Vector2(0.0, e.marker_y(-e.radius * 2.2)), now, e.claimer_until - now)
	for p in hazards.pages:
		ArchiveGlyphs.draw_page(self, p.pos, p.vel.angle(), p.t, p.rise_left > 0.0)
