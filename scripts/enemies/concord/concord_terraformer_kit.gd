## ConcordTerraformerKit — the kit of the landing pod (ConcordEnemyData
## "concord_terraformer"; Act IX; GDD §15.0 "Terraforming"). A STRUCTURE that
## Terraforming drops on a telegraphed streak (or --spawn= drops to test): on
## activation it ROOTS (Terraforming.add_pod(): its patch grows one ring of
## cells every spread_every s up to pod_radius while a necromancer is near) and
## stands until broken (Enemy.is_objective: never recycled to the spawn ring).
## Destroyed, it stops growing (Terraforming.pod_destroyed()); its ground stays
## until burnt. It never heals on its own turf (row "heals_on_turf": false).
## Determinism: no RNG.
class_name ConcordTerraformerKit
extends ConcordKit


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	e.is_objective = true  # It stands until broken (never recycled).
	rules(e).terraforming.add_pod(e)


func on_killed(e: Enemy) -> void:
	super.on_killed(e)
	rules(e).terraforming.pod_destroyed(e)
	e.game.effects.ring(e.position, 34.0, Palette.CONCORD_PLASMA_DARK, 0.4)


## Its vents breathe a faint plasma glow over the pod (visual only).
func draw_over(e: Enemy, ci: CanvasItem) -> void:
	var a := 0.25 + 0.2 * sin(e.game.elapsed * 2.5)
	SpriteBank.draw_disc(ci, Vector2(0.0, -e.radius * 0.4), e.radius * 0.45, Color(Palette.CONCORD_PLASMA, a))
