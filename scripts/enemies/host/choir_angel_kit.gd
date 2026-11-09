## ChoirAngelKit — the kit of the CHOIR ANGEL (female, figure style;
## HostEnemyData "choir_angel"; temporary Act XIII, the Celestial Host; GDD
## §15.0 "The Celestial Host foundation (phase 1)"; proposal: "Her hymn heals
## angels within 200 px | Priority target"). Her heal is the existing
## enemy-heal path (behavior "healer": Enemy._try_heal() ->
## CombatResolver.heal_enemy(); a Keening Lady's silence stops it), so the kit
## adds only the hymn's look: a faint dawn-rose ring at her feet (visual only).
## Phase 2 (the Empyrean's Choir) reads HostRules.choir for her count.
class_name ChoirAngelKit
extends HostKit


## A faint dawn-rose ring at her feet: the hymn (visual only).
func draw_under(e: Enemy) -> void:
	e.draw_texture_rect(SpriteBank.disc(), Rect2(Vector2(-e.radius * 1.7, e.radius * 0.4), Vector2(e.radius * 3.4, e.radius * 1.1)),
			false, Color(Palette.HOST_ROSE, 0.3))
