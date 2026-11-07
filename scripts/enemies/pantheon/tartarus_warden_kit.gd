## TartarusWardenKit — the kit of HADES' RING OF THE DEAD (UnderworldEnemyData
## "tartarus_warden"; Act IV, the Asphodel Underworld; GDD §15.0 "The Asphodel
## Underworld (Act IV phase 2)"; owner-approved proposal: "Lord of the Dead: he
## raises his own ring of the dead around himself, army against army, until his
## ring breaks"). A Shade Hoplite of Tartarus (ShadeHopliteKit: the Hoplite's
## art, dark; PHALANX, so the ring locks shields) bound to a POST on a circle
## around its lord: BossHades raises them and calls bind(). Each tick, farther
## than HadesData.BOSS warden_slack px from its post it walks back to it
## (warden_return_mult x its pace); at its post it fights whatever reaches it through the shared
## melee AI. Unbound (its lord gone) it is an ordinary Shade Hoplite. No RNG.
class_name TartarusWardenKit
extends ShadeHopliteKit

## The lord whose ring it holds (null = unbound).
var lord: Enemy = null
## Generation of `lord` when bound (stale guard).
var lord_gen: int = 0
## Angle (rad) of its post around the lord.
var post_angle: float = 0.0
## Radius (px) of the ring.
var post_radius: float = 64.0


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	lord = null


## Binds the Warden to post `angle` rad on a ring `radius` px around `p_lord`.
func bind(p_lord: Enemy, angle: float, radius: float) -> void:
	lord = p_lord
	lord_gen = p_lord.generation
	post_angle = angle
	post_radius = radius


## Holds its post: back to it when it strayed, else the shared AI.
func physics(e: Enemy, delta: float) -> bool:
	super.physics(e, delta)
	if lord == null or not lord.active or lord.generation != lord_gen:
		return false
	var post := lord.position + Vector2.from_angle(post_angle) * post_radius  # Its post (world px).
	var to := post - e.position
	if to.length() <= float(HadesData.BOSS["warden_slack"]):
		return false
	var spd := e.move_speed * float(HadesData.BOSS["warden_return_mult"]) * (1.0 - e.slow_factor if e.slow_timer > 0.0 else 1.0)
	e.velocity = to.normalized() * spd
	e.position += e.velocity * delta
	return true
