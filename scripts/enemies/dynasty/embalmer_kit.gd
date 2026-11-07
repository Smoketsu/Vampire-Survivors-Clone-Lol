## EmbalmerKit — the kit of the EMBALMER (female, figure style;
## DynastyEnemyData "embalmer"; temporary Act XII, the Necropolis Dynasty; GDD
## §15.0 "The Necropolis Dynasty foundation (phase 1)"; owner-approved
## proposal: "Wraps the fallen: the cartouche timer -3 s nearby and heals
## soldiers"). Her heal is the existing enemy-heal path (behavior "healer":
## Enemy._try_heal() -> CombatResolver.heal_enemy(); a Keening Lady's silence
## stops it). Her haste is Rebirth's: her row's "embalms" puts her on
## DynastyRules.embalmers (DynastyKit), and every cartouche within REBIRTH
## embalm_radius runs at embalm_speed (DynastyRules.embalm_rate()). Drawn:
## a faint linen ring at her feet while a cartouche she hastens is near
## (visual only).
class_name EmbalmerKit
extends DynastyKit


## A faint linen ring at her feet while a cartouche lies within her reach.
func draw_under(e: Enemy) -> void:
	var g := e.game
	if g.dynasty == null:
		return
	var r := float(g.dynasty.rebirth.cfg["embalm_radius"])
	for c in g.dynasty.rebirth.cartouches:
		if c.active and c.position.distance_to(e.position) <= r:
			e.draw_texture_rect(SpriteBank.disc(), Rect2(Vector2(-e.radius * 1.6, e.radius * 0.4), Vector2(e.radius * 3.2, e.radius * 1.1)),
					false, Color(Palette.DYN_LINEN, 0.35))
			return
