## WitchwoodReport — the autotest summary lines of the Witchwood (Act VII, Stage
## 20; GDD §15.0 "The Witchwood (Act VII phase 2)" and the rows after it).
## Read-only: it never changes the run. Two entry points:
##   print_lines(game, st) — from CourtReport.print_lines() (only when the Court
##       ran), each line only when its system ran:
##     witchwood:       WitchwoodDirector (the Fen, the hex stones, the Bog
##                      Mother, The Coven Breaks, the events)
##     witch hexes:     WitchHexes (covens, hex circles cast by the moon / a
##                      stone, denied on dead ground, failed when a witch fell,
##                      the Court healed, the summons drained; the blood pools)
##                      when any of it ran (a witch, a bloated thrall, a stone,
##                      Isolde)
##     witchwood kinds: the Crimson Witches' chant, the Bloated Thralls' bursts
##                      (when any of the stage's kinds spawned)
##     bog mother:      the miniboss's fight (when she spawned)
##     isolde:          Isolde's fight (when she was the boss)
##   item_lines(game, st) — from Autotest.finish() on every stage, only when one
##       of the Witchwood's items was taken (so other runs print as before):
##     act VII spell:     Hex Circle / Witches' Sabbath (level, damage, kills,
##                        pulses, heal)
##     act VII passives:  Moonlit Rite, Embalmed (levels, effects)
class_name WitchwoodReport
extends RefCounted


## The stage's lines (see the header).
static func print_lines(game: Game, st: Dictionary) -> void:
	var en := game.enemies  # The enemy director.
	if en.witchwood != null:
		print("[autotest] witchwood: %s" % en.witchwood.summary_line())
	var hx := game.court.hexes if game.court != null else null  # The witches' hexes (null when none ran).
	if hx != null:
		print("[autotest] witch hexes: covens formed %d | circles cast %d (moon %d, stone %d; isolde %d, sisters %d), denied on dead ground %d, failed (a witch fell) %d | healed the Court %d (covens %d) | summon drain hits %d (dmg %d) | blood pools %d (bloated %d, cauldron %d), healed %d | stones broken %d" % [
			int(st.get("hex_covens_formed", 0.0)), int(st.get("hex_casts", 0.0)), int(st.get("hex_casts_moon", 0.0)), int(st.get("hex_casts_stone", 0.0)),
			int(st.get("hex_casts_" + IsoldeData.CIRCLE_TAG, 0.0)), int(st.get("hex_casts_" + IsoldeData.SISTER_TAG, 0.0)),
			int(st.get("hex_casts_denied_dead", 0.0)), int(st.get("hex_circles_failed", 0.0)),
			int(st.get("hex_circle_heal", 0.0)), int(st.get("hex_circle_heal_coven", 0.0)),
			int(st.get("hex_drain_hits", 0.0)), int(st.get("summon_dmg_from_" + WitchHexData.CIRCLE_SOURCE, 0.0)),
			int(st.get("blood_pools_opened", 0.0)), int(st.get("blood_pools_opened_" + BloatedThrallKit.POOL_TAG, 0.0)),
			int(st.get("blood_pools_opened_" + IsoldeData.POOL_TAG, 0.0)), int(st.get("blood_pool_heal", 0.0)),
			int(st.get("hex_stones_broken", 0.0))])
	if float(st.get("spawned_" + WitchHexData.WITCH, 0.0)) > 0.0 or float(st.get("spawned_" + WitchHexData.BLOATED, 0.0)) > 0.0:
		print("[autotest] witchwood kinds: crimson witches %d/%d (chanting %d s, regrouping %d s; coven witches by event %d) | bloated thralls %d/%d (bursts %d)" % [
			int(st.get("spawned_" + WitchHexData.WITCH, 0.0)), int(st.get("kill_" + WitchHexData.WITCH, 0.0)),
			int(st.get("witch_chant_time", 0.0)), int(st.get("witch_regroup_time", 0.0)), int(st.get("witchwood_coven_witches", 0.0)),
			int(st.get("spawned_" + WitchHexData.BLOATED, 0.0)), int(st.get("kill_" + WitchHexData.BLOATED, 0.0)), int(st.get("bloated_bursts", 0.0))])
	if float(st.get("bog_mother_spawned", 0.0)) > 0.0:
		print("[autotest] bog mother: drags %d (marked %d, seized %d, drowned %d) | slams %d (summon hits %d) | her bog slowed you %d, summons %d, foes %d | killed %d (ttk %.0f s) | dmg to you %d, to summons %d" % [
			int(st.get("bog_drags", 0.0)), int(st.get("bog_marked", 0.0)), int(st.get("bog_seized", 0.0)), int(st.get("bog_drowned", 0.0)),
			int(st.get("bog_slams", 0.0)), int(st.get("bog_slam_hits", 0.0)),
			int(st.get("bog_wade_player", 0.0)), int(st.get("bog_wade_summons", 0.0)), int(st.get("bog_wade_enemies", 0.0)),
			int(st.get("bog_mother_kills", 0.0)), float(st.get("bog_mother_ttk", 0.0)),
			int(st.get("player_dmg_from_" + WitchwoodEnemyData.MIRE_SOURCE, 0.0) + st.get("player_dmg_from_" + WitchwoodEnemyData.BOG_MOTHER, 0.0)),
			int(st.get("summon_dmg_from_" + WitchwoodEnemyData.DROWN_SOURCE, 0.0) + st.get("summon_dmg_from_" + WitchwoodEnemyData.MIRE_SOURCE, 0.0) + st.get("summon_dmg_from_" + WitchwoodEnemyData.BOG_MOTHER, 0.0))])
	if String(en.boss_info.get("id", "")) == IsoldeData.ARRIVAL["id"] and en.boss is BossIsolde:
		print("[autotest] isolde: %s" % BossIsolde.summary_line(st))


## The items' lines (see the header).
static func item_lines(game: Game, st: Dictionary) -> void:
	var ab := game.abilities  # Spell and passive levels.
	var lvl := ab.spell_level(WitchCircleData.ID)  # 0 = never learned.
	if lvl > 0:
		var node: NecroSpell = ab.spells.nodes.get(WitchCircleData.ID)  # The spell node (null if never ticked).
		print("[autotest] act VII spell: witch_circle: Lv%d%s dmg=%d (sabbath %d) kills=%d %s" % [lvl,
			" EVOLVED" if ab.evolved.has(WitchCircleData.ID) else "", int(ab.spells.damage_of(WitchCircleData.ID)),
			int(st.get("dmg_" + WitchCircleData.EVOLVED_SOURCE, 0.0)),
			int(ab.spells.kills_of(WitchCircleData.ID)), node.summary_extra() if node != null else ""])
	var rite := ab.passive_level(WitchCircleData.MOONLIT_RITE)  # Moonlit Rite level.
	var emb := ab.passive_level(WitchCircleData.EMBALMED)  # Embalmed level.
	if rite > 0 or emb > 0:
		print("[autotest] act VII passives: moonlit_rite Lv%d (spell dmg in your circle +%d%%, bonus %d) | embalmed Lv%d (feeding on summons x%.2f, withheld %d)" % [
			rite, roundi(100.0 * ab.passive_value(WitchCircleData.MOONLIT_RITE, WitchCircleData.RITE_KEY)), int(st.get("moonlit_rite_bonus_dmg", 0.0)),
			emb, 1.0 - ab.passive_value(WitchCircleData.EMBALMED, CourtRulesData.EMBALMED_KEY), int(st.get("feast_embalmed_withheld", 0.0))])
