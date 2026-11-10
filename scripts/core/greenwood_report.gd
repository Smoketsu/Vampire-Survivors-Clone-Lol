## GreenwoodReport — the autotest summary lines of THE GREENWOOD and its rewards
## (temporary Act XV, the Turning Year; GDD §15.0 "The Greenwood (Act XV phase
## 2)" and the rows after it). Read-only: it never changes the run. Two entry
## points:
##   stage_lines(game, st) — from WildReport.print_lines() (only when the Wild's
##       rules ran), each line only when its system ran:
##     greenwood:      GreenwoodDirector (the sacred groves, the Huntsman of the
##                     Wild Hunt, Scorched Earth, the events)
##     wild specials:  the shared kinds' specials (the Treant's roots, the Fae
##                     Knight's blinks, the Great Stag's and the Riders' charges
##                     and hounds, the Wisps' lures, the Spore Mothers' spores
##                     and mould, the Corpse-Blooms' meals and buds) on any
##                     stage where one of them acted
##     stag king:      the Stag King's fight (when he was the boss)
##   item_lines(game, st) — from Autotest.finish() on every stage, only when one
##       of the Greenwood's items was taken (so other runs print as before):
##     act XV spell:   Wild Hunt / The Endless Hunt
##     act XV passive: Horn of the Hunt, Fallow Ground
class_name GreenwoodReport
extends RefCounted


## The stage's lines (see the header).
static func stage_lines(game: Game, st: Dictionary) -> void:
	var en := game.enemies  # The enemy director.
	if en.greenwood != null:
		print("[autotest] greenwood: %s" % en.greenwood.summary_line())
	var sp := specials_line(st)
	if sp != "":
		print("[autotest] wild specials: %s" % sp)
	if en.boss is BossStagKing:
		print("[autotest] stag king: %s" % BossStagKing.summary_line(st))


## The "wild specials" line ("" when no special acted this run).
static func specials_line(st: Dictionary) -> String:
	var keys := ["treant_roots", "fae_blinks", "great_stag_charges", "wild_rider_charges", "hunt_hounds_brought", "wisp_lures",
		"spore_puffs", "bloom_meals", "huntsman_lines"]
	var any := false
	for k: String in keys:
		if float(st.get(k, 0.0)) > 0.0:
			any = true
	if not any:
		return ""
	return "treant roots %d | fae blinks %d | stag charges %d (hit %d, you %d) | rider sweeps %d (hit %d, you %d; hounds %d, hound hits %d; rode on %d) | wisp lures %d | spore puffs %d (rots %d, mould cells %d) | bloom meals %d (corpses eaten %d, thornlings budded %d) | huntsman sweeps hit %d, you %d" % [
		int(st.get("treant_roots", 0.0)), int(st.get("fae_blinks", 0.0)),
		int(st.get("great_stag_charges", 0.0)), int(st.get("great_stag_charge_hits", 0.0)), int(st.get("great_stag_charge_on_you", 0.0)),
		int(st.get("wild_rider_charges", 0.0)), int(st.get("wild_rider_charge_hits", 0.0)), int(st.get("wild_rider_charge_on_you", 0.0)),
		int(st.get("hunt_hounds_brought", 0.0)), int(st.get("hunt_hound_charge_hits", 0.0)), int(st.get("hunt_riders_passed", 0.0)),
		int(st.get("wisp_lures", 0.0)), int(st.get("spore_puffs", 0.0)), int(st.get("spore_rots", 0.0)), int(st.get("mould_cells", 0.0)),
		int(st.get("bloom_meals", 0.0)), int(st.get("bloom_corpses_eaten", 0.0)), int(st.get("bloom_buds", 0.0)),
		int(st.get("huntsman_charge_hits", 0.0)), int(st.get("huntsman_charge_on_you", 0.0))]


## The items' lines (see the header).
static func item_lines(game: Game, st: Dictionary) -> void:
	var ab := game.abilities  # Spell and passive levels.
	var lvl := ab.spell_level(WildHuntData.ID)  # 0 = never learned.
	if lvl > 0:
		var node: NecroSpell = ab.spells.nodes.get(WildHuntData.ID)  # The spell node (null if never ticked).
		print("[autotest] act XV spell: wild_hunt: Lv%d%s dmg=%d (the endless hunt %d) boss=%d kills=%d %s" % [lvl,
			" EVOLVED" if ab.evolved.has(WildHuntData.ID) else "", int(ab.spells.damage_of(WildHuntData.ID)),
			int(st.get("dmg_" + WildHuntData.EVOLVED_SOURCE, 0.0)),
			int(st.get("bossdmg_" + WildHuntData.SOURCE, 0.0)) + int(st.get("bossdmg_" + WildHuntData.EVOLVED_SOURCE, 0.0)),
			int(ab.spells.kills_of(WildHuntData.ID)), node.summary_extra() if node != null else ""])
	var horn := ab.passive_level(WildHuntData.HORN)  # Horn of the Hunt level.
	if horn > 0:
		print("[autotest] act XV passive: horn_of_the_hunt Lv%d (riders strike +%d%%, wider +%d px)" % [
			horn, roundi(100.0 * ab.passive_value(WildHuntData.HORN, WildHuntData.DAMAGE_KEY)),
			roundi(ab.passive_value(WildHuntData.HORN, WildHuntData.WIDTH_KEY))])
	var fg := ab.passive_level(WildRulesData.FALLOW_GROUND)  # Fallow Ground level.
	if fg > 0:
		print("[autotest] act XV passive: fallow_ground Lv%d (blight rises +%d%%)" % [
			fg, roundi(100.0 * ab.passive_value(WildRulesData.FALLOW_GROUND, WildRulesData.FALLOW_GROUND_KEY))])
