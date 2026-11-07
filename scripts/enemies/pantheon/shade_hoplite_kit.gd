## ShadeHopliteKit — the kit of the Underworld's dead hoplites (UnderworldEnemyData
## "shade_hoplite", and Hades' guard "tartarus_warden"; Act IV, the Asphodel
## Underworld; GDD §15.0 "The Asphodel Underworld (Act IV phase 2)"): soldiers of
## a thousand wars, still in the ranks they died in. PHALANX: shoulder to
## shoulder they lock shields like the living (the Phalanx node does the test;
## the front is PantheonRules.hit_from_front()). They wear the Hoplite's art,
## tinted pale (row "wears" / "wear_tint", the Enemy's borrowed-sprite path
## also used by the Drowned Thrall; own decision, no new art). Everything else
## is the shared melee AI and the PantheonKit facing. No RNG.
class_name ShadeHopliteKit
extends PantheonKit


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	e.wears = String(def.get("wears", ""))
	e.wears_class = "warrior"  # Fallback glyph without the borrowed art.
	e.wear_tint = def.get("wear_tint", Color.WHITE)
