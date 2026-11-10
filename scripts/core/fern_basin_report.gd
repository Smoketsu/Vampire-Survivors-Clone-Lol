## FernBasinReport — the autotest summary lines of THE FERN BASIN and its
## rewards (temporary Act XIV, the Age of Titans; GDD §15.0 "The Fern Basin
## (Act XIV phase 2)" and the rows after it). Read-only: it never changes the
## run. Two entry points:
##   stage_lines(game, st) — from PrimevalReport.print_lines() (only when the
##       Titans' rules ran), each line only when its system ran:
##     fern basin:  FernBasinDirector (the tar: who it slowed, the beasts it
##                  trapped and the trapped kills; the Bog Crocs; Ironjaw and
##                  her nest; the events)
##     scarmaw:     Scarmaw's fight (when she was the boss)
##   item_lines(game, st) — from Autotest.finish() on every stage, only when one
##       of the Fern Basin's items was taken (so other runs print as before):
##     act XIV spell:   Pack Leap / Apex Pack
##     act XIV passive: Pack Instinct
class_name FernBasinReport
extends RefCounted


## The stage's lines (see the header).
static func stage_lines(game: Game, st: Dictionary) -> void:
	var en := game.enemies  # The enemy director.
	if en.fern_basin != null:
		print("[autotest] fern basin: %s" % en.fern_basin.summary_line())
	if String(en.boss_info.get("id", "")) == String(FernBasinStage.BOSS["id"]) and en.boss is BossScarmaw:
		print("[autotest] scarmaw: %s" % BossScarmaw.summary_line(st))


## The items' lines (see the header).
static func item_lines(game: Game, st: Dictionary) -> void:
	var ab := game.abilities  # Spell and passive levels.
	var lvl := ab.spell_level(PackLeapData.ID)  # 0 = never learned.
	if lvl > 0:
		var node: NecroSpell = ab.spells.nodes.get(PackLeapData.ID)  # The spell node (null if never ticked).
		print("[autotest] act XIV spell: pack_leap: Lv%d%s dmg=%d (apex pack %d) boss=%d kills=%d %s" % [lvl,
			" EVOLVED" if ab.evolved.has(PackLeapData.ID) else "", int(ab.spells.damage_of(PackLeapData.ID)),
			int(st.get("dmg_" + PackLeapData.EVOLVED_SOURCE, 0.0)),
			int(st.get("bossdmg_" + PackLeapData.SOURCE, 0.0)) + int(st.get("bossdmg_" + PackLeapData.EVOLVED_SOURCE, 0.0)),
			int(ab.spells.kills_of(PackLeapData.ID)), node.summary_extra() if node != null else ""])
	var inst := ab.passive_level(PackLeapData.PACK_INSTINCT)  # Pack Instinct level.
	if inst > 0:
		print("[autotest] act XIV passive: pack_instinct Lv%d (leaps +%d%%, pounce +%d px)" % [
			inst, roundi(100.0 * ab.passive_value(PackLeapData.PACK_INSTINCT, PackLeapData.DAMAGE_KEY)),
			roundi(ab.passive_value(PackLeapData.PACK_INSTINCT, PackLeapData.POUNCE_KEY))])
