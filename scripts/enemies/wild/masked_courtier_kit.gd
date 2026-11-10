## MaskedCourtierKit — the kit of a MASKED COURTIER, one face of the Summer
## Queen's Masque (FaeCourtEnemyData "masked_courtier"; temporary Act XV, the
## Turning Year; GDD §15.0 "The Summer Queen (Act XV phase 2)"; owner-approved
## proposal: "the Masque (glamour: she and her court change faces, and only hits
## reveal which is real)"). A fae courtier in a gown of roses:
##   * MASKED (from its first tick until a hit): drawn exactly as the Summer
##     Queen wears her mask (SummerQueenData.MASK_SPRITE, the same code shape
##     without the art), and every bolt_every s it throws one of her petal bolts
##     at the nearest necromancer within bolt_range px (the plain hostile shot,
##     tagged SummerQueenData.PETAL_SOURCE; bolt_damage x the time scaling);
##   * UNMASKED by the first hit it takes (taken_mult(), the kit's hook on every
##     hit; or by unmask() when the Queen herself is found): drawn as itself
##     (its own art wild/masked_courtier, else the Wild figure) and it fights on
##     with its thorn rapier (the shared melee AI).
## Determinism: no RNG, no instance ids. Stats: masque_unmasked, masque_bolts.
class_name MaskedCourtierKit
extends WildKit

## True while it wears the Queen's face.
var masked: bool = true
## Seconds until its next petal bolt.
var cd: float = 0.0


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	masked = true
	cd = first_cd(e, float(d.get("bolt_first", 1.0)))


## A hit unmasks it (the hit itself is not changed: 1).
func taken_mult(e: Enemy, _source: String) -> float:
	if masked:
		unmask(e)
	return 1.0


## Drops the mask: drawn as itself from now on.
func unmask(e: Enemy) -> void:
	if not masked:
		return
	masked = false
	e.game.stat_add("masque_unmasked", 1.0)
	e.game.effects.ring(e.position, e.radius * 2.0, SummerQueenData.PETAL, 0.3)
	e.queue_redraw()


## Masked, its petal bolt on its clock; the shared AI walks and strikes (false).
func physics(e: Enemy, delta: float) -> bool:
	if not masked:
		return false
	cd -= delta
	if cd > 0.0:
		return false
	cd = float(d.get("bolt_every", 2.8))
	var g := e.game
	var pl := g.nearest_player(e.position)
	if pl == null or pl.dead or e.position.distance_to(pl.position) > float(d.get("bolt_range", 340.0)):
		return false
	var to := pl.position - e.position
	g.projectiles.fire_hostile(e.position, to.normalized() if to.length() > 1.0 else Vector2.RIGHT,
			float(d.get("bolt_damage", 3.5)) * hit_scale(e), float(d.get("bolt_speed", 260.0)), e.undead_damage_mult,
			Projectile.Kind.RADIANT_BOLT, SummerQueenData.PETAL_SOURCE)
	g.stat_add("masque_bolts", 1.0)
	return false


## Masked, it is drawn as the Queen.
func draws_body(_e: Enemy) -> bool:
	return masked


## The Queen's masked face (her `_mask` art, else her code shape).
func draw_body(e: Enemy, ci: CanvasItem) -> void:
	BossSummerQueen.draw_masked(ci, e.flash > 0.0)
