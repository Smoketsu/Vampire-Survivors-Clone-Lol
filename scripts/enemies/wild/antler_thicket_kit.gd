## AntlerThicketKit — the kit of one thorn of THE ANTLER CROWN (GreenwoodEnemyData
## "antler_thicket"; temporary Act XV, the Greenwood; GDD §15.0 "The Stag King
## (Act XV phase 2)"; owner-approved proposal: "his antlers grow a thicket ring
## around him that must be burned through before he can be hurt"). A structure
## the Stag King grows round himself (BossStagKing.grow_crown()); every tick it
## keeps its place on the ring (`king` + `offset`), so the crown walks with him.
## While one stands the king takes no damage (BossStagKing.damage_taken_mult());
## it falls to damage, or to fire (BossStagKing.crown_burn(), Thickets' ring
## hook). With its king gone it withers at once. Determinism: no RNG, no
## instance ids.
class_name AntlerThicketKit
extends WildKit

## The king whose crown it is (null when free; generation-checked).
var king: Enemy = null
## Generation of `king` when it grew.
var king_gen: int = 0
## Its place on the ring, from the king's centre (px).
var offset: Vector2 = Vector2.ZERO


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	king = null
	offset = Vector2.ZERO


## Binds the thorn to king `k` at `p_offset` px from his centre.
func bind(k: Enemy, p_offset: Vector2) -> void:
	king = k
	king_gen = k.generation
	offset = p_offset


func physics(e: Enemy, _delta: float) -> bool:
	e.velocity = Vector2.ZERO
	e.knockback = Vector2.ZERO
	if king == null or not (king.active and king.generation == king_gen):
		king = null
		e.game.enemies.despawn(e)  # The crown withers with its king (no kill, no drop).
		return true
	e.position = king.position + offset
	return true
