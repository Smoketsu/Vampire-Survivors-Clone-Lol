## IlionReport — the autotest summary lines of the Shores of Ilion (Act IV,
## Stage 10; GDD §15.0 "The Shores of Ilion (Act IV phase 2)" and "Paris's
## Arrow, Mortal Heel and the Doomed Prophetess"). Read-only: it never changes
## the run. Two entry points:
##   print_lines(game, st) — from PantheonReport.print_lines() (only when the
##       Pantheon ran), each line only when its system ran:
##     ilion:        IlionDirector (siege towers, garrisons, Polyphemus,
##                   objective Soul Ash)
##     ilion kinds:  the testudo, the wolf packs and lunges, the cyclopes'
##                   boulders (when any of the stage's kinds spawned)
##     polyphemus:   the miniboss's fight (when he spawned)
##     achilles:     Achilles' fight (when he was the stage boss)
##   print_items(game, st) — from Autotest.finish() on every stage, only when
##       one of the Shores of Ilion's items was taken (so other runs print as
##       before):
##     act IV spell:     Paris's Arrow / Arrow of Fate (level, damage, kills, arrows)
##     act IV passives:  Mortal Heel, Bronze Breaker (levels, effects)
class_name IlionReport
extends RefCounted


## The stage's lines (see the header).
static func print_lines(game: Game, st: Dictionary) -> void:
	var en := game.enemies  # The enemy director.
	if en.ilion != null:
		print("[autotest] ilion: %s" % en.ilion.summary_line())
	var kinds := false  # A Shores of Ilion kind spawned.
	for k: String in IlionEnemyData.ENEMIES:
		kinds = kinds or float(st.get("spawned_" + k, 0.0)) > 0.0
	if kinds:
		print("[autotest] ilion kinds: testudo shots cut %d, boulders from above cut %d | wolf packs %d (packmates %d), lunges %d (hits %d) | cyclops throws %d (boulders %d, hits: summons %d, you %d)" % [
			int(st.get("testudo_shots", 0.0)), int(st.get("testudo_above_hits", 0.0)),
			int(st.get("wolf_packs", 0.0)), int(st.get("wolf_packmates", 0.0)), int(st.get("wolf_lunges", 0.0)), int(st.get("wolf_lunge_hits", 0.0)),
			int(st.get("cyclops_throws", 0.0)), int(st.get("cyclops_boulders", 0.0)), int(st.get("cyclops_boulder_hits_summon", 0.0)),
			int(st.get("cyclops_boulder_hits_player", 0.0))])
	if float(st.get("polyphemus_spawned", 0.0)) > 0.0:
		var rage := float(st.get("polyphemus_rage_at", -1.0))
		print("[autotest] polyphemus: volleys %d (boulders %d, hits: summons %d, you %d) | stomps %d (summon hits %d) | rage %s | killed %d (ttk %.0f s) | dmg to you %d, to summons %d" % [
			int(st.get("polyphemus_throws", 0.0)), int(st.get("polyphemus_boulders", 0.0)), int(st.get("polyphemus_boulder_hits_summon", 0.0)),
			int(st.get("polyphemus_boulder_hits_player", 0.0)), int(st.get("polyphemus_stomps", 0.0)), int(st.get("polyphemus_stomp_hits", 0.0)),
			("at %d:%02d" % [floori(rage / 60.0), int(rage) % 60]) if rage >= 0.0 else "no", int(st.get("polyphemus_kills", 0.0)), float(st.get("polyphemus_ttk", 0.0)),
			int(st.get("player_dmg_from_" + IlionEnemyData.POLY_BOULDER_SOURCE, 0.0) + st.get("player_dmg_from_" + IlionEnemyData.POLY_STOMP_SOURCE, 0.0) + st.get("player_dmg_from_polyphemus", 0.0)),
			int(st.get("summon_dmg_from_" + IlionEnemyData.POLY_BOULDER_SOURCE, 0.0) + st.get("summon_dmg_from_" + IlionEnemyData.POLY_STOMP_SOURCE, 0.0) + st.get("summon_dmg_from_polyphemus", 0.0))])
	if String(en.boss_info.get("id", "")) == "achilles" and en.boss != null:
		print("[autotest] achilles: %s" % BossAchilles.summary_line(st))


## The items' lines (see the header).
static func print_items(game: Game, st: Dictionary) -> void:
	var ab := game.abilities  # Spell and passive levels.
	var lvl := ab.spell_level("paris_arrow")  # 0 = never learned.
	if lvl > 0:
		var node: NecroSpell = ab.spells.nodes.get("paris_arrow")  # The spell node (null if never ticked).
		print("[autotest] act IV spell: paris_arrow: Lv%d%s dmg=%d (arrow of fate %d) boss=%d kills=%d %s" % [lvl,
			" EVOLVED" if ab.evolved.has("paris_arrow") else "", int(ab.spells.damage_of("paris_arrow")), int(st.get("dmg_arrow_of_fate", 0.0)),
			int(st.get("bossdmg_paris_arrow", 0.0) + st.get("bossdmg_arrow_of_fate", 0.0)),
			int(ab.spells.kills_of("paris_arrow")), node.summary_extra() if node != null else ""])
	var heel := ab.passive_level("mortal_heel")  # Mortal Heel level.
	var breaker := ab.passive_level("bronze_breaker")  # Bronze Breaker level.
	if heel > 0 or breaker > 0:
		print("[autotest] act IV passives: mortal_heel Lv%d (bonus dmg from behind %d) | bronze_breaker Lv%d" % [
			heel, int(st.get("mortal_heel_bonus_dmg", 0.0)), breaker])
