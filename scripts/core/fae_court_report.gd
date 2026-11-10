## FaeCourtReport — the autotest summary lines of THE FAE COURT and its rewards
## (temporary Act XV, the Turning Year; GDD §15.0 "The Fae Court (Act XV phase
## 2)" and the rows after it). Read-only: it never changes the run. Two entry
## points:
##   stage_lines(game, st) — from WildReport.print_lines() (only when the Wild's
##       rules ran), each line only when its system ran:
##     fae court:     FaeCourtDirector (the fairy rings' slows, the Winter Prince
##                    and his winter, the events)
##     summer queen:  the Summer Queen's fight (when she was the boss)
##     a fair bargain: the bargains struck and refused, the army damage and the
##                    heals the bargains barred (when she offered one)
##   item_lines(game, st) — from Autotest.finish() on every stage, only when one
##       of the Fae Court's items was taken (so other runs print as before):
##     act XV spell:   Glamour / Court of Masks
##     act XV passive: Changeling, Deadwood
## The big damage sources to the necromancer and the summons (her petals and
## blossoms, the courtiers, the Winter Prince's frost, a bargain's life cost,
## the endless summer's wildfires) each carry their own tag in the shared
## `wild damage` line.
class_name FaeCourtReport
extends RefCounted


## The stage's lines (see the header).
static func stage_lines(game: Game, st: Dictionary) -> void:
	var en := game.enemies  # The enemy director.
	if en.fae_court != null:
		print("[autotest] fae court: %s" % en.fae_court.summary_line())
	if en.boss is BossSummerQueen:
		print("[autotest] summer queen: %s" % BossSummerQueen.summary_line(st))
	if float(st.get("bargains_offered", 0.0)) > 0.0:
		print("[autotest] a fair bargain: offered %d, accepted %d, refused %d | army heals barred %d | life paid %d | earned %s" % [
			int(st.get("bargains_offered", 0.0)), int(st.get("bargains_accepted", 0.0)), int(st.get("bargains_refused", 0.0)),
			int(st.get("bargain_heals_barred", 0.0)), int(st.get("player_dmg_from_" + SummerQueenData.BARGAIN_SOURCE, 0.0)),
			"yes (if the run is won)" if fair_bargain(st, true) else "no"])


## True when the run's bargains make A Fair Bargain ("accept every bargain the
## Summer Queen offers and still win"): at least one offered, every one
## accepted, and `victory`. MetaProgress counts it.
static func fair_bargain(st: Dictionary, victory: bool) -> bool:
	var offered := int(st.get("bargains_offered", 0.0))
	return victory and offered > 0 and int(st.get("bargains_accepted", 0.0)) == offered


## The items' lines (see the header).
static func item_lines(game: Game, st: Dictionary) -> void:
	var ab := game.abilities  # Spell and passive levels.
	var lvl := ab.spell_level(GlamourData.ID)  # 0 = never learned.
	if lvl > 0:
		var node: NecroSpell = ab.spells.nodes.get(GlamourData.ID)  # The spell node (null if never ticked).
		print("[autotest] act XV spell: glamour: Lv%d%s dmg=%d (court of masks %d) boss=%d kills=%d %s" % [lvl,
			" EVOLVED" if ab.evolved.has(GlamourData.ID) else "", int(ab.spells.damage_of(GlamourData.ID)),
			int(st.get("dmg_" + GlamourData.EVOLVED_SOURCE, 0.0)),
			int(st.get("bossdmg_" + GlamourData.SOURCE, 0.0)) + int(st.get("bossdmg_" + GlamourData.EVOLVED_SOURCE, 0.0)),
			int(ab.spells.kills_of(GlamourData.ID)), node.summary_extra() if node != null else ""])
	var ch := ab.passive_level(GlamourData.CHANGELING)  # Changeling level.
	if ch > 0:
		print("[autotest] act XV passive: changeling Lv%d (copies +%.1f s, +%d%% HP)" % [
			ch, ab.passive_value(GlamourData.CHANGELING, GlamourData.LIFE_KEY), roundi(100.0 * ab.passive_value(GlamourData.CHANGELING, GlamourData.HP_KEY))])
	var dw := ab.passive_level(WildRulesData.DEADWOOD)  # Deadwood level.
	if dw > 0:
		print("[autotest] act XV passive: deadwood Lv%d (holds -%d%%)" % [
			dw, roundi(100.0 * ab.passive_value(WildRulesData.DEADWOOD, WildRulesData.DEADWOOD_KEY))])
