## SpecimenTankKit — the kit of a Specimen Tank (ArkEnemyData "specimen_tank";
## Act IX, the Ark of the Concord's Specimen Vaults; GDD §15.0 "The Ark of the
## Concord (Act IX phase 2)"; owner-approved proposal: "the Specimen Vaults
## (break the tanks to free captured beasts that attack everyone)"). A
## STRUCTURE: a sealed tank of green fluid with a beast curled inside.
## ArkDirector raises it (or --spawn= drops one to test). It stands until
## broken (Enemy.is_objective: never recycled); broken, it FREES `beasts`
## vault beasts where it stood (ArkEnemyData "vault_beast", VaultBeastKit:
## they attack everyone) and tells the director (the wreck it draws, the
## report). It never heals on turf (row "heals_on_turf": false).
## Determinism: no RNG (the beasts stand on fixed turns round the tank).
## Stats: ark_tanks_broken, ark_beasts_freed.
class_name SpecimenTankKit
extends ConcordKit


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	e.is_objective = true  # It stands until broken (never recycled).


func on_killed(e: Enemy) -> void:
	super.on_killed(e)
	var g := e.game
	g.stat_add("ark_tanks_broken", 1.0)
	g.effects.ring(e.position, 36.0, Palette.CONCORD_PLASMA, 0.4)
	g.effects.pop(e.position, Palette.CONCORD_PLASMA, 22.0)
	rules(e).play_sound("saucer_down", e.position, 0.3)
	var n := int(d.get("beasts", 2))
	for i in n:
		var at := e.position + Vector2.from_angle(TAU * float(i) / float(maxi(1, n)) + float(e.think_slot)) * (e.radius + 8.0)
		var b := g.enemies.spawn_at(ArkEnemyData.BEAST, at, false)
		if b != null:
			g.stat_add("ark_beasts_freed", 1.0)
	if g.enemies.ark != null:
		g.enemies.ark.on_tank_broken(e)


## The fluid's slow glow inside the glass (visual only).
func draw_over(e: Enemy, ci: CanvasItem) -> void:
	var a := 0.18 + 0.12 * sin(e.game.elapsed * 1.6 + float(e.think_slot))
	SpriteBank.draw_disc(ci, Vector2(0.0, -e.radius * 0.9), e.radius * 0.55, Color(Palette.CONCORD_PLASMA, a))
