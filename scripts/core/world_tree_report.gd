## WorldTreeReport — the autotest summary lines of THE WORLD-TREE and its rewards
## (temporary Act XV, the Turning Year's finale; GDD §15.0 "The World-Tree (Act XV
## phase 2)" and the rows after it). Read-only: it never changes the run. Two
## entry points:
##   stage_lines(game, st) — from WildReport.print_lines() (only when the Wild's
##       rules ran), each line only when its system ran:
##     world tree:    WorldTreeDirector (the Gardener of Roots, his call's grabs,
##                    the events)
##     green mother:  the Green Mother's fight (when she was the boss): the
##                    Turning by season, the Burial, her kill
##     last claim:    LastClaim (which slots ran, in order, and each one's effects)
##     first spring:  FirstSpring (only once it began)
##   item_lines(game, st) — from Autotest.finish() on every stage, only when one
##       of the World-Tree's items was taken (so other runs print as before):
##     act XV spell:   Root and Rot / Return to Earth
##     act XV passive: Compost Heart, Heartwood
##     act XV class:   the Ossuary Oak / World-Root Warden
## The big damage sources (her season bursts, the Last Claim's replays under
## their own acts' tags, the burial-free rules) carry their own tags in the
## shared `wild damage` line.
class_name WorldTreeReport
extends RefCounted


## The stage's lines (see the header).
static func stage_lines(game: Game, st: Dictionary) -> void:
	var en := game.enemies  # The enemy director.
	if en.world_tree != null:
		print("[autotest] world tree: %s" % en.world_tree.summary_line())
	if en.boss is BossGreenMother:
		var gm := en.boss as BossGreenMother
		print("[autotest] green mother: %s" % BossGreenMother.summary_line(st))
		print("[autotest] last claim: %s" % gm.claim.summary_line())
	var fs := game.wild.first_spring.summary_line()
	if fs != "":
		print("[autotest] first spring: %s" % fs)


## The items' lines (see the header).
static func item_lines(game: Game, st: Dictionary) -> void:
	var ab := game.abilities  # Spell and passive levels.
	var lvl := ab.spell_level(RootAndRotData.ID)  # 0 = never learned.
	if lvl > 0:
		var node: NecroSpell = ab.spells.nodes.get(RootAndRotData.ID)  # The spell node (null if never ticked).
		print("[autotest] act XV spell: root and rot: Lv%d%s dmg=%d (return to earth %d) boss=%d kills=%d %s" % [lvl,
			" EVOLVED" if ab.evolved.has(RootAndRotData.ID) else "", int(ab.spells.damage_of(RootAndRotData.ID)),
			int(st.get("dmg_" + RootAndRotData.EVOLVED_SOURCE, 0.0)),
			int(st.get("bossdmg_" + RootAndRotData.SOURCE, 0.0)) + int(st.get("bossdmg_" + RootAndRotData.EVOLVED_SOURCE, 0.0)),
			int(ab.spells.kills_of(RootAndRotData.ID)), node.summary_extra() if node != null else ""])
	var ch := ab.passive_level(RootAndRotData.COMPOST_HEART)  # Compost Heart level.
	if ch > 0:
		print("[autotest] act XV passive: compost heart Lv%d (rot +%d%%, rings +%.1f s)" % [
			ch, roundi(100.0 * ab.passive_value(RootAndRotData.COMPOST_HEART, RootAndRotData.ROT_KEY)), ab.passive_value(RootAndRotData.COMPOST_HEART, RootAndRotData.TIME_KEY)])
	var hw := ab.passive_level(OssuaryOakBehavior.HEARTWOOD)  # Heartwood level.
	if hw > 0:
		print("[autotest] act XV passive: heartwood Lv%d (lash +%d%%, +%d px)" % [
			hw, roundi(100.0 * ab.passive_value(OssuaryOakBehavior.HEARTWOOD, OssuaryOakBehavior.HEARTWOOD_DAMAGE_KEY)), int(ab.passive_value(OssuaryOakBehavior.HEARTWOOD, OssuaryOakBehavior.HEARTWOOD_RADIUS_KEY))])
	var cls := OssuaryOakBehavior.CLASS_ID
	if int(game.horde.class_levels.get(cls, 0)) > 0:
		print("[autotest] act XV class: ossuary oak: Lv %d%s, alive %d | dmg %d (melee %d, lash %d, world-root warden lash %d) | lashes %d (hits %d, warden roots %d) | rooted %d s" % [
			int(game.horde.class_levels.get(cls, 0)), " EVOLVED" if game.horde.evolutions.evolution_of(cls) != "" else "", game.horde.count_of(cls),
			int(st.get("dmg_" + cls, 0.0)) + int(st.get("dmg_" + OssuaryOakBehavior.SOURCE, 0.0)) + int(st.get("dmg_" + OssuaryOakBehavior.EVOLUTION_ID, 0.0)) + int(st.get("dmg_" + OssuaryOakBehavior.EVOLVED_SOURCE, 0.0)),
			int(st.get("dmg_" + cls, 0.0)) + int(st.get("dmg_" + OssuaryOakBehavior.EVOLUTION_ID, 0.0)), int(st.get("dmg_" + OssuaryOakBehavior.SOURCE, 0.0)),
			int(st.get("dmg_" + OssuaryOakBehavior.EVOLVED_SOURCE, 0.0)), int(st.get("oak_lashes", 0.0)), int(st.get("oak_lash_hits", 0.0)),
			int(st.get("warden_roots", 0.0)), int(st.get("oak_rooted_s", 0.0))])
