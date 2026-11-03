## CrashSiteReport — the autotest summary lines of the Crash Site (Act IX,
## Stage 25; GDD §15.0 "The Crash Site (Act IX phase 2)" and the rows after
## it). Read-only: it never changes the run. Two entry points:
##   print_lines(game, st) — from ConcordReport.print_lines() (only when the
##       Concord ran), each line only when its system ran:
##     crash site:     CrashSiteDirector (the crater, Infestation's eggs,
##                     Nothing Hatched, the Brood Matriarch, the events)
##     burrowers:      the Burrowers (when one spawned): dives, bursts, hits
##     acid:           AcidPools (when a lob was thrown): lobs, splashes,
##                     puddle hits, damage to summons and the necromancer
##     brood matriarch: the miniboss's fight (when she came)
##     hive mother:    the Hive Mother's fight (when she was the boss)
##   item_lines(game, st) — from Autotest.finish() on every stage, only when one
##       of the Crash Site's items was taken (so other runs print as before):
##     act IX spell:    Bone Beetles / Hive of Bone (level, damage, kills,
##                      bursts, beetles, bites)
##     act IX passives: Chitin, Anchored (levels, effects)
class_name CrashSiteReport
extends RefCounted


## The stage's lines (see the header).
static func print_lines(game: Game, st: Dictionary) -> void:
	var en := game.enemies  # The enemy director.
	if en.crash_site != null:
		print("[autotest] crash site: %s" % en.crash_site.summary_line())
	if float(st.get("spawned_" + ConcordEnemyData.BURROWER, 0.0)) > 0.0:
		print("[autotest] burrowers: dives %d (again %d), bursts %d (hits on summons %d, on you %d) | dmg to you %d, to summons %d" % [
			int(st.get("burrower_dives", 0.0)), int(st.get("burrower_reburrows", 0.0)), int(st.get("burrower_bursts", 0.0)),
			int(st.get("burrower_burst_hits", 0.0)), int(st.get("burrower_burst_on_you", 0.0)),
			int(st.get("player_dmg_from_" + ConcordEnemyData.BURROWER, 0.0)), int(st.get("summon_dmg_from_" + ConcordEnemyData.BURROWER, 0.0))])
	if game.concord != null and game.concord.acid.thrown > 0:
		var a := game.concord.acid
		print("[autotest] acid: lobs %d (spitters %d, refused %d), peak %d | splash hits %d, puddle hits %d, on you %d | dmg to you: splash %d, puddles %d | to summons: splash %d, puddles %d" % [
			a.thrown, int(st.get("acid_spitter_lobs", 0.0)), int(st.get("acid_lobs_refused", 0.0)), a.peak,
			int(st.get("acid_splash_hits", 0.0)), int(st.get("acid_puddle_hits", 0.0)), int(st.get("acid_on_you", 0.0)),
			int(st.get("player_dmg_from_" + ConcordEnemyData.ACID_SPITTER, 0.0)) + int(st.get("player_dmg_from_" + HiveMotherData.ACID_SOURCE, 0.0)),
			int(st.get("player_dmg_from_" + ConcordRulesData.ACID_SOURCE, 0.0)),
			int(st.get("summon_dmg_from_" + ConcordEnemyData.ACID_SPITTER, 0.0)) + int(st.get("summon_dmg_from_" + HiveMotherData.ACID_SOURCE, 0.0)),
			int(st.get("summon_dmg_from_" + ConcordRulesData.ACID_SOURCE, 0.0))])
	if float(st.get("spawned_" + CrashSiteEnemyData.MATRIARCH, 0.0)) > 0.0:
		print("[autotest] brood matriarch: spawned %d, sac volleys %d (sacs %d, landed as eggs %d), killed %d (ttk %.0f s), aloft grazes on her %d | dmg to you %d, to summons %d" % [
			int(st.get("spawned_" + CrashSiteEnemyData.MATRIARCH, 0.0)), int(st.get("matriarch_volleys", 0.0)),
			int(st.get("matriarch_sacs", 0.0)), int(st.get("matriarch_sacs_landed", 0.0)),
			int(st.get("matriarch_kills", 0.0)), float(st.get("matriarch_ttk", 0.0)), int(st.get("concord_air_whiffs", 0.0)),
			int(st.get("player_dmg_from_" + CrashSiteEnemyData.MATRIARCH, 0.0)), int(st.get("summon_dmg_from_" + CrashSiteEnemyData.MATRIARCH, 0.0))])
	if String(en.boss_info.get("id", "")) == HiveMotherData.ARRIVAL["id"] and en.boss is BossHiveMother:
		print("[autotest] hive mother: %s" % BossHiveMother.summary_line(st))


## The items' lines (see the header).
static func item_lines(game: Game, st: Dictionary) -> void:
	var ab := game.abilities  # Spell and passive levels.
	var lvl := ab.spell_level(BoneBeetlesData.ID)  # 0 = never learned.
	if lvl > 0:
		var node: NecroSpell = ab.spells.nodes.get(BoneBeetlesData.ID)  # The spell node (null if never ticked).
		print("[autotest] act IX spell: bone_beetles: Lv%d%s dmg=%d (hive of bone %d) kills=%d %s" % [lvl,
			" EVOLVED" if ab.evolved.has(BoneBeetlesData.ID) else "", int(ab.spells.damage_of(BoneBeetlesData.ID)),
			int(st.get("dmg_" + BoneBeetlesData.EVOLVED_SOURCE, 0.0)),
			int(ab.spells.kills_of(BoneBeetlesData.ID)), node.summary_extra() if node != null else ""])
	var chitin := ab.passive_level(BoneBeetlesData.CHITIN)  # Chitin level.
	var anchored := ab.passive_level(ConcordRulesData.ANCHORED)  # Anchored level.
	if chitin > 0 or anchored > 0:
		print("[autotest] act IX passives: chitin Lv%d (beetle bites +%d%%, bonus dmg %d) | anchored Lv%d (abduction holds -%d%%, broken by hits %d)" % [
			chitin, roundi(100.0 * ab.passive_value(BoneBeetlesData.CHITIN, BoneBeetlesData.CHITIN_KEY)), int(st.get("beetle_chitin_bonus_dmg", 0.0)),
			anchored, roundi(100.0 * ab.passive_value(ConcordRulesData.ANCHORED, ConcordRulesData.ANCHORED_KEY)), int(st.get("abduction_anchored_breaks", 0.0))])
