## AcidSpitterKit — the kit of the ACID SPITTER (ConcordEnemyData
## "acid_spitter"; Act IX, the Brood; GDD §15.0 "The Crash Site (Act IX phase
## 2)"; owner-approved proposal: "Acid Spitter | Brood | Ranged | Lobs acid
## that leaves a burning puddle; arcing, so it ignores the ring | Kill it on
## approach"). A green insect with a swollen glowing acid sac (a creature).
## The shared ranged AI walks it in and keeps it at range; its attack is a LOB
## through THE ACID PATH (ConcordRules.acid, AcidPools.lob(); never
## ProjectileManager): an arcing glob to its target's spot (fixed at the
## throw) in lob_flight s, with a landing telegraph; it splashes for
## acid_impact and leaves a puddle of acid_radius px for acid_life s burning
## summons and the necromancer for acid_dps, every number x its damage scaling
## (CovenantKit.hit_scale()). A refused lob (the acid cap) is simply lost.
## Determinism: no RNG. Stats: acid_spitter_lobs (AcidPools counts the rest).
class_name AcidSpitterKit
extends ConcordKit


## The ranged attack: a lob of acid at `t`'s spot. Always true (never a
## ProjectileManager shot).
func fire_ranged(e: Enemy, t: Node2D, _dir: Vector2, _dmg: float) -> bool:
	var scale := hit_scale(e)
	rules(e).acid.lob(e.position + Vector2(0.0, -e.radius * 0.6), t.position, {
		"flight": float(d.get("lob_flight", 0.9)),
		"radius": float(d.get("acid_radius", 28.0)),
		"life": float(d.get("acid_life", 3.5)),
		"dps": float(d.get("acid_dps", 3.0)) * scale,
		"impact": float(d.get("acid_impact", 3.0)) * scale,
		"umult": e.undead_damage_mult,
		"source": e.kind,
	})
	e.game.stat_add("acid_spitter_lobs", 1.0)
	return true


## Its acid sac glows slowly (visual only).
func draw_over(e: Enemy, ci: CanvasItem) -> void:
	var a := 0.22 + 0.14 * sin(e.game.elapsed * 2.2 + float(e.think_slot))
	SpriteBank.draw_disc(ci, Vector2(-e.radius * 0.5, -e.radius * 0.2), e.radius * 0.55, Color(AcidPools.ACID_COLOR, a))
