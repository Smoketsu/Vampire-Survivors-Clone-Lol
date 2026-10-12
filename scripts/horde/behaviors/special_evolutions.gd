## SpecialEvolutions — the shared bits of the two summon evolutions that
## upgrade a class special instead of adding a new kit (owner-approved;
## recipes and numbers in SummonEvolutionData, mechanics in the behaviours):
##   Shadow Reaper    (Grave Rogue + Bound Souls)       RogueBehavior: halved
##                    dash cooldown, chained dashes, stacking bleeds and a
##                    dash-kill cooldown reset.
##   Cathedral Horror (Crypt Gargoyle + Unholy Resilience) GargoyleBehavior:
##                    wider swoop, a stun on the dive (CombatResolver.
##                    stun_enemy()) and a stone form after landing
##                    (SummonedUnit.stone_form: no damage taken).
## This file builds their evolution-card lines (SummonEvolutions.
## build_offer()) and their autotest summary line, so the shared files only
## get one-line hooks. Data only in SummonEvolutionData; no state here.
class_name SpecialEvolutions
extends RefCounted


## Card lines for the special upgrades of evolution `evo`: `cur` and `nxt`
## are the class's effective stats without / with the evolution overlay
## (HordeDirector.compute_stats()). Empty for the other evolutions.
static func card_lines(evo: String, cur: Dictionary, nxt: Dictionary) -> PackedStringArray:
	var out := PackedStringArray()  # Card lines.
	var a: Dictionary = cur.get("special", {})  # Special numbers before.
	var b: Dictionary = nxt.get("special", {})  # Special numbers after.
	match evo:
		"shadow_reaper":
			SummonBehaviors._delta(out, "Dash cooldown (s)", a, b, "dash_cooldown")
			if int(b.get("chain_dashes", 0)) > 0:
				out.append("NEW  Each dash chains to %d more foe%s" % [int(b["chain_dashes"]), "" if int(b["chain_dashes"]) == 1 else "s"])
			if int(b.get("bleed_stacks", 1)) > 1:
				out.append("NEW  Bleeds stack up to %d times" % int(b["bleed_stacks"]))
			if int(b.get("dash_kill_reset", 0)) > 0:
				out.append("NEW  A kill mid-dash resets the cooldown")
		"cathedral_horror":
			SummonBehaviors._delta(out, "Swoop radius", a, b, "swoop_radius")
			if float(b.get("stun_duration", 0.0)) > 0.0:
				out.append("NEW  The dive stuns foes for %ss" % SummonBehaviors._f(b["stun_duration"]))
			if float(b.get("stone_duration", 0.0)) > 0.0:
				out.append("NEW  Turns to stone for %ss after landing: takes no damage" % SummonBehaviors._f(b["stone_duration"]))
	return out


## Autotest summary of both evolutions' new mechanics (game.stats keys set
## by RogueBehavior, GargoyleBehavior, CombatResolver and Enemy).
static func summary_line(game: Game) -> String:
	var st := game.stats
	return "shadow reaper: chain dashes %d, cooldown resets %d, bleed stacks added %d, max stacks %d, rogue bleed dmg (all) %d | cathedral horror: stuns %d (boss %d), stunned s %.1f, stone forms %d, stone s %.1f, dmg prevented by stone %d" % [
		int(st.get("reaper_chain_dashes", 0.0)), int(st.get("reaper_cd_resets", 0.0)), int(st.get("reaper_bleed_stacks_added", 0.0)),
		int(st.get("reaper_max_bleed_stacks", 0.0)), int(st.get("dmg_rogue_bleed", 0.0)),
		int(st.get("horror_stuns", 0.0)), int(st.get("horror_boss_stuns", 0.0)), float(st.get("enemy_stunned_seconds", 0.0)),
		int(st.get("horror_stone_forms", 0.0)), float(st.get("horror_stone_seconds", 0.0)), int(st.get("horror_stone_dmg_prevented", 0.0))]
