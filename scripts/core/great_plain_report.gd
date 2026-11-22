## GreatPlainReport — the autotest summary lines of THE GREAT PLAIN and its
## rewards (temporary Act XIV, the Age of Titans; GDD §15.0 "The Great Plain
## (Act XIV phase 2)" and the rows after it). Read-only: it never changes the
## run. Two entry points:
##   stage_lines(game, st) — from PrimevalReport.print_lines() (only when the
##       Titans' rules ran), each line only when its system ran:
##     great plain: GreatPlainDirector (the watering hole: lakes, herds,
##                  fights and their stampedes; Mother Clubtail; the
##                  Horncharger's charges, the Clubtail's sweeps; Nothing
##                  Taken; the events)
##     ironbrow:    Old Ironbrow's fight (when he was the boss)
##   item_lines(game, st) — from Autotest.finish() on every stage, only when one
##       of the Great Plain's items was taken (so other runs print as before):
##     act XIV spell:   Stampede / Herd of Ages
##     act XIV passive: Calcified Hide, Hoarder's Bones
class_name GreatPlainReport
extends RefCounted


## The stage's lines (see the header).
static func stage_lines(game: Game, st: Dictionary) -> void:
	var en := game.enemies  # The enemy director.
	if en.great_plain != null:
		print("[autotest] great plain: %s" % en.great_plain.summary_line())
	if String(en.boss_info.get("id", "")) == String(GreatPlainStage.BOSS["id"]) and en.boss is BossIronbrow:
		print("[autotest] ironbrow: %s" % BossIronbrow.summary_line(st))


## The items' lines (see the header).
static func item_lines(game: Game, st: Dictionary) -> void:
	var ab := game.abilities  # Spell and passive levels.
	var lvl := ab.spell_level(StampedeData.ID)  # 0 = never learned.
	if lvl > 0:
		var node: NecroSpell = ab.spells.nodes.get(StampedeData.ID)  # The spell node (null if never ticked).
		print("[autotest] act XIV spell: stampede: Lv%d%s dmg=%d (herd of ages %d) boss=%d kills=%d %s" % [lvl,
			" EVOLVED" if ab.evolved.has(StampedeData.ID) else "", int(ab.spells.damage_of(StampedeData.ID)),
			int(st.get("dmg_" + StampedeData.EVOLVED_SOURCE, 0.0)),
			int(st.get("bossdmg_" + StampedeData.SOURCE, 0.0)) + int(st.get("bossdmg_" + StampedeData.EVOLVED_SOURCE, 0.0)),
			int(ab.spells.kills_of(StampedeData.ID)), node.summary_extra() if node != null else ""])
	var hide := ab.passive_level(StampedeData.CALCIFIED_HIDE)  # Calcified Hide level.
	if hide > 0:
		print("[autotest] act XIV passive: calcified_hide Lv%d (tramples +%d%%, width +%d px)" % [
			hide, roundi(100.0 * ab.passive_value(StampedeData.CALCIFIED_HIDE, StampedeData.DAMAGE_KEY)),
			roundi(ab.passive_value(StampedeData.CALCIFIED_HIDE, StampedeData.WIDTH_KEY))])
	var hb := ab.passive_level(PrimevalRulesData.HOARDERS_BONES)  # Hoarder's Bones level.
	if hb > 0:
		print("[autotest] act XIV passive: hoarders_bones Lv%d (safe %d px, drops after %.1f s: %d drops)" % [
			hb, roundi(ab.passive_value(PrimevalRulesData.HOARDERS_BONES, PrimevalRulesData.HOARDERS_BONES_KEY)),
			ab.passive_value(PrimevalRulesData.HOARDERS_BONES, PrimevalRulesData.HOARDERS_BONES_DROP_KEY),
			int(st.get("scav_hoarder_drops", 0.0))])
