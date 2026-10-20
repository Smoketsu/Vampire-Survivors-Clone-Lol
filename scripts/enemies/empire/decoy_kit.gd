## DecoyKit — Kestrel's Decoy Drone (WastesEnemyData "kestrel_decoy"; Act III,
## the Scrap Wastes, GDD §15.0 "The Scrap Wastes (Act III phase 2)";
## owner-approved proposal: "she releases decoy drones"). A hovering projector
## drone (a MACHINE) that shows a flickering hologram of Kestrel. It walks and
## fires like every Empire shooter (EmpireKit: short bursts through EmpireShots,
## Line of Fire applies) and ranks at the top of every summon's target list
## (its row's target_priority 1.0: the army spends its fire on the hologram).
## After decoy_life s it fizzles out (EnemyDirector.despawn(): no kill, no XP).
## Its body is the hologram (draws_body()): Kestrel's sprite drawn see-through
## in signal amber with scan lines (a drawn effect, not a skin), the small
## projector under it. Stats: wastes_decoys_fizzled. No RNG.
class_name DecoyKit
extends EmpireKit

## Seconds since it appeared.
var age: float = 0.0


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	age = 0.0


## Ages the decoy (it fizzles out at decoy_life) and fires its bursts.
func physics(e: Enemy, delta: float) -> bool:
	age += delta
	if age >= float(d["decoy_life"]):
		e.game.effects.pop(e.position, Palette.EMPIRE_SIGNAL_AMBER, 10.0)
		e.game.stat_add("wastes_decoys_fizzled", 1.0)
		e.game.enemies.despawn(e)
		return true
	if int(age * 12.0) != int((age - delta) * 12.0):
		e.queue_redraw()  # The hologram flickers (visual only).
	return super.physics(e, delta)


## The hologram replaces the kind's look (see the header).
func draws_body(_e: Enemy) -> bool:
	return true


## The hologram of Kestrel over a little projector. Visual only.
func draw_body(e: Enemy, ci: CanvasItem) -> void:
	var flick := 0.45 + 0.15 * float(int(age * 12.0) % 3)  # Opacity flicker.
	ci.draw_circle(Vector2(0, e.radius * 0.9), 4.0, Palette.EMPIRE_CHROME_DARK)
	ci.draw_circle(Vector2(0, e.radius * 0.9), 2.0, Palette.EMPIRE_SIGNAL_AMBER)
	var tint := Color(1.0, 0.72, 0.38, flick)  # The hologram's amber cast.
	if not SpriteBank.draw(ci, "bosses/kestrel", Vector2(0, -2), e.flash > 0.0, tint):
		WastesGlyphs.draw_kestrel(ci, Vector2(0, -2), e.radius, e.flash > 0.0, tint, 0)
	var h := e.radius * 2.6  # Scan line span (px).
	for i in 5:
		var y := -h * 0.75 + h * float(i) / 5.0 + fmod(age * 18.0, h / 5.0)
		ci.draw_line(Vector2(-e.radius, y), Vector2(e.radius, y), Color(Palette.EMPIRE_SIGNAL_GLOW, 0.16), 1.0)
