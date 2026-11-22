## EinherjarKit — the kit of the feasting Einherjar (ValgardEnemyData
## "einherjar"; Valgard, the Hall of Heroes, the Hall of the Slain temporarily
## Act XI; GDD §15.0 "Valgard, the Hall of Heroes (the Hall of the Slain phase
## 2)"; owner-approved proposal: "The Feast: Einherjar sit at the long tables as
## obstacles that wake whenever a horn blows, then fight"). Every body of this
## kind IS an Einherjar: reset() makes it one at once
## (NorseKit.make_einherjar(): gold-lit, NorseRulesData.EINHERJAR stronger),
## wherever it comes from (a table of the Feast, ValgardDirector.wake_feast();
## Sigrun's Doors of the Hall; the timeline; --spawn=einherjar). No special of
## its own: a WARRIOR of the hall (Berserkergang drives it) that runs the shared
## AI with everything NorseKit gives every Norse kind. No RNG.
class_name EinherjarKit
extends NorseKit


func reset(e: Enemy, def: Dictionary) -> void:
	super.reset(e, def)
	make_einherjar(e)
	e.game.stat_add("einherjar_risen", 1.0)
