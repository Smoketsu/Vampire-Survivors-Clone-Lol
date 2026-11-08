## GalleonReport — the autotest summary lines of the Treasure Galleon (Act X,
## the Black Tide; GDD §15.0 "The Treasure Galleon (Act X phase 2)" and the
## rows after it). Read-only: it never changes the run. Two entry points:
##   print_lines(game, st) — from CorsairReport.print_lines() (only when the
##       Black Tide ran), each line only when its system ran:
##     galleon:          GalleonDirector (zones, broadsides, Old Hollow-Eye,
##                       the events)
##     broadsides:       the lanes' hits on summons, enemies hit and their
##                       damage, the enemies drowned overboard
##     deck cannons:     shots, damage, kills, splash hits, the s they were manned
##     galleon kinds:    the Gunnery Mate, the Voodoo Navigator, the Gunboat and
##                       the Hull Crab (only when one of them spawned, any stage)
##     old hollow-eye:   the miniboss's fight (when it spawned)
##     galleon threats:  the run's top summon-damage sources and summon deaths
##     marrec:           her fight (when she was the boss)
##   item_lines(game, st) — from Autotest.finish() on every stage, only when one
##       of the Galleon's items was taken (so other runs print as before):
##     act X spell:      Cannonade / Dead Men's Broadside
##     act X passives:   Black Powder, Sea Legs
##     walked the plank: the achievement's count (only on an Act X deck)
class_name GalleonReport
extends RefCounted


## The stage's lines (see the header).
static func print_lines(game: Game, st: Dictionary) -> void:
	var en := game.enemies  # The enemy director.
	if en.galleon != null:
		print("[autotest] galleon: %s" % en.galleon.summary_line())
		print("[autotest] broadsides: %d | summon hits %d (dmg %d), on you dmg %d | enemies hit %d (dmg %d)" % [
			int(st.get("broadsides", 0.0)), int(st.get("broadside_lane_hits", 0.0)),
			int(st.get("summon_dmg_from_" + GalleonData.BROADSIDE_SOURCE, 0.0)), int(st.get("player_dmg_from_" + GalleonData.BROADSIDE_SOURCE, 0.0)),
			int(st.get("broadside_enemy_hits", 0.0)), int(st.get("broadside_enemy_dmg", 0.0))])
		print("[autotest] deck cannons: %d | shots %d (dmg %d, kills %d, splash hits %d) | manned %.0f cannon-s" % [
			en.galleon.cannons.size(), int(st.get("cannon_shots", 0.0)), int(st.get("cannon_dmg", 0.0)), int(st.get("cannon_kills", 0.0)),
			int(st.get("cannon_splash_hits", 0.0)), float(st.get("cannon_manned_s", 0.0))])
	var kinds := PackedStringArray()
	if float(st.get("spawned_gunnery_mate", 0.0)) > 0.0:
		kinds.append("gunnery mates: lobs %d, grenadoes %d, fizzled %d" % [int(st.get("gunnery_lobs", 0.0)), int(st.get("gunnery_grenadoes", 0.0)), int(st.get("gunnery_fizzled", 0.0))])
	if float(st.get("spawned_voodoo_navigator", 0.0)) > 0.0:
		kinds.append("navigators: marks %d, failed %d" % [int(st.get("navigator_marks", 0.0)), int(st.get("sea_marks_failed", 0.0))])
	if float(st.get("gunboats_launched", 0.0)) > 0.0 or float(st.get("gunboats_refused", 0.0)) > 0.0:
		kinds.append("gunboats: launched %d (refused %d), volleys %d, lane hits %d, sunk %d, left %d" % [int(st.get("gunboats_launched", 0.0)),
			int(st.get("gunboats_refused", 0.0)), int(st.get("gunboat_volleys", 0.0)), int(st.get("gunboat_lane_hits", 0.0)),
			int(st.get("gunboats_sunk", 0.0)), int(st.get("gunboats_left", 0.0))])
	if float(st.get("spawned_hull_crab", 0.0)) > 0.0:
		kinds.append("hull crabs: strikes %d, climbed aboard %d, drowned %d" % [int(st.get("sea_strikes_climb", 0.0)), int(st.get("sea_climbs_landed", 0.0)),
			int(st.get("overboard_hull_crab", 0.0))])
	if not kinds.is_empty():
		print("[autotest] galleon kinds: %s" % " | ".join(kinds))
	if float(st.get("hollow_eye_spawned", 0.0)) > 0.0:
		print("[autotest] old hollow-eye: arms raised %d | killed %d (ttk %.0f s) | grabs on the run %d (dragged %d)" % [
			int(st.get("hollow_eye_arms", 0.0)), int(st.get("hollow_eye_kills", 0.0)), float(st.get("hollow_eye_ttk", 0.0)),
			int(st.get("sea_grabs", 0.0)), int(st.get("sea_dragged", 0.0))])
	if String(game.stage_def.get("id", "")) == GalleonStage.ID:
		print("[autotest] galleon threats (summon dmg by source): %s | summon deaths by source: %s | overboard %d (walked the plank: %s)" % [
			FortKesslerReport._threats(st), FortKesslerReport._deaths(st), int(st.get("overboard_total", 0.0)),
			"yes" if float(st.get("overboard_total", 0.0)) >= float(GalleonData.WALKED_GOAL) else "no"])
	if String(en.boss_info.get("id", "")) == "marrec" and en.boss is BossMarrec:
		print("[autotest] marrec: %s" % BossMarrec.summary_line(st))


## The items' lines (see the header).
static func item_lines(game: Game, st: Dictionary) -> void:
	var ab := game.abilities  # Spell and passive levels.
	var lvl := ab.spell_level(CannonadeData.ID)  # 0 = never learned.
	if lvl > 0:
		var node: NecroSpell = ab.spells.nodes.get(CannonadeData.ID)  # The spell node (null if never ticked).
		print("[autotest] act X spell: cannonade: Lv%d%s dmg=%d (dead men's broadside %d) kills=%d %s" % [lvl,
			" EVOLVED" if ab.evolved.has(CannonadeData.ID) else "", int(ab.spells.damage_of(CannonadeData.ID)),
			int(st.get("dmg_" + CannonadeData.EVOLVED_SOURCE, 0.0)), int(ab.spells.kills_of(CannonadeData.ID)),
			node.summary_extra() if node != null else ""])
	var powder := ab.passive_level(CannonadeData.BLACK_POWDER)  # Black Powder level.
	var legs := ab.passive_level(CorsairRulesData.SEA_LEGS)  # Sea Legs level.
	if powder > 0 or legs > 0:
		print("[autotest] act X passives: black_powder Lv%d (blast +%d%%, knock %d px; knocks %d) | sea_legs Lv%d (drift and pulls on summons -%d%%)" % [
			powder, roundi(100.0 * ab.passive_value(CannonadeData.BLACK_POWDER, CannonadeData.BLAST_KEY)),
			int(ab.passive_value(CannonadeData.BLACK_POWDER, CannonadeData.KNOCK_KEY)), int(st.get("cannonade_knocks", 0.0)),
			legs, roundi(100.0 * ab.passive_value(CorsairRulesData.SEA_LEGS, CorsairRulesData.SEA_LEGS_KEY))])
