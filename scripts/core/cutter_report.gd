## CutterReport — the autotest summary lines of the Smuggler's Cutter (Act X,
## the Black Tide; GDD §15.0 "The Smuggler's Cutter (Act X phase 2)" and the
## rows after it). Read-only: it never changes the run. Two entry points:
##   print_lines(game, st) — from CorsairReport.print_lines() (only when the
##       Black Tide ran), each line only when its system ran:
##     cutter:       CutterDirector (barrels, the Fog Bank, Gorran's ram, the
##                   Fire Ship's patches, Not One Aboard, the events)
##     cutter crew:  the shared Grappler and Boatswain (when one spawned):
##                   throws, bites, px dragged, lines cut; bellows, crew buffed
##     bosun gorran: the miniboss's fight (when he came)
##     captain crow: Captain Crow's fight (when he was the boss)
##   item_lines(game, st) — from Autotest.finish() on every stage, only when one
##       of the Cutter's items was taken (so other runs print as before):
##     act X spell:    Chain Shot / Keelhauler (level, damage, kills, casts,
##                     shots, hits, knocks)
##     act X passives: Bosun's Whistle, Barnacle Bones (levels, effects)
class_name CutterReport
extends RefCounted


## The stage's lines (see the header).
static func print_lines(game: Game, st: Dictionary) -> void:
	var en := game.enemies  # The enemy director.
	if en.cutter != null:
		print("[autotest] cutter: %s" % en.cutter.summary_line())
	if float(st.get("spawned_grappler", 0.0)) > 0.0 or float(st.get("spawned_boatswain", 0.0)) > 0.0:
		print("[autotest] cutter crew: grapplers %d (throws %d, bites %d, dragged %d px, lines cut %d) | boatswains %d (bellows %d, crew buffed %d)" % [
			int(st.get("spawned_grappler", 0.0)), int(st.get("grapple_throws", 0.0)), int(st.get("grapple_bites", 0.0)),
			int(st.get("grapple_dragged_px", 0.0)), int(st.get("grapple_cut", 0.0)), int(st.get("spawned_boatswain", 0.0)),
			int(st.get("boatswain_bellows", 0.0)), int(st.get("boatswain_buffed", 0.0))])
	if float(st.get("spawned_" + CutterEnemyData.GORRAN, 0.0)) > 0.0:
		print("[autotest] bosun gorran: spawned %d, chain sweeps %d (summons hit %d), bellows %d, killed %d (ttk %.0f s) | dmg to you %d, to summons %d" % [
			int(st.get("spawned_" + CutterEnemyData.GORRAN, 0.0)), int(st.get("gorran_sweeps", 0.0)), int(st.get("gorran_sweep_hits", 0.0)),
			int(st.get("gorran_bellows", 0.0)), int(st.get("gorran_kills", 0.0)), float(st.get("gorran_ttk", 0.0)),
			int(st.get("player_dmg_from_" + CutterEnemyData.GORRAN, 0.0)), int(st.get("summon_dmg_from_" + CutterEnemyData.GORRAN, 0.0))])
	if String(en.boss_info.get("id", "")) == CrowData.ARRIVAL["id"] and en.boss is BossCrow:
		print("[autotest] captain crow: %s" % BossCrow.summary_line(st))


## The items' lines (see the header).
static func item_lines(game: Game, st: Dictionary) -> void:
	var ab := game.abilities  # Spell and passive levels.
	var lvl := ab.spell_level(ChainShotData.ID)  # 0 = never learned.
	if lvl > 0:
		var node: NecroSpell = ab.spells.nodes.get(ChainShotData.ID)  # The spell node (null if never ticked).
		print("[autotest] act X spell: chain_shot: Lv%d%s dmg=%d (keelhauler %d) kills=%d %s" % [lvl,
			" EVOLVED" if ab.evolved.has(ChainShotData.ID) else "", int(ab.spells.damage_of(ChainShotData.ID)),
			int(st.get("dmg_" + ChainShotData.EVOLVED_SOURCE, 0.0)),
			int(ab.spells.kills_of(ChainShotData.ID)), node.summary_extra() if node != null else ""])
	var whistle := ab.passive_level(ChainShotData.WHISTLE)  # Bosun's Whistle level.
	var barnacle := ab.passive_level(CorsairRulesData.BARNACLE_BONES)  # Barnacle Bones level.
	if whistle > 0 or barnacle > 0:
		print("[autotest] act X passives: bosuns_whistle Lv%d (chain shot cooldown -%d%%, %.0f s saved) | barnacle_bones Lv%d (summon hits on boats and sea beasts +%d%%)" % [
			whistle, roundi(100.0 * ab.passive_value(ChainShotData.WHISTLE, ChainShotData.WHISTLE_KEY)), float(st.get("chain_whistle_s", 0.0)),
			barnacle, roundi(100.0 * ab.passive_value(CorsairRulesData.BARNACLE_BONES, CorsairRulesData.BARNACLE_KEY))])
