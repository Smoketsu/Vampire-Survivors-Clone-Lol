## GraveSpellLines — the one concrete, player-visible consequence line of a
## level-up card for the three new passives of the later spells (GDD §34
## "player-visible"; NecroSpellBook.passive_example() calls passive_line()):
##   Grim Ledger    — what a 100-damage hit on an elite deals now -> next.
##   Spirit Binding — the owned spell's slow (or a 2 s freeze) now -> next.
##   Restless Dead  — a raised skeleton's life now -> next.
## Values "now" come from the current passive level, `nxt` is the next
## level's row. Text only, no gameplay.
class_name GraveSpellLines
extends RefCounted

## Example hit (damage) shown on the Grim Ledger card.
const LEDGER_EXAMPLE_HIT: float = 100.0  # TUNING (not in GDD) card text only
## Example freeze (s) shown on the Spirit Binding card when no owned spell slows.
const BINDING_EXAMPLE_FREEZE: float = 2.0  # TUNING (not in GDD) card text only


## The card line of passive `id` ("" when there is nothing to show).
static func passive_line(game: Game, id: String, nxt: Dictionary) -> String:
	var ab := game.abilities  # The owning AbilityManager.
	match id:
		"grim_ledger":
			var cur := LEDGER_EXAMPLE_HIT * (1.0 + ab.passive_value(id, "elite_damage"))  # Damage now.
			var nx := LEDGER_EXAMPLE_HIT * (1.0 + float(nxt["elite_damage"]))  # Damage after the card.
			return "A %s-damage hit on an elite: %s -> %s" % [AbilityManager._fmt(LEDGER_EXAMPLE_HIT), AbilityManager._fmt(cur), AbilityManager._fmt(nx)]
		"spirit_binding":
			var k := (1.0 + float(nxt["cc_duration"])) / (1.0 + ab.passive_value(id, "cc_duration"))  # Ratio after / before.
			for spell: String in ["soul_chains", "shadow_blast"]:
				if ab.spell_level(spell) > 0:
					var d := float(ab.spell_stats(spell)["slow_duration"]) * game.combat.cc_mult()  # Slow now (s).
					return "%s slow %ss -> %ss" % [ab.spell_name(spell), AbilityManager._fmt(d), AbilityManager._fmt(d * k)]
			var f := BINDING_EXAMPLE_FREEZE * game.combat.cc_mult()  # Example freeze now (s).
			return "A %ss freeze: %ss -> %ss" % [AbilityManager._fmt(BINDING_EXAMPLE_FREEZE), AbilityManager._fmt(f), AbilityManager._fmt(f * k)]
		"restless_dead":
			var base := GraveSpellData.DEATH_MARK_RISEN_LIFE  # Life (s) shown, before the passive.
			var label := "Death Mark Risen"  # Whose life is shown.
			if ab.spell_level("raise_dead") > 0:
				base = float(ab.spell_stats("raise_dead")["life"])
				label = "Raised skeleton"
			var cur := base * (1.0 + ab.passive_value(id, "temp_duration"))  # Life now (s).
			var nx := base * (1.0 + float(nxt["temp_duration"]))  # Life after the card (s).
			return "%s life %ss -> %ss" % [label, AbilityManager._fmt(cur), AbilityManager._fmt(nx)]
	return ""
