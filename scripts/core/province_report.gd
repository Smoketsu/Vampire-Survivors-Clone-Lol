## ProvinceReport — the autotest summary lines of the Burning Province (Act V,
## Stage 13; GDD §15.0 "The Burning Province (Act V phase 2)" and "Hundred
## Shadows, Hidden Hand and the Grave Kunoichi (Act V)"), called by
## ShogunateReport (its own block) and by Autotest.finish() for the items:
##   print_lines():
##     province:        ProvinceDirector (the paddies, the village fires,
##                      Shuten-dōji, the lanterns and No Shadow Unlit)
##     province kinds:  the Kunoichi's smoke and lunges, the summons blinded,
##                      the Kappa's grapples, the sake and village fires
##     shuten-doji:     the miniboss's fight (only when he spawned)
##     kage:            the boss's fight (only when Kage is the boss)
##   print_items():
##     act V spell / act V passives: Hundred Shadows and its passives (only
##       when one of the Province's items was taken, so other runs print as
##       before).
## Read-only: it never changes the run.
class_name ProvinceReport
extends RefCounted


## The stage's lines (see the header).
static func print_lines(game: Game, st: Dictionary) -> void:
	var en := game.enemies  # The enemy director.
	if en.province != null:
		print("[autotest] province: %s" % en.province.summary_line())
	var kinds := false  # A Burning Province kind spawned (Kage's shadows are her fight's).
	for k: String in [ProvinceEnemyData.KUNOICHI, ProvinceEnemyData.KAPPA, ProvinceEnemyData.SHUTEN_DOJI]:
		kinds = kinds or float(st.get("spawned_" + k, 0.0)) > 0.0
	if kinds or en.province_haz != null:
		print("[autotest] province kinds: kunoichi smokes %d (summons blinded %d; all smoke: blinds %d, %d s), lunges %d (hit you %d) | kappa grapples %d (squeezes %d) | fires: sake %d, village %d (dmg to summons %d, to you %d) | smoke clouds %d" % [
			int(st.get("kunoichi_smokes", 0.0)), int(st.get("summon_blinds_kunoichi_smoke", 0.0)), int(st.get("summon_blinds", 0.0)), int(st.get("summon_blinded_seconds", 0.0)),
			int(st.get("kunoichi_lunges", 0.0)), int(st.get("kunoichi_lunge_hits", 0.0)), int(st.get("kappa_grapples", 0.0)), int(st.get("kappa_squeezes", 0.0)),
			int(st.get("shuten_barrels", 0.0)), int(st.get("village_fires", 0.0)),
			int(st.get("summon_dmg_from_" + ProvinceEnemyData.SAKE_FIRE_SOURCE, 0.0) + st.get("summon_dmg_from_village_fire", 0.0)),
			int(st.get("player_dmg_from_" + ProvinceEnemyData.SAKE_FIRE_SOURCE, 0.0) + st.get("player_dmg_from_village_fire", 0.0)),
			int(st.get("province_smokes", 0.0))])
	if float(st.get("spawned_" + ProvinceEnemyData.SHUTEN_DOJI, 0.0)) > 0.0:
		var rage := float(st.get("shuten_rage_at", -1.0))
		print("[autotest] shuten-doji: barrel volleys %d (barrels %d, hits: summons %d, you %d) | smashes %d | rage %s | killed %d (ttk %.0f s) | dmg to you %d, to summons %d" % [
			int(st.get("shuten_throws", 0.0)), int(st.get("shuten_barrels", 0.0)), int(st.get("shuten_barrel_hits_summon", 0.0)),
			int(st.get("shuten_barrel_hits_player", 0.0)), int(st.get("oni_smashes", 0.0)),
			("at %d:%02d" % [floori(rage / 60.0), int(rage) % 60]) if rage >= 0.0 else "no", int(st.get("shuten_kills", 0.0)), float(st.get("shuten_ttk", 0.0)),
			int(st.get("player_dmg_from_" + ProvinceEnemyData.BARREL_SOURCE, 0.0) + st.get("player_dmg_from_" + ProvinceEnemyData.SAKE_FIRE_SOURCE, 0.0) + st.get("player_dmg_from_shuten_doji", 0.0)),
			int(st.get("summon_dmg_from_" + ProvinceEnemyData.BARREL_SOURCE, 0.0) + st.get("summon_dmg_from_" + ProvinceEnemyData.SAKE_FIRE_SOURCE, 0.0) + st.get("summon_dmg_from_shuten_doji", 0.0))])
	if String(en.boss_info.get("id", "")) == "kage" and en.boss != null:
		print("[autotest] kage: %s" % BossKage.summary_line(st))


## The items' lines (see the header).
static func print_items(game: Game, st: Dictionary) -> void:
	var ab := game.abilities  # Spell and passive levels.
	var lvl := ab.spell_level(HundredShadowsData.ID)  # 0 = never learned.
	if lvl > 0:
		var node: NecroSpell = ab.spells.nodes.get(HundredShadowsData.ID)  # The spell node (null if never ticked).
		print("[autotest] act V spell: hundred_shadows: Lv%d%s dmg=%d (thousand shadows %d) boss=%d kills=%d %s" % [lvl,
			" EVOLVED" if ab.evolved.has(HundredShadowsData.ID) else "", int(ab.spells.damage_of(HundredShadowsData.ID)),
			int(st.get("dmg_" + HundredShadowsData.EVOLVED_SOURCE, 0.0)),
			int(st.get("bossdmg_" + HundredShadowsData.SOURCE, 0.0) + st.get("bossdmg_" + HundredShadowsData.EVOLVED_SOURCE, 0.0)),
			int(ab.spells.kills_of(HundredShadowsData.ID)), node.summary_extra() if node != null else ""])
	var hand := ab.passive_level("hidden_hand")  # Hidden Hand level.
	var lanterns := ab.passive_level(ShogunateRulesData.PAPER_LANTERNS)  # Paper Lanterns level.
	if hand > 0 or lanterns > 0:
		print("[autotest] act V passives: hidden_hand Lv%d (bonus dmg %d) | paper_lanterns Lv%d (light x%.2f)" % [
			hand, int(st.get("hidden_hand_bonus_dmg", 0.0)), lanterns,
			game.shogunate.sun.lantern_mult(game.player) if game.shogunate != null else 1.0])
