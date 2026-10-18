## AbyssalPact — the Abyssal Pact passive's soul burst (PassiveData
## "abyssal_pact"; Act II, GDD §15.0 "Ul-Thalos, the Risen Spire"; unlocked by
## slaying Vhal'Neth): every TEMPORARY summon (a Drowned Thrall, a Death Mark
## Risen, a Raise Dead / Legion skeleton, a Lich's raised dead, a stage
## reinforcement) releases a soul burst when it crumbles or falls, healing
## every other summon within burst_radius px by burst_heal HP through
## CombatResolver.heal_unit(). ONE call from HordeDirector.on_unit_died(); a
## no-op while the passive is not owned (every Act I run). Deterministic:
## positions only. Stats: abyssal_pact_bursts, abyssal_pact_heal.
class_name AbyssalPact
extends RefCounted

## Passive id (PassiveData).
const ID: String = "abyssal_pact"


## Temporary summon `u` is gone (expired or killed): its soul bursts.
static func on_temporary_gone(game: Game, u: SummonedUnit) -> void:
	var heal := game.abilities.passive_value(ID, "burst_heal")  # HP per summon (0 = not owned).
	if heal <= 0.0:
		return
	var r := game.abilities.passive_value(ID, "burst_radius")  # Reach (px).
	var healed := 0.0  # HP restored by this burst.
	for o in game.horde.units:
		if o != u and o.active and o.position.distance_to(u.position) <= r + o.radius:
			healed += game.combat.heal_unit(o, heal)
	game.stat_add("abyssal_pact_bursts", 1.0)
	game.stat_add("abyssal_pact_heal", healed)
	game.effects.ring(u.position, r, Color(0.45, 0.80, 0.74), 0.4)


## One-line autotest summary.
static func summary_line(game: Game) -> String:
	var st := game.stats
	return "abyssal_pact Lv%d bursts=%d heal=%d" % [game.abilities.passive_level(ID), int(st.get("abyssal_pact_bursts", 0.0)), int(st.get("abyssal_pact_heal", 0.0))]
