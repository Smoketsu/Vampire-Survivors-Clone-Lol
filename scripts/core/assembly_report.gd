## AssemblyReport — the autotest summary lines of the Assembly Halls' rewards
## (Act III; GDD §15.0 "The Assembly Halls (Act III phase 2)"), called once by
## Autotest.finish() on EVERY stage (the items are offered on every stage once
## unlocked; --spells= / --classes= / --passives= force them anywhere). Each
## line prints only when its item was owned (or the class raised) this run, so
## every other run's summary keeps its exact text:
##   hollow puppet:  the spell (level, evolved, damage, puppets, deaths,
##                   bursts) and Strings of the Dead (level, taunts)
##   class grave_drone: the class (level, alive, deaths, damage, darts) and
##                   Overclock (level)
##   signal ghost:   the counter-passive (level, Lock-On paints on you)
##   marionette:     the character's innate at work (puppet seconds added)
## Read-only: it never changes the run.
class_name AssemblyReport
extends RefCounted


## Prints every line that applies to this run.
static func print_items(game: Game, st: Dictionary) -> void:
	var ab := game.abilities
	var i := func(key: String) -> int: return int(st.get(key, 0.0))
	var lvl := ab.spell_level("hollow_puppet")
	var strings := ab.passive_level("strings_of_the_dead")
	if lvl > 0 or strings > 0:
		var node: NecroSpell = ab.spells.nodes.get("hollow_puppet")  # The spell node (null if never ticked).
		print("[autotest] hollow puppet: Lv%d%s dmg=%d (bursts %d) boss=%d %s | strings_of_the_dead Lv%d taunts=%d" % [
			lvl, " EVOLVED" if ab.evolved.has("hollow_puppet") else "", int(ab.spells.damage_of("hollow_puppet")),
			i.call("dmg_" + PuppetData.BURST_SOURCE), i.call("bossdmg_" + PuppetData.SOURCE) + i.call("bossdmg_" + PuppetData.BURST_SOURCE),
			node.summary_extra() if node != null else "", strings, i.call("strings_taunts")])
	var cls := "grave_drone"
	if int(game.horde.class_levels[cls]) > 0 or ab.passive_level("overclock") > 0:
		print("[autotest] class %s: Lv %d, alive %d/%d, deaths %d | dmg %d (grave_drone=%d wraith_drone=%d) | darts=%d | overclock Lv%d" % [
			cls, int(game.horde.class_levels[cls]), game.horde.count_of(cls), game.horde.capacity(cls),
			int(Autotest._sum_prefix(st, "death_%s_by_" % cls)),
			i.call("dmg_grave_drone") + i.call("dmg_wraith_drone"), i.call("dmg_grave_drone"), i.call("dmg_wraith_drone"),
			i.call("drone_darts"), ab.passive_level("overclock")])
	if ab.passive_level("signal_ghost") > 0:
		print("[autotest] signal ghost: Lv%d (paint time on you x%.2f) | lock-on paints on you %d, rails reached you %d" % [
			ab.passive_level("signal_ghost"), 1.0 + ab.passive_value("signal_ghost", "paint_time"),
			i.call("lockon_on_player"), i.call("los_heavy_player")])
	if game.character.innate_value("puppet_duration") > 0.0:
		print("[autotest] marionette: Puppeteer innate (puppets +%d%% life, +%d%% damage) | puppets raised %d" % [
			roundi(game.character.innate_value("puppet_duration") * 100.0), roundi(game.character.innate_value("puppet_damage") * 100.0),
			i.call("puppets_raised")])
