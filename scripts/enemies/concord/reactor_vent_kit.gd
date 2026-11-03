## ReactorVentKit — the kit of a Reactor Vent (ArkEnemyData "reactor_vent";
## Act IX, the Ark of the Concord's Reactor; GDD §15.0 "The Ark of the Concord
## (Act IX phase 2)"; brief: "The Reactor: vents that seed turf
## (Terraforming.seed(), tag vents) on a timer. They are structures; breaking
## one stops it"). A STRUCTURE (a grated reactor vent breathing plasma).
## ArkDirector raises it in the Reactor (or --spawn= drops one to test). Every
## vent_every s while it stands, it BREATHES: live alien ground vent_radius px
## round it through Terraforming.seed(at, r, {"live": true, "tag": "vents"})
## (THE ground: the Concord heals on it, the necromancer's spells burn it).
## Broken, it stops (its ground stays until burnt). It never heals on turf.
## Off an Act IX stage the rules exist (ConcordKit) and it seeds the same.
## Determinism: no RNG. Stats: ark_vent_breaths, terra_seeded_vents (the
## shared seed stat), ark_vents_broken.
class_name ReactorVentKit
extends ConcordKit

## Seconds until its next breath.
var breath_cd: float = 0.0


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	e.is_objective = true  # It stands until broken (never recycled).
	breath_cd = first_cd(e, float(d.get("vent_first", 2.0)))


func on_killed(e: Enemy) -> void:
	super.on_killed(e)
	e.game.stat_add("ark_vents_broken", 1.0)
	e.game.effects.ring(e.position, 40.0, Palette.CONCORD_PLASMA_DARK, 0.4)
	if e.game.enemies.ark != null:
		e.game.enemies.ark.on_vent_broken(e)


## Every vent_every s: a breath of live turf round it. Always false: the
## structure's own step holds it still.
func physics(e: Enemy, delta: float) -> bool:
	breath_cd -= delta
	if breath_cd <= 0.0:
		breath_cd = float(d.get("vent_every", 9.0))
		rules(e).terraforming.seed(e.position, float(d.get("vent_radius", 110.0)), {"live": true, "tag": "vents"})
		e.game.stat_add("ark_vent_breaths", 1.0)
		e.game.effects.ring(e.position, float(d.get("vent_radius", 110.0)) * 0.6, Palette.CONCORD_PLASMA, 0.5)
		rules(e).play_sound("ground_burn", e.position, 0.8)
	return false  # The structure's own step follows (it stands still).


## Its grating glows brighter toward the next breath (visual only).
func draw_over(e: Enemy, ci: CanvasItem) -> void:
	var every := maxf(float(d.get("vent_every", 9.0)), 0.1)
	var k := 1.0 - clampf(breath_cd / every, 0.0, 1.0)
	SpriteBank.draw_disc(ci, Vector2(0.0, -e.radius * 0.5), e.radius * (0.35 + 0.25 * k), Color(Palette.CONCORD_PLASMA, 0.25 + 0.45 * k))
